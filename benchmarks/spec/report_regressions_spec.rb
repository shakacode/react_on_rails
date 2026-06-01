# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../report_regressions"
require "open3"
require "tmpdir"
require "fileutils"

RSpec.describe "benchmark regression reporting" do
  # These specs pin the error-handling contract of RegressionIssueReporter, which
  # shells out to `gh` and must distinguish two outcomes that both used to collapse
  # to "": a `gh` *failure* (GithubCli.capture_success returns nil) versus a
  # successful lookup that simply found *nothing* (""). The former must abort so the
  # job fails loudly; the latter is the normal "create it" path. They also pin the
  # `gh issue create` URL parsing (that command has no --json/--jq).
  describe RegressionIssueReporter do
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
    let(:posted_bodies) { {} }

    before do
      allow(GithubCli).to receive(:capture_success) do |*args, **_kwargs|
        key = capture_key(args)
        calls << key
        capture_responses.fetch(key) { raise "unexpected capture_success: #{key}" }
      end

      allow(GithubCli).to receive(:run) do |*args, **kwargs|
        key = run_key(args)
        calls << key
        posted_bodies[key] = extract_body(args, kwargs)
        run_responses[key]
      end
    end

    # The comment body is passed as `--body <body>` (create) or, for PATCH, as a
    # JSON `{ "body": ... }` payload over stdin (--input -).
    def extract_body(args, kwargs)
      if (index = args.index("--body"))
        args[index + 1]
      elsif kwargs[:stdin_data]
        JSON.parse(kwargs[:stdin_data]).fetch("body")
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
      # Existing comment already has another suite's section plus a stale section
      # for this run's suite ("core"), so the upsert must replace core in place.
      let(:existing_body) do
        <<~BODY
          ## header
          #{section_for('pro', 'pro stuff')}
          #{section_for('core', 'OLD core data')}
        BODY
      end

      before do
        capture_responses["issue list"] = "77\n"
        capture_responses["comment list"] = "555\n"
        capture_responses["comment body"] = existing_body
      end

      it "updates the existing comment instead of creating a new issue" do
        expect(report).to eq("77")
        expect(calls).to include("comment patch")
        expect(calls).not_to include("issue create")
      end

      it "replaces this suite's section in place, preserving the header and other suites" do
        report
        body = posted_bodies.fetch("comment patch")

        expect(body).to include("## header")                        # header preserved
        expect(body).to include(section_for("pro", "pro stuff"))    # other suite preserved
        expect(body).to include("core regressed")                   # new core content written
        expect(body).not_to include("OLD core data")                # stale core content replaced
        expect(body.scan("<!-- BENCHMARK_REGRESSION_SECTION core -->").size).to eq(1) # not duplicated
      end

      # Mirrors the section markers the reporter writes, so upsert has an existing
      # body to merge into rather than starting from scratch.
      def section_for(suite, content = "")
        "<!-- BENCHMARK_REGRESSION_SECTION #{suite} -->\n#{content}\n<!-- /BENCHMARK_REGRESSION_SECTION #{suite} -->"
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

  # These drive the script end-to-end as a subprocess with a fake `gh` on PATH (no
  # network), pinning the artifact scan, the per-suite shard combining, and the
  # exit status.
  describe "report_regressions.rb (script)" do
    script = File.expand_path("../report_regressions.rb", __dir__)

    # Minimal `gh` stand-in: `issue create` prints a new-issue URL (the script
    # parses the number from it); every other subcommand (label create, issue list,
    # api, issue comment) succeeds with empty output, i.e. "no existing issue/comment".
    fake_gh = <<~BASH
      #!/usr/bin/env bash
      if [ "$1" = "issue" ] && [ "$2" = "create" ]; then
        echo "https://github.com/shakacode/react_on_rails/issues/7"
      fi
      exit 0
    BASH

    def run_script(script, artifacts_dir, gh_stub:)
      Dir.mktmpdir do |bin_dir|
        File.write(File.join(bin_dir, "gh"), gh_stub)
        File.chmod(0o755, File.join(bin_dir, "gh"))

        env = {
          "PATH" => "#{bin_dir}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH')}",
          "GITHUB_SHA" => "abcdef1234567890",
          "GITHUB_SERVER_URL" => "https://github.com",
          "GITHUB_REPOSITORY" => "shakacode/react_on_rails",
          "GITHUB_RUN_ID" => "999",
          "GITHUB_RUN_NUMBER" => "42",
          "GITHUB_ACTOR" => "octocat"
        }
        Open3.capture2e(env, "ruby", script, artifacts_dir)
      end
    end

    def write_payload(dir, artifact:, suite:, shard_label: "1/1", summary: nil)
      artifact_dir = File.join(dir, artifact)
      FileUtils.mkdir_p(artifact_dir)
      File.write(
        File.join(artifact_dir, RegressionReport::FILENAME),
        JSON.generate(suite_name: suite, shard_label: shard_label,
                      summary: summary || "#{suite} #{shard_label} regressed")
      )
    end

    it "exits 0 and reports nothing when no payloads are present" do
      Dir.mktmpdir do |dir|
        output, status = run_script(script, dir, gh_stub: fake_gh)
        expect(status).to be_success
        expect(output).to match(/No benchmark regressions/)
      end
    end

    it "files one report per suite for distinct suites (nested arbitrarily deep)" do
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-core", suite: "Core")
        write_payload(dir, artifact: "regression-pro", suite: "Pro")

        output, status = run_script(script, dir, gh_stub: fake_gh)
        expect(status).to be_success
        expect(output).to match(/Filing regression report for Core \(1 shard report\(s\)\)/)
        expect(output).to match(/Filing regression report for Pro \(1 shard report\(s\)\)/)
        expect(output).to match(/issue #7/)
      end
    end

    it "combines a sharded suite's payloads into a single report" do
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-pro-shard-1", suite: "Pro", shard_label: "1/2")
        write_payload(dir, artifact: "regression-pro-shard-2", suite: "Pro", shard_label: "2/2")

        output, status = run_script(script, dir, gh_stub: fake_gh)
        expect(status).to be_success
        expect(output).to match(/Filing regression report for Pro \(2 shard report\(s\)\)/)
        expect(output.scan("Filing regression report for Pro").size).to eq(1)
      end
    end

    it "exits non-zero when filing an issue fails" do
      failing_gh = "#!/usr/bin/env bash\nexit 1\n"
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-core", suite: "Core")
        output, status = run_script(script, dir, gh_stub: failing_gh)
        expect(status).not_to be_success
        expect(output).to match(/Failed to file regression issue for Core/)
      end
    end

    it "reports valid payloads but still fails when one payload is corrupt" do
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-core", suite: "Core")
        corrupt = File.join(dir, "regression-pro")
        FileUtils.mkdir_p(corrupt)
        File.write(File.join(corrupt, RegressionReport::FILENAME), "{ not valid json")

        output, status = run_script(script, dir, gh_stub: fake_gh)
        expect(status).not_to be_success
        expect(output).to match(/Filing regression report for Core/)
        expect(output).to match(%r{::error::Failed to read regression payload .*/regression-pro/regression\.json})
      end
    end
  end
end
