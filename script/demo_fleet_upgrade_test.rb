# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "demo_fleet_upgrade"

class DemoFleetUpgradeEditorsTest < Minitest::Test
  def test_version_accepts_gem_and_npm_forms
    [%w[17.2.1.rc.1 17.2.1.rc.1 17.2.1-rc.1], %w[17.2.1-rc.1 17.2.1.rc.1 17.2.1-rc.1],
     %w[17.2.1 17.2.1 17.2.1]].each do |input, gem, npm|
      version = DemoFleetUpgrade::Version.parse(input)
      assert_equal [gem, npm], [version.gem, version.npm], input
    end
    assert_raises(DemoFleetUpgrade::Error) { DemoFleetUpgrade::Version.parse("17.2") }
  end

  def test_gemfile_rewrite_keeps_quote_style_and_operator
    text = <<~RUBY
      gem "react_on_rails", "= 17.2.0"
      gem 'react_on_rails_pro', '17.2.0', require: false
      gem "shakapacker", "10.1.0"
    RUBY
    new_text, changes, errors = DemoFleetUpgrade::GemfileEditor.rewrite(text, pins("17.2.1.rc.1"))

    assert_empty errors
    assert_equal <<~RUBY, new_text
      gem "react_on_rails", "= 17.2.1.rc.1"
      gem 'react_on_rails_pro', '17.2.1.rc.1', require: false
      gem "shakapacker", "10.1.0"
    RUBY
    assert_equal [%w[react_on_rails 17.2.0 17.2.1.rc.1], %w[react_on_rails_pro 17.2.0 17.2.1.rc.1]], changes
  end

  def test_gemfile_rewrite_reports_non_exact_requirements_instead_of_guessing
    text = %(gem "react_on_rails_pro", "~> 17.2"\n)
    new_text, changes, errors = DemoFleetUpgrade::GemfileEditor.rewrite(text, pins("17.2.1.rc.1"))

    assert_equal text, new_text
    assert_empty changes
    assert_match(/without an exact version/, errors.first)
  end

  def test_locked_versions_reads_gem_specs_only
    lock = "GEM\n  specs:\n    react_on_rails (17.2.0)\n      rails (>= 7)\n    react_on_rails_pro (17.2.0)\n      " \
           "react_on_rails (= 17.2.0)\n"
    assert_equal({ "react_on_rails" => "17.2.0", "react_on_rails_pro" => "17.2.0" },
                 DemoFleetUpgrade::GemfileEditor.locked_versions(lock, %w[react_on_rails react_on_rails_pro]))
  end

  def test_package_json_rewrite_reaches_overrides_and_skips_protocols
    text = <<~JSON
      {
        "dependencies": { "react-on-rails-pro": "17.2.0", "react-on-rails-rsc": "19.3.0" },
        "pnpm": { "overrides": { "react-on-rails": "17.2.0" } },
        "devDependencies": { "react-on-rails-pro-node-renderer": "workspace:*" }
      }
    JSON
    npm = %w[react-on-rails react-on-rails-pro react-on-rails-pro-node-renderer].to_h { |n| [n, "17.2.1-rc.1"] }
    new_text, changes, errors = DemoFleetUpgrade::PackageJsonEditor.rewrite(text, npm)

    assert_includes new_text, %("react-on-rails-pro": "17.2.1-rc.1")
    assert_includes new_text, %("react-on-rails": "17.2.1-rc.1")
    assert_includes new_text, %("react-on-rails-rsc": "19.3.0")
    assert_includes new_text, %("react-on-rails-pro-node-renderer": "workspace:*")
    assert_equal 2, changes.size
    assert_match(/workspace:\*/, errors.first)
  end

  def test_child_env_drops_version_manager_installs_ahead_of_shims
    path = "/home/u/.local/share/mise/installs/ruby/4.0.5/bin:/usr/bin:/home/u/.local/share/mise/shims:" \
           "/home/u/.local/share/mise/installs/ruby/3.4.6/bin"
    env = DemoFleetUpgrade::CommandRunner.child_env(path)

    assert_equal "/usr/bin:/home/u/.local/share/mise/shims:/home/u/.local/share/mise/installs/ruby/3.4.6/bin",
                 env.fetch("PATH")
    assert_nil env.fetch("BUNDLE_GEMFILE")
  end

  def test_manifest_selects_by_short_or_full_name
    manifest = DemoFleetUpgrade::Manifest.new("repos" => [{ "name" => "shakacode/demo-a" }])
    assert_equal(["shakacode/demo-a"], manifest.select(["demo-a"]).map { |r| r["name"] })
    assert_raises(DemoFleetUpgrade::Error) { manifest.select(["demo-b"]) }
  end

  def test_checked_in_manifest_loads
    manifest = DemoFleetUpgrade::Manifest.load
    assert_equal "chore/demo-fleet", manifest.branch_prefix
    refute_empty manifest.repos
  end

  private

  def pins(version) = %w[react_on_rails react_on_rails_pro].to_h { |name| [name, version] }
end

# Simulates bundle, the JS package manager, and gh; runs real git against local fixture repos.
class FakeFleetRunner < DemoFleetUpgrade::CommandRunner
  attr_reader :calls, :prs
  attr_accessor :fail_steps

  def initialize
    super
    @calls = []
    @prs = []
    @fail_steps = []
  end

  def run(argv, chdir:, env: {}, timeout: 900)
    @calls << argv
    return super if argv.first == "git"
    return result("", false) if fail_steps.any? { |pattern| argv.join(" ").include?(pattern) }

    case argv.first
    when "bundle" then fake_bundle(argv, chdir)
    when "gh" then fake_gh(argv)
    else
      File.write(File.join(chdir, "package-lock.json"), File.read(File.join(chdir, "package.json"))) if
        argv.include?("--package-lock-only")
      result("ok", true)
    end
  end

  private

  def result(output, success) = Result.new(output:, success:)

  def fake_bundle(argv, chdir)
    if argv[1] == "lock"
      lock = File.join(chdir, "Gemfile.lock")
      target = File.read(File.join(chdir, "Gemfile"))[/react_on_rails_pro", "= ([^"]+)"/, 1]
      File.write(lock, File.read(lock).gsub(/\((\d[\w.]*)\)/, "(#{target})"))
    end
    result("ok", true)
  end

  def fake_gh(argv)
    case argv[1..2]
    when %w[pr list] then result(JSON.generate(@prs), true)
    when %w[pr create]
      url = "https://github.com/shakacode/demo-app/pull/#{@prs.size + 1}"
      head = argv[argv.index("--head") + 1]
      @prs << { "number" => @prs.size + 1, "url" => url, "state" => "OPEN", "headRefName" => head,
                "title" => "Upgrade React on Rails" }
      result("#{url}\n", true)
    else result("unexpected gh call", false)
    end
  end
end

# Builds a bare remote plus an operator clone and runs the CLI against them.
module FleetFixture
  BRANCH = "chore/demo-fleet/react-on-rails-17.2.1.rc.1"

  def setup
    @tmp = Dir.mktmpdir("demo-fleet-upgrade")
    @saved_env = ENV.to_h.slice(*git_env.keys)
    git_env.each { |key, value| ENV[key] = value }
    @remote = File.join(@tmp, "remote.git")
    @demos = File.join(@tmp, "demos")
    @clone = File.join(@demos, "demo-app")
    build_fixture
    @runner = FakeFleetRunner.new
  end

  def teardown
    git_env.each_key { |key| ENV[key] = @saved_env[key] }
    FileUtils.rm_rf(@tmp)
  end

  private

  def git_env
    { "GIT_CONFIG_GLOBAL" => File::NULL, "GIT_CONFIG_NOSYSTEM" => "1", "GIT_AUTHOR_NAME" => "Fleet Test",
      "GIT_AUTHOR_EMAIL" => "fleet@example.com", "GIT_COMMITTER_NAME" => "Fleet Test",
      "GIT_COMMITTER_EMAIL" => "fleet@example.com" }
  end

  def manifest
    DemoFleetUpgrade::Manifest.new(
      "defaults" => { "branch_prefix" => "chore/demo-fleet", "package_manager" => "npm" },
      "repos" => [{ "name" => "shakacode/demo-app", "js_test" => nil }]
    )
  end

  def run_cli(*args, version: "17.2.1.rc.1")
    out = StringIO.new
    argv = [version, "--demos-dir", @demos, "--work-dir", File.join(@tmp, "work"), "--skip-registry-check",
            "--jobs", "1", *args]
    code = DemoFleetUpgrade::CLI.new(argv, runner: @runner, out:, manifest:).run
    [out.string, code]
  end

  def build_fixture
    seed = File.join(@tmp, "seed")
    FileUtils.mkdir_p(seed)
    File.write(File.join(seed, "Gemfile"), %(source "https://rubygems.org"\ngem "react_on_rails_pro", "= 17.2.0"\n))
    File.write(File.join(seed, "Gemfile.lock"),
               "GEM\n  specs:\n    react_on_rails (17.2.0)\n    react_on_rails_pro (17.2.0)\n      react_on_rails\n")
    package = { "packageManager" => "npm@10.8.2", "dependencies" => { "react-on-rails-pro" => "17.2.0" },
                "overrides" => { "react-on-rails" => "17.2.0" } }
    File.write(File.join(seed, "package.json"), "#{JSON.pretty_generate(package)}\n")
    File.write(File.join(seed, "package-lock.json"), "{}\n")
    sh("git", "init", "-q", "-b", "main", seed)
    sh("git", "-C", seed, "add", ".")
    sh("git", "-C", seed, "commit", "-q", "-m", "seed")
    sh("git", "clone", "-q", "--bare", seed, @remote)
    sh("git", "clone", "-q", @remote, @clone)
    sh("git", "-C", @clone, "remote", "set-url", "origin", @remote)
    # The script matches origin against the manifest slug; a local path alias keeps the fixture offline.
    FileUtils.mkdir_p(File.join(@tmp, "shakacode"))
    File.symlink(@remote, File.join(@tmp, "shakacode", "demo-app.git"))
    sh("git", "-C", @clone, "remote", "set-url", "origin", File.join(@tmp, "shakacode", "demo-app.git"))
    sh("git", "-C", @clone, "fetch", "-q", "origin")
    sh("git", "-C", @clone, "remote", "set-head", "origin", "main")
  end

  def push_foreign_commit(file, from: BRANCH)
    other = File.join(@tmp, "other-#{file}")
    sh("git", "clone", "-q", "-b", from, @remote, other)
    sh("git", "-C", other, "checkout", "-q", "-B", BRANCH)
    File.write(File.join(other, file), "fix\n")
    sh("git", "-C", other, "add", file)
    sh("git", "-C", other, "commit", "-q", "-m", "agent fix")
    sh("git", "-C", other, "push", "-q", "-f", "origin", BRANCH) # simulates another writer, not the script
    remote_branch_sha
  end

  def push_to_main(write: {}, delete: [])
    other = File.join(@tmp, "main-#{rand(1_000_000)}")
    sh("git", "clone", "-q", @remote, other)
    write.each do |path, text|
      FileUtils.mkdir_p(File.dirname(File.join(other, path)))
      File.write(File.join(other, path), text)
    end
    sh("git", "-C", other, "rm", "-q", *delete) unless delete.empty?
    sh("git", "-C", other, "add", "-A")
    sh("git", "-C", other, "commit", "-q", "-m", "main moves on")
    sh("git", "-C", other, "push", "-q", "origin", "main")
  end

  def remote_branch_sha
    out, status = Open3.capture2e("git", "--git-dir", @remote, "rev-parse", "--verify", "--quiet",
                                  "refs/heads/#{BRANCH}")
    status.success? ? out.strip : nil
  end

  def sh(*argv)
    out, status = Open3.capture2e(*argv)
    raise "#{argv.join(' ')} failed: #{out}" unless status.success?

    out.strip
  end
end

class DemoFleetUpgradeFlowTest < Minitest::Test
  include FleetFixture

  def test_dry_run_plans_without_touching_git_state
    out, code = run_cli

    assert_equal 0, code
    assert_match(/planned/, out)
    assert_match(/react_on_rails_pro 17\.2\.0 -> 17\.2\.1\.rc\.1/, out)
    refute remote_branch_sha
    refute File.exist?(File.join(@tmp, "work"))
    assert_equal "main", sh("git", "-C", @clone, "branch", "--show-current")
  end

  def test_execute_pushes_branch_and_opens_one_draft_pr
    out, code = run_cli("--execute")

    assert_equal 0, code, out
    assert_match(%r{pr opened .*|https://github.com/shakacode/demo-app/pull/1}, out)
    assert remote_branch_sha
    create = @runner.calls.find { |argv| argv[0..2] == %w[gh pr create] }
    assert_includes create, "--draft"
    changed = sh("git", "--git-dir", @remote, "diff", "--name-only", "main", BRANCH).split
    assert_equal %w[Gemfile Gemfile.lock package-lock.json package.json], changed.sort
    assert_includes sh("git", "--git-dir", @remote, "show", "#{BRANCH}:Gemfile.lock"), "react_on_rails (17.2.1.rc.1)"
    assert_equal "main", sh("git", "-C", @clone, "branch", "--show-current"), "operator checkout must stay put"
  end

  def test_rerun_reuses_branch_and_pr_without_new_commits
    run_cli("--execute")
    first_sha = remote_branch_sha

    out, code = run_cli("--execute")

    assert_equal 0, code, out
    assert_match(/pr reused/, out)
    assert_equal first_sha, remote_branch_sha
    assert_equal(1, @runner.calls.count { |argv| argv[0..2] == %w[gh pr create] })
  end

  def test_rerun_builds_on_someone_elses_pushed_commit
    run_cli("--execute")
    foreign = push_foreign_commit("agent-fix.txt")

    out, code = run_cli("--execute")

    assert_equal 0, code, out
    assert_equal foreign, remote_branch_sha, "the agent's commit stays the branch tip"
  end

  def test_diverged_branch_fails_without_force_push
    run_cli("--execute", "--no-push")
    foreign = push_foreign_commit("agent-fix.txt", from: "main")

    out, code = run_cli("--execute")

    assert_equal 1, code
    assert_match(/diverged/, out)
    assert_equal foreign, remote_branch_sha
  end

  def test_smoke_failure_is_reported_and_still_opens_draft
    @runner.fail_steps = ["npm ci"]

    out, code = run_cli("--execute", "--smoke", "install")

    assert_equal 1, code
    assert_match(/fail \(js-install\)/, out)
    assert remote_branch_sha
  end

  def test_repo_already_on_target_is_up_to_date
    out, = run_cli(version: "17.2.0")

    assert_match(/up to date/, out)
  end
end

class DemoFleetUpgradeEdgeCaseTest < Minitest::Test
  include FleetFixture

  def test_pins_files_the_default_branch_added_after_the_operator_checkout
    push_to_main(write: { "client/package.json" => %({ "dependencies": { "react-on-rails": "17.2.0" } }\n) })

    out, code = run_cli("--execute")

    assert_equal 0, code, out
    assert_includes sh("git", "--git-dir", @remote, "show", "#{BRANCH}:client/package.json"), "17.2.1-rc.1"
  end

  def test_repo_without_js_lockfile_still_opens_pr
    push_to_main(delete: %w[package.json package-lock.json])

    out, code = run_cli("--execute")

    assert_equal 0, code, out
    assert_match(/pr opened/, out)
    body = File.read(File.join(@tmp, "work", "logs", "demo-app", "pr-body.md"))
    assert_match(/No JS lockfile found/, body)
  end

  def test_rejecting_commit_hook_fails_the_repo_without_pushing
    hook = File.join(@clone, ".git", "hooks", "pre-commit")
    File.write(hook, "#!/bin/sh\necho blocked by hook\nexit 1\n")
    File.chmod(0o755, hook)

    out, code = run_cli("--execute")

    assert_equal 1, code
    assert_match(/commit failed/, out)
    refute remote_branch_sha
  end
end
