# frozen_string_literal: true

require_relative "simplecov_helper"
require_relative "spec_helper"
require "stringio"
require "tmpdir"

RSpec.describe "release.rake helper methods" do
  def capture_stdout
    original_stdout = $stdout
    output = StringIO.new
    $stdout = output
    yield
    output.string
  ensure
    $stdout = original_stdout
  end

  before do
    next if Object.instance_variable_defined?(:@release_rake_helpers_loaded)

    load File.expand_path("../../../rakelib/release.rake", __dir__)
    Object.instance_variable_set(:@release_rake_helpers_loaded, true)
  end

  describe "#parse_release_tag_to_gem_version" do
    it "parses stable tag versions" do
      expect(parse_release_tag_to_gem_version("v16.4.0")).to eq("16.4.0")
    end

    it "parses dotted prerelease tag versions" do
      expect(parse_release_tag_to_gem_version("v16.4.0.rc.1")).to eq("16.4.0.rc.1")
    end

    it "parses dashed prerelease tag versions" do
      expect(parse_release_tag_to_gem_version("v16.4.0-rc.1")).to eq("16.4.0.rc.1")
    end
  end

  describe "#version_bump_type" do
    it "detects major bumps" do
      bump_type = version_bump_type(previous_stable_gem_version: "16.3.0", target_gem_version: "17.0.0")
      expect(bump_type).to eq(:major)
    end

    it "detects minor bumps" do
      bump_type = version_bump_type(previous_stable_gem_version: "16.3.0", target_gem_version: "16.4.0")
      expect(bump_type).to eq(:minor)
    end

    it "detects patch bumps" do
      bump_type = version_bump_type(previous_stable_gem_version: "16.3.0", target_gem_version: "16.3.1")
      expect(bump_type).to eq(:patch)
    end
  end

  describe "#compute_target_gem_version" do
    it "computes semver keyword bumps from the current version" do
      expect(compute_target_gem_version(current_gem_version: "16.3.4", version_input: "patch")).to eq("16.3.5")
      expect(compute_target_gem_version(current_gem_version: "16.3.4", version_input: "minor")).to eq("16.4.0")
      expect(compute_target_gem_version(current_gem_version: "16.3.4", version_input: "major")).to eq("17.0.0")
    end

    it "strips prerelease suffix on patch bumps from prerelease versions" do
      expect(compute_target_gem_version(current_gem_version: "16.5.0.rc.0", version_input: "patch")).to eq("16.5.0")
    end

    it "increments minor from prerelease base (use 'patch' to promote RC to stable)" do
      # 16.5.0.rc.0 + "minor" → 16.6.0, NOT 16.5.0
      # This matches gem-release behavior. To promote 16.5.0.rc.0 → 16.5.0, use "patch".
      expect(compute_target_gem_version(current_gem_version: "16.5.0.rc.0", version_input: "minor")).to eq("16.6.0")
    end

    it "increments major from prerelease base (use 'patch' to promote RC to stable)" do
      # 16.5.0.rc.0 + "major" → 17.0.0, NOT 16.5.0
      # This matches gem-release behavior. To promote 16.5.0.rc.0 → 16.5.0, use "patch".
      expect(compute_target_gem_version(current_gem_version: "16.5.0.rc.0", version_input: "major")).to eq("17.0.0")
    end

    it "passes through explicit versions unchanged" do
      expect(compute_target_gem_version(current_gem_version: "16.3.4",
                                        version_input: "16.4.0.rc.1")).to eq("16.4.0.rc.1")
    end
  end

  describe "#npm_dist_tag_for_version" do
    it "defaults stable releases to latest" do
      expect(npm_dist_tag_for_version("16.4.0")).to eq("latest")
    end

    it "extracts the prerelease channel for prerelease versions" do
      expect(npm_dist_tag_for_version("16.4.0-rc.1")).to eq("rc")
      expect(npm_dist_tag_for_version("16.4.0-beta.2")).to eq("beta")
    end
  end

  describe "#normalize_otp_code" do
    it "returns nil for nil input" do
      expect(normalize_otp_code(nil, service_name: "NPM")).to be_nil
    end

    it "strips valid numeric OTP values" do
      expect(normalize_otp_code(" 123456 ", service_name: "NPM")).to eq("123456")
    end

    it "rejects non-numeric OTP values" do
      expect do
        normalize_otp_code("12 34", service_name: "NPM")
      end.to raise_error(SystemExit, /Invalid OTP for NPM/)
    end
  end

  describe "#prompt_for_otp" do
    it "normalizes a submitted OTP" do
      allow($stdin).to receive(:gets).and_return(" 123456 \n")
      expect { expect(prompt_for_otp("RubyGems")).to eq("123456") }.to output(/Enter OTP code for RubyGems/).to_stdout
    end

    it "aborts when no OTP is entered and blanks are not allowed" do
      allow($stdin).to receive(:gets).and_return("\n")
      expect { prompt_for_otp("RubyGems") }.to raise_error(SystemExit, /No OTP provided/)
    end

    it "returns nil when blank input is allowed instead of aborting" do
      allow($stdin).to receive(:gets).and_return("\n")
      expect(prompt_for_otp("RubyGems", allow_blank: true)).to be_nil
    end

    it "includes the hint in the prompt when provided" do
      allow($stdin).to receive(:gets).and_return("123456\n")
      expect { prompt_for_otp("RubyGems", hint: "press Enter to skip") }
        .to output(/Enter OTP code for RubyGems \(press Enter to skip\)/).to_stdout
    end
  end

  describe "#resolve_rubygems_otp_for_publish" do
    it "returns the provided OTP without prompting" do
      expect(self).not_to receive(:prompt_for_otp)
      expect { expect(resolve_rubygems_otp_for_publish("123456")).to eq("123456") }
        .to output(/Using provided RubyGems OTP/).to_stdout
    end

    it "prompts once for the OTP when none is provided and stdin is a TTY" do
      allow($stdin).to receive(:tty?).and_return(true)
      allow(self).to receive(:prompt_for_otp)
        .with("RubyGems", allow_blank: true, hint: "press Enter to be prompted per gem")
        .and_return("654321")

      expect { expect(resolve_rubygems_otp_for_publish(nil)).to eq("654321") }
        .to output(/reused for both gems/).to_stdout
    end

    it "returns nil without prompting when stdin is not a TTY" do
      allow($stdin).to receive(:tty?).and_return(false)
      expect(self).not_to receive(:prompt_for_otp)

      expect { expect(resolve_rubygems_otp_for_publish(nil)).to be_nil }
        .to output(/Set RUBYGEMS_OTP environment variable/).to_stdout
    end

    it "returns nil when the operator submits a blank OTP (legacy per-gem prompting)" do
      allow($stdin).to receive(:tty?).and_return(true)
      allow(self).to receive(:prompt_for_otp)
        .with("RubyGems", allow_blank: true, hint: "press Enter to be prompted per gem")
        .and_return(nil)

      expect { expect(resolve_rubygems_otp_for_publish(nil)).to be_nil }
        .to output(/reused for both gems/).to_stdout
    end
  end

  describe "#expected_bump_type_from_changelog_section" do
    it "returns major for breaking changes" do
      section = <<~MARKDOWN
        ### [16.4.0] - 2026-03-08
        #### Breaking Changes
        - Something changed
      MARKDOWN
      expect(expected_bump_type_from_changelog_section(section)).to eq(:major)
    end

    it "returns minor for added sections" do
      section = <<~MARKDOWN
        ### [16.4.0] - 2026-03-08
        #### Added
        - New feature
      MARKDOWN
      expect(expected_bump_type_from_changelog_section(section)).to eq(:minor)
    end

    it "returns patch for fixed sections" do
      section = <<~MARKDOWN
        ### [16.4.0] - 2026-03-08
        #### Fixed
        - Bug fix
      MARKDOWN
      expect(expected_bump_type_from_changelog_section(section)).to eq(:patch)
    end
  end

  describe "#extract_changelog_section" do
    it "extracts the matching changelog section" do
      changelog = <<~CHANGELOG
        # Change Log

        ### [Unreleased]

        ### [16.4.0] - 2026-03-08
        #### Added
        - Feature A

        ### [16.3.0] - 2026-02-01
        #### Fixed
        - Bug B
      CHANGELOG

      Dir.mktmpdir do |dir|
        changelog_path = File.join(dir, "CHANGELOG.md")
        File.write(changelog_path, changelog)

        section = extract_changelog_section(changelog_path:, version: "16.4.0")
        expect(section).to include("Feature A")
        expect(section).not_to include("### [16.4.0] - 2026-03-08")
        expect(section).not_to include("Bug B")
      end
    end

    it "returns nil when the matching section has no content" do
      changelog = <<~CHANGELOG
        # Change Log

        ### [Unreleased]

        ### [16.4.0] - 2026-03-08

        ### [16.3.0] - 2026-02-01
        #### Fixed
        - Bug B
      CHANGELOG

      Dir.mktmpdir do |dir|
        changelog_path = File.join(dir, "CHANGELOG.md")
        File.write(changelog_path, changelog)

        section = extract_changelog_section(changelog_path:, version: "16.4.0")
        expect(section).to be_nil
      end
    end
  end

  describe "#run_release_preflight_checks!" do
    it "checks both npm and GitHub auth before a real release" do
      expect(self).to receive(:verify_npm_auth)
      expect(self).to receive(:verify_gh_auth).with(monorepo_root: "/tmp/repo")

      run_release_preflight_checks!(monorepo_root: "/tmp/repo", dry_run: false)
    end

    it "skips auth checks for dry runs" do
      expect(self).not_to receive(:verify_npm_auth)
      expect(self).not_to receive(:verify_gh_auth)

      run_release_preflight_checks!(monorepo_root: "/tmp/repo", dry_run: true)
    end
  end

  describe "#resolve_version_input" do
    it "uses the latest changelog version when it is newer than the current gem version" do
      allow(self).to receive(:extract_latest_changelog_version).with(monorepo_root: "/tmp/repo").and_return("16.4.0")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("16.3.0")

      expect(resolve_version_input("", "/tmp/repo")).to eq("16.4.0")
    end

    it "uses the current version when changelog version matches and is untagged" do
      allow(self).to receive(:extract_latest_changelog_version).with(monorepo_root: "/tmp/repo").and_return("16.3.0")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("16.3.0")
      allow(self).to receive(:version_tagged?).with("/tmp/repo", "16.3.0").and_return(false)

      expect(resolve_version_input("", "/tmp/repo")).to eq("16.3.0")
    end

    it "falls back to a patch bump when changelog version matches but is already tagged" do
      allow(self).to receive(:extract_latest_changelog_version).with(monorepo_root: "/tmp/repo").and_return("16.3.0")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("16.3.0")
      allow(self).to receive(:version_tagged?).with("/tmp/repo", "16.3.0").and_return(true)

      expect(resolve_version_input("", "/tmp/repo")).to eq("patch")
    end

    it "falls back to a patch bump when changelog version is older than current and untagged" do
      allow(self).to receive(:extract_latest_changelog_version).with(monorepo_root: "/tmp/repo").and_return("16.2.9")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("16.3.0")
      expect(self).not_to receive(:version_tagged?)

      expect(resolve_version_input("", "/tmp/repo")).to eq("patch")
    end
  end

  describe "#with_release_checkout" do
    it "preserves the original error if worktree cleanup also fails" do
      allow(Dir).to receive(:mktmpdir).with("react-on-rails-release-dry-run").and_yield("/tmp/release-dry-run")
      allow(self).to receive(:sh_in_dir_for_release) do |_dir, command|
        raise "cleanup failed" if command.include?("git worktree remove --force")
      end

      expect do
        with_release_checkout(monorepo_root: "/tmp/repo", dry_run: true) { raise "original failure" }
      end.to raise_error(RuntimeError, "original failure")
    end
  end

  describe "#run_shakaperf_release_gate!" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:repo_slug) { "shakacode/react_on_rails" }
    let(:head_sha) { "abc1234def5678abcdef" }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }
    let(:run) do
      {
        "databaseId" => 123_456,
        "headSha" => head_sha,
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
    end

    before do
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return(repo_slug)
    end

    it "dispatches the workflow on the release ref and watches the matching run" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([{ "databaseId" => 999_999, "headSha" => head_sha }])
      allow(self).to receive(:capture_gh_output)
        .with(
          "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
          "--repo", repo_slug,
          "--ref", "release-branch"
        )
        .and_return(["", success_status])
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!)
        .with(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          ignored_run_ids: ["999999"],
          earliest_created_at: kind_of(Time)
        )
        .and_return(run)
      allow(self).to receive(:capture_gh_output_with_timeout)
        .with(
          "run", "watch", "123456", "--repo", repo_slug, "--exit-status",
          timeout_seconds: SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS
        )
        .and_return(["", success_status, false])

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          allow_override: false,
          dry_run: false
        )
      end.to output(/ShakaPerf release gate passed/).to_stdout
      expect(self).to have_received(:capture_gh_output)
        .with(
          "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
          "--repo", repo_slug,
          "--ref", "release-branch"
        )
      expect(self).to have_received(:wait_for_shakaperf_release_gate_run!)
        .with(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          ignored_run_ids: ["999999"],
          earliest_created_at: kind_of(Time)
        )
      expect(self).to have_received(:capture_gh_output_with_timeout)
        .with(
          "run", "watch", "123456", "--repo", repo_slug, "--exit-status",
          timeout_seconds: SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS
        )
    end

    it "skips dispatching when the CI status override is enabled" do
      expect(self).not_to receive(:capture_gh_output)

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          allow_override: true,
          dry_run: false
        )
      end.to output(/skipping ShakaPerf release gate/).to_stdout
    end

    it "prints the intended gate during dry runs without dispatching" do
      expect(self).not_to receive(:capture_gh_output)

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          allow_override: false,
          dry_run: true
        )
      end.to output(/DRY RUN: Would run ShakaPerf release gate/).to_stdout
    end

    it "aborts when workflow dispatch fails" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([])
      allow(self).to receive(:capture_gh_output)
        .with(
          "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
          "--repo", repo_slug,
          "--ref", "release-branch"
        )
        .and_return(["HTTP 404", failure_status])

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, /Unable to dispatch ShakaPerf release gate workflow.*HTTP 404/m)
    end

    it "aborts when the matching gate run fails" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([])
      allow(self).to receive(:capture_gh_output)
        .with(
          "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
          "--repo", repo_slug,
          "--ref", "release-branch"
        )
        .and_return(["", success_status])
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!)
        .with(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          ignored_run_ids: [],
          earliest_created_at: kind_of(Time)
        )
        .and_return(run)
      allow(self).to receive(:capture_gh_output_with_timeout)
        .with(
          "run", "watch", "123456", "--repo", repo_slug, "--exit-status",
          timeout_seconds: SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS
        )
        .and_return(["Tests failed", failure_status, false])

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, %r{ShakaPerf release gate failed.*actions/runs/123456.*Tests failed}m)
    end

    it "aborts when watching the matching gate run times out" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([])
      allow(self).to receive(:capture_gh_output)
        .with(
          "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
          "--repo", repo_slug,
          "--ref", "release-branch"
        )
        .and_return(["", success_status])
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!)
        .with(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          ignored_run_ids: [],
          earliest_created_at: kind_of(Time)
        )
        .and_return(run)
      allow(self).to receive(:capture_gh_output_with_timeout)
        .with(
          "run", "watch", "123456", "--repo", repo_slug, "--exit-status",
          timeout_seconds: SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS
        )
        .and_return(["Still running", failure_status, true])

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, %r{Timed out watching ShakaPerf release gate run 123456.*actions/runs/123456}m)
    end

    it "finds the workflow_dispatch run for the pushed head SHA" do
      matching_run = { "databaseId" => 2, "headSha" => head_sha }
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([{ "databaseId" => 1, "headSha" => "old" }, matching_run])

      expect(
        wait_for_shakaperf_release_gate_run!(repo_slug:, ref: "release-branch", head_sha:)
      ).to eq(matching_run)
    end

    it "ignores stale workflow_dispatch runs for the same head SHA" do
      stale_run = { "databaseId" => 1, "headSha" => head_sha }
      matching_run = { "databaseId" => 2, "headSha" => head_sha }
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([stale_run, matching_run])

      expect(
        wait_for_shakaperf_release_gate_run!(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          ignored_run_ids: [1]
        )
      ).to eq(matching_run)
    end

    it "ignores workflow_dispatch runs created before the new dispatch starts" do
      stale_run = { "databaseId" => 1, "headSha" => head_sha, "createdAt" => "2026-06-05T01:00:00Z" }
      matching_run = { "databaseId" => 2, "headSha" => head_sha, "createdAt" => "2026-06-05T01:00:10Z" }
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([stale_run, matching_run])

      expect(
        wait_for_shakaperf_release_gate_run!(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          earliest_created_at: Time.iso8601("2026-06-05T01:00:05Z")
        )
      ).to eq(matching_run)
    end

    it "uses GitHub's second-precision timestamps when matching newly dispatched runs" do
      allow(Time).to receive(:now).and_return(Time.iso8601("2026-06-05T01:00:05.900Z"))
      newly_dispatched_run = { "databaseId" => 1, "headSha" => head_sha, "createdAt" => "2026-06-05T01:00:05Z" }
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([newly_dispatched_run])

      expect(
        wait_for_shakaperf_release_gate_run!(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          earliest_created_at: shakaperf_release_gate_dispatch_started_at
        )
      ).to eq(newly_dispatched_run)
    end

    it "aborts when no matching workflow_dispatch run appears before the deadline" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([{ "databaseId" => 1, "headSha" => "other" }])
      stub_const("SHAKAPERF_RELEASE_GATE_START_TIMEOUT_SECONDS", -1)

      expect do
        wait_for_shakaperf_release_gate_run!(
          repo_slug:,
          ref: "release-branch",
          head_sha:
        )
      end.to raise_error(SystemExit, /Timed out waiting for ShakaPerf release gate workflow to start/)
    end
  end

  describe "#publish_gem_with_retry" do
    it "passes OTP via environment instead of shell interpolation" do
      expect(self).to receive(:sh_args_in_dir_for_release).with(
        "/tmp/gem",
        "gem",
        "release",
        env: { "GEM_HOST_OTP_CODE" => "123456" }
      )

      publish_gem_with_retry("/tmp/gem", "react_on_rails", otp: "123456", max_retries: 1)
    end
  end

  describe "#publish_npm_with_retry" do
    it "passes OTP as a dedicated CLI argument" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "package.json"), JSON.pretty_generate({ "name" => "react-on-rails",
                                                                          "version" => "16.4.0-rc.1" }))

        expect(self).to receive(:sh_args_in_dir_for_release).with(
          dir,
          "pnpm",
          "publish",
          "--tag",
          "rc",
          "--otp",
          "123456"
        )
        expect(self).to receive(:verify_npm_package_published!).with(
          "react-on-rails",
          "16.4.0-rc.1"
        )

        publish_npm_with_retry(
          dir,
          "react-on-rails@16.4.0-rc.1",
          base_args: ["--tag", "rc"],
          otp: "123456",
          max_retries: 1
        )
      end
    end

    it "raises when pnpm publish exits but npm cannot see the package version" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "package.json"), JSON.pretty_generate({ "name" => "react-on-rails",
                                                                          "version" => "16.7.0-rc.1" }))
        expect(self).to receive(:sh_args_in_dir_for_release).with(dir, "pnpm", "publish")
        allow(Open3).to receive(:capture2e)
          .with(
            "npm",
            "view",
            "react-on-rails@16.7.0-rc.1",
            "version",
            "dependencies",
            "optionalDependencies",
            "peerDependencies",
            "--json",
            "--registry",
            "https://registry.npmjs.org/"
          )
          .and_return(["npm ERR! 404 Not Found", instance_double(Process::Status, success?: false)])
        allow(self).to receive(:sleep)

        expect do
          publish_npm_with_retry(
            dir,
            "react-on-rails@16.7.0-rc.1",
            max_retries: 1
          )
        end.to raise_error(SystemExit, /not visible on npm/)
      end
    end

    it "replaces workspace protocol dependencies while publishing and restores the package manifest" do
      Dir.mktmpdir do |dir|
        package_json_path = File.join(dir, "package.json")
        original_package_json = JSON.pretty_generate(
          {
            "name" => "react-on-rails-pro",
            "version" => "16.7.0-rc.1",
            "dependencies" => {
              "react-on-rails" => "workspace:*"
            },
            "optionalDependencies" => {
              "react-on-rails-optional" => "workspace:^"
            },
            "peerDependencies" => {
              "react-on-rails-peer" => "workspace:~"
            }
          }
        )
        File.write(package_json_path, "#{original_package_json}\n")

        expect(self).to receive(:sh_args_in_dir_for_release).with(dir, "pnpm", "publish") do
          published_package_json = JSON.parse(File.read(package_json_path))
          expect(published_package_json.dig("dependencies", "react-on-rails")).to eq("16.7.0-rc.1")
          expect(published_package_json.dig("optionalDependencies", "react-on-rails-optional"))
            .to eq("^16.7.0-rc.1")
          expect(published_package_json.dig("peerDependencies", "react-on-rails-peer")).to eq("~16.7.0-rc.1")
        end
        expect(self).to receive(:verify_npm_package_published!).with(
          "react-on-rails-pro",
          "16.7.0-rc.1"
        )

        publish_npm_with_retry(dir, "react-on-rails-pro@16.7.0-rc.1", max_retries: 1)

        expect(File.read(package_json_path)).to eq("#{original_package_json}\n")
      end
    end
  end

  describe "#npm_publish_base_args" do
    it "skips git checks for prereleases" do
      expect(
        npm_publish_base_args(
          actual_gem_version: "17.0.0.rc.1",
          actual_npm_version: "17.0.0-rc.1",
          current_branch: "release/17.0.0"
        )
      ).to eq(["--tag", "rc", "--no-git-checks"])
    end

    it "skips git checks for prereleases from main" do
      expect(
        npm_publish_base_args(
          actual_gem_version: "17.0.0.rc.1",
          actual_npm_version: "17.0.0-rc.1",
          current_branch: "main"
        )
      ).to eq(["--tag", "rc", "--no-git-checks"])
    end

    it "skips git checks and allows stable npm publish from a release branch" do
      expect(
        npm_publish_base_args(
          actual_gem_version: "17.0.0",
          actual_npm_version: "17.0.0",
          current_branch: "release/17.0.0"
        )
      ).to eq(["--no-git-checks", "--publish-branch", "release/17.0.0"])
    end

    it "uses default npm publish checks for stable main releases" do
      expect(
        npm_publish_base_args(
          actual_gem_version: "17.0.0",
          actual_npm_version: "17.0.0",
          current_branch: "main"
        )
      ).to eq([])
    end
  end

  describe "#with_publishable_package_json" do
    it "preserves the original publish failure when package.json restore also fails" do
      Dir.mktmpdir do |dir|
        package_json_path = File.join(dir, "package.json")
        File.write(
          package_json_path,
          "#{JSON.pretty_generate({ 'dependencies' => { 'react-on-rails' => 'workspace:*' } })}\n"
        )

        allow(File).to receive(:write).and_wrap_original do |method, *args|
          raise "restore failed" if args.first == package_json_path

          method.call(*args)
        end

        expect do
          with_publishable_package_json(dir, "16.7.0-rc.1") do
            raise "publish failed"
          end
        end.to raise_error(RuntimeError, "publish failed")
      end
    end

    it "removes the temporary package manifest when atomic rename fails" do
      Dir.mktmpdir do |dir|
        package_json_path = File.join(dir, "package.json")
        original_package_json = JSON.pretty_generate({ "dependencies" => { "react-on-rails" => "workspace:*" } })
        File.write(package_json_path, "#{original_package_json}\n")

        allow(File).to receive(:rename).and_wrap_original do |method, source, destination|
          if destination == package_json_path && File.basename(source).start_with?("package-json-")
            raise "rename failed"
          end

          method.call(source, destination)
        end

        expect do
          with_publishable_package_json(dir, "16.7.0-rc.1") { raise "publish should not run" }
        end.to raise_error(RuntimeError, "rename failed")

        expect(Dir.glob(File.join(dir, "package-json-*.json"))).to be_empty
        expect(File.read(package_json_path)).to eq("#{original_package_json}\n")
      end
    end
  end

  describe "#verify_npm_package_published!" do
    it "retries transient npm metadata lookup failures before accepting the published package" do
      failed_status = instance_double(Process::Status, success?: false)
      successful_status = instance_double(Process::Status, success?: true)

      allow(Open3).to receive(:capture2e)
        .with(
          "npm",
          "view",
          "react-on-rails@16.7.0-rc.1",
          "version",
          "dependencies",
          "optionalDependencies",
          "peerDependencies",
          "--json",
          "--registry",
          "https://registry.npmjs.org/"
        )
        .and_return(
          ["npm ERR! 404 Not Found", failed_status],
          [JSON.generate({ "version" => "16.7.0-rc.1" }), successful_status]
        )
      expect(self).to receive(:sleep).with(0).once

      verify_npm_package_published!(
        "react-on-rails",
        "16.7.0-rc.1",
        attempts: 2,
        retry_delay_seconds: 0
      )
    end

    it "raises when the published package metadata contains workspace protocol dependencies" do
      allow(Open3).to receive(:capture2e)
        .with(
          "npm",
          "view",
          "react-on-rails-pro@16.7.0-rc.1",
          "version",
          "dependencies",
          "optionalDependencies",
          "peerDependencies",
          "--json",
          "--registry",
          "https://registry.npmjs.org/"
        )
        .and_return([
                      JSON.generate(
                        {
                          "version" => "16.7.0-rc.1",
                          "dependencies" => {
                            "react-on-rails" => "workspace:*"
                          }
                        }
                      ),
                      instance_double(Process::Status, success?: true)
                    ])

      expect do
        verify_npm_package_published!("react-on-rails-pro", "16.7.0-rc.1")
      end.to raise_error(SystemExit, /workspace:\*/)
    end
  end

  describe "#validate_release_version_policy!" do
    it "skips downstream checks for same-base prerelease bumps" do
      allow(self).to receive(:tagged_release_gem_versions)
        .with("/tmp/repo", fetch_tags: false)
        .and_return(["16.4.0.rc.0"])

      expect do
        validate_release_version_policy!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "16.4.0.rc.1",
          allow_override: false,
          fetch_tags: false
        )
      end.to output(/Skipping all downstream checks for same-base prerelease bump/).to_stdout
    end

    it "raises when the changelog-implied bump does not match the requested stable release version" do
      allow(self).to receive(:tagged_release_gem_versions).with("/tmp/repo", fetch_tags: false).and_return(["16.3.0"])
      allow(self).to receive(:extract_changelog_section)
        .with(changelog_path: "/tmp/repo/CHANGELOG.md", version: "16.3.1")
        .and_return("#### Added\n- New feature\n")

      expect do
        validate_release_version_policy!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "16.3.1",
          allow_override: false,
          fetch_tags: false
        )
      end.to raise_error(SystemExit, /Version bump mismatch/)
    end
  end

  describe "#ci_status_override_enabled?" do
    it "returns true when the override flag is truthy" do
      expect(ci_status_override_enabled?("true")).to be true
      expect(ci_status_override_enabled?(true)).to be true
    end

    it "returns true when the env var is truthy" do
      allow(ENV).to receive(:fetch).with("RELEASE_CI_STATUS_OVERRIDE", nil).and_return("true")
      expect(ci_status_override_enabled?(nil)).to be true
    end

    it "returns false when both are falsy" do
      allow(ENV).to receive(:fetch).with("RELEASE_CI_STATUS_OVERRIDE", nil).and_return(nil)
      expect(ci_status_override_enabled?(nil)).to be false
      expect(ci_status_override_enabled?("false")).to be false
    end
  end

  describe "#validate_main_ci_status!" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:sha) { "abc1234def5678abcdef" }
    let(:short_sha) { "abc1234d" }

    # `validate_main_ci_status!` now queries `required_check_names_for_branch`
    # unconditionally so the missing-required-check gate can apply to both
    # stable and prerelease. The helper shells out to `git -C monorepo_root`
    # which would abort in tests where `monorepo_root` is a stub path. Default
    # to "no required checks configured" so tests that don't care about the
    # gate behave as before; tests that exercise the gate override this stub.
    before do
      allow(self).to receive_messages(
        fetch_main_commit_statuses: [],
        github_repo_slug: "shakacode/react_on_rails",
        required_check_names_for_branch: nil
      )
    end

    def required_checks(contexts: [], checks: [])
      { contexts:, checks: }
    end

    def required_check(context, app_id: nil)
      { context:, app_id: }
    end

    def next_check_run_id
      @next_check_run_id ||= 999
      @next_check_run_id += 1
    end

    # Distinct defaults keep same-named helper-generated runs from collapsing
    # in the nil-check_suite dedup path. Tests can still pin an id to model a
    # specific GitHub payload.
    def passing_run(name, id: next_check_run_id, app_id: nil)
      run = {
        "id" => id,
        "name" => name,
        "status" => "completed",
        "conclusion" => "success",
        "html_url" => "https://github.com/shakacode/react_on_rails/runs/#{name.gsub(/\W/, '_')}"
      }
      run["app"] = { "id" => app_id } if app_id
      run
    end

    def failing_run(name, conclusion: "failure", id: next_check_run_id, app_id: nil)
      run = {
        "id" => id,
        "name" => name,
        "status" => "completed",
        "conclusion" => conclusion,
        "html_url" => "https://github.com/shakacode/react_on_rails/runs/#{name.gsub(/\W/, '_')}"
      }
      run["app"] = { "id" => app_id } if app_id
      run
    end

    def in_progress_run(name, id: next_check_run_id)
      {
        "id" => id,
        "name" => name,
        "status" => "in_progress",
        "conclusion" => nil,
        "html_url" => "https://github.com/shakacode/react_on_rails/runs/#{name.gsub(/\W/, '_')}"
      }
    end

    context "when all check runs pass" do
      it "logs success and returns without raising" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint"), passing_run("Test")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(2 checks\)/).to_stdout
      end

      it "uses the default main branch helper path when ci_branch is omitted" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint")]))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to output(%r{Checking CI status on origin/main.*Main CI is healthy on #{short_sha}}m).to_stdout

        expect(self).to have_received(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
        expect(self).to have_received(:required_check_names_for_branch).with(monorepo_root:, ci_branch: "main")
      end
    end

    context "when releasing from a release branch (ci_branch override)" do
      it "evaluates the release branch tip and references it in violations" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "release/17.0.0")
          .and_return(sha:, check_runs: [passing_run("Lint"), failing_run("JS unit tests")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false,
            ci_branch: "release/17.0.0"
          )
        end.to raise_error(SystemExit, %r{CI on origin/release/17.0.0 is not healthy.*JS unit tests}m)
      end

      it "announces the release branch in the status header" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "release/17.0.0")
          .and_return(sha:, check_runs: [passing_run("Lint")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false,
            ci_branch: "release/17.0.0"
          )
        end.to output(
          %r{Checking CI status on origin/release/17.0.0.*CI on origin/release/17.0.0 is healthy on #{short_sha}}m
        ).to_stdout
      end

      it "evaluates only required checks for an RC cut (prerelease) from the release branch" do
        # RC cut: is_prerelease true + a release/* ci_branch. The required-only
        # filter must apply against the release branch tip, so a failing
        # non-required check is advisory and does not block the RC.
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "release/17.0.0")
          .and_return(sha:, check_runs: [passing_run("Lint"), failing_run("Benchmark Workflow")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "release/17.0.0")
          .and_return(required_checks(checks: [required_check("Lint")]))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            ci_branch: "release/17.0.0"
          )
        end.to output(%r{CI on origin/release/17.0.0 is healthy on #{short_sha} \(1 required check\)}).to_stdout
      end
    end

    context "when a check has failed on a stable release" do
      it "aborts with the failing check name and link" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint"), failing_run("JS unit tests")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*JS unit tests}m)
      end
    end

    context "when a non-required check fails on a prerelease" do
      it "passes because only required checks gate prereleases" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint"), failing_run("Benchmark Workflow")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main").and_return(required_checks(checks: [required_check("Lint")]))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(1 required check\)/).to_stdout
      end
    end

    context "when a required check fails on a prerelease" do
      it "aborts because the required check gates prereleases" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [failing_run("Lint"), passing_run("Benchmark Workflow")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main").and_return(required_checks(checks: [required_check("Lint")]))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Lint}m)
      end
    end

    context "when a check is still in progress" do
      it "aborts with the in-progress message and link" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint"), in_progress_run("Slow test")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /CI is still in progress.*Slow test/m)
      end
    end

    context "when there are both failed and in-progress checks" do
      it "reports the failure first so the operator does not wait on an already-broken main" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [failing_run("JS unit tests"), in_progress_run("Slow test")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*JS unit tests}m)
      end
    end

    context "when a check has been rerun and the latest attempt passes" do
      it "evaluates only the latest attempt per check name and passes" do
        # Reruns from the GitHub API preserve `check_suite.id` across attempts.
        # The dedup key includes the suite id so cross-workflow runs that share
        # a name don't collapse; both attempts here belong to the same suite,
        # which is what makes them a rerun rather than two distinct workflows.
        old_failed = failing_run("Lint").merge("id" => 1, "check_suite" => { "id" => 100 })
        new_passed = passing_run("Lint").merge("id" => 2, "check_suite" => { "id" => 100 })
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [old_failed, new_passed])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy/).to_stdout
      end
    end

    context "when two workflows emit jobs with the same name on the same commit" do
      it "preserves both runs (different check_suite ids) instead of collapsing them" do
        workflow_a_passing = passing_run("detect-changes").merge(
          "id" => 1, "check_suite" => { "id" => 100 }
        )
        workflow_b_failing = failing_run("detect-changes").merge(
          "id" => 2, "check_suite" => { "id" => 200 }
        )
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [workflow_a_passing, workflow_b_failing])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*detect-changes}m)
      end
    end

    context "when same-named checks do not include check_suite data" do
      it "keeps helper-generated runs distinct by default" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint"), failing_run("Lint")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Lint}m)
      end
    end

    context "when a rerun and a same-named distinct-suite run exist together" do
      it "collapses only within a suite (same-suite rerun) and keeps cross-suite runs distinct" do
        suite_a_old_failed = failing_run("detect-changes").merge(
          "id" => 1, "check_suite" => { "id" => 100 }
        )
        suite_a_new_passed = passing_run("detect-changes").merge(
          "id" => 3, "check_suite" => { "id" => 100 }
        )
        suite_b_passing = passing_run("detect-changes").merge(
          "id" => 2, "check_suite" => { "id" => 200 }
        )
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [suite_a_old_failed, suite_a_new_passed, suite_b_passing])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(2 checks\)/).to_stdout
      end
    end

    context "when there are zero check runs visible" do
      it "aborts with a 'no CI data' message" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{No CI check runs visible on origin/main})
      end
    end

    context "when override is set on a failing main" do
      it "warns and returns instead of aborting" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: true, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [failing_run("Lint")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: true,
            dry_run: false
          )
        end.to output(%r{CI STATUS OVERRIDE enabled.*Lint.*https://github.com}m).to_stdout
      end
    end

    context "when running in dry-run mode on a failing main" do
      it "warns and returns instead of aborting" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: true, ci_branch: "main")
          .and_return(sha:, check_runs: [failing_run("Lint")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: true
          )
        end.to output(%r{DRY RUN.*CI on origin/main is not healthy.*DRY RUN:.*Lint}m).to_stdout
      end
    end

    context "when fetch surfaces a violation via override/dry-run (returns nil)" do
      it "returns without raising and without trying to inspect the data" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: true, ci_branch: "main")
          .and_return(nil)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: true
          )
        end.not_to raise_error
      end
    end

    context "when branch protection is not queryable on a prerelease" do
      it "falls back to evaluating all checks (fail-safe)" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint"), failing_run("Optional Check")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main").and_return(nil)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Optional Check}m)
      end
    end

    context "when no check runs match the required names on a prerelease" do
      it "aborts with a 'no required check runs' message" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main").and_return(required_checks(checks: [required_check("DoesNotExist")]))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /No required CI check runs found.*DoesNotExist/m)
      end
    end

    context "when some required checks are present but others are missing on a prerelease" do
      it "aborts and lists the missing required check names" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint"), passing_run("Test")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main")
          .and_return(required_checks(checks: %w[Lint Test Build].map { |context| required_check(context) }))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(
          SystemExit,
          /Some required CI checks are missing.*Missing:\s*Build/m
        )
      end
    end

    context "when some required checks are missing on a stable release" do
      it "aborts on stable too (branch protection would refuse the merge)" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint"), passing_run("Test")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main")
          .and_return(required_checks(checks: %w[Lint Test Build].map { |context| required_check(context) }))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(
          SystemExit,
          /Some required CI checks are missing.*Missing:\s*Build/m
        )
      end
    end

    context "when a check has an unknown status (neither completed nor in CI_INCOMPLETE_STATUSES)" do
      it "treats the ambiguity as a failure rather than silently passing through" do
        weird_run = passing_run("Future Status").merge("status" => "scheduled", "conclusion" => nil)
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint"), weird_run])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /Check run\(s\) with unrecognized status.*Future Status/m)
      end

      it "treats a nil status as a failure too" do
        weird_run = passing_run("Malformed").merge("status" => nil, "conclusion" => nil)
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint"), weird_run])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /Check run\(s\) with unrecognized status.*Malformed/m)
      end
    end

    context "when a required check is pinned to a GitHub App" do
      it "does not let a same-named check from another app satisfy the requirement" do
        wrong_app_run = passing_run("Lint", app_id: 999)
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [wrong_app_run])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint", app_id: 123)]))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /No required CI check runs found.*Lint \(app_id: 123\)/m)
      end

      it "evaluates the same-named check from the required app" do
        wrong_app_run = passing_run("Lint", app_id: 999)
        required_app_run = failing_run("Lint", app_id: 123)
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [wrong_app_run, required_app_run])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint", app_id: 123)]))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Lint}m)
      end

      it "does not let a same-name check from a different app block a prerelease" do
        wrong_app_run = failing_run("Lint", app_id: 999)
        required_app_run = passing_run("Lint", app_id: 123)
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [wrong_app_run, required_app_run])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint", app_id: 123)]))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(1 required check\)/).to_stdout
      end
    end

    context "when branch protection includes legacy status contexts" do
      it "uses commit statuses to satisfy legacy contexts when no check runs are visible" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "success",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(1 required check\)/).to_stdout
      end

      it "blocks when the legacy commit status has failed" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "failure",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Travis}m)
      end

      it "blocks when a same-named legacy status fails even if a check run passes" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [passing_run("Travis")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "failure",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Travis}m)
      end

      it "treats a pending legacy commit status as in progress" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "pending",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /CI is still in progress.*Travis/m)
      end

      it "treats an unknown legacy commit status state as failed" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "unexpected",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Travis}m)
      end

      it "keeps evaluating fetched check runs when legacy status fetch is skipped in dry-run" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: true, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [failing_run("Lint")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: true)
          .and_return(nil)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: true
          )
        end.to output(%r{DRY RUN: .*CI on origin/main is not healthy.*DRY RUN:.*Lint}m).to_stdout
      end

      it "does not print green when required legacy status data is unavailable in dry-run" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: true, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [passing_run("Travis")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses) do
          puts "⚠️ DRY RUN: Required legacy status fetch failed."
          nil
        end

        output = capture_stdout do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: true
          )
        end

        expect(output).to include("DRY RUN: Required legacy status fetch failed.")
        expect(output).not_to include("Main CI is healthy")
      end

      it "raises if strict legacy status fetch unexpectedly returns nil" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [passing_run("Lint")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return(nil)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /Internal error: legacy status fetch returned nil unexpectedly in strict mode/)
      end

      it "does not print the commit-status API URL as a browser link" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "failure",
                          "url" => "https://api.github.com/repos/shakacode/react_on_rails/statuses/#{sha}"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit) { |error| expect(error.message).not_to include("api.github.com") }
      end

      it "reports a failed legacy status for a wildcard required check" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Travis")]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "failure",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Travis}m)
      end

      it "blocks a stable release when a legacy commit status has failed" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [passing_run("Lint")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "failure",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Travis}m)
      end

      it "uses a legacy status to satisfy a wildcard required check" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Travis")]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "success",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(1 required check\)/).to_stdout
      end

      it "counts a mirrored wildcard required check once when both APIs report it" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [passing_run("Travis")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Travis")]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "success",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(1 required check\)/).to_stdout
      end

      it "counts a mirrored wildcard required check once on stable releases" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [passing_run("Travis")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Travis")]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "success",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(1 check\)/).to_stdout
      end

      it "uses the newest same-context legacy status" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([
                        {
                          "id" => 1,
                          "context" => "Travis",
                          "state" => "failure",
                          "created_at" => "2026-06-07T20:00:00Z",
                          "target_url" => "https://ci.example.com/travis"
                        },
                        {
                          "id" => 2,
                          "context" => "Travis",
                          "state" => "success",
                          "created_at" => "2026-06-07T20:00:01Z",
                          "target_url" => "https://ci.example.com/travis"
                        }
                      ])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(1 required check\)/).to_stdout
      end

      it "reports a missing mirrored wildcard check once" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [passing_run("Build")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(
            required_checks(checks: [required_check("Travis"), required_check("Build")])
          )
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("Required: Travis, Build")
          expect(error.message).to include("Missing: Travis")
          expect(error.message).not_to include("2 gates")
        }
      end

      it "does not let a legacy status satisfy an app-pinned modern check" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [passing_run("Other")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Travis", app_id: 123)]))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /No required CI check runs found.*Required: Travis \(app_id: 123\)/m)
      end
    end

    it "raises when asked to format an unknown CI violation kind" do
      expect do
        format_main_ci_status_violation(kind: :typo, short_sha:, runs: [])
      end.to raise_error(ArgumentError, /Unknown CI violation kind: :typo/)
    end
  end

  describe "#fetch_main_ci_checks" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    # These tests focus on the fetch/parse behavior for a resolved SHA. The
    # commit-selection walk-back is covered separately in
    # `#main_ci_evaluation_sha`; stub it to the identity here so the gh check-runs
    # path stays pinned to the SHA from `git rev-parse origin/<branch>`.
    before do
      allow(self).to receive(:main_ci_evaluation_sha) { |**kwargs| kwargs[:head_sha] }
    end

    def stub_release_branch_refs(remote_sha:, local_sha:)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "release/17.0.0", "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/release/17.0.0")
        .and_return(["#{remote_sha}\n", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["#{local_sha}\n", success_status])
    end

    def stub_check_runs_for_sha(sha:, check_runs:)
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return("shakacode/react_on_rails")
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--paginate", "--jq", ".check_runs[]",
              "repos/shakacode/react_on_rails/commits/#{sha}/check-runs")
        .and_return([check_runs.map(&:to_json).join("\n"), success_status])
    end

    it "aborts if `git fetch origin main` fails" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["fetch failed: network down", failure_status])

      expect do
        fetch_main_ci_checks(monorepo_root:)
      end.to raise_error(SystemExit, %r{Unable to fetch origin/main})
    end

    it "warns instead of aborting when `git fetch` fails with allow_override" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["fetch failed: network down", failure_status])

      result = nil
      expect do
        result = fetch_main_ci_checks(monorepo_root:, allow_override: true)
      end.to output(%r{CI STATUS OVERRIDE enabled.*Unable to fetch origin/main}m).to_stdout
      expect(result).to be_nil
    end

    it "warns instead of aborting when `git fetch` fails in dry-run mode" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["fetch failed: network down", failure_status])

      result = nil
      expect do
        result = fetch_main_ci_checks(monorepo_root:, dry_run: true)
      end.to output(%r{DRY RUN.*Unable to fetch origin/main}m).to_stdout
      expect(result).to be_nil
    end

    it "aborts if `gh api check-runs` fails (no silent override)" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/main")
        .and_return(["abc1234\n", success_status])
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return("shakacode/react_on_rails")
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--paginate", "--jq", ".check_runs[]",
              "repos/shakacode/react_on_rails/commits/abc1234/check-runs")
        .and_return(["HTTP 401: unauthorized", failure_status])

      expect do
        fetch_main_ci_checks(monorepo_root:)
      end.to raise_error(SystemExit, /Unable to query GitHub Checks API.*HTTP 401/m)
    end

    it "aborts with a friendly install hint when `gh` is not installed" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/main")
        .and_return(["abc1234\n", success_status])
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return("shakacode/react_on_rails")
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--paginate", "--jq", ".check_runs[]",
              "repos/shakacode/react_on_rails/commits/abc1234/check-runs")
        .and_raise(Errno::ENOENT)

      expect do
        fetch_main_ci_checks(monorepo_root:)
      end.to raise_error(SystemExit, /GitHub CLI .* is not installed/)
    end

    it "warns instead of aborting when `gh` is missing in dry-run mode" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/main")
        .and_return(["abc1234\n", success_status])
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return("shakacode/react_on_rails")
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--paginate", "--jq", ".check_runs[]",
              "repos/shakacode/react_on_rails/commits/abc1234/check-runs")
        .and_raise(Errno::ENOENT)

      result = nil
      expect do
        result = fetch_main_ci_checks(monorepo_root:, dry_run: true)
      end.to output(/DRY RUN.*GitHub CLI .* is not installed/m).to_stdout
      expect(result).to be_nil
    end

    it "warns instead of aborting on unparseable check-runs JSON in dry-run mode" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/main")
        .and_return(["abc1234\n", success_status])
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return("shakacode/react_on_rails")
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--paginate", "--jq", ".check_runs[]",
              "repos/shakacode/react_on_rails/commits/abc1234/check-runs")
        .and_return(["this is not json", success_status])

      result = nil
      expect do
        result = fetch_main_ci_checks(monorepo_root:, dry_run: true)
      end.to output(/DRY RUN.*Failed to parse check_runs response/m).to_stdout
      expect(result).to be_nil
    end

    it "parses paginated JSONL check_runs into an array of hashes" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/main")
        .and_return(["abc1234def\n", success_status])
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return("shakacode/react_on_rails")
      jsonl = [
        { "name" => "Lint", "status" => "completed", "conclusion" => "success" },
        { "name" => "Test", "status" => "completed", "conclusion" => "failure" }
      ].map(&:to_json).join("\n")
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--paginate", "--jq", ".check_runs[]",
              "repos/shakacode/react_on_rails/commits/abc1234def/check-runs")
        .and_return([jsonl, success_status])

      result = fetch_main_ci_checks(monorepo_root:)
      expect(result[:sha]).to eq("abc1234def")
      expect(result[:repo_slug]).to eq("shakacode/react_on_rails")
      expect(result[:check_runs].length).to eq(2)
      expect(result[:check_runs].first["name"]).to eq("Lint")
    end

    it "fetches and evaluates a release branch tip when ci_branch is overridden" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "release/17.0.0", "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/release/17.0.0")
        .and_return(["rcsha123\n", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["rcsha123\n", success_status])
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return("shakacode/react_on_rails")
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--paginate", "--jq", ".check_runs[]",
              "repos/shakacode/react_on_rails/commits/rcsha123/check-runs")
        .and_return([{ "name" => "Lint", "status" => "completed", "conclusion" => "success" }.to_json,
                     success_status])

      result = fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0")
      expect(result[:sha]).to eq("rcsha123")
      expect(result[:check_runs].first["name"]).to eq("Lint")
    end

    it "aborts when the local release branch is ahead of the fetched remote branch" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "release/17.0.0", "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/release/17.0.0")
        .and_return(["remote123\n", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["local456\n", success_status])

      expect do
        fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0")
      end.to raise_error(SystemExit, %r{Local HEAD does not match origin/release/17.0.0})
    end

    it "aborts when local HEAD cannot be resolved for a release branch" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "release/17.0.0", "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/release/17.0.0")
        .and_return(["remote123\n", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["fatal: ambiguous argument HEAD\n", failure_status])

      expect do
        fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0")
      end.to raise_error(SystemExit, /Unable to resolve local HEAD before release CI status check/)
    end

    it "continues querying CI after a release branch HEAD mismatch under override" do
      stub_release_branch_refs(remote_sha: "remote123", local_sha: "local456")
      stub_check_runs_for_sha(
        sha: "remote123",
        check_runs: [{ "name" => "Lint", "status" => "completed", "conclusion" => "success" }]
      )

      result = nil
      expect do
        result = fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0", allow_override: true)
      end.to output(%r{CI STATUS OVERRIDE enabled.*Local HEAD does not match origin/release/17.0.0}m).to_stdout
      expect(result[:sha]).to eq("remote123")
      expect(result[:check_runs].first["name"]).to eq("Lint")
    end

    it "continues querying CI after a release branch HEAD mismatch in dry-run mode" do
      stub_release_branch_refs(remote_sha: "remote123", local_sha: "local456")
      stub_check_runs_for_sha(
        sha: "remote123",
        check_runs: [{ "name" => "Lint", "status" => "completed", "conclusion" => "success" }]
      )

      result = nil
      expect do
        result = fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0", dry_run: true)
      end.to output(%r{DRY RUN.*Local HEAD does not match origin/release/17.0.0}m).to_stdout
      expect(result[:sha]).to eq("remote123")
      expect(result[:check_runs].first["name"]).to eq("Lint")
    end

    it "aborts referencing the release branch when its fetch fails" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "release/17.0.0", "--quiet")
        .and_return(["fetch failed: network down", failure_status])

      expect do
        fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0")
      end.to raise_error(SystemExit, %r{Unable to fetch origin/release/17.0.0})
    end
  end

  describe "#main_ci_evaluation_sha" do
    let(:monorepo_root) { "/tmp/repo" }

    before do
      # Default to "no escape hatch"; the bypass test overrides this.
      allow(self).to receive(:ci_evaluate_head_only?).and_return(false)
    end

    it "returns HEAD unchanged when HEAD already ran the full suite" do
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "head").and_return(false)

      expect(self).not_to receive(:git_parent_sha)
      expect(main_ci_evaluation_sha(monorepo_root:, head_sha: "head")).to eq("head")
    end

    it "walks back one commit past a changelog/docs-only HEAD" do
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "head").and_return(true)
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "parent").and_return(false)
      allow(self).to receive(:git_parent_sha)
        .with(monorepo_root:, sha: "head").and_return("parent")

      result = nil
      expect { result = main_ci_evaluation_sha(monorepo_root:, head_sha: "head") }
        .to output(/Evaluating CI on parent/).to_stdout
      expect(result).to eq("parent")
    end

    it "labels release branch walkback output with the evaluated ref" do
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "head").and_return(true)
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "parent").and_return(false)
      allow(self).to receive(:git_parent_sha)
        .with(monorepo_root:, sha: "head").and_return("parent")

      result = nil
      expect do
        result = main_ci_evaluation_sha(monorepo_root:, head_sha: "head", ref: "origin/release/17.0.0")
      end.to output(%r{origin/release/17.0.0 HEAD head.*Evaluating CI on parent}m).to_stdout
      expect(result).to eq("parent")
    end

    it "walks back over a chain of consecutive non-runtime-only commits" do
      runtime = { "c0" => true, "c1" => true, "c2" => true, "c3" => false }
      parents = { "c0" => "c1", "c1" => "c2", "c2" => "c3" }
      allow(self).to receive(:commit_non_runtime_only?) { |**kwargs| runtime.fetch(kwargs[:sha]) }
      allow(self).to receive(:git_parent_sha) { |**kwargs| parents[kwargs[:sha]] }

      result = nil
      expect { result = main_ci_evaluation_sha(monorepo_root:, head_sha: "c0") }
        .to output(/Skipped 3 non-runtime commit\(s\): c0, c1, c2/).to_stdout
      expect(result).to eq("c3")
    end

    it "evaluates HEAD verbatim when RELEASE_CI_EVALUATE_HEAD is set" do
      allow(self).to receive(:ci_evaluate_head_only?).and_return(true)

      expect(self).not_to receive(:commit_non_runtime_only?)
      expect(main_ci_evaluation_sha(monorepo_root:, head_sha: "head")).to eq("head")
    end

    it "fail-safes to evaluating HEAD when the detector is unavailable" do
      # No stub on commit_non_runtime_only?: with no detector script under this
      # root the real predicate returns false, so the walk never starts.
      expect(self).not_to receive(:git_parent_sha)
      expect(main_ci_evaluation_sha(monorepo_root: "/nonexistent/repo", head_sha: "head")).to eq("head")
    end

    it "stops at a root commit even when it is non-runtime-only" do
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "root").and_return(true)
      allow(self).to receive(:git_parent_sha)
        .with(monorepo_root:, sha: "root").and_return(nil)

      expect(main_ci_evaluation_sha(monorepo_root:, head_sha: "root")).to eq("root")
    end

    it "stops after MAIN_CI_NONRUNTIME_WALK_LIMIT commits" do
      allow(self).to receive(:commit_non_runtime_only?).and_return(true)
      # Each commit reports a distinct parent, so only the cap terminates the walk.
      allow(self).to receive(:git_parent_sha) { |**kwargs| "#{kwargs[:sha]}-p" }

      result = nil
      expect { result = main_ci_evaluation_sha(monorepo_root:, head_sha: "c") }
        .to output(/Skipped #{MAIN_CI_NONRUNTIME_WALK_LIMIT} non-runtime/o).to_stdout
      expect(result).to eq("c#{'-p' * MAIN_CI_NONRUNTIME_WALK_LIMIT}")
    end
  end

  describe "#commit_non_runtime_only?" do
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    # Create a throwaway repo root with a (real, executable or not) detector
    # script so `File.executable?` reflects reality; the detector itself is
    # stubbed via Open3 so tests stay hermetic.
    def with_detector(executable: true)
      Dir.mktmpdir do |root|
        Dir.mkdir(File.join(root, "script"))
        detector = File.join(root, "script", "ci-changes-detector")
        File.write(detector, "#!/bin/sh\n")
        File.chmod(executable ? 0o755 : 0o644, detector)
        yield root
      end
    end

    def stub_detector_output(content)
      allow(Open3).to receive(:capture2e) do |env, *_cmd, **_opts|
        File.write(env["GITHUB_OUTPUT"], content)
        ["", success_status]
      end
    end

    it "returns false when the detector script is not executable" do
      with_detector(executable: false) do |root|
        expect(Open3).not_to receive(:capture2e)
        expect(commit_non_runtime_only?(monorepo_root: root, sha: "abc")).to be false
      end
    end

    it "returns true when the detector reports non_runtime_only=true" do
      with_detector do |root|
        stub_detector_output("docs_only=true\nnon_runtime_only=true\n")
        expect(commit_non_runtime_only?(monorepo_root: root, sha: "abc")).to be true
      end
    end

    it "returns false when the detector reports non_runtime_only=false" do
      with_detector do |root|
        stub_detector_output("non_runtime_only=false\n")
        expect(commit_non_runtime_only?(monorepo_root: root, sha: "abc")).to be false
      end
    end

    it "passes the commit range and GITHUB_OUTPUT env to the detector" do
      with_detector do |root|
        detector = File.join(root, "script", "ci-changes-detector")
        expect(Open3).to receive(:capture2e) do |env, *cmd, **opts|
          expect(env).to include("GITHUB_OUTPUT")
          expect(cmd).to eq([detector, "abc^", "abc"])
          expect(opts).to eq(chdir: root)
          File.write(env["GITHUB_OUTPUT"], "non_runtime_only=true\n")
          ["", success_status]
        end
        expect(commit_non_runtime_only?(monorepo_root: root, sha: "abc")).to be true
      end
    end

    it "returns false when the detector exits non-zero" do
      with_detector do |root|
        allow(Open3).to receive(:capture2e).and_return(["boom", failure_status])
        expect(commit_non_runtime_only?(monorepo_root: root, sha: "abc")).to be false
      end
    end

    it "returns false when the detector output omits the non_runtime_only flag" do
      with_detector do |root|
        stub_detector_output("docs_only=true\n")
        expect(commit_non_runtime_only?(monorepo_root: root, sha: "abc")).to be false
      end
    end
  end

  describe "#release_finalization_metadata_commit?" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    def stub_metadata_changes(sha:, output:, status: success_status)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "diff-tree", "--no-commit-id", "--name-status", "-r", "#{sha}^", sha)
        .and_return([output, status])
    end

    def stub_metadata_file(sha:, path:, before:, after:)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "show", "#{sha}^:#{path}")
        .and_return([before, success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "show", "#{sha}:#{path}")
        .and_return([after, success_status])
    end

    def package_json_metadata(version:, react_version: "19.0.7")
      "#{JSON.pretty_generate({ 'name' => 'react-on-rails', 'version' => version,
                                'dependencies' => { 'react' => react_version } })}\n"
    end

    def version_file_metadata(version:, protocol_version: "1")
      <<~RUBY
        module ReactOnRails
          VERSION = "#{version}"
          PROTOCOL_VERSION = "#{protocol_version}"
        end
      RUBY
    end

    def gemfile_lock_metadata(release_version:, rack_version: "3.0.0")
      <<~LOCK
        GEM
          specs:
            rack (#{rack_version})
            react_on_rails (#{release_version})
            react_on_rails_pro (#{release_version})

        DEPENDENCIES
          react_on_rails (= #{release_version})
          react_on_rails_pro
      LOCK
    end

    it "allows commits that modify only release finalization metadata" do
      metadata_files = {
        "react_on_rails/lib/react_on_rails/version.rb" => [
          version_file_metadata(version: "17.0.0.rc.5"),
          version_file_metadata(version: "17.0.0")
        ],
        "react_on_rails_pro/lib/react_on_rails_pro/version.rb" => [
          version_file_metadata(version: "17.0.0.rc.5"),
          version_file_metadata(version: "17.0.0")
        ],
        "package.json" => [
          package_json_metadata(version: "17.0.0-rc.5"),
          package_json_metadata(version: "17.0.0")
        ],
        "packages/react-on-rails/package.json" => [
          package_json_metadata(version: "17.0.0-rc.5"),
          package_json_metadata(version: "17.0.0")
        ],
        "react_on_rails_pro/spec/execjs-compatible-dummy/Gemfile.lock" => [
          gemfile_lock_metadata(release_version: "17.0.0.rc.5"),
          gemfile_lock_metadata(release_version: "17.0.0")
        ]
      }

      stub_metadata_changes(
        sha: "finalsha",
        output: metadata_files.keys.map { |path| "M\t#{path}" }.join("\n")
      )
      metadata_files.each do |path, (before, after)|
        stub_metadata_file(sha: "finalsha", path:, before:, after:)
      end

      expect(release_finalization_metadata_commit?(monorepo_root:, sha: "finalsha")).to be true
    end

    it "rejects commits that include runtime paths" do
      stub_metadata_changes(
        sha: "runtimesha",
        output: [
          "M\treact_on_rails/lib/react_on_rails/engine.rb",
          "M\treact_on_rails/lib/react_on_rails/version.rb"
        ].join("\n")
      )

      expect(release_finalization_metadata_commit?(monorepo_root:, sha: "runtimesha")).to be false
    end

    it "rejects package metadata when fields besides version change" do
      path = "packages/react-on-rails/package.json"
      stub_metadata_changes(sha: "packagesha", output: "M\t#{path}\n")
      stub_metadata_file(
        sha: "packagesha",
        path:,
        before: package_json_metadata(version: "17.0.0-rc.5"),
        after: package_json_metadata(version: "17.0.0", react_version: "19.0.8")
      )

      expect(release_finalization_metadata_commit?(monorepo_root:, sha: "packagesha")).to be false
    end

    it "rejects lockfile metadata when dependencies besides release gem versions change" do
      path = "react_on_rails_pro/Gemfile.lock"
      stub_metadata_changes(sha: "locksha", output: "M\t#{path}\n")
      stub_metadata_file(
        sha: "locksha",
        path:,
        before: gemfile_lock_metadata(release_version: "17.0.0.rc.5"),
        after: gemfile_lock_metadata(release_version: "17.0.0", rack_version: "3.0.1")
      )

      expect(release_finalization_metadata_commit?(monorepo_root:, sha: "locksha")).to be false
    end

    it "rejects non-modification metadata changes" do
      stub_metadata_changes(sha: "deletesha", output: "D\tpackage.json\n")

      expect(release_finalization_metadata_commit?(monorepo_root:, sha: "deletesha")).to be false
    end

    it "rejects empty diffs and git failures" do
      stub_metadata_changes(sha: "emptysha", output: "")
      expect(release_finalization_metadata_commit?(monorepo_root:, sha: "emptysha")).to be false

      stub_metadata_changes(sha: "badsha", output: "fatal: bad revision", status: failure_status)
      expect(release_finalization_metadata_commit?(monorepo_root:, sha: "badsha")).to be false
    end
  end

  describe "#git_parent_sha" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    it "returns the first parent of a commit" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "child^")
        .and_return(["parentsha\n", success_status])

      expect(git_parent_sha(monorepo_root:, sha: "child")).to eq("parentsha")
    end

    it "returns nil at a root commit (git reports failure)" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "root^")
        .and_return(["", failure_status])

      expect(git_parent_sha(monorepo_root:, sha: "root")).to be_nil
    end

    it "returns nil when git succeeds but yields empty output" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "weird^")
        .and_return(["\n", success_status])

      expect(git_parent_sha(monorepo_root:, sha: "weird")).to be_nil
    end
  end

  describe "#required_check_names_for_branch" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }
    let(:expected_jq) { "{contexts: (.contexts // []), checks: (.checks // [] | map({context, app_id}))}" }

    before do
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return("shakacode/react_on_rails")
    end

    it "returns legacy required status contexts when branch protection is configured" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([{ contexts: %w[Lint Test], checks: [] }.to_json, success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to eq(
        contexts: %w[Lint Test],
        checks: []
      )
    end

    it "returns modern required check contexts and app IDs when branch protection uses checks" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([
                      {
                        contexts: [],
                        checks: [
                          { context: "CodeQL", app_id: 15_368 },
                          { context: "Lint", app_id: nil }
                        ]
                      }.to_json,
                      success_status
                    ])

      expect(required_check_names_for_branch(monorepo_root:)).to eq(
        contexts: [],
        checks: [
          { context: "CodeQL", app_id: 15_368 },
          { context: "Lint", app_id: nil }
        ]
      )
    end

    it "returns legacy contexts and modern checks separately when both are configured" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([
                      {
                        contexts: %w[Lint Test],
                        checks: [
                          { context: "CodeQL", app_id: -1 },
                          { context: "Lint", app_id: nil }
                        ]
                      }.to_json,
                      success_status
                    ])

      expect(required_check_names_for_branch(monorepo_root:)).to eq(
        contexts: %w[Test],
        checks: [
          { context: "CodeQL", app_id: -1 },
          { context: "Lint", app_id: nil }
        ]
      )
    end

    it "returns nil when the branch protection endpoint returns an error" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return(["HTTP 404: Branch not protected", failure_status])

      expect(required_check_names_for_branch(monorepo_root:)).to be_nil
    end

    it "returns nil when the protection response yields an empty array (fail-safe)" do
      # Newer branch protection rules can return `contexts: []` with the real required
      # names in `checks`. The combined jq query above returns `[]` only when neither
      # field has names. Treat that as "no protection visible" and let the caller
      # evaluate every check run rather than abort with :no_required_checks.
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([{ contexts: [], checks: [] }.to_json, success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to be_nil
    end

    it "url-encodes the ci_branch when querying branch protection" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/release%2F17.0.0/protection/required_status_checks")
        .and_return([{ contexts: %w[Lint], checks: [] }.to_json, success_status])

      expect(required_check_names_for_branch(monorepo_root:, ci_branch: "release/17.0.0")).to eq(
        contexts: %w[Lint],
        checks: []
      )
    end
  end

  describe "#same_release_base?" do
    it "returns false for different patch versions" do
      expect(same_release_base?("17.0.1.rc.0", "17.0.0")).to be(false)
    end

    it "returns false for different minor versions" do
      expect(same_release_base?("17.1.0.rc.0", "17.0.0")).to be(false)
    end

    it "returns true for the same release base with different prerelease metadata" do
      expect(same_release_base?("17.0.0.rc.3", "17.0.0")).to be(true)
    end
  end

  describe "#stable_release_branch_allowed?" do
    it "allows a stable release from main" do
      expect(stable_release_branch_allowed?(current_branch: "main", target_gem_version: "17.0.0")).to be(true)
    end

    it "allows a stable release from the matching release branch" do
      expect(stable_release_branch_allowed?(current_branch: "release/17.0.0", target_gem_version: "17.0.0"))
        .to be(true)
    end

    it "rejects a stable release from a mismatched release branch" do
      expect(stable_release_branch_allowed?(current_branch: "release/16.7.1", target_gem_version: "17.0.0"))
        .to be(false)
    end

    it "rejects a stable release from an arbitrary feature branch" do
      expect(stable_release_branch_allowed?(current_branch: "jg/some-fix", target_gem_version: "17.0.0"))
        .to be(false)
    end
  end

  describe "#ensure_release_branch_matches_target_base!" do
    it "allows prerelease cuts from the matching release branch" do
      expect do
        ensure_release_branch_matches_target_base!(
          current_branch: "release/17.0.0",
          target_gem_version: "17.0.0.rc.0"
        )
      end.not_to raise_error
    end

    it "allows prerelease cuts from non-release branches" do
      expect do
        ensure_release_branch_matches_target_base!(
          current_branch: "jg/some-fix",
          target_gem_version: "17.0.0.rc.0"
        )
      end.not_to raise_error
    end

    it "allows stable releases from main" do
      expect do
        ensure_release_branch_matches_target_base!(
          current_branch: "main",
          target_gem_version: "17.0.0"
        )
      end.not_to raise_error
    end

    it "rejects prerelease cuts from a mismatched release branch" do
      expect do
        ensure_release_branch_matches_target_base!(
          current_branch: "release/16.7.1",
          target_gem_version: "17.0.0.rc.0"
        )
      end.to raise_error(SystemExit, /Release branch must match the target release line/)
    end
  end

  describe "#ensure_release_branch_promotes_tagged_rc!" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }
    let(:not_ancestor_status) { instance_double(Process::Status, success?: false, exitstatus: 1) }
    let(:git_error_status) { instance_double(Process::Status, success?: false, exitstatus: 128) }
    let(:remote_rc_tag_ref) { "refs/tags/v17.0.0.rc.3" }
    let(:remote_rc_tag_fetch_args) do
      ["git", "-C", monorepo_root, "fetch", "--force", "--no-tags", "--quiet",
       "origin", "#{remote_rc_tag_ref}:#{remote_rc_tag_ref}"]
    end

    before do
      allow(self).to receive(:remote_git_tag_exists?).and_call_original
      allow(self)
        .to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0.rc.3")
        .and_return(true)
      allow(self).to receive(:latest_remote_rc_tag_for_version).and_call_original
    end

    def stub_remote_rc_tag_fetch
      allow(Open3).to receive(:capture2e).with(*remote_rc_tag_fetch_args).and_return(["", success_status])
    end

    it "does not inspect tags for stable releases from main" do
      expect(Open3).not_to receive(:capture2e)

      ensure_release_branch_promotes_tagged_rc!(
        monorepo_root:,
        current_branch: "main",
        current_checkout_version: "17.0.0",
        target_gem_version: "17.0.1"
      )
    end

    it "allows a matching release branch when HEAD is the current RC tag" do
      stub_remote_rc_tag_fetch
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
        .and_return(["abc123\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["abc123\n", success_status])

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.3",
          target_gem_version: "17.0.0"
        )
      end.not_to raise_error

      expect(Open3).to have_received(:capture2e).with(*remote_rc_tag_fetch_args)
      expect(Open3)
        .to have_received(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
      expect(Open3).to have_received(:capture2e).with("git", "-C", monorepo_root, "rev-parse", "HEAD")
      expect(self).to have_received(:remote_git_tag_exists?).with(monorepo_root:, tag: "v17.0.0.rc.3")
    end

    it "allows non-runtime finalization commits after the current RC tag" do
      stub_remote_rc_tag_fetch
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
        .and_return(["tagsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["headsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "merge-base", "--is-ancestor", "tagsha", "headsha")
        .and_return(["", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-list", "--reverse", "tagsha..headsha")
        .and_return(["changelogsha\nnotessha\n", success_status])
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "changelogsha")
        .and_return(true)
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "notessha")
        .and_return(true)

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.3",
          target_gem_version: "17.0.0"
        )
      end.to output(/metadata-only commit\(s\) after v17\.0\.0\.rc\.3/).to_stdout

      expect(Open3)
        .to have_received(:capture2e)
        .with("git", "-C", monorepo_root, "merge-base", "--is-ancestor", "tagsha", "headsha")
      expect(Open3)
        .to have_received(:capture2e)
        .with("git", "-C", monorepo_root, "rev-list", "--reverse", "tagsha..headsha")
    end

    it "allows an already-bumped final release branch retry before the stable tag exists" do
      stub_remote_rc_tag_fetch
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0^{}")
        .and_return(["", failure_status])
      allow(self)
        .to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0")
        .and_return(false)
      allow(self)
        .to receive(:latest_remote_rc_tag_for_version)
        .with(monorepo_root:, target_gem_version: "17.0.0")
        .and_return("v17.0.0.rc.3")
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
        .and_return(["tagsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["headsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "merge-base", "--is-ancestor", "tagsha", "headsha")
        .and_return(["", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-list", "--reverse", "tagsha..headsha")
        .and_return(["versionbumpsha\n", success_status])
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "versionbumpsha")
        .and_return(false)
      allow(self).to receive(:release_finalization_metadata_commit?)
        .with(monorepo_root:, sha: "versionbumpsha")
        .and_return(true)

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0",
          target_gem_version: "17.0.0"
        )
      end.to output(/metadata-only commit\(s\) after v17\.0\.0\.rc\.3/).to_stdout
    end

    it "aborts an already-bumped final release branch retry when the stable tag exists" do
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0^{}")
        .and_return(["stabletagsha\n", success_status])

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /already tagged/)

      expect(self).not_to have_received(:latest_remote_rc_tag_for_version)
    end

    it "aborts when a stable release branch is on a different stable version" do
      expect(Open3).not_to receive(:capture2e)

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.1",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /Unexpected stable checkout version/)
    end

    it "aborts when a release branch final promotion starts from a non-RC prerelease" do
      expect(Open3).not_to receive(:capture2e)

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.beta.1",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /must use an RC prerelease/)
    end

    it "aborts when the current RC is for a different final version" do
      expect(Open3).not_to receive(:capture2e)

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.1.rc.1",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /must use an RC for the target version/)
    end

    it "aborts when the current RC tag is missing" do
      stub_remote_rc_tag_fetch
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
        .and_return(["", failure_status])

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.3",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /Expected tag: v17.0.0.rc.3/)

      expect(Open3).to have_received(:capture2e).with(*remote_rc_tag_fetch_args)
      expect(Open3)
        .to have_received(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
    end

    it "aborts when the accepted remote RC tag cannot be force-fetched" do
      allow(Open3)
        .to receive(:capture2e)
        .with(*remote_rc_tag_fetch_args)
        .and_return(["would clobber existing tag", failure_status])

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.3",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /Unable to fetch remote RC tag/)
    end

    it "aborts when the current RC tag exists only locally" do
      allow(self)
        .to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0.rc.3")
        .and_return(false)

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.3",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /Expected remote tag: v17.0.0.rc.3/)
    end

    it "aborts when the release branch tip differs from the current RC tag" do
      stub_remote_rc_tag_fetch
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
        .and_return(["tagsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["headsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "merge-base", "--is-ancestor", "tagsha", "headsha")
        .and_return(["", not_ancestor_status])

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.3",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /must descend from the accepted RC tag/)

      expect(Open3)
        .to have_received(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
      expect(Open3).to have_received(:capture2e).with("git", "-C", monorepo_root, "rev-parse", "HEAD")
      expect(Open3)
        .to have_received(:capture2e)
        .with("git", "-C", monorepo_root, "merge-base", "--is-ancestor", "tagsha", "headsha")
    end

    it "aborts when the RC tag ancestry check errors" do
      stub_remote_rc_tag_fetch
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
        .and_return(["tagsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["headsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "merge-base", "--is-ancestor", "tagsha", "headsha")
        .and_return(["fatal: bad object tagsha", git_error_status])

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.3",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /Unable to verify RC tag ancestry/)
    end

    it "aborts when commits after the RC tag cannot be listed" do
      stub_remote_rc_tag_fetch
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
        .and_return(["tagsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["headsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "merge-base", "--is-ancestor", "tagsha", "headsha")
        .and_return(["", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-list", "--reverse", "tagsha..headsha")
        .and_return(["fatal: invalid range", failure_status])

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.3",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /Unable to list commits after RC tag/)
    end

    it "aborts when runtime-bearing commits follow the current RC tag" do
      stub_remote_rc_tag_fetch
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0.rc.3^{}")
        .and_return(["tagsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["headsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "merge-base", "--is-ancestor", "tagsha", "headsha")
        .and_return(["", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-list", "--reverse", "tagsha..headsha")
        .and_return(["runtimesha\n", success_status])
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "runtimesha")
        .and_return(false)
      allow(self).to receive(:release_finalization_metadata_commit?)
        .with(monorepo_root:, sha: "runtimesha")
        .and_return(false)

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.3",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /Runtime-bearing commits require a new RC/)
    end
  end

  describe "#release_ci_branch" do
    it "returns the release branch itself when on a release branch" do
      expect(release_ci_branch("release/17.0.0")).to eq("release/17.0.0")
    end

    it "returns main for the main branch" do
      expect(release_ci_branch("main")).to eq("main")
    end

    it "returns main for any non-release branch" do
      expect(release_ci_branch("jg/some-fix")).to eq("main")
    end
  end
end
