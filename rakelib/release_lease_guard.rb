# frozen_string_literal: true

require "json"

# Fences live release writes to the local supervisor established by
# script/release. Cross-agent coordination is owned by the Shaka workflow;
# publication safety here is deliberately limited to process-local guarantees.
module ReleaseLeaseGuard
  CONTRACT_ENV = "REACT_ON_RAILS_RELEASE_LEASE_CONTRACT"
  CONTRACT_VERSION = 2
  REPOSITORY = "shakacode/react_on_rails"
  RELEASE_TARGET_PATTERN = /\Arelease-line:(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\z/
  RELEASE_VERSION_PATTERN = /\A(?<base>(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*))
                            (?:\.(?:test|beta|alpha|rc|pre)\.(?:0|[1-9]\d*))?\z/ix
  CONTRACT_KEYS = %w[
    version release_version liveness_fd parent_pid pgid repo target branch
  ].freeze

  class LeaseError < StandardError; end

  Contract = Data.define(
    :liveness_fd,
    :parent_pid,
    :pgid,
    :repo,
    :target,
    :release_version,
    :branch
  )

  class SystemProcessAdapter
    def parent_pid
      Process.ppid
    end

    def process_group_id
      Process.getpgrp
    end
  end

  class Guard
    def initialize(dry_run:, process_adapter:, contract: nil, liveness_io: nil)
      @dry_run = dry_run
      @contract = contract
      @liveness_io = liveness_io
      @process_adapter = process_adapter
      @active = false
    end

    def activate!
      if @dry_run
        @active = true
        return true
      end

      verify_private_contract!
      @active = true
    rescue StandardError
      @active = false
      raise
    end

    def fence!
      raise LeaseError, "release supervisor guard is not active" unless active?
      return true if @dry_run

      # This is a fresh point-in-time supervisor fence. The wrapper's independent
      # death watch terminates the process group if its supervisor disappears
      # while the resulting outward command is running.
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
        raise LeaseError, "release parent process does not match the wrapper contract"
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
  end

  class << self
    def activate!(dry_run:, env: ENV, process_adapter: SystemProcessAdapter.new, liveness_io: nil)
      @guard = nil
      guard = if dry_run
                Guard.new(dry_run: true, process_adapter:)
              else
                contract = parse_contract!(env)
                io = liveness_io || inherited_liveness_io!(contract.liveness_fd)
                Guard.new(dry_run: false, contract:, liveness_io: io, process_adapter:)
              end
      guard.activate!
      @guard = guard
      true
    end

    def fence!
      raise LeaseError, "release supervisor guard is not active" unless @guard

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
        branch: attributes.fetch("branch").dup.freeze
      ).freeze
    end

    def validate_contract_attributes!(attributes)
      unless attributes.is_a?(Hash) && attributes.keys.sort == CONTRACT_KEYS.sort &&
             attributes["version"] == CONTRACT_VERSION
        raise LeaseError, "live release wrapper contract is invalid"
      end

      validate_contract_process_fields!(attributes)
      validate_contract_release_scope!(attributes)
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

    def inherited_liveness_io!(descriptor)
      IO.for_fd(descriptor, autoclose: false)
    rescue SystemCallError, ArgumentError
      raise LeaseError, "release supervisor liveness descriptor is unavailable"
    end
  end
end
