#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "base64"
require "json"
require "net/http"
require "openssl"
require "securerandom"
require "timeout"
require "uri"
require "yaml"
require_relative "fleet_health"

module FleetValidation
  class TransientPublicRequestError < StandardError; end

  class PublicHTTPResponseError < ManifestError
    attr_reader :status

    def initialize(status, message)
      @status = status.to_i
      super(message)
    end
  end

  class PublicHTTPClient
    USER_AGENT = "react-on-rails-fleet-health/1"

    def initialize(github_token: ENV["GITHUB_TOKEN"], transport: Net::HTTP)
      @github_token = github_token
      @transport = transport
    end

    def json(url)
      uri = URI(url)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/vnd.github+json"
      request["User-Agent"] = USER_AGENT
      request["Authorization"] = "Bearer #{@github_token}" if @github_token && uri.host == "api.github.com"
      response = @transport.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 30) do |http|
        http.request(request)
      end
      unless response.is_a?(Net::HTTPSuccess)
        raise PublicHTTPResponseError.new(
          response.code,
          "public HTTP GET #{uri} failed with #{response.code}"
        )
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise ManifestError, "public HTTP GET #{url} returned invalid JSON: #{e.message}"
    rescue SocketError, SystemCallError, Timeout::Error, EOFError, OpenSSL::SSL::SSLError => e
      raise TransientPublicRequestError, "#{e.class}: #{e.message}"
    end
  end

  class PublicGitHubClient
    API = "https://api.github.com"

    def initialize(http:)
      @http = http
    end

    def get(path)
      @http.json("#{API}#{path}")
    end

    def content(repo, path, ref:)
      encoded = path.split("/").map { |part| URI.encode_www_form_component(part) }.join("/")
      result = get("/repos/#{repo}/contents/#{encoded}?ref=#{URI.encode_www_form_component(ref)}")
      raise ManifestError, "#{repo}:#{path} is not a file" unless result["type"] == "file"

      Base64.decode64(result.fetch("content"))
    rescue PublicHTTPResponseError => e
      raise unless e.status == 404

      raise MissingPublicContentError, "#{repo}:#{path} is unavailable"
    end
  end

  module FleetHealthCLI
    module_function

    def run(argv, http: nil)
      options = {
        manifest_path: "internal/contributor-info/demo-fleet.yml",
        observations_path: nil,
        registry_artifacts_path: nil,
        release: nil,
        rsc_version: nil,
        pack_id: nil,
        policy_commit: nil,
        generated_at: Time.now.utc.iso8601,
        output_dir: nil,
        live: false
      }
      parser = option_parser(options)
      parser.parse!(argv)

      manifest = load_yaml(options.fetch(:manifest_path))
      apply_manifest_versions!(options, manifest)
      require_options!(options)
      contract = FleetHealth.new(
        manifest:,
        pack_id: options[:pack_id] || "fleet-health-#{SecureRandom.hex(4)}",
        release: options.fetch(:release),
        rsc_version: options.fetch(:rsc_version),
        policy_commit: options.fetch(:policy_commit),
        generated_at: options.fetch(:generated_at)
      )
      observations, registry_artifacts = evidence_inputs(options, contract, http:)
      evidence = contract.evaluate(observations:, registry_artifacts:)
      contract.write_pack(options.fetch(:output_dir), evidence)
      puts "Wrote public fleet health pack to #{options.fetch(:output_dir)}"
      puts "Aggregate: #{evidence.dig('aggregate', 'status')}"
      0
    rescue TransientPublicRequestError => e
      warn "ERROR: live public request failed: #{e.message}"
      1
    rescue Errno::ENOENT, Psych::Exception, ManifestError, OptionParser::ParseError => e
      warn "ERROR: #{e.message}"
      warn parser
      1
    end

    def option_parser(options)
      OptionParser.new do |parser|
        parser.banner = "Usage: check_fleet_health.rb --release TAG --rsc-version VERSION [options]"
        parser.on("--manifest PATH", "Fleet manifest path") { |value| options[:manifest_path] = value }
        parser.on("--observations PATH", "Offline public observations YAML") do |value|
          options[:observations_path] = value
        end
        parser.on("--registry-artifacts PATH", "Offline public registry artifacts YAML") do |value|
          options[:registry_artifacts_path] = value
        end
        parser.on("--live", "Read public registries and public GitHub default heads") { options[:live] = true }
        parser.on("--release TAG", "Stable React on Rails tag") { |value| options[:release] = value }
        parser.on("--rsc-version VERSION", "Stable react-on-rails-rsc version") do |value|
          options[:rsc_version] = value
        end
        parser.on("--pack-id ID", "Stable evidence pack ID") { |value| options[:pack_id] = value }
        parser.on("--policy-commit SHA", "Exact policy commit") { |value| options[:policy_commit] = value }
        parser.on("--generated-at TIME", "ISO-8601 evidence timestamp") { |value| options[:generated_at] = value }
        parser.on("--output-dir PATH", "Output directory") { |value| options[:output_dir] = value }
        parser.on("-h", "--help", "Show help") do
          puts parser
          exit 0
        end
      end
    end

    def require_options!(options)
      %i[release rsc_version policy_commit output_dir].each do |key|
        next if options[key]

        raise OptionParser::MissingArgument, "--#{key.to_s.tr('_', '-')}"
      end
      offline = options[:observations_path] && options[:registry_artifacts_path]
      partial_offline = options[:observations_path] || options[:registry_artifacts_path]
      if options[:live] && partial_offline
        raise OptionParser::InvalidArgument, "--live cannot be combined with offline evidence paths"
      end
      return if options[:live] || offline

      raise OptionParser::MissingArgument,
            "--live or both --observations and --registry-artifacts"
    end

    def apply_manifest_versions!(options, manifest)
      options[:release] ||= manifest.dig("standing_health", "stable_release")
      options[:rsc_version] ||= manifest.dig("standing_health", "rsc_version")
    end

    def load_yaml(path)
      YAML.safe_load_file(path, permitted_classes: [], permitted_symbols: [], aliases: false)
    end

    def evidence_inputs(options, contract, http: nil)
      unless options[:live]
        return [
          load_yaml(options.fetch(:observations_path)),
          load_yaml(options.fetch(:registry_artifacts_path))
        ]
      end

      http ||= PublicHTTPClient.new
      registry = PublicRegistryResolver.new(fetcher: ->(url) { http.json(url) }).resolve(
        release: options.fetch(:release),
        rsc_version: options.fetch(:rsc_version)
      )
      probe = PublicGitHubProbe.new(client: PublicGitHubClient.new(http:))
      observations = contract.targets.to_h do |target|
        [target.fetch("id"), probe.observe(target, observed_at: options.fetch(:generated_at))]
      end
      [observations, registry]
    end
  end
end

exit FleetValidation::FleetHealthCLI.run(ARGV) if $PROGRAM_NAME == __FILE__
