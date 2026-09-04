# frozen_string_literal: true

require "json"
require "time"
require_relative "../../../../rakelib/release_atomic_claim"

RSpec.describe ReleaseAtomicClaim::Client do
  let(:response_class) { Data.define(:code, :body) }
  let(:requests) { [] }
  let(:responses) { [] }
  let(:transport) do
    lambda do |**request|
      requests << request
      responses.shift || raise("missing fake response")
    end
  end
  let(:client) do
    described_class.new(
      base_url: "https://coord.example.test",
      token: "secret-token",
      transport:
    )
  end
  let(:claim_args) do
    {
      repo: "shakacode/react_on_rails",
      target: "release-line:17.1.0",
      agent_id: "release-17.1.0-uuid",
      instance_id: "uuid",
      machine_id: "release-machine",
      branch: "release/17.1.0",
      ttl: 14_400,
      now: Time.utc(2026, 8, 25, 6, 30, 0)
    }
  end

  it "creates an absent claim with a create-only conditional write" do
    responses.push(
      response_class.new(code: "404", body: '{"error":"not_found"}'),
      response_class.new(code: "201", body: "{}")
    )

    expect(client.acquire!(**claim_args)).to be(true)

    put = requests.fetch(1)
    expect(put.fetch(:headers)).to include("If-None-Match" => "*")
    expect(put.fetch(:headers)).not_to have_key("If-Match")
    payload = JSON.parse(put.fetch(:body)).fetch("data")
    expect(payload).to include(
      "status" => "active",
      "agent_id" => "release-17.1.0-uuid",
      "instance_id" => "uuid",
      "machine_id" => "release-machine",
      "expires_at" => "2026-08-25T10:30:00Z"
    )
  end

  it "replaces only an exactly versioned released claim" do
    responses.push(
      response_class.new(
        code: "200",
        body: '{"version":"claim-v7","data":{"status":"released"}}'
      ),
      response_class.new(code: "200", body: "{}")
    )

    expect(client.acquire!(**claim_args)).to be(true)
    expect(requests.fetch(1).fetch(:headers)).to include("If-Match" => "claim-v7")
  end

  it "refuses every active claim without attempting a write" do
    responses << response_class.new(
      code: "200",
      body: '{"version":8,"data":{"status":"active","agent_id":"foreign"}}'
    )

    expect { client.acquire!(**claim_args) }.to raise_error(ReleaseAtomicClaim::ClaimRefused)
    expect(requests.length).to eq(1)
  end

  it "maps a conditional-write conflict to claim refusal" do
    responses.push(
      response_class.new(code: "404", body: '{"error":"not_found"}'),
      response_class.new(code: "409", body: '{"error":"conflict"}')
    )

    expect { client.acquire!(**claim_args) }.to raise_error(ReleaseAtomicClaim::ClaimRefused)
  end

  it "renews only the exact active identity with an exact-version conditional write" do
    responses.push(
      response_class.new(
        code: "200",
        body: JSON.generate(
          "version" => 9,
          "data" => {
            "status" => "active",
            "repo" => "shakacode/react_on_rails",
            "target" => "release-line:17.1.0",
            "agent_id" => "release-17.1.0-uuid",
            "instance_id" => "uuid",
            "machine_id" => "release-machine",
            "branch" => "release/17.1.0",
            "claimed_at" => "2026-08-25T05:30:00Z"
          }
        )
      ),
      response_class.new(code: "200", body: "{}")
    )

    expect(client.renew!(**claim_args)).to be(true)

    put = requests.fetch(1)
    expect(put.fetch(:headers)).to include("If-Match" => "9")
    payload = JSON.parse(put.fetch(:body)).fetch("data")
    expect(payload).to include(
      "claimed_at" => "2026-08-25T05:30:00Z",
      "updated_at" => "2026-08-25T06:30:00Z",
      "expires_at" => "2026-08-25T10:30:00Z"
    )
  end

  it "refuses to renew a claim whose exact identity changed" do
    responses << response_class.new(
      code: "200",
      body: JSON.generate(
        "version" => 10,
        "data" => {
          "status" => "active",
          "repo" => "shakacode/react_on_rails",
          "target" => "release-line:17.1.0",
          "agent_id" => "foreign",
          "instance_id" => "foreign",
          "machine_id" => "release-machine",
          "branch" => "release/17.1.0"
        }
      )
    )

    expect { client.renew!(**claim_args) }.to raise_error(ReleaseAtomicClaim::ClaimRefused)
    expect(requests.length).to eq(1)
  end

  it "maps a renewal conditional-write conflict to claim refusal" do
    claim_data = {
      "status" => "active",
      "repo" => "shakacode/react_on_rails",
      "target" => "release-line:17.1.0",
      "agent_id" => "release-17.1.0-uuid",
      "instance_id" => "uuid",
      "machine_id" => "release-machine",
      "branch" => "release/17.1.0"
    }
    responses.push(
      response_class.new(code: "200", body: JSON.generate("version" => 11, "data" => claim_data)),
      response_class.new(code: "409", body: '{"error":"conflict"}')
    )

    expect { client.renew!(**claim_args) }.to raise_error(ReleaseAtomicClaim::ClaimRefused)
  end

  it "releases only the exact active identity with an exact-version conditional write" do
    claim_data = {
      "status" => "active",
      "repo" => "shakacode/react_on_rails",
      "target" => "release-line:17.1.0",
      "agent_id" => "release-17.1.0-uuid",
      "instance_id" => "uuid",
      "machine_id" => "release-machine",
      "branch" => "release/17.1.0"
    }
    responses.push(
      response_class.new(code: "200", body: JSON.generate("version" => 12, "data" => claim_data)),
      response_class.new(code: "200", body: "{}")
    )

    expect(client.release!(**claim_args.slice(:repo, :target, :agent_id, :instance_id, :now))).to be(true)

    put = requests.fetch(1)
    expect(put.fetch(:headers)).to include("If-Match" => "12")
    payload = JSON.parse(put.fetch(:body)).fetch("data")
    expect(payload).to include(
      "status" => "released",
      "agent_id" => "release-17.1.0-uuid",
      "instance_id" => "uuid",
      "released_at" => "2026-08-25T06:30:00Z"
    )
  end

  it "treats an already-released exact identity as a successful retry" do
    responses << response_class.new(
      code: "200",
      body: JSON.generate(
        "version" => 13,
        "data" => {
          "status" => "released",
          "repo" => "shakacode/react_on_rails",
          "target" => "release-line:17.1.0",
          "agent_id" => "release-17.1.0-uuid",
          "instance_id" => "uuid"
        }
      )
    )

    release_args = claim_args.slice(:repo, :target, :agent_id, :instance_id, :now)
    expect(client.release!(**release_args)).to be(true)
    expect(requests.length).to eq(1)
  end

  it "refuses to release a replacement claim with the same agent and a new instance" do
    responses << response_class.new(
      code: "200",
      body: JSON.generate(
        "version" => 13,
        "data" => {
          "status" => "active",
          "repo" => "shakacode/react_on_rails",
          "target" => "release-line:17.1.0",
          "agent_id" => "release-17.1.0-uuid",
          "instance_id" => "replacement-uuid"
        }
      )
    )

    release_args = claim_args.slice(:repo, :target, :agent_id, :instance_id, :now)
    expect { client.release!(**release_args) }.to raise_error(ReleaseAtomicClaim::ClaimRefused)
    expect(requests.length).to eq(1)
  end

  it "maps a release conditional-write conflict to claim refusal" do
    claim_data = {
      "status" => "active",
      "repo" => "shakacode/react_on_rails",
      "target" => "release-line:17.1.0",
      "agent_id" => "release-17.1.0-uuid",
      "instance_id" => "uuid"
    }
    responses.push(
      response_class.new(code: "200", body: JSON.generate("version" => 14, "data" => claim_data)),
      response_class.new(code: "409", body: '{"error":"conflict"}')
    )

    release_args = claim_args.slice(:repo, :target, :agent_id, :instance_id, :now)
    expect { client.release!(**release_args) }.to raise_error(ReleaseAtomicClaim::ClaimRefused)
  end

  it "rejects malformed backend records without exposing the token" do
    responses << response_class.new(code: "200", body: '["secret-token"]')

    expect { client.acquire!(**claim_args) }
      .to raise_error(ReleaseAtomicClaim::Error) { |error| expect(error.message).not_to include("secret-token") }
  end

  it "requires HTTPS for non-loopback coordination backends" do
    expect do
      described_class.new(base_url: "http://coord.example.test", token: "secret-token", transport:)
    end.to raise_error(ReleaseAtomicClaim::Error, /HTTPS/)
  end
end
