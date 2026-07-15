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

  def accelerated_rc_test_authorization(tracker: 3823)
    build_accelerated_rc_publication_record(
      options: {
        target_gem_version: "17.0.0.rc.10",
        tracker:,
        reason: "Start published-artifact QA while remaining checks finish"
      },
      candidate_sha: "f" * 40,
      runtime_tree_fingerprint: "a" * 64,
      release_branch: "release/17.0.0",
      ci_snapshot: {
        status: "pending",
        sha: "f" * 40,
        checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
        non_success: [
          {
            name: "generator",
            state: "in_progress",
            url: "https://github.com/shakacode/react_on_rails/actions/runs/123"
          }
        ]
      },
      shakaperf: {
        status: "pending",
        run_id: 123_456,
        attempt: 1,
        run_url: "https://github.com/shakacode/react_on_rails/actions/runs/123456",
        candidate_sha: "f" * 40,
        target_version: "17.0.0.rc.10",
        release_started_at: "2026-07-14T13:00:00Z"
      },
      approved_by: "justin808",
      recorded_at: Time.utc(2026, 7, 14, 13, 30)
    )
  end

  def accelerated_rc_test_accepted_history(tracker: 3823)
    authorization = accelerated_rc_test_authorization(tracker:)
    publication = accelerated_rc_published_record(
      authorized_record: authorization,
      recorded_at: Time.utc(2026, 7, 14, 14)
    )
    accepted = publication.merge(
      "status" => "candidate-accepted",
      "ci" => publication.fetch("ci").merge("status" => "success", "non_success" => []),
      "shakaperf" => publication.fetch("shakaperf").merge("status" => "success"),
      "reason" => "All required evidence passed",
      "recorded_at" => "2026-07-14T15:00:00Z",
      "required_follow_up" => "Proceed only through the strict final promotion gates.",
      "evidence" => {
        "demo_fleet" => "https://github.com/demo-fleet",
        "behavioral" => "https://github.com/behavioral",
        "artifacts" => "https://github.com/artifacts"
      }
    )
    [authorization, publication, accepted]
  end

  def accelerated_rc_test_rejected_history(tracker: 3823)
    authorization, publication, accepted = accelerated_rc_test_accepted_history(tracker:)
    rejected = accepted.merge(
      "status" => "candidate-rejected",
      "ci" => accepted.fetch("ci").merge(
        "status" => "failed",
        "non_success" => [{
          "name" => "generator",
          "state" => "failure",
          "url" => "https://github.com/shakacode/react_on_rails/actions/runs/999"
        }]
      ),
      "reason" => "Current exact-candidate CI failed",
      "required_follow_up" => "Do not promote this immutable RC; fix the failure and cut the next RC.",
      "evidence" => {}
    )
    [authorization, publication, rejected]
  end

  def accelerated_final_promotion_test_context(record:, ci_snapshot:, ci_branch: "release/17.0.0",
                                               final_candidate_sha: "e" * 40)
    authorization = accelerated_rc_test_authorization(tracker: record.fetch("release_tracker"))
    {
      candidate_sha: final_candidate_sha,
      ci_branch:,
      final_target_version: Gem::Version.new(record.fetch("target_version")).release.to_s,
      record:,
      source_rc_tag: "v#{record.fetch('target_version')}",
      source_rc_candidate_sha: record.fetch("candidate_sha"),
      source_rc_tag_provenance: accelerated_rc_tag_provenance(authorization),
      ci_snapshot: json_compatible_release_value(ci_snapshot),
      shakaperf_evidence_mode: FINAL_PROMOTION_SHAKAPERF_ACCEPTED_RC_MODE,
      shakaperf_record: {
        "release_branch" => ci_branch,
        "candidate_sha" => record.dig("shakaperf", "candidate_sha"),
        "target_version" => record.fetch("target_version"),
        "shakaperf" => record.fetch("shakaperf")
      }
    }
  end

  def strict_final_promotion_test_context(record:, ci_snapshot:, ci_branch: "release/17.0.0",
                                          final_candidate_sha: "e" * 40)
    context = accelerated_final_promotion_test_context(
      record:, ci_snapshot:, ci_branch:, final_candidate_sha:
    )
    strict_snapshot = record.fetch("shakaperf").merge(
      "candidate_sha" => final_candidate_sha,
      "target_version" => context.fetch(:final_target_version)
    )
    strict_record = {
      "release_branch" => ci_branch,
      "candidate_sha" => final_candidate_sha,
      "target_version" => context.fetch(:final_target_version),
      "shakaperf" => strict_snapshot
    }
    context.merge(
      shakaperf_evidence_mode: FINAL_PROMOTION_SHAKAPERF_STRICT_FINAL_MODE,
      shakaperf_record: strict_record,
      strict_final_shakaperf_identity_anchor: final_promotion_shakaperf_identity_anchor(strict_record)
    )
  end

  def mutate_strict_final_promotion_test_identity!(context, component)
    record = context.fetch(:shakaperf_record)
    snapshot = record.fetch("shakaperf")
    case component
    when :release_branch
      mutate_strict_final_promotion_test_branch!(context:, record:)
    when :candidate_sha
      mutate_strict_final_promotion_test_candidate!(context:, record:, snapshot:)
    when :target_version
      mutate_strict_final_promotion_test_target!(context:, record:, snapshot:)
    when :missing_anchor, :changed_anchor, :mutable_anchor
      mutate_strict_final_promotion_test_anchor!(context:, component:)
    else
      field, value = {
        run_id: ["run_id", 777_777],
        attempt: ["attempt", 2],
        run_url: ["run_url", "https://github.com/shakacode/react_on_rails/actions/runs/777777"],
        release_started_at: ["release_started_at", "2026-07-14T15:00:00Z"]
      }.fetch(component)
      snapshot[field] = value
    end
  end

  def redefine_strict_final_promotion_test_identity_and_anchor!(context, component)
    if component == :run_identity
      snapshot = context.dig(:shakaperf_record, "shakaperf")
      snapshot.merge!(
        "run_id" => 777_777,
        "attempt" => 2,
        "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/777777"
      )
    else
      mutate_strict_final_promotion_test_identity!(context, component)
    end
    context[:strict_final_shakaperf_identity_anchor] =
      final_promotion_shakaperf_identity_anchor(context.fetch(:shakaperf_record))
  end

  def mutate_strict_final_promotion_test_branch!(context:, record:)
    context[:ci_branch] = "release/17.0.0-mutated"
    record["release_branch"] = context.fetch(:ci_branch)
  end

  def mutate_strict_final_promotion_test_anchor!(context:, component:)
    case component
    when :missing_anchor
      context.delete(:strict_final_shakaperf_identity_anchor)
    when :changed_anchor
      context[:strict_final_shakaperf_identity_anchor] = "{}"
    when :mutable_anchor
      context[:strict_final_shakaperf_identity_anchor] =
        context.fetch(:strict_final_shakaperf_identity_anchor).dup
    end
  end

  def mutate_strict_final_promotion_test_candidate!(context:, record:, snapshot:)
    context.fetch(:candidate_sha).replace("d" * 40)
    record["candidate_sha"] = context.fetch(:candidate_sha)
    snapshot["candidate_sha"] = context.fetch(:candidate_sha)
  end

  def mutate_strict_final_promotion_test_target!(context:, record:, snapshot:)
    mutated_rc_target = "17.0.1.rc.10"
    context.fetch(:record)["target_version"] = mutated_rc_target
    context[:source_rc_tag] = "v#{mutated_rc_target}"
    context.fetch(:source_rc_tag_provenance)["target_version"] = mutated_rc_target
    context[:final_target_version] = "17.0.1"
    record["target_version"] = context.fetch(:final_target_version)
    snapshot["target_version"] = context.fetch(:final_target_version)
  end

  def accelerated_rc_test_issue_comment(id:, body:, tracker: 3823, created_at: "2026-07-14T13:00:00Z", user: nil)
    {
      "id" => id,
      "body" => body,
      "issue_url" => "https://api.github.com/repos/shakacode/react_on_rails/issues/#{tracker}",
      "created_at" => created_at,
      "user" => user
    }
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

  describe "#confirm_release!" do
    it "refuses a stable release with no changelog content before prompting even when input would confirm" do
      allow(self).to receive(:extract_changelog_section)
        .with(changelog_path: "/tmp/repo/CHANGELOG.md", version: "17.0.0")
        .and_return(nil)
      expect($stdin).not_to receive(:gets)

      expect do
        confirm_release!(version: "17.0.0", monorepo_root: "/tmp/repo")
      end.to raise_error(SystemExit, /Stable release 17\.0\.0 requires a non-empty CHANGELOG\.md section/)
    end

    it "refuses a stable dry run with no changelog content before reporting success" do
      allow(self).to receive(:extract_changelog_section)
        .with(changelog_path: "/tmp/repo/CHANGELOG.md", version: "17.0.0")
        .and_return(nil)
      expect($stdin).not_to receive(:gets)

      expect do
        confirm_release!(version: "17.0.0", monorepo_root: "/tmp/repo", dry_run: true)
      end.to raise_error(SystemExit, /Stable release 17\.0\.0 requires a non-empty CHANGELOG\.md section/)
    end

    it "warns without prompting during a prerelease dry run with no changelog content" do
      allow(self).to receive(:extract_changelog_section)
        .with(changelog_path: "/tmp/repo/CHANGELOG.md", version: "17.0.0.rc.10")
        .and_return(nil)
      expect($stdin).not_to receive(:gets)

      expect do
        confirm_release!(version: "17.0.0.rc.10", monorepo_root: "/tmp/repo", dry_run: true)
      end.to output(/Prerelease dry run.*no matching non-empty CHANGELOG\.md section/).to_stdout
    end

    it "allows confirmation when the stable release has non-empty changelog content" do
      allow(self).to receive(:extract_changelog_section)
        .with(changelog_path: "/tmp/repo/CHANGELOG.md", version: "17.0.0")
        .and_return("#### Breaking Changes\n\n- Final release notes")
      allow($stdin).to receive(:gets).and_return("y\n")

      expect do
        confirm_release!(version: "17.0.0", monorepo_root: "/tmp/repo")
      end.to output(/Changelog: ✓ section found.*Proceed with release\?/m).to_stdout
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

  describe "#resolve_release_version_before_auth!" do
    it "aborts an argument-less prerelease retry before external authentication checks" do
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root: "/tmp/repo")
        .and_return("17.0.0.rc.10")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("17.0.0.rc.10")
      expect(self).not_to receive(:run_release_preflight_checks!)

      expect do
        resolve_release_version_before_auth!(version_input: "", monorepo_root: "/tmp/repo", dry_run: false)
      end.to raise_error(SystemExit, /bundle exec rake "release\[17\.0\.0\.rc\.10\]"/)
    end

    it "uses the pre-pull prerelease version when a pull advances the checkout to stable" do
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root: "/tmp/repo")
        .and_return("17.0.0")
      expect(self).not_to receive(:current_gem_version)
      expect(self).not_to receive(:run_release_preflight_checks!)

      expect do
        resolve_release_version_before_auth!(
          version_input: "",
          monorepo_root: "/tmp/repo",
          dry_run: false,
          current_version: "17.0.0.rc.10"
        )
      end.to raise_error(SystemExit, /bundle exec rake "release\[17\.0\.0\.rc\.10\]"/)
    end
  end

  describe "#resolve_version_input" do
    it "preserves an explicit prerelease version without inferring from repository state" do
      expect(self).not_to receive(:extract_latest_changelog_version)
      expect(self).not_to receive(:current_gem_version)
      expect(self).not_to receive(:version_tagged?)

      expect(resolve_version_input("17.0.0.rc.10", "/tmp/repo")).to eq("17.0.0.rc.10")
    end

    it "uses the latest changelog version when it is newer than the current gem version" do
      allow(self).to receive(:extract_latest_changelog_version).with(monorepo_root: "/tmp/repo").and_return("16.4.0")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("16.3.0")

      expect(resolve_version_input("", "/tmp/repo")).to eq("16.4.0")
    end

    it "refuses an argument-less prerelease retry before tag lookup instead of inferring stable promotion" do
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root: "/tmp/repo")
        .and_return("17.0.0.rc.10")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("17.0.0.rc.10")
      expect(self).not_to receive(:version_tagged?)

      expect do
        resolve_version_input("", "/tmp/repo")
      end.to raise_error(
        SystemExit,
        /Refusing to infer stable 17\.0\.0.*bundle exec rake "release\[17\.0\.0\.rc\.10\]"/m
      )
    end

    it "refuses argument-less stable promotion from a prerelease checkout" do
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root: "/tmp/repo")
        .and_return("17.0.0")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("17.0.0.rc.10")
      expect(self).not_to receive(:version_tagged?)

      expect do
        resolve_version_input("", "/tmp/repo")
      end.to raise_error(
        SystemExit,
        /Refusing to infer stable 17\.0\.0.*bundle exec rake "release\[17\.0\.0\]"/m
      )
    end

    it "refuses an argument-less prerelease retry when the changelog has no version" do
      allow(self).to receive(:extract_latest_changelog_version).with(monorepo_root: "/tmp/repo").and_return(nil)
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("17.0.0.rc.10")
      expect(self).not_to receive(:version_tagged?)

      expect do
        resolve_version_input("", "/tmp/repo")
      end.to raise_error(
        SystemExit,
        /bundle exec rake "release\[17\.0\.0\.rc\.10\]".*non-empty CHANGELOG\.md section for 17\.0\.0/m
      )
    end

    it "refuses an argument-less prerelease retry when the changelog prerelease is stale" do
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root: "/tmp/repo")
        .and_return("17.0.0.rc.9")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("17.0.0.rc.10")
      expect(self).not_to receive(:version_tagged?)

      expect do
        resolve_version_input("", "/tmp/repo")
      end.to raise_error(SystemExit, /bundle exec rake "release\[17\.0\.0\.rc\.10\]"/)
    end

    it "derives stable-promotion guidance from the current prerelease when the changelog is stale" do
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root: "/tmp/repo")
        .and_return("16.6.0")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("17.0.0.rc.10")

      expect do
        resolve_version_input("", "/tmp/repo")
      end.to raise_error(SystemExit, /stable 17\.0\.0.*bundle exec rake "release\[17\.0\.0\]"/m)
    end

    it "allows an argument-less advance to a newer prerelease from the changelog" do
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root: "/tmp/repo")
        .and_return("17.0.0.rc.11")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("17.0.0.rc.10")

      expect(resolve_version_input("", "/tmp/repo")).to eq("17.0.0.rc.11")
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

    it "blocks an inferred stable patch candidate until matching changelog evidence exists" do
      allow(self).to receive(:extract_latest_changelog_version).with(monorepo_root: "/tmp/repo").and_return("16.2.9")
      allow(self).to receive(:current_gem_version).with("/tmp/repo").and_return("16.3.0")
      allow(self).to receive(:extract_changelog_section)
        .with(changelog_path: "/tmp/repo/CHANGELOG.md", version: "16.3.1")
        .and_return(nil)

      version_input = resolve_version_input("", "/tmp/repo")
      target_version = compute_target_gem_version(current_gem_version: "16.3.0", version_input:)

      expect do
        confirm_release!(version: target_version, monorepo_root: "/tmp/repo", dry_run: true)
      end.to raise_error(SystemExit, /Stable release 16\.3\.1 requires a non-empty CHANGELOG\.md section/)
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

  describe "#shakaperf_prerun_candidate" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:head_sha) { "candidate123" }

    it "identifies a prepared next release on the matching release branch" do
      allow(self).to receive(:current_gem_version).with(monorepo_root).and_return("17.0.0.rc.7")
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root:).and_return("17.0.0.rc.8")
      allow(self).to receive(:extract_changelog_section)
        .with(changelog_path: "/tmp/repo/CHANGELOG.md", version: "17.0.0.rc.8")
        .and_return("#### Fixed\n\n- Release fix")
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root:, sha: head_sha).and_return("a" * 64)

      expect(
        shakaperf_prerun_candidate(
          monorepo_root:,
          ref: "release/17.0.0",
          head_sha:
        )
      ).to eq(
        branch: "release/17.0.0",
        candidate_sha: head_sha,
        target_version: "17.0.0.rc.8",
        runtime_tree_fingerprint: "a" * 64
      )
    end

    it "ignores a changelog push that does not prepare a newer matching release" do
      allow(self).to receive(:current_gem_version).with(monorepo_root).and_return("17.0.0.rc.8")
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root:).and_return("17.0.0.rc.8")

      expect(
        shakaperf_prerun_candidate(
          monorepo_root:,
          ref: "release/17.0.0",
          head_sha:
        )
      ).to be_nil
    end
  end

  describe "#shakaperf_runtime_tree_fingerprint" do
    let(:success_status) { instance_double(Process::Status, success?: true) }

    it "hashes the exact non-release-metadata tree" do
      entries = [
        "100644 blob changelog\tCHANGELOG.md",
        "100644 blob version\treact_on_rails/lib/react_on_rails/version.rb",
        "100644 blob runtime\treact_on_rails/lib/react_on_rails/engine.rb",
        ""
      ].join("\0")
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "ls-tree", "-r", "-z", "--full-tree", "candidate")
        .and_return([entries, success_status])

      expected = Digest::SHA256.hexdigest(
        "100644 blob runtime\treact_on_rails/lib/react_on_rails/engine.rb"
      )
      expect(shakaperf_runtime_tree_fingerprint(monorepo_root: "/tmp/repo", sha: "candidate")).to eq(expected)
    end
  end

  describe "ShakaPerf pre-run workflow contract" do
    let(:repo_root) { File.expand_path("../../..", __dir__) }

    it "dispatches an identified changelog candidate and records reusable gate evidence" do
      prerun_workflow = File.read(File.join(repo_root, ".github/workflows/shakaperf-release-prerun.yml"))
      gate_workflow = File.read(File.join(repo_root, ".github/workflows/shakaperf-release-gates.yml"))

      expect(prerun_workflow).to include("branches:\n      - 'release/**'", "paths:\n      - CHANGELOG.md")
      expect(prerun_workflow).to include(
        "workflow run shakaperf-release-gates.yml",
        "target_version=",
        "candidate_sha="
      )
      expect(gate_workflow).to include("target_version:", "candidate_sha:", "cancel-in-progress: true")
      expect(gate_workflow).to include("name: shakaperf-release-evidence", "shakaperf-release-evidence.json")
      expect(gate_workflow).to include(
        "RUN_ATTEMPT: ${{ github.run_attempt }}",
        'run_attempt: Integer(ENV.fetch("RUN_ATTEMPT"), 10)'
      )
    end

    it "sets up a supported Ruby before either workflow loads the release helpers" do
      %w[shakaperf-release-gates.yml shakaperf-release-prerun.yml].each do |workflow_name|
        workflow = File.read(File.join(repo_root, ".github/workflows", workflow_name))
        version_reader = workflow.index("uses: ./.github/actions/read-tool-versions")
        ruby_setup = workflow.index("uses: ./.github/actions/setup-ruby")
        release_helper_load = workflow.index("ruby -rrake")

        expect(version_reader).to be < ruby_setup
        expect(ruby_setup).to be < release_helper_load
      end
    end

    it "bounds every gate job and leaves the release watcher enough time for the full workflow" do
      gate_workflow = File.read(File.join(repo_root, ".github/workflows/shakaperf-release-gates.yml"))
      job_timeouts = gate_workflow.scan(/^    timeout-minutes: (\d+)$/).flatten.map(&:to_i)

      expect(job_timeouts).to contain_exactly(10, 45, 5)
      expect(job_timeouts.sum).to eq(SHAKAPERF_RELEASE_GATE_WORKFLOW_TIMEOUT_MINUTES)
      expect(SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS / 60)
        .to be > SHAKAPERF_RELEASE_GATE_WORKFLOW_TIMEOUT_MINUTES
    end
  end

  describe "#shakaperf_release_gate_evidence_rejection" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:candidate_sha) { "a" * 40 }
    let(:head_sha) { "b" * 40 }
    let(:fingerprint) { "c" * 64 }
    let(:run_url) { "https://github.com/shakacode/react_on_rails/actions/runs/123456" }
    let(:run) do
      {
        "databaseId" => 123_456,
        "attempt" => 1,
        "headSha" => candidate_sha,
        "status" => "completed",
        "conclusion" => "success",
        "createdAt" => "2026-07-14T11:30:00Z",
        "startedAt" => "2026-07-14T11:30:05Z",
        "updatedAt" => "2026-07-14T12:00:30Z",
        "url" => run_url
      }
    end
    let(:evidence) do
      {
        "schema_version" => 2,
        "run_attempt" => 1,
        "run_id" => 123_456,
        "run_url" => run_url,
        "branch" => "release/17.0.0",
        "candidate_sha" => candidate_sha,
        "target_version" => "17.0.0.rc.8",
        "conclusion" => "success",
        "runtime_tree_fingerprint" => fingerprint,
        "completed_at" => "2026-07-14T12:00:00Z"
      }
    end
    let(:release_started_at) { Time.iso8601("2026-07-14T13:00:00Z") }
    let(:validation_time) { Time.iso8601("2026-07-14T13:05:00Z") }

    before do
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root:, sha: candidate_sha).and_return(fingerprint)
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root:, sha: head_sha).and_return(fingerprint)
      allow(self).to receive(:shakaperf_candidate_commit_shas)
        .with(monorepo_root:, candidate_sha:, head_sha:).and_return([head_sha])
      allow(self).to receive(:release_finalization_metadata_commit?)
        .with(monorepo_root:, sha: head_sha).and_return(true)
    end

    def evidence_rejection(run: self.run, evidence: self.evidence, target_version: "17.0.0.rc.8",
                           release_started_at: self.release_started_at,
                           allow_prerun_completion_after_release_start: false)
      shakaperf_release_gate_evidence_rejection(
        monorepo_root:,
        ref: "release/17.0.0",
        head_sha:,
        target_version:,
        run:,
        evidence:,
        release_started_at:,
        validation_time:,
        require_prerun: true,
        allow_prerun_completion_after_release_start:
      )
    end

    it "accepts a successful pre-run followed only by a version-metadata bump" do
      expect(evidence_rejection).to be_nil
    end

    it "rejects a runtime tree change after the tested candidate" do
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root:, sha: head_sha).and_return("d" * 64)

      expect(evidence_rejection).to eq("release runtime tree differs from the tested candidate")
    end

    it "rejects evidence for another target version" do
      expect(
        evidence_rejection(evidence: evidence.merge("target_version" => "17.0.0.rc.9"))
      ).to eq("evidence target version does not match the release")
    end

    it "rejects a run ID that only coerces to the workflow run ID" do
      coerced_id_evidence = evidence.merge("run_id" => "123456junk")

      expect(evidence_rejection(evidence: coerced_id_evidence))
        .to eq("evidence run ID does not match the workflow run")
    end

    it "rejects evidence from another workflow run attempt" do
      expect(evidence_rejection(evidence: evidence.merge("run_attempt" => 2)))
        .to eq("evidence run attempt does not match the workflow run")
    end

    %w[failure cancelled].each do |conclusion|
      it "rejects a #{conclusion} workflow run" do
        rejected_run = run.merge("conclusion" => conclusion)

        expect(evidence_rejection(run: rejected_run)).to eq("workflow run did not complete successfully")
      end
    end

    it "rejects stale evidence" do
      stale_evidence = evidence.merge("completed_at" => "2026-07-01T12:00:00Z")
      stale_run = run.merge("updatedAt" => "2026-07-01T12:00:30Z")

      expect(evidence_rejection(run: stale_run, evidence: stale_evidence)).to eq("evidence is stale")
    end

    it "rejects a gate that did not finish before the release run started" do
      late_evidence = evidence.merge("completed_at" => "2026-07-14T13:00:00Z")
      late_run = run.merge("updatedAt" => "2026-07-14T13:00:30Z")

      expect(evidence_rejection(run: late_run, evidence: late_evidence))
        .to eq("evidence was not complete before the release run started")
    end

    it "accepts a pre-run that started before release and completed while the release waited for it" do
      late_evidence = evidence.merge("completed_at" => "2026-07-14T13:01:00Z")
      late_run = run.merge("updatedAt" => "2026-07-14T13:01:30Z")

      expect(
        evidence_rejection(
          run: late_run,
          evidence: late_evidence,
          allow_prerun_completion_after_release_start: true
        )
      ).to be_nil
    end

    it "rejects a rerun attempt that started after the release even when the workflow was created earlier" do
      late_evidence = evidence.merge("run_attempt" => 2, "completed_at" => "2026-07-14T13:02:00Z")
      rerun = run.merge(
        "attempt" => 2,
        "startedAt" => "2026-07-14T13:01:00Z",
        "updatedAt" => "2026-07-14T13:02:30Z"
      )

      expect(
        evidence_rejection(
          run: rerun,
          evidence: late_evidence,
          allow_prerun_completion_after_release_start: true
        )
      ).to eq("pre-run did not start before the release run")
    end

    it "rejects an active pre-run whose start time cannot be proven to precede release" do
      late_evidence = evidence.merge("completed_at" => "2026-07-14T13:01:00Z")
      same_second_run = run.merge(
        "startedAt" => "2026-07-14T13:00:00Z",
        "updatedAt" => "2026-07-14T13:01:30Z"
      )

      expect(
        evidence_rejection(
          run: same_second_run,
          evidence: late_evidence,
          allow_prerun_completion_after_release_start: true
        )
      ).to eq("pre-run did not start before the release run")
    end

    it "rejects an active pre-run when refreshed start metadata is missing" do
      late_evidence = evidence.merge("completed_at" => "2026-07-14T13:01:00Z")
      missing_start_run = run.merge("startedAt" => nil, "updatedAt" => "2026-07-14T13:01:30Z")

      expect(
        evidence_rejection(
          run: missing_start_run,
          evidence: late_evidence,
          allow_prerun_completion_after_release_start: true
        )
      ).to eq("workflow start time is invalid")
    end

    it "rejects second-precision evidence from the same second as a fractional release start" do
      fractional_start = Time.iso8601("2026-07-14T12:00:30.900Z")

      expect(evidence_rejection(release_started_at: fractional_start))
        .to eq("evidence was not complete before the release run started")
    end

    it "rejects evidence from another release branch" do
      wrong_branch_evidence = evidence.merge("branch" => "release/17.0.1")

      expect(evidence_rejection(evidence: wrong_branch_evidence))
        .to eq("evidence branch does not match the release branch")
    end

    it "rejects unverifiable candidate ancestry instead of accepting unknown state" do
      allow(self).to receive(:shakaperf_candidate_commit_shas)
        .with(monorepo_root:, candidate_sha:, head_sha:).and_return(nil)

      expect(evidence_rejection).to eq("tested candidate ancestry or intervening commits cannot be verified")
    end
  end

  describe "#find_latest_shakaperf_prerun" do
    it "treats the newest branch candidate as authoritative even when it was cancelled" do
      old_success = {
        "databaseId" => 1,
        "attempt" => 1,
        "headSha" => "old",
        "status" => "completed",
        "conclusion" => "success",
        "createdAt" => "2026-07-14T11:00:00Z",
        "startedAt" => "2026-07-14T11:00:05Z",
        "updatedAt" => "2026-07-14T11:00:00Z"
      }
      newer_cancelled = {
        "databaseId" => 2,
        "attempt" => 1,
        "headSha" => "new",
        "status" => "completed",
        "conclusion" => "cancelled",
        "createdAt" => "2026-07-14T12:00:00Z",
        "startedAt" => "2026-07-14T12:00:05Z",
        "updatedAt" => "2026-07-14T12:00:00Z"
      }

      expect(find_latest_shakaperf_prerun([old_success, newer_cancelled], "release-head"))
        .to eq(newer_cancelled)
    end

    it "does not let a rerun of an older candidate supersede a newer candidate" do
      old_rerun = {
        "databaseId" => 1,
        "headSha" => "old",
        "status" => "completed",
        "conclusion" => "success",
        "attempt" => 2,
        "createdAt" => "2026-07-14T11:00:00Z",
        "startedAt" => "2026-07-14T12:59:00Z",
        "updatedAt" => "2026-07-14T13:00:00Z"
      }
      newer_cancelled = {
        "databaseId" => 2,
        "headSha" => "new",
        "status" => "completed",
        "conclusion" => "cancelled",
        "attempt" => 1,
        "createdAt" => "2026-07-14T12:00:00Z",
        "startedAt" => "2026-07-14T12:00:05Z",
        "updatedAt" => "2026-07-14T12:00:30Z"
      }

      expect(find_latest_shakaperf_prerun([old_rerun, newer_cancelled], "release-head"))
        .to eq(newer_cancelled)
    end

    it "refuses reuse when candidate ordering metadata is incomplete" do
      old_success = {
        "databaseId" => 1,
        "attempt" => 1,
        "headSha" => "old",
        "status" => "completed",
        "conclusion" => "success",
        "createdAt" => "2026-07-14T11:00:00Z",
        "startedAt" => "2026-07-14T11:00:05Z",
        "updatedAt" => "2026-07-14T11:30:00Z"
      }
      malformed_newer_cancelled = {
        "databaseId" => 2,
        "attempt" => 1,
        "headSha" => "new",
        "status" => "completed",
        "conclusion" => "cancelled",
        "createdAt" => nil,
        "startedAt" => "2026-07-14T12:00:05Z",
        "updatedAt" => "2026-07-14T12:30:00Z"
      }

      expect(find_latest_shakaperf_prerun([old_success, malformed_newer_cancelled], "release-head"))
        .to be_nil
    end
  end

  describe "#shakaperf_prerun_metadata_commit?" do
    let(:monorepo_root) { "/tmp/repo" }

    it "does not accept an arbitrary detector-classified non-runtime commit" do
      allow(self).to receive(:release_finalization_metadata_commit?)
        .with(monorepo_root:, sha: "docs").and_return(false)
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "docs").and_return(true)
      allow(self).to receive(:shakaperf_changelog_only_commit?)
        .with(monorepo_root:, sha: "docs").and_return(false)

      expect(shakaperf_prerun_metadata_commit?(monorepo_root:, sha: "docs")).to be false
    end
  end

  describe "#trustworthy_terminal_shakaperf_release_gate_run?" do
    let(:original_run) do
      {
        "databaseId" => 654_321,
        "attempt" => 1,
        "headSha" => "abc123",
        "status" => "in_progress",
        "conclusion" => nil
      }
    end
    let(:terminal_run) { original_run.merge("status" => "completed", "conclusion" => "failure") }

    it "accepts a known terminal result for the watched run" do
      expect(trustworthy_terminal_shakaperf_release_gate_run?(original_run:, refreshed_run: terminal_run)).to be true
    end

    it "rejects another run ID" do
      refreshed_run = terminal_run.merge("databaseId" => 654_322)

      expect(trustworthy_terminal_shakaperf_release_gate_run?(original_run:, refreshed_run:)).to be false
    end

    it "rejects another head SHA" do
      refreshed_run = terminal_run.merge("headSha" => "different-head")

      expect(trustworthy_terminal_shakaperf_release_gate_run?(original_run:, refreshed_run:)).to be false
    end

    it "rejects an invalid attempt" do
      refreshed_run = terminal_run.merge("attempt" => 0)

      expect(trustworthy_terminal_shakaperf_release_gate_run?(original_run:, refreshed_run:)).to be false
    end

    it "rejects an unknown terminal conclusion" do
      refreshed_run = terminal_run.merge("conclusion" => "future_conclusion")

      expect(trustworthy_terminal_shakaperf_release_gate_run?(original_run:, refreshed_run:)).to be false
    end
  end

  describe "#run_shakaperf_release_gate!" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:repo_slug) { "shakacode/react_on_rails" }
    let(:head_sha) { "abc1234def5678abcdef" }
    let(:target_version) { "17.0.0.rc.8" }
    let(:release_started_at) { Time.iso8601("2026-07-14T13:00:00Z") }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }
    let(:run) do
      {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha:, target_version:
        ),
        "headSha" => head_sha,
        "createdAt" => "2026-07-14T12:00:00Z",
        "startedAt" => "2026-07-14T12:00:05Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
    end

    before do
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return(repo_slug)
      allow(self).to receive_messages(
        fetch_shakaperf_release_gate_evidence: { "verified" => true },
        shakaperf_release_gate_evidence_rejection: nil
      )
      allow(self).to receive(:refresh_shakaperf_release_gate_run!) do |run:, **|
        run.merge(
          "status" => "completed",
          "conclusion" => "success",
          "updatedAt" => "2026-07-14T13:30:00Z"
        )
      end
    end

    it "dispatches the workflow on the release ref and watches the matching run" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([{ "databaseId" => 999_999, "headSha" => head_sha }])
      allow(self).to receive(:capture_gh_output)
        .with(
          "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
          "--repo", repo_slug,
          "--ref", "release-branch",
          "-f", "target_version=#{target_version}",
          "-f", "candidate_sha=#{head_sha}"
        )
        .and_return(["", success_status])
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!)
        .with(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          target_version:,
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

      expected_notice = Regexp.new(
        [
          "fresh dispatch can therefore block for up to about 75 minutes total",
          "RELEASE_CI_STATUS_OVERRIDE=true",
          "ShakaPerf release gate passed"
        ].join(".*"),
        Regexp::IGNORECASE | Regexp::MULTILINE
      )

      validated_run = nil
      expect do
        validated_run = run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(expected_notice).to_stdout
      expect(self).to have_received(:capture_gh_output)
        .with(
          "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
          "--repo", repo_slug,
          "--ref", "release-branch",
          "-f", "target_version=#{target_version}",
          "-f", "candidate_sha=#{head_sha}"
        )
      expect(self).to have_received(:wait_for_shakaperf_release_gate_run!)
        .with(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          ignored_run_ids: ["999999"],
          earliest_created_at: kind_of(Time)
        )
      expect(self).to have_received(:capture_gh_output_with_timeout)
        .with(
          "run", "watch", "123456", "--repo", repo_slug, "--exit-status",
          timeout_seconds: SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS
        )
      expect(validated_run).to include(
        "databaseId" => 123_456,
        "attempt" => 1,
        "headSha" => head_sha,
        "status" => "completed",
        "conclusion" => "success"
      )
      expect(validated_run).to eq(
        run.merge(
          "status" => "completed",
          "conclusion" => "success",
          "updatedAt" => "2026-07-14T13:30:00Z"
        )
      )
    end

    it "reuses an already successful gate run for the same head SHA without dispatching another run" do
      successful_run = run.merge(
        "status" => "completed",
        "conclusion" => "success"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([successful_run])
      expect(self).not_to receive(:capture_gh_output)
      expect(self).not_to receive(:capture_gh_output_with_timeout)

      validated_run = nil
      expect do
        validated_run = run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(%r{ShakaPerf release gate already passed.*actions/runs/123456}m).to_stdout
      expect(validated_run).to eq(successful_run)
      expect(validated_run).to include(
        "databaseId" => 123_456,
        "attempt" => 1,
        "headSha" => head_sha,
        "status" => "completed",
        "conclusion" => "success"
      )
    end

    it "selects an exact-head run for the requested target when another target has a newer run" do
      matching_run = run.merge(
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T12:00:30Z"
      )
      other_target_run = matching_run.merge(
        "databaseId" => 654_321,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha:, target_version: "17.0.0.rc.7"
        ),
        "updatedAt" => "2026-07-14T12:30:00Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/654321"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch").and_return([matching_run, other_target_run])
      allow(self).to receive(:shakaperf_release_gate_run_evidence_rejection)
        .with(hash_including(run: matching_run, target_version:)).and_return(nil)
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      expect(
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      ).to eq(matching_run)
      expect(self).to have_received(:shakaperf_release_gate_run_evidence_rejection)
        .with(hash_including(run: matching_run, target_version:))
    end

    it "dispatches a fresh exact-head gate when a successful run has no verifiable evidence" do
      successful_run = run.merge(
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T12:00:30Z"
      )
      fresh_run = run.merge("databaseId" => 654_321)
      refreshed_fresh_run = fresh_run.merge(
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T13:30:00Z"
      )
      release_started_at = Time.iso8601("2026-07-14T13:00:00Z")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([successful_run])
      allow(self).to receive(:fetch_shakaperf_release_gate_evidence)
        .with(repo_slug:, run: successful_run).and_return(nil)
      allow(self).to receive(:fetch_shakaperf_release_gate_evidence)
        .with(repo_slug:, run: refreshed_fresh_run).and_return({ "fresh" => true })
      expect(self).to receive(:dispatch_shakaperf_release_gate_workflow!).with(
        repo_slug:,
        ref: "release-branch",
        target_version: "17.0.0.rc.8",
        candidate_sha: head_sha
      )
      allow(self).to receive_messages(
        shakaperf_release_gate_evidence_rejection: nil,
        shakaperf_release_gate_dispatch_started_at: release_started_at,
        wait_for_shakaperf_release_gate_run!: fresh_run,
        capture_gh_output_with_timeout: ["", success_status, false]
      )
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: fresh_run).and_return(refreshed_fresh_run)

      validated_run = nil
      expect do
        validated_run = run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version: "17.0.0.rc.8",
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(/dispatching a fresh exact-head gate.*ShakaPerf release gate passed with verified evidence/m)
        .to_stdout
      expect(validated_run).to eq(refreshed_fresh_run)
      expect(validated_run).to include(
        "databaseId" => 654_321,
        "attempt" => 1,
        "headSha" => head_sha,
        "status" => "completed",
        "conclusion" => "success"
      )
    end

    it "fails closed when a freshly dispatched gate refresh changes run identity" do
      fresh_run = run.merge("databaseId" => 654_321)
      mismatched_run = fresh_run.merge(
        "databaseId" => 654_322,
        "headSha" => "different-head",
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T13:30:00Z"
      )
      allow(self).to receive(:dispatch_shakaperf_release_gate_workflow!)
      allow(self).to receive_messages(
        shakaperf_release_gate_dispatch_started_at: release_started_at,
        wait_for_shakaperf_release_gate_run!: fresh_run
      )
      allow(self).to receive(:watch_shakaperf_release_gate_run!).with(repo_slug:, run: fresh_run)
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: fresh_run).and_return(mismatched_run)
      expect(self).not_to receive(:verify_fresh_shakaperf_release_gate_evidence!)

      expect do
        dispatch_and_validate_shakaperf_release_gate!(
          repo_slug:,
          monorepo_root:,
          ref: "release-branch",
          existing_runs: [],
          head_sha:,
          target_version:,
          release_started_at:
        )
      end.to raise_error(SystemExit, /Unable to establish the terminal result of freshly dispatched.*654321/m)
    end

    it "reuses successful pre-run evidence for a runtime-equivalent metadata bump" do
      candidate_sha = "feedface" * 5
      successful_prerun = run.merge(
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha: candidate_sha, target_version: "17.0.0.rc.8"
        ),
        "headSha" => candidate_sha,
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T12:00:30Z"
      )
      evidence = { "candidate_sha" => candidate_sha }
      release_started_at = Time.iso8601("2026-07-14T13:00:00Z")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([successful_prerun])
      allow(self).to receive(:fetch_shakaperf_release_gate_evidence)
        .with(repo_slug:, run: successful_prerun).and_return(evidence)
      allow(self).to receive(:shakaperf_release_gate_evidence_rejection).and_return(nil)
      expect(self).not_to receive(:capture_gh_output_with_timeout)
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      validated_run = nil
      expect do
        validated_run = run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version: "17.0.0.rc.8",
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(%r{Reusing successful ShakaPerf pre-run.*actions/runs/123456}m).to_stdout
      expect(validated_run).to eq(successful_prerun)
      expect(validated_run).to include(
        "databaseId" => 123_456,
        "attempt" => 1,
        "headSha" => candidate_sha,
        "status" => "completed",
        "conclusion" => "success"
      )
    end

    it "selects a pre-run for the requested target when another target has a newer pre-run" do
      matching_sha = "feedface" * 5
      matching_prerun = run.merge(
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha: matching_sha, target_version:
        ),
        "headSha" => matching_sha,
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T12:00:30Z"
      )
      other_target_prerun = matching_prerun.merge(
        "databaseId" => 654_321,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha: "badc0ffe" * 5, target_version: "17.0.0.rc.7"
        ),
        "headSha" => "badc0ffe" * 5,
        "createdAt" => "2026-07-14T12:30:00Z",
        "startedAt" => "2026-07-14T12:30:05Z",
        "updatedAt" => "2026-07-14T12:30:30Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/654321"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch").and_return([matching_prerun, other_target_prerun])
      allow(self).to receive(:fetch_shakaperf_release_gate_evidence)
        .with(repo_slug:, run: matching_prerun).and_return({ "candidate_sha" => matching_sha })
      allow(self).to receive(:shakaperf_release_gate_evidence_rejection).and_return(nil)
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      expect(
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      ).to eq(matching_prerun)
      expect(self).to have_received(:fetch_shakaperf_release_gate_evidence).with(repo_slug:, run: matching_prerun)
    end

    it "waits for an in-progress pre-run before reusing its evidence" do
      candidate_sha = "feedface" * 5
      in_progress_prerun = run.merge(
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha: candidate_sha, target_version:
        ),
        "headSha" => candidate_sha,
        "status" => "in_progress",
        "conclusion" => nil,
        "updatedAt" => "2026-07-14T12:00:30Z"
      )
      completed_prerun = in_progress_prerun.merge(
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T13:30:00Z"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([in_progress_prerun])
      allow(self).to receive(:capture_gh_output_with_timeout)
        .with(
          "run", "watch", "123456", "--repo", repo_slug,
          timeout_seconds: SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS
        )
        .and_return(["", success_status, false])
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: in_progress_prerun).and_return(completed_prerun)
      expect(self).not_to receive(:fetch_shakaperf_release_gate_evidence)
        .with(repo_slug:, run: in_progress_prerun)
      allow(self).to receive(:fetch_shakaperf_release_gate_evidence)
        .with(repo_slug:, run: completed_prerun).and_return({ "candidate_sha" => candidate_sha })
      allow(self).to receive(:shakaperf_release_gate_evidence_rejection).with(
        monorepo_root:,
        ref: "release-branch",
        head_sha:,
        target_version:,
        run: completed_prerun,
        evidence: { "candidate_sha" => candidate_sha },
        release_started_at:,
        validation_time: kind_of(Time),
        require_prerun: true,
        allow_prerun_completion_after_release_start: true
      ).and_return(nil)
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      validated_run = nil
      expect do
        validated_run = run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(/watching it before deciding whether to dispatch.*Reusing successful ShakaPerf pre-run/m)
        .to_stdout
      expect(self).to have_received(:shakaperf_release_gate_evidence_rejection).with(
        monorepo_root:,
        ref: "release-branch",
        head_sha:,
        target_version:,
        run: completed_prerun,
        evidence: { "candidate_sha" => candidate_sha },
        release_started_at:,
        validation_time: kind_of(Time),
        require_prerun: true,
        allow_prerun_completion_after_release_start: true
      )
      expect(validated_run).to eq(completed_prerun)
      expect(validated_run).to include(
        "databaseId" => 123_456,
        "attempt" => 1,
        "headSha" => candidate_sha,
        "status" => "completed",
        "conclusion" => "success"
      )
    end

    it "dispatches an exact-head gate when the active pre-run attempt changes while waiting" do
      candidate_sha = "feedface" * 5
      in_progress_prerun = run.merge(
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha: candidate_sha, target_version:
        ),
        "headSha" => candidate_sha,
        "status" => "in_progress",
        "conclusion" => nil,
        "updatedAt" => "2026-07-14T12:00:30Z"
      )
      rerun_prerun = in_progress_prerun.merge(
        "attempt" => 2,
        "startedAt" => "2026-07-14T13:01:00Z",
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T13:30:00Z"
      )
      fresh_run = run.merge("databaseId" => 654_321)
      completed_fresh_run = fresh_run.merge(
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T14:30:00Z"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([in_progress_prerun])
      allow(self).to receive(:capture_gh_output_with_timeout)
        .and_return(["", success_status, false], ["", success_status, false])
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: in_progress_prerun).and_return(rerun_prerun)
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: fresh_run).and_return(completed_fresh_run)
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!).and_return(fresh_run)
      expect(self).to receive(:dispatch_shakaperf_release_gate_workflow!).with(
        repo_slug:,
        ref: "release-branch",
        target_version:,
        candidate_sha: head_sha
      )

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(/attempt changed.*dispatching an exact-head gate.*gate passed/m).to_stdout
    end

    it "dispatches an exact-head gate when the active pre-run start time changes while waiting" do
      candidate_sha = "feedface" * 5
      in_progress_prerun = run.merge(
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha: candidate_sha, target_version:
        ),
        "headSha" => candidate_sha,
        "startedAt" => "2026-07-14T13:01:00Z",
        "status" => "in_progress",
        "conclusion" => nil,
        "updatedAt" => "2026-07-14T13:01:30Z"
      )
      changed_prerun = in_progress_prerun.merge(
        "startedAt" => "2026-07-14T12:00:05Z",
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T13:30:00Z"
      )
      fresh_run = run.merge("databaseId" => 654_321)
      completed_fresh_run = fresh_run.merge(
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T14:30:00Z"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([in_progress_prerun])
      allow(self).to receive(:capture_gh_output_with_timeout)
        .and_return(["", success_status, false], ["", success_status, false])
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: in_progress_prerun).and_return(changed_prerun)
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: fresh_run).and_return(completed_fresh_run)
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!).and_return(fresh_run)
      expect(self).not_to receive(:fetch_shakaperf_release_gate_evidence).with(repo_slug:, run: changed_prerun)
      expect(self).to receive(:dispatch_shakaperf_release_gate_workflow!).with(
        repo_slug:,
        ref: "release-branch",
        target_version:,
        candidate_sha: head_sha
      )

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(/provenance changed.*dispatching an exact-head gate.*gate passed/m).to_stdout
    end

    it "dispatches an exact-head gate when an in-progress pre-run finishes unsuccessfully" do
      candidate_sha = "feedface" * 5
      in_progress_prerun = run.merge(
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha: candidate_sha, target_version:
        ),
        "headSha" => candidate_sha,
        "status" => "in_progress",
        "conclusion" => nil
      )
      failed_prerun = in_progress_prerun.merge(
        "status" => "completed",
        "conclusion" => "failure",
        "updatedAt" => "2026-07-14T13:30:00Z"
      )
      fresh_run = run.merge("databaseId" => 654_321)
      completed_fresh_run = fresh_run.merge(
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T14:30:00Z"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([in_progress_prerun])
      allow(self).to receive(:capture_gh_output_with_timeout)
        .and_return(["", success_status, false], ["", success_status, false])
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: in_progress_prerun).and_return(failed_prerun)
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: fresh_run).and_return(completed_fresh_run)
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!).and_return(fresh_run)
      expect(self).to receive(:dispatch_shakaperf_release_gate_workflow!).with(
        repo_slug:,
        ref: "release-branch",
        target_version:,
        candidate_sha: head_sha
      )

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(/pre-run.*conclusion failure.*dispatching an exact-head gate.*gate passed/m).to_stdout
    end

    it "reuses valid pre-run evidence after a non-reusable exact-head run" do
      candidate_sha = "feedface" * 5
      failed_exact_head_run = run.merge(
        "databaseId" => 654_321,
        "status" => "completed",
        "conclusion" => "failure",
        "updatedAt" => "2026-07-14T12:30:00Z"
      )
      successful_prerun = run.merge(
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha: candidate_sha, target_version:
        ),
        "headSha" => candidate_sha,
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T12:00:30Z"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([failed_exact_head_run, successful_prerun])
      allow(self).to receive(:fetch_shakaperf_release_gate_evidence)
        .with(repo_slug:, run: successful_prerun).and_return({ "candidate_sha" => candidate_sha })
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(/completed with conclusion failure.*Reusing successful ShakaPerf pre-run/m).to_stdout
    end

    it "watches an in-progress gate run for the same head SHA without dispatching another run" do
      in_progress_run = run.merge(
        "databaseId" => 321_654,
        "status" => "in_progress",
        "conclusion" => nil
      )
      completed_run = in_progress_run.merge(
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T13:30:00Z"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([in_progress_run])
      expect(self).not_to receive(:capture_gh_output)
      allow(self).to receive(:capture_gh_output_with_timeout)
        .with(
          "run", "watch", "321654", "--repo", repo_slug,
          timeout_seconds: SHAKAPERF_RELEASE_GATE_WATCH_TIMEOUT_SECONDS
        )
        .and_return(["", success_status, false])
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: in_progress_run).and_return(completed_run)

      validated_run = nil
      expect do
        validated_run = run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(/watching it instead.*ShakaPerf release gate passed/m).to_stdout
      expect(validated_run).to eq(completed_run)
      expect(validated_run).to include(
        "databaseId" => 321_654,
        "attempt" => 1,
        "headSha" => head_sha,
        "status" => "completed",
        "conclusion" => "success"
      )
    end

    it "considers reusable pre-run evidence when an in-progress exact-head run finishes unsuccessfully" do
      candidate_sha = "feedface" * 5
      in_progress_exact_head_run = run.merge(
        "databaseId" => 654_321,
        "status" => "in_progress",
        "conclusion" => nil
      )
      failed_exact_head_run = in_progress_exact_head_run.merge(
        "status" => "completed",
        "conclusion" => "failure",
        "updatedAt" => "2026-07-14T13:30:00Z"
      )
      successful_prerun = run.merge(
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha: candidate_sha, target_version:
        ),
        "headSha" => candidate_sha,
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T12:00:30Z"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([in_progress_exact_head_run, successful_prerun])
      allow(self).to receive(:capture_gh_output_with_timeout)
        .and_return(["", success_status, false])
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: in_progress_exact_head_run).and_return(failed_exact_head_run)
      allow(self).to receive(:fetch_shakaperf_release_gate_evidence)
        .with(repo_slug:, run: successful_prerun).and_return({ "candidate_sha" => candidate_sha })
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(/completed with conclusion failure.*Reusing successful ShakaPerf pre-run/m).to_stdout
    end

    it "fails closed when a watched existing run has no trustworthy terminal result" do
      in_progress_run = run.merge(
        "databaseId" => 654_321,
        "status" => "in_progress",
        "conclusion" => nil
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([in_progress_run])
      allow(self).to receive(:capture_gh_output_with_timeout)
        .and_return(["", success_status, false])
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run: in_progress_run).and_return(in_progress_run)
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, /Unable to establish the terminal result/m)
    end

    it "fails closed on a watcher API error even when refresh reports a terminal workflow failure" do
      in_progress_run = run.merge(
        "databaseId" => 654_321,
        "status" => "in_progress",
        "conclusion" => nil
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([in_progress_run])
      allow(self).to receive(:capture_gh_output_with_timeout)
        .and_return(["GitHub API unavailable", failure_status, false])
      expect(self).not_to receive(:refresh_shakaperf_release_gate_run!)
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, /Unable to watch existing ShakaPerf release gate.*GitHub API unavailable/m)
    end

    it "does not reuse a successful run when a rerun updated a same-SHA failure more recently" do
      failed_run = run.merge(
        "databaseId" => 222_222,
        "status" => "completed",
        "conclusion" => "failure",
        "attempt" => 2,
        "createdAt" => "2026-07-10T21:00:00Z",
        "updatedAt" => "2026-07-10T21:45:00Z"
      )
      earlier_updated_successful_run = run.merge(
        "databaseId" => 111_111,
        "status" => "completed",
        "conclusion" => "success",
        "attempt" => 1,
        "createdAt" => "2026-07-10T21:30:00Z",
        "updatedAt" => "2026-07-10T21:35:00Z"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([failed_run, earlier_updated_successful_run])
      allow(self).to receive(:capture_gh_output)
        .with(
          "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
          "--repo", repo_slug,
          "--ref", "release-branch",
          "-f", "target_version=#{target_version}",
          "-f", "candidate_sha=#{head_sha}"
        )
        .and_return(["", success_status])
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!)
        .with(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          ignored_run_ids: %w[222222 111111],
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
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to output(/dispatching a fresh gate run.*ShakaPerf release gate passed/m).to_stdout
      expect(self).to have_received(:capture_gh_output)
        .with(
          "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
          "--repo", repo_slug,
          "--ref", "release-branch",
          "-f", "target_version=#{target_version}",
          "-f", "candidate_sha=#{head_sha}"
        )
    end

    it "skips dispatching when the CI status override is enabled" do
      expect(self).not_to receive(:capture_gh_output)

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
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
          target_version:,
          release_started_at:,
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
          "--ref", "release-branch",
          "-f", "target_version=#{target_version}",
          "-f", "candidate_sha=#{head_sha}"
        )
        .and_return(["HTTP 404", failure_status])

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
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
          "--ref", "release-branch",
          "-f", "target_version=#{target_version}",
          "-f", "candidate_sha=#{head_sha}"
        )
        .and_return(["", success_status])
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!)
        .with(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          target_version:,
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
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, %r{ShakaPerf release gate failed.*actions/runs/123456.*Tests failed}m)
    end

    it "aborts after a successful fresh gate when its evidence is invalid" do
      refreshed_run = run.merge(
        "status" => "completed",
        "conclusion" => "success",
        "updatedAt" => "2026-07-14T13:30:00Z"
      )
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch").and_return([])
      allow(self).to receive(:dispatch_shakaperf_release_gate_workflow!)
      allow(self).to receive(:refresh_shakaperf_release_gate_run!)
        .with(repo_slug:, run:).and_return(refreshed_run)
      allow(self).to receive(:fetch_shakaperf_release_gate_evidence)
        .with(repo_slug:, run: refreshed_run).and_return({ "invalid" => true })
      allow(self).to receive_messages(
        wait_for_shakaperf_release_gate_run!: run,
        capture_gh_output_with_timeout: ["", success_status, false],
        shakaperf_release_gate_evidence_rejection: "evidence target version does not match the release"
      )

      expect do
        run_shakaperf_release_gate!(
          monorepo_root:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(
        SystemExit,
        /Fresh ShakaPerf release gate evidence is invalid: evidence target version does not match the release/
      )
    end

    it "aborts when watching the matching gate run times out" do
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([])
      allow(self).to receive(:capture_gh_output)
        .with(
          "workflow", "run", SHAKAPERF_RELEASE_GATE_WORKFLOW_FILE,
          "--repo", repo_slug,
          "--ref", "release-branch",
          "-f", "target_version=#{target_version}",
          "-f", "candidate_sha=#{head_sha}"
        )
        .and_return(["", success_status])
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!)
        .with(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          target_version:,
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
          target_version:,
          release_started_at:,
          allow_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, %r{Timed out watching ShakaPerf release gate run 123456.*actions/runs/123456}m)
    end

    it "finds the workflow_dispatch run for the pushed head SHA" do
      matching_run = {
        "databaseId" => 2,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha:, target_version:
        ),
        "headSha" => head_sha
      }
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([{ "databaseId" => 1, "headSha" => "old" }, matching_run])

      expect(
        wait_for_shakaperf_release_gate_run!(repo_slug:, ref: "release-branch", head_sha:, target_version:)
      ).to eq(matching_run)
    end

    it "ignores stale workflow_dispatch runs for the same head SHA" do
      run_identity = {
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha:, target_version:
        ),
        "headSha" => head_sha
      }
      stale_run = run_identity.merge("databaseId" => 1)
      matching_run = run_identity.merge("databaseId" => 2)
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([stale_run, matching_run])

      expect(
        wait_for_shakaperf_release_gate_run!(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          ignored_run_ids: [1]
        )
      ).to eq(matching_run)
    end

    it "ignores workflow_dispatch runs created before the new dispatch starts" do
      run_identity = {
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha:, target_version:
        ),
        "headSha" => head_sha
      }
      stale_run = run_identity.merge("databaseId" => 1, "createdAt" => "2026-06-05T01:00:00Z")
      matching_run = run_identity.merge("databaseId" => 2, "createdAt" => "2026-06-05T01:00:10Z")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([stale_run, matching_run])

      expect(
        wait_for_shakaperf_release_gate_run!(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          target_version:,
          earliest_created_at: Time.iso8601("2026-06-05T01:00:05Z")
        )
      ).to eq(matching_run)
    end

    it "uses GitHub's second-precision timestamps when matching newly dispatched runs" do
      allow(Time).to receive(:now).and_return(Time.iso8601("2026-06-05T01:00:05.900Z"))
      newly_dispatched_run = {
        "databaseId" => 1,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release-branch", head_sha:, target_version:
        ),
        "headSha" => head_sha,
        "createdAt" => "2026-06-05T01:00:05Z"
      }
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug:, ref: "release-branch")
        .and_return([newly_dispatched_run])

      expect(
        wait_for_shakaperf_release_gate_run!(
          repo_slug:,
          ref: "release-branch",
          head_sha:,
          target_version:,
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
          head_sha:,
          target_version:
        )
      end.to raise_error(SystemExit, /Timed out waiting for ShakaPerf release gate workflow to start/)
    end
  end

  describe "#run_accelerated_shakaperf_release_gate!" do
    it "rejects every active status when its conclusion is non-nil" do
      non_nil_conclusions = ["failure", ""]
      aggregate_failures do
        SHAKAPERF_RELEASE_GATE_ACTIVE_STATUSES.each do |status|
          non_nil_conclusions.each do |conclusion|
            expect do
              active_shakaperf_release_gate_run?("status" => status, "conclusion" => conclusion)
            end.to raise_error(SystemExit, /active ShakaPerf run.*terminal conclusion/i)
          end
        end
      end
    end

    it "dispatches an exact-head gate and returns its URL without watching it" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "d" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "d" * 40,
        "status" => "queued",
        "conclusion" => nil,
        "createdAt" => "2026-07-14T13:00:00Z",
        "startedAt" => nil,
        "updatedAt" => "2026-07-14T13:00:00Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: "shakacode/react_on_rails", ref: "release/17.0.0").and_return([])
      allow(self).to receive_messages(
        shakaperf_release_gate_dispatch_started_at: Time.iso8601("2026-07-14T13:00:00Z"),
        dispatch_shakaperf_release_gate_workflow!: nil
      )
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!).and_return(run)
      expect(self).not_to receive(:watch_shakaperf_release_gate_run!)

      result = run_accelerated_shakaperf_release_gate!(
        monorepo_root: "/tmp/repo",
        ref: "release/17.0.0",
        head_sha: "d" * 40,
        target_version: "17.0.0.rc.10",
        release_started_at: Time.iso8601("2026-07-14T12:59:00Z")
      )

      expect(result).to include(
        status: "pending",
        run_id: 123_456,
        run_url: "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      )
    end

    it "blocks a freshly dispatched active run that already has a terminal conclusion" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "d" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "d" * 40,
        "status" => "queued",
        "conclusion" => "failure",
        "createdAt" => "2026-07-14T13:00:00Z",
        "startedAt" => nil,
        "updatedAt" => "2026-07-14T13:00:00Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: "shakacode/react_on_rails", ref: "release/17.0.0").and_return([])
      allow(self).to receive_messages(
        shakaperf_release_gate_dispatch_started_at: Time.iso8601("2026-07-14T13:00:00Z"),
        dispatch_shakaperf_release_gate_workflow!: nil
      )
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!).and_return(run)

      expect do
        run_accelerated_shakaperf_release_gate!(
          monorepo_root: "/tmp/repo",
          ref: "release/17.0.0",
          head_sha: "d" * 40,
          target_version: "17.0.0.rc.10",
          release_started_at: Time.iso8601("2026-07-14T12:59:00Z")
        )
      end.to raise_error(SystemExit, /active ShakaPerf run.*terminal conclusion/i)
    end

    it "blocks a freshly dispatched run that is already known to have failed" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "d" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "d" * 40,
        "status" => "completed",
        "conclusion" => "failure",
        "createdAt" => "2026-07-14T13:00:00Z",
        "startedAt" => "2026-07-14T13:00:01Z",
        "updatedAt" => "2026-07-14T13:00:02Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: "shakacode/react_on_rails", ref: "release/17.0.0").and_return([])
      allow(self).to receive_messages(
        shakaperf_release_gate_dispatch_started_at: Time.iso8601("2026-07-14T13:00:00Z"),
        dispatch_shakaperf_release_gate_workflow!: nil
      )
      allow(self).to receive(:wait_for_shakaperf_release_gate_run!).and_return(run)

      expect do
        run_accelerated_shakaperf_release_gate!(
          monorepo_root: "/tmp/repo",
          ref: "release/17.0.0",
          head_sha: "d" * 40,
          target_version: "17.0.0.rc.10",
          release_started_at: Time.iso8601("2026-07-14T12:59:00Z")
        )
      end.to raise_error(SystemExit, /known ShakaPerf failure/)
    end

    it "reuses an active exact-head run without dispatching a duplicate" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "d" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "d" * 40,
        "status" => "in_progress",
        "conclusion" => nil,
        "createdAt" => "2026-07-14T13:00:00Z",
        "startedAt" => "2026-07-14T13:00:05Z",
        "updatedAt" => "2026-07-14T13:01:00Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: "shakacode/react_on_rails", ref: "release/17.0.0").and_return([run])
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      result = run_accelerated_shakaperf_release_gate!(
        monorepo_root: "/tmp/repo",
        ref: "release/17.0.0",
        head_sha: "d" * 40,
        target_version: "17.0.0.rc.10",
        release_started_at: Time.iso8601("2026-07-14T12:59:00Z")
      )

      expect(result).to include(status: "pending", run_id: 123_456)
    end

    it "blocks an existing active exact-head run that already has a terminal conclusion" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "d" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "d" * 40,
        "status" => "in_progress",
        "conclusion" => "failure",
        "createdAt" => "2026-07-14T13:00:00Z",
        "startedAt" => "2026-07-14T13:00:05Z",
        "updatedAt" => "2026-07-14T13:01:00Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: "shakacode/react_on_rails", ref: "release/17.0.0").and_return([run])
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      expect do
        run_accelerated_shakaperf_release_gate!(
          monorepo_root: "/tmp/repo",
          ref: "release/17.0.0",
          head_sha: "d" * 40,
          target_version: "17.0.0.rc.10",
          release_started_at: Time.iso8601("2026-07-14T12:59:00Z")
        )
      end.to raise_error(SystemExit, /active ShakaPerf run.*terminal conclusion/i)
    end

    it "ignores a same-SHA run dispatched for another target version" do
      wrong_target = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "d" * 40, target_version: "17.0.0.rc.9"
        ),
        "headSha" => "d" * 40,
        "status" => "in_progress"
      }

      expect(
        find_latest_shakaperf_release_gate_run(
          [wrong_target],
          "d" * 40,
          ref: "release/17.0.0",
          target_version: "17.0.0.rc.10"
        )
      ).to be_nil
    end

    it "fails closed when an active exact-head run has no trustworthy GitHub identity" do
      run = {
        "databaseId" => nil,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "d" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "d" * 40,
        "status" => "in_progress",
        "conclusion" => nil,
        "createdAt" => "2026-07-14T13:00:00Z",
        "startedAt" => "2026-07-14T13:00:05Z",
        "updatedAt" => "2026-07-14T13:01:00Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/unknown"
      }
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: "shakacode/react_on_rails", ref: "release/17.0.0").and_return([run])
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      expect do
        run_accelerated_shakaperf_release_gate!(
          monorepo_root: "/tmp/repo",
          ref: "release/17.0.0",
          head_sha: "d" * 40,
          target_version: "17.0.0.rc.10",
          release_started_at: Time.iso8601("2026-07-14T12:59:00Z")
        )
      end.to raise_error(SystemExit, /identity is unknown/)
    end

    it "reuses a completed exact-head run only after verifying its evidence" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "d" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "d" * 40,
        "status" => "completed",
        "conclusion" => "success",
        "createdAt" => "2026-07-14T13:00:00Z",
        "startedAt" => "2026-07-14T13:00:05Z",
        "updatedAt" => "2026-07-14T13:30:00Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: "shakacode/react_on_rails", ref: "release/17.0.0").and_return([run])
      allow(self).to receive(:shakaperf_release_gate_run_evidence_rejection).and_return(nil)
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      result = run_accelerated_shakaperf_release_gate!(
        monorepo_root: "/tmp/repo",
        ref: "release/17.0.0",
        head_sha: "d" * 40,
        target_version: "17.0.0.rc.10",
        release_started_at: Time.iso8601("2026-07-14T12:59:00Z")
      )

      expect(result).to include(status: "success", run_id: 123_456)
    end

    it "fails closed on a completed exact-head ShakaPerf failure" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "d" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "d" * 40,
        "status" => "completed",
        "conclusion" => "failure",
        "createdAt" => "2026-07-14T13:00:00Z",
        "startedAt" => "2026-07-14T13:00:05Z",
        "updatedAt" => "2026-07-14T13:30:00Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: "shakacode/react_on_rails", ref: "release/17.0.0").and_return([run])
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      expect do
        run_accelerated_shakaperf_release_gate!(
          monorepo_root: "/tmp/repo",
          ref: "release/17.0.0",
          head_sha: "d" * 40,
          target_version: "17.0.0.rc.10",
          release_started_at: Time.iso8601("2026-07-14T12:59:00Z")
        )
      end.to raise_error(SystemExit, %r{known ShakaPerf failure.*actions/runs/123456}mi)
    end

    it "keeps an unknown completed exact-head conclusion distinct from a known failure" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "d" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "d" * 40,
        "status" => "completed",
        "conclusion" => "future_conclusion",
        "createdAt" => "2026-07-14T13:00:00Z",
        "startedAt" => "2026-07-14T13:00:05Z",
        "updatedAt" => "2026-07-14T13:30:00Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: "shakacode/react_on_rails", ref: "release/17.0.0").and_return([run])
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      expect do
        run_accelerated_shakaperf_release_gate!(
          monorepo_root: "/tmp/repo",
          ref: "release/17.0.0",
          head_sha: "d" * 40,
          target_version: "17.0.0.rc.10",
          release_started_at: Time.iso8601("2026-07-14T12:59:00Z")
        )
      end.to raise_error(SystemExit, /ShakaPerf.*unknown.*refusing unaudited publication/i)
    end

    it "reuses a completed pre-run only when runtime-equivalent evidence verifies" do
      run = {
        "databaseId" => 222_222,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "e" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "e" * 40,
        "status" => "completed",
        "conclusion" => "success",
        "createdAt" => "2026-07-14T12:00:00Z",
        "startedAt" => "2026-07-14T12:00:05Z",
        "updatedAt" => "2026-07-14T12:30:00Z",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/222222"
      }
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:fetch_shakaperf_release_gate_runs)
        .with(repo_slug: "shakacode/react_on_rails", ref: "release/17.0.0").and_return([run])
      allow(self).to receive(:shakaperf_release_gate_run_evidence_rejection).and_return(nil)
      expect(self).not_to receive(:dispatch_shakaperf_release_gate_workflow!)

      result = run_accelerated_shakaperf_release_gate!(
        monorepo_root: "/tmp/repo",
        ref: "release/17.0.0",
        head_sha: "d" * 40,
        target_version: "17.0.0.rc.10",
        release_started_at: Time.iso8601("2026-07-14T12:59:00Z")
      )

      expect(result).to include(status: "success", run_id: 222_222)
    end
  end

  describe "#fetch_rubygems_versions" do
    it "queries RubyGems with bounded timeouts" do
      response = instance_double(Net::HTTPSuccess, body: '[{"number":"17.0.0"}]')
      http = instance_double(Net::HTTP)

      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:get).and_return(response)

      expect(fetch_rubygems_versions("react_on_rails", api_url: "https://rubygems.example/versions"))
        .to eq([response.body, response])
      expect(Net::HTTP).to have_received(:start).with(
        "rubygems.example",
        443,
        use_ssl: true,
        open_timeout: RUBYGEMS_VERSIONS_OPEN_TIMEOUT_SECONDS,
        read_timeout: RUBYGEMS_VERSIONS_READ_TIMEOUT_SECONDS
      )
      expect(http).to have_received(:get).with("/versions/react_on_rails.json")
    end
  end

  describe "#preflight_registry_publish_conflicts!" do
    before do
      stub_const("NPM_RELEASE_PACKAGE_NAMES", %w[react-on-rails react-on-rails-pro])
      stub_const("RUBYGEMS_RELEASE_GEM_NAMES", %w[react_on_rails react_on_rails_pro])
    end

    it "skips registry probes during an idempotent retry" do
      expect(self).not_to receive(:release_registry_publish_conflicts)

      preflight_registry_publish_conflicts!(
        gem_version: "17.0.0",
        npm_version: "17.0.0",
        idempotent_retry: true
      )
    end

    it "allows a first publish when no target artifacts exist" do
      allow(self).to receive_messages(npm_package_already_published?: false, rubygem_version_published?: false)

      expect do
        preflight_registry_publish_conflicts!(
          gem_version: "17.0.0",
          npm_version: "17.0.0",
          idempotent_retry: false
        )
      end.not_to raise_error
      expect(self).to have_received(:npm_package_already_published?).with("react-on-rails", "17.0.0")
      expect(self).to have_received(:npm_package_already_published?).with("react-on-rails-pro", "17.0.0")
      expect(self).to have_received(:rubygem_version_published?).with("react_on_rails", "17.0.0")
      expect(self).to have_received(:rubygem_version_published?).with("react_on_rails_pro", "17.0.0")
    end

    it "aborts before tagging when target artifacts already exist outside an idempotent retry" do
      allow(self).to receive(:npm_package_already_published?) do |package_name, version|
        expect(version).to eq("17.0.0")
        package_name == "react-on-rails-pro"
      end
      allow(self).to receive(:rubygem_version_published?) do |gem_name, version|
        expect(version).to eq("17.0.0")
        gem_name == "react_on_rails"
      end

      expect do
        preflight_registry_publish_conflicts!(
          gem_version: "17.0.0",
          npm_version: "17.0.0",
          idempotent_retry: false
        )
      end.to raise_error(
        SystemExit,
        /react-on-rails-pro@17\.0\.0.*react_on_rails 17\.0\.0/m
      )
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

    it "aborts when the exact gem version is already visible outside an idempotent retry" do
      allow(self).to receive(:rubygem_version_published?)
        .with("react_on_rails", "17.0.0")
        .and_return(true)
      expect(self).not_to receive(:sh_args_in_dir_for_release)

      expect do
        publish_gem_with_retry(
          "/tmp/gem",
          "react_on_rails",
          otp: "123456",
          published_version: "17.0.0",
          max_retries: 1
        )
      end.to raise_error(SystemExit, /already visible on RubyGems\.org/)
    end

    it "skips RubyGems publish when the exact gem version is visible during an idempotent retry" do
      allow(self).to receive(:rubygem_version_published?)
        .with("react_on_rails", "17.0.0")
        .and_return(true)
      expect(self).not_to receive(:sh_args_in_dir_for_release)

      expect do
        publish_gem_with_retry(
          "/tmp/gem",
          "react_on_rails",
          otp: "123456",
          published_version: "17.0.0",
          idempotent_retry: true,
          max_retries: 1
        )
      end.to output(/already visible on RubyGems\.org/).to_stdout
    end
  end

  describe "#publish_npm_with_retry" do
    it "passes OTP as a dedicated CLI argument" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "package.json"), JSON.pretty_generate({ "name" => "react-on-rails",
                                                                          "version" => "16.4.0-rc.1" }))
        allow(self).to receive(:npm_package_already_published?)
          .with("react-on-rails", "16.4.0-rc.1")
          .and_return(false)

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
        allow(self).to receive(:npm_package_already_published?)
          .with("react-on-rails", "16.7.0-rc.1")
          .and_return(false)
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
        allow(self).to receive(:npm_package_already_published?)
          .with("react-on-rails-pro", "16.7.0-rc.1")
          .and_return(false)

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

    it "aborts when the exact package version is already visible outside an idempotent retry" do
      allow(self).to receive(:npm_package_already_published?)
        .with("react-on-rails", "17.0.0")
        .and_return(true)
      expect(self).not_to receive(:sh_args_in_dir_for_release)

      expect do
        publish_npm_with_retry("/tmp/npm", "react-on-rails@17.0.0", max_retries: 1)
      end.to raise_error(SystemExit, /already visible on npm/)
    end

    it "skips npm publish when the exact package version is visible during an idempotent retry" do
      allow(self).to receive(:npm_package_already_published?)
        .with("react-on-rails", "17.0.0")
        .and_return(true)
      expect(self).not_to receive(:sh_args_in_dir_for_release)

      expect do
        publish_npm_with_retry("/tmp/npm", "react-on-rails@17.0.0", idempotent_retry: true, max_retries: 1)
      end.to output(/already visible on npm/).to_stdout
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

    it "allows an existing target tag for an idempotent release branch retry" do
      allow(self).to receive(:tagged_release_gem_versions)
        .with("/tmp/repo", fetch_tags: false)
        .and_return(["16.4.0"])

      expect do
        validate_release_version_policy!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "16.4.0",
          allow_override: false,
          fetch_tags: false,
          allow_existing_target_tag: true
        )
      end.to output(/Existing target tag 16\.4\.0/).to_stdout
    end

    it "keeps ordinary stable releases above the globally latest tag" do
      allow(self).to receive(:tagged_release_gem_versions)
        .with("/tmp/repo", fetch_tags: false)
        .and_return(["16.9.9", "17.1.0.beta.1"])

      expect do
        validate_release_version_policy!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "17.0.0",
          allow_override: false,
          fetch_tags: false
        )
      end.to raise_error(SystemExit, /latest tagged version 17.1.0.beta.1/)
    end

    it "allows release branch final promotion when another release line has newer prerelease tags" do
      allow(self).to receive(:tagged_release_gem_versions)
        .with("/tmp/repo", fetch_tags: false)
        .and_return(["16.9.9", "17.0.0.rc.3", "17.1.0.beta.1"])
      allow(self).to receive(:extract_changelog_section)
        .with(changelog_path: "/tmp/repo/CHANGELOG.md", version: "17.0.0")
        .and_return("#### Breaking Changes\n- Major release\n")

      expect do
        validate_release_version_policy!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "17.0.0",
          allow_override: false,
          fetch_tags: false,
          release_branch_final_promotion: true
        )
      end.not_to raise_error
    end

    it "allows release branch RC cuts when main already has a newer prerelease tag on another line" do
      allow(self).to receive(:tagged_release_gem_versions)
        .with("/tmp/repo", fetch_tags: false)
        .and_return(["16.9.9", "17.0.0.rc.3", "17.1.0.beta.1"])

      expect do
        validate_release_version_policy!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "17.0.0.rc.4",
          allow_override: false,
          fetch_tags: false,
          release_branch_tag_scope: true
        )
      end.to output(/Skipping all downstream checks for same-base prerelease bump/).to_stdout
    end

    it "rejects release branch final promotion when a newer stable tag already exists" do
      allow(self).to receive(:tagged_release_gem_versions)
        .with("/tmp/repo", fetch_tags: false)
        .and_return(["16.9.9", "17.0.0.rc.3", "17.1.0"])

      expect do
        validate_release_version_policy!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "17.0.0",
          allow_override: false,
          fetch_tags: false,
          release_branch_final_promotion: true
        )
      end.to raise_error(SystemExit, /latest tagged version 17.1.0/)
    end

    it "rejects release branch final promotion when the final tag already exists" do
      allow(self).to receive(:tagged_release_gem_versions)
        .with("/tmp/repo", fetch_tags: false)
        .and_return(["16.9.9", "17.0.0.rc.3", "17.0.0", "17.1.0.beta.1"])

      expect do
        validate_release_version_policy!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "17.0.0",
          allow_override: false,
          fetch_tags: false,
          release_branch_final_promotion: true
        )
      end.to raise_error(SystemExit, /latest tagged version 17.0.0/)
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

  describe "#remote_git_tag_exists?" do
    it "aborts when git ls-remote fails with an unexpected exit code" do
      error_status = instance_double(Process::Status, success?: false, exitstatus: 128)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "ls-remote", "--exit-code", "--tags", "origin", "refs/tags/v17.0.0")
        .and_return(["fatal: unable to connect to origin", error_status])

      expect do
        remote_git_tag_exists?(monorepo_root: "/tmp/repo", tag: "v17.0.0")
      end.to raise_error(SystemExit, /Unable to verify remote git tag/)
    end
  end

  describe "#preflight_explicit_accelerated_rc_target_tag!" do
    let(:tag) { "v17.0.0.rc.10" }

    it "allows a canonical annotated retry only from the exact tagged candidate" do
      provenance = {
        "target_version" => "17.0.0.rc.10",
        "candidate_sha" => "f" * 40
      }
      allow(self).to receive_messages(
        local_release_tag_exists?: true,
        remote_git_tag_exists?: true,
        fetch_remote_release_tag!: nil,
        accelerated_rc_tag_provenance_for_tag!: provenance,
        peeled_git_tag_sha: "f" * 40,
        current_git_sha!: "f" * 40
      )

      expect(
        preflight_explicit_accelerated_rc_target_tag!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "17.0.0.rc.10",
          current_checkout_version: "17.0.0.rc.10"
        )
      ).to eq(provenance)
      expect(self).to have_received(:fetch_remote_release_tag!).with(
        monorepo_root: "/tmp/repo", tag:, tag_type: "accelerated RC"
      )
    end

    it "fails closed when exact-target remote discovery is unknown" do
      allow(self).to receive(:local_release_tag_exists?).and_return(false)
      allow(self).to receive(:remote_git_tag_exists?)
        .and_raise(SystemExit, "Unable to verify remote git tag")
      expect(self).not_to receive(:accelerated_rc_tag_provenance_for_tag!)

      expect do
        preflight_explicit_accelerated_rc_target_tag!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "17.0.0.rc.10",
          current_checkout_version: "16.9.0"
        )
      end.to raise_error(SystemExit, /Unable to verify remote git tag/)
    end

    it "fails closed when a discovered exact-target tag cannot be classified" do
      allow(self).to receive_messages(
        local_release_tag_exists?: false,
        remote_git_tag_exists?: true,
        fetch_remote_release_tag!: nil
      )
      allow(self).to receive(:accelerated_rc_tag_provenance_for_tag!)
        .and_raise(SystemExit, "RC tag has an unexpected git object type")

      expect do
        preflight_explicit_accelerated_rc_target_tag!(
          monorepo_root: "/tmp/repo",
          target_gem_version: "17.0.0.rc.10",
          current_checkout_version: "16.9.0"
        )
      end.to raise_error(SystemExit, /unexpected git object type/)
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

  describe "#ci_status_override_allowed_for_release!" do
    it "rejects a positional CI override for a stable release before CI validation" do
      expect do
        ci_status_override_allowed_for_release!(override_flag: true, is_prerelease: false)
      end.to raise_error(SystemExit, /CI status override is allowed only for prerelease releases/)
    end

    it "rejects RELEASE_CI_STATUS_OVERRIDE for a stable release" do
      allow(ENV).to receive(:fetch).with("RELEASE_CI_STATUS_OVERRIDE", nil).and_return("true")

      expect do
        ci_status_override_allowed_for_release!(override_flag: nil, is_prerelease: false)
      end.to raise_error(SystemExit, /CI status override is allowed only for prerelease releases/)
    end

    it "preserves the prerelease waiver" do
      expect(ci_status_override_allowed_for_release!(override_flag: true, is_prerelease: true)).to be(true)
    end
  end

  describe "#resolve_accelerated_rc_options!" do
    it "rejects an argument-less accelerated RC release" do
      expect do
        resolve_accelerated_rc_options!(
          requested: true,
          explicit_version_input: "",
          target_gem_version: "17.0.0.rc.10",
          tracker: "3823",
          reason: "Start published-artifact QA while exact-head checks finish",
          allow_ci_override: false
        )
      end.to raise_error(SystemExit, /explicit RC version/)
    end

    it "rejects accelerated publication for a stable target" do
      expect do
        resolve_accelerated_rc_options!(
          requested: true,
          explicit_version_input: "17.0.0",
          target_gem_version: "17.0.0",
          tracker: "3823",
          reason: "Start published-artifact QA while exact-head checks finish",
          allow_ci_override: false
        )
      end.to raise_error(SystemExit, /RC targets only/)
    end

    it "requires a numeric release tracker" do
      expect do
        resolve_accelerated_rc_options!(
          requested: true,
          explicit_version_input: "17.0.0.rc.10",
          target_gem_version: "17.0.0.rc.10",
          tracker: "",
          reason: "Start published-artifact QA while exact-head checks finish",
          allow_ci_override: false
        )
      end.to raise_error(SystemExit, /release tracker issue number/)
    end

    it "requires a single-line maintainer reason" do
      expect do
        resolve_accelerated_rc_options!(
          requested: true,
          explicit_version_input: "17.0.0.rc.10",
          target_gem_version: "17.0.0.rc.10",
          tracker: "3823",
          reason: "",
          allow_ci_override: false
        )
      end.to raise_error(SystemExit, /maintainer reason/)
    end

    it "rejects comment-breaking content in the maintainer reason" do
      expect do
        resolve_accelerated_rc_options!(
          requested: true,
          explicit_version_input: "17.0.0.rc.10",
          target_gem_version: "17.0.0.rc.10",
          tracker: "3823",
          reason: "approved --> forged record",
          allow_ci_override: false
        )
      end.to raise_error(SystemExit, /single-line plain text/)
    end

    it "rejects the broad CI override in accelerated mode" do
      expect do
        resolve_accelerated_rc_options!(
          requested: true,
          explicit_version_input: "17.0.0.rc.10",
          target_gem_version: "17.0.0.rc.10",
          tracker: "3823",
          reason: "Start published-artifact QA while exact-head checks finish",
          allow_ci_override: true
        )
      end.to raise_error(SystemExit, /cannot be combined.*CI status override/i)
    end

    it "rejects a derived RC target instead of accepting a non-RC version input" do
      expect do
        resolve_accelerated_rc_options!(
          requested: true,
          explicit_version_input: "patch",
          target_gem_version: "17.0.0.rc.10",
          tracker: "3823",
          reason: "Start published-artifact QA while exact-head checks finish",
          allow_ci_override: false
        )
      end.to raise_error(SystemExit, /explicit version must exactly match/)
    end

    it "rejects case-varied accelerated identities before persistence or tag provenance" do
      uppercase_options = {
        target_gem_version: "17.0.0.RC.10",
        tracker: 3823,
        reason: "Start published-artifact QA while exact-head checks finish"
      }
      uppercase_record = build_accelerated_rc_publication_record(
        options: uppercase_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: {
          status: "pending",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: [{
            name: "generator",
            state: "in_progress",
            url: "https://github.com/shakacode/react_on_rails/actions/runs/123"
          }]
        },
        shakaperf: {
          status: "pending",
          run_id: 123_456,
          attempt: 1,
          run_url: "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          candidate_sha: "f" * 40,
          target_version: "17.0.0.RC.10",
          release_started_at: "2026-07-14T13:00:00Z"
        },
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      uppercase_provenance = {
        "schema_version" => 1,
        "target_version" => "17.0.0.RC.10",
        "candidate_sha" => "f" * 40,
        "release_tracker" => 3823,
        "authorization_digest" => "b" * 64
      }

      aggregate_failures do
        expect do
          resolve_accelerated_rc_options!(
            requested: true,
            explicit_version_input: "17.0.0.RC.10",
            target_gem_version: "17.0.0.RC.10",
            tracker: "3823",
            reason: uppercase_options.fetch(:reason),
            allow_ci_override: false
          )
        end.to raise_error(SystemExit, /canonical lowercase.*\.rc\./i)
        expect do
          validate_accelerated_rc_tracker_record!(uppercase_record)
        end.to raise_error(SystemExit, /malformed accelerated RC record/)
        expect(valid_accelerated_rc_tag_provenance?(uppercase_provenance)).to be(false)
      end
    end

    it "rejects accelerated RC numeric identifiers with leading zeroes" do
      invalid_versions = %w[
        17.0.0.rc.01
        017.0.0.rc.1
        17.00.0.rc.1
        17.0.00.rc.1
      ]

      aggregate_failures do
        invalid_versions.each do |version|
          expect do
            resolve_accelerated_rc_options!(
              requested: true,
              explicit_version_input: version,
              target_gem_version: version,
              tracker: "3823",
              reason: "Start published-artifact QA while exact-head checks finish",
              allow_ci_override: false
            )
          end.to raise_error(SystemExit, /canonical npm semver.*leading zero/i), version
        end
      end
    end

    it "accepts canonical accelerated RC versions with zero and positive numeric components" do
      valid_versions = %w[0.0.0.rc.0 17.0.0.rc.10]

      aggregate_failures do
        valid_versions.each do |version|
          options = resolve_accelerated_rc_options!(
            requested: true,
            explicit_version_input: version,
            target_gem_version: version,
            tracker: "3823",
            reason: "Start published-artifact QA while exact-head checks finish",
            allow_ci_override: false
          )
          expect(options.fetch(:target_gem_version)).to eq(version)
        end
      end
    end

    it "carries a canonical lowercase accelerated identity through final-promotion validation" do
      options = resolve_accelerated_rc_options!(
        requested: true,
        explicit_version_input: "17.0.0.rc.10",
        target_gem_version: "17.0.0.rc.10",
        tracker: "3823",
        reason: "Start published-artifact QA while exact-head checks finish",
        allow_ci_override: false
      )
      authorization = build_accelerated_rc_publication_record(
        options:,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: {
          status: "pending",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: [{
            name: "generator",
            state: "in_progress",
            url: "https://github.com/shakacode/react_on_rails/actions/runs/123"
          }]
        },
        shakaperf: {
          status: "pending",
          run_id: 123_456,
          attempt: 1,
          run_url: "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          candidate_sha: "f" * 40,
          target_version: "17.0.0.rc.10",
          release_started_at: "2026-07-14T13:00:00Z"
        },
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      publication = accelerated_rc_published_record(
        authorized_record: authorization,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      accepted = reconcile_accelerated_rc_record(
        published_record: publication,
        ci_snapshot: authorization.fetch("ci").merge("status" => "success", "non_success" => []),
        shakaperf: authorization.fetch("shakaperf").merge("status" => "success"),
        evidence: {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        },
        approved_by: "justin808",
        reason: "All required evidence passed",
        recorded_at: "2026-07-14T15:00:00Z"
      )
      provenance = accelerated_rc_tag_provenance(authorization)
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint).and_return("a" * 64)

      expect(
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization, publication, accepted],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance: provenance
        )
      ).to eq(accepted)
    end
  end

  describe "#resolve_accelerated_rc_options_for_release!" do
    let(:authorization) do
      build_accelerated_rc_publication_record(
        options: {
          target_gem_version: "17.0.0.rc.10",
          tracker: 3823,
          reason: "Start published-artifact QA while remaining checks finish"
        },
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: {
          status: "pending",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: [
            {
              name: "generator",
              state: "in_progress",
              url: "https://github.com/shakacode/react_on_rails/actions/runs/123"
            }
          ]
        },
        shakaperf: {
          status: "pending",
          run_id: 123_456,
          attempt: 1,
          run_url: "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          candidate_sha: "f" * 40,
          target_version: "17.0.0.rc.10",
          release_started_at: "2026-07-14T13:00:00Z"
        },
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
    end

    def resolve_unflagged_accelerated_retry(allow_ci_override: false)
      resolve_accelerated_rc_options_for_release!(
        requested: false,
        explicit_version_input: "17.0.0.rc.10",
        target_gem_version: "17.0.0.rc.10",
        tracker: nil,
        reason: nil,
        allow_ci_override:,
        repo_slug: "shakacode/react_on_rails",
        monorepo_root: "/tmp/repo",
        current_checkout_version: "17.0.0.rc.10",
        candidate_sha: "f" * 40
      )
    end

    def resolve_flagged_accelerated_retry(tracker: 3823, reason: nil)
      resolve_accelerated_rc_options_for_release!(
        requested: true,
        explicit_version_input: "17.0.0.rc.10",
        target_gem_version: "17.0.0.rc.10",
        tracker: tracker.to_s,
        reason: reason || authorization.fetch("reason"),
        allow_ci_override: false,
        repo_slug: "shakacode/react_on_rails",
        monorepo_root: "/tmp/repo",
        current_checkout_version: "17.0.0.rc.10",
        candidate_sha: "f" * 40
      )
    end

    it "resumes persisted pre-tag authorization when accelerated variables are omitted" do
      allow(self).to receive_messages(
        local_release_tag_exists?: false,
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        fetch_release_tracker_issue!: {}
      )

      expect(resolve_unflagged_accelerated_retry).to include(
        target_gem_version: "17.0.0.rc.10",
        tracker: 3823,
        reason: authorization.fetch("reason")
      )
    end

    it "resumes an annotated accelerated-tag retry when accelerated variables are omitted" do
      allow(self).to receive_messages(
        local_release_tag_exists?: true,
        accelerated_rc_tag_provenance_for_tag!: accelerated_rc_tag_provenance(authorization),
        fetch_release_tracker_issue!: {},
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization]
      )

      expect(resolve_unflagged_accelerated_retry).to include(
        target_gem_version: "17.0.0.rc.10",
        tracker: 3823,
        reason: authorization.fetch("reason")
      )
    end

    it "preserves an ordinary RC retry when no accelerated history exists" do
      allow(self).to receive_messages(
        local_release_tag_exists?: true,
        accelerated_rc_tag_provenance_for_tag!: nil,
        fetch_repository_accelerated_rc_records_for_candidate!: []
      )

      expect(resolve_unflagged_accelerated_retry).to be_nil
    end

    it "blocks a flagged retry over an existing ordinary lightweight tag before authorization append" do
      allow(self).to receive_messages(
        local_release_tag_exists?: true,
        accelerated_rc_tag_provenance_for_tag!: nil,
        fetch_repository_accelerated_rc_records_for_candidate!: [],
        append_accelerated_rc_tracker_record!: nil
      )

      failure = begin
        options = resolve_flagged_accelerated_retry
        append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails",
          tracker: options.fetch(:tracker),
          record: authorization
        )
        nil
      rescue SystemExit => error
        error
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/ordinary lightweight RC tag.*accelerated/i)
        expect(self).not_to have_received(:append_accelerated_rc_tracker_record!)
      end
    end

    it "rejects the broad prerelease override when durable accelerated history is discovered" do
      allow(self).to receive_messages(
        local_release_tag_exists?: false,
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        fetch_release_tracker_issue!: {}
      )

      expect do
        resolve_unflagged_accelerated_retry(allow_ci_override: true)
      end.to raise_error(SystemExit, /accelerated RC retry.*broad CI status override/i)
    end

    it "blocks a flagged same-candidate retry that switches the durable tracker or reason" do
      allow(self).to receive_messages(
        local_release_tag_exists?: false,
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        fetch_release_tracker_issue!: {}
      )

      aggregate_failures do
        expect do
          resolve_flagged_accelerated_retry(tracker: 3824)
        end.to raise_error(SystemExit, /explicit accelerated RC retry.*canonical authorization/i)
        expect do
          resolve_flagged_accelerated_retry(reason: "A different retry reason")
        end.to raise_error(SystemExit, /explicit accelerated RC retry.*canonical authorization/i)
      end
    end

    it "reuses the canonical authorization for a flagged same-tracker retry with a deleted tag" do
      allow(self).to receive_messages(
        local_release_tag_exists?: false,
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        fetch_release_tracker_issue!: {}
      )

      expect(resolve_flagged_accelerated_retry).to eq(
        target_gem_version: "17.0.0.rc.10",
        tracker: 3823,
        reason: authorization.fetch("reason"),
        allow_ci_override: false
      )
      expect(self).to have_received(:fetch_repository_accelerated_rc_records_for_candidate!).with(
        repo_slug: "shakacode/react_on_rails",
        target_version: "17.0.0.rc.10",
        candidate_sha: "f" * 40
      )
    end

    it "keeps candidate-rejected absorbing for a flagged retry after its tag is deleted" do
      publication = accelerated_rc_published_record(
        authorized_record: authorization,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      failed_ci = authorization.fetch("ci").merge(
        "status" => "failed",
        "non_success" => [authorization.dig("ci", "non_success").first.merge("state" => "failure")]
      )
      rejected = reconcile_accelerated_rc_record(
        published_record: publication,
        ci_snapshot: failed_ci,
        shakaperf: authorization.fetch("shakaperf"),
        evidence: {},
        approved_by: "justin808",
        reason: "Exact-head CI failed after publication",
        recorded_at: "2026-07-14T15:00:00Z"
      )
      allow(self).to receive_messages(
        local_release_tag_exists?: false,
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization, publication, rejected],
        fetch_release_tracker_issue!: {}
      )

      expect do
        resolve_flagged_accelerated_retry
      end.to raise_error(SystemExit, /permanently rejected/i)
    end

    it "blocks conflicting durable trackers and authorizations before a flagged retry" do
      conflicting_tracker = authorization.merge("release_tracker" => 3824)
      conflicting_authorization = authorization.merge("reason" => "Conflicting durable authorization")
      histories = {
        "trackers" => [authorization, conflicting_tracker],
        "authorizations" => [authorization, conflicting_authorization]
      }
      allow(self).to receive_messages(local_release_tag_exists?: false, fetch_release_tracker_issue!: {})

      aggregate_failures do
        histories.each do |description, records|
          allow(self).to receive(:fetch_repository_accelerated_rc_records_for_candidate!).and_return(records)
          expect do
            resolve_flagged_accelerated_retry
          end.to raise_error(SystemExit, /conflicting.*(?:trackers|authorizations)/i), description
        end
      end
    end

    it "allows a history-free explicit first attempt only after exact-candidate discovery" do
      allow(self).to receive_messages(
        local_release_tag_exists?: false,
        fetch_repository_accelerated_rc_records_for_candidate!: []
      )

      expect(resolve_flagged_accelerated_retry).to include(
        target_gem_version: "17.0.0.rc.10",
        tracker: 3823,
        reason: authorization.fetch("reason")
      )
      expect(self).to have_received(:fetch_repository_accelerated_rc_records_for_candidate!).with(
        repo_slug: "shakacode/react_on_rails",
        target_version: "17.0.0.rc.10",
        candidate_sha: "f" * 40
      )
    end
  end

  describe "#accelerated_rc_ci_snapshot" do
    it "captures every pending or skipped exact-head check with its URL" do
      snapshot = accelerated_rc_ci_snapshot(
        sha: "a" * 40,
        repo_slug: "shakacode/react_on_rails",
        check_runs: [
          {
            "id" => 1,
            "name" => "lint",
            "status" => "completed",
            "conclusion" => "success",
            "html_url" => "https://github.com/shakacode/react_on_rails/actions/runs/1"
          },
          {
            "id" => 2,
            "name" => "generator-1",
            "status" => "in_progress",
            "conclusion" => nil,
            "html_url" => "https://github.com/shakacode/react_on_rails/actions/runs/2"
          },
          {
            "id" => 3,
            "name" => "intentional-skip",
            "status" => "completed",
            "conclusion" => "skipped",
            "html_url" => "https://github.com/shakacode/react_on_rails/actions/runs/3"
          }
        ],
        statuses: []
      )

      expect(snapshot).to include(status: "pending", sha: "a" * 40)
      expect(snapshot[:non_success]).to contain_exactly(
        include(name: "generator-1", state: "in_progress", url: %r{runs/2}),
        include(name: "intentional-skip", state: "skipped", url: %r{runs/3})
      )
    end

    it "uses the exact-SHA checks page when a non-success check has no direct URL" do
      snapshot = accelerated_rc_ci_snapshot(
        sha: "a" * 40,
        repo_slug: "shakacode/react_on_rails",
        check_runs: [
          {
            "id" => 2,
            "name" => "generator-1",
            "status" => "in_progress",
            "conclusion" => nil,
            "html_url" => nil
          }
        ],
        statuses: []
      )

      expect(snapshot.fetch(:non_success)).to contain_exactly(
        include(url: "https://github.com/shakacode/react_on_rails/commit/#{'a' * 40}/checks")
      )
    end

    it "fails closed on a known failed exact-head check" do
      expect do
        accelerated_rc_ci_snapshot(
          sha: "b" * 40,
          repo_slug: "shakacode/react_on_rails",
          check_runs: [
            {
              "id" => 4,
              "name" => "generator-2",
              "status" => "completed",
              "conclusion" => "failure",
              "html_url" => "https://github.com/shakacode/react_on_rails/actions/runs/4"
            }
          ],
          statuses: []
        )
      end.to raise_error(SystemExit, %r{known failed.*generator-2.*actions/runs/4}mi)
    end

    it "fails closed when the exact-head CI API returns no evidence" do
      expect do
        accelerated_rc_ci_snapshot(
          sha: "c" * 40,
          repo_slug: "shakacode/react_on_rails",
          check_runs: [],
          statuses: []
        )
      end.to raise_error(SystemExit, /exact-head CI evidence is unknown/)
    end

    it "fails closed while a required exact-head check has not appeared" do
      expect do
        accelerated_rc_ci_snapshot(
          sha: "d" * 40,
          repo_slug: "shakacode/react_on_rails",
          check_runs: [
            {
              "id" => 5,
              "name" => "optional-docs",
              "status" => "completed",
              "conclusion" => "success",
              "html_url" => "https://github.com/shakacode/react_on_rails/actions/runs/5"
            }
          ],
          statuses: [],
          required_names: { contexts: [], checks: [{ context: "generator", app_id: nil }] }
        )
      end.to raise_error(SystemExit, /required exact-head CI checks have not appeared.*generator/i)
    end
  end

  describe "#fetch_accelerated_rc_ci_snapshot!" do
    it "fails closed when either exact-head CI API is unknown" do
      allow(self).to receive(:fetch_ci_check_runs_for_sha)
        .and_return(error: "GitHub Checks API unavailable")
      expect(self).not_to receive(:fetch_ci_statuses_for_sha)

      expect do
        fetch_accelerated_rc_ci_snapshot!(
          repo_slug: "shakacode/react_on_rails",
          sha: "f" * 40
        )
      end.to raise_error(SystemExit, /Checks API unavailable.*unknown/mi)
    end
  end

  describe "accelerated RC tracker records" do
    let(:accelerated_rc_options) do
      {
        target_gem_version: "17.0.0.rc.10",
        tracker: 3823,
        reason: "Start published-artifact QA while remaining checks finish"
      }
    end

    let(:accelerated_rc_ci_snapshot) do
      {
        status: "pending",
        sha: "f" * 40,
        checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
        non_success: [
          {
            name: "generator",
            state: "in_progress",
            url: "https://github.com/shakacode/react_on_rails/actions/runs/123"
          }
        ]
      }
    end

    let(:accelerated_rc_shakaperf_snapshot) do
      {
        status: "pending",
        run_id: 123_456,
        attempt: 1,
        run_url: "https://github.com/shakacode/react_on_rails/actions/runs/123456",
        candidate_sha: "f" * 40,
        target_version: "17.0.0.rc.10",
        release_started_at: "2026-07-14T13:00:00Z"
      }
    end

    it "blocks a fresh accelerated request over an existing ordinary lightweight target tag" do
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [],
        local_release_tag_exists?: true,
        accelerated_rc_tag_provenance_for_tag!: nil,
        run_accelerated_shakaperf_release_gate!: accelerated_rc_shakaperf_snapshot,
        fetch_accelerated_rc_ci_snapshot!: accelerated_rc_ci_snapshot,
        confirm_accelerated_rc_publication!: nil,
        shakaperf_runtime_tree_fingerprint: "a" * 64,
        fetch_release_tracker_issue!: nil,
        append_accelerated_rc_tracker_record!: nil,
        push_release_tag_for_candidate!: nil
      )

      failure = begin
        options = resolve_accelerated_rc_options_for_release!(
          requested: true,
          explicit_version_input: "17.0.0.rc.10",
          target_gem_version: "17.0.0.rc.10",
          tracker: "3823",
          reason: accelerated_rc_options.fetch(:reason),
          allow_ci_override: false,
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          current_checkout_version: "16.9.0",
          candidate_sha: nil
        )
        authorization = authorize_accelerated_rc_publication!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          release_branch: "release/17.0.0",
          candidate_sha: "f" * 40,
          options:,
          approver: "justin808",
          release_started_at: Time.utc(2026, 7, 14, 14),
          tag: "v17.0.0.rc.10"
        )
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0.rc.10",
          candidate_sha: "f" * 40,
          accelerated_publication_record: authorization
        )
        nil
      rescue SystemExit => error
        error
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/ordinary lightweight RC tag.*accelerated/i)
        expect(self).not_to have_received(:run_accelerated_shakaperf_release_gate!)
        expect(self).not_to have_received(:confirm_accelerated_rc_publication!)
        expect(self).not_to have_received(:append_accelerated_rc_tracker_record!)
        expect(self).not_to have_received(:push_release_tag_for_candidate!)
      end
    end

    it "blocks authorization when exact-candidate history already exists on another tracker" do
      conflicting_authorization = accelerated_rc_test_authorization(tracker: 3824)
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [conflicting_authorization],
        fetch_accelerated_rc_tracker_records!: [],
        local_release_tag_exists?: false,
        run_accelerated_shakaperf_release_gate!: accelerated_rc_shakaperf_snapshot,
        fetch_accelerated_rc_ci_snapshot!: accelerated_rc_ci_snapshot,
        confirm_accelerated_rc_publication!: nil,
        shakaperf_runtime_tree_fingerprint: "a" * 64,
        fetch_release_tracker_issue!: nil,
        append_accelerated_rc_tracker_record!: nil
      )

      expect do
        authorize_accelerated_rc_publication!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          release_branch: "release/17.0.0",
          candidate_sha: "f" * 40,
          options: accelerated_rc_options,
          approver: "justin808",
          release_started_at: Time.utc(2026, 7, 14, 14),
          tag: "v17.0.0.rc.10"
        )
      end.to raise_error(SystemExit, /repository-wide.*tracker|different release tracker/i)
    end

    it "blocks immutable tag handling when a cross-tracker conflict appears after authorization append" do
      authorization = accelerated_rc_test_authorization
      conflicting_authorization = accelerated_rc_test_authorization(tracker: 3824)
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization, conflicting_authorization],
        github_repo_slug: "shakacode/react_on_rails",
        system: true,
        validate_existing_accelerated_rc_tag!: nil,
        validate_release_candidate_publication_boundary!: nil,
        sh_in_dir_for_release: nil
      )

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0.rc.10",
          candidate_sha: "f" * 40,
          accelerated_publication_record: authorization
        )
      end.to raise_error(SystemExit, /repository-wide.*tracker|conflicting release trackers/i)
    end

    it "records a durable authorization state before immutable publication" do
      record = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )

      expect(record).to include(
        "status" => "publication-authorized",
        "recorded_at" => "2026-07-14T13:30:00Z",
        "required_follow_up" => /complete immutable publication/i
      )
      expect(validate_accelerated_rc_tracker_record!(record)).to eq(record)
    end

    it "transitions the authorized snapshot only after immutable publication completes" do
      authorized_record = {
        "status" => "publication-authorized",
        "target_version" => "17.0.0.rc.10",
        "candidate_sha" => "f" * 40,
        "recorded_at" => "2026-07-14T13:30:00Z"
      }

      published_record = accelerated_rc_published_record(
        authorized_record:,
        recorded_at: Time.utc(2026, 7, 14, 14, 0)
      )

      expect(published_record).to include(
        "status" => "published-awaiting-gates",
        "target_version" => "17.0.0.rc.10",
        "candidate_sha" => "f" * 40,
        "recorded_at" => "2026-07-14T14:00:00Z",
        "required_follow_up" => /reconcile_accelerated_rc/
      )
      expect(authorized_record["status"]).to eq("publication-authorized")
    end

    it "fails closed when paginated tracker comments have an unexpected JSON shape" do
      status = instance_double(Process::Status, success?: true)
      allow(self).to receive(:capture_gh_output).and_return([JSON.generate("not-pages"), status])

      expect do
        fetch_release_tracker_comments(repo_slug: "shakacode/react_on_rails", tracker: 3823)
      end.to raise_error(SystemExit, /unexpected JSON structure/)
    end

    it "loads selected-tracker comments incrementally and retains only marker comments" do
      success = instance_double(Process::Status, success?: true)
      ordinary_comments = Array.new(99) do |index|
        accelerated_rc_test_issue_comment(id: index + 1, body: "ordinary tracker discussion")
      end
      marker_comment = accelerated_rc_test_issue_comment(
        id: 100, body: ACCELERATED_RC_RECORD_MARKER
      )
      endpoint = lambda do |page|
        "repos/shakacode/react_on_rails/issues/3823/comments?per_page=100" \
          "&sort=created&direction=asc&page=#{page}"
      end
      expect(self).to receive(:capture_gh_output)
        .ordered.with("api", endpoint.call(1))
        .and_return([JSON.generate(ordinary_comments + [marker_comment]), success])
      expect(self).to receive(:capture_gh_output)
        .ordered.with("api", endpoint.call(2))
        .and_return([JSON.generate([]), success])

      expect(
        fetch_release_tracker_comments(repo_slug: "shakacode/react_on_rails", tracker: 3823)
      ).to eq([marker_comment])
    end

    it "fails closed when selected-tracker discovery reaches its configured page bound on a full page" do
      success = instance_double(Process::Status, success?: true)
      page_count = 0
      allow(self).to receive(:capture_gh_output) do
        page_count += 1
        comments = Array.new(100) do |index|
          accelerated_rc_test_issue_comment(
            id: ((page_count - 1) * 100) + index + 1,
            body: "ordinary tracker discussion"
          )
        end
        [JSON.generate(comments), success]
      end

      expect do
        fetch_release_tracker_comments(repo_slug: "shakacode/react_on_rails", tracker: 3823)
      end.to raise_error(SystemExit, /bounded release tracker.*page limit.*unknown/i)
      expect(page_count).to eq(250)
    end

    it "allows selected-tracker discovery to complete on a short 250th page" do
      success = instance_double(Process::Status, success?: true)
      page_count = 0
      final_marker = nil
      allow(self).to receive(:capture_gh_output) do
        page_count += 1
        comments = if page_count == 250
                     final_marker = accelerated_rc_test_issue_comment(
                       id: 24_901, body: ACCELERATED_RC_RECORD_MARKER
                     )
                     [final_marker]
                   else
                     Array.new(100) do |index|
                       accelerated_rc_test_issue_comment(
                         id: ((page_count - 1) * 100) + index + 1,
                         body: "ordinary tracker discussion"
                       )
                     end
                   end
        [JSON.generate(comments), success]
      end

      expect(
        fetch_release_tracker_comments(repo_slug: "shakacode/react_on_rails", tracker: 3823)
      ).to eq([final_marker])
      expect(page_count).to eq(250)
    end

    it "allows exactly 1,000 marker comments in selected-tracker discovery" do
      success = instance_double(Process::Status, success?: true)
      pages = Array.new(10) do |page|
        Array.new(100) do |index|
          accelerated_rc_test_issue_comment(
            id: (page * 100) + index + 1,
            body: ACCELERATED_RC_RECORD_MARKER
          )
        end
      end
      pages << []
      allow(self).to receive(:capture_gh_output) do
        [JSON.generate(pages.shift), success]
      end

      comments = nil
      expect do
        comments = fetch_release_tracker_comments(repo_slug: "shakacode/react_on_rails", tracker: 3823)
      end.not_to raise_error
      expect(comments).to have_attributes(length: 1_000)
    end

    it "fails closed on marker 1,001 in selected-tracker discovery" do
      success = instance_double(Process::Status, success?: true)
      pages = Array.new(10) do |page|
        Array.new(100) do |index|
          accelerated_rc_test_issue_comment(
            id: (page * 100) + index + 1,
            body: ACCELERATED_RC_RECORD_MARKER
          )
        end
      end
      pages << [accelerated_rc_test_issue_comment(id: 1_001, body: ACCELERATED_RC_RECORD_MARKER)]
      allow(self).to receive(:capture_gh_output) do
        [JSON.generate(pages.shift), success]
      end

      expect do
        fetch_release_tracker_comments(repo_slug: "shakacode/react_on_rails", tracker: 3823)
      end.to raise_error(SystemExit, /bounded release tracker.*marker.*limit.*unknown/i)
    end

    it "documents the exact accelerated-comment discovery boundaries" do
      guide = File.read(
        File.expand_path("../../../internal/contributor-info/releasing.md", __dir__)
      )
      normalized_guide = guide.gsub(/\s+/, " ")

      expect(normalized_guide).to include(
        "Exactly 1,000 retained marker comments are allowed, and a short 250th page completes discovery"
      )
      expect(normalized_guide).to include(
        "exceeding 1,000 markers or requiring a 251st page blocks as unknown"
      )
    end

    it "rejects a closed release tracker" do
      expect do
        validate_release_tracker_issue!(
          {
            "number" => 3823,
            "state" => "closed",
            "title" => "Release gate: React on Rails 17.0.0",
            "labels" => [{ "name" => "release" }, { "name" => "TRACKING" }]
          },
          tracker: 3823
        )
      end.to raise_error(SystemExit, /active open release tracker/)
    end

    it "rejects a pull request even when its issue fields otherwise look like a release tracker" do
      expect do
        validate_release_tracker_issue!(
          {
            "number" => 3823,
            "state" => "open",
            "title" => "Release gate: React on Rails 17.0.0",
            "labels" => [{ "name" => "release" }, { "name" => "TRACKING" }],
            "pull_request" => { "url" => "https://api.github.com/repos/shakacode/react_on_rails/pulls/3823" }
          },
          tracker: 3823
        )
      end.to raise_error(SystemExit, /active open release tracker/)
    end

    it "rejects an approver without maintainer repository permission" do
      expect do
        validate_release_approver!(login: "external-user", permission: "read")
      end.to raise_error(SystemExit, /write, maintain, or admin/)
    end

    it "ignores a known non-maintainer marker at an idempotent tracker append boundary" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      untrusted_marker = "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 " \
                         "#{JSON.generate({ 'schema_version' => 1 }).unpack1('H*')} -->"
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        fetch_release_tracker_comments: [
          { "body" => untrusted_marker, "user" => { "login" => "external-user" } },
          { "body" => accelerated_rc_tracker_comment(authorization), "user" => { "login" => "justin808" } }
        ]
      )
      success = instance_double(Process::Status, success?: true)
      allow(self).to receive(:capture_gh_output)
        .with(
          "api",
          "repos/shakacode/react_on_rails/collaborators/external-user/permission",
          "--jq",
          ".permission"
        ).and_return(["read\n", success])
      allow(self).to receive(:capture_gh_output)
        .with(
          "api",
          "repos/shakacode/react_on_rails/collaborators/justin808/permission",
          "--jq",
          ".permission"
        ).and_return(["write\n", success])
      expect(self).not_to receive(:post_release_tracker_comment!)

      result = nil
      failure = begin
        result = append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails", tracker: 3823, record: authorization
        )
        nil
      rescue SystemExit => error
        error
      end

      aggregate_failures do
        expect(failure).to be_nil
        expect(result).to eq(authorization)
      end
    end

    it "fails closed when a tracker marker author permission lookup fails" do
      marker = "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 " \
               "#{JSON.generate({ 'schema_version' => 1 }).unpack1('H*')} -->"
      failure = instance_double(Process::Status, success?: false)
      allow(self).to receive_messages(
        fetch_release_tracker_comments: [
          { "body" => marker, "user" => { "login" => "external-user" } }
        ],
        capture_gh_output: ["permission unavailable", failure]
      )

      expect do
        fetch_accelerated_rc_tracker_records!(repo_slug: "shakacode/react_on_rails", tracker: 3823)
      end.to raise_error(SystemExit, /Unable to verify the repository permission/)
    end

    it "fails closed on an unknown successful tracker marker permission" do
      marker = "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 " \
               "#{JSON.generate({ 'schema_version' => 1 }).unpack1('H*')} -->"
      success = instance_double(Process::Status, success?: true)
      allow(self).to receive_messages(
        fetch_release_tracker_comments: [
          { "body" => marker, "user" => { "login" => "external-user" } }
        ],
        capture_gh_output: ["future_permission\n", success]
      )

      expect do
        fetch_accelerated_rc_tracker_records!(repo_slug: "shakacode/react_on_rails", tracker: 3823)
      end.to raise_error(SystemExit, /repository permission.*unknown/i)
    end

    it "loads repository issue-comment discovery incrementally and retains only marker comments" do
      success = instance_double(Process::Status, success?: true)
      ordinary_comments = Array.new(99) do |index|
        accelerated_rc_test_issue_comment(id: index + 1, body: "ordinary repository discussion")
      end
      marker_comment = accelerated_rc_test_issue_comment(
        id: 100, body: "prefix #{ACCELERATED_RC_RECORD_MARKER} suffix"
      )
      full_page = ordinary_comments + [marker_comment]
      endpoint = lambda do |page|
        "repos/shakacode/react_on_rails/issues/comments?per_page=100&sort=created&direction=asc&page=#{page}"
      end
      expect(self).to receive(:capture_gh_output)
        .ordered.with("api", endpoint.call(1))
        .and_return([JSON.generate(full_page), success])
      expect(self).to receive(:capture_gh_output)
        .ordered.with("api", endpoint.call(2))
        .and_return([JSON.generate([]), success])

      expect(
        fetch_repository_issue_comments_for_accelerated_rc_retry!(repo_slug: "shakacode/react_on_rails")
      ).to eq([marker_comment])
    end

    it "allows a safely structured markerless repository comment whose author was deleted" do
      success = instance_double(Process::Status, success?: true)
      deleted_user_comment = accelerated_rc_test_issue_comment(
        id: 1, body: "ordinary repository discussion", user: nil
      )
      allow(self).to receive(:capture_gh_output)
        .and_return([JSON.generate([deleted_user_comment]), success])

      expect(
        fetch_repository_issue_comments_for_accelerated_rc_retry!(repo_slug: "shakacode/react_on_rails")
      ).to eq([])
    end

    it "fails closed when a repository comment page contains a malformed comment hash" do
      success = instance_double(Process::Status, success?: true)
      allow(self).to receive(:capture_gh_output).and_return([JSON.generate([{}]), success])

      expect do
        fetch_repository_issue_comments_for_accelerated_rc_retry!(repo_slug: "shakacode/react_on_rails")
      end.to raise_error(SystemExit, /comment.*schema|unexpected JSON structure/i)
    end

    it "fails closed on duplicate repository comment IDs within one page" do
      success = instance_double(Process::Status, success?: true)
      comments = [
        accelerated_rc_test_issue_comment(id: 1, body: "ordinary comment"),
        accelerated_rc_test_issue_comment(id: 1, body: "another ordinary comment")
      ]
      allow(self).to receive(:capture_gh_output).and_return([JSON.generate(comments), success])

      expect do
        fetch_repository_issue_comments_for_accelerated_rc_retry!(repo_slug: "shakacode/react_on_rails")
      end.to raise_error(SystemExit, /duplicate.*comment.*id|comment.*identity/i)
    end

    it "fails closed on duplicate repository comment IDs across pages" do
      success = instance_double(Process::Status, success?: true)
      full_page = Array.new(100) do |index|
        accelerated_rc_test_issue_comment(id: index + 1, body: "ordinary comment")
      end
      duplicate = accelerated_rc_test_issue_comment(id: 100, body: "duplicate on next page")
      responses = [full_page, [duplicate]]
      allow(self).to receive(:capture_gh_output) do
        [JSON.generate(responses.shift), success]
      end

      expect do
        fetch_repository_issue_comments_for_accelerated_rc_retry!(repo_slug: "shakacode/react_on_rails")
      end.to raise_error(SystemExit, /duplicate.*comment.*id|comment.*identity/i)
    end

    it "fails closed on out-of-order repository comments within one page" do
      success = instance_double(Process::Status, success?: true)
      comments = [
        accelerated_rc_test_issue_comment(
          id: 1, body: "ordinary comment", created_at: "2026-07-14T13:01:00Z"
        ),
        accelerated_rc_test_issue_comment(
          id: 2, body: "older ordinary comment", created_at: "2026-07-14T13:00:00Z"
        )
      ]
      allow(self).to receive(:capture_gh_output).and_return([JSON.generate(comments), success])

      expect do
        fetch_repository_issue_comments_for_accelerated_rc_retry!(repo_slug: "shakacode/react_on_rails")
      end.to raise_error(SystemExit, /comment.*chronolog|out.of.order/i)
    end

    it "fails closed on out-of-order repository comment pages" do
      success = instance_double(Process::Status, success?: true)
      full_page = Array.new(100) do |index|
        accelerated_rc_test_issue_comment(
          id: index + 1, body: "ordinary comment", created_at: "2026-07-14T13:01:00Z"
        )
      end
      older_comment = accelerated_rc_test_issue_comment(
        id: 101, body: "older comment on next page", created_at: "2026-07-14T13:00:00Z"
      )
      responses = [full_page, [older_comment]]
      allow(self).to receive(:capture_gh_output) do
        [JSON.generate(responses.shift), success]
      end

      expect do
        fetch_repository_issue_comments_for_accelerated_rc_retry!(repo_slug: "shakacode/react_on_rails")
      end.to raise_error(SystemExit, /comment.*chronolog|out.of.order/i)
    end

    it "fails closed at the bounded repository issue-comment page limit" do
      stub_const("ACCELERATED_RC_REPOSITORY_COMMENT_MAX_PAGES", 2)
      success = instance_double(Process::Status, success?: true)
      pages = Array.new(2) do |page|
        Array.new(100) do |index|
          accelerated_rc_test_issue_comment(
            id: (page * 100) + index + 1, body: "ordinary repository discussion"
          )
        end
      end
      allow(self).to receive(:capture_gh_output) do
        [JSON.generate(pages.shift), success]
      end

      expect do
        fetch_repository_issue_comments_for_accelerated_rc_retry!(repo_slug: "shakacode/react_on_rails")
      end.to raise_error(SystemExit, /bounded repository.*page limit.*unknown/i)
      expect(self).to have_received(:capture_gh_output).twice
    end

    it "fails closed at the bounded repository accelerated-marker retention limit" do
      stub_const("ACCELERATED_RC_REPOSITORY_MARKER_COMMENT_LIMIT", 1)
      success = instance_double(Process::Status, success?: true)
      marker_comments = Array.new(2) do |index|
        accelerated_rc_test_issue_comment(id: index + 1, body: ACCELERATED_RC_RECORD_MARKER)
      end
      allow(self).to receive(:capture_gh_output).and_return([JSON.generate(marker_comments), success])

      expect do
        fetch_repository_issue_comments_for_accelerated_rc_retry!(repo_slug: "shakacode/react_on_rails")
      end.to raise_error(SystemExit, /bounded repository.*marker.*limit.*unknown/i)
    end

    it "discovers exact candidate history from trusted repository issue comments" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      comment = accelerated_rc_test_issue_comment(
        id: 1,
        body: accelerated_rc_tracker_comment(authorization),
        user: { "login" => "justin808" }
      )
      success = instance_double(Process::Status, success?: true)
      allow(self).to receive(:capture_gh_output)
        .with(
          "api",
          "repos/shakacode/react_on_rails/issues/comments?per_page=100&sort=created&direction=asc&page=1"
        ).and_return([JSON.generate([comment]), success])
      allow(self).to receive(:capture_gh_output)
        .with(
          "api", "repos/shakacode/react_on_rails/collaborators/justin808/permission", "--jq", ".permission"
        ).and_return(["maintain\n", success])
      allow(self).to receive(:fetch_release_tracker_issue!).and_return({})

      expect(
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      ).to eq([authorization])
    end

    it "caches eligibility for repeated repository-discovered markers on the same tracker" do
      authorization = accelerated_rc_test_authorization
      comments = [
        accelerated_rc_test_issue_comment(
          id: 1,
          body: accelerated_rc_tracker_comment(authorization),
          user: { "login" => "justin808" }
        ),
        accelerated_rc_test_issue_comment(
          id: 2,
          body: accelerated_rc_tracker_comment(authorization),
          created_at: "2026-07-14T13:01:00Z",
          user: { "login" => "justin808" }
        )
      ]
      allow(self).to receive_messages(
        fetch_repository_issue_comments_for_accelerated_rc_retry!: comments,
        accelerated_rc_repository_comment_permission!: "maintain"
      )
      expect(self).to receive(:fetch_release_tracker_issue!)
        .once.with(repo_slug: "shakacode/react_on_rails", tracker: 3823)
        .and_return({})

      expect(
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      ).to eq([authorization, authorization])
    end

    it "rejects repository-discovered candidate history whose canonical issue URL resolves to a pull request" do
      authorization = accelerated_rc_test_authorization
      comment = accelerated_rc_test_issue_comment(
        id: 1,
        body: accelerated_rc_tracker_comment(authorization),
        user: { "login" => "justin808" }
      )
      success = instance_double(Process::Status, success?: true)
      pull_request_issue = {
        "number" => 3823,
        "state" => "open",
        "title" => "Release gate: React on Rails 17.0.0",
        "labels" => [{ "name" => "release" }, { "name" => "TRACKING" }],
        "pull_request" => { "url" => "https://api.github.com/repos/shakacode/react_on_rails/pulls/3823" }
      }
      allow(self).to receive(:fetch_repository_issue_comments_for_accelerated_rc_retry!).and_return([comment])
      allow(self).to receive(:capture_gh_output)
        .with("api", "repos/shakacode/react_on_rails/issues/3823")
        .and_return([JSON.generate(pull_request_issue), success])
      allow(self).to receive(:capture_gh_output)
        .with(
          "api", "repos/shakacode/react_on_rails/collaborators/justin808/permission", "--jq", ".permission"
        ).and_return(["maintain\n", success])

      expect do
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      end.to raise_error(SystemExit, /active open release tracker/)
    end

    it "ignores one clearly unrelated valid repository marker before author permission checks" do
      unrelated_options = accelerated_rc_options.merge(target_gem_version: "16.9.0.rc.1")
      unrelated_authorization = build_accelerated_rc_publication_record(
        options: unrelated_options,
        candidate_sha: "e" * 40,
        runtime_tree_fingerprint: "b" * 64,
        release_branch: "release/16.9.0",
        ci_snapshot: accelerated_rc_ci_snapshot.merge(sha: "e" * 40),
        shakaperf: accelerated_rc_shakaperf_snapshot.merge(
          candidate_sha: "e" * 40,
          target_version: "16.9.0.rc.1"
        ),
        approved_by: "read-only-user",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      unrelated_marker = accelerated_rc_tracker_comment(unrelated_authorization).lines.first
      comments = [{
        "body" => unrelated_marker,
        "issue_url" => "https://api.github.com/repos/shakacode/react_on_rails/issues/3800",
        "user" => { "login" => "read-only-user" }
      }]
      allow(self).to receive(:fetch_repository_issue_comments_for_accelerated_rc_retry!).and_return(comments)
      expect(self).not_to receive(:accelerated_rc_repository_comment_permission!)
      expect(self).not_to receive(:fetch_release_tracker_issue!)

      expect(
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      ).to eq([])
    end

    it "ignores an exact-candidate repository marker after proving its author is not a maintainer" do
      authorization = accelerated_rc_test_authorization
      comment = accelerated_rc_test_issue_comment(
        id: 1,
        body: accelerated_rc_tracker_comment(authorization),
        user: { "login" => "read-only-user" }
      )
      allow(self).to receive_messages(
        fetch_repository_issue_comments_for_accelerated_rc_retry!: [comment],
        accelerated_rc_repository_comment_permission!: "read"
      )
      expect(self).not_to receive(:fetch_release_tracker_issue!)

      expect(
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      ).to eq([])
    end

    it "fails closed when exact-candidate marker author permission cannot be determined" do
      authorization = accelerated_rc_test_authorization
      comment = accelerated_rc_test_issue_comment(
        id: 1,
        body: accelerated_rc_tracker_comment(authorization),
        user: { "login" => "unknown-user" }
      )
      allow(self).to receive(:fetch_repository_issue_comments_for_accelerated_rc_retry!).and_return([comment])
      allow(self).to receive(:accelerated_rc_repository_comment_permission!).and_raise(
        SystemExit, "Unable to verify repository permission"
      )

      expect do
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      end.to raise_error(SystemExit, /Unable to verify repository permission/)
    end

    it "fails closed on blank or unrecognized successful repository permission responses" do
      success = instance_double(Process::Status, success?: true)
      allow(self).to receive(:capture_gh_output)
        .with(
          "api", "repos/shakacode/react_on_rails/collaborators/blank-user/permission", "--jq", ".permission"
        ).and_return(["\n", success])

      aggregate_failures do
        expect do
          accelerated_rc_repository_comment_permission!(
            repo_slug: "shakacode/react_on_rails", login: "blank-user", permissions: {}
          )
        end.to raise_error(SystemExit, /repository permission.*unknown/i)

        expect do
          accelerated_rc_repository_comment_permission!(
            repo_slug: "shakacode/react_on_rails",
            login: "future-user",
            permissions: { "future-user" => "future_permission" }
          )
        end.to raise_error(SystemExit, /repository permission.*unknown/i)

        expect do
          accelerated_rc_repository_comment_permission!(
            repo_slug: "shakacode/react_on_rails", login: "nil-user", permissions: { "nil-user" => nil }
          )
        end.to raise_error(SystemExit, /repository permission.*unknown/i)
      end
    end

    it "fails closed when repository discovery receives a blank or unrecognized permission classification" do
      authorization = accelerated_rc_test_authorization
      comment = accelerated_rc_test_issue_comment(
        id: 1,
        body: accelerated_rc_tracker_comment(authorization),
        user: { "login" => "unknown-user" }
      )
      allow(self).to receive(:fetch_repository_issue_comments_for_accelerated_rc_retry!).and_return([comment])

      aggregate_failures do
        ["", "future_permission"].each do |permission|
          allow(self).to receive(:accelerated_rc_repository_comment_permission!).and_return(permission)

          expect do
            fetch_repository_accelerated_rc_records_for_candidate!(
              repo_slug: "shakacode/react_on_rails",
              target_version: "17.0.0.rc.10",
              candidate_sha: "f" * 40
            )
          end.to raise_error(SystemExit, /repository permission.*unknown/i), permission.inspect
        end
      end
    end

    it "strictly rejects complete unrelated records whose marker encoding is noncanonical" do
      unrelated_authorization = accelerated_rc_test_authorization.merge(
        "target_version" => "16.9.0.rc.1",
        "candidate_sha" => "e" * 40,
        "release_branch" => "release/16.9.0",
        "ci" => accelerated_rc_test_authorization.fetch("ci").merge("sha" => "e" * 40),
        "shakaperf" => accelerated_rc_test_authorization.fetch("shakaperf").merge(
          "candidate_sha" => "e" * 40,
          "target_version" => "16.9.0.rc.1"
        )
      )
      canonical_json = JSON.generate(canonical_accelerated_rc_value(unrelated_authorization))
      noncanonical_payloads = {
        "reordered whitespace JSON" => JSON.pretty_generate(unrelated_authorization.to_a.reverse.to_h).unpack1("H*"),
        "uppercase hexadecimal" => canonical_json.unpack1("H*").upcase
      }
      allow(self).to receive(:accelerated_rc_repository_comment_permission!).and_return("maintain")

      aggregate_failures do
        noncanonical_payloads.each do |description, encoded_payload|
          comment = {
            "body" => "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 #{encoded_payload} -->",
            "issue_url" => "https://api.github.com/repos/shakacode/react_on_rails/issues/3823",
            "user" => { "login" => "justin808" }
          }
          allow(self).to receive(:fetch_repository_issue_comments_for_accelerated_rc_retry!).and_return([comment])

          expect do
            fetch_repository_accelerated_rc_records_for_candidate!(
              repo_slug: "shakacode/react_on_rails",
              target_version: "17.0.0.rc.10",
              candidate_sha: "f" * 40
            )
          end.to raise_error(SystemExit, /malformed accelerated RC record/), description
        end
      end
      expect(self).to have_received(:accelerated_rc_repository_comment_permission!).twice
    end

    it "strictly rejects an incomplete valid-JSON unrelated repository marker" do
      incomplete_record = {
        "target_version" => "16.9.0.rc.1",
        "candidate_sha" => "e" * 40
      }
      encoded_payload = JSON.generate(incomplete_record).unpack1("H*")
      comment = {
        "body" => "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 #{encoded_payload} -->",
        "issue_url" => "https://api.github.com/repos/shakacode/react_on_rails/issues/3800",
        "user" => { "login" => "justin808" }
      }
      allow(self).to receive_messages(
        fetch_repository_issue_comments_for_accelerated_rc_retry!: [comment],
        accelerated_rc_repository_comment_permission!: "maintain"
      )

      expect do
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
      expect(self).to have_received(:accelerated_rc_repository_comment_permission!)
    end

    it "strictly rejects duplicated valid unrelated repository markers as malformed" do
      unrelated_authorization = accelerated_rc_test_authorization.merge(
        "target_version" => "16.9.0.rc.1",
        "candidate_sha" => "e" * 40,
        "release_branch" => "release/16.9.0",
        "ci" => accelerated_rc_test_authorization.fetch("ci").merge("sha" => "e" * 40),
        "shakaperf" => accelerated_rc_test_authorization.fetch("shakaperf").merge(
          "candidate_sha" => "e" * 40,
          "target_version" => "16.9.0.rc.1"
        )
      )
      unrelated_marker = accelerated_rc_tracker_comment(unrelated_authorization).lines.first
      comment = {
        "body" => "#{unrelated_marker}#{unrelated_marker}",
        "issue_url" => "https://api.github.com/repos/shakacode/react_on_rails/issues/3800",
        "user" => { "login" => "justin808" }
      }
      allow(self).to receive_messages(
        fetch_repository_issue_comments_for_accelerated_rc_retry!: [comment],
        accelerated_rc_repository_comment_permission!: "maintain"
      )

      expect do
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
    end

    it "fails closed when a malformed repository marker plausibly names the exact candidate" do
      comment = {
        "body" => "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 not-hex -->\n" \
                  "- RC: `17.0.0.rc.10` at `#{'f' * 40}`",
        "issue_url" => "https://api.github.com/repos/shakacode/react_on_rails/issues/3823",
        "user" => { "login" => "justin808" }
      }
      allow(self).to receive_messages(
        fetch_repository_issue_comments_for_accelerated_rc_retry!: [comment],
        accelerated_rc_repository_comment_permission!: "maintain"
      )

      expect do
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
    end

    it "strictly parses a corrupted encoded marker that names the exact candidate despite a spoofed summary" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      corrupted_payload = "#{JSON.generate(authorization)} trailing-corruption".unpack1("H*")
      comment = {
        "body" => "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 #{corrupted_payload} -->\n" \
                  "- RC: `16.9.0.rc.1` at `#{'e' * 40}`",
        "issue_url" => "https://api.github.com/repos/shakacode/react_on_rails/issues/3823",
        "user" => { "login" => "justin808" }
      }
      allow(self).to receive_messages(
        fetch_repository_issue_comments_for_accelerated_rc_retry!: [comment],
        accelerated_rc_repository_comment_permission!: "maintain"
      )

      expect do
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
    end

    it "strictly parses uppercase encoded exact-candidate markers before ignoring malformed JSON" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      corrupted_payload = "#{JSON.generate(authorization)} trailing-corruption".unpack1("H*").upcase
      comment = {
        "body" => "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 #{corrupted_payload} -->",
        "issue_url" => "https://api.github.com/repos/shakacode/react_on_rails/issues/3823",
        "user" => { "login" => "justin808" }
      }
      allow(self).to receive_messages(
        fetch_repository_issue_comments_for_accelerated_rc_retry!: [comment],
        accelerated_rc_repository_comment_permission!: "maintain"
      )

      expect do
        fetch_repository_accelerated_rc_records_for_candidate!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40
        )
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
    end

    it "fails closed for every malformed marker shape that cannot prove it targets another candidate" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      unrelated_authorization = authorization.merge(
        "target_version" => "16.9.0.rc.1",
        "candidate_sha" => "e" * 40,
        "release_branch" => "release/16.9.0",
        "ci" => authorization.fetch("ci").merge("sha" => "e" * 40),
        "shakaperf" => authorization.fetch("shakaperf").merge(
          "candidate_sha" => "e" * 40,
          "target_version" => "16.9.0.rc.1"
        )
      )
      exact_payload = JSON.generate(authorization).unpack1("H*")
      odd_exact_payload = exact_payload[0...-1]
      escaped_version = ["17", '\u002e', "0", '\u002e', "0", '\u002e', "rc", '\u002e', "10"].join
      escaped_sha = '\u0066' * 40
      escaped_corrupt_payload =
        %({"target_version":"#{escaped_version}","candidate_sha":"#{escaped_sha}"} trailing-corruption).unpack1("H*")
      unrelated_marker = accelerated_rc_tracker_comment(unrelated_authorization).lines.first.strip
      spoofed_summary = "- RC: `16.8.0.rc.2` at `#{'d' * 40}`"
      malformed_bodies = {
        "odd-length exact payload" =>
          "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 #{odd_exact_payload} -->\n#{spoofed_summary}",
        "Unicode-escaped exact identity with trailing corruption" =>
          "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 #{escaped_corrupt_payload} -->\n#{spoofed_summary}",
        "corrupted marker boundary" =>
          "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 #{exact_payload} --!>\n#{spoofed_summary}",
        "unrelated marker followed by a duplicated malformed exact marker" =>
          "#{unrelated_marker}\n<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 #{odd_exact_payload} -->\n#{spoofed_summary}"
      }
      allow(self).to receive(:accelerated_rc_repository_comment_permission!).and_return("maintain")

      aggregate_failures do
        malformed_bodies.each do |description, body|
          comment = {
            "body" => body,
            "issue_url" => "https://api.github.com/repos/shakacode/react_on_rails/issues/3823",
            "user" => { "login" => "justin808" }
          }
          allow(self).to receive(:fetch_repository_issue_comments_for_accelerated_rc_retry!).and_return([comment])

          expect do
            fetch_repository_accelerated_rc_records_for_candidate!(
              repo_slug: "shakacode/react_on_rails",
              target_version: "17.0.0.rc.10",
              candidate_sha: "f" * 40
            )
          end.to raise_error(SystemExit, /malformed accelerated RC record/), description
        end
      end
    end

    it "rejects repository discovery comments whose issue URL is not the exact requested repository issue" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      invalid_urls = [
        "https://github.com/shakacode/react_on_rails/issues/3823",
        "https://api.github.example/repos/shakacode/react_on_rails/issues/3823",
        "https://api.github.com/repos/other/react_on_rails/issues/3823",
        "https://api.github.com/repos/shakacode/other/issues/3823",
        "https://api.github.com/repos/shakacode/react_on_rails/pulls/3823",
        "https://api.github.com/repos/shakacode/react_on_rails/issues/3823/extra",
        "https://api.github.com/repos/shakacode/react_on_rails/issues/3823?redirect=/issues/3824",
        "https://api.github.com/repos/shakacode/react_on_rails/issues/3823#issues/3824",
        "not-a-url/issues/3823"
      ]
      expect(self).not_to receive(:accelerated_rc_repository_comment_permission!)

      aggregate_failures do
        invalid_urls.each do |issue_url|
          comment = {
            "body" => accelerated_rc_tracker_comment(authorization),
            "issue_url" => issue_url,
            "user" => { "login" => "justin808" }
          }
          expect do
            trusted_accelerated_rc_records_from_repository_comment!(
              comment:, repo_slug: "shakacode/react_on_rails", permissions: {}
            )
          end.to raise_error(SystemExit, /exact requested repository issue URL/i), issue_url
        end
      end
    end

    it "accepts the canonical API issue URL for the exact requested repository" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      comment = {
        "body" => accelerated_rc_tracker_comment(authorization),
        "issue_url" => "https://api.github.com/repos/shakacode/react_on_rails/issues/3823",
        "user" => { "login" => "justin808" }
      }
      allow(self).to receive_messages(
        accelerated_rc_repository_comment_permission!: "maintain",
        fetch_release_tracker_issue!: {}
      )

      expect(
        trusted_accelerated_rc_records_from_repository_comment!(
          comment:, repo_slug: "shakacode/react_on_rails", permissions: {}
        )
      ).to eq([authorization])
    end

    it "rejects an auditable record that names a different approver than its comment author" do
      record = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "claimed-approver",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      status = instance_double(Process::Status, success?: true)
      allow(self).to receive_messages(
        fetch_release_tracker_comments: [
          { "body" => accelerated_rc_tracker_comment(record), "user" => { "login" => "actual-author" } }
        ],
        capture_gh_output: ["write\n", status]
      )

      expect do
        fetch_accelerated_rc_tracker_records!(repo_slug: "shakacode/react_on_rails", tracker: 3823)
      end.to raise_error(SystemExit, /approver does not match.*comment author/i)
    end

    it "round-trips a published-awaiting-gates record through the auditable comment marker" do
      record = {
        "schema_version" => 1,
        "status" => "published-awaiting-gates",
        "target_version" => "17.0.0.rc.10",
        "candidate_sha" => "f" * 40,
        "release_tracker" => 3823,
        "runtime_tree_fingerprint" => "a" * 64,
        "release_branch" => "release/17.0.0",
        "ci" => {
          "status" => "pending",
          "sha" => "f" * 40,
          "checks_url" => "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          "non_success" => [
            {
              "name" => "generator",
              "state" => "in_progress",
              "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123"
            }
          ]
        },
        "shakaperf" => {
          "status" => "pending",
          "run_id" => 123_456,
          "attempt" => 1,
          "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          "candidate_sha" => "f" * 40,
          "target_version" => "17.0.0.rc.10",
          "release_started_at" => "2026-07-14T13:00:00Z"
        },
        "reason" => "Start published-artifact QA while remaining checks finish",
        "approved_by" => "justin808",
        "recorded_at" => "2026-07-14T13:30:00Z",
        "required_follow_up" => "Run reconciliation before final promotion.",
        "evidence" => {}
      }

      comment = accelerated_rc_tracker_comment(record)

      expect(comment).to include("published-awaiting-gates", "17.0.0.rc.10", "123456")
      expect(comment).to include(canonical_accelerated_rc_encoded_payload(record))
      expect(accelerated_rc_records_from_comments([{ "body" => comment }])).to eq([record])
    end

    it "fails closed when a tracker marker is malformed instead of ignoring it" do
      comment = "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 {not-json} -->"

      expect do
        accelerated_rc_records_from_comments([{ "body" => comment }])
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
    end

    it "fails closed when a tracker marker contains an incomplete hex payload" do
      comment = "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 f -->"

      expect do
        accelerated_rc_records_from_comments([{ "body" => comment }])
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
    end

    it "fails closed when a tracker marker uses an unsupported schema" do
      record = { "schema_version" => 2, "status" => "candidate-accepted" }
      payload = JSON.generate(record).unpack1("H*")
      comment = "<!-- #{ACCELERATED_RC_RECORD_MARKER} v2 #{payload} -->"

      expect do
        accelerated_rc_records_from_comments([{ "body" => comment }])
      end.to raise_error(SystemExit, /unsupported accelerated RC record schema/)
    end

    it "fails closed when a versioned tracker record omits required identity fields" do
      record = { "schema_version" => 1, "status" => "candidate-accepted" }
      payload = JSON.generate(record).unpack1("H*")
      comment = "<!-- #{ACCELERATED_RC_RECORD_MARKER} v1 #{payload} -->"

      expect do
        accelerated_rc_records_from_comments([{ "body" => comment }])
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
    end

    it "rejects a candidate-accepted state whose required evidence is incomplete" do
      record = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot.merge(status: "success"),
        shakaperf: accelerated_rc_shakaperf_snapshot.merge(status: "success"),
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      ).merge("status" => "candidate-accepted")

      expect do
        validate_accelerated_rc_tracker_record!(record)
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
    end

    it "rejects malformed nested CI evidence and unknown ShakaPerf fields" do
      record = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )

      malformed_ci = Marshal.load(Marshal.dump(record))
      malformed_ci["ci"]["non_success"] = "malformed"
      expect do
        validate_accelerated_rc_tracker_record!(malformed_ci)
      end.to raise_error(SystemExit, /malformed accelerated RC record/)

      malformed_shakaperf = Marshal.load(Marshal.dump(record))
      malformed_shakaperf["shakaperf"]["unexpected"] = true
      expect do
        validate_accelerated_rc_tracker_record!(malformed_shakaperf)
      end.to raise_error(SystemExit, /malformed accelerated RC record/)

      nil_ci = Marshal.load(Marshal.dump(record))
      nil_ci["ci"] = nil
      expect do
        validate_accelerated_rc_tracker_record!(nil_ci)
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
    end

    it "refuses to publish an invalid locally generated tracker record" do
      expect(self).not_to receive(:fetch_accelerated_rc_tracker_records!)
      expect(self).not_to receive(:post_release_tracker_comment!)

      expect do
        append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          record: { "schema_version" => 1 }
        )
      end.to raise_error(SystemExit, /malformed accelerated RC record/)
    end

    it "re-reads the tracker after posting and rejects a concurrently appended authorization" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      conflicting_authorization = authorization.merge("reason" => "Concurrent authorization")
      allow(self).to receive(:fetch_repository_accelerated_rc_records_for_candidate!).and_return([])
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!).and_return(
        [],
        [authorization, conflicting_authorization]
      )
      allow(self).to receive(:post_release_tracker_comment!)

      expect do
        append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          record: authorization
        )
      end.to raise_error(SystemExit, /conflicting canonical publication authorizations/i)
    end

    it "requires the exact posted payload instead of a concurrent retry-equivalent publication" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      concurrent_publication = accelerated_rc_published_record(
        authorized_record: authorization,
        approved_by: "first-maintainer",
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      posted_publication = concurrent_publication.merge(
        "approved_by" => "second-maintainer",
        "recorded_at" => "2026-07-14T14:01:00Z"
      )
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!).and_return(
        [authorization],
        [authorization, concurrent_publication]
      )
      allow(self).to receive(:post_release_tracker_comment!)

      expect do
        append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          record: posted_publication
        )
      end.to raise_error(SystemExit, /append could not be verified after posting/i)
    end

    it "reuses only the canonical persisted record for an equivalent retry" do
      authorized_record = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      persisted_record = accelerated_rc_published_record(
        authorized_record:,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      retry_record = persisted_record.merge(
        "approved_by" => "another-maintainer",
        "recorded_at" => "2026-07-14T14:01:00Z"
      )
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!)
        .with(repo_slug: "shakacode/react_on_rails", tracker: 3823)
        .and_return([authorized_record, persisted_record])
      expect(self).not_to receive(:post_release_tracker_comment!)

      result = nil
      expect do
        result = append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          record: retry_record
        )
      end.not_to raise_error
      expect(result).to eq(persisted_record)
    end

    it "rejects the complete publication set before an append can reuse its canonical first record" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      canonical_publication = accelerated_rc_published_record(
        authorized_record: authorization,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      mutated_publication = canonical_publication.merge(
        "shakaperf" => canonical_publication.fetch("shakaperf").merge(
          "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/654321"
        )
      )
      retry_record = canonical_publication.merge(
        "approved_by" => "another-maintainer",
        "recorded_at" => "2026-07-14T14:01:00Z"
      )
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!)
        .and_return([authorization, canonical_publication, mutated_publication])
      expect(self).not_to receive(:post_release_tracker_comment!)

      expect do
        append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          record: retry_record
        )
      end.to raise_error(SystemExit, /publication set.*not the canonical authorized transition/i)
    end

    it "rejects conflicting authorizations before an append can reuse canonical publication state" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      conflicting_authorization = authorization.merge(
        "ci" => authorization.fetch("ci").merge("status" => "success", "non_success" => [])
      )
      canonical_publication = accelerated_rc_published_record(
        authorized_record: authorization,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      retry_record = canonical_publication.merge("recorded_at" => "2026-07-14T14:01:00Z")
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!)
        .and_return([authorization, conflicting_authorization, canonical_publication])
      expect(self).not_to receive(:post_release_tracker_comment!)

      expect do
        append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          record: retry_record
        )
      end.to raise_error(SystemExit, /conflicting canonical publication authorizations/i)
    end

    it "rejects appending terminal candidate state before canonical publication" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      accepted = authorization.merge(
        "status" => "candidate-accepted",
        "ci" => authorization.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => authorization.fetch("shakaperf").merge("status" => "success"),
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        },
        "required_follow_up" => "Proceed only through the strict final promotion gates."
      )
      expect(validate_accelerated_rc_tracker_record!(accepted)).to eq(accepted)
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!).and_return([authorization])
      expect(self).not_to receive(:post_release_tracker_comment!)

      expect do
        append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          record: accepted
        )
      end.to raise_error(SystemExit, /canonical published-awaiting-gates transition is missing/i)
    end

    it "does not append candidate-accepted after candidate-rejected" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      publication = accelerated_rc_published_record(
        authorized_record: authorization,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      rejected = publication.merge(
        "status" => "candidate-rejected",
        "ci" => publication.fetch("ci").merge(
          "status" => "failed",
          "non_success" => [
            { "name" => "generator", "state" => "failure", "url" => "https://example.com/failure" }
          ]
        ),
        "reason" => "Exact-head CI failed",
        "required_follow_up" => "Do not promote this immutable RC; fix the failure and cut the next RC."
      )
      accepted = publication.merge(
        "status" => "candidate-accepted",
        "ci" => publication.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => publication.fetch("shakaperf").merge("status" => "success"),
        "reason" => "All required evidence passed",
        "required_follow_up" => "Proceed only through the strict final promotion gates.",
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        }
      )
      expect(validate_accelerated_rc_tracker_record!(rejected)).to eq(rejected)
      expect(validate_accelerated_rc_tracker_record!(accepted)).to eq(accepted)
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!)
        .and_return([authorization, publication, rejected])
      expect(self).not_to receive(:post_release_tracker_comment!)

      expect do
        append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          record: accepted
        )
      end.to raise_error(SystemExit, /permanently rejected.*absorbing/i)
    end

    it "rejects a same-state retry when its authorization evidence changed" do
      record = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [record],
        fetch_accelerated_rc_tracker_records!: [record]
      )
      expect(self).not_to receive(:post_release_tracker_comment!)

      expect do
        append_accelerated_rc_tracker_record!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          record: record.merge("reason" => "Changed authorization after interruption")
        )
      end.to raise_error(SystemExit, /not canonical|conflicting canonical publication authorizations/i)
    end

    it "blocks fresh authorization when pending CI fails during confirmation" do
      failed_ci = accelerated_rc_ci_snapshot.merge(
        status: "failed",
        non_success: [accelerated_rc_ci_snapshot.fetch(:non_success).first.merge(state: "failure")]
      )
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [],
        local_release_tag_exists?: false,
        run_accelerated_shakaperf_release_gate!: accelerated_rc_shakaperf_snapshot,
        confirm_accelerated_rc_publication!: nil,
        accelerated_rc_shakaperf_snapshot!: json_compatible_release_value(accelerated_rc_shakaperf_snapshot),
        shakaperf_runtime_tree_fingerprint: "a" * 64,
        fetch_release_tracker_issue!: nil,
        append_accelerated_rc_tracker_record!: nil,
        push_release_tag_for_candidate!: nil
      )
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!)
        .and_return(accelerated_rc_ci_snapshot, failed_ci)

      failure = begin
        authorization = authorize_accelerated_rc_publication!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          release_branch: "release/17.0.0",
          candidate_sha: "f" * 40,
          options: accelerated_rc_options,
          approver: "justin808",
          release_started_at: Time.utc(2026, 7, 14, 14),
          tag: "v17.0.0.rc.10"
        )
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0.rc.10",
          candidate_sha: "f" * 40,
          accelerated_publication_record: authorization
        )
        nil
      rescue SystemExit => error
        error
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/refreshed.*exact-candidate CI.*failed|known failed.*CI/i)
        expect(self).to have_received(:accelerated_rc_shakaperf_snapshot!).once
        expect(self).to have_received(:fetch_accelerated_rc_ci_snapshot!).twice
        expect(self).not_to have_received(:append_accelerated_rc_tracker_record!)
        expect(self).not_to have_received(:push_release_tag_for_candidate!)
      end
    end

    it "reconfirms materially changed pending evidence before recording fresh authorization" do
      changed_ci = accelerated_rc_ci_snapshot.merge(
        non_success: accelerated_rc_ci_snapshot.fetch(:non_success) + [{
          name: "docs",
          state: "queued",
          url: "https://github.com/shakacode/react_on_rails/actions/runs/124"
        }]
      )
      persisted_record = nil
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [],
        local_release_tag_exists?: false,
        run_accelerated_shakaperf_release_gate!: accelerated_rc_shakaperf_snapshot,
        confirm_accelerated_rc_publication!: nil,
        accelerated_rc_shakaperf_snapshot!: json_compatible_release_value(accelerated_rc_shakaperf_snapshot),
        shakaperf_runtime_tree_fingerprint: "a" * 64,
        fetch_release_tracker_issue!: nil
      )
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!)
        .and_return(accelerated_rc_ci_snapshot, changed_ci, changed_ci)
      allow(self).to receive(:append_accelerated_rc_tracker_record!) do |record:, **|
        persisted_record = record
      end

      authorize_accelerated_rc_publication!(
        repo_slug: "shakacode/react_on_rails",
        monorepo_root: "/tmp/repo",
        release_branch: "release/17.0.0",
        candidate_sha: "f" * 40,
        options: accelerated_rc_options,
        approver: "justin808",
        release_started_at: Time.utc(2026, 7, 14, 14),
        tag: "v17.0.0.rc.10"
      )

      aggregate_failures do
        expect(self).to have_received(:confirm_accelerated_rc_publication!).twice
        expect(self).to have_received(:accelerated_rc_shakaperf_snapshot!).twice
        expect(self).to have_received(:fetch_accelerated_rc_ci_snapshot!).exactly(3).times
        expect(persisted_record.fetch("ci")).to eq(json_compatible_release_value(changed_ci))
      end
    end

    it "does not reconfirm when pending CI checks only arrive in a different order" do
      check_runs = [
        {
          "id" => 1,
          "name" => "generator",
          "status" => "in_progress",
          "conclusion" => nil,
          "html_url" => "https://github.com/shakacode/react_on_rails/actions/runs/123"
        },
        {
          "id" => 2,
          "name" => "docs",
          "status" => "queued",
          "conclusion" => nil,
          "html_url" => "https://github.com/shakacode/react_on_rails/actions/runs/124"
        }
      ]
      snapshot_arguments = {
        sha: "f" * 40,
        repo_slug: "shakacode/react_on_rails",
        statuses: []
      }
      snapshot_builder = Object.instance_method(:accelerated_rc_ci_snapshot).bind(self)
      prompted_ci = snapshot_builder.call(**snapshot_arguments, check_runs:)
      refreshed_ci = snapshot_builder.call(**snapshot_arguments, check_runs: check_runs.reverse)
      allow(self).to receive(:confirm_accelerated_rc_publication!)
      allow(self).to receive(:refresh_accelerated_rc_live_evidence!).and_return(
        ci: refreshed_ci,
        shakaperf: accelerated_rc_shakaperf_snapshot
      )

      evidence = confirmed_fresh_accelerated_rc_evidence!(
        repo_slug: "shakacode/react_on_rails",
        monorepo_root: "/tmp/repo",
        release_branch: "release/17.0.0",
        candidate_sha: "f" * 40,
        target_version: "17.0.0.rc.10",
        tracker: 3823,
        reason: accelerated_rc_options.fetch(:reason),
        ci_snapshot: prompted_ci,
        shakaperf: accelerated_rc_shakaperf_snapshot
      )

      aggregate_failures do
        expect(self).to have_received(:confirm_accelerated_rc_publication!).once
        expect(evidence.fetch(:ci)).to eq(prompted_ci)
      end
    end

    it "refreshes live pending evidence before reusing persisted authorization" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        fetch_accelerated_rc_tracker_records!: [authorization],
        local_release_tag_exists?: false
      )
      expect(self).not_to receive(:run_accelerated_shakaperf_release_gate!)
      allow(self).to receive(:accelerated_rc_shakaperf_snapshot!).with(
        repo_slug: "shakacode/react_on_rails",
        monorepo_root: "/tmp/repo",
        record: authorization
      ).and_return(authorization.fetch("shakaperf"))
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!).with(
        repo_slug: "shakacode/react_on_rails",
        sha: "f" * 40,
        monorepo_root: "/tmp/repo",
        ci_branch: "release/17.0.0"
      ).and_return(accelerated_rc_ci_snapshot)
      expect(self).not_to receive(:confirm_accelerated_rc_publication!)
      expect(self).not_to receive(:shakaperf_runtime_tree_fingerprint)
      expect(self).not_to receive(:append_accelerated_rc_tracker_record!)

      result = nil
      expect do
        result = authorize_accelerated_rc_publication!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          release_branch: "release/17.0.0",
          candidate_sha: "f" * 40,
          options: accelerated_rc_options,
          approver: "another-maintainer",
          release_started_at: Time.utc(2026, 7, 14, 14),
          tag: "v17.0.0.rc.10"
        )
      end.to output(/Reusing canonical accelerated RC publication authorization/).to_stdout
      expect(result).to eq(authorization)
      expect(self).to have_received(:accelerated_rc_shakaperf_snapshot!)
      expect(self).to have_received(:fetch_accelerated_rc_ci_snapshot!)
    end

    it "fails closed when persisted authorization refresh returns malformed exact-candidate CI" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        fetch_accelerated_rc_tracker_records!: [authorization],
        local_release_tag_exists?: false,
        fetch_accelerated_rc_ci_snapshot!: {
          status: "pending",
          sha: "f" * 40,
          non_success: nil
        }
      )
      expect(self).not_to receive(:accelerated_rc_shakaperf_snapshot!)

      expect do
        authorize_accelerated_rc_publication!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          release_branch: "release/17.0.0",
          candidate_sha: "f" * 40,
          options: accelerated_rc_options,
          approver: "another-maintainer",
          release_started_at: Time.utc(2026, 7, 14, 14),
          tag: "v17.0.0.rc.10"
        )
      end.to raise_error(SystemExit, /current exact-candidate CI.*malformed/i)
    end

    %w[failed missing stale unknown].each do |outcome|
      it "blocks persisted authorization reuse when current exact-candidate CI is #{outcome}" do
        authorization = build_accelerated_rc_publication_record(
          options: accelerated_rc_options,
          candidate_sha: "f" * 40,
          runtime_tree_fingerprint: "a" * 64,
          release_branch: "release/17.0.0",
          ci_snapshot: accelerated_rc_ci_snapshot,
          shakaperf: accelerated_rc_shakaperf_snapshot,
          approved_by: "justin808",
          recorded_at: Time.utc(2026, 7, 14, 13, 30)
        )
        current_ci = case outcome
                     when "failed"
                       accelerated_rc_ci_snapshot.merge(
                         status: "failed",
                         non_success: [
                           accelerated_rc_ci_snapshot.fetch(:non_success).first.merge(state: "failure")
                         ]
                       )
                     when "missing"
                       accelerated_rc_ci_snapshot.merge(non_success: [])
                     when "stale"
                       accelerated_rc_ci_snapshot.merge(sha: "e" * 40)
                     when "unknown"
                       accelerated_rc_ci_snapshot.merge(
                         status: "success",
                         non_success: [
                           accelerated_rc_ci_snapshot.fetch(:non_success).first.merge(state: "future_state")
                         ]
                       )
                     end
        allow(self).to receive_messages(
          fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
          fetch_accelerated_rc_tracker_records!: [authorization],
          local_release_tag_exists?: false,
          fetch_accelerated_rc_ci_snapshot!: current_ci
        )
        expect(self).not_to receive(:accelerated_rc_shakaperf_snapshot!)

        expect do
          authorize_accelerated_rc_publication!(
            repo_slug: "shakacode/react_on_rails",
            monorepo_root: "/tmp/repo",
            release_branch: "release/17.0.0",
            candidate_sha: "f" * 40,
            options: accelerated_rc_options,
            approver: "another-maintainer",
            release_started_at: Time.utc(2026, 7, 14, 14),
            tag: "v17.0.0.rc.10"
          )
        end.to raise_error(SystemExit, /current exact-candidate CI/i)
      end
    end

    it "blocks persisted authorization reuse when refreshed ShakaPerf has failed" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        fetch_accelerated_rc_tracker_records!: [authorization],
        local_release_tag_exists?: false,
        fetch_accelerated_rc_ci_snapshot!: accelerated_rc_ci_snapshot,
        accelerated_rc_shakaperf_snapshot!: authorization.fetch("shakaperf").merge("status" => "failed")
      )

      expect do
        authorize_accelerated_rc_publication!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          release_branch: "release/17.0.0",
          candidate_sha: "f" * 40,
          options: accelerated_rc_options,
          approver: "another-maintainer",
          release_started_at: Time.utc(2026, 7, 14, 14),
          tag: "v17.0.0.rc.10"
        )
      end.to raise_error(SystemExit, /current ShakaPerf evidence failed/i)
    end

    it "blocks persisted authorization reuse when an active ShakaPerf run has a terminal conclusion" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        fetch_accelerated_rc_tracker_records!: [authorization],
        local_release_tag_exists?: false,
        fetch_accelerated_rc_ci_snapshot!: accelerated_rc_ci_snapshot,
        refresh_shakaperf_release_gate_run!: {
          "databaseId" => 123_456,
          "attempt" => 1,
          "displayTitle" => shakaperf_release_gate_display_title(
            ref: "release/17.0.0", head_sha: "f" * 40, target_version: "17.0.0.rc.10"
          ),
          "headSha" => "f" * 40,
          "status" => "in_progress",
          "conclusion" => "failure",
          "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
        }
      )
      expect(self).not_to receive(:append_accelerated_rc_tracker_record!)

      expect do
        authorize_accelerated_rc_publication!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          release_branch: "release/17.0.0",
          candidate_sha: "f" * 40,
          options: accelerated_rc_options,
          approver: "another-maintainer",
          release_started_at: Time.utc(2026, 7, 14, 14),
          tag: "v17.0.0.rc.10"
        )
      end.to raise_error(SystemExit, /active ShakaPerf run.*terminal conclusion/i)
    end

    it "blocks an untagged retry when a later valid authorization changes CI detail" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      ci = authorization.fetch("ci")
      conflicting_authorization = authorization.merge(
        "ci" => ci.merge(
          "non_success" => [ci.fetch("non_success").first.merge("url" => "https://example.com/other-check")]
        )
      )
      expect(validate_accelerated_rc_tracker_record!(conflicting_authorization)).to eq(conflicting_authorization)
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization, conflicting_authorization],
        local_release_tag_exists?: false
      )

      expect do
        accelerated_rc_authorization_for_same_candidate_retry!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          accelerated_requested: false
        )
      end.to raise_error(SystemExit, /conflicting canonical publication authorizations/i)
    end

    it "blocks a tagged retry whose provenance names another immutable candidate" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        local_release_tag_exists?: true,
        fetch_release_tracker_issue!: {},
        accelerated_rc_tag_provenance_for_tag!: {
          "target_version" => "17.0.0.rc.10",
          "candidate_sha" => "e" * 40,
          "release_tracker" => 3823,
          "authorization_digest" => accelerated_rc_record_digest(authorization)
        }
      )

      expect do
        accelerated_rc_authorization_for_same_candidate_retry!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          accelerated_requested: false
        )
      end.to raise_error(SystemExit, /lacks matching canonical accelerated publication provenance/)
    end

    it "blocks a tagged retry when provenance selects the canonical first of conflicting authorizations" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      conflicting_authorization = authorization.merge("reason" => "Mutated authorization reason")
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization, conflicting_authorization],
        local_release_tag_exists?: true,
        accelerated_rc_tag_provenance_for_tag!: accelerated_rc_tag_provenance(authorization)
      )

      expect do
        accelerated_rc_authorization_for_same_candidate_retry!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          accelerated_requested: false
        )
      end.to raise_error(SystemExit, /conflicting canonical publication authorizations/i)
    end

    it "blocks a retry when accepted terminal records contradict each other" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      publication = accelerated_rc_published_record(
        authorized_record: authorization,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      accepted = publication.merge(
        "status" => "candidate-accepted",
        "ci" => publication.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => publication.fetch("shakaperf").merge("status" => "success"),
        "reason" => "All required evidence passed",
        "required_follow_up" => "Proceed only through the strict final promotion gates.",
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        }
      )
      conflicting_accepted = accepted.merge("approved_by" => "other-maintainer")
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [
          authorization, publication, accepted, conflicting_accepted
        ],
        local_release_tag_exists?: false
      )

      expect do
        accelerated_rc_authorization_for_same_candidate_retry!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          accelerated_requested: false
        )
      end.to raise_error(SystemExit, /conflicting candidate-accepted terminal records/i)
    end

    it "round-trips canonical accelerated provenance through the annotated tag message" do
      record = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )

      provenance = accelerated_rc_tag_provenance_from_message(accelerated_rc_tag_message(record))

      expect(provenance).to include(
        "target_version" => "17.0.0.rc.10",
        "candidate_sha" => "f" * 40,
        "release_tracker" => 3823,
        "authorization_digest" => accelerated_rc_record_digest(record)
      )
    end

    it "creates the annotated tag at the explicitly authorized candidate SHA" do
      record = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      allow(self).to receive(:current_git_sha!).with("/tmp/repo").and_return("f" * 40)
      expect(self).to receive(:sh_args_in_dir_for_release).with(
        "/tmp/repo",
        "git", "tag", "-a", "v17.0.0.rc.10", "f" * 40, "-m", accelerated_rc_tag_message(record)
      )

      create_accelerated_rc_tag!(monorepo_root: "/tmp/repo", tag: "v17.0.0.rc.10", record:)
    end

    it "refuses tag creation when HEAD moved after publication authorization" do
      record = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      allow(self).to receive(:current_git_sha!).with("/tmp/repo").and_return("e" * 40)
      expect(self).not_to receive(:sh_args_in_dir_for_release)

      expect do
        create_accelerated_rc_tag!(monorepo_root: "/tmp/repo", tag: "v17.0.0.rc.10", record:)
      end.to raise_error(SystemExit, /HEAD moved after accelerated RC authorization/)
    end

    it "rejects an existing accelerated tag whose peeled target is not the authorized candidate" do
      record = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      allow(self).to receive_messages(
        accelerated_rc_tag_provenance_for_tag!: accelerated_rc_tag_provenance(record),
        peeled_git_tag_sha: "e" * 40
      )

      expect do
        validate_existing_accelerated_rc_tag!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0.rc.10",
          record:
        )
      end.to raise_error(SystemExit, /does not match the persisted accelerated publication authorization/)
    end

    it "rejects a mutated existing publication-complete record on retry" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      existing = accelerated_rc_published_record(
        authorized_record: authorization,
        recorded_at: Time.utc(2026, 7, 14, 14)
      ).merge("reason" => "Mutated after authorization")
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!).and_return([authorization, existing])
      expect(self).not_to receive(:append_accelerated_rc_tracker_record!)

      expect do
        record_accelerated_rc_publication_complete!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          authorized_record: authorization,
          approved_by: "another-maintainer",
          recorded_at: Time.utc(2026, 7, 14, 15)
        )
      end.to raise_error(SystemExit, /not the canonical authorized transition/)
    end

    it "reuses the canonical publication-complete transition across trusted retry approvers" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      existing = accelerated_rc_published_record(
        authorized_record: authorization,
        approved_by: "first-completing-maintainer",
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!).and_return([authorization, existing])
      expect(self).not_to receive(:append_accelerated_rc_tracker_record!)

      expect(
        record_accelerated_rc_publication_complete!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          authorized_record: authorization,
          approved_by: "retrying-maintainer",
          recorded_at: Time.utc(2026, 7, 14, 15)
        )
      ).to eq(existing)
    end

    it "rejects the complete publication set when a later same-identity record contradicts the canonical first" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      canonical_publication = accelerated_rc_published_record(
        authorized_record: authorization,
        approved_by: "first-completing-maintainer",
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      mutated_publication = canonical_publication.merge(
        "reason" => "Mutated after the canonical publication record"
      )
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!)
        .and_return([authorization, canonical_publication, mutated_publication])
      expect(self).not_to receive(:append_accelerated_rc_tracker_record!)

      expect do
        record_accelerated_rc_publication_complete!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          authorized_record: authorization,
          approved_by: "retrying-maintainer",
          recorded_at: Time.utc(2026, 7, 14, 15)
        )
      end.to raise_error(SystemExit, /publication set.*not the canonical authorized transition/i)
    end

    it "rejects publication completion when a later authorization contradicts the canonical first" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      conflicting_authorization = authorization.merge("required_follow_up" => "Skip canonical publication")
      canonical_publication = accelerated_rc_published_record(
        authorized_record: authorization,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!)
        .and_return([authorization, conflicting_authorization, canonical_publication])
      expect(self).not_to receive(:append_accelerated_rc_tracker_record!)

      expect do
        record_accelerated_rc_publication_complete!(
          repo_slug: "shakacode/react_on_rails",
          tracker: 3823,
          authorized_record: authorization,
          approved_by: "retrying-maintainer",
          recorded_at: Time.utc(2026, 7, 14, 15)
        )
      end.to raise_error(SystemExit, /conflicting canonical publication authorizations/i)
    end

    it "treats every non-metadata publication mutation as contradictory" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      canonical_publication = accelerated_rc_published_record(
        authorized_record: authorization,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      mutations = {
        "reason" => canonical_publication.merge("reason" => "Changed reason"),
        "required follow-up" => canonical_publication.merge("required_follow_up" => "Skip reconciliation"),
        "CI status" => canonical_publication.merge(
          "ci" => canonical_publication.fetch("ci").merge("status" => "failed")
        ),
        "CI checks URL" => canonical_publication.merge(
          "ci" => canonical_publication.fetch("ci").merge("checks_url" => "https://example.com/other-checks")
        ),
        "CI non-success detail" => canonical_publication.merge(
          "ci" => canonical_publication.fetch("ci").merge(
            "non_success" => [{ "name" => "generator", "state" => "failure", "url" => "https://example.com/fail" }]
          )
        ),
        "ShakaPerf status" => canonical_publication.merge(
          "shakaperf" => canonical_publication.fetch("shakaperf").merge("status" => "failed")
        ),
        "ShakaPerf run URL" => canonical_publication.merge(
          "shakaperf" => canonical_publication.fetch("shakaperf").merge("run_url" => "https://example.com/other-run")
        ),
        "evidence" => canonical_publication.merge("evidence" => { "unexpected" => "https://example.com" })
      }

      aggregate_failures do
        mutations.each do |name, mutated_publication|
          expect do
            validated_accelerated_rc_publication_set!(
              [authorization, canonical_publication, mutated_publication], authorization
            )
          end.to raise_error(
            SystemExit,
            /publication set.*not the canonical authorized transition/i
          ), name
        end
      end
    end

    it "treats every distinct valid authorization digest as conflicting" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      ci = authorization.fetch("ci")
      shakaperf = authorization.fetch("shakaperf")
      mutations = {
        "reason" => authorization.merge("reason" => "Changed authorization reason"),
        "required follow-up" => authorization.merge("required_follow_up" => "Changed required follow-up"),
        "CI status" => authorization.merge("ci" => ci.merge("status" => "success", "non_success" => [])),
        "CI checks URL" => authorization.merge(
          "ci" => ci.merge("checks_url" => "https://example.com/other-checks")
        ),
        "CI check detail" => authorization.merge(
          "ci" => ci.merge(
            "non_success" => [ci.fetch("non_success").first.merge("name" => "mutated-generator")]
          )
        ),
        "ShakaPerf status" => authorization.merge("shakaperf" => shakaperf.merge("status" => "success")),
        "ShakaPerf run URL" => authorization.merge(
          "shakaperf" => shakaperf.merge("run_url" => "https://example.com/other-run")
        ),
        "ShakaPerf attempt" => authorization.merge("shakaperf" => shakaperf.merge("attempt" => 2)),
        "ShakaPerf candidate identity" => authorization.merge(
          "shakaperf" => shakaperf.merge("candidate_sha" => "e" * 40)
        ),
        "runtime fingerprint" => authorization.merge("runtime_tree_fingerprint" => "b" * 64),
        "approver metadata" => authorization.merge("approved_by" => "another-maintainer"),
        "recorded-at metadata" => authorization.merge("recorded_at" => "2026-07-14T13:31:00Z")
      }

      aggregate_failures do
        mutations.each do |name, conflicting_authorization|
          expect(validate_accelerated_rc_tracker_record!(conflicting_authorization)).to eq(
            conflicting_authorization
          ), name
          expect do
            validated_accelerated_rc_authorization_set!(
              [authorization, conflicting_authorization], selected_authorization: authorization
            )
          end.to raise_error(SystemExit, /conflicting canonical publication authorizations/i), name
        end
      end
    end

    it "allows exact duplicate authorization copies to remain idempotent" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      duplicate = JSON.parse(JSON.generate(authorization))

      expect(
        validated_accelerated_rc_authorization_set!(
          [authorization, duplicate], selected_authorization: authorization
        )
      ).to eq(authorization)
    end

    it "rejects mutated publication-complete state before an interrupted retry republishes" do
      authorization = build_accelerated_rc_publication_record(
        options: accelerated_rc_options,
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: accelerated_rc_ci_snapshot,
        shakaperf: accelerated_rc_shakaperf_snapshot,
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
      mutated_publication = accelerated_rc_published_record(
        authorized_record: authorization,
        recorded_at: Time.utc(2026, 7, 14, 14)
      ).merge("required_follow_up" => "Skip reconciliation")
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization, mutated_publication],
        local_release_tag_exists?: false
      )

      expect do
        accelerated_rc_authorization_for_same_candidate_retry!(
          repo_slug: "shakacode/react_on_rails",
          target_version: "17.0.0.rc.10",
          candidate_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          accelerated_requested: false
        )
      end.to raise_error(SystemExit, /not the canonical authorized transition/)
    end
  end

  describe "#confirm_accelerated_rc_publication!" do
    it "names the exact candidate, tracker, non-success checks, ShakaPerf run, and reason" do
      allow($stdin).to receive(:gets).and_return("y\n")
      ci = {
        status: "pending",
        sha: "f" * 40,
        checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
        non_success: [
          {
            name: "generator-1",
            state: "in_progress",
            url: "https://github.com/shakacode/react_on_rails/actions/runs/1"
          }
        ]
      }
      shakaperf = {
        status: "pending",
        run_id: 123_456,
        run_url: "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }

      expect do
        confirm_accelerated_rc_publication!(
          version: "17.0.0.rc.10",
          candidate_sha: "f" * 40,
          tracker: 3823,
          reason: "Start fleet QA now",
          ci_snapshot: ci,
          shakaperf:
        )
      end.to output(
        %r{17\.0\.0\.rc\.10.*#{'f' * 40}.*#3823.*generator-1.*actions/runs/1.*actions/runs/123456.*Start fleet QA now}m
      ).to_stdout
    end
  end

  describe "#accelerated_rc_shakaperf_requires_prerun?" do
    it "distinguishes a runtime-equivalent pre-run from an exact-candidate run" do
      exact_record = {
        "candidate_sha" => "f" * 40,
        "shakaperf" => { "candidate_sha" => "f" * 40 }
      }
      prerun_record = {
        "candidate_sha" => "f" * 40,
        "shakaperf" => { "candidate_sha" => "e" * 40 }
      }

      expect(accelerated_rc_shakaperf_requires_prerun?(exact_record)).to be(false)
      expect(accelerated_rc_shakaperf_requires_prerun?(prerun_record)).to be(true)
    end
  end

  describe "#reconcile_accelerated_rc_record" do
    let(:published_record) do
      {
        "schema_version" => 1,
        "status" => "published-awaiting-gates",
        "target_version" => "17.0.0.rc.10",
        "candidate_sha" => "f" * 40,
        "release_tracker" => 3823,
        "runtime_tree_fingerprint" => "a" * 64,
        "release_branch" => "release/17.0.0",
        "ci" => { "status" => "pending" },
        "shakaperf" => { "status" => "pending" },
        "reason" => "Start fleet QA now",
        "approved_by" => "justin808",
        "recorded_at" => "2026-07-14T13:30:00Z",
        "evidence" => {}
      }
    end

    it "records candidate-accepted only after every deferred and downstream gate is evidenced" do
      record = reconcile_accelerated_rc_record(
        published_record:,
        ci_snapshot: { "status" => "success", "checks_url" => "https://github.com/checks" },
        shakaperf: { "status" => "success", "run_url" => "https://github.com/shakaperf" },
        evidence: {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        },
        approved_by: "justin808",
        reason: "All RC gates and published-artifact checks passed",
        recorded_at: "2026-07-14T15:00:00Z"
      )

      expect(record).to include(
        "status" => "candidate-accepted",
        "candidate_sha" => "f" * 40,
        "approved_by" => "justin808",
        "required_follow_up" => /strict final promotion gates/i
      )
      expect(record.fetch("evidence").keys).to contain_exactly("demo_fleet", "behavioral", "artifacts")
    end

    it "records candidate-rejected with do-not-promote guidance after a relevant late failure" do
      record = reconcile_accelerated_rc_record(
        published_record:,
        ci_snapshot: { "status" => "failed", "checks_url" => "https://github.com/checks" },
        shakaperf: { "status" => "success", "run_url" => "https://github.com/shakaperf" },
        evidence: {},
        approved_by: "justin808",
        reason: "Generator validation failed on the published candidate",
        recorded_at: "2026-07-14T15:00:00Z"
      )

      expect(record).to include(
        "status" => "candidate-rejected",
        "candidate_sha" => "f" * 40,
        "required_follow_up" => /Do not promote.*cut the next RC/i
      )
    end

    it "does not accept syntactically incomplete HTTPS evidence URLs" do
      expect do
        reconcile_accelerated_rc_record(
          published_record:,
          ci_snapshot: { "status" => "success", "checks_url" => "https://github.com/checks" },
          shakaperf: { "status" => "success", "run_url" => "https://github.com/shakaperf" },
          evidence: {
            "demo_fleet" => "https://",
            "behavioral" => "https://github.com/behavioral",
            "artifacts" => "https://github.com/artifacts"
          },
          approved_by: "justin808",
          reason: "All RC gates and published-artifact checks passed",
          recorded_at: "2026-07-14T15:00:00Z"
        )
      end.to raise_error(SystemExit, /required gate evidence is incomplete/)
    end
  end

  describe "#accelerated_rc_shakaperf_snapshot!" do
    it "fails closed when the refreshed pending run no longer matches the recorded candidate" do
      record = {
        "candidate_sha" => "f" * 40,
        "release_branch" => "release/17.0.0",
        "shakaperf" => {
          "status" => "pending",
          "run_id" => 123_456,
          "attempt" => 1,
          "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          "candidate_sha" => "f" * 40,
          "target_version" => "17.0.0.rc.10",
          "release_started_at" => "2026-07-14T13:00:00Z"
        }
      }
      allow(self).to receive(:refresh_shakaperf_release_gate_run!).and_return(
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "e" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "e" * 40,
        "status" => "in_progress",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      )

      expect do
        accelerated_rc_shakaperf_snapshot!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          record:
        )
      end.to raise_error(SystemExit, /run identity is unknown or malformed/)
    end

    it "keeps an unknown completed conclusion unresolved instead of rejecting the immutable RC" do
      record = {
        "candidate_sha" => "f" * 40,
        "release_branch" => "release/17.0.0",
        "shakaperf" => {
          "status" => "pending",
          "run_id" => 123_456,
          "attempt" => 1,
          "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          "candidate_sha" => "f" * 40,
          "target_version" => "17.0.0.rc.10",
          "release_started_at" => "2026-07-14T13:00:00Z"
        }
      }
      allow(self).to receive(:refresh_shakaperf_release_gate_run!).and_return(
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "f" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "f" * 40,
        "status" => "completed",
        "conclusion" => "unrecognized",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      )

      expect do
        accelerated_rc_shakaperf_snapshot!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          record:
        )
      end.to raise_error(SystemExit, /reconciliation is unknown.*refusing to accept or reject/i)
    end

    it "fails closed when the refreshed run attempt differs from the authorized attempt" do
      record = {
        "candidate_sha" => "f" * 40,
        "release_branch" => "release/17.0.0",
        "shakaperf" => {
          "status" => "pending",
          "run_id" => 123_456,
          "attempt" => 1,
          "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          "candidate_sha" => "f" * 40,
          "target_version" => "17.0.0.rc.10",
          "release_started_at" => "2026-07-14T13:00:00Z"
        }
      }
      allow(self).to receive(:refresh_shakaperf_release_gate_run!).and_return(
        "databaseId" => 123_456,
        "attempt" => 2,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "f" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "f" * 40,
        "status" => "completed",
        "conclusion" => "success",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      )

      expect do
        accelerated_rc_shakaperf_snapshot!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          record:
        )
      end.to raise_error(SystemExit, /run identity is unknown or malformed/)
    end
  end

  describe "#run_accelerated_rc_reconciliation!" do
    let(:authorization_record) do
      build_accelerated_rc_publication_record(
        options: {
          target_gem_version: "17.0.0.rc.10",
          tracker: 3823,
          reason: "Start fleet QA now"
        },
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: {
          status: "pending",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: [
            {
              name: "generator",
              state: "in_progress",
              url: "https://github.com/shakacode/react_on_rails/actions/runs/123"
            }
          ]
        },
        shakaperf: {
          status: "pending",
          run_id: 123_456,
          attempt: 1,
          run_url: "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          candidate_sha: "f" * 40,
          target_version: "17.0.0.rc.10",
          release_started_at: "2026-07-14T13:00:00Z"
        },
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
    end

    let(:published_record) do
      accelerated_rc_published_record(
        authorized_record: authorization_record,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
    end

    let(:accepted_record) do
      published_record.merge(
        "status" => "candidate-accepted",
        "ci" => published_record.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => published_record.fetch("shakaperf").merge("status" => "success"),
        "reason" => "All required evidence passed",
        "recorded_at" => "2026-07-14T15:00:00Z",
        "required_follow_up" => "Proceed only through the strict final promotion gates.",
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        }
      )
    end

    before do
      allow(self).to receive_messages(
        fetch_release_tracker_issue!: nil,
        current_release_approver!: "justin808",
        fetch_accelerated_rc_tracker_records!: [authorization_record, published_record],
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization_record, published_record]
      )
    end

    it "is idempotent after a terminal tracker record and does not re-query deferred gates" do
      retry_equivalent_accepted = accepted_record.merge("recorded_at" => "2026-07-14T15:01:00Z")
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!)
        .and_return([authorization_record, published_record, accepted_record, retry_equivalent_accepted])
      expect(self).not_to receive(:fetch_accelerated_rc_ci_snapshot!)
      expect(self).not_to receive(:accelerated_rc_shakaperf_snapshot!)
      expect(self).not_to receive(:append_accelerated_rc_tracker_record!)

      expect do
        expect(
          run_accelerated_rc_reconciliation!(
            repo_slug: "shakacode/react_on_rails",
            monorepo_root: "/tmp/repo",
            tracker: 3823,
            target_version: "17.0.0.rc.10",
            reason: "All required evidence passed",
            evidence: {}
          )
        ).to eq(accepted_record)
      end.to output(/already terminal.*candidate-accepted/i).to_stdout
    end

    it "rejects out-of-order candidate histories before reconciliation consumes terminal state" do
      publication_after_terminal = published_record.merge(
        "approved_by" => "retrying-maintainer",
        "recorded_at" => "2026-07-14T15:01:00Z"
      )
      histories = {
        "publication before authorization" => [published_record, authorization_record],
        "acceptance before publication" => [authorization_record, accepted_record, published_record],
        "pending publication after terminal" => [
          authorization_record, published_record, accepted_record, publication_after_terminal
        ]
      }

      aggregate_failures do
        histories.each do |name, records|
          expect do
            accelerated_rc_published_record!(records:, target_version: "17.0.0.rc.10")
          end.to raise_error(SystemExit, /transition order/i), name
        end
      end
    end

    it "rejects non-monotonic candidate transition timestamps" do
      early_publication = published_record.merge("recorded_at" => "2026-07-14T13:00:00Z")

      expect do
        accelerated_rc_published_record!(
          records: [authorization_record, early_publication],
          target_version: "17.0.0.rc.10"
        )
      end.to raise_error(SystemExit, /timestamps.*monotonic/i)
    end

    it "fails closed when reconciliation sees conflicting accepted terminal records" do
      conflicting_accepted = accepted_record.merge("reason" => "Different claimed acceptance basis")
      expect(validate_accelerated_rc_tracker_record!(accepted_record)).to eq(accepted_record)
      expect(validate_accelerated_rc_tracker_record!(conflicting_accepted)).to eq(conflicting_accepted)
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!).and_return(
        [authorization_record, published_record, accepted_record, conflicting_accepted]
      )
      expect(self).not_to receive(:fetch_accelerated_rc_ci_snapshot!)
      expect(self).not_to receive(:accelerated_rc_shakaperf_snapshot!)
      expect(self).not_to receive(:append_accelerated_rc_tracker_record!)

      expect do
        run_accelerated_rc_reconciliation!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          tracker: 3823,
          target_version: "17.0.0.rc.10",
          reason: "All required evidence passed",
          evidence: {}
        )
      end.to raise_error(SystemExit, /conflicting candidate-accepted terminal records/i)
    end

    it "records a known late failure as rejected before stopping promotion" do
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!).and_return(
        status: "failed",
        checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks"
      )
      expect(self).not_to receive(:accelerated_rc_shakaperf_snapshot!)
      expect(self).to receive(:append_accelerated_rc_tracker_record!) do |record:, **|
        expect(record["status"]).to eq("candidate-rejected")
      end

      expect do
        run_accelerated_rc_reconciliation!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          tracker: 3823,
          target_version: "17.0.0.rc.10",
          reason: "Exact-head generator CI failed",
          evidence: {}
        )
      end.to raise_error(SystemExit, /Do not promote.*cut the next RC/i)
    end

    it "cannot append acceptance when concurrent reconciliation has already rejected the candidate" do
      rejected_record = published_record.merge(
        "status" => "candidate-rejected",
        "ci" => published_record.fetch("ci").merge(
          "status" => "failed",
          "non_success" => [
            { "name" => "generator", "state" => "failure", "url" => "https://example.com/failure" }
          ]
        ),
        "reason" => "Concurrent reconciliation found failed CI",
        "recorded_at" => "2026-07-14T14:55:00Z",
        "required_follow_up" => "Do not promote this immutable RC; fix the failure and cut the next RC."
      )
      expect(validate_accelerated_rc_tracker_record!(rejected_record)).to eq(rejected_record)
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!).and_return(
        [authorization_record, published_record],
        [authorization_record, published_record],
        [authorization_record, published_record, rejected_record]
      )
      allow(self).to receive_messages(
        fetch_accelerated_rc_ci_snapshot!: {
          status: "success",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: []
        },
        accelerated_rc_shakaperf_snapshot!: published_record.fetch("shakaperf").merge("status" => "success")
      )
      expect(self).to receive(:post_release_tracker_comment!)

      expect do
        run_accelerated_rc_reconciliation!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          tracker: 3823,
          target_version: "17.0.0.rc.10",
          reason: "All required evidence passed",
          evidence: {
            "demo_fleet" => "https://github.com/demo-fleet",
            "behavioral" => "https://github.com/behavioral",
            "artifacts" => "https://github.com/artifacts"
          }
        )
      end.to raise_error(SystemExit, /permanently rejected.*absorbing/i)
    end

    it "blocks reconciliation when the canonical publication transition is missing" do
      allow(self).to receive(:fetch_accelerated_rc_tracker_records!).and_return([authorization_record])
      expect(self).not_to receive(:fetch_accelerated_rc_ci_snapshot!)
      expect(self).not_to receive(:accelerated_rc_shakaperf_snapshot!)
      expect(self).not_to receive(:append_accelerated_rc_tracker_record!)

      expect do
        run_accelerated_rc_reconciliation!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          tracker: 3823,
          target_version: "17.0.0.rc.10",
          reason: "All required evidence passed",
          evidence: {}
        )
      end.to raise_error(SystemExit, /No published-awaiting-gates record exists/)
    end

    it "blocks reconciliation when a later authorization contradicts the canonical first" do
      conflicting_authorization = authorization_record.merge(
        "shakaperf" => authorization_record.fetch("shakaperf").merge(
          "status" => "success",
          "run_url" => "https://example.com/mutated-run"
        )
      )
      expect(validate_accelerated_rc_tracker_record!(conflicting_authorization)).to eq(conflicting_authorization)
      allow(self).to receive_messages(
        fetch_accelerated_rc_tracker_records!: [
          authorization_record, conflicting_authorization, published_record
        ],
        fetch_accelerated_rc_ci_snapshot!: {
          status: "success",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: []
        },
        accelerated_rc_shakaperf_snapshot!: {
          "status" => "success",
          "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
        },
        append_accelerated_rc_tracker_record!: nil
      )

      expect do
        run_accelerated_rc_reconciliation!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          tracker: 3823,
          target_version: "17.0.0.rc.10",
          reason: "All required evidence passed",
          evidence: {
            "demo_fleet" => "https://github.com/demo-fleet",
            "behavioral" => "https://github.com/behavioral",
            "artifacts" => "https://github.com/artifacts"
          }
        )
      end.to raise_error(SystemExit, /conflicting canonical publication authorizations/i)
    end

    it "rejects a later contradictory publication record before reconciliation accepts the candidate" do
      mutated_publication = published_record.merge("reason" => "Mutated after the canonical publication record")
      allow(self).to receive_messages(
        fetch_accelerated_rc_tracker_records!: [authorization_record, published_record, mutated_publication],
        fetch_accelerated_rc_ci_snapshot!: {
          status: "success",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: []
        },
        accelerated_rc_shakaperf_snapshot!: {
          "status" => "success",
          "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
        },
        append_accelerated_rc_tracker_record!: nil
      )

      expect do
        run_accelerated_rc_reconciliation!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          tracker: 3823,
          target_version: "17.0.0.rc.10",
          reason: "All required evidence passed",
          evidence: {
            "demo_fleet" => "https://github.com/demo-fleet",
            "behavioral" => "https://github.com/behavioral",
            "artifacts" => "https://github.com/artifacts"
          }
        )
      end.to raise_error(SystemExit, /publication set.*not the canonical authorized transition/i)
    end

    it "blocks a repository-wide cross-tracker authorization before terminal reconciliation append" do
      conflicting_authorization = authorization_record.merge("release_tracker" => 3824)
      allow(self).to receive_messages(
        fetch_repository_accelerated_rc_records_for_candidate!: [
          authorization_record, published_record, conflicting_authorization
        ],
        fetch_accelerated_rc_ci_snapshot!: {
          status: "success",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: []
        },
        accelerated_rc_shakaperf_snapshot!: published_record.fetch("shakaperf").merge("status" => "success")
      )
      appended = false
      allow(self).to receive(:append_accelerated_rc_tracker_record!) { appended = true }

      failure = begin
        run_accelerated_rc_reconciliation!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          tracker: 3823,
          target_version: "17.0.0.rc.10",
          reason: "All required evidence passed",
          evidence: {
            "demo_fleet" => "https://github.com/demo-fleet",
            "behavioral" => "https://github.com/behavioral",
            "artifacts" => "https://github.com/artifacts"
          }
        )
        nil
      rescue SystemExit => error
        error
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/repository-wide.*conflicting release trackers/i)
        expect(appended).to be(false)
      end
    end

    it "blocks a repository-wide authorization conflict after terminal append re-fetch and before success" do
      conflicting_authorization = authorization_record.merge("release_tracker" => 3824)
      repository_reads = 0
      allow(self).to receive(:fetch_repository_accelerated_rc_records_for_candidate!) do
        repository_reads += 1
        if repository_reads == 1
          [authorization_record, published_record]
        else
          [authorization_record, published_record, conflicting_authorization]
        end
      end
      allow(self).to receive_messages(
        fetch_accelerated_rc_ci_snapshot!: {
          status: "success",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: []
        },
        accelerated_rc_shakaperf_snapshot!: published_record.fetch("shakaperf").merge("status" => "success")
      )
      append_completed = false
      allow(self).to receive(:append_accelerated_rc_tracker_record!) { append_completed = true }

      failure = begin
        run_accelerated_rc_reconciliation!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          tracker: 3823,
          target_version: "17.0.0.rc.10",
          reason: "All required evidence passed",
          evidence: {
            "demo_fleet" => "https://github.com/demo-fleet",
            "behavioral" => "https://github.com/behavioral",
            "artifacts" => "https://github.com/artifacts"
          }
        )
        nil
      rescue SystemExit => error
        error
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/repository-wide.*conflicting release trackers/i)
        expect(append_completed).to be(true)
        expect(repository_reads).to eq(2)
      end
    end
  end

  describe "#accepted_accelerated_rc_record_for_release_branch_promotion!" do
    it "rejects cross-tracker exact-candidate history during final promotion" do
      authorization, publication, accepted = accelerated_rc_test_accepted_history
      conflicting_authorization = accelerated_rc_test_authorization(tracker: 3824)
      provenance = accelerated_rc_tag_provenance(authorization)
      allow(self).to receive_messages(
        accelerated_rc_tag_provenance_for_tag!: provenance,
        github_repo_slug: "shakacode/react_on_rails",
        fetch_release_tracker_issue!: nil,
        fetch_repository_accelerated_rc_records_for_candidate!: [
          authorization, publication, accepted, conflicting_authorization
        ],
        fetch_accelerated_rc_tracker_records!: [authorization, publication, accepted],
        peeled_git_tag_sha: "f" * 40,
        shakaperf_runtime_tree_fingerprint: "a" * 64
      )

      expect do
        accepted_accelerated_rc_record_for_release_branch_promotion!(
          monorepo_root: "/tmp/repo",
          rc_tag: "v17.0.0.rc.10",
          final_head_sha: "f" * 40,
          tracker_input: "3823"
        )
      end.to raise_error(SystemExit, /repository-wide.*tracker|conflicting release trackers/i)
    end

    it "requires the literal canonical tag name for accelerated provenance" do
      authorization, publication, accepted = accelerated_rc_test_accepted_history
      provenance = accelerated_rc_tag_provenance(authorization)
      allow(self).to receive_messages(
        accelerated_rc_tag_provenance_for_tag!: provenance,
        github_repo_slug: "shakacode/react_on_rails",
        fetch_release_tracker_issue!: nil,
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization, publication, accepted],
        fetch_accelerated_rc_tracker_records!: [authorization, publication, accepted],
        peeled_git_tag_sha: "f" * 40,
        shakaperf_runtime_tree_fingerprint: "a" * 64
      )

      aggregate_failures do
        ["v17.0.0-rc.10", "v17.0.0.RC.10"].each do |alias_tag|
          expect do
            accepted_accelerated_rc_record_for_release_branch_promotion!(
              monorepo_root: "/tmp/repo",
              rc_tag: alias_tag,
              final_head_sha: "f" * 40,
              tracker_input: "3823"
            )
          end.to raise_error(SystemExit, /literal canonical accelerated RC tag.*v17\.0\.0\.rc\.10/i), alias_tag
        end

        expect(
          accepted_accelerated_rc_record_for_release_branch_promotion!(
            monorepo_root: "/tmp/repo",
            rc_tag: "v17.0.0.rc.10",
            final_head_sha: "f" * 40,
            tracker_input: "3823"
          )
        ).to eq(accepted)
      end
    end

    it "does not require a tracker for an ordinary lightweight RC tag" do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "cat-file", "-t", "refs/tags/v17.0.0.rc.10")
        .and_return(["commit\n", status])
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:peeled_git_tag_sha)
        .with(monorepo_root: "/tmp/repo", tag: "v17.0.0.rc.10").and_return("f" * 40)
      allow(self).to receive(:fetch_repository_accelerated_rc_records_for_candidate!).with(
        repo_slug: "shakacode/react_on_rails",
        target_version: "17.0.0.rc.10",
        candidate_sha: "f" * 40
      ).and_return([])
      expect(self).not_to receive(:fetch_release_tracker_issue!)
      expect(self).not_to receive(:fetch_accelerated_rc_tracker_records!)

      result = accepted_accelerated_rc_record_for_release_branch_promotion!(
        monorepo_root: "/tmp/repo",
        rc_tag: "v17.0.0.rc.10",
        final_head_sha: "f" * 40,
        tracker_input: nil
      )

      expect(result).to be_nil
      expect(self).to have_received(:fetch_repository_accelerated_rc_records_for_candidate!).with(
        repo_slug: "shakacode/react_on_rails",
        target_version: "17.0.0.rc.10",
        candidate_sha: "f" * 40
      )
    end

    it "blocks a lightweight RC tag when durable accelerated history exists for the exact candidate" do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "cat-file", "-t", "refs/tags/v17.0.0.rc.10")
        .and_return(["commit\n", status])
      allow(self).to receive(:github_repo_slug).with("/tmp/repo").and_return("shakacode/react_on_rails")
      allow(self).to receive(:peeled_git_tag_sha)
        .with(monorepo_root: "/tmp/repo", tag: "v17.0.0.rc.10").and_return("f" * 40)
      allow(self).to receive(:fetch_repository_accelerated_rc_records_for_candidate!).with(
        repo_slug: "shakacode/react_on_rails",
        target_version: "17.0.0.rc.10",
        candidate_sha: "f" * 40
      ).and_return(
        [{ "status" => "publication-authorized", "release_tracker" => 3823 }]
      )
      expect(self).not_to receive(:fetch_release_tracker_issue!)
      expect(self).not_to receive(:fetch_accelerated_rc_tracker_records!)

      expect do
        accepted_accelerated_rc_record_for_release_branch_promotion!(
          monorepo_root: "/tmp/repo",
          rc_tag: "v17.0.0.rc.10",
          final_head_sha: "f" * 40,
          tracker_input: nil
        )
      end.to raise_error(SystemExit, /lightweight RC tag.*durable accelerated history/i)
    end

    it "blocks a markerless annotated RC tag even when no tracker is supplied" do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "cat-file", "-t", "refs/tags/v17.0.0.rc.10")
        .and_return(["tag\n", status])
      allow(Open3).to receive(:capture2e)
        .with(
          "git", "-C", "/tmp/repo", "for-each-ref", "--format=%(contents)", "refs/tags/v17.0.0.rc.10"
        ).and_return(["Ordinary-looking annotation without canonical provenance\n", status])
      expect(self).not_to receive(:github_repo_slug)

      expect do
        accepted_accelerated_rc_record_for_release_branch_promotion!(
          monorepo_root: "/tmp/repo",
          rc_tag: "v17.0.0.rc.10",
          final_head_sha: "f" * 40,
          tracker_input: nil
        )
      end.to raise_error(SystemExit, /annotated RC tag.*lacks canonical accelerated provenance/i)
    end

    it "blocks a markerless annotated RC tag when an explicit tracker is supplied" do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "cat-file", "-t", "refs/tags/v17.0.0.rc.10")
        .and_return(["tag\n", status])
      allow(Open3).to receive(:capture2e)
        .with(
          "git", "-C", "/tmp/repo", "for-each-ref", "--format=%(contents)", "refs/tags/v17.0.0.rc.10"
        ).and_return(["Ordinary-looking annotation without canonical provenance\n", status])
      expect(self).not_to receive(:github_repo_slug)
      expect(self).not_to receive(:fetch_release_tracker_issue!)
      expect(self).not_to receive(:fetch_accelerated_rc_tracker_records!)

      expect do
        accepted_accelerated_rc_record_for_release_branch_promotion!(
          monorepo_root: "/tmp/repo",
          rc_tag: "v17.0.0.rc.10",
          final_head_sha: "f" * 40,
          tracker_input: "3823"
        )
      end.to raise_error(SystemExit, /annotated RC tag.*lacks canonical accelerated provenance/i)
    end

    it "blocks when the RC tag object type cannot be determined" do
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "cat-file", "-t", "refs/tags/v17.0.0.rc.10")
        .and_return(["fatal: object unavailable\n", status])
      expect(self).not_to receive(:github_repo_slug)

      expect do
        accepted_accelerated_rc_record_for_release_branch_promotion!(
          monorepo_root: "/tmp/repo",
          rc_tag: "v17.0.0.rc.10",
          final_head_sha: "f" * 40,
          tracker_input: nil
        )
      end.to raise_error(SystemExit, /Unable to inspect RC tag provenance.*object unavailable/i)
    end

    it "requires the tracker encoded by an accelerated RC tag" do
      allow(self).to receive(:accelerated_rc_tag_provenance_for_tag!).and_return(
        "target_version" => "17.0.0.rc.10",
        "release_tracker" => 3823
      )
      expect(self).not_to receive(:github_repo_slug)

      expect do
        accepted_accelerated_rc_record_for_release_branch_promotion!(
          monorepo_root: "/tmp/repo",
          rc_tag: "v17.0.0.rc.10",
          final_head_sha: "f" * 40,
          tracker_input: "3824"
        )
      end.to raise_error(SystemExit, /RELEASE_TRACKER must match the canonical tracker/)
    end
  end

  describe "#accepted_accelerated_rc_record_for_promotion!" do
    let(:authorization_record) do
      build_accelerated_rc_publication_record(
        options: {
          target_gem_version: "17.0.0.rc.10",
          tracker: 3823,
          reason: "Start fleet QA now"
        },
        candidate_sha: "f" * 40,
        runtime_tree_fingerprint: "a" * 64,
        release_branch: "release/17.0.0",
        ci_snapshot: {
          status: "pending",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: [
            {
              name: "generator",
              state: "in_progress",
              url: "https://github.com/shakacode/react_on_rails/actions/runs/123"
            }
          ]
        },
        shakaperf: {
          status: "pending",
          run_id: 123_456,
          attempt: 1,
          run_url: "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          candidate_sha: "f" * 40,
          target_version: "17.0.0.rc.10",
          release_started_at: "2026-07-14T13:00:00Z"
        },
        approved_by: "justin808",
        recorded_at: Time.utc(2026, 7, 14, 13, 30)
      )
    end

    let(:tag_provenance) do
      {
        "schema_version" => 1,
        "target_version" => "17.0.0.rc.10",
        "candidate_sha" => "f" * 40,
        "release_tracker" => 3823,
        "authorization_digest" => accelerated_rc_record_digest(authorization_record)
      }
    end

    let(:canonical_publication) do
      accelerated_rc_published_record(
        authorized_record: authorization_record,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
    end

    it "blocks final promotion while accelerated RC evidence is unresolved" do
      expect(self).not_to receive(:shakaperf_runtime_tree_fingerprint)

      %w[publication-authorized published-awaiting-gates].each do |status|
        pending_record = if status == "publication-authorized"
                           authorization_record
                         else
                           accelerated_rc_published_record(
                             authorized_record: authorization_record,
                             recorded_at: Time.utc(2026, 7, 14, 14)
                           )
                         end
        records = status == "publication-authorized" ? [authorization_record] : [authorization_record, pending_record]
        expected_error = if status == "publication-authorized"
                           /canonical published-awaiting-gates transition is missing/i
                         else
                           /pending, rejected, or unreconciled evidence/
                         end

        expect do
          accepted_accelerated_rc_record_for_promotion!(
            records:,
            rc_version: "17.0.0.rc.10",
            rc_sha: "f" * 40,
            final_head_sha: "f" * 40,
            monorepo_root: "/tmp/repo",
            tag_provenance:
          )
        end.to raise_error(SystemExit, expected_error)
      end
    end

    it "blocks when canonical tag provenance has no matching authorization record" do
      expect do
        accepted_accelerated_rc_record_for_promotion!(
          records: [],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance:
        )
      end.to raise_error(SystemExit, /canonical accelerated RC publication authorization is missing/)
    end

    it "blocks tracker records whose RC tag lacks canonical accelerated provenance" do
      expect do
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization_record],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance: nil
        )
      end.to raise_error(SystemExit, /RC tag lacks canonical accelerated-publication provenance/)
    end

    it "treats candidate-rejected as absorbing even if a later accepted record exists" do
      rejected = authorization_record.merge("status" => "candidate-rejected")
      accepted = rejected.merge("status" => "candidate-accepted")

      expect do
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization_record, canonical_publication, rejected, accepted],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance:
        )
      end.to raise_error(SystemExit, /permanently rejected/)
    end

    it "fails closed when final promotion sees conflicting accepted terminal records" do
      accepted = authorization_record.merge(
        "status" => "candidate-accepted",
        "ci" => authorization_record.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => authorization_record.fetch("shakaperf").merge("status" => "success"),
        "reason" => "All required evidence passed",
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        }
      )
      conflicting_accepted = accepted.merge("approved_by" => "other-maintainer")
      expect(validate_accelerated_rc_tracker_record!(accepted)).to eq(accepted)
      expect(validate_accelerated_rc_tracker_record!(conflicting_accepted)).to eq(conflicting_accepted)
      expect(self).not_to receive(:shakaperf_runtime_tree_fingerprint)

      expect do
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization_record, canonical_publication, accepted, conflicting_accepted],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance:
        )
      end.to raise_error(SystemExit, /conflicting candidate-accepted terminal records/i)
    end

    it "blocks terminal tracker state that mutates authorization-bound evidence" do
      accepted = authorization_record.merge(
        "status" => "candidate-accepted",
        "release_branch" => "release/tampered"
      )

      expect do
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization_record, canonical_publication, accepted],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance:
        )
      end.to raise_error(SystemExit, /tracker state is not bound to the canonical publication authorization/)
    end

    it "blocks final promotion when the canonical publication transition is missing" do
      accepted = authorization_record.merge(
        "status" => "candidate-accepted",
        "ci" => authorization_record.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => authorization_record.fetch("shakaperf").merge("status" => "success"),
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        }
      )
      expect(self).not_to receive(:shakaperf_runtime_tree_fingerprint)

      expect do
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization_record, accepted],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance:
        )
      end.to raise_error(SystemExit, /canonical published-awaiting-gates transition is missing/i)
    end

    it "blocks final promotion when tag provenance selects the canonical first of conflicting authorizations" do
      conflicting_authorization = authorization_record.merge("reason" => "Mutated authorization reason")
      expect(validate_accelerated_rc_tracker_record!(conflicting_authorization)).to eq(conflicting_authorization)
      accepted = authorization_record.merge(
        "status" => "candidate-accepted",
        "ci" => authorization_record.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => authorization_record.fetch("shakaperf").merge("status" => "success"),
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        }
      )
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root: "/tmp/repo", sha: "f" * 40).and_return("a" * 64)

      expect do
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization_record, conflicting_authorization, canonical_publication, accepted],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance:
        )
      end.to raise_error(SystemExit, /conflicting canonical publication authorizations/i)
    end

    it "blocks final promotion when a later publication record contradicts the canonical first" do
      canonical_publication = accelerated_rc_published_record(
        authorized_record: authorization_record,
        recorded_at: Time.utc(2026, 7, 14, 14)
      )
      mutated_publication = canonical_publication.merge(
        "ci" => canonical_publication.fetch("ci").merge(
          "status" => "failed",
          "non_success" => [{ "name" => "generator", "state" => "failure", "url" => "https://example.com/fail" }]
        )
      )
      accepted = authorization_record.merge(
        "status" => "candidate-accepted",
        "ci" => authorization_record.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => authorization_record.fetch("shakaperf").merge("status" => "success"),
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        }
      )
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root: "/tmp/repo", sha: "f" * 40).and_return("a" * 64)

      expect do
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization_record, canonical_publication, mutated_publication, accepted],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance:
        )
      end.to raise_error(SystemExit, /publication set.*not the canonical authorized transition/i)
    end

    it "reuses accepted evidence bound to the exact RC candidate SHA" do
      record = authorization_record.merge(
        "status" => "candidate-accepted",
        "recorded_at" => "2026-07-14T15:00:00Z",
        "ci" => authorization_record.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => authorization_record.fetch("shakaperf").merge("status" => "success"),
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        }
      )
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root: "/tmp/repo", sha: "f" * 40).and_return("a" * 64)

      expect(
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization_record, canonical_publication, record],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "f" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance:
        )
      ).to eq(record)
    end

    it "reuses accepted evidence for a mechanically runtime-equivalent final tip" do
      record = authorization_record.merge(
        "status" => "candidate-accepted",
        "recorded_at" => "2026-07-14T15:00:00Z",
        "ci" => authorization_record.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => authorization_record.fetch("shakaperf").merge("status" => "success"),
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        }
      )
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root: "/tmp/repo", sha: "f" * 40).and_return("a" * 64)
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root: "/tmp/repo", sha: "e" * 40).and_return("a" * 64)
      allow(self).to receive(:release_branch_commits_after_rc_tag).with(
        monorepo_root: "/tmp/repo",
        tag_sha: "f" * 40,
        head_sha: "e" * 40
      ).and_return(status: :non_runtime_only, commits: ["metadata-only-sha"])

      expect(
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization_record, canonical_publication, record],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "e" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance:
        )
      ).to eq(record)
    end

    it "blocks accepted evidence when the final tip changes the runtime tree" do
      record = authorization_record.merge(
        "status" => "candidate-accepted",
        "recorded_at" => "2026-07-14T15:00:00Z",
        "ci" => authorization_record.fetch("ci").merge("status" => "success", "non_success" => []),
        "shakaperf" => authorization_record.fetch("shakaperf").merge("status" => "success"),
        "evidence" => {
          "demo_fleet" => "https://github.com/demo-fleet",
          "behavioral" => "https://github.com/behavioral",
          "artifacts" => "https://github.com/artifacts"
        }
      )
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root: "/tmp/repo", sha: "f" * 40).and_return("a" * 64)
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint)
        .with(monorepo_root: "/tmp/repo", sha: "e" * 40).and_return("b" * 64)

      expect do
        accepted_accelerated_rc_record_for_promotion!(
          records: [authorization_record, canonical_publication, record],
          rc_version: "17.0.0.rc.10",
          rc_sha: "f" * 40,
          final_head_sha: "e" * 40,
          monorepo_root: "/tmp/repo",
          tag_provenance:
        )
      end.to raise_error(SystemExit, /not runtime-equivalent/)
    end
  end

  describe "#refresh_accepted_rc_ci_evidence_for_promotion!" do
    let(:record) { { "candidate_sha" => "f" * 40 } }

    it "requires a fresh successful exact-candidate CI snapshot before final promotion" do
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!).and_return(
        status: "success",
        sha: "f" * 40,
        checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
        non_success: []
      )

      expect(
        refresh_accepted_rc_ci_evidence_for_promotion!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          ci_branch: "release/17.0.0",
          record:
        )
      ).to include(status: "success", sha: "f" * 40)
    end

    it "blocks when the refreshed exact-candidate CI is still pending" do
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!).and_return(
        status: "pending",
        sha: "f" * 40,
        checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
        non_success: []
      )

      expect do
        refresh_accepted_rc_ci_evidence_for_promotion!(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          ci_branch: "release/17.0.0",
          record:
        )
      end.to raise_error(SystemExit, /refreshed exact-RC CI is failed, pending/)
    end
  end

  describe "#validate_final_promotion_ci_publication_boundary!" do
    let(:candidate_sha) { "f" * 40 }
    let(:record) { { "candidate_sha" => candidate_sha } }
    let(:promotion_branch) { "release/17.0.0" }
    let(:checks) do
      [
        {
          name: "generator",
          state: "skipped",
          url: "https://github.com/shakacode/react_on_rails/actions/runs/123"
        },
        {
          name: "docs",
          state: "neutral",
          url: "https://github.com/shakacode/react_on_rails/actions/runs/124"
        }
      ]
    end
    let(:expected_snapshot) do
      {
        status: "success",
        sha: candidate_sha,
        checks_url: "https://github.com/shakacode/react_on_rails/commit/#{candidate_sha}/checks",
        non_success: checks
      }
    end
    let(:context) do
      {
        record:,
        ci_branch: promotion_branch,
        ci_snapshot: json_compatible_release_value(expected_snapshot)
      }
    end

    before do
      allow(self).to receive(:github_repo_slug).and_return("shakacode/react_on_rails")
    end

    it "accepts the same logical non-success checks in a different order" do
      refreshed_snapshot = expected_snapshot.merge(non_success: checks.reverse)
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!).and_return(refreshed_snapshot)

      expect(
        validate_final_promotion_ci_publication_boundary!(
          monorepo_root: "/tmp/repo", context:, phase: "package publication"
        )
      ).to eq(refreshed_snapshot)
    end

    it "blocks a real non-success check identity change" do
      changed_checks = checks.map(&:dup)
      changed_checks.first[:url] = "https://github.com/shakacode/react_on_rails/actions/runs/999"
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!).and_return(
        expected_snapshot.merge(non_success: changed_checks)
      )

      expect do
        validate_final_promotion_ci_publication_boundary!(
          monorepo_root: "/tmp/repo", context:, phase: "package publication"
        )
      end.to raise_error(SystemExit, /materially changed exact-candidate CI evidence/)
    end
  end

  describe "#run_accepted_rc_final_promotion_gates!" do
    let(:accepted_record) do
      {
        "target_version" => "17.0.0.rc.10",
        "candidate_sha" => "f" * 40,
        "release_tracker" => 3823,
        "runtime_tree_fingerprint" => "a" * 64,
        "release_branch" => "release/17.0.0",
        "shakaperf" => {
          "status" => "success",
          "run_id" => 123_456,
          "attempt" => 1,
          "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          "candidate_sha" => "f" * 40,
          "target_version" => "17.0.0.rc.10",
          "release_started_at" => "2026-07-14T13:00:00Z"
        }
      }
    end

    let(:gate_arguments) do
      {
        repo_slug: "shakacode/react_on_rails",
        monorepo_root: "/tmp/repo",
        current_branch: "release/17.0.0",
        rc_tag: "v17.0.0.rc.10",
        tracker_input: "3823",
        final_head_sha: "e" * 40,
        record: accepted_record,
        target_version: "17.0.0",
        release_started_at: Time.utc(2026, 7, 14, 14),
        allow_ci_override: false,
        dry_run: false
      }
    end

    let(:successful_final_ci_snapshot) do
      {
        status: "success",
        sha: "f" * 40,
        checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
        non_success: []
      }
    end

    let(:strict_final_shakaperf_run) do
      {
        "databaseId" => 654_321,
        "attempt" => 1,
        "headSha" => "e" * 40,
        "status" => "completed",
        "conclusion" => "success",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/654321"
      }
    end

    let(:strict_final_shakaperf_snapshot) do
      {
        status: "success",
        run_id: 654_321,
        attempt: 1,
        run_url: strict_final_shakaperf_run.fetch("url"),
        candidate_sha: "e" * 40,
        target_version: "17.0.0",
        release_started_at: "2026-07-14T14:00:00Z"
      }
    end

    let(:source_rc_tag_provenance) do
      {
        "schema_version" => ACCELERATED_RC_RECORD_SCHEMA_VERSION,
        "target_version" => "17.0.0.rc.10",
        "candidate_sha" => "f" * 40,
        "release_tracker" => 3823,
        "authorization_digest" => "b" * 64
      }
    end

    before do
      allow(self).to receive_messages(
        remote_git_tag_exists?: true,
        fetch_remote_rc_tag!: nil,
        current_git_sha!: "e" * 40,
        github_repo_slug: "shakacode/react_on_rails",
        accelerated_shakaperf_snapshot: strict_final_shakaperf_snapshot,
        accelerated_rc_tag_provenance_for_tag!: source_rc_tag_provenance
      )
    end

    it "rejects a successful reusable pre-run that is not bound to the strict final candidate" do
      reusable_prerun = strict_final_shakaperf_run.merge("headSha" => "f" * 40)
      allow(self).to receive(:run_shakaperf_release_gate!).and_return(reusable_prerun)
      expect(self).not_to receive(:accelerated_shakaperf_snapshot)

      expect do
        strict_final_promotion_shakaperf_snapshot!(
          monorepo_root: "/tmp/repo",
          current_branch: "release/17.0.0",
          final_head_sha: "e" * 40,
          target_version: "17.0.0",
          release_started_at: Time.utc(2026, 7, 14, 14),
          allow_ci_override: false,
          dry_run: false
        )
      end.to raise_error(SystemExit, /strict ShakaPerf.*exact final candidate/i)
    end

    it "rejects accepted-RC identity presented as newly run strict-final evidence" do
      _authorization, _publication, accepted = accelerated_rc_test_accepted_history
      successful_ci = {
        status: "success",
        sha: accepted.fetch("candidate_sha"),
        checks_url: accepted.dig("ci", "checks_url"),
        non_success: []
      }
      stable_target_snapshot = accepted.fetch("shakaperf").merge("target_version" => "17.0.0")
      context = accelerated_final_promotion_test_context(record: accepted, ci_snapshot: successful_ci)
      context[:shakaperf_evidence_mode] = FINAL_PROMOTION_SHAKAPERF_STRICT_FINAL_MODE
      context[:final_target_version] = "17.0.0"
      context[:shakaperf_record] = {
        "release_branch" => "release/17.0.0",
        "candidate_sha" => accepted.fetch("candidate_sha"),
        "target_version" => "17.0.0",
        "shakaperf" => stable_target_snapshot
      }

      expect do
        validate_final_promotion_context!(
          boundary_record: accepted, context:, candidate_sha: "e" * 40
        )
      end.to raise_error(SystemExit, /inconsistent accelerated final-promotion boundary evidence/i)
    end

    it "aborts post-bump runtime drift instead of falling back to a fresh ShakaPerf gate" do
      allow(self).to receive(:accelerated_rc_runtime_equivalent?).and_return(false)
      expect(self).not_to receive(:refresh_accepted_rc_ci_evidence_for_promotion!)
      expect(self).not_to receive(:reuse_accepted_rc_shakaperf_evidence!)
      expect(self).not_to receive(:run_shakaperf_release_gate!)
      expect(self).not_to receive(:accepted_accelerated_rc_record_for_release_branch_promotion!)

      expect do
        run_accepted_rc_final_promotion_gates!(**gate_arguments)
      end.to raise_error(SystemExit, /post-bump.*runtime.*new accepted RC/i)
    end

    it "reuses accepted evidence only after content-validating version-only finalization commits" do
      allow(self).to receive(:shakaperf_runtime_tree_fingerprint).and_return("a" * 64)
      allow(self).to receive(:release_branch_commits_after_rc_tag).with(
        monorepo_root: "/tmp/repo",
        tag_sha: "f" * 40,
        head_sha: "e" * 40
      ).and_return(status: :non_runtime_only, commits: ["version-only-sha"])
      allow(self).to receive_messages(
        refresh_accepted_rc_ci_evidence_for_promotion!: successful_final_ci_snapshot,
        reuse_accepted_rc_shakaperf_evidence!: true,
        accepted_accelerated_rc_record_for_release_branch_promotion!: accepted_record
      )

      expect(run_accepted_rc_final_promotion_gates!(**gate_arguments)).to include(candidate_sha: "e" * 40)
    end

    it "blocks dependency and lockfile drift even when the coarse runtime fingerprints still match" do
      allow(self).to receive_messages(
        shakaperf_runtime_tree_fingerprint: "a" * 64,
        refresh_accepted_rc_ci_evidence_for_promotion!: nil,
        reuse_accepted_rc_shakaperf_evidence!: true,
        accepted_accelerated_rc_record_for_release_branch_promotion!: accepted_record
      )

      aggregate_failures do
        {
          "package.json dependency drift" => "package-dependency-sha",
          "Gemfile.lock dependency drift" => "lockfile-dependency-sha"
        }.each do |description, sha|
          allow(self).to receive(:release_branch_commits_after_rc_tag).and_return(
            status: :runtime_bearing,
            commits: [sha]
          )

          expect do
            run_accepted_rc_final_promotion_gates!(**gate_arguments)
          end.to raise_error(SystemExit, /post-bump.*runtime.*new accepted RC/i), description
        end
      end
    end

    it "re-fetches tracker state after the final gate and blocks a newly appended rejection" do
      allow(self).to receive(:accelerated_rc_runtime_equivalent?).and_return(true)
      expect(self).to receive(:refresh_accepted_rc_ci_evidence_for_promotion!).ordered
                                                                              .and_return(successful_final_ci_snapshot)
      expect(self).to receive(:reuse_accepted_rc_shakaperf_evidence!).ordered.and_return(false)
      expect(self).to receive(:run_shakaperf_release_gate!).ordered.and_return(strict_final_shakaperf_run)
      expect(self).to receive(:accepted_accelerated_rc_record_for_release_branch_promotion!).ordered.and_raise(
        SystemExit, "Final promotion is blocked: RC was permanently rejected"
      )

      expect do
        run_accepted_rc_final_promotion_gates!(**gate_arguments)
      end.to raise_error(SystemExit, /permanently rejected/)
    end

    it "blocks when the live remote RC tag is deleted at the irreversible boundary" do
      allow(self).to receive_messages(
        accelerated_rc_runtime_equivalent?: true,
        refresh_accepted_rc_ci_evidence_for_promotion!: nil,
        reuse_accepted_rc_shakaperf_evidence!: true,
        remote_git_tag_exists?: false
      )
      expect(self).not_to receive(:fetch_remote_rc_tag!)
      expect(self).not_to receive(:accepted_accelerated_rc_record_for_release_branch_promotion!)

      expect do
        run_accepted_rc_final_promotion_gates!(**gate_arguments)
      end.to raise_error(SystemExit, /live remote RC tag.*publication boundary/i)
    end

    it "force-fetches the live remote RC tag before rejecting a moved tag" do
      allow(self).to receive_messages(
        accelerated_rc_runtime_equivalent?: true,
        refresh_accepted_rc_ci_evidence_for_promotion!: nil,
        reuse_accepted_rc_shakaperf_evidence!: true
      )
      expect(self).to receive(:fetch_remote_rc_tag!).ordered
      expect(self).to receive(:accepted_accelerated_rc_record_for_release_branch_promotion!).ordered.and_raise(
        SystemExit, "RC tag provenance does not match the selected RC SHA"
      )

      expect do
        run_accepted_rc_final_promotion_gates!(**gate_arguments)
      end.to raise_error(SystemExit, /RC tag provenance.*RC SHA/)
    end

    it "refreshes exact accepted-RC CI again at the irreversible boundary" do
      boundary_record = accepted_record.merge("recorded_at" => "2026-07-14T14:30:00Z")
      allow(self).to receive(:accelerated_rc_runtime_equivalent?).and_return(true)
      expect(self).to receive(:refresh_accepted_rc_ci_evidence_for_promotion!).ordered.with(
        hash_including(record: accepted_record)
      ).and_return(successful_final_ci_snapshot)
      expect(self).to receive(:reuse_accepted_rc_shakaperf_evidence!).ordered.and_return(false)
      expect(self).to receive(:run_shakaperf_release_gate!).ordered.and_return(strict_final_shakaperf_run)
      expect(self).to receive(:accepted_accelerated_rc_record_for_release_branch_promotion!).ordered.and_return(
        boundary_record
      )
      expect(self).to receive(:refresh_accepted_rc_ci_evidence_for_promotion!).ordered.with(
        hash_including(record: boundary_record)
      ).and_raise(SystemExit, "refreshed exact-RC CI is pending")

      expect do
        run_accepted_rc_final_promotion_gates!(**gate_arguments)
      end.to raise_error(SystemExit, /exact-RC CI is pending/)
    end

    it "blocks a valid but mutated accepted record at the irreversible boundary" do
      mutations = {
        "reason" => accepted_record.merge("reason" => "Changed acceptance basis"),
        "approver" => accepted_record.merge("approved_by" => "another-maintainer"),
        "evidence" => accepted_record.merge("evidence" => { "demo_fleet" => "https://example.com/changed" })
      }
      allow(self).to receive_messages(
        accelerated_rc_runtime_equivalent?: true,
        refresh_accepted_rc_ci_evidence_for_promotion!: nil,
        reuse_accepted_rc_shakaperf_evidence!: true
      )

      aggregate_failures do
        mutations.each do |name, boundary_record|
          allow(self).to receive(:accepted_accelerated_rc_record_for_release_branch_promotion!)
            .and_return(boundary_record)

          expect do
            run_accepted_rc_final_promotion_gates!(**gate_arguments)
          end.to raise_error(SystemExit, /accepted RC record.*changed.*boundary/i), name
        end
      end
    end

    it "blocks when local HEAD moves after the boundary evidence refresh" do
      allow(self).to receive_messages(
        accelerated_rc_runtime_equivalent?: true,
        refresh_accepted_rc_ci_evidence_for_promotion!: successful_final_ci_snapshot,
        reuse_accepted_rc_shakaperf_evidence!: true,
        accepted_accelerated_rc_record_for_release_branch_promotion!: accepted_record,
        current_git_sha!: "d" * 40
      )

      expect do
        run_accepted_rc_final_promotion_gates!(**gate_arguments)
      end.to raise_error(SystemExit, /local HEAD moved.*publication boundary/i)
    end

    it "returns the validated final candidate SHA for tag and publication handling" do
      allow(self).to receive_messages(
        accelerated_rc_runtime_equivalent?: true,
        refresh_accepted_rc_ci_evidence_for_promotion!: {
          status: "success",
          sha: "f" * 40,
          checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
          non_success: []
        },
        reuse_accepted_rc_shakaperf_evidence!: true,
        accepted_accelerated_rc_record_for_release_branch_promotion!: accepted_record
      )

      context = run_accepted_rc_final_promotion_gates!(**gate_arguments)

      expect(context).to include(
        candidate_sha: "e" * 40,
        final_target_version: "17.0.0",
        record: accepted_record,
        shakaperf_evidence_mode: FINAL_PROMOTION_SHAKAPERF_ACCEPTED_RC_MODE,
        source_rc_tag: "v17.0.0.rc.10",
        source_rc_candidate_sha: "f" * 40,
        source_rc_tag_provenance:
      )
      expect(context.fetch(:shakaperf_record).fetch("shakaperf")).to eq(accepted_record.fetch("shakaperf"))
    end

    it "keeps reused accepted-RC ShakaPerf evidence bound to the exact RC SHA at publication boundaries" do
      allow(self).to receive_messages(
        accelerated_rc_runtime_equivalent?: true,
        refresh_accepted_rc_ci_evidence_for_promotion!: successful_final_ci_snapshot,
        reuse_accepted_rc_shakaperf_evidence!: true,
        accepted_accelerated_rc_record_for_release_branch_promotion!: accepted_record
      )
      context = run_accepted_rc_final_promotion_gates!(**gate_arguments)
      refreshed_run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "f" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "f" * 40,
        "status" => "completed",
        "conclusion" => "success",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:refresh_shakaperf_release_gate_run!).and_return(refreshed_run)
      allow(self).to receive(:shakaperf_release_gate_run_evidence_rejection) do |require_prerun:, **|
        require_prerun ? "pre-run completed after release started" : nil
      end

      expect do
        validate_final_promotion_shakaperf_publication_boundary!(
          monorepo_root: "/tmp/repo", context:, phase: "package publication"
        )
      end.not_to raise_error
      expect(context.fetch(:shakaperf_record).fetch("candidate_sha")).to eq("f" * 40)
    end

    it "carries exact accepted pre-run evidence through final promotion and every publication boundary" do
      prerun_sha = "d" * 40
      record = accelerated_rc_test_accepted_history.last
      record = record.merge(
        "runtime_tree_fingerprint" => "a" * 64,
        "shakaperf" => record.fetch("shakaperf").merge("candidate_sha" => prerun_sha)
      )
      prerun = {
        "databaseId" => record.dig("shakaperf", "run_id"),
        "attempt" => record.dig("shakaperf", "attempt"),
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: prerun_sha, target_version: "17.0.0.rc.10"
        ),
        "headSha" => prerun_sha,
        "status" => "completed",
        "conclusion" => "success",
        "url" => record.dig("shakaperf", "run_url")
      }
      runtime_checks = []
      live_shakaperf_policies = []
      allow(self).to receive(:accelerated_rc_runtime_equivalent?) do |**arguments|
        runtime_checks << arguments
        true
      end
      allow(self).to receive_messages(
        refresh_accepted_rc_ci_evidence_for_promotion!: successful_final_ci_snapshot,
        refresh_shakaperf_release_gate_run!: prerun,
        accepted_accelerated_rc_record_for_release_branch_promotion!: record
      )
      allow(self).to receive(:shakaperf_release_gate_run_evidence_rejection) do |head_sha:, require_prerun:, **|
        live_shakaperf_policies << [head_sha, require_prerun]
        nil
      end
      expect(self).not_to receive(:run_shakaperf_release_gate!)

      context = run_accepted_rc_final_promotion_gates!(**gate_arguments.merge(record:))

      aggregate_failures do
        expect(context).to include(
          candidate_sha: "e" * 40,
          shakaperf_evidence_mode: FINAL_PROMOTION_SHAKAPERF_ACCEPTED_RC_MODE,
          record:
        )
        expect(context).not_to have_key(:strict_final_shakaperf_identity_anchor)
        expect(context.dig(:shakaperf_record, "shakaperf")).to eq(record.fetch("shakaperf"))
      end

      boundary_phases = Hash.new { |phases, boundary| phases[boundary] = [] }
      allow(self).to receive(:validate_accelerated_repository_publication_boundary!) do |phase:, **|
        boundary_phases[:repository] << phase
      end
      {
        validate_final_promotion_ci_publication_boundary!: :ci,
        validate_final_promotion_shakaperf_publication_boundary!: :shakaperf,
        validate_final_promotion_source_rc_tag_boundary!: :source_rc_tag
      }.each do |validator, boundary|
        allow(self).to receive(validator).and_wrap_original do |method, **arguments|
          boundary_phases[boundary] << arguments.fetch(:phase)
          method.call(**arguments)
        end
      end
      allow(self).to receive(:validate_release_candidate_publication_boundary!)
        .and_wrap_original do |method, **arguments|
        boundary_phases[:candidate] << arguments.fetch(:phase)
        method.call(**arguments)
      end
      allow(self).to receive(:validate_remote_release_tag_candidate_sha!).and_wrap_original do |method, **arguments|
        boundary_phases[:stable_tag] << arguments.fetch(:phase)
        method.call(**arguments)
      end
      allow(self).to receive_messages(
        system: true,
        remote_release_tag_candidate_sha!: "e" * 40
      )
      allow(self).to receive(:peeled_git_tag_sha) do |tag:, **|
        tag == "v17.0.0.rc.10" ? "f" * 40 : "e" * 40
      end
      pushed = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }
      package_continuation_reached = false

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha: "e" * 40,
          accelerated_boundary_record: record,
          accelerated_final_promotion_context: context
        )
        package_continuation_reached = true
      end.not_to raise_error

      expected_accelerated_phases = ["tag handling", "git tag push", "package publication"]
      aggregate_failures do
        expect(runtime_checks.length).to eq(1)
        expect(runtime_checks.first).to include(
          record:, rc_sha: "f" * 40, final_head_sha: "e" * 40, monorepo_root: "/tmp/repo"
        )
        expect(live_shakaperf_policies).to eq(
          [["e" * 40, true]] + Array.new(3) { ["f" * 40, true] }
        )
        expect(boundary_phases.values_at(:repository, :ci, :shakaperf, :source_rc_tag)).to all(
          eq(expected_accelerated_phases)
        )
        expect(boundary_phases[:candidate]).to eq(["git tag push", "package publication"])
        expect(boundary_phases[:stable_tag]).to eq(["package publication"])
        expect(pushed).to be(true)
        expect(package_continuation_reached).to be(true)
      end
    end

    it "rejects a substituted accepted pre-run snapshot that differs from the trusted record" do
      record = accelerated_rc_test_accepted_history.last
      record = record.merge(
        "shakaperf" => record.fetch("shakaperf").merge("candidate_sha" => "d" * 40)
      )
      context = accelerated_final_promotion_test_context(
        record:, ci_snapshot: successful_final_ci_snapshot
      )
      substituted_snapshot = context.dig(:shakaperf_record, "shakaperf").merge(
        "candidate_sha" => "c" * 40
      )
      context[:shakaperf_record] = context.fetch(:shakaperf_record).merge(
        "candidate_sha" => "c" * 40,
        "shakaperf" => substituted_snapshot
      )

      expect do
        validate_final_promotion_context!(
          boundary_record: record, context:, candidate_sha: "e" * 40
        )
      end.to raise_error(SystemExit, /inconsistent accelerated final-promotion boundary evidence/i)
    end

    it "carries the promotion CI branch when accepted evidence originated on another branch" do
      source_record = accepted_record.merge("release_branch" => "release/17.0.0-rc-source")
      allow(self).to receive_messages(
        accelerated_rc_runtime_equivalent?: true,
        refresh_accepted_rc_ci_evidence_for_promotion!: successful_final_ci_snapshot,
        reuse_accepted_rc_shakaperf_evidence!: true,
        accepted_accelerated_rc_record_for_release_branch_promotion!: source_record
      )

      context = run_accepted_rc_final_promotion_gates!(**gate_arguments.merge(record: source_record))

      expect(context).to include(
        candidate_sha: "e" * 40,
        ci_branch: "release/17.0.0",
        record: source_record
      )
      expect(self).to have_received(:refresh_accepted_rc_ci_evidence_for_promotion!).with(
        hash_including(ci_branch: "release/17.0.0")
      ).twice
    end

    it "carries a newly run strict ShakaPerf identity into final publication boundaries" do
      ci_snapshot = {
        status: "success",
        sha: "f" * 40,
        checks_url: "https://github.com/shakacode/react_on_rails/commit/#{'f' * 40}/checks",
        non_success: []
      }
      strict_run = {
        "databaseId" => 654_321,
        "attempt" => 1,
        "headSha" => "e" * 40,
        "status" => "completed",
        "conclusion" => "success",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/654321"
      }
      strict_snapshot = {
        status: "success",
        run_id: 654_321,
        attempt: 1,
        run_url: strict_run.fetch("url"),
        candidate_sha: "e" * 40,
        target_version: "17.0.0",
        release_started_at: "2026-07-14T14:00:00Z"
      }
      allow(self).to receive_messages(
        accelerated_rc_runtime_equivalent?: true,
        github_repo_slug: "shakacode/react_on_rails",
        refresh_accepted_rc_ci_evidence_for_promotion!: ci_snapshot,
        reuse_accepted_rc_shakaperf_evidence!: false,
        run_shakaperf_release_gate!: strict_run,
        accelerated_shakaperf_snapshot: strict_snapshot,
        accepted_accelerated_rc_record_for_release_branch_promotion!: accepted_record
      )

      context = run_accepted_rc_final_promotion_gates!(**gate_arguments)

      aggregate_failures do
        expect(context).to include(
          candidate_sha: "e" * 40,
          final_target_version: "17.0.0",
          record: accepted_record,
          shakaperf_evidence_mode: FINAL_PROMOTION_SHAKAPERF_STRICT_FINAL_MODE
        )
        expect(context.fetch(:ci_snapshot)).to eq(json_compatible_release_value(ci_snapshot))
        expect(context.fetch(:shakaperf_record)).to include(
          "release_branch" => "release/17.0.0",
          "candidate_sha" => "e" * 40,
          "target_version" => "17.0.0",
          "shakaperf" => json_compatible_release_value(strict_snapshot)
        )
        identity_anchor = context.fetch(:strict_final_shakaperf_identity_anchor)
        expect(identity_anchor).to be_frozen
        expect(identity_anchor).to eq(
          final_promotion_shakaperf_identity_anchor(context.fetch(:shakaperf_record))
        )
      end
    end
  end

  describe "#create_release_tag_at_candidate_sha!" do
    it "creates and verifies a release tag against the explicit candidate SHA" do
      allow(self).to receive_messages(
        current_git_sha!: "e" * 40,
        peeled_git_tag_sha: "e" * 40
      )
      expect(self).to receive(:sh_args_in_dir_for_release).with(
        "/tmp/repo", "git", "tag", "v17.0.0", "e" * 40
      )

      expect(
        create_release_tag_at_candidate_sha!(
          monorepo_root: "/tmp/repo", tag: "v17.0.0", candidate_sha: "e" * 40
        )
      ).to eq("e" * 40)
    end

    it "refuses explicit tag creation when local HEAD moved" do
      allow(self).to receive(:current_git_sha!).and_return("d" * 40)
      expect(self).not_to receive(:sh_args_in_dir_for_release)

      expect do
        create_release_tag_at_candidate_sha!(
          monorepo_root: "/tmp/repo", tag: "v17.0.0", candidate_sha: "e" * 40
        )
      end.to raise_error(SystemExit, /local HEAD moved.*tag creation/i)
    end
  end

  describe "#reuse_accepted_rc_shakaperf_evidence!" do
    let(:record) do
      {
        "target_version" => "17.0.0.rc.10",
        "candidate_sha" => "e" * 40,
        "shakaperf" => {
          "run_id" => 123_456,
          "attempt" => 1,
          "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456",
          "release_started_at" => "2026-07-14T13:00:00Z",
          "candidate_sha" => "e" * 40,
          "target_version" => "17.0.0.rc.10"
        }
      }
    end

    it "reuses only refreshed successful evidence bound to the accepted RC and runtime-equivalent final tip" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "e" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "e" * 40,
        "status" => "completed",
        "conclusion" => "success",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:refresh_shakaperf_release_gate_run!).and_return(run)
      allow(self).to receive(:shakaperf_release_gate_run_evidence_rejection)
        .with(
          repo_slug: "shakacode/react_on_rails",
          monorepo_root: "/tmp/repo",
          ref: "release/17.0.0",
          head_sha: "e" * 40,
          target_version: "17.0.0.rc.10",
          run:,
          release_started_at: Time.iso8601("2026-07-14T13:00:00Z"),
          require_prerun: false
        ).and_return(nil)

      expect do
        expect(
          reuse_accepted_rc_shakaperf_evidence!(
            repo_slug: "shakacode/react_on_rails",
            monorepo_root: "/tmp/repo",
            ref: "release/17.0.0",
            head_sha: "e" * 40,
            record:
          )
        ).to be(true)
      end.to output(/Reusing accepted RC ShakaPerf evidence/).to_stdout
    end

    it "declines stale or invalid accepted evidence so final promotion runs the strict gate" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 1,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "e" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "e" * 40,
        "status" => "completed",
        "conclusion" => "success",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive_messages(
        refresh_shakaperf_release_gate_run!: run,
        shakaperf_release_gate_run_evidence_rejection: "evidence is stale"
      )

      expect do
        expect(
          reuse_accepted_rc_shakaperf_evidence!(
            repo_slug: "shakacode/react_on_rails",
            monorepo_root: "/tmp/repo",
            ref: "release/17.0.0",
            head_sha: "e" * 40,
            record:
          )
        ).to be(false)
      end.to output(/not reusable.*evidence is stale/).to_stdout
    end

    it "declines a different run attempt so final promotion dispatches the strict gate" do
      run = {
        "databaseId" => 123_456,
        "attempt" => 2,
        "displayTitle" => shakaperf_release_gate_display_title(
          ref: "release/17.0.0", head_sha: "e" * 40, target_version: "17.0.0.rc.10"
        ),
        "headSha" => "e" * 40,
        "status" => "completed",
        "conclusion" => "success",
        "url" => "https://github.com/shakacode/react_on_rails/actions/runs/123456"
      }
      allow(self).to receive(:refresh_shakaperf_release_gate_run!).and_return(run)
      expect(self).not_to receive(:shakaperf_release_gate_run_evidence_rejection)

      expect do
        expect(
          reuse_accepted_rc_shakaperf_evidence!(
            repo_slug: "shakacode/react_on_rails",
            monorepo_root: "/tmp/repo",
            ref: "release/17.0.0",
            head_sha: "e" * 40,
            record:
          )
        ).to be(false)
      end.to output(/not reusable.*run identity changed/i).to_stdout
    end
  end

  describe "release task help" do
    it "does not advertise strict HEAD retry before the CI gate establishes healthy evidence" do
      rakefile = File.read(File.expand_path("../../../rakelib/release.rake", __dir__))
      help = rakefile.match(/desc\("(.*?)"\)\ntask :release/m)[1]

      expect(help).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
      expect(help).to include("only after it has found complete healthy\n    CI evidence")
      expect(help).to include("Override prerelease CI gates only")
    end

    it "documents the explicit accelerated RC inputs and exposes the reconciliation task" do
      rakefile = File.read(File.expand_path("../../../rakelib/release.rake", __dir__))
      help = rakefile.match(/desc\("(.*?)"\)\ntask :release/m)[1]

      expect(help).to include(
        "RELEASE_ACCELERATED_RC=true",
        "RELEASE_TRACKER=<issue>",
        "RELEASE_ACCELERATED_RC_REASON=<reason>"
      )
      expect(Rake::Task.task_defined?("release:reconcile_accelerated_rc")).to be(true)
    end

    it "orders retry discovery and final evidence refresh before their irreversible boundaries" do
      rakefile = File.read(File.expand_path("../../../rakelib/release.rake", __dir__))
      release_task = rakefile.match(/task :release,.*?(?=\ndesc\("Creates or updates a GitHub release)/m)[0]
      tag_push_helper = rakefile.match(/def push_release_tag_for_candidate!.*?^end$/m)[0]
      tag_retry_index = release_task.index("release_tag_retry_state_for_current_head")
      retry_mode_index = release_task.index("resolve_accelerated_rc_options_for_release!")
      ci_gate_index = release_task.index("validate_main_ci_status!")
      final_refresh_index = release_task.index("run_accepted_rc_final_promotion_gates!")
      tag_push_index = release_task.index("push_release_tag_for_candidate!")
      package_publish_index = release_task.index("Publishing PUBLIC packages to npmjs.org")
      tag_handling_index = tag_push_helper.index('phase: "tag handling"')
      tag_creation_index = tag_push_helper.index("ensure_release_tag_for_candidate!")
      pre_push_boundary_index = tag_push_helper.index('phase: "git tag push"')
      git_push_index = tag_push_helper.index('sh_in_dir_for_release(monorepo_root, "LEFTHOOK=0 git push --tags")')
      package_boundary_index = tag_push_helper.index('phase: "package publication"')

      expect(tag_retry_index).to be < retry_mode_index
      expect(retry_mode_index).to be < ci_gate_index
      expect(final_refresh_index).to be < tag_push_index
      expect(tag_push_index).to be < package_publish_index
      expect(tag_handling_index).to be < tag_creation_index
      expect(tag_creation_index).to be < pre_push_boundary_index
      expect(pre_push_boundary_index).to be < git_push_index
      expect(git_push_index).to be < package_boundary_index
      expect(release_task).to include(
        "final_promotion_context = run_accepted_rc_final_promotion_gates!",
        "validated_release_candidate_sha = final_promotion_context.fetch(:candidate_sha)",
        "candidate_sha: validated_release_candidate_sha",
        "accelerated_boundary_record: accelerated_publication_record || accepted_rc_record",
        "accelerated_final_promotion_context: final_promotion_context",
        "accelerated_rc_same_candidate_retry =",
        "candidate_sha: accelerated_rc_same_candidate_retry ? current_git_sha!(release_root) : nil"
      )
      expect(release_task).not_to match(/sh_in_dir_for_release\(release_root, "git tag /)
    end
  end

  describe "release task accelerated RC preflight" do
    it "blocks a remote-only ordinary target tag before gates or release side effects from a mismatched checkout" do
      release_task = Rake::Task["release"]
      task_receiver = release_task.actions.first.binding.receiver
      success_status = instance_double(Process::Status, success?: true)
      events = []

      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "rev-parse", "--abbrev-ref", "HEAD")
        .and_return(["release/17.0.0\n", success_status])
      allow(ReactOnRails::GitUtils).to receive(:uncommitted_changes?)
      allow(task_receiver).to receive(:with_release_checkout) { |**_, &block| block.call("/tmp/repo") }
      allow(task_receiver).to receive_messages(
        current_monorepo_root: "/tmp/repo",
        verbose: nil,
        resolve_release_version_before_auth!: "17.0.0.rc.10",
        current_gem_version: "16.9.0",
        github_repo_slug: "shakacode/react_on_rails",
        local_release_tag_exists?: false,
        remote_git_tag_exists?: true,
        fetch_remote_release_tag!: nil,
        accelerated_rc_tag_provenance_for_tag!: nil,
        fetch_release_tracker_issue!: {},
        current_release_approver!: "justin808"
      )
      allow(task_receiver).to receive(:sh_in_dir_for_release) do |_dir, command|
        events << :push if command.include?("git push")
        events << :version_mutation if command.include?("gem bump")
      end
      allow(task_receiver).to receive(:validate_main_ci_status!) do
        events << :ci
        abort "CI was reached before exact-target tag classification"
      end
      allow(task_receiver).to receive(:confirm_release!) { events << :confirmation }
      allow(task_receiver).to receive(:append_accelerated_rc_tracker_record!) { events << :tracker_append }
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("RELEASE_ACCELERATED_RC", nil).and_return("true")
      allow(ENV).to receive(:fetch).with("RELEASE_TRACKER", nil).and_return("3823")
      allow(ENV).to receive(:fetch).with("RELEASE_ACCELERATED_RC_REASON", nil)
                                   .and_return("Start published-artifact QA while exact-head checks finish")

      failure = begin
        release_task.reenable
        release_task.invoke("17.0.0.rc.10", false, true, false)
        nil
      rescue SystemExit => error
        error
      ensure
        release_task.reenable
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/ordinary lightweight.*v17\.0\.0\.rc\.10.*accelerated/i)
        expect(events).to be_empty
        expect(task_receiver).to have_received(:local_release_tag_exists?)
          .with(monorepo_root: "/tmp/repo", tag: "v17.0.0.rc.10")
        expect(task_receiver).to have_received(:remote_git_tag_exists?)
          .with(monorepo_root: "/tmp/repo", tag: "v17.0.0.rc.10")
        expect(task_receiver).to have_received(:fetch_remote_release_tag!)
          .with(monorepo_root: "/tmp/repo", tag: "v17.0.0.rc.10", tag_type: "accelerated RC")
        expect(task_receiver).not_to have_received(:confirm_release!)
        expect(task_receiver).not_to have_received(:append_accelerated_rc_tracker_record!)
      end
    end
  end

  describe "#push_release_tag_for_candidate!" do
    it "blocks candidate-accepted tag handling when final-promotion context is missing" do
      _authorization, _publication, accepted = accelerated_rc_test_accepted_history
      tag_handled = false
      pushed = false
      package_publication_started = false
      allow(self).to receive(:validate_accelerated_tag_publication_boundary!)
      allow(self).to receive(:ensure_release_tag_for_candidate!) { tag_handled = true }
      allow(self).to receive(:validate_release_candidate_publication_boundary!)
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      failure = begin
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha: "e" * 40,
          accelerated_boundary_record: accepted
        )
        package_publication_started = true
        nil
      rescue SystemExit => error
        error
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/missing accelerated final-promotion context/i)
        expect(tag_handled).to be(false)
        expect(pushed).to be(false)
        expect(package_publication_started).to be(false)
      end
    end

    context "when final-promotion evidence mode changes after initial validation" do
      let(:accepted_record) { accelerated_rc_test_accepted_history.last }
      let(:candidate_sha) { "e" * 40 }
      let(:successful_ci) do
        {
          status: "success",
          sha: accepted_record.fetch("candidate_sha"),
          checks_url: accepted_record.dig("ci", "checks_url"),
          non_success: []
        }
      end
      let(:accepted_context) do
        accelerated_final_promotion_test_context(record: accepted_record, ci_snapshot: successful_ci)
      end

      before do
        allow(self).to receive_messages(
          validate_accelerated_repository_publication_boundary!: nil,
          validate_final_promotion_ci_publication_boundary!: nil,
          validate_final_promotion_shakaperf_publication_boundary!: nil,
          validate_final_promotion_source_rc_tag_boundary!: nil,
          validate_release_candidate_publication_boundary!: candidate_sha,
          validate_remote_release_tag_candidate_sha!: candidate_sha
        )
      end

      it "rejects a missing mode at the later tag-handling boundary" do
        initial_validation_complete = false
        allow(self).to receive(:validate_final_promotion_context!).and_wrap_original do |method, **arguments|
          result = method.call(**arguments)
          unless initial_validation_complete
            initial_validation_complete = true
            accepted_context.delete(:shakaperf_evidence_mode)
          end
          result
        end
        tag_handled = false
        allow(self).to receive(:ensure_release_tag_for_candidate!) { tag_handled = true }
        expect(self).not_to receive(:sh_in_dir_for_release)

        expect do
          push_release_tag_for_candidate!(
            monorepo_root: "/tmp/repo",
            tag: "v17.0.0",
            candidate_sha:,
            accelerated_boundary_record: accepted_record,
            accelerated_final_promotion_context: accepted_context
          )
        end.to raise_error(SystemExit, /incomplete accelerated final-promotion boundary evidence/i)
        expect(tag_handled).to be(false)
      end

      it "rejects an unknown mode at the later pre-push boundary" do
        allow(self).to receive(:ensure_release_tag_for_candidate!) do
          accepted_context[:shakaperf_evidence_mode] = "future-mode"
        end
        expect(self).not_to receive(:sh_in_dir_for_release)

        expect do
          push_release_tag_for_candidate!(
            monorepo_root: "/tmp/repo",
            tag: "v17.0.0",
            candidate_sha:,
            accelerated_boundary_record: accepted_record,
            accelerated_final_promotion_context: accepted_context
          )
        end.to raise_error(SystemExit, /inconsistent accelerated final-promotion boundary evidence/i)
      end

      it "rejects accepted-RC evidence relabeled strict-final after tag push" do
        package_publication_continued = false
        allow(self).to receive(:ensure_release_tag_for_candidate!)
        allow(self).to receive(:sh_in_dir_for_release) do
          accepted_context[:shakaperf_evidence_mode] = FINAL_PROMOTION_SHAKAPERF_STRICT_FINAL_MODE
        end
        allow(self).to receive(:validate_remote_release_tag_candidate_sha!) do
          package_publication_continued = true
        end

        expect do
          push_release_tag_for_candidate!(
            monorepo_root: "/tmp/repo",
            tag: "v17.0.0",
            candidate_sha:,
            accelerated_boundary_record: accepted_record,
            accelerated_final_promotion_context: accepted_context
          )
        end.to raise_error(SystemExit, /inconsistent accelerated final-promotion boundary evidence/i)
        expect(package_publication_continued).to be(false)
      end

      it "rejects strict-final evidence relabeled accepted-RC at the later pre-push boundary" do
        strict_context = strict_final_promotion_test_context(record: accepted_record, ci_snapshot: successful_ci)
        allow(self).to receive(:ensure_release_tag_for_candidate!) do
          strict_context[:shakaperf_evidence_mode] = FINAL_PROMOTION_SHAKAPERF_ACCEPTED_RC_MODE
        end
        expect(self).not_to receive(:sh_in_dir_for_release)

        expect do
          push_release_tag_for_candidate!(
            monorepo_root: "/tmp/repo",
            tag: "v17.0.0",
            candidate_sha:,
            accelerated_boundary_record: accepted_record,
            accelerated_final_promotion_context: strict_context
          )
        end.to raise_error(SystemExit, /inconsistent accelerated final-promotion boundary evidence/i)
      end
    end

    context "when strict-final ShakaPerf identity changes after initial validation" do
      let(:accepted_record) { accelerated_rc_test_accepted_history.last }
      let(:candidate_sha) { "e" * 40 }
      let(:successful_ci) do
        {
          status: "success",
          sha: accepted_record.fetch("candidate_sha"),
          checks_url: accepted_record.dig("ci", "checks_url"),
          non_success: []
        }
      end
      let(:strict_context) do
        strict_final_promotion_test_context(
          record: accepted_record, ci_snapshot: successful_ci, final_candidate_sha: candidate_sha
        )
      end

      before do
        allow(self).to receive_messages(
          validate_accelerated_repository_publication_boundary!: nil,
          validate_final_promotion_ci_publication_boundary!: nil,
          validate_final_promotion_shakaperf_publication_boundary!: nil,
          validate_final_promotion_source_rc_tag_boundary!: nil,
          validate_release_candidate_publication_boundary!: candidate_sha,
          validate_remote_release_tag_candidate_sha!: candidate_sha
        )
      end

      {
        "a changed run ID" => :run_id,
        "a changed attempt" => :attempt,
        "a changed run URL" => :run_url,
        "a changed release start" => :release_started_at,
        "a changed release branch/ref" => :release_branch,
        "a changed candidate SHA" => :candidate_sha,
        "a changed target version" => :target_version,
        "a missing identity anchor" => :missing_anchor,
        "a replaced identity anchor" => :changed_anchor,
        "an unfrozen identity anchor" => :mutable_anchor
      }.each do |description, component|
        it "rejects #{description} before tag push" do
          allow(self).to receive(:ensure_release_tag_for_candidate!) do
            mutate_strict_final_promotion_test_identity!(strict_context, component)
          end
          expect(self).not_to receive(:sh_in_dir_for_release)

          expect do
            push_release_tag_for_candidate!(
              monorepo_root: "/tmp/repo",
              tag: "v17.0.0",
              candidate_sha:,
              accelerated_boundary_record: accepted_record,
              accelerated_final_promotion_context: strict_context
            )
          end.to raise_error(SystemExit, /inconsistent accelerated final-promotion boundary evidence/i)
        end

        it "rejects #{description} after tag push and before package publication" do
          package_publication_continued = false
          allow(self).to receive(:ensure_release_tag_for_candidate!)
          allow(self).to receive(:sh_in_dir_for_release) do
            mutate_strict_final_promotion_test_identity!(strict_context, component)
          end
          allow(self).to receive(:validate_remote_release_tag_candidate_sha!) do
            package_publication_continued = true
          end

          expect do
            push_release_tag_for_candidate!(
              monorepo_root: "/tmp/repo",
              tag: "v17.0.0",
              candidate_sha:,
              accelerated_boundary_record: accepted_record,
              accelerated_final_promotion_context: strict_context
            )
          end.to raise_error(SystemExit, /inconsistent accelerated final-promotion boundary evidence/i)
          expect(package_publication_continued).to be(false)
        end
      end
    end

    context "when strict-final identity and its context anchor are redefined together" do
      let(:accepted_record) { accelerated_rc_test_accepted_history.last }
      let(:candidate_sha) { "e" * 40 }
      let(:successful_ci) do
        {
          status: "success",
          sha: accepted_record.fetch("candidate_sha"),
          checks_url: accepted_record.dig("ci", "checks_url"),
          non_success: []
        }
      end
      let(:strict_context) do
        strict_final_promotion_test_context(
          record: accepted_record, ci_snapshot: successful_ci, final_candidate_sha: candidate_sha
        )
      end

      before do
        allow(self).to receive_messages(
          validate_accelerated_repository_publication_boundary!: nil,
          validate_final_promotion_ci_publication_boundary!: nil,
          validate_final_promotion_shakaperf_publication_boundary!: nil,
          validate_final_promotion_source_rc_tag_boundary!: nil,
          validate_release_candidate_publication_boundary!: candidate_sha,
          validate_remote_release_tag_candidate_sha!: candidate_sha
        )
      end

      {
        "run identity" => :run_identity,
        "candidate SHA" => :candidate_sha,
        "target version" => :target_version
      }.each do |description, component|
        it "rejects coordinated #{description} and anchor redefinition before tag push" do
          allow(self).to receive(:ensure_release_tag_for_candidate!) do
            redefine_strict_final_promotion_test_identity_and_anchor!(strict_context, component)
          end
          expect(self).not_to receive(:sh_in_dir_for_release)

          expect do
            push_release_tag_for_candidate!(
              monorepo_root: "/tmp/repo",
              tag: "v17.0.0",
              candidate_sha:,
              accelerated_boundary_record: accepted_record,
              accelerated_final_promotion_context: strict_context
            )
          end.to raise_error(SystemExit, /inconsistent accelerated final-promotion boundary evidence/i)
        end

        it "rejects coordinated #{description} and anchor redefinition after tag push" do
          package_publication_continued = false
          allow(self).to receive(:ensure_release_tag_for_candidate!)
          allow(self).to receive(:sh_in_dir_for_release) do
            redefine_strict_final_promotion_test_identity_and_anchor!(strict_context, component)
          end
          allow(self).to receive(:validate_remote_release_tag_candidate_sha!) do
            package_publication_continued = true
          end

          expect do
            push_release_tag_for_candidate!(
              monorepo_root: "/tmp/repo",
              tag: "v17.0.0",
              candidate_sha:,
              accelerated_boundary_record: accepted_record,
              accelerated_final_promotion_context: strict_context
            )
          end.to raise_error(SystemExit, /inconsistent accelerated final-promotion boundary evidence/i)
          expect(package_publication_continued).to be(false)
        end
      end
    end

    it "blocks stable-tag push when the live source RC tag disappears after initial final gates" do
      _authorization, _publication, accepted = accelerated_rc_test_accepted_history
      candidate_sha = "e" * 40
      source_candidate_sha = accepted.fetch("candidate_sha")
      successful_ci = {
        status: "success",
        sha: source_candidate_sha,
        checks_url: accepted.dig("ci", "checks_url"),
        non_success: []
      }
      context = accelerated_final_promotion_test_context(record: accepted, ci_snapshot: successful_ci)
      allow(self).to receive_messages(
        validate_accelerated_repository_publication_boundary!: nil,
        validate_final_promotion_ci_publication_boundary!: nil,
        validate_final_promotion_shakaperf_publication_boundary!: nil,
        system: true,
        validate_release_tag_candidate_sha!: candidate_sha,
        validate_release_candidate_publication_boundary!: candidate_sha,
        remote_git_tag_exists?: true,
        fetch_remote_rc_tag!: nil,
        accelerated_rc_tag_provenance_for_tag!: context.fetch(:source_rc_tag_provenance),
        peeled_git_tag_sha: source_candidate_sha,
        validate_remote_release_tag_candidate_sha!: candidate_sha
      )
      allow(self).to receive(:remote_git_tag_exists?).and_return(true, false)
      expect(self).not_to receive(:sh_in_dir_for_release)

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha:,
          accelerated_boundary_record: accepted,
          accelerated_final_promotion_context: context
        )
      end.to raise_error(SystemExit, /source RC tag.*disappeared.*git tag push/i)
    end

    it "blocks packages when the live source RC tag moves after stable-tag push" do
      _authorization, _publication, accepted = accelerated_rc_test_accepted_history
      candidate_sha = "e" * 40
      source_candidate_sha = accepted.fetch("candidate_sha")
      moved_sha = "d" * 40
      successful_ci = {
        status: "success",
        sha: source_candidate_sha,
        checks_url: accepted.dig("ci", "checks_url"),
        non_success: []
      }
      context = accelerated_final_promotion_test_context(record: accepted, ci_snapshot: successful_ci)
      allow(self).to receive_messages(
        validate_accelerated_repository_publication_boundary!: nil,
        validate_final_promotion_ci_publication_boundary!: nil,
        validate_final_promotion_shakaperf_publication_boundary!: nil,
        system: true,
        validate_release_tag_candidate_sha!: candidate_sha,
        remote_git_tag_exists?: true,
        fetch_remote_rc_tag!: nil,
        accelerated_rc_tag_provenance_for_tag!: context.fetch(:source_rc_tag_provenance),
        validate_release_candidate_publication_boundary!: candidate_sha,
        validate_remote_release_tag_candidate_sha!: candidate_sha
      )
      allow(self).to receive(:peeled_git_tag_sha)
        .and_return(source_candidate_sha, source_candidate_sha, moved_sha)
      pushed = false
      package_publication_started = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha:,
          accelerated_boundary_record: accepted,
          accelerated_final_promotion_context: context
        )
        package_publication_started = true
      end.to raise_error(SystemExit, /source RC tag.*moved.*package publication/i)

      aggregate_failures do
        expect(pushed).to be(true)
        expect(package_publication_started).to be(false)
      end
    end

    it "still validates the live stable tag after all source RC boundaries pass" do
      _authorization, _publication, accepted = accelerated_rc_test_accepted_history
      candidate_sha = "e" * 40
      source_candidate_sha = accepted.fetch("candidate_sha")
      successful_ci = {
        status: "success",
        sha: source_candidate_sha,
        checks_url: accepted.dig("ci", "checks_url"),
        non_success: []
      }
      context = accelerated_final_promotion_test_context(record: accepted, ci_snapshot: successful_ci)
      allow(self).to receive_messages(
        validate_accelerated_repository_publication_boundary!: nil,
        validate_final_promotion_ci_publication_boundary!: nil,
        validate_final_promotion_shakaperf_publication_boundary!: nil,
        system: true,
        validate_release_tag_candidate_sha!: candidate_sha,
        validate_release_candidate_publication_boundary!: candidate_sha,
        remote_git_tag_exists?: true,
        fetch_remote_rc_tag!: nil,
        accelerated_rc_tag_provenance_for_tag!: context.fetch(:source_rc_tag_provenance),
        peeled_git_tag_sha: source_candidate_sha
      )
      allow(self).to receive(:sh_in_dir_for_release)
      allow(self).to receive(:validate_remote_release_tag_candidate_sha!).with(
        monorepo_root: "/tmp/repo", tag: "v17.0.0", candidate_sha:, phase: "package publication"
      ).and_return(candidate_sha)

      push_release_tag_for_candidate!(
        monorepo_root: "/tmp/repo",
        tag: "v17.0.0",
        candidate_sha:,
        accelerated_boundary_record: accepted,
        accelerated_final_promotion_context: context
      )

      expect(self).to have_received(:fetch_remote_rc_tag!).exactly(3).times
      expect(self).to have_received(:validate_remote_release_tag_candidate_sha!).with(
        monorepo_root: "/tmp/repo", tag: "v17.0.0", candidate_sha:, phase: "package publication"
      )
    end

    it "blocks newly failed live CI immediately before accelerated RC tag push" do
      authorization = accelerated_rc_test_authorization
      pending_ci = {
        status: "pending",
        sha: authorization.fetch("candidate_sha"),
        checks_url: authorization.dig("ci", "checks_url"),
        non_success: authorization.dig("ci", "non_success").map do |check|
          check.transform_keys(&:to_sym)
        end
      }
      failed_ci = {
        status: "failed",
        sha: "f" * 40,
        checks_url: authorization.dig("ci", "checks_url"),
        non_success: [{
          name: "generator",
          state: "failure",
          url: authorization.dig("ci", "non_success", 0, "url")
        }]
      }
      allow(self).to receive_messages(
        github_repo_slug: "shakacode/react_on_rails",
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        accelerated_rc_shakaperf_snapshot!: authorization.fetch("shakaperf"),
        system: true,
        validate_existing_accelerated_rc_tag!: nil,
        validate_release_candidate_publication_boundary!: nil
      )
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!)
        .and_return(pending_ci, failed_ci)
      pushed = false
      package_publication_started = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      failure = begin
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0.rc.10",
          candidate_sha: "f" * 40,
          accelerated_publication_record: authorization
        )
        package_publication_started = true
        nil
      rescue SystemExit => error
        error
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/live.*exact-candidate CI.*failed|known failed.*CI/i)
        expect(pushed).to be(false)
        expect(package_publication_started).to be(false)
      end
    end

    it "blocks unknown live ShakaPerf after tag push before accelerated package publication" do
      authorization = accelerated_rc_test_authorization
      pending_ci = {
        status: "pending",
        sha: authorization.fetch("candidate_sha"),
        checks_url: authorization.dig("ci", "checks_url"),
        non_success: authorization.dig("ci", "non_success").map do |check|
          check.transform_keys(&:to_sym)
        end
      }
      allow(self).to receive_messages(
        github_repo_slug: "shakacode/react_on_rails",
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization],
        fetch_accelerated_rc_ci_snapshot!: pending_ci,
        system: true,
        validate_existing_accelerated_rc_tag!: nil,
        validate_release_candidate_publication_boundary!: nil
      )
      allow(self).to receive(:accelerated_rc_shakaperf_snapshot!)
        .and_return(authorization.fetch("shakaperf"), authorization.fetch("shakaperf"), { "status" => "unknown" })
      pushed = false
      package_publication_started = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      failure = begin
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0.rc.10",
          candidate_sha: "f" * 40,
          accelerated_publication_record: authorization
        )
        package_publication_started = true
        nil
      rescue SystemExit => error
        error
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/live ShakaPerf.*unknown/i)
        expect(pushed).to be(true)
        expect(package_publication_started).to be(false)
      end
    end

    it "blocks a repository-wide tracker conflict that appears immediately before accelerated RC tag push" do
      authorization = accelerated_rc_test_authorization
      conflicting_authorization = accelerated_rc_test_authorization(tracker: 3824)
      pending_ci = {
        status: "pending",
        sha: authorization.fetch("candidate_sha"),
        checks_url: authorization.dig("ci", "checks_url"),
        non_success: authorization.dig("ci", "non_success").map do |check|
          check.transform_keys(&:to_sym)
        end
      }
      allow(self).to receive_messages(
        github_repo_slug: "shakacode/react_on_rails",
        fetch_accelerated_rc_ci_snapshot!: pending_ci,
        accelerated_rc_shakaperf_snapshot!: authorization.fetch("shakaperf"),
        system: true,
        validate_existing_accelerated_rc_tag!: nil,
        validate_release_candidate_publication_boundary!: nil
      )
      allow(self).to receive(:fetch_repository_accelerated_rc_records_for_candidate!)
        .and_return([authorization], [authorization, conflicting_authorization])
      pushed = false
      package_publication_started = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      failure = begin
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0.rc.10",
          candidate_sha: "f" * 40,
          accelerated_publication_record: authorization
        )
        package_publication_started = true
        nil
      rescue SystemExit => e
        e
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/repository-wide.*tracker|conflicting release trackers/i)
        expect(pushed).to be(false)
        expect(package_publication_started).to be(false)
      end
    end

    it "blocks stable final package publication when rejection appears after tag push" do
      authorization, publication, accepted = accelerated_rc_test_accepted_history
      rejected_history = accelerated_rc_test_rejected_history
      successful_ci = {
        status: "success",
        sha: accepted.fetch("candidate_sha"),
        checks_url: accepted.dig("ci", "checks_url"),
        non_success: []
      }
      final_promotion_context = accelerated_final_promotion_test_context(
        record: accepted, ci_snapshot: successful_ci
      )
      allow(self).to receive_messages(
        github_repo_slug: "shakacode/react_on_rails",
        validate_final_promotion_source_rc_tag_boundary!: nil,
        fetch_accelerated_rc_ci_snapshot!: successful_ci,
        accelerated_rc_shakaperf_snapshot!: accepted.fetch("shakaperf"),
        system: true,
        validate_release_tag_candidate_sha!: "e" * 40,
        validate_release_candidate_publication_boundary!: "e" * 40
      )
      allow(self).to receive(:fetch_repository_accelerated_rc_records_for_candidate!)
        .and_return([authorization, publication, accepted], [authorization, publication, accepted], rejected_history)
      pushed = false
      package_publication_started = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha: "e" * 40,
          accelerated_boundary_record: accepted,
          accelerated_final_promotion_context: final_promotion_context
        )
        package_publication_started = true
      end.to raise_error(SystemExit, /permanently rejected|candidate-rejected.*absorbing/i)

      expect(pushed).to be(true)
      expect(package_publication_started).to be(false)
    end

    it "blocks stable final package publication when exact-candidate CI fails after tag push" do
      authorization, publication, accepted = accelerated_rc_test_accepted_history
      successful_ci = {
        status: "success",
        sha: accepted.fetch("candidate_sha"),
        checks_url: accepted.dig("ci", "checks_url"),
        non_success: []
      }
      failed_ci = successful_ci.merge(
        status: "failed",
        non_success: [{
          name: "generator",
          state: "failure",
          url: "https://github.com/shakacode/react_on_rails/actions/runs/999"
        }]
      )
      final_promotion_context = accelerated_final_promotion_test_context(
        record: accepted, ci_snapshot: successful_ci
      )
      allow(self).to receive_messages(
        github_repo_slug: "shakacode/react_on_rails",
        validate_final_promotion_source_rc_tag_boundary!: nil,
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization, publication, accepted],
        accelerated_rc_shakaperf_snapshot!: accepted.fetch("shakaperf"),
        system: true,
        validate_release_tag_candidate_sha!: "e" * 40,
        validate_release_candidate_publication_boundary!: "e" * 40
      )
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!)
        .and_return(successful_ci, successful_ci, failed_ci)
      pushed = false
      package_publication_started = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha: "e" * 40,
          accelerated_boundary_record: accepted,
          accelerated_final_promotion_context: final_promotion_context
        )
        package_publication_started = true
      end.to raise_error(SystemExit, /final promotion.*exact-candidate CI.*failed|exact-RC CI.*pending/i)

      expect(pushed).to be(true)
      expect(package_publication_started).to be(false)
    end

    it "blocks stable final package publication when the exact ShakaPerf run becomes unknown after tag push" do
      authorization, publication, accepted = accelerated_rc_test_accepted_history
      successful_ci = {
        status: "success",
        sha: accepted.fetch("candidate_sha"),
        checks_url: accepted.dig("ci", "checks_url"),
        non_success: []
      }
      final_promotion_context = accelerated_final_promotion_test_context(
        record: accepted, ci_snapshot: successful_ci
      )
      allow(self).to receive_messages(
        github_repo_slug: "shakacode/react_on_rails",
        validate_final_promotion_source_rc_tag_boundary!: nil,
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization, publication, accepted],
        fetch_accelerated_rc_ci_snapshot!: successful_ci,
        system: true,
        validate_release_tag_candidate_sha!: "e" * 40,
        validate_release_candidate_publication_boundary!: "e" * 40
      )
      allow(self).to receive(:accelerated_rc_shakaperf_snapshot!)
        .and_return(accepted.fetch("shakaperf"), accepted.fetch("shakaperf"), { "status" => "unknown" })
      pushed = false
      package_publication_started = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha: "e" * 40,
          accelerated_boundary_record: accepted,
          accelerated_final_promotion_context: final_promotion_context
        )
        package_publication_started = true
      end.to raise_error(SystemExit, /final promotion.*ShakaPerf.*unknown/i)

      expect(pushed).to be(true)
      expect(package_publication_started).to be(false)
    end

    it "blocks stable final package publication when exact ShakaPerf evidence changes after tag push" do
      authorization, publication, accepted = accelerated_rc_test_accepted_history
      successful_ci = {
        status: "success",
        sha: accepted.fetch("candidate_sha"),
        checks_url: accepted.dig("ci", "checks_url"),
        non_success: []
      }
      final_promotion_context = accelerated_final_promotion_test_context(
        record: accepted, ci_snapshot: successful_ci
      )
      changed_shakaperf = accepted.fetch("shakaperf").merge(
        "run_url" => "https://github.com/shakacode/react_on_rails/actions/runs/654321"
      )
      allow(self).to receive_messages(
        github_repo_slug: "shakacode/react_on_rails",
        validate_final_promotion_source_rc_tag_boundary!: nil,
        fetch_repository_accelerated_rc_records_for_candidate!: [authorization, publication, accepted],
        fetch_accelerated_rc_ci_snapshot!: successful_ci,
        system: true,
        validate_release_tag_candidate_sha!: "e" * 40,
        validate_release_candidate_publication_boundary!: "e" * 40
      )
      allow(self).to receive(:accelerated_rc_shakaperf_snapshot!)
        .and_return(accepted.fetch("shakaperf"), accepted.fetch("shakaperf"), changed_shakaperf)
      pushed = false
      package_publication_started = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha: "e" * 40,
          accelerated_boundary_record: accepted,
          accelerated_final_promotion_context: final_promotion_context
        )
        package_publication_started = true
      end.to raise_error(SystemExit, /final promotion.*materially changed ShakaPerf/i)

      expect(pushed).to be(true)
      expect(package_publication_started).to be(false)
    end

    it "uses the promotion CI branch at all final boundaries and blocks its post-push failure" do
      _authorization, _publication, accepted = accelerated_rc_test_accepted_history
      source_record = accepted.merge("release_branch" => "release/17.0.0-rc-source")
      promotion_branch = "release/17.0.0"
      successful_ci = {
        status: "success",
        sha: source_record.fetch("candidate_sha"),
        checks_url: source_record.dig("ci", "checks_url"),
        non_success: []
      }
      failed_ci = successful_ci.merge(
        status: "failed",
        non_success: [{
          name: "required-generator",
          state: "failure",
          url: "https://github.com/shakacode/react_on_rails/actions/runs/999"
        }]
      )
      final_promotion_context = accelerated_final_promotion_test_context(
        record: source_record, ci_snapshot: successful_ci, ci_branch: promotion_branch
      )
      promotion_snapshots = [successful_ci, successful_ci, failed_ci]
      fetched_branches = []
      allow(self).to receive_messages(
        github_repo_slug: "shakacode/react_on_rails",
        validate_accelerated_repository_publication_boundary!: nil,
        validate_final_promotion_shakaperf_publication_boundary!: nil,
        validate_final_promotion_source_rc_tag_boundary!: nil,
        system: true,
        validate_release_tag_candidate_sha!: "e" * 40,
        validate_release_candidate_publication_boundary!: "e" * 40
      )
      allow(self).to receive(:fetch_accelerated_rc_ci_snapshot!) do |**arguments|
        ci_branch = arguments.fetch(:ci_branch)
        fetched_branches << ci_branch
        ci_branch == promotion_branch ? promotion_snapshots.shift : successful_ci
      end
      pushed = false
      package_publication_started = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha: "e" * 40,
          accelerated_boundary_record: source_record,
          accelerated_final_promotion_context: final_promotion_context
        )
        package_publication_started = true
      end.to raise_error(SystemExit, /refreshed exact-RC CI is failed/)

      aggregate_failures do
        expect(fetched_branches).to eq([promotion_branch, promotion_branch, promotion_branch])
        expect(pushed).to be(true)
        expect(package_publication_started).to be(false)
      end
    end

    it "blocks package continuation when the remote tag moves after tag push" do
      candidate_sha = "e" * 40
      moved_sha = "d" * 40
      success = instance_double(Process::Status, success?: true)
      allow(self).to receive_messages(
        system: true,
        validate_accelerated_tag_publication_boundary!: nil,
        validate_release_tag_candidate_sha!: candidate_sha,
        validate_release_candidate_publication_boundary!: candidate_sha
      )
      allow(Open3).to receive(:capture2e).with(
        "git", "-C", "/tmp/repo", "ls-remote", "--tags", "origin",
        "refs/tags/v17.0.0", "refs/tags/v17.0.0^{}"
      ).and_return(["#{moved_sha}\trefs/tags/v17.0.0\n", success])
      pushed = false
      package_publication_started = false
      allow(self).to receive(:sh_in_dir_for_release) { pushed = true }

      failure = begin
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha:
        )
        package_publication_started = true
        nil
      rescue SystemExit => error
        error
      end

      aggregate_failures do
        expect(failure).to be_a(SystemExit)
        expect(failure&.message).to match(/remote release tag.*moved.*package publication/i)
        expect(pushed).to be(true)
        expect(package_publication_started).to be(false)
      end
      expect(Open3).to have_received(:capture2e).with(
        "git", "-C", "/tmp/repo", "ls-remote", "--tags", "origin",
        "refs/tags/v17.0.0", "refs/tags/v17.0.0^{}"
      )
    end

    it "uses the peeled remote SHA for an annotated accelerated RC tag" do
      candidate_sha = "e" * 40
      tag_object_sha = "a" * 40
      success = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2e).with(
        "git", "-C", "/tmp/repo", "ls-remote", "--tags", "origin",
        "refs/tags/v17.0.0.rc.10", "refs/tags/v17.0.0.rc.10^{}"
      ).and_return(
        [
          "#{tag_object_sha}\trefs/tags/v17.0.0.rc.10\n" \
          "#{candidate_sha}\trefs/tags/v17.0.0.rc.10^{}\n",
          success
        ]
      )

      expect(
        validate_remote_release_tag_candidate_sha!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0.rc.10",
          candidate_sha:,
          phase: "package publication"
        )
      ).to eq(candidate_sha)
      expect(Open3).to have_received(:capture2e).with(
        "git", "-C", "/tmp/repo", "ls-remote", "--tags", "origin",
        "refs/tags/v17.0.0.rc.10", "refs/tags/v17.0.0.rc.10^{}"
      )
    end

    it "blocks an existing stable tag before push when HEAD moved after final gates" do
      allow(self).to receive(:system).and_return(true)
      allow(self).to receive_messages(
        validate_release_tag_candidate_sha!: "e" * 40,
        current_git_sha!: "d" * 40
      )
      expect(self).not_to receive(:sh_in_dir_for_release)

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha: "e" * 40
        )
      end.to raise_error(SystemExit, /HEAD moved.*before git tag push/i)
    end

    it "blocks a newly created stable tag before push when HEAD moves after tag creation" do
      allow(self).to receive_messages(system: false, current_git_sha!: "d" * 40)
      expect(self).to receive(:create_release_tag_at_candidate_sha!).with(
        monorepo_root: "/tmp/repo",
        tag: "v17.0.0",
        candidate_sha: "e" * 40
      )
      expect(self).not_to receive(:sh_in_dir_for_release)

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha: "e" * 40
        )
      end.to raise_error(SystemExit, /HEAD moved.*before git tag push/i)
    end

    it "revalidates HEAD after tag push before package publication" do
      head_shas = ["e" * 40, "d" * 40]
      allow(self).to receive_messages(
        system: true,
        validate_release_tag_candidate_sha!: "e" * 40
      )
      allow(self).to receive(:current_git_sha!) { head_shas.shift }
      expect(self).to receive(:sh_in_dir_for_release).with("/tmp/repo", "LEFTHOOK=0 git push --tags")

      expect do
        push_release_tag_for_candidate!(
          monorepo_root: "/tmp/repo",
          tag: "v17.0.0",
          candidate_sha: "e" * 40
        )
      end.to raise_error(SystemExit, /HEAD moved.*before package publication/i)
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

    def statuses_envelope(sha)
      { "name" => "statuses", "sha" => sha }
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

    context "when the release branch is intentionally unprotected" do
      it "evaluates every visible prerelease check instead of treating required checks as unknown" do
        failure_status = instance_double(Process::Status, success?: false)
        success_status = instance_double(Process::Status, success?: true)
        api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
        branch_path = "repos/shakacode/react_on_rails/branches/main"
        allow(self).to receive(:required_check_names_for_branch).and_call_original
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [passing_run("Lint")])
        allow(Open3).to receive(:capture2e)
          .with("gh", "api", "--jq", "{contexts, checks}", api_path)
          .and_return(["HTTP 404: Branch not protected", failure_status])
        allow(Open3).to receive(:capture3)
          .with("gh", "api", "--include", api_path)
          .and_return([
                        "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\r\n\r\n" \
                        '{"message":"Branch not protected"}',
                        "gh: branch protection is not enabled for this branch\n",
                        failure_status
                      ])
        allow(Open3).to receive(:capture2e)
          .with("gh", "api", branch_path)
          .and_return(['{"name":"main","protected":false}', success_status])

        output = nil
        expect do
          output = capture_stdout do
            validate_main_ci_status!(
              monorepo_root:,
              is_prerelease: true,
              allow_override: false,
              dry_run: false
            )
          end
        end.not_to raise_error
        expect(output).to include("Main CI is healthy on #{short_sha} (1 check)")
      end
    end

    context "when a protected branch has required status checks disabled" do
      it "evaluates every visible prerelease check instead of treating required checks as unknown" do
        failure_status = instance_double(Process::Status, success?: false)
        success_status = instance_double(Process::Status, success?: true)
        api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
        branch_path = "repos/shakacode/react_on_rails/branches/main"
        allow(self).to receive(:required_check_names_for_branch).and_call_original
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, repo_slug: "shakacode/react_on_rails", check_runs: [passing_run("Lint")])
        allow(Open3).to receive(:capture2e)
          .with("gh", "api", "--jq", "{contexts, checks}", api_path)
          .and_return(["HTTP 404: Required status checks not enabled", failure_status])
        allow(Open3).to receive(:capture3)
          .with("gh", "api", "--include", api_path)
          .and_return([
                        "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\r\n\r\n" \
                        '{"message":"Required status checks not enabled"}',
                        "gh: Required status checks not enabled\n",
                        failure_status
                      ])
        allow(Open3).to receive(:capture2e)
          .with("gh", "api", branch_path)
          .and_return(['{"name":"main","protected":true}', success_status])

        output = nil
        expect do
          output = capture_stdout do
            validate_main_ci_status!(
              monorepo_root:,
              is_prerelease: true,
              allow_override: false,
              dry_run: false
            )
          end
        end.not_to raise_error
        expect(output).to include("Main CI is healthy on #{short_sha} (1 check)")
      end
    end

    context "when strict exact-HEAD evaluation is enabled" do
      before do
        allow(self).to receive(:ci_evaluate_head_only?).and_return(true)
      end

      it "rejects a stable CI override before strict exact-HEAD evidence can be waived" do
        expect(self).not_to receive(:fetch_main_ci_checks)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: true,
            dry_run: false
          )
        end.to raise_error(SystemExit, /CI status override is allowed only for prerelease releases/)
      end

      it "blocks a prerelease when an unrelated exact-HEAD check fails" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(
            sha:,
            head_sha: sha,
            repo_slug: "shakacode/react_on_rails",
            check_runs: [passing_run("Lint", app_id: 123), failing_run("Benchmark")]
          )
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
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Benchmark}m)
      end

      it "blocks a prerelease when an unrelated exact-HEAD check is pending" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(
            sha:,
            head_sha: sha,
            repo_slug: "shakacode/react_on_rails",
            check_runs: [passing_run("Lint", app_id: 123), in_progress_run("Benchmark")]
          )
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
        end.to raise_error(SystemExit, /CI is still in progress.*Benchmark/m)
      end

      it "reuses initially fetched statuses when strict evaluation reaches the missing-required fallback" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(
            sha:,
            head_sha: sha,
            repo_slug: "shakacode/react_on_rails",
            check_runs: [passing_run("Advisory")]
          )
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint", app_id: 123)]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([], nil)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("No required CI check runs found")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
        expect(self).to have_received(:fetch_main_commit_statuses).once
      end

      it "accepts a successful strict exact-HEAD check rerun over an earlier failure" do
        check_suite = { "id" => 77 }
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(
            sha:,
            head_sha: sha,
            repo_slug: "shakacode/react_on_rails",
            check_runs: [
              failing_run("Lint", id: 1).merge("check_suite" => check_suite),
              passing_run("Lint", id: 2).merge("check_suite" => check_suite)
            ]
          )
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint")]))
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
        end.to output(/Main CI is healthy on #{short_sha} \(1 required check\)/).to_stdout
      end

      it "accepts a successful strict exact-HEAD legacy status over an earlier failure" do
        statuses = [
          { "id" => 1, "context" => "Legacy CI", "state" => "failure", "created_at" => "2026-07-13T00:00:00Z" },
          { "id" => 2, "context" => "Legacy CI", "state" => "success", "created_at" => "2026-07-13T00:01:00Z" }
        ]
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, head_sha: sha, repo_slug: "shakacode/react_on_rails", check_runs: [])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Legacy CI"]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return(statuses)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to output(/Main CI is healthy on #{short_sha} \(1 required check\)/).to_stdout
      end

      it "fetches and blocks failed legacy status evidence for app-pinned-only protection" do
        failed_status = {
          "id" => 1,
          "context" => "Advisory",
          "state" => "failure",
          "created_at" => "2026-07-13T00:00:00Z"
        }
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(
            sha:,
            head_sha: sha,
            repo_slug: "shakacode/react_on_rails",
            check_runs: [passing_run("Lint", app_id: 123)]
          )
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint", app_id: 123)]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([failed_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, %r{CI on origin/main is not healthy.*Advisory}m)
        expect(self).to have_received(:fetch_main_commit_statuses)
      end

      it "fails closed when strict exact-HEAD status evidence is unavailable" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(
            sha:,
            head_sha: sha,
            repo_slug: "shakacode/react_on_rails",
            check_runs: [passing_run("Lint", app_id: 123)]
          )
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint", app_id: 123)]))
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
        end.to raise_error(SystemExit, /legacy status fetch returned nil unexpectedly in strict mode/)
      end

      it "fails closed when strict exact-HEAD status evidence is malformed" do
        malformed_status = {
          "id" => 1,
          "context" => nil,
          "state" => "success",
          "created_at" => "2026-07-13T00:00:00Z"
        }
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(
            sha:,
            head_sha: sha,
            repo_slug: "shakacode/react_on_rails",
            check_runs: [passing_run("Lint", app_id: 123)]
          )
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint", app_id: 123)]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: false)
          .and_return([malformed_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /Strict exact-HEAD CI evidence is malformed or unknown/)
      end

      it "keeps explicitly empty strict exact-HEAD evidence blocked" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(
            sha:,
            head_sha: sha,
            repo_slug: "shakacode/react_on_rails",
            check_runs: []
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
        end.to raise_error(SystemExit, %r{No CI check runs visible on origin/main})
      end
    end

    context "when required check discovery is unknown" do
      it "fails closed for a stable release despite a healthy-looking visible subset" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main")
          .and_return(REQUIRED_CHECK_DISCOVERY_UNKNOWN)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /Required CI check discovery is unknown/)
      end

      it "fails closed for a prerelease despite a healthy-looking visible subset" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [passing_run("Lint")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main")
          .and_return(REQUIRED_CHECK_DISCOVERY_UNKNOWN)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit, /Required CI check discovery is unknown/)
      end

      it "fails closed when strict exact-HEAD evaluation has a healthy-looking subset" do
        exact_head_sha = "head5678"
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha: exact_head_sha, head_sha: exact_head_sha, check_runs: [passing_run("Lint")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main")
          .and_return(REQUIRED_CHECK_DISCOVERY_UNKNOWN)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("Required CI check discovery is unknown")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
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

      it "hints to wait for release branch CI when no check runs are visible" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "release/17.0.0")
          .and_return(sha:, check_runs: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false,
            ci_branch: "release/17.0.0"
          )
        end.to raise_error(
          SystemExit,
          %r{No CI check runs visible on origin/release/17.0.0.*wait for at least one CI run to complete}m
        )
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

      it "allows only the explicit accelerated RC path to defer pending required checks" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [in_progress_run("Lint")])
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, ci_branch: "main").and_return(required_checks(checks: [required_check("Lint")]))

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            defer_pending: true
          )
        end.to output(/ACCELERATED RC.*deferring pending CI.*Lint/mi).to_stdout
      end

      it "never defers pending checks for stable or final promotion" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [in_progress_run("Lint")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false,
            defer_pending: true
          )
        end.to raise_error(SystemExit, /CI is still in progress.*Lint/m)
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

    context "when metadata walkback has no usable CI runs" do
      let(:walked_back_sha) { "runtime123" }
      let(:exact_head_sha) { "head5678" }
      let(:walkback_without_ci_runs) do
        {
          sha: walked_back_sha,
          head_sha: exact_head_sha,
          repo_slug: "shakacode/react_on_rails",
          check_runs: []
        }
      end

      before do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(walkback_without_ci_runs)
      end

      it "keeps the complete walkback output free of strict guidance for incomplete exact-HEAD evidence" do
        exact_head_cases = {
          pending: { check_runs: [in_progress_run("Slow test")], statuses: [] },
          failed: { check_runs: [failing_run("JS unit tests")], statuses: [] },
          empty: { check_runs: [], statuses: [] },
          malformed: {
            check_runs: [{
              "id" => 1, "name" => "Lint", "status" => "completed", "conclusion" => "success", "app" => {}
            }],
            statuses: []
          },
          unknown: { error: "❌ Unable to query GitHub Checks API for #{exact_head_sha}." }
        }

        exact_head_cases.each do |kind, result|
          allow(self).to receive(:fetch_ci_check_runs_for_sha)
            .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
            .and_return(result.slice(:check_runs, :error))
          allow(self).to receive(:fetch_ci_statuses_for_sha)
            .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
            .and_return(statuses: result.fetch(:statuses, []))

          error = nil
          output = capture_stdout do
            log_main_ci_walkback(
              head_sha: exact_head_sha,
              evaluated_sha: walked_back_sha,
              skipped: [exact_head_sha],
              ref: "origin/main"
            )
            begin
              validate_main_ci_status!(
                monorepo_root:,
                is_prerelease: false,
                allow_override: false,
                dry_run: false,
                target_gem_version: "17.0.0.rc.10"
              )
            rescue SystemExit => exception
              error = exception
            end
          end

          expect(error).to be_a(SystemExit), "#{kind} exact-HEAD evidence should block the release"
          expect(output).not_to include("RELEASE_CI_EVALUATE_HEAD=true"),
                                "#{kind} exact-HEAD evidence must not receive strict guidance"
        end
      end

      it "offers strict exact-HEAD evaluation only after exact HEAD is healthy" do
        strict_head_guidance = [
          "strict evaluation, not a waiver",
          'RELEASE_CI_EVALUATE_HEAD=true bundle exec rake "release\\[17\\.0\\.0\\.rc\\.10\\]"',
          "DANGEROUS",
          "RELEASE_CI_STATUS_OVERRIDE=true"
        ].join(".*")
        define_singleton_method(:fetch_ci_check_runs_for_sha) do |repo_slug:, sha:|
          expect(repo_slug).to eq("shakacode/react_on_rails")
          expect(sha).to eq(exact_head_sha)
          { check_runs: [passing_run("Lint")] }
        end
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(
          SystemExit,
          Regexp.new(strict_head_guidance, Regexp::MULTILINE)
        )
      end

      it "offers strict guidance when a successful exact-HEAD check rerun supersedes an earlier failure" do
        check_suite = { "id" => 77 }
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(
            check_runs: [
              failing_run("Lint", id: 1).merge("check_suite" => check_suite),
              passing_run("Lint", id: 2).merge("check_suite" => check_suite)
            ]
          )
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit, /RELEASE_CI_EVALUATE_HEAD=true bundle exec rake "release\[17\.0\.0\.rc\.10\]"/)
      end

      it "offers strict guidance when a successful exact-HEAD legacy status supersedes an earlier failure" do
        successful_statuses = [
          { "id" => 1, "context" => "Legacy CI", "state" => "failure", "created_at" => "2026-07-13T00:00:00Z" },
          { "id" => 2, "context" => "Legacy CI", "state" => "success", "created_at" => "2026-07-13T00:01:00Z" }
        ]
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Legacy CI"]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha: walked_back_sha, allow_override: false, dry_run: false)
          .and_return([])
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: successful_statuses)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit, /RELEASE_CI_EVALUATE_HEAD=true bundle exec rake "release\[17\.0\.0\.rc\.10\]"/)
      end

      it "withholds strict exact-HEAD guidance when walked-back unrelated evidence is pending" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(walkback_without_ci_runs.merge(check_runs: [in_progress_run("Advisory")]))
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint")]))
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [passing_run("Lint")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("No required CI check runs found")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
        expect(self).not_to have_received(:fetch_ci_check_runs_for_sha)
      end

      it "withholds strict exact-HEAD guidance when unrelated walked-back legacy status evidence is pending" do
        pending_status = {
          "id" => 1,
          "context" => "Advisory",
          "state" => "pending",
          "created_at" => "2026-07-13T00:00:00Z"
        }
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(walkback_without_ci_runs.merge(check_runs: [passing_run("Advisory")]))
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Legacy CI"]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha: walked_back_sha, allow_override: false, dry_run: false)
          .and_return([pending_status])
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [passing_run("Legacy CI")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("No required CI check runs found")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
        expect(self).not_to have_received(:fetch_ci_check_runs_for_sha)
        expect(self).not_to have_received(:fetch_ci_statuses_for_sha)
      end

      it "withholds strict exact-HEAD guidance when unrelated walked-back evidence has failed" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(walkback_without_ci_runs.merge(check_runs: [failing_run("Advisory")]))
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint")]))
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [passing_run("Lint")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("No required CI check runs found")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
        expect(self).not_to have_received(:fetch_ci_check_runs_for_sha)
        expect(self).not_to have_received(:fetch_ci_statuses_for_sha)
      end

      it "fails closed when an app-pinned exact-HEAD check run has a malformed app ID" do
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint", app_id: 123)]))
        success_status = instance_double(Process::Status, success?: true)
        malformed_run = {
          "id" => 1,
          "name" => "Lint",
          "status" => "completed",
          "conclusion" => "success",
          "app" => { "id" => "123-junk" }
        }
        allow(Open3).to receive(:capture2e)
          .with(
            "gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
            "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/check-runs"
          )
          .and_return([malformed_run.to_json, success_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("Exact HEAD evidence is unknown")
          expect(error.message).to include("malformed")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "fails closed when an exact-HEAD check run has a partial app identity" do
        success_status = instance_double(Process::Status, success?: true)
        malformed_run = {
          "id" => 1,
          "name" => "Lint",
          "status" => "completed",
          "conclusion" => "success",
          "app" => {}
        }
        allow(Open3).to receive(:capture2e)
          .with(
            "gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
            "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/check-runs"
          )
          .and_return([malformed_run.to_json, success_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("Exact HEAD evidence is unknown")
          expect(error.message).to include("malformed")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "fails closed when malformed suite identity would hide an exact-HEAD failure" do
        success_status = instance_double(Process::Status, success?: true)
        earlier_failure = {
          "id" => 1,
          "name" => "Lint",
          "status" => "completed",
          "conclusion" => "failure",
          "check_suite" => { "id" => "suite-junk" }
        }
        later_success = earlier_failure.merge("id" => 2, "conclusion" => "success")
        allow(Open3).to receive(:capture2e)
          .with(
            "gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
            "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/check-runs"
          )
          .and_return([[earlier_failure, later_success].map(&:to_json).join("\n"), success_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("Exact HEAD evidence is unknown")
          expect(error.message).to include("malformed")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "fails closed when exact-HEAD legacy status evidence has a malformed ID" do
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Legacy CI"]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha: walked_back_sha, allow_override: false, dry_run: false)
          .and_return([])
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [])
        success_status = instance_double(Process::Status, success?: true)
        malformed_status = { "id" => "7-junk", "context" => "Legacy CI", "state" => "success" }
        allow(Open3).to receive(:capture2e)
          .with(
            "gh", "api", "--paginate", "--jq", CI_STATUSES_JSONL_QUERY,
            "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/status"
          )
          .and_return([malformed_status.to_json, success_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("Exact HEAD evidence is unknown")
          expect(error.message).to include("malformed")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "fails closed when a newer exact-HEAD legacy status lacks created_at" do
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Legacy CI"]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha: walked_back_sha, allow_override: false, dry_run: false)
          .and_return([])
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [])
        success_status = instance_double(Process::Status, success?: true)
        statuses = [
          { "id" => 1, "context" => "Legacy CI", "state" => "success", "created_at" => "2026-07-13T00:00:00Z" },
          { "id" => 2, "context" => "Legacy CI", "state" => "failure" }
        ]
        allow(Open3).to receive(:capture2e)
          .with(
            "gh", "api", "--paginate", "--jq", CI_STATUSES_JSONL_QUERY,
            "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/status"
          )
          .and_return([[
            [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, statuses_envelope(exact_head_sha)],
            *statuses.map { |status| [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, status] }
          ].map(&:to_json).join("\n"), success_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("Exact HEAD evidence is unknown")
          expect(error.message).to include("malformed")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "keeps the newer exact-HEAD legacy status failure when offsets differ" do
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Legacy CI"]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha: walked_back_sha, allow_override: false, dry_run: false)
          .and_return([])
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [])
        success_status = instance_double(Process::Status, success?: true)
        statuses = [
          {
            "id" => 1, "context" => "Legacy CI", "state" => "success",
            "created_at" => "2026-07-13T10:00:00+10:00"
          },
          {
            "id" => 2, "context" => "Legacy CI", "state" => "failure",
            "created_at" => "2026-07-13T01:00:00Z"
          }
        ]
        allow(Open3).to receive(:capture2e)
          .with(
            "gh", "api", "--paginate", "--jq", CI_STATUSES_JSONL_QUERY,
            "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/status"
          )
          .and_return([[
            [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, statuses_envelope(exact_head_sha)],
            *statuses.map { |status| [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, status] }
          ].map(&:to_json).join("\n"), success_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("Exact HEAD #{exact_head_sha} has failing CI evidence")
          expect(error.message).to include("Legacy CI")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "fails closed when the exact-HEAD statuses envelope is malformed" do
        expected_statuses_query = CI_STATUSES_JSONL_QUERY
        statuses_query = nil
        success_status = instance_double(Process::Status, success?: true)
        failure_status = instance_double(Process::Status, success?: false)
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Legacy CI"]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha: walked_back_sha, allow_override: false, dry_run: false)
          .and_return([])
        allow(Open3).to receive(:capture2e) do |*args|
          jq_query = args[4]
          case args[5]
          when "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/check-runs"
            output = [
              [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
              [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, passing_run("Legacy CI").merge("head_sha" => exact_head_sha)]
            ].map(&:to_json).join("\n")
            [output, success_status]
          when "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/status"
            statuses_query = jq_query
            jq_query == expected_statuses_query ? ["jq: expected status object", failure_status] : ["", success_status]
          else
            raise "Unexpected GitHub API request: #{args.inspect}"
          end
        end

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("Exact HEAD evidence is unknown")
          expect(error.message).to include("Statuses API")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
        expect(statuses_query).to eq(expected_statuses_query)
      end

      it "rejects a malformed exact-HEAD check-runs envelope before flattening" do
        expected_check_runs_query = CI_CHECK_RUNS_JSONL_QUERY
        check_runs_query = nil
        success_status = instance_double(Process::Status, success?: true)
        failure_status = instance_double(Process::Status, success?: false)
        allow(Open3).to receive(:capture2e) do |*args|
          check_runs_query = args[4]
          if check_runs_query == expected_check_runs_query
            ["jq: expected check_runs array", failure_status]
          else
            ["", success_status]
          end
        end

        result = fetch_ci_check_runs_for_sha(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)

        expect(result[:error]).to include("Checks API")
        expect(check_runs_query).to eq(expected_check_runs_query)
      end

      it "keeps valid empty exact-HEAD API envelopes known empty" do
        success_status = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture2e) do |*args|
          envelope = if args.last.end_with?("/check-runs")
                       "check_runs"
                     else
                       statuses_envelope(exact_head_sha)
                     end
          [[CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, envelope].to_json, success_status]
        end

        expect(fetch_ci_check_runs_for_sha(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha))
          .to eq(check_runs: [])
        expect(fetch_ci_statuses_for_sha(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha))
          .to eq(statuses: [])
        expect(Open3).to have_received(:capture2e)
          .with(
            "gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
            "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/check-runs"
          )
        expect(Open3).to have_received(:capture2e)
          .with(
            "gh", "api", "--paginate", "--jq", CI_STATUSES_JSONL_QUERY,
            "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/status"
          )
      end

      it "accepts documented legacy status items without an item SHA when the response envelope matches" do
        success_status = instance_double(Process::Status, success?: true)
        documented_status = {
          "id" => 7,
          "context" => "Legacy CI",
          "state" => "success",
          "created_at" => "2026-07-13T00:00:00Z"
        }
        output = [
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, { "name" => "statuses", "sha" => exact_head_sha }],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, documented_status]
        ].map(&:to_json).join("\n")
        allow(Open3).to receive(:capture2e)
          .with(
            "gh", "api", "--paginate", "--jq", CI_STATUSES_JSONL_QUERY,
            "repos/shakacode/react_on_rails/commits/#{exact_head_sha}/status"
          )
          .and_return([output, success_status])

        expect(fetch_ci_statuses_for_sha(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha))
          .to eq(statuses: [documented_status])
      end

      it "fails closed when a combined-status response envelope is missing or mismatches the requested SHA" do
        success_status = instance_double(Process::Status, success?: true)
        documented_status = {
          "id" => 7,
          "context" => "Legacy CI",
          "state" => "success",
          "created_at" => "2026-07-13T00:00:00Z"
        }

        [{ "name" => "statuses" }, statuses_envelope("different-sha")].each do |envelope|
          output = [
            [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, envelope],
            [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, documented_status]
          ].map(&:to_json).join("\n")
          allow(Open3).to receive(:capture2e).and_return([output, success_status])

          expect(fetch_ci_statuses_for_sha(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)[:error])
            .to include("malformed")
        end
      end

      it "fails closed when a later combined-status page mismatches the requested SHA" do
        success_status = instance_double(Process::Status, success?: true)
        documented_status = {
          "id" => 7,
          "context" => "Legacy CI",
          "state" => "success",
          "created_at" => "2026-07-13T00:00:00Z"
        }
        output = [
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, statuses_envelope(exact_head_sha)],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, documented_status],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, statuses_envelope("different-sha")]
        ].map(&:to_json).join("\n")
        allow(Open3).to receive(:capture2e).and_return([output, success_status])

        expect(fetch_ci_statuses_for_sha(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)[:error])
          .to include("malformed")
      end

      it "treats successful blank JSONL output as unknown evidence" do
        success_status = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture2e).and_return(["", success_status])

        expect(fetch_ci_check_runs_for_sha(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)[:error])
          .to include("malformed")
        expect(fetch_ci_statuses_for_sha(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)[:error])
          .to include("malformed")
      end

      it "keeps current-marker-like exact-HEAD payloads as item data for schema validation" do
        marker_like_failed_run = failing_run("Marker benchmark").merge(
          CI_JSONL_FRAME_KEY => CI_JSONL_ENVELOPE_FRAME
        )
        output = [
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, marker_like_failed_run]
        ].map(&:to_json).join("\n")

        items = validated_github_jsonl_items(
          output:,
          envelope_name: "check_runs",
          item_validator: method(:valid_ci_check_run?)
        )

        expect(items).to eq([marker_like_failed_run])
        expect(
          main_ci_status_evaluation(
            check_runs: items,
            legacy_status_runs: [],
            required_names: nil,
            is_prerelease: false,
            sha: exact_head_sha,
            ci_branch: "main"
          )[:kind]
        ).to eq(:failed)

        malformed_marker_like_run = { CI_JSONL_FRAME_KEY => CI_JSONL_ENVELOPE_FRAME }
        malformed_output = [
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, malformed_marker_like_run]
        ].map(&:to_json).join("\n")

        expect(
          validated_github_jsonl_items(
            output: malformed_output,
            envelope_name: "check_runs",
            item_validator: method(:valid_ci_check_run?)
          )
        ).to be_nil
      end

      it "keeps the strict exact-HEAD command copy-pasteable during a dry run" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: true, ci_branch: "main")
          .and_return(walkback_without_ci_runs)
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [passing_run("Lint")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expected_output = [
          "⚠️ DRY RUN: CI evidence below would block a real release:",
          '^  RELEASE_CI_EVALUATE_HEAD=true bundle exec rake "release\\[17\\.0\\.0\\.rc\\.10\\]"$',
          "⚠️ DRY RUN: Real release remains blocked.",
          "⚠️ DRY RUN: DANGEROUS PRERELEASE-ONLY LAST RESORT",
          "RELEASE_CI_STATUS_OVERRIDE=true"
        ].join(".*")

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: true,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to output(Regexp.new(expected_output, Regexp::MULTILINE)).to_stdout
      end

      it "withholds strict exact-HEAD guidance without a resolved target version" do
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [passing_run("Lint")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("resolved release version is unavailable")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "fails closed when required-check discovery is unknown" do
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
        expect(self).not_to receive(:fetch_ci_check_runs_for_sha)

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("Required CI check discovery is unknown")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "inspects exact HEAD when a prerelease walked-back SHA has only advisory checks" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(walkback_without_ci_runs.merge(check_runs: [passing_run("Change detector")]))
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint")]))
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [passing_run("Lint")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit, /RELEASE_CI_EVALUATE_HEAD=true bundle exec rake "release\[17\.0\.0\.rc\.10\]"/)
      end

      it "tells the operator to wait for pending exact-HEAD checks without recommending strict HEAD" do
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [in_progress_run("Slow test")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to match(%r{Exact HEAD.*pending.*Wait.*Slow test.*https://github\.com}m)
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "keeps failed exact-HEAD checks blocking without recommending strict HEAD" do
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [failing_run("JS unit tests")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to match(%r{Exact HEAD.*failing.*JS unit tests.*https://github\.com}m)
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "fails closed when neither walked-back SHA nor exact HEAD has CI evidence" do
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to match(
            /Exact HEAD.*does not provide complete healthy CI evidence.*No CI check runs visible/m
          )
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "fails closed when exact-HEAD CI evidence cannot be queried" do
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(error: "❌ Unable to query GitHub Checks API for #{exact_head_sha}.")

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: false,
            allow_override: false,
            dry_run: false
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to match(/Exact HEAD evidence is unknown.*Unable to query GitHub Checks API/m)
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "keeps unrelated failed exact-HEAD checks blocking for prerelease recovery" do
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint")]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha: walked_back_sha, allow_override: false, dry_run: false)
          .and_return([])
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [passing_run("Lint"), failing_run("Advisory benchmark")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to match(/Exact HEAD.*failing CI evidence.*Advisory benchmark/m)
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "keeps unrelated pending exact-HEAD checks blocking for prerelease recovery" do
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint")]))
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [passing_run("Lint"), in_progress_run("Benchmark")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to match(/Exact HEAD.*pending CI evidence.*Benchmark/m)
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
      end

      it "fetches raw walked-back legacy statuses for app-pinned recovery evidence" do
        pending_status = {
          "id" => 1,
          "context" => "Advisory",
          "state" => "pending",
          "created_at" => "2026-07-13T00:00:00Z"
        }
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint", app_id: 123)]))
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: false, ci_branch: "main")
          .and_return(walkback_without_ci_runs.merge(check_runs: [passing_run("Advisory")]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha: walked_back_sha, allow_override: false, dry_run: false)
          .and_return([pending_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to include("No required CI check runs found")
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
        expect(self).to have_received(:fetch_main_commit_statuses)
      end

      it "fetches raw exact-HEAD legacy statuses for app-pinned recovery evidence" do
        failed_status = {
          "id" => 1,
          "context" => "Advisory",
          "state" => "failure",
          "created_at" => "2026-07-13T00:00:00Z"
        }
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(checks: [required_check("Lint", app_id: 123)]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha: walked_back_sha, allow_override: false, dry_run: false)
          .and_return([])
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [passing_run("Lint", app_id: 123)])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [failed_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit) { |error|
          expect(error.message).to match(/Exact HEAD.*failing CI evidence.*Advisory/m)
          expect(error.message).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        }
        expect(self).to have_received(:fetch_ci_statuses_for_sha)
      end

      it "uses legacy required-status evidence for exact HEAD" do
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Legacy CI"]))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha: walked_back_sha, allow_override: false, dry_run: false)
          .and_return([])
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [])
        successful_status = {
          "id" => 7,
          "context" => "Legacy CI",
          "state" => "success",
          "created_at" => "2026-07-13T00:00:00Z"
        }
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [successful_status])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: false,
            target_gem_version: "17.0.0.rc.10"
          )
        end.to raise_error(SystemExit, /RELEASE_CI_EVALUATE_HEAD=true bundle exec rake "release\[17\.0\.0\.rc\.10\]"/)
      end
    end

    context "when override is set on a failing prerelease" do
      it "warns and returns instead of aborting" do
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: true, dry_run: false, ci_branch: "main")
          .and_return(sha:, check_runs: [failing_run("Lint")])

        expect do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
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
        end.to output(%r{DRY RUN: CI evidence below.*CI on origin/main is not healthy.*Lint}m).to_stdout
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
        end.to output(%r{DRY RUN: CI evidence below.*CI on origin/main is not healthy.*Lint}m).to_stdout
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

      it "withholds strict exact-HEAD guidance when walked-back legacy status evidence is unknown in dry-run" do
        exact_head_sha = "head5678"
        allow(self).to receive(:fetch_main_ci_checks)
          .with(monorepo_root:, allow_override: false, dry_run: true, ci_branch: "main")
          .and_return(
            sha:,
            head_sha: exact_head_sha,
            repo_slug: "shakacode/react_on_rails",
            check_runs: []
          )
        allow(self).to receive(:required_check_names_for_branch)
          .with(monorepo_root:, repo_slug: "shakacode/react_on_rails", ci_branch: "main")
          .and_return(required_checks(contexts: ["Travis"], checks: []))
        allow(self).to receive(:fetch_main_commit_statuses)
          .with(repo_slug: "shakacode/react_on_rails", sha:, allow_override: false, dry_run: true)
          .and_return(nil)
        allow(self).to receive(:fetch_ci_check_runs_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(check_runs: [passing_run("Lint")])
        allow(self).to receive(:fetch_ci_statuses_for_sha)
          .with(repo_slug: "shakacode/react_on_rails", sha: exact_head_sha)
          .and_return(statuses: [{ "id" => 1, "context" => "Travis", "state" => "success" }])

        output = capture_stdout do
          validate_main_ci_status!(
            monorepo_root:,
            is_prerelease: true,
            allow_override: false,
            dry_run: true,
            target_gem_version: "17.0.0.rc.10"
          )
        end

        expect(output).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
        expect(self).not_to have_received(:fetch_ci_check_runs_for_sha)
        expect(self).not_to have_received(:fetch_ci_statuses_for_sha)
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

  describe "CI JSONL framing queries" do
    def run_ci_jsonl_query(query, pages)
      pages.flat_map do |page|
        output, status = Open3.capture2e("jq", "-c", query, stdin_data: page.to_json)
        expect(status.success?).to be(true), "jq framing query failed: #{output}"

        output.lines.map { |line| JSON.parse(line) }
      end
    rescue Errno::ENOENT
      raise "jq is required to verify the release CI JSONL framing boundary"
    end

    it "frames every raw check run in page order, including failures and empty pages" do
      first_page = {
        "check_runs" => [
          { "id" => 1, "name" => "Lint", "status" => "completed", "conclusion" => "success" },
          { "id" => 2, "name" => "Benchmark", "status" => "completed", "conclusion" => "failure" }
        ]
      }
      second_page = { "check_runs" => [] }

      expect(run_ci_jsonl_query(CI_CHECK_RUNS_JSONL_QUERY, [first_page, second_page])).to eq(
        [
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, first_page["check_runs"][0]],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, first_page["check_runs"][1]],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"]
        ]
      )
    end

    it "keeps current-marker-like raw check-run data inside exactly one item frame" do
      marker_like_run = {
        "id" => 3,
        "name" => "Marker benchmark",
        "status" => "completed",
        "conclusion" => "failure",
        CI_JSONL_FRAME_KEY => CI_JSONL_ENVELOPE_FRAME
      }
      raw_page = { "check_runs" => [marker_like_run] }

      expect(run_ci_jsonl_query(CI_CHECK_RUNS_JSONL_QUERY, [raw_page])).to eq(
        [
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, marker_like_run]
        ]
      )
    end

    it "frames every raw legacy status in page order, including pending statuses and empty pages" do
      response_sha = "head5678"
      first_page = {
        "sha" => response_sha,
        "statuses" => [
          { "id" => 1, "context" => "Legacy CI", "state" => "success" },
          { "id" => 2, "context" => "Advisory", "state" => "pending" }
        ]
      }
      second_page = { "sha" => response_sha, "statuses" => [] }

      expect(run_ci_jsonl_query(CI_STATUSES_JSONL_QUERY, [first_page, second_page])).to eq(
        [
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, { "name" => "statuses", "sha" => response_sha }],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, first_page["statuses"][0]],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, first_page["statuses"][1]],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, { "name" => "statuses", "sha" => response_sha }]
        ]
      )
    end

    it "rejects malformed raw response envelopes" do
      expect do
        run_ci_jsonl_query(CI_CHECK_RUNS_JSONL_QUERY, [{ "check_runs" => nil }])
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected check_runs array/)

      malformed_status_pages = [
        { "statuses" => [] },
        { "sha" => " ", "statuses" => [] },
        { "sha" => "head5678", "statuses" => {} }
      ]
      malformed_status_pages.each do |page|
        expect do
          run_ci_jsonl_query(CI_STATUSES_JSONL_QUERY, [page])
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          /expected status object with sha and statuses array/
        )
      end
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

    def release_branch_fetch_refspec
      "+refs/heads/release/17.0.0:refs/remotes/origin/release/17.0.0"
    end

    def stub_release_branch_refs(remote_sha:, local_sha:)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", release_branch_fetch_refspec, "--quiet")
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
        .with("gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
              "repos/shakacode/react_on_rails/commits/#{sha}/check-runs")
        .and_return([[
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
          *check_runs.map { |run| [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, run.merge("head_sha" => sha)] }
        ].map(&:to_json).join("\n"), success_status])
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
        .with("gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
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
        .with("gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
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
        .with("gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
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
        .with("gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
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
        [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
        [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, {
          "id" => 1, "name" => "Lint", "status" => "completed", "conclusion" => "success", "head_sha" => "abc1234def"
        }],
        [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
        [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, {
          "id" => 2, "name" => "Test", "status" => "completed", "conclusion" => "failure", "head_sha" => "abc1234def"
        }]
      ].map(&:to_json).join("\n")
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
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
        .with("git", "-C", monorepo_root, "fetch", "origin", release_branch_fetch_refspec, "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/release/17.0.0")
        .and_return(["rcsha123\n", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["rcsha123\n", success_status])
      allow(self).to receive(:github_repo_slug).with(monorepo_root).and_return("shakacode/react_on_rails")
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--paginate", "--jq", CI_CHECK_RUNS_JSONL_QUERY,
              "repos/shakacode/react_on_rails/commits/rcsha123/check-runs")
        .and_return([[
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, {
            "id" => 1, "name" => "Lint", "status" => "completed", "conclusion" => "success", "head_sha" => "rcsha123"
          }]
        ].map(&:to_json).join("\n"), success_status])

      result = fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0")
      expect(result[:sha]).to eq("rcsha123")
      expect(result[:check_runs].first["name"]).to eq("Lint")
    end

    it "aborts when the local release branch is ahead of the fetched remote branch" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", release_branch_fetch_refspec, "--quiet")
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
        .with("git", "-C", monorepo_root, "fetch", "origin", release_branch_fetch_refspec, "--quiet")
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

    it "does not let the CI override bypass release branch HEAD mismatches" do
      stub_release_branch_refs(remote_sha: "remote123", local_sha: "local456")

      expect do
        fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0", allow_override: true)
      end.to raise_error(SystemExit, %r{Local HEAD does not match origin/release/17.0.0})
    end

    it "continues querying CI after a release branch HEAD mismatch in dry-run mode" do
      stub_release_branch_refs(remote_sha: "remote123", local_sha: "local456")
      stub_check_runs_for_sha(
        sha: "remote123",
        check_runs: [{ "id" => 1, "name" => "Lint", "status" => "completed", "conclusion" => "success" }]
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
        .with("git", "-C", monorepo_root, "fetch", "origin", release_branch_fetch_refspec, "--quiet")
        .and_return(["fetch failed: network down", failure_status])

      expect do
        fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0")
      end.to raise_error(SystemExit, %r{Unable to fetch origin/release/17.0.0})
    end

    it "does not let the CI override bypass release branch fetch failures" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", release_branch_fetch_refspec, "--quiet")
        .and_return(["fetch failed: network down", failure_status])

      expect do
        fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0", allow_override: true)
      end.to raise_error(SystemExit, %r{Unable to fetch origin/release/17.0.0})
    end

    it "does not let the CI override bypass release branch remote HEAD resolution failures" do
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "fetch", "origin", release_branch_fetch_refspec, "--quiet")
        .and_return(["", success_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "origin/release/17.0.0")
        .and_return(["fatal: ambiguous argument origin/release/17.0.0\n", failure_status])

      expect do
        fetch_main_ci_checks(monorepo_root:, ci_branch: "release/17.0.0", allow_override: true)
      end.to raise_error(SystemExit, %r{Unable to resolve origin/release/17.0.0 HEAD})
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

      expect(self).not_to receive(:release_finalization_metadata_commit?)
      expect(self).not_to receive(:git_parent_sha)
      expect(main_ci_evaluation_sha(monorepo_root:, head_sha: "head")).to eq("head")
    end

    it "walks back one commit past a changelog/docs-only HEAD" do
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "head").and_return(true)
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "parent").and_return(false)
      allow(self).to receive(:release_finalization_metadata_commit?)
        .with(monorepo_root:, sha: "parent").and_return(false)
      allow(self).to receive(:git_parent_sha)
        .with(monorepo_root:, sha: "head").and_return("parent")

      result = nil
      expect { result = main_ci_evaluation_sha(monorepo_root:, head_sha: "head") }
        .to output(/Evaluating CI on parent/).to_stdout
      expect(result).to eq("parent")
    end

    it "does not recommend strict HEAD evaluation before exact-HEAD evidence is inspected" do
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "head").and_return(true)
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "parent").and_return(false)
      allow(self).to receive(:release_finalization_metadata_commit?)
        .with(monorepo_root:, sha: "parent").and_return(false)
      allow(self).to receive(:git_parent_sha)
        .with(monorepo_root:, sha: "head").and_return("parent")

      output = capture_stdout do
        main_ci_evaluation_sha(monorepo_root:, head_sha: "head")
      end

      expect(output).not_to include("RELEASE_CI_EVALUATE_HEAD=true")
      expect(output).to include(
        "Strict exact-HEAD recovery is offered only after exact-HEAD CI evidence is complete and healthy."
      )
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

    it "walks back over final release metadata on release branches" do
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "head").and_return(false)
      allow(self).to receive(:release_finalization_metadata_commit?)
        .with(monorepo_root:, sha: "head").and_return(true)
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "parent").and_return(false)
      allow(self).to receive(:release_finalization_metadata_commit?)
        .with(monorepo_root:, sha: "parent").and_return(false)
      allow(self).to receive(:git_parent_sha)
        .with(monorepo_root:, sha: "head").and_return("parent")

      result = nil
      expect do
        result = main_ci_evaluation_sha(monorepo_root:, head_sha: "head", ref: "origin/release/17.0.0")
      end.to output(/Skipped 1 release-gate commit\(s\): head.*Evaluating CI on parent/m).to_stdout
      expect(result).to eq("parent")
    end

    it "walks back over a chain of consecutive non-runtime-only commits" do
      runtime = { "c0" => true, "c1" => true, "c2" => true, "c3" => false }
      parents = { "c0" => "c1", "c1" => "c2", "c2" => "c3" }
      allow(self).to receive(:commit_non_runtime_only?) { |**kwargs| runtime.fetch(kwargs[:sha]) }
      allow(self).to receive(:git_parent_sha) { |**kwargs| parents[kwargs[:sha]] }

      result = nil
      expect { result = main_ci_evaluation_sha(monorepo_root:, head_sha: "c0") }
        .to output(/Skipped 3 release-gate commit\(s\): c0, c1, c2/).to_stdout
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
        .to output(/Skipped #{MAIN_CI_NONRUNTIME_WALK_LIMIT} release-gate/o).to_stdout
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

    it "keeps workspace package metadata paths in sync with package manifests" do
      repo_root = File.expand_path("../../..", __dir__)
      package_paths = Dir.glob(File.join(repo_root, "packages", "*", "package.json")).map do |path|
        path.delete_prefix("#{repo_root}/")
      end

      expect(package_paths).not_to be_empty
      expect(RELEASE_FINALIZATION_METADATA_PATHS).to include(*package_paths)
    end

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

    it "raises for allowlisted metadata paths without a content handler" do
      path = "internal/release-metadata.txt"
      stub_const("RELEASE_FINALIZATION_METADATA_PATHS", RELEASE_FINALIZATION_METADATA_PATHS + [path])
      stub_metadata_changes(sha: "unhandledsha", output: "M\t#{path}\n")
      stub_metadata_file(sha: "unhandledsha", path:, before: "17.0.0.rc.5\n", after: "17.0.0\n")

      expect do
        release_finalization_metadata_commit?(monorepo_root:, sha: "unhandledsha")
      end.to raise_error(
        UnhandledReleaseFinalizationMetadataPathError,
        %r{Unhandled release finalization metadata path type.*internal/release-metadata\.txt}
      )
    end

    it "rejects empty diffs and git failures" do
      stub_metadata_changes(sha: "emptysha", output: "")
      expect(release_finalization_metadata_commit?(monorepo_root:, sha: "emptysha")).to be false

      stub_metadata_changes(sha: "badsha", output: "fatal: bad revision", status: failure_status)
      expect(release_finalization_metadata_commit?(monorepo_root:, sha: "badsha")).to be false
    end

    it "warns and treats raised inspection errors as runtime-bearing" do
      allow(Open3).to receive(:capture2e).and_raise(Errno::ENOENT, "git")

      result = nil
      expect do
        result = release_finalization_metadata_commit?(monorepo_root:, sha: "raisingsha")
      end.to output(/Unable to inspect release finalization metadata.*raisingsha.*runtime-bearing/).to_stderr
      expect(result).to be false
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

  describe "#gh_included_json_response" do
    it "rejects mixed newline framing and HTTP control bytes" do
      mixed_newlines = "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\n\n" \
                       '{"message":"Branch not protected"}'
      nul_header = "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\u0000\r\n\r\n" \
                   '{"message":"Branch not protected"}'

      expect(gh_included_json_response(mixed_newlines)).to be_nil
      expect(gh_included_json_response(nul_header)).to be_nil
    end

    it "returns nil instead of raising for invalid or incompatible response encodings" do
      response = "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\r\n\r\n" \
                 '{"message":"Branch not protected"}'
      invalid_utf8 = "#{response}\xFF".b.force_encoding(Encoding::UTF_8)
      incompatible_encoding = response.encode(Encoding::UTF_16LE)

      [invalid_utf8, incompatible_encoding].each do |output|
        parsed = nil
        expect { parsed = gh_included_json_response(output) }.not_to raise_error
        expect(parsed).to be_nil
      end
    end
  end

  describe "#validated_github_jsonl_items" do
    it "returns nil instead of raising for invalid or incompatible evidence encodings" do
      output = [
        [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
        [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, {
          "id" => 1, "name" => "Lint", "status" => "completed", "conclusion" => "success"
        }]
      ].map(&:to_json).join("\n")
      invalid_utf8 = "#{output}\xFF".b.force_encoding(Encoding::UTF_8)
      incompatible_encoding = output.encode(Encoding::UTF_16LE)

      [invalid_utf8, incompatible_encoding].each do |evidence|
        items = nil
        expect do
          items = validated_github_jsonl_items(
            output: evidence,
            envelope_name: "check_runs",
            item_validator: method(:valid_ci_check_run?)
          )
        end.not_to raise_error
        expect(items).to be_nil
      end
    end

    it "rejects item frames before the expected envelope" do
      run = { "id" => 1, "name" => "Lint", "status" => "completed", "conclusion" => "success" }
      output = [
        [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, run],
        [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
        [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, run.merge("id" => 2)]
      ].map(&:to_json).join("\n")

      expect(
        validated_github_jsonl_items(
          output:,
          envelope_name: "check_runs",
          item_validator: method(:valid_ci_check_run?)
        )
      ).to be_nil
    end

    it "requires exact SHA matches and positive GitHub identities for raw CI evidence" do
      requested_sha = "head5678"
      check_run = {
        "id" => 1,
        "name" => "Lint",
        "status" => "completed",
        "conclusion" => "success",
        "head_sha" => requested_sha,
        "app" => { "id" => 2 },
        "check_suite" => { "id" => 3 }
      }
      status = {
        "id" => 4,
        "context" => "Legacy CI",
        "state" => "success",
        "created_at" => "2026-07-13T00:00:00Z"
      }

      [
        check_run.merge("head_sha" => "other"),
        check_run.merge("id" => 0),
        check_run.merge("check_suite" => { "id" => 0 }),
        check_run.merge("app" => { "id" => 0 })
      ].each do |run|
        output = [
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, "check_runs"],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, run]
        ].map(&:to_json).join("\n")

        expect(
          validated_github_jsonl_items(
            output:,
            envelope_name: "check_runs",
            item_validator: ->(item) { valid_ci_check_run?(item, sha: requested_sha) }
          )
        ).to be_nil
      end

      [status.merge("id" => 0)].each do |legacy_status|
        output = [
          [CI_JSONL_FRAME_KEY, CI_JSONL_ENVELOPE_FRAME, { "name" => "statuses", "sha" => requested_sha }],
          [CI_JSONL_FRAME_KEY, CI_JSONL_ITEM_FRAME, legacy_status]
        ].map(&:to_json).join("\n")

        expect(
          validated_github_jsonl_items(
            output:,
            envelope_name: "statuses",
            envelope_validator: ->(envelope) { valid_ci_statuses_envelope?(envelope, sha: requested_sha) },
            item_validator: method(:valid_ci_status?)
          )
        ).to be_nil
      end
    end
  end

  describe "#required_check_names_for_branch" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }
    let(:expected_jq) { "{contexts, checks}" }

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

    it "returns an unknown discovery state for an authentication or scope failure" do
      api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              api_path)
        .and_return(["HTTP 403: insufficient token scope", failure_status])
      allow(Open3).to receive(:capture3)
        .with("gh", "api", "--include", api_path)
        .and_return([
                      "HTTP/2.0 403 Forbidden\r\nContent-Type: application/json\r\n\r\n" \
                      '{"message":"Resource not accessible by integration"}',
                      "gh: insufficient token scope\n",
                      failure_status
                    ])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns an unknown discovery state for an unrelated not-found response" do
      api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq, api_path)
        .and_return(["HTTP 404: Not Found", failure_status])
      allow(Open3).to receive(:capture3)
        .with("gh", "api", "--include", api_path)
        .and_return([
                      "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\r\n\r\n" \
                      '{"message":"Not Found"}',
                      "gh: Not Found\n",
                      failure_status
                    ])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
      expect(Open3).not_to have_received(:capture2e).with(
        "gh", "api", "repos/shakacode/react_on_rails/branches/main"
      )
    end

    it "returns unknown when the unprotected-branch corroboration names a different branch" do
      api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
      branch_path = "repos/shakacode/react_on_rails/branches/main"
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq, api_path)
        .and_return(["HTTP 404: Branch not protected", failure_status])
      allow(Open3).to receive(:capture3)
        .with("gh", "api", "--include", api_path)
        .and_return([
                      "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\r\n\r\n" \
                      '{"message":"Branch not protected"}',
                      "gh: branch protection is not enabled for this branch\n",
                      failure_status
                    ])
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", branch_path)
        .and_return(['{"name":"release/17.0.0","protected":false}', success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns unknown when the unprotected-branch corroboration omits its name" do
      api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
      branch_path = "repos/shakacode/react_on_rails/branches/main"
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq, api_path)
        .and_return(["HTTP 404: Branch not protected", failure_status])
      allow(Open3).to receive(:capture3)
        .with("gh", "api", "--include", api_path)
        .and_return([
                      "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\r\n\r\n" \
                      '{"message":"Branch not protected"}',
                      "gh: branch protection is not enabled for this branch\n",
                      failure_status
                    ])
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", branch_path)
        .and_return(['{"protected":false}', success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns an unknown discovery state when failed response evidence is malformed" do
      api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq, api_path)
        .and_return(["HTTP 500: upstream failure", failure_status])
      allow(Open3).to receive(:capture3)
        .with("gh", "api", "--include", api_path)
        .and_return(["HTTP/2.0 500 Internal Server Error\r\n\r\nnot JSON", "gh: upstream failure\n", failure_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns unknown instead of accepting a malformed included response header" do
      api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
      branch_path = "repos/shakacode/react_on_rails/branches/main"
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq, api_path)
        .and_return(["HTTP 404: Branch not protected", failure_status])
      allow(Open3).to receive(:capture3)
        .with("gh", "api", "--include", api_path)
        .and_return([
                      "HTTP/2.0 404 Not Found\r\nnot-a-header\r\n\r\n" \
                      '{"message":"Branch not protected"}',
                      "gh: branch protection is not enabled for this branch\n",
                      failure_status
                    ])
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", branch_path)
        .and_return(['{"protected":false}', success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
      expect(Open3).not_to have_received(:capture2e).with("gh", "api", branch_path)
    end

    it "returns unknown instead of accepting contradictory included response statuses" do
      api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
      branch_path = "repos/shakacode/react_on_rails/branches/main"
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq, api_path)
        .and_return(["HTTP 404: Branch not protected", failure_status])
      allow(Open3).to receive(:capture3)
        .with("gh", "api", "--include", api_path)
        .and_return([
                      "HTTP/2.0 500 Internal Server Error\r\nContent-Type: application/json\r\n\r\n" \
                      '{"message":"Internal Server Error"}' \
                      "\r\n\r\nHTTP/2.0 404 Not Found\r\nContent-Type: application/json\r\n\r\n" \
                      '{"message":"Branch not protected"}',
                      "gh: branch protection is not enabled for this branch\n",
                      failure_status
                    ])
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", branch_path)
        .and_return(['{"protected":false}', success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
      expect(Open3).not_to have_received(:capture2e).with("gh", "api", branch_path)
    end

    it "returns unknown instead of accepting a contradictory included status header" do
      api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
      branch_path = "repos/shakacode/react_on_rails/branches/main"
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq, api_path)
        .and_return(["HTTP 404: Branch not protected", failure_status])
      allow(Open3).to receive(:capture3)
        .with("gh", "api", "--include", api_path)
        .and_return([
                      "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\r\nStatus: 500\r\n\r\n" \
                      '{"message":"Branch not protected"}',
                      "gh: branch protection is not enabled for this branch\n",
                      failure_status
                    ])
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", branch_path)
        .and_return(['{"protected":false}', success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
      expect(Open3).not_to have_received(:capture2e).with("gh", "api", branch_path)
    end

    it "returns unknown instead of raising for a non-object included response body" do
      api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq, api_path)
        .and_return(["HTTP 404: Branch not protected", failure_status])
      allow(Open3).to receive(:capture3)
        .with("gh", "api", "--include", api_path)
        .and_return([
                      "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\r\n\r\n[]",
                      "gh: branch protection is not enabled for this branch\n",
                      failure_status
                    ])

      expect { required_check_names_for_branch(monorepo_root:) }
        .not_to raise_error
      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns unknown for trailing content after the included JSON response body" do
      api_path = "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks"
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq, api_path)
        .and_return(["HTTP 404: Branch not protected", failure_status])
      allow(Open3).to receive(:capture3)
        .with("gh", "api", "--include", api_path)
        .and_return([
                      "HTTP/2.0 404 Not Found\r\nContent-Type: application/json\r\n\r\n" \
                      '{"message":"Branch not protected"}\ntrailing content',
                      "gh: branch protection is not enabled for this branch\n",
                      failure_status
                    ])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns an unknown discovery state when the branch protection response is malformed" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return(["not valid JSON", success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "keeps nullable or missing branch protection fields visible to fail closed" do
      # `{contexts, checks}` renders missing fields as null, which must remain
      # distinguishable from a configured pair of empty arrays.
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", "{contexts, checks}",
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([{ contexts: nil, checks: nil }.to_json, success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns an unknown discovery state when the branch protection payload is not an object" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([[].to_json, success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns an unknown discovery state when branch protection fields are not arrays" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([{ contexts: [], checks: {} }.to_json, success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns an unknown discovery state when a required check entry is malformed" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([{ contexts: [], checks: [{ context: nil, app_id: 123 }] }.to_json, success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns an unknown discovery state when a modern check omits app_id" do
      allow(Open3).to receive(:capture2e)
        .with("gh", "api", "--jq", expected_jq,
              "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
        .and_return([{ contexts: [], checks: [{ context: "Lint" }] }.to_json, success_status])

      expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
    end

    it "returns an unknown discovery state when a modern check has a nonpositive app_id" do
      [0, -2].each do |app_id|
        allow(Open3).to receive(:capture2e)
          .with("gh", "api", "--jq", expected_jq,
                "repos/shakacode/react_on_rails/branches/main/protection/required_status_checks")
          .and_return([{ contexts: [], checks: [{ context: "Lint", app_id: }] }.to_json, success_status])

        expect(required_check_names_for_branch(monorepo_root:)).to equal(REQUIRED_CHECK_DISCOVERY_UNKNOWN)
      end
    end

    it "returns nil for a structurally valid empty protection configuration" do
      # Newer branch protection rules can return `contexts: []` with the real required
      # names in `checks`. With both fields present and empty, treat this as "no
      # protection visible" and let the caller evaluate every check run.
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

  describe "#stable_release_retry_for_current_head?" do
    let(:monorepo_root) { "/tmp/repo" }

    it "does not inspect tags before the checkout is already on the target version" do
      expect(self).not_to receive(:current_git_sha!)

      expect(
        stable_release_retry_for_current_head?(
          monorepo_root:,
          current_branch: "main",
          current_checkout_version: "16.9.0",
          target_gem_version: "17.0.0"
        )
      ).to be(false)
    end

    it "allows a main release retry when the remote stable tag points at HEAD" do
      allow(self).to receive(:current_git_sha!)
        .with(monorepo_root, context: "stable release retry")
        .and_return("headsha")
      allow(self).to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0")
        .and_return(true)
      allow(self).to receive(:peeled_git_tag_sha)
        .with(monorepo_root:, tag: "v17.0.0")
        .and_return(nil, "headsha")
      allow(self).to receive(:fetch_remote_release_tag!)
        .with(monorepo_root:, tag: "v17.0.0", tag_type: "stable")

      expect do
        expect(
          stable_release_retry_for_current_head?(
            monorepo_root:,
            current_branch: "main",
            current_checkout_version: "17.0.0",
            target_gem_version: "17.0.0"
          )
        ).to be(true)
      end.to output(/Stable tag v17\.0\.0 already points at local HEAD/).to_stdout
    end

    it "does not trust a local-only stable tag at HEAD for idempotent retry" do
      allow(self).to receive(:current_git_sha!)
        .with(monorepo_root, context: "stable release retry")
        .and_return("headsha")
      allow(self).to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0")
        .and_return(false)
      allow(self).to receive(:peeled_git_tag_sha)
        .with(monorepo_root:, tag: "v17.0.0")
        .and_return("headsha")
      expect(self).not_to receive(:fetch_remote_release_tag!)

      expect(
        stable_release_retry_for_current_head?(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0",
          target_gem_version: "17.0.0"
        )
      ).to be(false)
    end

    it "reports a local-only stable tag at HEAD for version-policy retry" do
      allow(self).to receive(:current_git_sha!)
        .with(monorepo_root, context: "stable release retry")
        .and_return("headsha")
      allow(self).to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0")
        .and_return(false)
      allow(self).to receive(:peeled_git_tag_sha)
        .with(monorepo_root:, tag: "v17.0.0")
        .and_return("headsha")
      expect(self).not_to receive(:fetch_remote_release_tag!)

      retry_state = nil
      expect do
        retry_state = stable_release_retry_state_for_current_head(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0",
          target_gem_version: "17.0.0"
        )
      end.to output(/continuing retry without registry publish skips/).to_stdout
      expect(retry_state).to eq(:local)
      expect(remote_release_tag_retry?(retry_state)).to be(false)
      expect(release_tag_at_current_head?(retry_state)).to be(true)
    end

    it "allows a prerelease retry when the remote prerelease tag points at HEAD" do
      allow(self).to receive(:current_git_sha!)
        .with(monorepo_root, context: "prerelease release retry")
        .and_return("headsha")
      allow(self).to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0.rc.1")
        .and_return(true)
      allow(self).to receive(:peeled_git_tag_sha)
        .with(monorepo_root:, tag: "v17.0.0.rc.1")
        .and_return(nil, "headsha")
      allow(self).to receive(:fetch_remote_release_tag!)
        .with(monorepo_root:, tag: "v17.0.0.rc.1", tag_type: "prerelease")

      expect do
        expect(
          release_tag_retry_state_for_current_head(
            monorepo_root:,
            current_branch: "release/17.0.0",
            current_checkout_version: "17.0.0.rc.1",
            target_gem_version: "17.0.0.rc.1",
            tag_type: "prerelease"
          )
        ).to eq(:remote)
      end.to output(/Prerelease tag v17\.0\.0\.rc\.1 already points at local HEAD/).to_stdout
    end

    it "reports a local-only prerelease tag at HEAD without idempotent publish retry" do
      allow(self).to receive(:current_git_sha!)
        .with(monorepo_root, context: "prerelease release retry")
        .and_return("headsha")
      allow(self).to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0.rc.1")
        .and_return(false)
      allow(self).to receive(:peeled_git_tag_sha)
        .with(monorepo_root:, tag: "v17.0.0.rc.1")
        .and_return("headsha")
      expect(self).not_to receive(:fetch_remote_release_tag!)

      retry_state = nil
      expect do
        retry_state = release_tag_retry_state_for_current_head(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.1",
          target_gem_version: "17.0.0.rc.1",
          tag_type: "prerelease"
        )
      end.to output(/continuing retry without registry publish skips/).to_stdout
      expect(retry_state).to eq(:local)
      expect(remote_release_tag_retry?(retry_state)).to be(false)
      expect(release_tag_at_current_head?(retry_state)).to be(true)
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

  describe "#latest_remote_rc_tag_for_version" do
    %w[dotted-first dashed-first].each do |ordering|
      it "rejects equivalent dotted and dashed RC tag names when #{ordering.tr('-', ' ')}" do
        tags = %w[v17.0.0.rc.10 v17.0.0-rc.10]
        tags.reverse! if ordering == "dashed-first"
        allow(self).to receive(:remote_release_tags).and_return(tags)

        expect do
          latest_remote_rc_tag_for_version(monorepo_root: "/tmp/repo", target_gem_version: "17.0.0")
        end.to raise_error(SystemExit, /ambiguous remote RC tags.*v17\.0\.0[.-]rc\.10/mi)
      end
    end
  end

  describe "#ensure_release_branch_promotes_tagged_rc!" do
    let(:monorepo_root) { "/tmp/repo" }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }
    let(:not_ancestor_status) { instance_double(Process::Status, success?: false, exitstatus: 1) }
    let(:git_error_status) { instance_double(Process::Status, success?: false, exitstatus: 128) }
    let(:remote_rc_tag_ref) { "refs/tags/v17.0.0.rc.3" }
    let(:remote_stable_tag_ref) { "refs/tags/v17.0.0" }
    let(:remote_rc_tag_fetch_args) do
      ["git", "-C", monorepo_root, "fetch", "--force", "--no-tags", "--quiet",
       "origin", "#{remote_rc_tag_ref}:#{remote_rc_tag_ref}"]
    end
    let(:remote_stable_tag_fetch_args) do
      ["git", "-C", monorepo_root, "fetch", "--force", "--no-tags", "--quiet",
       "origin", "#{remote_stable_tag_ref}:#{remote_stable_tag_ref}"]
    end

    before do
      allow(self).to receive(:remote_git_tag_exists?).and_call_original
      allow(self).to receive(:remote_release_tags).and_return(["v17.0.0.rc.3"])
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

      expect(
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "main",
          current_checkout_version: "17.0.0",
          target_gem_version: "17.0.1"
        )
      ).to eq(stable_tag_retry: false, stable_tag_at_head: false)
    end

    %w[dotted-first dashed-first].product(%w[dotted dashed]).each do |ordering, provenance_alias|
      it "blocks first promotion when #{ordering.tr('-', ' ')} and #{provenance_alias} carries provenance" do
        tags = %w[v17.0.0.rc.10 v17.0.0-rc.10]
        tags.reverse! if ordering == "dashed-first"
        provenance_tag = provenance_alias == "dotted" ? "v17.0.0.rc.10" : "v17.0.0-rc.10"
        allow(self).to receive(:remote_release_tags).and_return(tags)
        allow(self).to receive(:remote_git_tag_exists?)
          .with(monorepo_root:, tag: "v17.0.0.rc.10")
          .and_return(true)
        allow(self).to receive_messages(
          fetch_remote_rc_tag!: nil,
          peeled_git_tag_sha: "headsha",
          current_git_sha!: "headsha"
        )
        allow(self).to receive(:accepted_accelerated_rc_record_for_release_branch_promotion!) do |rc_tag:, **|
          { "status" => "candidate-accepted" } if rc_tag == provenance_tag
        end

        expect do
          promotion = ensure_release_branch_promotes_tagged_rc!(
            monorepo_root:,
            current_branch: "release/17.0.0",
            current_checkout_version: "17.0.0.rc.10",
            target_gem_version: "17.0.0"
          )
          accepted_accelerated_rc_record_for_release_branch_promotion!(
            monorepo_root:,
            rc_tag: promotion.fetch(:rc_tag),
            final_head_sha: "headsha",
            tracker_input: "3823"
          )
        end.to raise_error(SystemExit, /ambiguous remote RC tags.*v17\.0\.0[.-]rc\.10/mi)
        expect(self).not_to have_received(:accepted_accelerated_rc_record_for_release_branch_promotion!)
      end
    end

    it "preserves a unique dashed RC tag identity through first final promotion" do
      allow(self).to receive(:remote_release_tags).and_return(["v17.0.0-rc.10"])
      allow(self).to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0-rc.10")
        .and_return(true)
      allow(self).to receive_messages(
        fetch_remote_rc_tag!: nil,
        peeled_git_tag_sha: "headsha",
        current_git_sha!: "headsha"
      )

      expect(
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0.rc.10",
          target_gem_version: "17.0.0"
        )
      ).to include(rc_tag: "v17.0.0-rc.10")
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
      allow(self).to receive(:release_finalization_metadata_touched)
        .with(monorepo_root:, sha: "changelogsha")
        .and_return(false)
      allow(self).to receive(:release_finalization_metadata_touched)
        .with(monorepo_root:, sha: "notessha")
        .and_return(false)

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
      allow(self).to receive(:release_finalization_metadata_touched)
        .with(monorepo_root:, sha: "versionbumpsha")
        .and_return(true)
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

    it "allows an already-bumped final release branch retry after metadata-only RC follow-ups" do
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
        .and_return(["changelogsha\n", success_status])
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "changelogsha")
        .and_return(true)
      allow(self).to receive(:release_finalization_metadata_touched)
        .with(monorepo_root:, sha: "changelogsha")
        .and_return(false)

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0",
          target_gem_version: "17.0.0"
        )
      end.to output(/metadata-only commit\(s\) after v17\.0\.0\.rc\.3/).to_stdout
    end

    it "aborts an already-bumped final release branch retry when HEAD has runtime commits after the RC" do
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
        .and_return(["runtimesha\n", success_status])
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "runtimesha")
        .and_return(false)
      allow(self).to receive(:release_finalization_metadata_touched)
        .with(monorepo_root:, sha: "runtimesha")
        .and_return(false)
      allow(self).to receive(:release_finalization_metadata_commit?)
        .with(monorepo_root:, sha: "runtimesha")
        .and_return(false)

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /Runtime-bearing commits require a new RC/)
    end

    it "allows an already-bumped final release branch retry when the stable tag points at HEAD" do
      stub_remote_rc_tag_fetch
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["headsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0^{}")
        .and_return(["", failure_status], ["headsha\n", success_status])
      allow(self)
        .to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0")
        .and_return(true)
      allow(Open3)
        .to receive(:capture2e)
        .with(*remote_stable_tag_fetch_args)
        .and_return(["", success_status])
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
        .with("git", "-C", monorepo_root, "merge-base", "--is-ancestor", "tagsha", "headsha")
        .and_return(["", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-list", "--reverse", "tagsha..headsha")
        .and_return(["versionbumpsha\n", success_status])
      allow(self).to receive(:commit_non_runtime_only?)
        .with(monorepo_root:, sha: "versionbumpsha")
        .and_return(false)
      allow(self).to receive(:release_finalization_metadata_touched)
        .with(monorepo_root:, sha: "versionbumpsha")
        .and_return(true)
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
      end.to output(/Stable tag v17\.0\.0 already points at local HEAD.*metadata-only commit\(s\)/m).to_stdout
    end

    it "aborts an already-bumped final release branch retry when the stable tag points elsewhere" do
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "HEAD")
        .and_return(["headsha\n", success_status])
      allow(Open3)
        .to receive(:capture2e)
        .with("git", "-C", monorepo_root, "rev-parse", "--verify", "--quiet", "refs/tags/v17.0.0^{}")
        .and_return(["stabletagsha\n", success_status])
      allow(self)
        .to receive(:remote_git_tag_exists?)
        .with(monorepo_root:, tag: "v17.0.0")
        .and_return(false)

      expect do
        ensure_release_branch_promotes_tagged_rc!(
          monorepo_root:,
          current_branch: "release/17.0.0",
          current_checkout_version: "17.0.0",
          target_gem_version: "17.0.0"
        )
      end.to raise_error(SystemExit, /already tagged at a different commit/)

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
      allow(self).to receive(:release_finalization_metadata_touched)
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

  describe "#rc_prerelease_version?" do
    it "is true for rc prereleases" do
      expect(rc_prerelease_version?("17.0.0.rc.0")).to be true
      expect(rc_prerelease_version?("17.0.0.rc.3")).to be true
    end

    it "is false for non-rc prereleases" do
      expect(rc_prerelease_version?("17.0.0.beta.1")).to be false
      expect(rc_prerelease_version?("17.0.0.alpha.2")).to be false
      expect(rc_prerelease_version?("17.0.0.pre.1")).to be false
    end

    it "is false for stable versions" do
      expect(rc_prerelease_version?("17.0.0")).to be false
    end
  end

  describe "#local_or_remote_branch_exists?" do
    def git!(dir, *args)
      _output, status = Open3.capture2e("git", "-C", dir, *args)
      raise "git #{args.join(' ')} failed" unless status.success?
    end

    def init_repo_with_commit(dir)
      git!(dir, "init", "--quiet")
      git!(dir, "config", "user.email", "test@example.com")
      git!(dir, "config", "user.name", "Test")
      git!(dir, "config", "commit.gpgsign", "false")
      File.write(File.join(dir, "README.md"), "seed\n")
      git!(dir, "add", "-A")
      git!(dir, "commit", "--quiet", "-m", "seed")
    end

    it "returns true when the branch exists locally" do
      Dir.mktmpdir do |dir|
        init_repo_with_commit(dir)
        git!(dir, "branch", "release/17.0.0")

        expect(local_or_remote_branch_exists?(monorepo_root: dir, branch: "release/17.0.0")).to be true
      end
    end

    it "returns true when the branch exists only on origin" do
      Dir.mktmpdir do |remote_dir|
        Dir.mktmpdir do |local_dir|
          init_repo_with_commit(remote_dir)
          git!(remote_dir, "branch", "release/17.0.0")

          git!(local_dir, "init", "--quiet")
          git!(local_dir, "remote", "add", "origin", remote_dir)
          git!(local_dir, "fetch", "--quiet", "origin")

          # The release branch is not a local head here, only on origin.
          expect(local_or_remote_branch_exists?(monorepo_root: local_dir, branch: "release/17.0.0")).to be true
        end
      end
    end

    it "returns false when the branch exists neither locally nor on origin" do
      Dir.mktmpdir do |remote_dir|
        Dir.mktmpdir do |local_dir|
          init_repo_with_commit(remote_dir)

          git!(local_dir, "init", "--quiet")
          git!(local_dir, "remote", "add", "origin", remote_dir)
          git!(local_dir, "fetch", "--quiet", "origin")

          expect(local_or_remote_branch_exists?(monorepo_root: local_dir, branch: "release/17.0.0")).to be false
        end
      end
    end

    it "treats a non-success local rev-parse (exit 1 = absent ref) as 'not local' and checks origin" do
      # `git rev-parse --verify --quiet` exits 1 for a well-formed missing ref, so
      # a non-success local result must fall through to the remote check, not abort.
      absent_local_status = instance_double(Process::Status, success?: false, exitstatus: 1)
      remote_hit_status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "rev-parse", "--verify", "--quiet", "refs/heads/release/17.0.0")
        .and_return(["", absent_local_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "ls-remote", "--exit-code", "--heads", "origin", "refs/heads/release/17.0.0")
        .and_return(["abc123\trefs/heads/release/17.0.0", remote_hit_status])

      expect(local_or_remote_branch_exists?(monorepo_root: "/tmp/repo", branch: "release/17.0.0")).to be true
    end

    it "aborts when the remote git check fails with an unexpected status" do
      absent_local_status = instance_double(Process::Status, success?: false, exitstatus: 1)
      unexpected_remote_status = instance_double(Process::Status, success?: false, exitstatus: 128)
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "rev-parse", "--verify", "--quiet", "refs/heads/release/17.0.0")
        .and_return(["", absent_local_status])
      allow(Open3).to receive(:capture2e)
        .with("git", "-C", "/tmp/repo", "ls-remote", "--exit-code", "--heads", "origin", "refs/heads/release/17.0.0")
        .and_return(["fatal: unable to connect to origin", unexpected_remote_status])

      expect do
        local_or_remote_branch_exists?(monorepo_root: "/tmp/repo", branch: "release/17.0.0")
      end.to raise_error(SystemExit, %r{Unable to verify whether branch "release/17.0.0" exists})
    end
  end

  describe "#maybe_offer_release_branch_cut!" do
    it "offers (prompts and creates) for an rc cut on main when the branch is missing" do
      allow(self).to receive(:local_or_remote_branch_exists?)
        .with(monorepo_root: "/tmp/repo", branch: "release/17.0.0")
        .and_return(false)
      allow($stdin).to receive_messages(tty?: true, gets: "y\n")
      allow(self).to receive(:start_release_line!)

      # On acceptance the offer runs the shared start helper and then `exit 0`
      # before any tagging; `exit 0` raises a catchable SystemExit.
      expect do
        expect do
          maybe_offer_release_branch_cut!(
            monorepo_root: "/tmp/repo",
            current_branch: "main",
            target_gem_version: "17.0.0.rc.0",
            dry_run: false
          )
        end.to raise_error(SystemExit) { |error| expect(error.status).to eq(0) }
      end.to output(%r{Start the 17.0.0 release line now\? \[y/N\]}).to_stdout

      expect(self).to have_received(:start_release_line!)
        .with(monorepo_root: "/tmp/repo", release_branch: "release/17.0.0", dry_run: false)
    end

    it "aborts without creating anything when the operator declines the prompt" do
      allow(self).to receive(:local_or_remote_branch_exists?)
        .with(monorepo_root: "/tmp/repo", branch: "release/17.0.0")
        .and_return(false)
      allow($stdin).to receive_messages(tty?: true, gets: "n\n")
      expect(self).not_to receive(:start_release_line!)

      expect do
        maybe_offer_release_branch_cut!(
          monorepo_root: "/tmp/repo",
          current_branch: "main",
          target_gem_version: "17.0.0.rc.0",
          dry_run: false
        )
      end.to raise_error(SystemExit, /No release branch was created/)
    end

    it "stops with the checkout-and-re-run guard when the release branch already exists" do
      allow(self).to receive(:local_or_remote_branch_exists?)
        .with(monorepo_root: "/tmp/repo", branch: "release/17.0.0")
        .and_return(true)
      expect(self).not_to receive(:start_release_line!)

      expect do
        maybe_offer_release_branch_cut!(
          monorepo_root: "/tmp/repo",
          current_branch: "main",
          target_gem_version: "17.0.0.rc.0",
          dry_run: false
        )
      end.to raise_error(SystemExit, %r{release/17.0.0 already exists.*git checkout release/17.0.0}m)
    end

    it "aborts with the manual recipe when stdin is not a TTY" do
      allow(self).to receive(:local_or_remote_branch_exists?)
        .with(monorepo_root: "/tmp/repo", branch: "release/17.0.0")
        .and_return(false)
      allow($stdin).to receive(:tty?).and_return(false)
      expect(self).not_to receive(:start_release_line!)

      expect do
        maybe_offer_release_branch_cut!(
          monorepo_root: "/tmp/repo",
          current_branch: "main",
          target_gem_version: "17.0.0.rc.0",
          dry_run: false
        )
      end.to raise_error(SystemExit, %r{without a terminal.*git checkout -b release/17.0.0 origin/main}m)
    end

    it "is a no-op for a non-rc target on main" do
      expect(self).not_to receive(:local_or_remote_branch_exists?)
      expect(self).not_to receive(:start_release_line!)

      expect do
        maybe_offer_release_branch_cut!(
          monorepo_root: "/tmp/repo",
          current_branch: "main",
          target_gem_version: "17.0.0",
          dry_run: false
        )
      end.not_to raise_error
    end

    it "is a no-op for an rc target when not on main" do
      expect(self).not_to receive(:local_or_remote_branch_exists?)
      expect(self).not_to receive(:start_release_line!)

      expect do
        maybe_offer_release_branch_cut!(
          monorepo_root: "/tmp/repo",
          current_branch: "release/17.0.0",
          target_gem_version: "17.0.0.rc.1",
          dry_run: false
        )
      end.not_to raise_error
    end

    it "prints the create plan during a dry run (branch missing) without prompting or creating" do
      allow(self).to receive(:local_or_remote_branch_exists?)
        .with(monorepo_root: "/tmp/repo", branch: "release/17.0.0")
        .and_return(false)
      expect(self).not_to receive(:start_release_line!)
      expect($stdin).not_to receive(:gets)

      expect do
        maybe_offer_release_branch_cut!(
          monorepo_root: "/tmp/repo",
          current_branch: "main",
          target_gem_version: "17.0.0.rc.0",
          dry_run: true
        )
      end.to output(%r{DRY RUN: would offer to create release/17.0.0}).to_stdout
    end

    it "reports the existence-guard stop during a dry run when the branch already exists" do
      # Dry-run must evaluate existence (read-only git) so the plan is honest:
      # an existing branch would stop the offer, not create a new line.
      allow(self).to receive(:local_or_remote_branch_exists?)
        .with(monorepo_root: "/tmp/repo", branch: "release/17.0.0")
        .and_return(true)
      expect(self).not_to receive(:start_release_line!)
      expect($stdin).not_to receive(:gets)

      expect do
        maybe_offer_release_branch_cut!(
          monorepo_root: "/tmp/repo",
          current_branch: "main",
          target_gem_version: "17.0.0.rc.0",
          dry_run: true
        )
      end.to output(%r{DRY RUN: would stop.*release/17.0.0 already exists}m).to_stdout
    end
  end

  describe "#start_release_line!" do
    it "prints the plan and creates nothing during a dry run" do
      expect(self).not_to receive(:sh_in_dir_for_release)
      expect(self).not_to receive(:local_or_remote_branch_exists?)

      expect do
        start_release_line!(monorepo_root: "/tmp/repo", release_branch: "release/17.0.0", dry_run: true)
      end.to output(%r{DRY RUN: would create release/17.0.0 from origin/main}).to_stdout
    end

    it "fetches, guards, creates, pushes, and prints next steps in normal mode" do
      allow(self).to receive(:sh_in_dir_for_release)
      allow(self).to receive(:local_or_remote_branch_exists?)
        .with(monorepo_root: "/tmp/repo", branch: "release/17.0.0")
        .and_return(false)

      expect do
        start_release_line!(monorepo_root: "/tmp/repo", release_branch: "release/17.0.0", dry_run: false)
      end.to output(%r{Started release/17.0.0.*update-changelog rc.*bundle exec rake release}m).to_stdout

      expect(self).to have_received(:sh_in_dir_for_release).with("/tmp/repo", "git fetch origin")
      expect(self).to have_received(:sh_in_dir_for_release)
        .with("/tmp/repo", "git checkout -b release/17.0.0 origin/main")
      expect(self).to have_received(:sh_in_dir_for_release).with("/tmp/repo", "git push -u origin release/17.0.0")
    end

    it "aborts after fetching when the release branch already exists" do
      allow(self).to receive(:sh_in_dir_for_release)
      allow(self).to receive(:local_or_remote_branch_exists?)
        .with(monorepo_root: "/tmp/repo", branch: "release/17.0.0")
        .and_return(true)

      expect do
        start_release_line!(monorepo_root: "/tmp/repo", release_branch: "release/17.0.0", dry_run: false)
      end.to raise_error(SystemExit, %r{release/17.0.0 already exists})

      expect(self).to have_received(:sh_in_dir_for_release).with("/tmp/repo", "git fetch origin")
      expect(self).not_to have_received(:sh_in_dir_for_release)
        .with("/tmp/repo", "git checkout -b release/17.0.0 origin/main")
    end
  end

  describe "#resolve_release_start_base_version" do
    it "accepts an explicit stable X.Y.Z" do
      expect(resolve_release_start_base_version("17.0.0", monorepo_root: "/tmp/repo")).to eq("17.0.0")
    end

    it "rejects an rc/prerelease argument (the branch name is the base)" do
      expect do
        resolve_release_start_base_version("17.0.0.rc.0", monorepo_root: "/tmp/repo")
      end.to raise_error(SystemExit, /Invalid release line version.*do not pass 17.0.0.rc.0/m)
    end

    it "derives the base from the top changelog header when it is an rc" do
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root: "/tmp/repo")
        .and_return("17.0.0.rc.2")

      expect do
        expect(resolve_release_start_base_version("", monorepo_root: "/tmp/repo")).to eq("17.0.0")
      end.to output(/Derived release line 17.0.0 from the top CHANGELOG.md header/).to_stdout
    end

    it "aborts asking for an explicit X.Y.Z when the top changelog header is not an rc" do
      allow(self).to receive(:extract_latest_changelog_version)
        .with(monorepo_root: "/tmp/repo")
        .and_return("17.0.0")

      expect do
        resolve_release_start_base_version("", monorepo_root: "/tmp/repo")
      end.to raise_error(SystemExit, /Could not determine which release line to start/)
    end
  end
end
