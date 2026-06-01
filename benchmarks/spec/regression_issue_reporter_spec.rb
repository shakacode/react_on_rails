# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/regression_issue_reporter"

# These specs pin the error-handling contract of RegressionIssueReporter, which
# shells out to `gh` and must distinguish two outcomes that both used to collapse
# to "": a `gh` *failure* (GithubCli.capture_success returns nil) versus a
# successful lookup that simply found *nothing* (""). The former must abort so the
# job fails loudly; the latter is the normal "create it" path. They also pin the
# `gh issue create` URL parsing (that command has no --json/--jq).
RSpec.describe RegressionIssueReporter do
  def stub_env
    {
      "GITHUB_SHA" => "abcdef1234567890",
      "GITHUB_SERVER_URL" => "https://github.com",
      "GITHUB_REPOSITORY" => "shakacode/react_on_rails",
      "GITHUB_RUN_NUMBER" => "42",
      "GITHUB_ACTOR" => "octocat"
    }
  end

  around do |example|
    snapshot = ENV.to_h
    stub_env.each { |key, value| ENV[key] = value }
    example.run
  ensure
    ENV.replace(snapshot)
  end

  # Records every `gh` invocation by its subcommand (e.g. "issue create") and
  # returns canned responses so each example can simulate success/failure/empty
  # without touching the network. capture_success returns a String on success or
  # nil on failure; run returns a boolean.
  let(:calls) { [] }
  let(:capture_responses) { {} }
  let(:run_responses) { Hash.new(true) }

  before do
    allow(GithubCli).to receive(:capture_success) do |*args, **_kwargs|
      key = capture_key(args)
      calls << key
      capture_responses.fetch(key) { raise "unexpected capture_success: #{key}" }
    end

    allow(GithubCli).to receive(:run) do |*args, **_kwargs|
      key = run_key(args)
      calls << key
      run_responses[key]
    end
  end

  def capture_key(args)
    return "issue list" if args[1..2] == %w[issue list]
    return "issue create" if args[1..2] == %w[issue create]
    return "comment list" if args[1] == "api" && args[2].match?(%r{/issues/\d+/comments\z})
    return "comment body" if args[1] == "api" && args[2].match?(%r{/issues/comments/\d+\z})

    raise "unrecognized capture_success args: #{args.inspect}"
  end

  def run_key(args)
    return "label create" if args[1..2] == %w[label create]
    return "issue comment" if args[1..2] == %w[issue comment]
    return "comment patch" if args[1..3] == %w[api -X PATCH]

    raise "unrecognized run args: #{args.inspect}"
  end

  def report
    described_class.report(
      summary: "core regressed",
      suite_name: "core",
      github_run_url: "https://github.com/run/1",
      bencher_url: "https://bencher.dev/dash"
    )
  end

  context "when no regression issue exists yet" do
    before do
      capture_responses["issue list"] = ""
      capture_responses["issue create"] = "https://github.com/shakacode/react_on_rails/issues/123\n"
      capture_responses["comment list"] = ""
    end

    it "creates the issue, parses the number from the URL, and posts the first comment" do
      expect(report).to eq("123")
      expect(calls).to eq(["label create", "issue list", "issue create", "comment list", "issue comment"])
    end
  end

  context "when an open regression issue already exists" do
    before do
      capture_responses["issue list"] = "77\n"
      capture_responses["comment body"] = "header\n#{section_for('pro')}"
      capture_responses["comment list"] = "555\n"
    end

    it "updates the existing comment instead of creating a new issue" do
      expect(report).to eq("77")
      expect(calls).to include("comment patch")
      expect(calls).not_to include("issue create")
    end

    # Helper mirrors the section markers the reporter writes, so upsert has an
    # existing body to merge into rather than starting from scratch.
    def section_for(suite)
      "<!-- BENCHMARK_REGRESSION_SECTION #{suite} -->\n<!-- /BENCHMARK_REGRESSION_SECTION #{suite} -->"
    end
  end

  context "when `gh issue list` fails" do
    before { capture_responses["issue list"] = nil }

    it "aborts without creating a duplicate issue" do
      expect(report).to eq("")
      expect(calls).not_to include("issue create")
    end
  end

  context "when the comment lookup fails" do
    before do
      capture_responses["issue list"] = "77\n"
      capture_responses["comment list"] = nil
    end

    it "aborts without posting a duplicate comment" do
      expect(report).to eq("")
      expect(calls).not_to include("issue comment")
      expect(calls).not_to include("comment patch")
    end
  end

  context "when fetching the existing comment body fails" do
    before do
      capture_responses["issue list"] = "77\n"
      capture_responses["comment list"] = "555\n"
      capture_responses["comment body"] = nil
    end

    it "aborts without rewriting (and clobbering) the comment" do
      expect(report).to eq("")
      expect(calls).not_to include("comment patch")
    end
  end

  context "when issue creation fails" do
    before do
      capture_responses["issue list"] = ""
      capture_responses["issue create"] = nil
    end

    it "returns empty so the caller fails the job" do
      expect(report).to eq("")
      expect(calls).not_to include("comment list")
    end
  end
end
