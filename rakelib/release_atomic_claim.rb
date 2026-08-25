# frozen_string_literal: true

require "json"
require "net/http"
require "time"
require "uri"

# Atomically acquires a release-line claim without the coordination backend's
# normal dead-holder takeover behavior. This is intentionally narrower than the
# general agent-coord claim command: active claims always refuse, and only an
# absent or exactly versioned released record may be replaced.
module ReleaseAtomicClaim
  class Error < StandardError; end
  class ClaimRefused < Error; end

  # The client deliberately combines validation, conditional-write semantics,
  # payload construction, and sanitized transport errors as one security boundary.
  # rubocop:disable Metrics/ClassLength
  class Client
    LOOPBACK_HOSTS = %w[localhost 127.0.0.1 ::1].freeze
    SAFE_COMPONENT = /[^A-Za-z0-9._~-]/
    REPOSITORY_PATTERN = %r{\A[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\z}
    TARGET_PATTERN = /\A[A-Za-z0-9_:-]+(?:\.[A-Za-z0-9_:-]+)*\z/
    SUCCESS_CODES = %w[200 201].freeze

    def initialize(base_url:, token:, transport: nil)
      @base_uri = validated_base_uri(base_url)
      raise Error, "coordination backend token is missing" if token.to_s.empty?

      @token = token
      @transport = transport || method(:net_http_request)
    end

    def acquire!(repo:, target:, agent_id:, instance_id:, machine_id:, branch:, ttl:, now: Time.now.utc)
      validate_claim_inputs!(repo:, target:, agent_id:, instance_id:, machine_id:, branch:, ttl:)
      path = "claims/#{repo}/#{target}.json"
      current = read_claim(path)
      conditional_headers = acquisition_headers(current)
      payload = claim_payload(
        repo:, target:, agent_id:, instance_id:, machine_id:, branch:, ttl:, now:
      )
      response = request(
        method: Net::HTTP::Put,
        path: state_path(path),
        headers: conditional_headers,
        body: JSON.generate("data" => payload)
      )
      return true if SUCCESS_CODES.include?(response.code.to_s)
      raise ClaimRefused, "release-line claim changed during atomic acquisition" if response.code.to_s == "409"

      raise Error, "coordination backend atomic claim write failed (HTTP #{response.code})"
    end

    def renew!(repo:, target:, agent_id:, instance_id:, machine_id:, branch:, ttl:, now: Time.now.utc)
      validate_claim_inputs!(repo:, target:, agent_id:, instance_id:, machine_id:, branch:, ttl:)
      path = "claims/#{repo}/#{target}.json"
      current = read_claim(path)
      verify_renewal_identity!(current, repo:, target:, agent_id:, instance_id:, machine_id:, branch:)
      payload = current.fetch(:data).merge(
        "updated_at" => now.utc.iso8601,
        "expires_at" => (now.utc + ttl).iso8601
      )
      response = request(
        method: Net::HTTP::Put,
        path: state_path(path),
        headers: { "If-Match" => current.fetch(:version) },
        body: JSON.generate("data" => payload)
      )
      return true if SUCCESS_CODES.include?(response.code.to_s)
      raise ClaimRefused, "release-line claim changed during atomic renewal" if response.code.to_s == "409"

      raise Error, "coordination backend atomic claim renewal failed (HTTP #{response.code})"
    end

    private

    def validated_base_uri(base_url)
      uri = URI.parse(base_url.to_s)
      unless %w[http https].include?(uri.scheme) && !uri.host.to_s.empty?
        raise Error, "coordination backend URL must be an HTTP(S) URL with a host"
      end
      if uri.scheme != "https" && !LOOPBACK_HOSTS.include?(uri.host)
        raise Error, "coordination backend URL must use HTTPS unless it is loopback"
      end

      uri
    rescue URI::InvalidURIError
      raise Error, "coordination backend URL is invalid"
    end

    def validate_claim_inputs!(repo:, target:, agent_id:, instance_id:, machine_id:, branch:, ttl:)
      raise Error, "release claim repository is invalid" unless repo.match?(REPOSITORY_PATTERN)
      raise Error, "release claim target is invalid" unless target.match?(TARGET_PATTERN)

      {
        "agent id" => agent_id,
        "instance id" => instance_id,
        "machine id" => machine_id,
        "branch" => branch
      }.each do |label, value|
        raise Error, "release claim #{label} is missing" if value.to_s.empty? || value.to_s.casecmp?("UNKNOWN")
      end
      raise Error, "release claim TTL must be positive" unless ttl.is_a?(Integer) && ttl.positive?
    end

    def read_claim(path)
      response = request(method: Net::HTTP::Get, path: state_path(path), headers: {}, body: nil)
      if response.code.to_s == "404"
        body = parsed_object(response.body)
        return nil if body["error"] == "not_found"

        raise Error, "coordination backend claim read returned an unknown missing-state response"
      end
      raise Error, "coordination backend claim read failed (HTTP #{response.code})" unless response.code.to_s == "200"

      body = parsed_object(response.body)
      data = body["data"]
      version = body["version"].to_s
      unless data.is_a?(Hash) && %w[active released].include?(data["status"]) &&
             !version.empty?
        raise Error, "coordination backend claim record is malformed"
      end

      { data:, version: }
    end

    def acquisition_headers(current)
      return { "If-None-Match" => "*" } unless current
      raise ClaimRefused, "release line already has an active claim" unless current.fetch(:data)["status"] == "released"

      { "If-Match" => current.fetch(:version) }
    end

    def verify_renewal_identity!(current, repo:, target:, agent_id:, instance_id:, machine_id:, branch:)
      raise ClaimRefused, "release-line claim is absent during renewal" unless current

      expected = {
        "status" => "active",
        "repo" => repo,
        "target" => target,
        "agent_id" => agent_id,
        "instance_id" => instance_id,
        "machine_id" => machine_id,
        "branch" => branch
      }
      return if expected.all? { |field, value| current.fetch(:data)[field] == value }

      raise ClaimRefused, "release-line claim identity changed during renewal"
    end

    def claim_payload(repo:, target:, agent_id:, instance_id:, machine_id:, branch:, ttl:, now:)
      timestamp = now.utc.iso8601
      {
        "schema_version" => 1,
        "repo" => repo,
        "target" => target,
        "agent_id" => agent_id,
        "branch" => branch,
        "status" => "active",
        "claimed_at" => timestamp,
        "updated_at" => timestamp,
        "expires_at" => (now.utc + ttl).iso8601,
        "phase" => "release-write-serialization",
        "instance_id" => instance_id,
        "machine_id" => machine_id
      }
    end

    def state_path(path)
      encoded = URI::DEFAULT_PARSER.escape(path, SAFE_COMPONENT)
      base_path = @base_uri.path.to_s.chomp("/")
      "#{base_path}/v1/state/#{encoded}"
    end

    def request(method:, path:, headers:, body:)
      request_headers = { "Authorization" => "Bearer #{@token}" }.merge(headers)
      request_headers["Content-Type"] = "application/json" if body
      @transport.call(
        method:,
        uri: request_uri(path),
        headers: request_headers,
        body:,
        open_timeout: 5,
        read_timeout: 10
      )
    rescue ClaimRefused, Error
      raise
    rescue StandardError
      raise Error, "coordination backend atomic claim request failed"
    end

    def request_uri(path)
      uri = @base_uri.dup
      uri.path = path
      uri.query = nil
      uri.fragment = nil
      uri
    end

    def parsed_object(raw_body)
      body = JSON.parse(raw_body.to_s)
      return body if body.is_a?(Hash)

      raise Error, "coordination backend returned a malformed JSON object"
    rescue JSON::ParserError
      raise Error, "coordination backend returned malformed JSON"
    end

    def net_http_request(method:, uri:, headers:, body:, open_timeout:, read_timeout:)
      request = method.new(uri)
      headers.each { |name, value| request[name] = value }
      request.body = body if body
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout:,
        read_timeout:
      ) do |http|
        http.max_retries = 0 if http.respond_to?(:max_retries=)
        http.request(request)
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
