# frozen_string_literal: true

require "json"
require_relative "spec_helper"
require_relative "../../../rakelib/release_lease_guard"

RSpec.describe ReleaseLeaseGuard do
  let(:repo) { "shakacode/react_on_rails" }
  let(:target) { "release-line:17.1.0" }
  let(:branch) { "release/17.1.0" }
  let(:parent_pid) { 12_345 }
  let(:pgid) { 12_346 }
  let(:liveness) do
    pipe = IO.pipe
    { reader: pipe.first, writer: pipe.last }
  end

  around do |example|
    described_class.instance_variable_set(:@guard, nil)
    example.run
  ensure
    liveness.each_value { |io| io.close unless io.closed? }
    described_class.instance_variable_set(:@guard, nil)
  end

  def process_adapter(parent: parent_pid, group: pgid)
    Struct.new(:parent_pid, :process_group_id).new(parent, group)
  end

  def contract(overrides = {})
    {
      "version" => 2,
      "liveness_fd" => liveness.fetch(:reader).fileno,
      "parent_pid" => parent_pid,
      "pgid" => pgid,
      "repo" => repo,
      "target" => target,
      "release_version" => "17.1.0.rc.0",
      "branch" => branch
    }.merge(overrides)
  end

  def activate_live(contract_overrides: {}, adapter: process_adapter)
    described_class.activate!(
      dry_run: false,
      env: { described_class::CONTRACT_ENV => JSON.generate(contract(contract_overrides)) },
      process_adapter: adapter,
      liveness_io: liveness.fetch(:reader)
    )
  end

  it "refuses direct live activation without a wrapper contract" do
    expect do
      described_class.activate!(dry_run: false, env: {}, process_adapter:)
    end.to raise_error(described_class::LeaseError, /wrapper contract is required/)

    expect(described_class).not_to be_active
  end

  it "fences live release writes using only the local supervisor contract" do
    expect(activate_live).to be(true)
    expect(described_class.fence!).to be(true)
    expect(described_class).to be_active
  end

  it "accepts a stable release from main" do
    expect(
      activate_live(contract_overrides: { "release_version" => "17.1.0", "branch" => "main" })
    ).to be(true)
  end

  it "rejects a prerelease contract on main" do
    expect { activate_live(contract_overrides: { "branch" => "main" }) }
      .to raise_error(described_class::LeaseError, /wrapper contract is invalid/)
  end

  it "rejects a release version outside the contract target base" do
    expect { activate_live(contract_overrides: { "release_version" => "17.2.0.rc.0" }) }
      .to raise_error(described_class::LeaseError, /wrapper contract is invalid/)
  end

  it "rejects a different parent process" do
    expect { activate_live(adapter: process_adapter(parent: parent_pid + 1)) }
      .to raise_error(described_class::LeaseError, /parent process/)
  end

  it "rejects a different process group" do
    expect { activate_live(adapter: process_adapter(group: pgid + 1)) }
      .to raise_error(described_class::LeaseError, /process group/)
  end

  it "rejects a closed supervisor liveness channel" do
    liveness.fetch(:writer).close

    expect { activate_live }
      .to raise_error(described_class::LeaseError, /liveness channel is closed/)
  end

  it "rejects unexpected supervisor liveness data" do
    liveness.fetch(:writer).write("x")

    expect { activate_live }
      .to raise_error(described_class::LeaseError, /unexpected data/)
  end

  it "allows dry-run activation without a live wrapper contract" do
    expect(described_class.activate!(dry_run: true, env: {})).to be(true)
    expect(described_class.fence!).to be(true)
  end
end
