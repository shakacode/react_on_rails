# frozen_string_literal: true

require_relative "simplecov_helper"
require_relative "spec_helper"
require "tmpdir"

RSpec.describe "release.rake helper methods" do
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

        section = extract_changelog_section(changelog_path: changelog_path, version: "16.4.0")
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

        section = extract_changelog_section(changelog_path: changelog_path, version: "16.4.0")
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
        .with(repo_slug: repo_slug, ref: "release-branch")
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
          repo_slug: repo_slug,
          ref: "release-branch",
          head_sha: head_sha,
          ignored_run_ids: ["999999"]
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
          monorepo_root: monorepo_root,
          ref: "release-branch",
          head_sha: head_sha,
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
          repo_slug: repo_slug,
          ref: "release-branch",
          head_sha: head_sha,
          ignored_run_ids: ["999999"]
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
          monorepo_root: monorepo_root,
          ref: "release-branch",
          head_sha: head_sha,
          allow_override: true,
          dry_run: false
        )
      end.to output(/skipping ShakaPerf release gate/).to_stdout
    end

    it "prints the intended gate during dry runs without dispatching" do
      expect(self).not_to receive(:capture_gh_output)

      expect do
        run_shakaperf_release_gate!(
          monorepo_root: monorepo_root,
          ref: "release-branch",
          head_sha: head_sha,
          allow_override: false,
          dry_run: true
        )
      end.to output(/DRY RUN: Would run ShakaPerf release gate/).to_stdout
    end

    it "aborts when workflow dispatch fails" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: repo_slug, ref: "release-branch")
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
          monorepo_root: monorepo_root,
          ref: "release-branch",
          head_sha: head_sha,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, /Unable to dispatch ShakaPerf release gate workflow.*HTTP 404/m)
    end

    it "aborts when the matching gate run fails" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: repo_slug, ref: "release-branch")
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
          repo_slug: repo_slug,
          ref: "release-branch",
          head_sha: head_sha,
          ignored_run_ids: []
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
          monorepo_root: monorepo_root,
          ref: "release-branch",
          head_sha: head_sha,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, %r{ShakaPerf release gate failed.*actions/runs/123456.*Tests failed}m)
    end

    it "aborts when watching the matching gate run times out" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: repo_slug, ref: "release-branch")
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
          repo_slug: repo_slug,
          ref: "release-branch",
          head_sha: head_sha,
          ignored_run_ids: []
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
          monorepo_root: monorepo_root,
          ref: "release-branch",
          head_sha: head_sha,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, %r{Timed out watching ShakaPerf release gate run 123456.*actions/runs/123456}m)
    end

    it "finds the workflow_dispatch run for the pushed head SHA" do
      matching_run = { "databaseId" => 2, "headSha" => head_sha }
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: repo_slug, ref: "release-branch")
        .and_return([{ "databaseId" => 1, "headSha" => "old" }, matching_run])

      expect(
        wait_for_shakaperf_release_gate_run!(repo_slug: repo_slug, ref: "release-branch", head_sha: head_sha)
      ).to eq(matching_run)
    end

    it "ignores stale workflow_dispatch runs for the same head SHA" do
      stale_run = { "databaseId" => 1, "headSha" => head_sha }
      matching_run = { "databaseId" => 2, "headSha" => head_sha }
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: repo_slug, ref: "release-branch")
        .and_return([stale_run, matching_run])

      expect(
        wait_for_shakaperf_release_gate_run!(
          repo_slug: repo_slug,
          ref: "release-branch",
          head_sha: head_sha,
          ignored_run_ids: [1]
        )
      ).to eq(matching_run)
    end

    it "aborts when no matching workflow_dispatch run appears before the deadline" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: repo_slug, ref: "release-branch")
        .and_return([{ "databaseId" => 1, "headSha" => "other" }])
      stub_const("SHAKAPERF_RELEASE_GATE_START_TIMEOUT_SECONDS", -1)

      expect do
        wait_for_shakaperf_release_gate_run!(
          repo_slug: repo_slug,
          ref: "release-branch",
          head_sha: head_sha
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

    # `validate_main_ci_status!` now queries `required_check_names_for_main`
    # unconditionally so the missing-required-check gate can apply to both
    # stable and prerelease. The helper shells out to `git -C monorepo_root`
    # which would abort in tests where `monorepo_root` is a stub path. Default
    # to "no required checks configured" so tests that don't care about the
    # gate behave as before; tests that exercise the gate override this stub.
    before do
      allow(self).to receive(:required_check_names_for_main)
        .with(monorepo_root: monorepo_root).and_return(nil)
    end

    def next_check_run_id
      @next_check_run_id ||= 999
      @next_check_run_id += 1
    end

    # Distinct defaults keep same-named helper-generated runs from collapsing
    # in the nil-check_suite dedup path. Tests can still pin an id to model a
    # specific GitHub payload.
    def passing_run(name, id: next_check_run_id)
      {
        "id" => id,
        "name" => name,
        "status" => "completed",
        "conclusion" => "success",
        "html_url" => "https://github.com/shakacode/react_on_rails/runs/#{name.gsub(/\W/, '_')}"
      }
    end

    def failing_run(name, conclusion: "failure", id: next_check_run_id)
      {
        "id" => id,
        "name" => name,
        "status" => "completed",
        "conclusion" => conclusion,
        "html_url" => "https://github.com/shakacode/react_on_rails/runs/#{name.gsub(/\W/, '_')}"
      }
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint"), passing_run("Test")])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(2 checks\)/).to_stdout
      end
    end

    context "when a check has failed on a stable release" do
      it "aborts with the failing check name and link" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint"), failing_run("JS unit tests")])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint"), failing_run("Benchmark Workflow")])
        allow(self).to receive(:required_check_names_for_main)
          .with(monorepo_root: monorepo_root).and_return(["Lint"])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [failing_run("Lint"), passing_run("Benchmark Workflow")])
        allow(self).to receive(:required_check_names_for_main)
          .with(monorepo_root: monorepo_root).and_return(["Lint"])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint"), in_progress_run("Slow test")])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [failing_run("JS unit tests"), in_progress_run("Slow test")])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [old_failed, new_passed])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [workflow_a_passing, workflow_b_failing])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint"), failing_run("Lint")])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [suite_a_old_failed, suite_a_new_passed, suite_b_passing])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: true, dry_run: false)
          .and_return(sha: sha, check_runs: [failing_run("Lint")])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: true)
          .and_return(sha: sha, check_runs: [failing_run("Lint")])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: true)
          .and_return(nil)

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint"), failing_run("Optional Check")])
        allow(self).to receive(:required_check_names_for_main)
          .with(monorepo_root: monorepo_root).and_return(nil)

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint")])
        allow(self).to receive(:required_check_names_for_main)
          .with(monorepo_root: monorepo_root).and_return(["DoesNotExist"])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint"), passing_run("Test")])
        allow(self).to receive(:required_check_names_for_main)
          .with(monorepo_root: monorepo_root).and_return(%w[Lint Test Build])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint"), passing_run("Test")])
        allow(self).to receive(:required_check_names_for_main)
          .with(monorepo_root: monorepo_root).and_return(%w[Lint Test Build])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
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
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint"), weird_run])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /Check run\(s\) with unrecognized status.*Future Status/m)
      end

      it "treats a nil status as a failure too" do
        weird_run = passing_run("Malformed").merge("status" => nil, "conclusion" => nil)
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root: monorepo_root, allow_override: false, dry_run: false)
          .and_return(sha: sha, check_runs: [passing_run("Lint"), weird_run])

        expect do
          validate_main_ci_status!(
            monorepo_root: monorepo_root,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /Check run\(s\) with unrecognized status.*Malformed/m)
      end
    end

    it "raises when asked to format an unknown CI violation kind" do
      expect do
        format_main_ci_status_violation(kind: :typo, short_sha: short_sha, runs: [])
      end.to raise_error(ArgumentError, /Unknown CI violation kind: :typo/)
    end
  end

  describe "#fetch_main_ci_checks" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    it "aborts if `git fetch origin main` fails" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["fetch failed: network down", failure_status])

      expect do
        fetch_main_ci_checks(monorepo_root: monorepo_root)
      end.to raise_error(SystemExit, %r{Unable to fetch origin/main})
    end

    it "warns instead of aborting when `git fetch` fails with allow_override" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["fetch failed: network down", failure_status])

      result = nil
      expect do
        result = fetch_main_ci_checks(monorepo_root: monorepo_root, allow_override: true)
      end.to output(%r{CI STATUS OVERRIDE enabled.*Unable to fetch origin/main}m).to_stdout
      expect(result).to be_nil
    end

    it "warns instead of aborting when `git fetch` fails in dry-run mode" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", "main", "--quiet")
        .and_return(["fetch failed: network down", failure_status])

      result = nil
      expect do
        result = fetch_main_ci_checks(monorepo_root: monorepo_root, dry_run: true)
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
        fetch_main_ci_checks(monorepo_root: monorepo_root)
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
        fetch_main_ci_checks(monorepo_root: monorepo_root)
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
        result = fetch_main_ci_checks(monorepo_root: monorepo_root, dry_run: true)
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
        result = fetch_main_ci_checks(monorepo_root: monorepo_root, dry_run: true)
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

      result = fetch_main_ci_checks(monorepo_root: monorepo_root)
      expect(result[:sha]).to eq("abc1234def")
      expect(result[:repo_slug]).to eq("shakacode/react_on_rails")
      expect(result[:check_runs].length).to eq(2)
      expect(result[:check_runs].first["name"]).to eq("Lint")
    end
  end

  describe "#required_check_names_for_main" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }
    let(:expected_jq) { "(.contexts // []) + (.checks // [] | map(.context)) | unique" }

    before do
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return("shakacode/react_on_rails")
    end

    it "returns legacy required status contexts when branch protection is configured" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([%w[Lint Test].to_json, success_status])

      expect(required_check_names_for_main(monorepo_root: monorepo_root)).to eq(%w[Lint Test])
    end

    it "returns modern required check contexts when branch protection uses checks" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([%w[CodeQL Lint].to_json, success_status])

      expect(required_check_names_for_main(monorepo_root: monorepo_root)).to eq(%w[CodeQL Lint])
    end

    it "returns the deduplicated union when branch protection has contexts and checks" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([%w[CodeQL Lint Test].to_json, success_status])

      expect(required_check_names_for_main(monorepo_root: monorepo_root)).to eq(%w[CodeQL Lint Test])
    end

    it "returns nil when the branch protection endpoint returns an error" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return(["HTTP 404: Branch not protected", failure_status])

      expect(required_check_names_for_main(monorepo_root: monorepo_root)).to be_nil
    end

    it "returns nil when the protection response yields an empty array (fail-safe)" do
      # Newer branch protection rules can return `contexts: []` with the real required
      # names in `checks`. The combined jq query above returns `[]` only when neither
      # field has names. Treat that as "no protection visible" and let the caller
      # evaluate every check run rather than abort with :no_required_checks.
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return(["[]", success_status])

      expect(required_check_names_for_main(monorepo_root: monorepo_root)).to be_nil
    end
  end
end
