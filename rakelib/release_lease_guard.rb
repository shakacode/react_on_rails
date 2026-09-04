# frozen_string_literal: true

require "json"
require "tempfile"
require "time"

# Fences live release writes to the release-line lease established by
# script/release. The wrapper contract intentionally contains only public
# identity and process metadata; coordination credentials remain outside it.
module ReleaseLeaseGuard
  CONTRACT_ENV = "REACT_ON_RAILS_RELEASE_LEASE_CONTRACT"
  CONTRACT_VERSION = 1
  REPOSITORY = "shakacode/react_on_rails"
  RELEASE_TARGET_PATTERN = /\Arelease-line:(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\z/
  RELEASE_VERSION_PATTERN = /\A(?<base>(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*))
                            (?:\.(?:test|beta|alpha|rc|pre)\.(?:0|[1-9]\d*))?\z/ix
  CONTRACT_KEYS = %w[
    version release_version liveness_fd parent_pid pgid repo target branch agent_id instance_id machine_id
  ].freeze
  IDENTITY_FIELDS = %w[agent_id instance_id machine_id].freeze

  class LeaseError < StandardError; end

  Contract = Data.define(
    :liveness_fd,
    :parent_pid,
    :pgid,
    :repo,
    :target,
    :release_version,
    :branch,
    :agent_id,
    :instance_id,
    :machine_id
  )

  class SystemProcessAdapter
    def parent_pid
      Process.ppid
    end

    def process_group_id
      Process.getpgrp
    end
  end

  class AgentCoordStatusReader
    TIMEOUT_SECONDS = 20.0
    TERMINATION_GRACE_SECONDS = 5.0
    POLL_INTERVAL_SECONDS = 0.05

    def call(repo:, target:)
      stdout_file = Tempfile.new("react-on-rails-release-status-stdout")
      stderr_file = Tempfile.new("react-on-rails-release-status-stderr")
      child_pid = Process.spawn(
        "agent-coord", "status", "--repo", repo, "--target", target, "--json",
        out: stdout_file, err: stderr_file
      )
      status = wait_for_child(child_pid, monotonic_time + TIMEOUT_SECONDS)
      unless status
        terminate_child(child_pid)
        child_pid = nil
        raise LeaseError, "release lease status is unavailable"
      end
      raise LeaseError, "release lease status is unavailable" unless status.success?

      stdout_file.rewind
      JSON.parse(stdout_file.read)
    rescue JSON::ParserError, SystemCallError
      raise LeaseError, "release lease status is unavailable"
    ensure
      terminate_child(child_pid) if child_pid && !status
      stdout_file&.close!
      stderr_file&.close!
    end

    private

    def wait_for_child(child_pid, deadline)
      loop do
        waited = Process.waitpid2(child_pid, Process::WNOHANG)
        return waited[1] if waited

        remaining = deadline - monotonic_time
        return nil unless remaining.positive?

        sleep([POLL_INTERVAL_SECONDS, remaining].min)
      end
    rescue Errno::ECHILD
      nil
    end

    def terminate_child(child_pid)
      deadline = monotonic_time + TERMINATION_GRACE_SECONDS
      signal_child("TERM", child_pid)
      status = wait_for_child(child_pid, deadline)
      return status if status

      deadline = monotonic_time + TERMINATION_GRACE_SECONDS
      signal_child("KILL", child_pid)
      wait_for_child(child_pid, deadline)
    end

    def signal_child(signal, child_pid)
      Process.kill(signal, child_pid)
    rescue Errno::ESRCH
      nil
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end

  class Guard
    def initialize(dry_run:, status_reader:, clock:, process_adapter:, contract: nil, liveness_io: nil)
      @dry_run = dry_run
      @contract = contract
      @liveness_io = liveness_io
      @status_reader = status_reader
      @clock = clock
      @process_adapter = process_adapter
      @active = false
    end

    def activate!
      if @dry_run
        @active = true
        return true
      end

      verify_private_contract!
      verify_lease!
      verify_private_contract!
      @active = true
    rescue StandardError
      @active = false
      raise
    end

    def fence!
      raise LeaseError, "release lease guard is not active" unless active?
      return true if @dry_run

      # This is a fresh point-in-time ownership fence. The wrapper's independent
      # death watch terminates the process group if its supervisor disappears
      # while the resulting outward command is running.
      verify_private_contract!
      verify_lease!
      verify_private_contract!
      true
    end

    def active?
      @active
    end

    private

    def verify_private_contract!
      verify_process_identity!
      verify_liveness_descriptor!
      verify_supervisor_liveness!
    end

    def verify_process_identity!
      unless @process_adapter.parent_pid == @contract.parent_pid
        raise LeaseError, "release lease parent process does not match the wrapper contract"
      end
      return if @process_adapter.process_group_id == @contract.pgid

      raise LeaseError, "release process group does not match the wrapper contract"
    end

    def verify_liveness_descriptor!
      return if @liveness_io.fileno == @contract.liveness_fd

      raise LeaseError, "release supervisor liveness descriptor does not match the wrapper contract"
    rescue IOError
      raise LeaseError, "release supervisor liveness channel is closed"
    end

    def verify_supervisor_liveness!
      state = liveness_state
      return if state == :wait_readable

      raise LeaseError, "release supervisor liveness channel is closed" if state.nil? || state.empty?

      raise LeaseError, "release supervisor liveness channel contained unexpected data"
    end

    def liveness_state
      @liveness_io.read_nonblock(1, exception: false)
    rescue IOError
      nil
    end

    def verify_lease!
      payload = read_status!
      verify_status_scope!(payload)
      claim = exactly_one!(payload, "claims", "active claim")
      heartbeat = exactly_one!(payload, "heartbeats", "live heartbeat")
      verify_claim!(claim)
      verify_heartbeat!(heartbeat)
    end

    def read_status!
      payload = @status_reader.call(repo: @contract.repo, target: @contract.target)
      payload = JSON.parse(payload) if payload.is_a?(String)
      return payload if payload.is_a?(Hash)

      raise LeaseError, "release lease status is unavailable"
    rescue LeaseError
      raise
    rescue StandardError
      raise LeaseError, "release lease status is unavailable"
    end

    def verify_status_scope!(payload)
      scope = payload["scope"]
      unless scope.is_a?(Hash) && scope["kind"] == "target" && scope["repo"] == @contract.repo &&
             scope["target"] == @contract.target
        raise LeaseError, "release lease status scope does not match the wrapper contract"
      end
    end

    def exactly_one!(payload, field, description)
      entries = payload[field]
      return entries.first if entries.is_a?(Array) && entries.one? && entries.first.is_a?(Hash)

      raise LeaseError, "release lease status must contain exactly one #{description}"
    end

    def verify_claim!(claim)
      verify_field!(claim, "status", "active", "claim")
      verify_field!(claim, "repo", @contract.repo, "claim")
      verify_field!(claim, "target", @contract.target, "claim")
      verify_field!(claim, "branch", @contract.branch, "claim")
      IDENTITY_FIELDS.each { |field| verify_field!(claim, field, @contract.public_send(field), "claim") }
      verify_claim_expiry!(claim["expires_at"])
    end

    def verify_claim_expiry!(expires_at)
      raise LeaseError, "release claim expiry is unknown" if expires_at.nil? || expires_at.to_s.casecmp?("UNKNOWN")

      expiry = Time.iso8601(expires_at).utc
      raise LeaseError, "release claim is expired" unless expiry > @clock.call.utc
    rescue ArgumentError, TypeError
      raise LeaseError, "release claim expiry is invalid"
    end

    def verify_heartbeat!(heartbeat)
      verify_field!(heartbeat, "liveness", "live", "heartbeat")
      verify_field!(heartbeat, "target", "#{@contract.repo}##{@contract.target}", "heartbeat")
      verify_field!(heartbeat, "branch", @contract.branch, "heartbeat")
      IDENTITY_FIELDS.each do |field|
        verify_field!(heartbeat, field, @contract.public_send(field), "heartbeat")
      end
    end

    def verify_field!(record, field, expected, record_name)
      return if record[field] == expected

      raise LeaseError, "release #{record_name} #{field} does not match the wrapper contract"
    end
  end

  class << self
    def activate!(dry_run:, env: ENV, status_reader: AgentCoordStatusReader.new, clock: -> { Time.now.utc },
                  process_adapter: SystemProcessAdapter.new, liveness_io: nil)
      @guard = nil
      guard = if dry_run
                Guard.new(dry_run: true, status_reader:, clock:, process_adapter:)
              else
                contract = parse_contract!(env)
                io = liveness_io || inherited_liveness_io!(contract.liveness_fd)
                Guard.new(dry_run: false, contract:, liveness_io: io, status_reader:, clock:, process_adapter:)
              end
      guard.activate!
      @guard = guard
      true
    end

    def fence!
      raise LeaseError, "release lease guard is not active" unless @guard

      @guard.fence!
    end

    def active?
      @guard&.active? || false
    end

    private

    def parse_contract!(env)
      raw_contract = env[CONTRACT_ENV]
      raise LeaseError, "live release wrapper contract is required" if raw_contract.nil? || raw_contract.empty?

      attributes = JSON.parse(raw_contract)
      validate_contract_attributes!(attributes)
      immutable_contract(attributes)
    rescue JSON::ParserError, KeyError, TypeError
      raise LeaseError, "live release wrapper contract is invalid"
    end

    def immutable_contract(attributes)
      Contract.new(
        liveness_fd: attributes.fetch("liveness_fd"),
        parent_pid: attributes.fetch("parent_pid"),
        pgid: attributes.fetch("pgid"),
        repo: attributes.fetch("repo").dup.freeze,
        target: attributes.fetch("target").dup.freeze,
        release_version: attributes.fetch("release_version").dup.freeze,
        branch: attributes.fetch("branch").dup.freeze,
        agent_id: attributes.fetch("agent_id").dup.freeze,
        instance_id: attributes.fetch("instance_id").dup.freeze,
        machine_id: attributes.fetch("machine_id").dup.freeze
      ).freeze
    end

    def validate_contract_attributes!(attributes)
      unless attributes.is_a?(Hash) && attributes.keys.sort == CONTRACT_KEYS.sort &&
             attributes["version"] == CONTRACT_VERSION
        raise LeaseError, "live release wrapper contract is invalid"
      end

      validate_contract_process_fields!(attributes)
      validate_contract_release_scope!(attributes)
      validate_contract_identity!(attributes)
    end

    def validate_contract_process_fields!(attributes)
      %w[liveness_fd parent_pid pgid].each do |field|
        value = attributes[field]
        minimum = field == "liveness_fd" ? 3 : 1
        next if value.is_a?(Integer) && value >= minimum

        raise LeaseError, "live release wrapper contract is invalid"
      end
    end

    def validate_contract_release_scope!(attributes)
      return if contract_release_scope_valid?(attributes)

      raise LeaseError, "live release wrapper contract is invalid"
    end

    def contract_release_scope_valid?(attributes)
      target_match = RELEASE_TARGET_PATTERN.match(attributes["target"].to_s)
      target_base = target_match&.captures&.join(".")
      release_version = attributes["release_version"].to_s
      release_match = RELEASE_VERSION_PATTERN.match(release_version)
      return false unless attributes["repo"] == REPOSITORY && target_base && release_match&.[](:base) == target_base

      contract_release_branch_allowed?(attributes["branch"], target_base, release_version)
    end

    def contract_release_branch_allowed?(branch, target_base, release_version)
      branch == "release/#{target_base}" || (branch == "main" && release_version == target_base)
    end

    def validate_contract_identity!(attributes)
      IDENTITY_FIELDS.each do |field|
        value = attributes[field]
        next if value.is_a?(String) && value == value.strip && !value.empty? && !value.casecmp?("UNKNOWN")

        raise LeaseError, "live release wrapper contract is invalid"
      end
    end

    def inherited_liveness_io!(descriptor)
      IO.for_fd(descriptor, autoclose: false)
    rescue SystemCallError, ArgumentError
      raise LeaseError, "release supervisor liveness descriptor is unavailable"
    end
  end
end
