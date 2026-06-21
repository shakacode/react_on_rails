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
      allow(GithubCli).to receive(:capture_success) do |*args, **kwargs|
        key = capture_key(args)
        calls << key
        posted_bodies[key] = extract_body(args, kwargs)
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
      return "comment create" if args[1..3] == %w[api -X POST]
      return "comment list" if args[1] == "api" && args[2].match?(%r{/issues/\d+/comments\z})
      return "comment body" if args[1] == "api" && args[2].match?(%r{/issues/comments/\d+\z})

      raise "unrecognized capture_success args: #{args.inspect}"
    end

    def run_key(args)
      return "label create" if args[1..2] == %w[label create]
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

    def report_with_cache(suite_name, issue_number_cache, report_comment_id_cache = nil)
      described_class.report(
        summary: "#{suite_name} regressed",
        suite_name:,
        github_run_url: "https://github.com/run/1",
        bencher_url: "https://bencher.dev/dash",
        issue_number_cache:,
        report_comment_id_cache:
      )
    end

    context "when no regression issue exists yet" do
      before do
        capture_responses["issue list"] = ""
        capture_responses["issue create"] = "https://github.com/shakacode/react_on_rails/issues/123\n"
        capture_responses["comment list"] = ""
        capture_responses["comment create"] = "999\n"
      end

      it "creates the issue, parses the number from the URL, and posts the first comment" do
        expect(report).to eq("123")
        expect(calls).to eq(["label create", "issue list", "issue create", "comment list", "comment create"])
      end

      it "names the confirmed benchmark+measure pairs in the created issue body" do
        described_class.report(
          summary: "core regressed",
          suite_name: "core",
          github_run_url: "https://github.com/run/1",
          bencher_url: "https://bencher.dev/dash",
          regressed_overview: "- `/x: Core` — **rps**"
        )
        body = posted_bodies.fetch("issue create")
        expect(body).to include("### What regressed")
        expect(body).to include("- `/x: Core` — **rps**")
      end

      it "omits the what-regressed section when no pairs were handed off" do
        report
        expect(posted_bodies.fetch("issue create")).not_to include("What regressed")
      end

      it "reuses a just-created issue number for later suites in the same reporter run" do
        issue_number_cache = {}

        expect(report_with_cache("Core", issue_number_cache)).to eq("123")
        expect(report_with_cache("Pro", issue_number_cache)).to eq("123")

        expect(calls.count("issue list")).to eq(1)
        expect(calls.count("issue create")).to eq(1)
      end

      it "reuses a just-created report comment for later suites in the same reporter run" do
        issue_number_cache = {}
        report_comment_id_cache = {}
        capture_responses["comment body"] = "Core regressed"

        expect(report_with_cache("Core", issue_number_cache, report_comment_id_cache)).to eq("123")
        expect(report_with_cache("Pro", issue_number_cache, report_comment_id_cache)).to eq("123")

        expect(calls.count("comment list")).to eq(1)
        expect(calls.count("comment create")).to eq(1)
        expect(calls).to include("comment patch")
        expect(posted_bodies.fetch("comment patch")).to include("Core regressed")
        expect(posted_bodies.fetch("comment patch")).to include("Pro regressed")
      end

      it "does not create duplicate same-run comments after a comment id parse miss" do
        issue_number_cache = {}
        report_comment_id_cache = {}
        capture_responses["comment create"] = "\n"

        expect(report_with_cache("Core", issue_number_cache, report_comment_id_cache)).to eq("")
        expect(report_with_cache("Pro", issue_number_cache, report_comment_id_cache)).to eq("")

        expect(calls.count("comment list")).to eq(1)
        expect(calls.count("comment create")).to eq(1)
        expect(calls).not_to include("comment patch")
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
        expect(calls).not_to include("comment create")
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

    context "when issue creation succeeds but gh output does not include an issue URL" do
      before do
        capture_responses["issue list"] = ""
        capture_responses["issue create"] = "Created issue without a parseable URL\n"
      end

      it "emits the parse warning to stdout so GitHub Actions annotates it" do
        expect { expect(report).to eq("") }
          .to output(/::warning::Created the issue but could not parse its number/).to_stdout
          .and output("").to_stderr
        expect(calls).not_to include("comment list")
      end

      it "does not create duplicate same-run issues after the parse miss" do
        issue_number_cache = {}

        expect(report_with_cache("Core", issue_number_cache)).to eq("")
        expect(report_with_cache("Pro", issue_number_cache)).to eq("")

        expect(calls.count("issue list")).to eq(1)
        expect(calls.count("issue create")).to eq(1)
      end
    end
  end

  # These drive the script end-to-end as a subprocess with a fake `gh` on PATH (no
  # network), pinning the confirmed-artifact scan, the per-suite shard combining, the
  # first-run/confirmation evidence rendering, and the exit status. A confirmed
  # regression fails the workflow (exit 1) even though the issue was filed successfully —
  # this job owns the final pass/fail.
  describe "regressed_overview_markdown" do
    it "renders deduped benchmark+measure bullets from each payload's ALERTS" do
      payloads = [
        { RegressionReport::ALERTS => [
          { RegressionReport::ALERT_BENCHMARK => "/a: Core", RegressionReport::ALERT_MEASURE => "rps" },
          { RegressionReport::ALERT_BENCHMARK => "/a: Core", RegressionReport::ALERT_MEASURE => "rps" }
        ] },
        { RegressionReport::ALERTS => [
          { RegressionReport::ALERT_BENCHMARK => "/b: Pro", RegressionReport::ALERT_MEASURE => nil }
        ] }
      ]
      expect(regressed_overview_markdown(payloads)).to eq("- `/a: Core` — **rps**\n- `/b: Pro`")
    end

    it "is empty when no payload carries structured alert pairs" do
      expect(regressed_overview_markdown([{ RegressionReport::SUITE_NAME => "Core" }])).to eq("")
    end
  end

  describe "report_regressions.rb (script)" do
    script = File.expand_path("../report_regressions.rb", __dir__)

    # Minimal `gh` stand-in: `issue create` prints a new-issue URL (the script
    # parses the number from it); every other subcommand (label create, issue list,
    # api, issue comment) succeeds with empty output, i.e. "no existing issue/comment".
    fake_gh = <<~BASH
      #!/usr/bin/env bash
      if [ "$1" = "issue" ] && [ "$2" = "create" ]; then
        echo "https://github.com/shakacode/react_on_rails/issues/7"
      elif [ "$1" = "api" ] && [ "$2" = "-X" ] && [ "$3" = "POST" ]; then
        echo "777"
      fi
      exit 0
    BASH

    def run_script(script, artifacts_dir, gh_stub:, extra_env: {})
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
        }.merge(extra_env)
        Open3.capture2e(env, "ruby", script, artifacts_dir)
      end
    end

    # Writes a CONFIRMED regression payload (the only thing report_regressions consumes
    # now). first_run/confirmation default to recognizable strings so the side-by-side
    # rendering can be asserted.
    def write_payload(dir, artifact:, suite:, shard_label: "1/1", first_run: nil, confirmation: nil)
      artifact_dir = File.join(dir, artifact)
      FileUtils.mkdir_p(artifact_dir)
      payload = {
        RegressionReport::SUITE_NAME => suite,
        RegressionReport::SHARD_LABEL => shard_label,
        RegressionReport::FIRST_RUN_SUMMARY => first_run || "#{suite} #{shard_label} first run",
        RegressionReport::CONFIRMATION_SUMMARY => confirmation || "#{suite} #{shard_label} confirmation",
        RegressionReport::REGRESSED_BENCHMARKS => ["/x: #{suite}"]
      }
      File.write(File.join(artifact_dir, RegressionReport::CONFIRMED_FILENAME), JSON.generate(payload))
    end

    it "exits 0 and reports nothing when no confirmed payloads are present" do
      Dir.mktmpdir do |dir|
        output, status = run_script(script, dir, gh_stub: fake_gh)
        expect(status).to be_success
        expect(output).to match(/No confirmed benchmark regressions/)
      end
    end

    it "files one report per suite for distinct suites (nested arbitrarily deep) and fails the run" do
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-confirmed-core", suite: "Core")
        write_payload(dir, artifact: "regression-confirmed-pro", suite: "Pro")

        output, status = run_script(script, dir, gh_stub: fake_gh)
        # A confirmed regression fails the workflow even though filing succeeded.
        expect(status).not_to be_success
        expect(output).to match(/Filing confirmed regression report for Core \(1 shard report\(s\)\)/)
        expect(output).to match(/Filing confirmed regression report for Pro \(1 shard report\(s\)\)/)
        expect(output).to match(/issue #7/)
        expect(output).to match(/Confirmed benchmark regression/)
      end
    end

    it "creates only one issue for multiple suites even when live issue lookup stays empty" do
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-confirmed-core", suite: "Core")
        write_payload(dir, artifact: "regression-confirmed-pro", suite: "Pro")

        call_log = File.join(dir, "gh-calls.log")
        counting_gh = <<~BASH
          #!/usr/bin/env bash
          printf '%s\\n' "$*" >> "$GH_CALL_LOG"
          if [ "$1" = "issue" ] && [ "$2" = "create" ]; then
            echo "https://github.com/shakacode/react_on_rails/issues/7"
          elif [ "$1" = "api" ] && [ "$2" = "-X" ] && [ "$3" = "POST" ]; then
            echo "777"
          fi
          exit 0
        BASH

        output, _status = run_script(script, dir, gh_stub: counting_gh, extra_env: { "GH_CALL_LOG" => call_log })

        expect(output).to match(/issue #7/)
        expect(File.readlines(call_log).count { |line| line.start_with?("issue create") }).to eq(1)
        expect(File.readlines(call_log).count { |line| line.start_with?("api -X POST") }).to eq(1)
      end
    end

    it "renders the first-run and confirmation summaries side by side" do
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-confirmed-core", suite: "Core",
                           first_run: "FIRST RUN TABLE", confirmation: "CONFIRMATION TABLE")

        posted = File.join(dir, "posted-body.txt")
        capturing_gh = <<~BASH
          #!/usr/bin/env bash
          if [ "$1" = "issue" ] && [ "$2" = "create" ]; then
            echo "https://github.com/shakacode/react_on_rails/issues/7"
          elif [ "$1" = "api" ] && [ "$2" = "-X" ] && [ "$3" = "POST" ]; then
            cat > "$POSTED_BODY"
            echo "777"
          fi
          exit 0
        BASH

        run_script(script, dir, gh_stub: capturing_gh, extra_env: { "POSTED_BODY" => posted })
        body = JSON.parse(File.read(posted)).fetch("body")
        expect(body).to include("First run").and include("FIRST RUN TABLE")
        expect(body).to include("Confirmation run").and include("CONFIRMATION TABLE")
      end
    end

    it "shares one issue-number cache across suite reports in the same run" do
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-confirmed-core", suite: "Core")
        write_payload(dir, artifact: "regression-confirmed-pro", suite: "Pro")

        caches = []
        allow(Github).to receive(:run_url).and_return("https://github.com/run/1")
        allow(RegressionIssueReporter).to receive(:report) do |issue_number_cache:, **_attributes|
          caches << issue_number_cache
          issue_number_cache["created"] = "7"
          "7"
        end

        expect(report_regressions(dir)).to eq(:filed)
        expect(caches.size).to eq(2)
        expect(caches[0]).to equal(caches[1])
      end
    end

    it "combines a sharded suite's payloads into a single report" do
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-confirmed-pro-shard-1", suite: "Pro", shard_label: "1/2")
        write_payload(dir, artifact: "regression-confirmed-pro-shard-2", suite: "Pro", shard_label: "2/2")

        output, status = run_script(script, dir, gh_stub: fake_gh)
        expect(status).not_to be_success
        expect(output).to match(/Filing confirmed regression report for Pro \(2 shard report\(s\)\)/)
        expect(output.scan("Filing confirmed regression report for Pro").size).to eq(1)
      end
    end

    it "exits non-zero when filing an issue fails" do
      failing_gh = "#!/usr/bin/env bash\nexit 1\n"
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-confirmed-core", suite: "Core")
        output, status = run_script(script, dir, gh_stub: failing_gh)
        expect(status).not_to be_success
        expect(output).to match(/Failed to file regression issue for Core/)
      end
    end

    it "reports valid payloads but still fails when one payload is corrupt" do
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-confirmed-core", suite: "Core")
        corrupt = File.join(dir, "regression-confirmed-pro")
        FileUtils.mkdir_p(corrupt)
        File.write(File.join(corrupt, RegressionReport::CONFIRMED_FILENAME), "{ not valid json")

        output, status = run_script(script, dir, gh_stub: fake_gh)
        expect(status).not_to be_success
        expect(output).to match(/Filing confirmed regression report for Core/)
        expect(output).to match(
          %r{::error::Failed to read confirmed regression payload .*/regression-confirmed-pro/}
        )
      end
    end

    it "reports valid payloads but still fails when one payload has the wrong JSON shape" do
      Dir.mktmpdir do |dir|
        write_payload(dir, artifact: "regression-confirmed-core", suite: "Core")
        invalid = File.join(dir, "regression-confirmed-pro")
        FileUtils.mkdir_p(invalid)
        File.write(File.join(invalid, RegressionReport::CONFIRMED_FILENAME), JSON.generate(%w[not a hash]))

        output, status = run_script(script, dir, gh_stub: fake_gh)
        expect(status).not_to be_success
        expect(output).to match(/Filing confirmed regression report for Core/)
        expect(output).to match(
          %r{::error::Failed to read confirmed regression payload .*/regression-confirmed-pro/}
        )
      end
    end
  end
end
