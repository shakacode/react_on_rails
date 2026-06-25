# frozen_string_literal: true

require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"
require_relative "spec_helper"

RSpec.describe "script/release-forward-port" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:script_path) { File.join(repo_root, "script/release-forward-port") }

  def git_env
    { "GIT_CONFIG_COUNT" => "0" }
  end

  def git(repo, *args)
    stdout, stderr, status = Open3.capture3(git_env, "git", *args, chdir: repo)
    raise "git #{args.join(' ')} failed: #{stderr}#{stdout}" unless status.success?

    stdout
  end

  def write_file(repo, path, contents)
    full_path = File.join(repo, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, contents)
  end

  def commit_all(repo, message)
    git(repo, "add", ".")
    git(repo, "commit", "--no-gpg-sign", "-m", message)
    git(repo, "rev-parse", "HEAD").strip
  end

  def run_script(repo, *args)
    Open3.capture3(git_env, RbConfig.ruby, script_path, *args, chdir: repo)
  end

  def run_script_from_repo_root(*args)
    Open3.capture3(git_env, RbConfig.ruby, script_path, *args, chdir: repo_root)
  end

  def version_file(version)
    <<~RUBY
      # frozen_string_literal: true

      module ReactOnRails
        VERSION = "#{version}"
      end
    RUBY
  end

  def with_release_repo
    Dir.mktmpdir("release-forward-port") do |repo|
      git(repo, "init")
      git(repo, "checkout", "-b", "main")
      git(repo, "config", "user.email", "test@example.com")
      git(repo, "config", "user.name", "Release Test")
      git(repo, "config", "commit.gpgsign", "false")

      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.0"))
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [Unreleased]\n")
      write_file(repo, "app.txt", "base\n")
      commit_all(repo, "Initial commit")

      yield repo
    end
  end

  def add_rc_bump_and_fix(repo)
    git(repo, "checkout", "-b", "release/1.0.1")
    write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1.rc.1"))
    write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [1.0.1.rc.1]\n- RC notes\n")
    rc_bump_sha = commit_all(repo, "Bump version to 1.0.1.rc.1")

    write_file(repo, "app.txt", "base\nrelease fix\n")
    fix_sha = commit_all(repo, "Fix release regression")
    git(repo, "checkout", "main")

    [rc_bump_sha, fix_sha]
  end

  it "dry-runs the forward-port plan without changing the target branch" do
    with_release_repo do |repo|
      rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stderr).to eq("")
      expect(stdout).to include("DRY RUN")
      expect(stdout).to include("SKIP #{rc_bump_sha[0, 12]} Bump version to 1.0.1.rc.1")
      expect(stdout).to include("rc version bump commit")
      expect(stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-parse", "--abbrev-ref", "HEAD").strip).to eq("main")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\n")
      expect(File.read(File.join(repo, "react_on_rails/lib/react_on_rails/version.rb"))).to include("1.0.0")
    end
  end

  it "prints usage without a stack trace for argument errors" do
    _stdout, stderr, status = run_script_from_repo_root("--bogus")

    expect(status.exitstatus).to eq(2)
    expect(stderr).to include("ERROR: invalid option: --bogus")
    expect(stderr).to include("Usage: script/release-forward-port")
    expect(stderr).not_to include("script/release-forward-port:")
  end

  it "rejects an extra positional arg when --target is already set" do
    with_release_repo do |repo|
      add_rc_bump_and_fix(repo)

      _stdout, stderr, status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "typo", "--dry-run")

      expect(status.exitstatus).to eq(2)
      expect(stderr).to include("ERROR: too many arguments: typo")
      expect(stderr).to include("Usage: script/release-forward-port")
    end
  end

  it "uses a leftover positional as the target when only --source is set" do
    with_release_repo do |repo|
      add_rc_bump_and_fix(repo)

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("target: main")
      expect(stdout).to include("PICK")
    end
  end

  it "skips commits already applied without an -x footer when the patch is still in the target tree" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      # Apply the fix onto main WITHOUT -x so there is no
      # "(cherry picked from commit ...)" footer; the helper must confirm the
      # patch is still present in the current target tree before skipping it.
      git(repo, "cherry-pick", fix_sha)
      latest_body = git(repo, "log", "-1", "--format=%B")
      expect(latest_body).not_to include("cherry picked from commit")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("patch already exists on main according to the current target tree")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
    end
  end

  it "does not skip a no-footer cherry-pick that was later reverted" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      git(repo, "cherry-pick", fix_sha)
      git(repo, "revert", "--no-edit", "HEAD")
      reverted_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\n")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(stdout).not_to include("patch already exists on main according to the current target tree")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")
      expect(git(repo, "rev-list", "--count", "main").strip.to_i).to eq(reverted_count.to_i + 1)

      latest_commit_body = git(repo, "log", "-1", "--format=%B")
      expect(latest_commit_body).to include("(cherry picked from commit #{fix_sha})")
    end
  end

  it "cherry-picks fixes with -x while excluding rc version bump commits" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("Forward-port complete")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")
      expect(File.read(File.join(repo, "react_on_rails/lib/react_on_rails/version.rb"))).to include("1.0.0")

      latest_commit_body = git(repo, "log", "-1", "--format=%B")
      expect(latest_commit_body).to include("Fix release regression")
      expect(latest_commit_body).to include("(cherry picked from commit #{fix_sha})")
      expect(git(repo, "log", "--format=%s", "main")).not_to include("Bump version to 1.0.1.rc.1")
    end
  end

  it "omits release branch merge commits from the forward-port plan" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1.rc.1"))
      rc_bump_sha = commit_all(repo, "Bump version to 1.0.1.rc.1")

      git(repo, "checkout", "-b", "release-fix")
      write_file(repo, "app.txt", "base\nrelease fix\n")
      fix_sha = commit_all(repo, "Fix release regression")

      git(repo, "checkout", "release/1.0.1")
      git(repo, "merge", "--no-ff", "release-fix", "-m", "Merge release fix branch")
      merge_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("SKIP #{rc_bump_sha[0, 12]} Bump version to 1.0.1.rc.1")
      expect(stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(stdout).not_to include(merge_sha[0, 12])
      expect(stdout).not_to include("Merge release fix branch")
    end
  end

  it "keeps earlier picks when a later cherry-pick is aborted" do
    with_release_repo do |repo|
      add_rc_bump_and_fix(repo)
      git(repo, "checkout", "release/1.0.1")
      write_file(repo, "conflict.txt", "release branch\n")
      commit_all(repo, "Fix release conflict")

      git(repo, "checkout", "main")
      write_file(repo, "conflict.txt", "main branch\n")
      commit_all(repo, "Change conflict on main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).not_to be_success
      expect(stdout).to include("Cherry-picking")
      expect(stderr).to include("only the current conflicting commit is abandoned")
      expect(git(repo, "log", "--format=%s", "main")).to include("Fix release regression")

      git(repo, "cherry-pick", "--abort")

      expect(git(repo, "log", "--format=%s", "main")).to include("Fix release regression")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")
    end
  end

  it "is idempotent when release commits were already forward-ported with -x" do
    with_release_repo do |repo|
      add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      second_stdout, second_stderr, second_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(second_stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
    end
  end

  it "skips stable version bump commits when the target branch has already advanced" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1"))
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [1.0.1]\n- Final notes\n")
      stable_bump_sha = commit_all(repo, "Bump version to 1.0.1")

      git(repo, "checkout", "main")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.1.0.dev"))
      commit_all(repo, "Start 1.1.0 development")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("SKIP #{stable_bump_sha[0, 12]} Bump version to 1.0.1")
      expect(stdout).to include("target main is already at 1.1.0.dev")
      expect(stdout).to include("manual fallback to take only the CHANGELOG hunks")
    end
  end

  it "skips test prerelease version bumps when the target has advanced to a later prerelease" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1.test.1"))
      test_bump_sha = commit_all(repo, "Bump version to 1.0.1.test.1")

      git(repo, "checkout", "main")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1.beta.1"))
      commit_all(repo, "Start 1.0.1 beta")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("SKIP #{test_bump_sha[0, 12]} Bump version to 1.0.1.test.1")
      expect(stdout).to include("target main is already at 1.0.1.beta.1")
    end
  end
end
