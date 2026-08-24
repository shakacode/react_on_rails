# frozen_string_literal: true

require "json"
require "tmpdir"
require "time"
require_relative "spec_helper"
require_relative "../../../rakelib/release_lease_guard"

RSpec.describe ReleaseLeaseGuard do
  let(:now) { Time.utc(2026, 8, 23, 12) }
  let(:repo) { "shakacode/react_on_rails" }
  let(:target) { "release-line:17.1.0" }
  let(:branch) { "release/17.1.0" }
  let(:agent_id) { "release-17.1.0-7f715da1" }
  let(:instance_id) { "7f715da1-1507-40e0-bbec-9af64cd1a819" }
  let(:machine_id) { "release-host" }
  let(:parent_pid) { 12_345 }
  let(:pgid) { 12_346 }
  let(:status_reads) { [] }
  let(:liveness) do
    pipe = IO.pipe
    { reader: pipe.first, writer: pipe.last }
  end
  let(:status_payload) do
    {
      "scope" => { "kind" => "target", "repo" => repo, "target" => target },
      "claims" => [
        {
          "status" => "active",
          "repo" => repo,
          "target" => target,
          "branch" => branch,
          "agent_id" => agent_id,
          "instance_id" => instance_id,
          "machine_id" => machine_id,
          "expires_at" => (now + 300).iso8601
        }
      ],
      "heartbeats" => [
        {
          "agent_id" => agent_id,
          "instance_id" => instance_id,
          "machine_id" => machine_id,
          "branch" => branch,
          "target" => "#{repo}##{target}",
          "liveness" => "live"
        }
      ]
    }
  end

  around do |example|
    described_class.instance_variable_set(:@guard, nil)
    example.run
  ensure
    liveness.each_value { |io| io.close unless io.closed? }
    described_class.instance_variable_set(:@guard, nil)
  end

  def process_adapter
    Struct.new(:parent_pid, :process_group_id).new(parent_pid, pgid)
  end

  def status_reader
    lambda do |repo:, target:|
      status_reads << [repo, target]
      status_payload
    end
  end

  def contract(overrides = {})
    {
      "version" => 1,
      "liveness_fd" => liveness.fetch(:reader).fileno,
      "parent_pid" => parent_pid,
      "pgid" => pgid,
      "repo" => repo,
      "target" => target,
      "release_version" => "17.1.0.rc.0",
      "branch" => branch,
      "agent_id" => agent_id,
      "instance_id" => instance_id,
      "machine_id" => machine_id
    }.merge(overrides)
  end

  def activate_live(contract_overrides: {}, payload: status_payload, adapter: process_adapter)
    described_class.activate!(
      dry_run: false,
      env: { described_class::CONTRACT_ENV => JSON.generate(contract(contract_overrides)) },
      status_reader: lambda { |repo:, target:|
                       status_reads << [repo, target]
                       payload
                     },
      clock: -> { now },
      process_adapter: adapter,
      liveness_io: liveness.fetch(:reader)
    )
  end

  def changed_status(*path, value:)
    changed = Marshal.load(Marshal.dump(status_payload))
    path[0...-1].reduce(changed) { |cursor, key| cursor.fetch(key) }[path.last] = value
    changed
  end

  it "bounds and reaps a stalled default status subprocess without exposing diagnostics" do
    stub_const("ReleaseLeaseGuard::AgentCoordStatusReader::TIMEOUT_SECONDS", 0.7)
    stub_const("ReleaseLeaseGuard::AgentCoordStatusReader::TERMINATION_GRACE_SECONDS", 0.1)
    stub_const("ReleaseLeaseGuard::AgentCoordStatusReader::POLL_INTERVAL_SECONDS", 0.01)

    Dir.mktmpdir("release-lease-guard-status") do |directory|
      pid_file = File.join(directory, "agent-coord.pid")
      executable = File.join(directory, "agent-coord")
      File.write(
        executable,
        <<~RUBY
          #!#{RbConfig.ruby}
          File.write(ENV.fetch("TEST_AGENT_COORD_PID_FILE"), Process.pid.to_s)
          warn "fake backend diagnostic: \#{ENV.fetch('AGENT_COORD_API_TOKEN')}"
          Signal.trap("TERM", "IGNORE")
          sleep 4
        RUBY
      )
      File.chmod(0o755, executable)

      previous_path = ENV.fetch("PATH")
      previous_pid_file = ENV.fetch("TEST_AGENT_COORD_PID_FILE", nil)
      previous_token = ENV.fetch("AGENT_COORD_API_TOKEN", nil)
      ENV["PATH"] = "#{directory}:#{previous_path}"
      ENV["TEST_AGENT_COORD_PID_FILE"] = pid_file
      ENV["AGENT_COORD_API_TOKEN"] = "coord-secret-must-never-appear"
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      expect do
        expect do
          described_class::AgentCoordStatusReader.new.call(repo:, target:)
        end.to raise_error(described_class::LeaseError, "release lease status is unavailable")
      end.to output("").to_stdout.and output("").to_stderr

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      stalled_pid = Integer(File.read(pid_file), 10)
      expect(elapsed).to be < 1.5
      expect { Process.kill(0, stalled_pid) }.to raise_error(Errno::ESRCH)
      expect { Process.waitpid(stalled_pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
    ensure
      ENV["PATH"] = previous_path
      ENV["TEST_AGENT_COORD_PID_FILE"] = previous_pid_file
      ENV["AGENT_COORD_API_TOKEN"] = previous_token
    end
  end

  it "refuses direct live activation without a wrapper contract" do
    expect do
      described_class.activate!(
        dry_run: false,
        env: {},
        status_reader:,
        clock: -> { now },
        process_adapter:
      )
    end.to raise_error(described_class::LeaseError, /wrapper contract is required/)

    expect(status_reads).to be_empty
    expect(described_class).not_to be_active
  end

  it "accepts a matching claim, heartbeat, parent channel, and process group" do
    expect(activate_live).to be(true)

    expect(status_reads).to eq([[repo, target]])
    expect(described_class).to be_active
  end

  it "accepts a stable release from main when the target base and live lease branch match" do
    payload = changed_status("claims", 0, "branch", value: "main")
    payload.fetch("heartbeats").first["branch"] = "main"

    expect(
      activate_live(
        contract_overrides: { "release_version" => "17.1.0", "branch" => "main" },
        payload:
      )
    ).to be(true)
  end

  it "rejects a prerelease contract on main" do
    expect do
      activate_live(contract_overrides: { "branch" => "main" })
    end.to raise_error(described_class::LeaseError, /wrapper contract is invalid/)
  end

  it "rejects a release version outside the contract target base" do
    expect do
      activate_live(contract_overrides: { "release_version" => "17.2.0.rc.0" })
    end.to raise_error(described_class::LeaseError, /wrapper contract is invalid/)
  end

  it "performs a fresh authoritative read for every fence" do
    activate_live

    expect(described_class.fence!).to be(true)
    expect(described_class.fence!).to be(true)
    expect(status_reads).to eq([[repo, target], [repo, target], [repo, target]])
  end

  {
    "inactive" => "released",
    "unknown" => "unknown"
  }.each do |description, status|
    it "rejects an #{description} claim" do
      expect { activate_live(payload: changed_status("claims", 0, "status", value: status)) }
        .to raise_error(described_class::LeaseError, /claim status/)
    end
  end

  it "rejects an expired claim" do
    payload = changed_status("claims", 0, "expires_at", value: (now - 1).iso8601)

    expect { activate_live(payload:) }
      .to raise_error(described_class::LeaseError, /claim is expired/)
  end

  it "rejects a claim whose expiry is unknown" do
    payload = changed_status("claims", 0, "expires_at", value: "UNKNOWN")

    expect { activate_live(payload:) }
      .to raise_error(described_class::LeaseError, /claim expiry/)
  end

  {
    "repo" => "other/repository",
    "target" => "release-line:17.2.0",
    "branch" => "release/17.2.0",
    "agent_id" => "other-agent",
    "instance_id" => "other-instance",
    "machine_id" => "other-machine"
  }.each do |field, wrong_value|
    it "rejects a claim with the wrong #{field}" do
      payload = changed_status("claims", 0, field, value: wrong_value)

      expect { activate_live(payload:) }
        .to raise_error(described_class::LeaseError, /claim #{field}/)
    end
  end

  it "rejects a dead heartbeat" do
    payload = changed_status("heartbeats", 0, "liveness", value: "dead")

    expect { activate_live(payload:) }
      .to raise_error(described_class::LeaseError, /heartbeat liveness/)
  end

  it "requires exactly one claim and one heartbeat" do
    no_claim = changed_status("claims", value: [])
    duplicate_heartbeat = changed_status("heartbeats", value: status_payload.fetch("heartbeats") * 2)

    expect { activate_live(payload: no_claim) }
      .to raise_error(described_class::LeaseError, /exactly one active claim/)
    expect { activate_live(payload: duplicate_heartbeat) }
      .to raise_error(described_class::LeaseError, /exactly one live heartbeat/)
  end

  it "rejects a closed parent-liveness channel" do
    liveness.fetch(:writer).close

    expect { activate_live }
      .to raise_error(described_class::LeaseError, /supervisor liveness channel is closed/)
  end

  it "rejects a contract for the wrong parent" do
    wrong_parent = Struct.new(:parent_pid, :process_group_id).new(parent_pid + 1, pgid)

    expect { activate_live(adapter: wrong_parent) }
      .to raise_error(described_class::LeaseError, /parent process/)
  end

  it "rejects a contract for the wrong process group" do
    wrong_group = Struct.new(:parent_pid, :process_group_id).new(parent_pid, pgid + 1)

    expect { activate_live(adapter: wrong_group) }
      .to raise_error(described_class::LeaseError, /process group/)
  end

  it "rejects a liveness IO that does not match the inherited descriptor" do
    wrong_descriptor = liveness.fetch(:reader).fileno + 1

    expect { activate_live(contract_overrides: { "liveness_fd" => wrong_descriptor }) }
      .to raise_error(described_class::LeaseError, /liveness descriptor/)
  end

  it "fails closed if the supervisor channel closes after activation" do
    activate_live
    liveness.fetch(:writer).close

    expect { described_class.fence! }
      .to raise_error(described_class::LeaseError, /supervisor liveness channel is closed/)
  end

  it "fails closed if the supervisor channel closes during the authoritative status read" do
    reads = 0
    closing_reader = lambda do |repo:, target:|
      status_reads << [repo, target]
      reads += 1
      liveness.fetch(:writer).close if reads == 2
      status_payload
    end
    described_class.activate!(
      dry_run: false,
      env: { described_class::CONTRACT_ENV => JSON.generate(contract) },
      status_reader: closing_reader,
      clock: -> { now },
      process_adapter:,
      liveness_io: liveness.fetch(:reader)
    )

    expect { described_class.fence! }
      .to raise_error(described_class::LeaseError, /supervisor liveness channel is closed/)
  end

  it "activates dry-run mode without identity, a wrapper contract, or coordination reads" do
    reader = ->(**) { raise "coordination must not be read in dry-run mode" }

    expect(
      described_class.activate!(
        dry_run: true,
        env: {},
        status_reader: reader,
        clock: -> { now },
        process_adapter:
      )
    ).to be(true)
    expect(described_class.fence!).to be(true)
    expect(described_class).to be_active
  end
end
