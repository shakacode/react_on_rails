# frozen_string_literal: true

# Upgrades the React on Rails demo fleet to one release candidate and opens the
# first draft PR in each demo repository. See script/demo-fleet-upgrade --help.
#
# The script does only the mechanical part of an RC fleet upgrade: pin bumps,
# lockfile regeneration with each repo's own tools, a cheap local smoke check,
# commit, push, and a draft PR. Review apps, CI baseline fixes, and deployed
# verification stay with agents and humans.

require "fileutils"
require "json"
require "net/http"
require "open3"
require "optparse"
require "shellwords"
require "timeout"
require "uri"
require "yaml"

# Pipes and File.read inherit the default external encoding at creation time.
Encoding.default_external = Encoding::UTF_8

module DemoFleetUpgrade
  MANIFEST_PATH = File.expand_path("../internal/contributor-info/demo-fleet.yml", __dir__)
  COORDINATED_GEMS = %w[react_on_rails react_on_rails_pro].freeze
  COORDINATED_NPM = %w[react-on-rails react-on-rails-pro react-on-rails-pro-node-renderer].freeze
  COMMIT_TRAILER = "Demo-Fleet-Upgrade"
  SMOKE_MARKER = /<!-- demo-fleet-upgrade:smoke=(.*?) -->/
  LOCKFILES = {
    "package-lock.json" => "npm", "pnpm-lock.yaml" => "pnpm", "yarn.lock" => "yarn"
  }.freeze
  # Strips the parent process's Bundler state so each demo resolves its own Gemfile.
  CHILD_ENV = %w[BUNDLE_GEMFILE BUNDLE_BIN_PATH BUNDLER_SETUP BUNDLER_VERSION RUBYOPT RUBYLIB]
              .to_h { |key| [key, nil] }.freeze

  class Error < StandardError; end
  class SkipRepo < Error; end
  class NeedsAgent < Error; end

  # Converts between the gem form (17.2.1.rc.1) and the npm form (17.2.1-rc.1).
  Version = Struct.new(:gem, :npm) do
    def self.parse(text)
      match = /\A(\d+\.\d+\.\d+)(?:[.-]([a-z]+)\.?(\d+))?\z/.match(text.to_s.strip)
      raise Error, "Unrecognized version #{text.inspect}; use 17.2.1.rc.1 or 17.2.1-rc.1" unless match

      core, tag, number = match.captures
      return new(core, core) unless tag

      new("#{core}.#{tag}.#{number}", "#{core}-#{tag}.#{number}")
    end
  end

  # Rewrites exact version pins in a Gemfile, keeping quotes and an existing "=" operator.
  module GemfileEditor
    module_function

    def declares?(text, names)
      names.any? { |name| text.match?(/^\s*gem\s*\(?\s*(["'])#{Regexp.escape(name)}\1/) }
    end

    # Returns [new_text, changes, errors]; changes are [name, from, to] triples.
    def rewrite(text, pins)
      changes = []
      errors = []
      lines = text.lines.map do |line|
        name = pins.keys.find { |gem_name| line.match?(/^\s*gem\s*\(?\s*(["'])#{Regexp.escape(gem_name)}\1/) }
        next line unless name

        rewrite_line(line, name, pins.fetch(name), changes, errors)
      end
      [lines.join, changes, errors]
    end

    def rewrite_line(line, name, target, changes, errors)
      pattern = /\A(\s*gem\s*\(?\s*(["'])#{Regexp.escape(name)}\2\s*,\s*)(["'])(=\s*)?(\d[\w.]*)\3/
      match = pattern.match(line)
      unless match
        errors << "Gemfile pins #{name} without an exact version (#{line.strip}); update it by hand"
        return line
      end
      return line if match[5] == target

      changes << [name, match[5], target]
      "#{match[1]}#{match[3]}#{match[4]}#{target}#{match[3]}#{match.post_match}"
    end

    # Locked versions of the named gems, from the GEM specs section of a Gemfile.lock.
    def locked_versions(lock_text, names)
      names.each_with_object({}) do |name, versions|
        locked = lock_text[/^ {4}#{Regexp.escape(name)} \(([^)]+)\)$/, 1]
        versions[name] = locked if locked
      end
    end
  end

  # Rewrites version strings for named packages in a package.json's dependency sections
  # (dependencies, devDependencies, optionalDependencies, overrides, resolutions, pnpm.overrides).
  # A small scanner records each string value's JSON path and position, so edits touch only
  # those entries and the rest of the file keeps its formatting.
  module PackageJsonEditor
    module_function

    # A pin the script can replace: an exact version, optionally with ^, ~ or =.
    PINNABLE = /\A[~^=]?\s*v?\d+\.\d+\.\d+[\w.+-]*\z/
    DEPENDENCY_SECTIONS = %w[dependencies devDependencies optionalDependencies].freeze
    OVERRIDE_SECTIONS = [%w[overrides], %w[resolutions], %w[pnpm overrides]].freeze

    def declares?(text, names) = names.any? { |name| entries(text, name).any? }

    def rewrite(text, pins)
      changes = []
      errors = []
      edits = pins.flat_map do |name, target|
        entries(text, name).filter_map do |value, from, to|
          unless value.match?(PINNABLE)
            errors << "package.json sets #{name} to #{value}; update it by hand"
            next
          end
          changes << [name, value, target] unless value == target
          [from, to, target]
        end
      end
      [apply_edits(text, edits), changes, errors]
    rescue JSON::ParserError => e
      [text, [], ["package.json does not parse (#{e.message.lines.first.strip}); update it by hand"]]
    end

    # Applies [from, to, replacement] edits back to front so earlier offsets stay valid.
    def apply_edits(text, edits)
      edits.sort_by { |from, _to, _replacement| -from }.each_with_object(text.dup) do |(from, to, replacement), out|
        out[from...to] = replacement
      end
    end

    # [value, from, to] for each pin of the named package, where from...to spans the value's characters.
    def entries(text, name)
      JSON.parse(text)
      string_values(text).filter_map do |path, value, from, to|
        [value, from, to] if pin_path?(path, name)
      end
    end

    def pin_path?(path, name)
      return path.size == 2 && path.last == name if DEPENDENCY_SECTIONS.include?(path.first)

      override_path?(path, name)
    end

    def override_path?(path, name)
      section = OVERRIDE_SECTIONS.find { |prefix| path.first(prefix.size) == prefix }
      return false unless section && path.size > section.size

      # npm's object form keeps a package's own version under ".".
      key = path.last == "." ? path[-2] : path.last
      key == name || (path.first == "resolutions" && key.to_s.end_with?("/#{name}"))
    end

    # Yields [path, value, from, to] for every string value; path holds object keys and array indexes.
    def string_values(text)
      values = []
      stack = []
      index = 0
      while index < text.length
        if text[index] == '"'
          index = read_string(text, index, stack, values)
        else
          track_structure(text[index], stack)
        end
        index += 1
      end
      values
    end

    # Pushes, pops, and advances the stack of [kind, key-or-index] frames.
    def track_structure(char, stack)
      case char
      when "{" then stack << [:object, nil]
      when "[" then stack << [:array, 0]
      when "}", "]" then stack.pop
      when "," then stack.last[1] = stack.last[0] == :array ? stack.last[1] + 1 : nil
      end
    end

    # Records a string as the open object's key, or as a value at the current path; returns its closing offset.
    def read_string(text, opening, stack, values)
      closing = string_end(text, opening)
      value = JSON.parse(text[opening..closing])
      frame = stack.last
      if frame && frame[0] == :object && frame[1].nil?
        frame[1] = value
      else
        values << [stack.map(&:last), value, opening + 1, closing]
      end
      closing
    end

    def string_end(text, opening)
      index = opening + 1
      index += text[index] == "\\" ? 2 : 1 until text[index] == '"'
      index
    end
  end

  # Reads demo-fleet.yml and resolves each repo's defaults.
  class Manifest
    attr_reader :repos, :branch_prefix

    def self.load(path = MANIFEST_PATH)
      data = YAML.safe_load_file(path, aliases: false)
      unless data["schema_version"] == 1
        raise Error,
              "Unsupported demo-fleet.yml schema_version #{data['schema_version']}"
      end

      new(data)
    end

    def initialize(data)
      defaults = data.fetch("defaults", {})
      @branch_prefix = defaults.fetch("branch_prefix", "chore/demo-fleet")
      @repos = data.fetch("repos").map { |repo| defaults.merge(repo) }
    end

    def select(filters)
      return repos.uniq { |repo| repo["name"] } if filters.empty?

      selected = filters.map do |filter|
        repos.find { |repo| [repo["name"], repo["name"].split("/").last].include?(filter) } ||
          raise(Error, "No manifest repo matches #{filter.inspect}")
      end
      selected.uniq { |repo| repo["name"] }
    end
  end

  # Runs a command, capturing combined output, with a timeout and a scrubbed environment.
  class CommandRunner
    Result = Struct.new(:output, :success, keyword_init: true)

    # A version-manager shim (mise, asdf) that launched this script puts its own Ruby and Node
    # ahead of the shims on PATH. Dropping those entries lets each demo's shims pick the
    # versions its .ruby-version and .node-version ask for.
    def self.child_env(path = ENV.fetch("PATH", ""))
      entries = path.split(File::PATH_SEPARATOR)
      shims = entries.index { |entry| entry.match?(%r{/(mise|asdf)/shims\z}) }
      if shims
        entries = entries.each_with_index.reject do |entry, index|
          index < shims && entry.match?(%r{/(mise|asdf)/installs/})
        end.map(&:first)
      end
      CHILD_ENV.merge("PATH" => entries.join(File::PATH_SEPARATOR), "__MISE_DIFF" => nil, "__MISE_SESSION" => nil,
                      "__MISE_SHIM" => nil)
    end

    def initialize(term_grace: 10)
      @term_grace = term_grace
    end

    def run(argv, chdir:, env: {}, timeout: 900)
      output = +""
      status = nil
      deadline = now + timeout
      Open3.popen2e(self.class.child_env.merge(env), *argv, chdir:, pgroup: true) do |stdin, out, wait|
        stdin.close
        reader = Thread.new { output << out.read.to_s }
        # The reader also waits on background descendants that keep stdout open, so it shares the deadline.
        finished = wait.join(timeout) && reader.join([deadline - now, 0].max)
        unless finished
          terminate(wait)
          reader.join(5)
          return Result.new(output: "#{output}\nTimed out after #{timeout}s", success: false)
        end
        status = wait.value
      end
      Result.new(output:, success: status.success?)
    rescue SystemCallError => e
      Result.new(output: e.message, success: false)
    end

    private

    def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # TERM the whole process group, then KILL the group after a grace period, since
    # descendants can outlive the parent.
    def terminate(wait)
      signal_group("TERM", wait.pid)
      wait.join(@term_grace)
      signal_group("KILL", wait.pid)
      wait.join(@term_grace)
    end

    def signal_group(signal, pid)
      Process.kill(signal, -pid)
    rescue Errno::ESRCH, Errno::EPERM
      nil
    end
  end

  # Per-repo outcome, rendered in the summary table and the JSON report.
  RepoResult = Struct.new(:repo, :branch, :pr_url, :smoke, :status, :error, :changes, :worktree, :logs,
                          keyword_init: true) do
    def to_h = super.transform_keys(&:to_s)
  end

  # One JS package root: picks its package manager and the lockfile/install commands for it.
  JsProject = Struct.new(:dir, :fallback_manager) do
    # Prefers the packageManager field, then the lockfile, then the manifest value.
    def package_manager
      @package_manager ||= begin
        name, version = declared_manager.split("@", 2)
        if name == "yarn" && version
          version.to_i >= 2 ? "yarn_berry" : "yarn_classic"
        elsif %w[npm pnpm].include?(name)
          name
        else
          lockfile_package_manager
        end
      end
    end

    def lock_command
      case package_manager
      when "npm" then pm_command("install", "--package-lock-only", "--ignore-scripts", "--no-audit", "--no-fund")
      when "pnpm" then pm_command("install", "--lockfile-only", "--ignore-scripts")
      when "yarn_berry" then pm_command("install", "--mode=update-lockfile")
      else pm_command("install", "--ignore-scripts", "--non-interactive")
      end
    end

    def frozen_install_command
      case package_manager
      when "npm" then pm_command("ci", "--no-audit", "--no-fund")
      when "pnpm" then pm_command("install", "--frozen-lockfile")
      when "yarn_berry" then pm_command("install", "--immutable")
      else pm_command("install", "--frozen-lockfile", "--non-interactive")
      end
    end

    def relative_to(root) = dir == root ? "." : dir.delete_prefix("#{root}/")

    private

    def declared_manager = JSON.parse(File.read(File.join(dir, "package.json")))["packageManager"].to_s

    def lockfile_package_manager
      lock = LOCKFILES.keys.find { |file| File.exist?(File.join(dir, file)) }
      return fallback_manager unless lock
      return LOCKFILES.fetch(lock) unless lock == "yarn.lock"

      File.read(File.join(dir, lock)).include?("__metadata:") ? "yarn_berry" : "yarn_classic"
    end

    # Corepack runs the exact pnpm or yarn release a packageManager field pins.
    def pm_command(*args)
      tool = package_manager.start_with?("yarn") ? "yarn" : package_manager
      prefix = !declared_manager.empty? && tool != "npm" ? ["corepack", tool] : [tool]
      prefix + args
    end
  end

  # Upgrades one demo repository. Every mutation goes through a separate git
  # worktree so the operator's checkout and its current branch stay untouched.
  # rubocop:disable Metrics/ClassLength
  class RepoUpgrade
    attr_reader :repo, :options, :runner, :result

    def initialize(repo, options, runner, branch_prefix:)
      @repo = repo
      @options = options
      @runner = runner
      @slug = repo.fetch("name")
      @basename = @slug.split("/").last
      @clone = File.join(options.fetch(:demos_dir), @basename)
      @branch = "#{branch_prefix}/react-on-rails-#{options.fetch(:version).gem}"
      @worktree = File.join(options.fetch(:work_dir), @basename)
      @log_dir = File.join(options.fetch(:work_dir), "logs", @basename)
      @result = RepoResult.new(repo: @basename, branch: @branch, smoke: "not run", changes: [], logs: [])
    end

    def call
      upgrade
    rescue SkipRepo => e
      finish("skipped", e.message)
    rescue NeedsAgent => e
      finish("needs agent", e.message)
    rescue Error => e
      finish("failed", e.message)
    rescue StandardError => e
      finish("failed", "#{e.class}: #{e.message}")
    end

    private

    def upgrade
      prepare_clone
      plan = read_plan(start_ref)
      result.changes = plan.fetch(:changes)
      return finish("needs agent", plan[:errors].join("; ")) unless plan[:errors].empty?
      return finish("up to date", nil) if result.changes.empty? && !remote_branch?

      options[:dry_run] ? dry_run_finish : execute
      result
    end

    def finish(status, error)
      result.status = status
      result.error = error
      result
    end

    def git(*args, chdir: @clone, allow_failure: false)
      outcome = runner.run(["git", *args], chdir:, timeout: 300)
      unless outcome.success || allow_failure
        raise Error,
              "git #{args.join(' ')} failed: #{outcome.output.strip.lines.last}"
      end

      outcome
    end

    def prepare_clone
      git_dir = File.join(@clone, ".git")
      raise SkipRepo, "No local clone at #{@clone} (clone #{@slug} there first)" unless File.directory?(git_dir)

      # The configured fetch and push URLs, before any insteadOf rewrite, must name the manifest repo on GitHub.
      urls = %w[url pushurl].flat_map do |key|
        git("config", "--get-all", "remote.origin.#{key}", allow_failure: true).output.lines.map(&:strip)
      end
      wrong = urls.reject { |url| github_origin?(url) }
      raise Error, "#{@clone} origin #{wrong.join(', ')} is not github.com/#{@slug}" if urls.empty? || wrong.any?

      git("fetch", "--prune", "origin") unless options[:no_fetch]
      @default_branch = detect_default_branch
    end

    def github_origin?(url)
      slug = Regexp.escape(@slug)
      url.match?(%r{\A(?:git@github\.com:|ssh://git@github\.com/|https://github\.com/)#{slug}(?:\.git)?/?\z}i)
    end

    def detect_default_branch
      head = git("symbolic-ref", "--short", "refs/remotes/origin/HEAD", allow_failure: true)
      return head.output.strip.delete_prefix("origin/") if head.success

      %w[main master].find { |name| ref_exists?("refs/remotes/origin/#{name}") } ||
        raise(Error, "Cannot find the default branch of #{@slug}")
    end

    def ref_exists?(ref, chdir: @clone)
      git("rev-parse", "--verify", "--quiet", ref, chdir:, allow_failure: true).success
    end

    def remote_branch? = ref_exists?("refs/remotes/origin/#{@branch}")

    def start_ref = remote_branch? ? "origin/#{@branch}" : "origin/#{@default_branch}"

    def show(ref, path, chdir: @clone)
      outcome = git("show", "#{ref}:#{path}", chdir:, allow_failure: true)
      outcome.success ? outcome.output : nil
    end

    def tracked_files(ref, chdir: @clone)
      git("ls-tree", "-r", "--name-only", ref, chdir:).output.lines.map(&:strip)
    end

    # Computes the pin edits a ref still needs, from committed file contents only.
    def read_plan(ref, chdir: @clone)
      files = file_contents(ref, chdir:)
      changes = []
      errors = []
      declared = false
      files.each do |path, text|
        editor = path.end_with?("Gemfile") ? GemfileEditor : PackageJsonEditor
        declared ||= editor.declares?(text, path.end_with?("Gemfile") ? COORDINATED_GEMS : COORDINATED_NPM)
        pins = path.end_with?("Gemfile") ? gem_pins : npm_pins
        _text, file_changes, file_errors = editor.rewrite(text, pins)
        changes.concat(file_changes.map do |name, from, to|
                         { "file" => path, "name" => name, "from" => from, "to" => to }
                       end)
        errors.concat(file_errors)
      end
      errors << "No root or one-level Gemfile or package.json declares a React on Rails package" unless declared
      { changes:, errors:, files: }
    end

    def file_contents(ref, chdir:)
      paths = tracked_files(ref, chdir:).select do |path|
        path == "Gemfile" || (File.basename(path) == "package.json" && path.count("/") <= 1)
      end
      paths.to_h { |path| [path, show(ref, path, chdir:)] }.compact
    end

    def gem_pins
      COORDINATED_GEMS.to_h { |name| [name, options.fetch(:version).gem] }
                      .merge(options.fetch(:extra_bumps).fetch("gem", {}))
    end

    def npm_pins
      COORDINATED_NPM.to_h { |name| [name, options.fetch(:version).npm] }
                     .merge(options.fetch(:extra_bumps).fetch("npm", {}))
    end

    def dry_run_finish
      pr = existing_pr unless options[:offline]
      result.pr_url = pr&.fetch("url")
      action = remote_branch? ? "would update existing branch" : "would create branch from #{@default_branch}"
      finish("planned", [action, *related_pr_note].join("; "))
    end

    # Other open upgrade PRs (an earlier RC's lane, Dependabot) that an agent may need to reconcile.
    def related_pr_note
      return [] if options[:offline]

      outcome = runner.run(["gh", "pr", "list", "--repo", @slug, "--state", "open", "--limit", "100",
                            "--json", "url,headRefName,title"], chdir: @clone, timeout: 120)
      return ["could not list open PRs"] unless outcome.success

      related = JSON.parse(outcome.output).select do |pr|
        pr["headRefName"] != @branch && pr["title"].match?(/react[ _-]?on[ _-]?rails/i)
      end
      urls = related.map { |pr| pr["url"] }
      urls.empty? ? [] : ["other open upgrade PRs: #{urls.join(' ')}"]
    end

    def execute
      prepare_worktree
      apply_pins
      regenerate_gem_lock
      regenerate_js_lock
      run_smoke
      committed = commit_changes
      return finish(committed ? "committed locally" : "no changes", nil) if options[:no_push]

      head = git("rev-parse", "HEAD", chdir: @worktree).output.strip
      pushed = remote_branch? ? git("rev-parse", "origin/#{@branch}").output.strip : nil
      if pushed.nil? && head == git("rev-parse", "origin/#{@default_branch}").output.strip
        return finish("no changes", "Regeneration left nothing to commit")
      end

      @pushed_now = head != pushed
      push if @pushed_now
      ensure_pr
    end

    def prepare_worktree
      FileUtils.mkdir_p(@log_dir)
      if File.directory?(@worktree)
        reuse_worktree
      else
        FileUtils.mkdir_p(File.dirname(@worktree))
        if ref_exists?("refs/heads/#{@branch}")
          git("worktree", "add", @worktree, @branch)
        else
          git("worktree", "add", "--no-track", "-b", @branch, @worktree, start_ref)
        end
      end
      fast_forward_to_remote
      result.worktree = @worktree
    end

    def reuse_worktree
      current = git("branch", "--show-current", chdir: @worktree).output.strip
      raise Error, "#{@worktree} is on #{current}, not #{@branch}" unless current == @branch

      dirty = git("status", "--porcelain", "--untracked-files=no", chdir: @worktree).output
      raise Error, "#{@worktree} has uncommitted changes; commit or discard them first" unless dirty.strip.empty?
    end

    # Brings the local branch up to the pushed branch without ever rewriting history.
    def fast_forward_to_remote
      return unless remote_branch?

      merged = git("merge", "--ff-only", "origin/#{@branch}", chdir: @worktree, allow_failure: true)
      return if merged.success

      raise Error, "Local #{@branch} and origin/#{@branch} diverged; resolve by hand (never force-pushed)"
    end

    # Re-plans from the worktree, which can hold local commits the remote ref did not show.
    def apply_pins
      plan = read_plan("HEAD", chdir: @worktree)
      raise NeedsAgent, plan[:errors].join("; ") unless plan[:errors].empty?

      plan.fetch(:files).each_key do |path|
        full_path = File.join(@worktree, path)
        editor = path.end_with?("Gemfile") ? GemfileEditor : PackageJsonEditor
        pins = path.end_with?("Gemfile") ? gem_pins : npm_pins
        new_text, = editor.rewrite(File.read(full_path), pins)
        File.write(full_path, new_text)
      end
    end

    def regenerate_gem_lock
      lock_path = File.join(@worktree, "Gemfile.lock")
      return unless File.exist?(lock_path)

      names = (gem_pins.keys & GemfileEditor.locked_versions(File.read(lock_path), gem_pins.keys).keys)
      return if names.empty?

      step("bundle-lock", ["bundle", "lock", "--update", *names, "--conservative"], fatal: true)
    end

    def regenerate_js_lock
      env = { "YARN_ENABLE_IMMUTABLE_INSTALLS" => "false" }
      js_projects.each_with_index do |project, index|
        step(numbered("js-lock", index), project.lock_command, chdir: project.dir, env:, fatal: true)
      end
    end

    def numbered(name, index) = index.zero? ? name : "#{name}-#{index}"

    # Every directory (repo root or one level down) with its own package.json and lockfile.
    def js_projects
      @js_projects ||= begin
        dirs = [@worktree, *Dir[File.join(@worktree, "*/")].map { |dir| dir.chomp("/") }]
        dirs = dirs.select do |dir|
          File.exist?(File.join(dir, "package.json")) && LOCKFILES.keys.any? do |lock|
            File.exist?(File.join(dir, lock))
          end
        end
        dirs.map { |dir| JsProject.new(dir, repo.fetch("package_manager")) }
      end
    end

    # Smoke levels: none, install (frozen installs), quick (+ js_test), full (+ build, ruby_test).
    def run_smoke
      return result.smoke = "skipped" if options[:smoke] == "none"

      checks = [["bundle-install", %w[bundle install], @worktree, { "BUNDLE_FROZEN" => "true" }]]
      js_projects.each_with_index do |project, index|
        checks << [numbered("js-install", index), project.frozen_install_command, project.dir, {}]
      end
      manifest_checks.each { |name| checks << [name, ["bash", "-c", repo[name]], @worktree, {}] }
      failed = checks.find { |name, argv, chdir, env| !step(name, argv, chdir:, env:) }
      result.smoke = failed ? "fail (#{failed.first})" : "pass (#{checks.map(&:first).join(', ')})"
    end

    def manifest_checks
      names = { "quick" => %w[js_test], "full" => %w[js_test build ruby_test] }.fetch(options[:smoke], [])
      names.select { |name| repo[name].is_a?(String) && !repo[name].strip.empty? }
    end

    def step(name, argv, chdir: @worktree, env: {}, fatal: false)
      outcome = runner.run(argv, chdir:, env:, timeout: options.fetch(:timeout))
      log = File.join(@log_dir, "#{name}.log")
      File.write(log, "$ #{argv.shelljoin}\n#{outcome.output}")
      result.logs << log
      raise Error, "#{name} failed (see #{log})" if fatal && !outcome.success

      outcome.success
    end

    def commit_changes
      changed = git("diff", "--name-only", chdir: @worktree).output.lines.map(&:strip)
      return false if changed.empty?

      git("add", "--", *changed, chdir: @worktree)
      # Repository hooks run; a rejecting hook fails this repo with its log instead of being skipped.
      step("commit", ["git", "commit", "-m", commit_message], fatal: true)
      true
    end

    def commit_message
      version = options.fetch(:version).gem
      "Upgrade React on Rails to #{version}\n\nPins and lockfiles regenerated by " \
        "react_on_rails script/demo-fleet-upgrade.\n\n#{COMMIT_TRAILER}: #{version}\n"
    end

    def push
      git("push", "origin", "#{@branch}:refs/heads/#{@branch}", chdir: @worktree)
    end

    def existing_pr
      outcome = runner.run(["gh", "pr", "list", "--repo", @slug, "--head", @branch, "--state", "all",
                            "--json", "number,url,state"], chdir: @clone, timeout: 120)
      raise Error, "gh pr list failed: #{outcome.output.strip}" unless outcome.success

      prs = JSON.parse(outcome.output)
      prs.find { |pr| pr["state"] == "OPEN" } || prs.first
    end

    def ensure_pr
      pr = existing_pr
      if pr && pr["state"] != "OPEN"
        result.pr_url = pr["url"]
        return finish("pr #{pr['state'].downcase}", "Existing PR is #{pr['state'].downcase}; not reopening")
      end
      if pr
        result.pr_url = pr["url"]
        comment_rerun(pr) if @pushed_now || (result.smoke != "skipped" && last_reported_smoke(pr) != result.smoke)
        return finish("pr reused", nil)
      end

      create_pr
    end

    def create_pr
      body_path = File.join(@log_dir, "pr-body.md")
      File.write(body_path, pr_body)
      outcome = runner.run(["gh", "pr", "create", "--repo", @slug, "--base", @default_branch, "--head", @branch,
                            "--draft", "--title", "Upgrade React on Rails to #{options.fetch(:version).gem}",
                            "--body-file", body_path], chdir: @worktree, timeout: 120)
      raise Error, "gh pr create failed: #{outcome.output.strip}" unless outcome.success

      result.pr_url = outcome.output.strip.lines.last&.strip
      finish("pr opened", nil)
    end

    # A rerun never rewrites the PR description, which people may have edited; it adds this
    # run's evidence as a comment so the PR does not keep showing the first run's results.
    # The smoke result the PR last reported, from the hidden marker in its body and rerun comments.
    def last_reported_smoke(pull_request)
      outcome = runner.run(["gh", "pr", "view", pull_request.fetch("number").to_s, "--repo", @slug,
                            "--json", "body,comments"], chdir: @worktree, timeout: 120)
      return nil unless outcome.success

      data = JSON.parse(outcome.output)
      texts = [data["body"].to_s, *Array(data["comments"]).map { |comment| comment["body"].to_s }]
      texts.join("\n").scan(SMOKE_MARKER).flatten.last
    end

    def comment_rerun(pull_request)
      head = git("rev-parse", "--short", "HEAD", chdir: @worktree).output.strip
      body_path = File.join(@log_dir, "pr-rerun-comment.md")
      File.write(body_path, <<~MARKDOWN)
        Rerun of `script/demo-fleet-upgrade` at `#{head}`#{@pushed_now ? ' pushed new commits' : ''}. \
        These results replace the table and smoke line in the PR description.

        #{run_evidence}
      MARKDOWN
      argv = ["gh", "pr", "comment", pull_request.fetch("number").to_s, "--repo", @slug, "--body-file", body_path]
      outcome = runner.run(argv, chdir: @worktree, timeout: 120)
      raise Error, "gh pr comment failed: #{outcome.output.strip}" unless outcome.success
    end

    def run_evidence
      rows = result.changes.map { |c| "| `#{c['file']}` | `#{c['name']}` | `#{c['from']}` | `#{c['to']}` |" }
      <<~MARKDOWN.chomp
        | File | Package | Before | After |
        | --- | --- | --- | --- |
        #{rows.empty? ? '| (no pin changes on this run) | | | |' : rows.join("\n")}

        Locked gems after `bundle lock --update`: #{locked_gems_summary}.
        #{js_lock_summary}

        Local smoke: **#{result.smoke}**.
        <!-- demo-fleet-upgrade:smoke=#{result.smoke} -->
      MARKDOWN
    end

    def pr_body
      <<~MARKDOWN
        Upgrades React on Rails to `#{options.fetch(:version).gem}` (npm `#{options.fetch(:version).npm}`).

        #{run_evidence}
        #{options[:issue_url] ? "\nRelease tracking: #{options[:issue_url]}\n" : ''}
        Still needed before merge: this repo's CI, the review-app deploy and smoke (then shut it down),
        and any baseline fixes. Opened as a draft by `script/demo-fleet-upgrade` in shakacode/react_on_rails.
      MARKDOWN
    end

    def js_lock_summary
      return "No JS lockfile found, so no JS lockfile was regenerated." if js_projects.empty?

      js_projects.map do |project|
        "JS lockfile in `#{project.relative_to(@worktree)}` regenerated with `#{project.lock_command.shelljoin}` " \
          "(#{project.package_manager})."
      end.join("\n")
    end

    def locked_gems_summary
      lock_path = File.join(@worktree, "Gemfile.lock")
      return "none" unless File.exist?(lock_path)

      GemfileEditor.locked_versions(File.read(lock_path), gem_pins.keys).map { |name, v| "`#{name} #{v}`" }.join(", ")
    end
  end
  # rubocop:enable Metrics/ClassLength

  # Confirms the target versions are published before anything is changed.
  module Registry
    module_function

    def missing(version)
      gem_versions = fetch_json("https://rubygems.org/api/v1/versions/react_on_rails.json").map { |v| v["number"] }
      missing = gem_versions.include?(version.gem) ? [] : ["gem react_on_rails #{version.gem}"]
      COORDINATED_NPM.each do |name|
        uri = URI("https://registry.npmjs.org/#{name}/#{version.npm}")
        missing << "npm #{name} #{version.npm}" unless Net::HTTP.get_response(uri).is_a?(Net::HTTPSuccess)
      end
      missing
    end

    def fetch_json(url) = JSON.parse(Net::HTTP.get(URI(url)))
  end

  # Command-line entry point.
  class CLI
    FAILING_STATUSES = ["failed", "needs agent"].freeze
    def initialize(argv, runner: CommandRunner.new, out: $stdout, manifest: nil)
      @argv = argv
      @runner = runner
      @out = out
      @manifest = manifest
    end

    def run
      options = parse
      manifest = @manifest || Manifest.load(options[:manifest])
      check_registry(options)
      repos = manifest.select(options[:repos])
      results = run_repos(repos, options, manifest.branch_prefix)
      @out.puts(Table.render(results))
      write_json(options[:json], results) if options[:json]
      results.any? { |r| FAILING_STATUSES.include?(r.status) || r.smoke.start_with?("fail") } ? 1 : 0
    end

    private

    def write_json(path, results)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, JSON.pretty_generate(results.map(&:to_h)))
    end

    def run_repos(repos, options, branch_prefix)
      queue = Queue.new
      repos.each_with_index { |repo, index| queue << [repo, index] }
      results = Array.new(repos.size)
      workers = Array.new([options[:jobs], repos.size].min) do
        Thread.new do
          while (item = queue.pop(true) rescue nil) # rubocop:disable Style/RescueModifier
            repo, index = item
            results[index] = RepoUpgrade.new(repo, options, @runner, branch_prefix:).call
            @out.puts("#{results[index].repo}: #{results[index].status}")
          end
        end
      end
      workers.each(&:join)
      results
    end

    def check_registry(options)
      return if options[:offline] || options[:skip_registry_check]

      missing = Registry.missing(options[:version])
      return if missing.empty?
      raise Error, "Not published yet: #{missing.join(', ')}" unless options[:dry_run]

      @out.puts("Warning: not published yet: #{missing.join(', ')}")
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
    def parse
      options = { repos: [], extra_bumps: Hash.new { |h, k| h[k] = {} }, dry_run: true, smoke: "quick",
                  jobs: 4, timeout: 900, manifest: MANIFEST_PATH,
                  demos_dir: File.expand_path("~/claude/demos") }
      parser = OptionParser.new do |o|
        o.banner = "Usage: script/demo-fleet-upgrade VERSION [options]\n" \
                   "Bumps react_on_rails/react_on_rails_pro gems and react-on-rails* npm packages in every\n" \
                   "demo-fleet.yml repo, regenerates lockfiles, smoke-tests, pushes, and opens a draft PR.\n" \
                   "Dry run unless --execute is given."
        o.on("--execute", "Create branches, commit, push, and open draft PRs") { options[:dry_run] = false }
        o.on("--no-push", "With --execute: stop after the local commit") { options[:no_push] = true }
        o.on("--repos LIST", Array, "Comma-separated repo names (default: whole manifest)") { |v| options[:repos] = v }
        o.on("--bump ECOSYSTEM:NAME=VERSION", "Also pin another package, e.g. npm:react-on-rails-rsc=19.3.1") do |v|
          match = /\A(gem|npm):([^=]+)=(.+)\z/.match(v) || raise(OptionParser::InvalidArgument, v)
          options[:extra_bumps][match[1]][match[2]] = match[3]
        end
        o.on("--smoke LEVEL", %w[none install quick full], "none|install|quick|full (default quick)") do |v|
          options[:smoke] = v
        end
        o.on("--demos-dir DIR", "Directory of local clones (default ~/claude/demos)") { |v| options[:demos_dir] = v }
        o.on("--work-dir DIR", "Worktrees and logs (default DEMOS_DIR/.fleet-upgrade/VERSION)") do |v|
          options[:work_dir] = v
        end
        o.on("--jobs N", Integer, "Repos upgraded in parallel (default 4)") do |v|
          raise OptionParser::InvalidArgument, "--jobs must be at least 1" if v < 1

          options[:jobs] = v
        end
        o.on("--timeout SECONDS", Integer, "Per-command timeout (default 900)") { |v| options[:timeout] = v }
        o.on("--issue-url URL", "Release tracking issue linked from each PR") { |v| options[:issue_url] = v }
        o.on("--json PATH", "Also write results as JSON") { |v| options[:json] = v }
        o.on("--no-fetch", "Use already-fetched refs") { options[:no_fetch] = true }
        o.on("--offline", "Dry run without GitHub or registry calls (implies --no-fetch)") do
          options[:offline] = options[:no_fetch] = true
        end
        o.on("--skip-registry-check", "Do not confirm the version is published") do
          options[:skip_registry_check] = true
        end
        o.on("--manifest PATH", "Fleet manifest (default internal/contributor-info/demo-fleet.yml)") do |v|
          options[:manifest] = v
        end
      end
      rest = parser.parse(@argv)
      raise Error, parser.help unless rest.size == 1
      raise Error, "--offline only works for dry runs" if options[:offline] && !options[:dry_run]

      options[:version] = Version.parse(rest.first)
      options[:demos_dir] = File.expand_path(options[:demos_dir])
      options[:work_dir] = File.expand_path(
        options[:work_dir] || File.join(options[:demos_dir], ".fleet-upgrade", options[:version].gem)
      )
      options
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
  end

  # Renders the one summary table agents read after a run.
  module Table
    module_function

    HEADERS = %w[repo branch pr change smoke status error].freeze

    def render(results)
      rows = results.map { |r| row(r) }
      widths = HEADERS.each_index.map { |i| ([HEADERS[i]] + rows.map { |row| row[i].to_s }).map(&:length).max }
      line = ->(cells) { "| #{cells.each_with_index.map { |c, i| c.to_s.ljust(widths[i]) }.join(' | ')} |" }
      [line.call(HEADERS), line.call(widths.map { |w| "-" * w }), *rows.map(&line)].join("\n")
    end

    def row(result)
      [result.repo, result.branch, result.pr_url || "-", change_summary(result.changes), result.smoke,
       result.status, result.error || "-"]
    end

    # First pin change plus a count, e.g. "react_on_rails_pro 17.2.0 -> 17.2.1.rc.1 (+3)".
    def change_summary(changes)
      return "-" if changes.to_a.empty?

      first = changes.first
      more = changes.size > 1 ? " (+#{changes.size - 1})" : ""
      "#{first['name']} #{first['from']} -> #{first['to']}#{more}"
    end
  end
end
