# frozen_string_literal: true

require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"
require_relative "spec_helper"

release_forward_port_script = File.expand_path("../../../script/release-forward-port", __dir__)
# Guard against re-loading when this spec file is required more than once. The
# helper constant is defined only by script/release-forward-port.
load release_forward_port_script unless defined?(ReleaseForwardPort)

RSpec.describe "script/release-forward-port" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:script_path) { File.join(repo_root, "script/release-forward-port") }

  def git_env
    {
      "GIT_CONFIG_COUNT" => "0",
      "GIT_CONFIG_GLOBAL" => File::NULL,
      "GIT_CONFIG_NOSYSTEM" => "1"
    }
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

  def write_binary_file(repo, path, contents)
    full_path = File.join(repo, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.binwrite(full_path, contents)
  end

  def executable_file?(repo, path)
    (File.stat(File.join(repo, path)).mode & 0o111).positive?
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

  def add_reverted_feature_merge(repo)
    base_sha = git(repo, "rev-parse", "HEAD").strip
    git(repo, "checkout", "-b", "feature")
    write_file(repo, "app.txt", "base\nmain merge fix\n")
    feature_sha = commit_all(repo, "Fix regression through feature branch")

    git(repo, "checkout", "main")
    git(repo, "merge", "--no-ff", "feature", "-m", "Merge feature fix")
    merge_sha = git(repo, "rev-parse", "HEAD").strip
    git(repo, "revert", "-m", "1", "--no-edit", merge_sha)
    merge_revert_body = git(repo, "log", "-1", "--format=%B")
    expect(merge_revert_body).to include("This reverts commit #{merge_sha}, reversing")

    [base_sha, feature_sha, merge_sha]
  end

  def configure_external_diff(repo)
    external_diff_path = File.join(repo, "external-diff.sh")
    File.write(external_diff_path, "#!/bin/sh\nprintf '%s --- Text\\n' \"$1\"\n")
    File.chmod(0o755, external_diff_path)
    git(repo, "add", "external-diff.sh")
    git(repo, "commit", "--no-gpg-sign", "-m", "Configure external diff helper")
    git(repo, "config", "diff.external", external_diff_path)
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

  it "dry-runs release and target branches with unrelated root histories" do
    with_release_repo do |repo|
      git(repo, "checkout", "--orphan", "release/1.0.1")
      commit_all(repo, "Seed rewritten release history")
      write_file(repo, "app.txt", "base\nrelease fix\n")
      fix_sha = commit_all(repo, "Fix release regression after history rewrite")
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stderr).to eq("")
      expect(stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression after history rewrite")
      expect(stdout).to include("DRY RUN")
    end
  end

  it "fails closed when shallow history prevents finding a merge base" do
    with_release_repo do |repo|
      main_sha = git(repo, "rev-parse", "main").strip
      git(repo, "checkout", "--orphan", "release/1.0.1")
      release_root_sha = commit_all(repo, "Seed shallow release history")
      write_file(repo, "app.txt", "base\nrelease fix\n")
      commit_all(repo, "Fix release regression after shallow boundary")
      git(repo, "checkout", "main")

      git_dir = git(repo, "rev-parse", "--git-dir").strip
      shallow_boundaries = [main_sha, release_root_sha].sort.join("\n")
      File.write(File.join(repo, git_dir, "shallow"), "#{shallow_boundaries}\n")

      _stdout, stderr, status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).not_to be_success
      expect(stderr).to include("repository history is shallow")
      expect(stderr).to include("git fetch --unshallow")
    end
  end

  it "skips bare rc version bump subjects before version-drift checks" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1.rc"))
      bare_rc_bump_sha = commit_all(repo, "Bump version to 1.0.1.rc")
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("SKIP #{bare_rc_bump_sha[0, 12]} Bump version to 1.0.1.rc")
      expect(stdout).to include("rc version bump commit")
      expect(stdout).to include("Summary: 0 commits to cherry-pick, 1 commit skipped.")
    end
  end

  it "skips reverts of skipped rc version bump commits" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1.rc.1"))
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [1.0.1.rc.1]\n- RC notes\n")
      rc_bump_sha = commit_all(repo, "Bump version to 1.0.1.rc.1")
      git(repo, "revert", "--no-edit", "HEAD")
      rc_revert_sha = git(repo, "rev-parse", "HEAD").strip

      git(repo, "checkout", "main")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("SKIP #{rc_bump_sha[0, 12]} Bump version to 1.0.1.rc.1")
      expect(stdout).to include("SKIP #{rc_revert_sha[0, 12]} Revert \"Bump version to 1.0.1.rc.1\"")
      expect(stdout).to include("reverts a release-only version bump that is skipped for main")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
      expect(File.read(File.join(repo, "react_on_rails/lib/react_on_rails/version.rb"))).to include("1.0.0")
    end
  end

  it "reports no commits when the source has nothing ahead of the target" do
    with_release_repo do |repo|
      stdout, stderr, status = run_script(repo, "--source", "main", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("No commits found in main..main.")
      expect(stdout).to include("DRY RUN")
    end
  end

  it "does not require a clean worktree or checkout target for a no-op normal run" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "feature-work")
      write_file(repo, "scratch.txt", "local notes\n")

      stdout, stderr, status = run_script(repo, "--source", "main", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("No commits found in main..main.")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-parse", "--abbrev-ref", "HEAD").strip).to eq("feature-work")
      expect(File.read(File.join(repo, "scratch.txt"))).to eq("local notes\n")
    end
  end

  it "rejects no-op normal runs while a cherry-pick is in progress" do
    with_release_repo do |repo|
      git_dir = git(repo, "rev-parse", "--git-dir").strip
      File.write(File.join(repo, git_dir, "CHERRY_PICK_HEAD"), git(repo, "rev-parse", "HEAD"))

      stdout, stderr, status = run_script(repo, "--source", "main", "--target", "main")

      expect(status).not_to be_success
      expect(stdout).to include("No commits found in main..main.")
      expect(stdout).not_to include("Nothing to cherry-pick")
      expect(stderr).to include("a cherry-pick is already in progress")
    end
  end

  it "skips initially empty release commits before cherry-picking" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      git(repo, "commit", "--allow-empty", "--no-gpg-sign", "-m", "Record release-only marker")
      empty_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("SKIP #{empty_sha[0, 12]} Record release-only marker")
      expect(stdout).to include("empty commit; cherry-picking would only create a no-op commit on main")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
    end
  end

  it "defers changelog-only commits to the reconciliation pass" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [1.0.1.rc.1]\n- Release fix\n")
      changelog_sha = commit_all(repo, "Update changelog for 1.0.1.rc.1")
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("SKIP #{changelog_sha[0, 12]} Update changelog for 1.0.1.rc.1")
      expect(stdout).to include("changelog-only commit; use --changelog reconciliation")
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

  it "accepts positional source and target refs" do
    with_release_repo do |repo|
      add_rc_bump_and_fix(repo)

      stdout, stderr, status = run_script(repo, "release/1.0.1", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("source: release/1.0.1")
      expect(stdout).to include("target: main")
      expect(stdout).to include("PICK")
    end
  end

  it "skips commits already applied without an -x footer when the patch is still in the target tree" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      # Apply the fix onto main WITHOUT -x so there is no
      # "(cherry picked from commit ...)" footer; the helper must confirm the
      # equivalent target patch is still present in history before skipping it.
      git(repo, "cherry-pick", fix_sha)
      latest_body = git(repo, "log", "-1", "--format=%B")
      expect(latest_body).not_to include("cherry picked from commit")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("patch already exists on main according to target history")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
    end
  end

  it "skips no-footer cherry-picks after later target context changes" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      git(repo, "cherry-pick", fix_sha)
      write_file(repo, "app.txt", "base updated on main\nrelease fix\n")
      commit_all(repo, "Adjust target context around release fix")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("patch already exists on main according to target history")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
      expect(File.read(File.join(repo, "app.txt"))).to eq("base updated on main\nrelease fix\n")
    end
  end

  it "skips source patches embedded in combined target commits that mention the source subject" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      write_file(repo, "app.txt", "base\nrelease fix\n")
      write_file(repo, "main-only.txt", "combined target work\n")
      commit_all(repo, "Forward-port release fixes\n\nIncludes: Fix release regression")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("patch already exists on main according to target history")
      expect(stdout).to include("DRY RUN")
      expect(stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
    end
  end

  it "skips source patches embedded in combined target commits that mention the source PR" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "app.txt", "base\nrelease fix\n")
      fix_sha = commit_all(repo, "Fix release regression (#123)")
      git(repo, "checkout", "main")

      write_file(repo, "app.txt", "base\nrelease fix\n")
      write_file(repo, "main-only.txt", "combined target work\n")
      commit_all(repo, "Forward-port release fixes\n\nIncludes #123 with other release work")

      stdout, stderr, status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("patch already exists on main according to target history")
      expect(stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression (#123)")
    end
  end

  it "ignores changelog differences when matching mixed commits to combined forward-ports" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "app.txt", "base\nrelease fix\n")
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [1.0.1.rc.1]\n- Release wording\n")
      fix_sha = commit_all(repo, "Fix release regression (#123)")
      git(repo, "checkout", "main")

      write_file(repo, "app.txt", "base\nrelease fix\n")
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [Unreleased]\n- Mainline wording\n")
      commit_all(repo, "Forward-port release fixes\n\nIncludes #123 with reconciled changelog wording")

      stdout, stderr, status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("patch already exists on main according to target history")
      expect(stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression (#123)")
    end
  end

  it "does not trust a source-subject mention when the target patch differs" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      write_file(repo, "app.txt", "base\ndifferent target fix\n")
      write_file(repo, "main-only.txt", "combined target work\n")
      commit_all(repo, "Discuss release forward-port\n\nCandidate: Fix release regression")

      stdout, stderr, status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(stdout).not_to include("patch already exists on main according to target history")
    end
  end

  it "skips no-footer target patches that rename the source path" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      git(repo, "mv", "app.txt", "renamed file.txt")
      write_file(repo, "renamed file.txt", "base\nrelease fix\n")
      commit_all(repo, "Rename and apply release fix manually")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("patch already exists on main according to target history")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
      expect(File.read(File.join(repo, "renamed file.txt"))).to eq("base\nrelease fix\n")
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
      expect(stdout).not_to include("patch already exists on main according to target history")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")
      expect(git(repo, "rev-list", "--count", "main").strip.to_i).to eq(reverted_count.to_i + 1)

      latest_commit_body = git(repo, "log", "-1", "--format=%B")
      expect(latest_commit_body).to include("(cherry picked from commit #{fix_sha})")
    end
  end

  it "skips no-footer manual reapplications after source-sha reverts" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      git(repo, "cherry-pick", fix_sha)
      git(repo, "revert", "--no-edit", fix_sha)
      write_file(repo, "app.txt", "base\nrelease fix\n")
      commit_all(repo, "Reapply release fix manually")
      reapplied_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("patch already exists on main according to target history")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(reapplied_count)
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")
    end
  end

  it "skips no-footer manual reapplications after source-sha reverts and target renames" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      git(repo, "cherry-pick", fix_sha)
      git(repo, "mv", "app.txt", "renamed file.txt")
      commit_all(repo, "Rename target file")
      write_file(repo, "renamed file.txt", "base\n")
      git(repo, "add", "renamed file.txt")
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Undo release regression manually after rename",
        "-m",
        "This reverts commit #{fix_sha}."
      )
      write_file(repo, "renamed file.txt", "base\nrelease fix\n")
      commit_all(repo, "Reapply release fix manually after rename")
      reapplied_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("patch already exists on main according to target history")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(reapplied_count)
      expect(File.read(File.join(repo, "renamed file.txt"))).to eq("base\nrelease fix\n")
    end
  end

  it "skips live patches after empty source-sha reverts" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      git(repo, "cherry-pick", fix_sha)
      git(
        repo,
        "commit",
        "--allow-empty",
        "--no-gpg-sign",
        "-m",
        "Record empty source revert",
        "-m",
        "This reverts commit #{fix_sha}."
      )
      commit_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("patch already exists on main according to target history")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")
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

  it "reports release branch merge commits for manual handling" do
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
      expect(stdout).to include("MANUAL #{merge_sha[0, 12]} Merge release fix branch")
      expect(stdout).to include("merge commit; inspect manually for conflict-resolution hunks")
    end
  end

  it "blocks normal mode when release branch merge commits need manual inspection" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "app.txt", "base\nrelease base\n")
      base_fix_sha = commit_all(repo, "Fix release regression")

      git(repo, "checkout", "-b", "release-fix")
      write_file(repo, "merge-only.txt", "merge-only fix\n")
      commit_all(repo, "Fix merge-only regression")

      git(repo, "checkout", "release/1.0.1")
      git(repo, "merge", "--no-ff", "release-fix", "-m", "Merge release fix branch")
      merge_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).not_to be_success
      expect(stdout).to include("PICK #{base_fix_sha[0, 12]} Fix release regression")
      expect(stdout).to include("MANUAL #{merge_sha[0, 12]} Merge release fix branch")
      expect(stdout).not_to include("Forward-port complete")
      expect(stderr).to include("Manual inspection required for #{merge_sha}")
      expect(stderr).to include("Earlier successful picks from this run are already committed and safe")
    end
  end

  it "routes reverts of release-branch merge commits to manual handling" do
    with_release_repo do |repo|
      write_file(repo, "app.txt", "base\nmain fix\n")
      main_fix_sha = commit_all(repo, "Fix release regression")

      git(repo, "checkout", "-b", "release/1.0.1", "HEAD~1")
      git(repo, "checkout", "-b", "release-fix", main_fix_sha)
      git(repo, "checkout", "release/1.0.1")
      git(repo, "merge", "--no-ff", "release-fix", "-m", "Merge release fix branch")
      merge_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "revert", "-m", "1", "--no-edit", merge_sha)
      merge_revert_sha = git(repo, "rev-parse", "HEAD").strip
      merge_revert_body = git(repo, "log", "-1", "--format=%B")
      expect(merge_revert_body).to include("This reverts commit #{merge_sha}, reversing")
      git(repo, "checkout", "main")

      stdout, stderr, status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--ack-manual", merge_sha)

      expect(status).not_to be_success
      expect(stdout).to include("ACK-MANUAL #{merge_sha[0, 12]} Merge release fix branch")
      expect(stdout).to include("MANUAL #{merge_revert_sha[0, 12]} Revert \"Merge release fix branch\"")
      expect(stdout).to include("reverts a release-branch merge commit")
      expect(stderr).to include("Manual inspection required for #{merge_revert_sha}")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nmain fix\n")
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

  it "skips -x cherry-picks after later target context changes" do
    with_release_repo do |repo|
      add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      write_file(repo, "app.txt", "base updated on main\nrelease fix\n")
      commit_all(repo, "Adjust target context around release fix")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(second_stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
      expect(File.read(File.join(repo, "app.txt"))).to eq("base updated on main\nrelease fix\n")
    end
  end

  it "skips -x cherry-picks after unrelated target merges are reverted" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      git(repo, "checkout", "-b", "unrelated-main-work")
      write_file(repo, "notes.txt", "unrelated target work\n")
      commit_all(repo, "Add unrelated target notes")
      git(repo, "checkout", "main")
      git(repo, "merge", "--no-ff", "unrelated-main-work", "-m", "Merge unrelated target work")
      unrelated_merge_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "revert", "-m", "1", "--no-edit", unrelated_merge_sha)
      commit_count = git(repo, "rev-list", "--count", "main").strip

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(second_stdout).to include("Nothing to cherry-pick")
      expect(second_stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")
    end
  end

  it "skips conflict-resolved -x cherry-picks on rerun" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "app.txt", "release branch\n")
      fix_sha = commit_all(repo, "Fix release regression")

      git(repo, "checkout", "main")
      write_file(repo, "app.txt", "main branch\n")
      commit_all(repo, "Change same line on main")

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(first_status).not_to be_success
      expect(first_stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(first_stderr).to include("Cherry-pick failed for #{fix_sha}")

      write_file(repo, "app.txt", "main branch\nrelease branch\n")
      git(repo, "add", "app.txt")
      git(repo, "-c", "core.editor=true", "cherry-pick", "--continue")
      commit_count = git(repo, "rev-list", "--count", "main").strip
      latest_commit_body = git(repo, "log", "-1", "--format=%B")
      expect(latest_commit_body).to include("(cherry picked from commit #{fix_sha})")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(second_stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
      expect(File.read(File.join(repo, "app.txt"))).to eq("main branch\nrelease branch\n")
    end
  end

  it "skips release commits cherry-picked from a live target commit" do
    with_release_repo do |repo|
      write_file(repo, "app.txt", "base\nmain fix\n")
      main_fix_sha = commit_all(repo, "Fix release regression")

      git(repo, "checkout", "-b", "release/1.0.1", "HEAD~1")
      write_file(repo, "app.txt", "base\nrelease-specific fix\n")
      git(repo, "add", "app.txt")
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Fix release regression",
        "-m",
        "(cherry picked from commit #{main_fix_sha})"
      )
      release_fix_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("SKIP #{release_fix_sha[0, 12]} Fix release regression")
      expect(stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nmain fix\n")
    end
  end

  it "skips adapted backports that narrate their live target cherry-pick origin" do
    with_release_repo do |repo|
      write_file(repo, "app.txt", "base\nmain fix\n")
      main_fix_sha = commit_all(repo, "Fix release regression on main")

      git(repo, "checkout", "-b", "release/1.0.1", "HEAD~1")
      write_file(repo, "app.txt", "base\nrelease-adapted fix\n")
      git(repo, "add", "app.txt")
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Backport release regression fix",
        "-m",
        "Cherry-picked main squash commit\n`#{main_fix_sha}` with `-x`."
      )
      release_fix_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("SKIP #{release_fix_sha[0, 12]} Backport release regression fix")
      expect(stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nmain fix\n")
    end
  end

  it "picks release commits cherry-picked from target merge commits that were later reverted" do
    with_release_repo do |repo|
      base_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "-b", "feature")
      write_file(repo, "app.txt", "base\nmain merge fix\n")
      commit_all(repo, "Fix regression through feature branch")

      git(repo, "checkout", "main")
      git(repo, "merge", "--no-ff", "feature", "-m", "Merge feature fix")
      merge_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "revert", "-m", "1", "--no-edit", merge_sha)
      merge_revert_body = git(repo, "log", "-1", "--format=%B")
      expect(merge_revert_body).to include("This reverts commit #{merge_sha}, reversing")

      git(repo, "checkout", "-b", "release/1.0.1", base_sha)
      git(repo, "cherry-pick", "-x", "-m", "1", merge_sha)
      release_fix_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("PICK #{release_fix_sha[0, 12]} Merge feature fix")
      expect(stdout).to include("Forward-port complete")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nmain merge fix\n")
    end
  end

  it "picks release commits cherry-picked from target feature commits whose merge was later reverted" do
    with_release_repo do |repo|
      base_sha, feature_sha = add_reverted_feature_merge(repo)

      git(repo, "checkout", "-b", "release/1.0.1", base_sha)
      git(repo, "cherry-pick", "-x", feature_sha)
      release_fix_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("PICK #{release_fix_sha[0, 12]} Fix regression through feature branch")
      expect(stdout).to include("Forward-port complete")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nmain merge fix\n")
    end
  end

  it "picks no-footer release commits when the matching target merge was later reverted" do
    with_release_repo do |repo|
      base_sha, = add_reverted_feature_merge(repo)

      git(repo, "checkout", "-b", "release/1.0.1", base_sha)
      write_file(repo, "app.txt", "base\nmain merge fix\n")
      release_fix_sha = commit_all(repo, "Fix release regression")
      release_fix_body = git(repo, "log", "-1", "--format=%B")
      expect(release_fix_body).not_to include("cherry picked from commit")
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("PICK #{release_fix_sha[0, 12]} Fix release regression")
      expect(stdout).to include("Forward-port complete")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nmain merge fix\n")
    end
  end

  it "routes release-only reverts of reverse cherry-picks to manual handling" do
    with_release_repo do |repo|
      write_file(repo, "app.txt", "base\nmain fix\n")
      main_fix_sha = commit_all(repo, "Fix release regression")

      git(repo, "checkout", "-b", "release/1.0.1", "HEAD~1")
      git(repo, "cherry-pick", "-x", main_fix_sha)
      release_pick_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "revert", "--no-edit", "HEAD")
      release_revert_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).not_to be_success
      expect(stdout).to include("SKIP #{release_pick_sha[0, 12]} Fix release regression")
      expect(stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(stdout).to include("MANUAL #{release_revert_sha[0, 12]} Revert \"Fix release regression\"")
      expect(stdout).to include("reverts a release-only application of a commit already live on main")
      expect(stderr).to include("Manual inspection required for #{release_revert_sha}")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nmain fix\n")
    end
  end

  it "routes release-only reverts of no-footer reverse picks to manual handling" do
    with_release_repo do |repo|
      write_file(repo, "app.txt", "base\nmain fix\n")
      main_fix_sha = commit_all(repo, "Fix release regression")

      git(repo, "checkout", "-b", "release/1.0.1", "HEAD~1")
      git(repo, "cherry-pick", main_fix_sha)
      release_pick_body = git(repo, "log", "-1", "--format=%B")
      expect(release_pick_body).not_to include("cherry picked from commit")
      git(repo, "revert", "--no-edit", "HEAD")
      release_revert_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).not_to be_success
      expect(stdout).to include("MANUAL #{release_revert_sha[0, 12]} Revert \"Fix release regression\"")
      expect(stdout).to include("reverts a release-only application of a commit already live on main")
      expect(stderr).to include("Manual inspection required for #{release_revert_sha}")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nmain fix\n")
    end
  end

  it "allows acknowledged manual items to be skipped so later eligible commits can continue" do
    with_release_repo do |repo|
      write_file(repo, "app.txt", "base\nmain fix\n")
      main_fix_sha = commit_all(repo, "Fix release regression")

      git(repo, "checkout", "-b", "release/1.0.1", "HEAD~1")
      git(repo, "cherry-pick", "-x", main_fix_sha)
      git(repo, "revert", "--no-edit", "HEAD")
      release_revert_sha = git(repo, "rev-parse", "HEAD").strip
      write_file(repo, "later.txt", "later release fix\n")
      later_fix_sha = commit_all(repo, "Fix later release regression")
      git(repo, "checkout", "main")

      first_stdout, first_stderr, first_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(first_status).not_to be_success
      expect(first_stdout).to include("MANUAL #{release_revert_sha[0, 12]} Revert \"Fix release regression\"")
      expect(first_stdout).to include("PICK #{later_fix_sha[0, 12]} Fix later release regression")
      expect(first_stderr).to include("Manual inspection required for #{release_revert_sha}")
      expect(first_stderr).to include("--ack-manual #{release_revert_sha}")
      expect(first_stderr).to include("Note: 1 later eligible commit in this plan is not attempted after this failure")
      expect(File).not_to exist(File.join(repo, "later.txt"))

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--ack-manual", release_revert_sha)

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("ACK-MANUAL #{release_revert_sha[0, 12]} Revert \"Fix release regression\"")
      expect(second_stdout).to include("PICK #{later_fix_sha[0, 12]} Fix later release regression")
      expect(second_stdout).to include("Forward-port complete")
      expect(File.read(File.join(repo, "later.txt"))).to eq("later release fix\n")

      latest_commit_body = git(repo, "log", "-1", "--format=%B")
      expect(latest_commit_body).to include("(cherry picked from commit #{later_fix_sha})")
    end
  end

  it "rejects acknowledged commits that are not manual items in the current plan" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      _stdout, stderr, status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run", "--ack-manual", fix_sha)

      expect(status.exitstatus).to eq(2)
      expect(stderr).to include("--ack-manual only accepts commits currently marked MANUAL")
      expect(stderr).to include(fix_sha)
    end
  end

  it "reports invalid acknowledged commits as usage errors" do
    with_release_repo do |repo|
      _stdout, stderr, status =
        run_script(repo, "--source", "main", "--target", "main", "--dry-run", "--ack-manual", "not-a-sha")

      expect(status.exitstatus).to eq(2)
      expect(stderr).to include("Usage: script/release-forward-port")
      expect(stderr).to include("--ack-manual \"not-a-sha\" is not a commit")
    end
  end

  it "does not skip an -x cherry-pick that was later reverted" do
    with_release_repo do |repo|
      add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")
      git(repo, "revert", "--no-edit", "HEAD")
      reverted_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\n")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("PICK")
      expect(second_stdout).not_to include("already forward-ported to main via cherry-pick -x evidence")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")
      expect(git(repo, "rev-list", "--count", "main").strip.to_i).to eq(reverted_count.to_i + 1)
    end
  end

  it "does not skip an -x cherry-pick when the source commit was later reverted on target" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      git(repo, "revert", "--no-commit", fix_sha)
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Undo release regression manually",
        "-m",
        "This reverts commit #{fix_sha}."
      )
      source_revert_body = git(repo, "log", "-1", "--format=%B")
      expect(source_revert_body).to include("Undo release regression manually")
      expect(source_revert_body).to include("This reverts commit #{fix_sha}.")
      reverted_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\n")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(second_stdout).not_to include("already forward-ported to main via cherry-pick -x evidence")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")
      expect(git(repo, "rev-list", "--count", "main").strip.to_i).to eq(reverted_count.to_i + 1)

      repicked_count = git(repo, "rev-list", "--count", "main").strip
      third_stdout, third_stderr, third_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(third_status).to be_success, third_stderr
      expect(third_stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(third_stdout).to include("Nothing to cherry-pick")
      expect(third_stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(repicked_count)
    end
  end

  it "does not trust -x evidence after conflict-resolved source-sha reverts" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      write_file(repo, "app.txt", "base updated on main\nrelease fix\n")
      commit_all(repo, "Adjust target context around release fix")

      _stdout, _stderr, revert_status =
        Open3.capture3(git_env, "git", "revert", "--no-commit", fix_sha, chdir: repo)
      expect(revert_status).not_to be_success
      write_file(repo, "app.txt", "base updated on main\n")
      git(repo, "add", "app.txt")
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Undo release regression after context update",
        "-m",
        "This reverts commit #{fix_sha}."
      )

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(stdout).not_to include("already forward-ported to main via cherry-pick -x evidence")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base updated on main\n")
    end
  end

  it "skips source-sha reverts superseded by merged no-footer reapplications" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      base_sha = git(repo, "rev-list", "--max-parents=0", "HEAD").strip
      git(repo, "checkout", "-b", "side-reapply", base_sha)
      write_file(repo, "app.txt", "base\nrelease fix\n")
      commit_all(repo, "Independently reapply release fix")

      git(repo, "checkout", "main")
      git(repo, "revert", "--no-commit", fix_sha)
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Undo release regression manually",
        "-m",
        "This reverts commit #{fix_sha}."
      )
      git(repo, "merge", "--no-ff", "side-reapply", "-m", "Merge independent reapply")
      restored_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("Nothing to cherry-pick")
      expect(second_stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(restored_count)
    end
  end

  it "skips source-sha reverts superseded by merged conflict-resolved -x reapplications" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "app.txt", "release branch\n")
      fix_sha = commit_all(repo, "Fix release regression")

      git(repo, "checkout", "main")
      write_file(repo, "app.txt", "main branch\n")
      commit_all(repo, "Change same line on main")

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).not_to be_success
      expect(first_stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(first_stderr).to include("Cherry-pick failed for #{fix_sha}")
      write_file(repo, "app.txt", "main branch\nrelease branch\n")
      git(repo, "add", "app.txt")
      git(repo, "-c", "core.editor=true", "cherry-pick", "--continue")

      git(repo, "checkout", "-b", "side-reapply", "main~1")
      write_file(repo, "side.txt", "side branch marker\n")
      commit_all(repo, "Prepare side branch")
      _stdout, _stderr, side_status =
        Open3.capture3(git_env, "git", "cherry-pick", "-x", fix_sha, chdir: repo)
      expect(side_status).not_to be_success
      write_file(repo, "app.txt", "main branch\nrelease branch\n")
      git(repo, "add", "app.txt")
      git(repo, "-c", "core.editor=true", "cherry-pick", "--continue")

      git(repo, "checkout", "main")
      _stdout, _stderr, revert_status =
        Open3.capture3(git_env, "git", "revert", "--no-commit", fix_sha, chdir: repo)
      expect(revert_status).not_to be_success
      write_file(repo, "app.txt", "main branch\n")
      git(repo, "add", "app.txt")
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Undo release regression manually",
        "-m",
        "This reverts commit #{fix_sha}."
      )

      _stdout, _stderr, merge_status =
        Open3.capture3(git_env, "git", "merge", "--no-ff", "side-reapply", "-m", "Merge side reapply", chdir: repo)
      unless merge_status.success?
        write_file(repo, "app.txt", "main branch\nrelease branch\n")
        git(repo, "add", "app.txt")
        git(repo, "commit", "--no-gpg-sign", "-m", "Merge side reapply")
      end
      restored_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "app.txt"))).to eq("main branch\nrelease branch\n")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(second_stdout).to include("Nothing to cherry-pick")
      expect(second_stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(restored_count)
    end
  end

  it "skips source-sha reverts superseded by merge-only reapplications" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      git(repo, "checkout", "-b", "side-reapply")
      write_file(repo, "side.txt", "side branch marker\n")
      commit_all(repo, "Prepare side branch")

      git(repo, "checkout", "main")
      git(repo, "revert", "--no-commit", fix_sha)
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Undo release regression manually",
        "-m",
        "This reverts commit #{fix_sha}."
      )
      git(repo, "merge", "--no-ff", "--no-commit", "side-reapply")
      write_file(repo, "app.txt", "base\nrelease fix\n")
      git(repo, "add", "app.txt")
      git(repo, "commit", "--no-gpg-sign", "-m", "Merge side reapply with manual fix")
      restored_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(second_stdout).to include("Nothing to cherry-pick")
      expect(second_stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(restored_count)
    end
  end

  it "picks source-sha reverts that remove a renamed target path" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      git(repo, "mv", "app.txt", "renamed.txt")
      commit_all(repo, "Rename target file")
      write_file(repo, "renamed.txt", "base\n")
      git(repo, "add", "renamed.txt")
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Undo release regression manually after rename",
        "-m",
        "This reverts commit #{fix_sha}."
      )
      reverted_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "renamed.txt"))).to eq("base\n")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(second_stdout).not_to include("already forward-ported to main via cherry-pick -x evidence")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(reverted_count)
    end
  end

  it "skips source-sha reverts superseded by merge-only reapplications after target renames" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      git(repo, "checkout", "-b", "side-reapply")
      write_file(repo, "side.txt", "side branch marker\n")
      commit_all(repo, "Prepare side branch")

      git(repo, "checkout", "main")
      write_file(repo, "app.txt", "base\n")
      git(repo, "add", "app.txt")
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Undo release regression manually",
        "-m",
        "This reverts commit #{fix_sha}."
      )
      git(repo, "mv", "app.txt", "renamed file.txt")
      commit_all(repo, "Rename target file")
      git(repo, "merge", "--no-ff", "--no-commit", "side-reapply")
      write_file(repo, "renamed file.txt", "base\nrelease fix\n")
      git(repo, "add", "renamed file.txt")
      git(repo, "commit", "--no-gpg-sign", "-m", "Merge side reapply with renamed manual fix")
      configure_external_diff(repo)
      restored_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "renamed file.txt"))).to eq("base\nrelease fix\n")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(second_stdout).to include("Nothing to cherry-pick")
      expect(second_stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(restored_count)
    end
  end

  it "skips side-merged -x reapplications when the target renamed the changed file before merge" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      git(repo, "checkout", "-b", "side-reapply", "main")
      git(repo, "cherry-pick", "-x", fix_sha)

      git(repo, "checkout", "main")
      git(repo, "mv", "app.txt", "renamed.txt")
      commit_all(repo, "Rename target file")
      git(repo, "merge", "--no-ff", "side-reapply", "-m", "Merge side reapply after rename")
      merged_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "renamed.txt"))).to eq("base\nrelease fix\n")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(File.read(File.join(repo, "renamed.txt"))).to eq("base\nrelease fix\n")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(merged_count)
    end
  end

  it "does not treat -x side commits merged with ours as source-revert supersession" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      base_sha = git(repo, "rev-parse", "main~1").strip
      git(repo, "checkout", "-b", "side-reapply", base_sha)
      write_file(repo, "side.txt", "side branch marker\n")
      commit_all(repo, "Prepare side branch")
      git(repo, "cherry-pick", "-x", fix_sha)

      git(repo, "checkout", "main")
      git(repo, "revert", "--no-commit", fix_sha)
      git(
        repo,
        "commit",
        "--no-gpg-sign",
        "-m",
        "Undo release regression manually",
        "-m",
        "This reverts commit #{fix_sha}."
      )
      git(repo, "merge", "--no-ff", "-s", "ours", "side-reapply", "-m", "Merge side but keep reverted content")
      reverted_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\n")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(second_stdout).not_to include("already forward-ported to main via cherry-pick -x evidence")
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")
      expect(git(repo, "rev-list", "--count", "main").strip.to_i).to eq(reverted_count.to_i + 1)
    end
  end

  it "ignores source-sha reverts merged with ours when the target kept the fix" do
    with_release_repo do |repo|
      _rc_bump_sha, fix_sha = add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      git(repo, "checkout", "-b", "side-revert")
      git(repo, "revert", "--no-edit", fix_sha)
      git(repo, "checkout", "main")
      git(repo, "merge", "--no-ff", "-s", "ours", "side-revert", "-m", "Merge side revert but keep fix")
      kept_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(second_stdout).to include("Nothing to cherry-pick")
      expect(second_stdout).not_to include("PICK #{fix_sha[0, 12]} Fix release regression")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(kept_count)
    end
  end

  it "keeps stable version bumps manual after source-sha reverts" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1"))
      stable_bump_sha = commit_all(repo, "Bump version to 1.0.1")

      git(repo, "checkout", "main")
      write_file(repo, "target.txt", "target-only work\n")
      commit_all(repo, "Advance target branch")
      git(repo, "cherry-pick", stable_bump_sha)
      git(repo, "revert", "--no-edit", stable_bump_sha)
      restored_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "react_on_rails/lib/react_on_rails/version.rb"))).to include("1.0.0")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("MANUAL #{stable_bump_sha[0, 12]} Bump version to 1.0.1")
      expect(stdout).to include("stable release version bump commit")
      expect(stdout).not_to include("PICK #{stable_bump_sha[0, 12]} Bump version to 1.0.1")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(restored_count)
      expect(File.read(File.join(repo, "react_on_rails/lib/react_on_rails/version.rb"))).to include("1.0.0")
    end
  end

  it "keeps empty stable version bump commits manual" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      git(repo, "commit", "--allow-empty", "--no-gpg-sign", "-m", "Bump version to 1.0.1")
      stable_bump_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("MANUAL #{stable_bump_sha[0, 12]} Bump version to 1.0.1")
      expect(stdout).to include("stable release version bump commit")
      expect(stdout).not_to include("empty commit; cherry-picking would only create a no-op commit")
    end
  end

  it "skips an -x cherry-pick restored by reverting its revert" do
    with_release_repo do |repo|
      add_rc_bump_and_fix(repo)

      first_stdout, first_stderr, first_status = run_script(repo, "--source", "release/1.0.1", "--target", "main")
      expect(first_status).to be_success, first_stderr
      expect(first_stdout).to include("Forward-port complete")

      git(repo, "revert", "--no-edit", "HEAD")
      git(repo, "revert", "--no-edit", "HEAD")
      restored_count = git(repo, "rev-list", "--count", "main").strip
      expect(File.read(File.join(repo, "app.txt"))).to eq("base\nrelease fix\n")

      second_stdout, second_stderr, second_status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(second_status).to be_success, second_stderr
      expect(second_stdout).to include("already forward-ported to main via cherry-pick -x evidence")
      expect(second_stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(restored_count)
    end
  end

  it "marks stable version bump commits as manual when the target branch has already advanced" do
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
      expect(stdout).to include("MANUAL #{stable_bump_sha[0, 12]} Bump version to 1.0.1")
      expect(stdout).to include("stable release version bump commit")
      expect(stdout).to include("manual fallback to take only the CHANGELOG hunks")
    end
  end

  it "marks stable final version bumps as manual when the target is still pre-release-cut" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1.rc.1"))
      rc_bump_sha = commit_all(repo, "Bump version to 1.0.1.rc.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1"))
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [1.0.1]\n- Final notes\n")
      stable_bump_sha = commit_all(repo, "Bump version to 1.0.1")
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("target version: 1.0.0")
      expect(stdout).to include("SKIP #{rc_bump_sha[0, 12]} Bump version to 1.0.1.rc.1")
      expect(stdout).to include("MANUAL #{stable_bump_sha[0, 12]} Bump version to 1.0.1")
      expect(stdout).to include("stable release version bump commit")
      expect(stdout).to include("manual fallback to take only the CHANGELOG hunks")
    end
  end

  it "blocks normal mode on stable final version bumps so changelog extraction is explicit" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1"))
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [1.0.1]\n- Final notes\n")
      stable_bump_sha = commit_all(repo, "Bump version to 1.0.1")
      git(repo, "checkout", "main")
      commit_count = git(repo, "rev-list", "--count", "main").strip

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).not_to be_success
      expect(stdout).to include("MANUAL #{stable_bump_sha[0, 12]} Bump version to 1.0.1")
      expect(stderr).to include("Manual inspection required for #{stable_bump_sha}")
      expect(stderr).to include("--ack-manual #{stable_bump_sha}")
      expect(stdout).not_to include("Forward-port complete")
      expect(git(repo, "rev-list", "--count", "main").strip).to eq(commit_count)
    end
  end

  it "requires a clean worktree before completing acknowledged manual-only plans" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1"))
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [1.0.1]\n- Final notes\n")
      stable_bump_sha = commit_all(repo, "Bump version to 1.0.1")

      git(repo, "checkout", "main")
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [1.0.1]\n- Manually copied final notes\n")

      stdout, stderr, status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--ack-manual", stable_bump_sha)

      expect(status).not_to be_success
      expect(stdout).to include("ACK-MANUAL #{stable_bump_sha[0, 12]} Bump version to 1.0.1")
      expect(stdout).not_to include("Nothing to cherry-pick")
      expect(stderr).to include("working tree is not clean")
    end
  end

  it "checks out the target branch before completing acknowledged manual-only plans" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1"))
      write_file(repo, "CHANGELOG.md", "# Change Log\n\n### [1.0.1]\n- Final notes\n")
      stable_bump_sha = commit_all(repo, "Bump version to 1.0.1")

      git(repo, "checkout", "main")
      git(repo, "checkout", "-b", "operator-notes")

      stdout, stderr, status =
        run_script(repo, "--source", "release/1.0.1", "--target", "main", "--ack-manual", stable_bump_sha)

      expect(status).to be_success, stderr
      expect(stdout).to include("ACK-MANUAL #{stable_bump_sha[0, 12]} Bump version to 1.0.1")
      expect(stdout).to include("Checking out main")
      expect(stdout).to include("Nothing to cherry-pick")
      expect(git(repo, "rev-parse", "--abbrev-ref", "HEAD").strip).to eq("main")
    end
  end

  it "picks version bumps when the target prerelease label is unknown" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1.beta.1"))
      beta_bump_sha = commit_all(repo, "Bump version to 1.0.1.beta.1")

      git(repo, "checkout", "main")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1.canary.1"))
      commit_all(repo, "Start canary prerelease")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stdout).to include("target version: 1.0.1.canary.1")
      expect(stdout).to include("PICK #{beta_bump_sha[0, 12]} Bump version to 1.0.1.beta.1")
      expect(stdout).not_to include("target main is already at 1.0.1.canary.1")
    end
  end

  it "warns when the target version file cannot be parsed" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1"))
      stable_bump_sha = commit_all(repo, "Bump version to 1.0.1")

      git(repo, "checkout", "main")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", "# version constant intentionally missing\n")
      commit_all(repo, "Break target version file")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stderr).to include("WARNING: VERSION constant not found")
      expect(stdout).to include("target version: UNKNOWN")
      expect(stdout).to include("MANUAL #{stable_bump_sha[0, 12]} Bump version to 1.0.1")
      expect(stdout).to include("stable release version bump commit")
    end
  end

  it "skips prerelease version bumps when the target version file cannot be parsed" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", version_file("1.0.1.beta.1"))
      beta_bump_sha = commit_all(repo, "Bump version to 1.0.1.beta.1")

      git(repo, "checkout", "main")
      write_file(repo, "react_on_rails/lib/react_on_rails/version.rb", "# version constant intentionally missing\n")
      commit_all(repo, "Break target version file")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stderr).to include("WARNING: VERSION constant not found")
      expect(stdout).to include("target version: UNKNOWN")
      expect(stdout).to include("SKIP #{beta_bump_sha[0, 12]} Bump version to 1.0.1.beta.1")
      expect(stdout).to include("prerelease version bump commit with target version UNKNOWN")
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

  it "does not recurse forever when target revert messages reference each other" do
    helper = ReleaseForwardPort.new([])
    first_sha = "a" * 40
    second_sha = "b" * 40

    allow(helper).to receive(:standard_revert_shas_on_target) do |sha, target|
      case [sha, target]
      when [first_sha, "main"]
        [second_sha]
      when [second_sha, "main"]
        [first_sha]
      else
        raise "unexpected standard_revert_shas_on_target call: #{[sha, target].inspect}"
      end
    end
    allow(helper).to receive(:commit_descends_from?).and_return(true)

    result = nil
    expect { result = helper.send(:standard_revert_on_target?, first_sha, "main") }.not_to raise_error
    expect(result).to be(false)
  end

  it "does not crash when a standard revert footer references a missing commit" do
    with_release_repo do |repo|
      missing_sha = "a" * 40
      git(repo, "checkout", "-b", "release/1.0.1")
      git(
        repo,
        "commit",
        "--allow-empty",
        "--no-gpg-sign",
        "-m",
        "Revert \"Missing release commit\"",
        "-m",
        "This reverts commit #{missing_sha}."
      )
      revert_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stderr).not_to include("ERROR")
      expect(stdout).to include("SKIP #{revert_sha[0, 12]} Revert \"Missing release commit\"")
      expect(stdout).to include("empty commit; cherry-picking would only create a no-op commit on main")
    end
  end

  it "handles invalid byte patches without encoding errors during patch-id checks" do
    with_release_repo do |repo|
      git(repo, "checkout", "-b", "release/1.0.1")
      write_binary_file(repo, "invalid-bytes.txt", "\xffrelease bytes\n".b)
      binary_fix_sha = commit_all(repo, "Fix release binary payload")
      git(repo, "checkout", "main")

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main", "--dry-run")

      expect(status).to be_success, stderr
      expect(stderr).not_to include("ERROR")
      expect(stdout).to include("PICK #{binary_fix_sha[0, 12]} Fix release binary payload")
    end
  end

  it "picks mode-only commits instead of treating hunkless patch-id output as empty" do
    with_release_repo do |repo|
      write_file(repo, "script.sh", "#!/bin/sh\necho base\n")
      commit_all(repo, "Add script")
      expect(executable_file?(repo, "script.sh")).to be(false)

      git(repo, "checkout", "-b", "release/1.0.1")
      git(repo, "update-index", "--chmod=+x", "script.sh")
      FileUtils.chmod(0o755, File.join(repo, "script.sh"))
      git(repo, "commit", "--no-gpg-sign", "-m", "Make script executable")
      mode_fix_sha = git(repo, "rev-parse", "HEAD").strip
      git(repo, "checkout", "main")
      expect(executable_file?(repo, "script.sh")).to be(false)

      stdout, stderr, status = run_script(repo, "--source", "release/1.0.1", "--target", "main")

      expect(status).to be_success, stderr
      expect(stdout).to include("PICK #{mode_fix_sha[0, 12]} Make script executable")
      expect(stdout).to include("Forward-port complete")
      expect(executable_file?(repo, "script.sh")).to be(true)
    end
  end

  it "does not suggest cherry-pick --continue when Git did not start a cherry-pick" do
    helper = ReleaseForwardPort.new([])
    entry = ReleaseForwardPort::PlanEntry.new(sha: "a" * 40, subject: "Fix release regression", action: :pick)

    allow(helper).to receive(:cherry_pick_in_progress?).and_return(false)

    expect do
      helper.send(:warn_cherry_pick_failure, entry, completed: 0, remaining: 1)
    end.to output(/\A(?=.*Git did not leave a cherry-pick in progress)(?!.*--continue).*\z/m).to_stderr
  end

  it "rejects a pre-existing cherry-pick before checking worktree cleanliness" do
    helper = ReleaseForwardPort.new([])

    allow(helper).to receive(:cherry_pick_in_progress?).and_return(true)
    expect(helper).not_to receive(:git).with("status", "--porcelain")

    expect do
      helper.send(:ensure_clean_worktree!)
    end.to raise_error(
      ReleaseForwardPort::GitError,
      "a cherry-pick is already in progress; run git cherry-pick --continue or --abort first"
    )
  end
end
