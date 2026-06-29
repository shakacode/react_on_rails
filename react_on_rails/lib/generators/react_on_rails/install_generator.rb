# frozen_string_literal: true

require "rails/generators"
require "json"
require "bundler"
require "open3"
require_relative "generator_helper"
require_relative "generator_messages"
require_relative "js_dependency_manager"
require_relative "pro_setup"
require_relative "rsc_setup"
require_relative "shakapacker_precompile_hook_helper"
# Load-path require: git_utils lives under react_on_rails/lib, not relative to this generator directory.
require "react_on_rails/git_utils"

module ReactOnRails
  module Generators
    # TODO: Extract more modules to reduce class length below 150 lines.
    #       Candidates: ShakapackerSetup (~100 lines), TypeScriptSetup (~60 lines),
    #       ValidationHelpers (~80 lines for Node/package manager checks).
    # rubocop:disable Metrics/ClassLength
    class InstallGenerator < Rails::Generators::Base
      # Keep this Tailwind-only layout gate local so non-Tailwind installs can keep the lower gemspec floor.
      MINIMUM_SHAKAPACKER_VERSION_FOR_TAILWIND_LAYOUT = "6.5.6"

      include GeneratorHelper
      include JsDependencyManager
      include ProSetup
      include RscSetup
      include ShakapackerPrecompileHookHelper

      # fetch USAGE file for details generator description
      source_root(File.expand_path(__dir__))

      # Hidden legacy --redux escape hatch for existing scripted installs.
      class_option :redux,
                   type: :boolean,
                   default: false,
                   desc: "Deprecated legacy Redux install path; use react_on_rails:react_with_redux directly.",
                   aliases: "-R",
                   hide: true

      # --typescript
      class_option :typescript,
                   type: :boolean,
                   default: false,
                   desc: "Generate TypeScript files and install TypeScript dependencies. Default: false",
                   aliases: "-T"

      # --tailwind
      class_option :tailwind,
                   type: :boolean,
                   default: false,
                   desc: "Install Tailwind CSS v4 and style the generated SSR example. Default: false"

      # --rspack / --no-rspack (Rspack is the default on fresh installs; --no-rspack selects Webpack)
      # IMPORTANT: do NOT add a `default:` here. The absence of a default is load-bearing — Thor
      # only includes :rspack in the options hash when the flag is explicitly passed, which is how
      # GeneratorHelper#using_rspack? tells an explicit choice from "no flag given" (the latter
      # falls back to rspack_bundler_default). Adding `default: false` would make
      # options.key?(:rspack) always true and silently break the fresh-install Rspack default.
      # (Thor's omit-when-no-default behavior verified against Thor 1.5.0; see Gemfile.lock.)
      class_option :rspack,
                   type: :boolean,
                   desc: "Use Rspack (default) as the bundler; pass --no-rspack to use Webpack"

      # --webpack: friendly alias for --no-rspack (reconciled in GeneratorHelper#explicit_bundler_choice).
      # No `default:` here either — same load-bearing reason as --rspack above.
      class_option :webpack,
                   type: :boolean,
                   desc: "Use Webpack as the bundler (alias for --no-rspack; --no-webpack is equivalent to --rspack)"

      # --ignore-warnings
      class_option :ignore_warnings,
                   type: :boolean,
                   default: false,
                   desc: "Skip warnings. Default: false"

      # --agent-files / --no-agent-files
      # Emits consumer-scoped AI-agent guidance (AGENTS.md) plus thin editor pointer
      # files (CLAUDE.md, .cursor/rules/react-on-rails.mdc, .github/copilot-instructions.md).
      # Default ON; pass --no-agent-files to skip. Existing files are never overwritten.
      class_option :agent_files,
                   type: :boolean,
                   default: true,
                   desc: "Write AI-agent guidance files (AGENTS.md + editor pointers). Default: true"

      # --pro
      class_option :pro,
                   type: :boolean,
                   default: false,
                   desc: "Install React on Rails Pro with Node Renderer. Default: false"

      # --rsc
      class_option :rsc,
                   type: :boolean,
                   default: false,
                   desc: "Install React Server Components support (includes Pro). Default: false"

      # Hidden option: allows tests (and advanced users) to signal that Shakapacker
      # was just installed, triggering force-overwrite of shakapacker.yml with RoR's template.
      # The CLI flag takes precedence over runtime detection (@shakapacker_just_installed):
      # when this flag is set, shakapacker_just_installed? returns true immediately without
      # consulting the ivar. Passing this flag manually overrides runtime detection — the yml
      # will be force-overwritten with RoR's template even if it already exists, including
      # when Shakapacker is pre-configured (no prompt is shown).
      class_option :shakapacker_just_installed,
                   type: :boolean,
                   default: false,
                   hide: true

      # Hidden option: used by create-react-on-rails-app to enable fresh-app
      # scaffolding (landing page + browser-open defaults) without changing the
      # behavior of install runs inside existing apps.
      class_option :new_app,
                   type: :boolean,
                   default: false,
                   hide: true

      # Removed: --skip-shakapacker-install (Shakapacker is now a required dependency)

      HELLO_WORLD_ROUTE = "hello_world"
      HELLO_SERVER_ROUTE = "hello_server"
      # Matches the stock `bin/dev` written by Rails 8.x. Rails 7.1 commonly
      # generated a foreman-based shell script instead, which stock_rails_bin_dev?
      # also recognizes so the React on Rails template can replace either variant.
      STOCK_RAILS_BIN_DEV = <<~RUBY
        #!/usr/bin/env ruby
        exec "./bin/rails", "server", *ARGV
      RUBY
      # Recognize only known legacy Rails foreman templates. Any other variant is
      # treated as customized so install does not overwrite app-specific logic.
      LEGACY_FOREMAN_BIN_DEV_TEMPLATES = [
        <<~BASH,
          #!/usr/bin/env bash
          if ! gem list foreman -i --silent; then
            gem install foreman
          fi

          exec foreman start -f Procfile.dev "$@"
        BASH
        <<~SH,
          #!/usr/bin/env sh
          if ! gem list foreman -i --silent; then
            gem install foreman
          fi

          exec foreman start -f Procfile.dev "$@"
        SH
        <<~BASH,
          #!/usr/bin/env bash
          if ! gem list foreman -i --silent; then
            gem install foreman
          fi

          exec foreman start -f Procfile.dev $@
        BASH
        <<~SH
          #!/usr/bin/env sh
          if ! gem list foreman -i --silent; then
            gem install foreman
          fi

          exec foreman start -f Procfile.dev $@
        SH
      ].map { |template| template.gsub("\r\n", "\n").strip }.freeze

      # Exact fallback used when the scaffolded CI workflow has to supply a pnpm
      # version because `pnpm/action-setup` requires one unless package.json declares
      # `packageManager`. Match the repo's own packageManager version so generated
      # CI defaults to the pnpm major this codebase tests with. Track the exact release
      # used for this fallback at https://github.com/pnpm/pnpm/releases/tag/v10.33.4;
      # update this URL with the constant when bumping. Users who need exact
      # reproducibility should commit `packageManager` to their package.json instead.
      # Bump checklist: heading text below is spec-asserted.
      # CONTRIBUTING.md > "Updating the pnpm Fallback Version for Scaffolded CI".
      # renovate: datasource=github-releases depName=pnpm/pnpm extractVersion=^v(?<version>.+)$ allowedVersions=<11
      CI_PNPM_FALLBACK_VERSION = "10.33.4"
      private_constant :CI_PNPM_FALLBACK_VERSION

      # Main generator entry point
      #
      # Sets up React on Rails in a Rails application by:
      # 1. Validating prerequisites
      # 2. Installing required packages
      # 3. Generating configuration files
      # 4. Setting up example components
      #
      # @note Validation Skipping: Sets ENV["REACT_ON_RAILS_SKIP_VALIDATION"] to prevent
      #   version validation from running during generator execution. The npm package
      #   isn't installed until midway through the generator, so validation would fail
      #   if run during Rails initialization. The ensure block guarantees cleanup even
      #   if the generator fails.
      def run_generators
        # Set environment variable to skip validation during generator run
        # This is inherited by all invoked generators and persists through Rails initialization
        # See lib/react_on_rails/engine.rb for the validation skip logic
        ENV["REACT_ON_RAILS_SKIP_VALIDATION"] = "true"

        if installation_prerequisites_met? || options.ignore_warnings?
          invoke_generators
          add_package_json_scripts
          add_ci_workflow
          add_bin_scripts
          add_agent_files
          add_post_install_message
        else
          error = <<~MSG.strip
            🚫 React on Rails generator prerequisites not met!

            Please resolve the issues listed above before continuing.
            All prerequisites must be satisfied for a successful installation.

            Use --ignore-warnings to bypass checks (not recommended).
          MSG
          GeneratorMessages.add_error(error)
        end
      ensure
        # Always clean up ENV variable, even if generator fails
        # CRITICAL: ENV cleanup must come first to ensure it executes even if
        # print_generator_messages raises an exception. This prevents ENV pollution
        # that could affect subsequent processes.
        ENV.delete("REACT_ON_RAILS_SKIP_VALIDATION")
        add_legacy_redux_install_warning_once
        print_generator_messages
      end

      # Everything here is not run automatically b/c it's private

      private

      # Fresh-install context: default to Rspack (when Shakapacker supports it) unless the
      # app already declares a bundler. See GeneratorHelper#fresh_install_rspack_default.
      # NOTE: BaseGenerator#rspack_bundler_default is an intentional twin of this override
      # (both generators are independently CLI-invocable); keep the two in sync.
      def rspack_bundler_default
        fresh_install_rspack_default
      end

      def invoke_generators
        ensure_shakapacker_installed
        install_typescript_dependencies if options.typescript?
        # `invoke` instantiates child generators with a fresh options hash, so
        # --pretend/--force/--skip must be forwarded explicitly at each boundary.
        invoke "react_on_rails:base", [],
               { typescript: options.typescript?, redux: options.redux?, rspack: using_rspack?,
                 pro: use_pro?, rsc: use_rsc?, tailwind: use_tailwind?, new_app: options.new_app?,
                 shakapacker_just_installed: shakapacker_just_installed?,
                 force: options[:force], skip: options[:skip], pretend: options[:pretend] }

        if options.typescript?
          create_css_module_types
          create_typescript_config
        end

        # Component generator logic:
        # - --rsc without hidden legacy Redux: Skip HelloWorld; setup_rsc generates HelloServer.
        # - Hidden legacy --redux: Generate HelloWorldApp as a one-major escape hatch.
        # - Without --rsc: Generate the default HelloWorld example unless the legacy flag is present.
        if options.redux?
          invoke "react_on_rails:react_with_redux", [], { typescript: options.typescript?,
                                                          tailwind: use_tailwind?,
                                                          invoked_by_install: true,
                                                          new_app: options.new_app?,
                                                          rsc: use_rsc?,
                                                          force: options[:force], skip: options[:skip],
                                                          pretend: options[:pretend] }
        elsif !use_rsc?
          # Only generate HelloWorld if RSC is not enabled
          # For RSC, HelloServer replaces HelloWorld as the example component
          invoke "react_on_rails:react_no_redux", [], { typescript: options.typescript?,
                                                        tailwind: use_tailwind?,
                                                        new_app: options.new_app?,
                                                        force: options[:force], skip: options[:skip],
                                                        pretend: options[:pretend] }
        end

        setup_react_dependencies
        ensure_jsx_in_js_compatibility

        # Invoke standalone Pro/RSC generators when flags are used
        # Pass invoked_by_install: true so they skip message printing (we handle it)
        if use_pro?
          invoke "react_on_rails:pro", [], { invoked_by_install: true,
                                             force: options[:force], skip: options[:skip],
                                             pretend: options[:pretend] }
        end
        return unless use_rsc?

        invoke "react_on_rails:rsc", [], { typescript: options.typescript?, invoked_by_install: true,
                                           new_app: options.new_app?, redux: options.redux?,
                                           tailwind: use_tailwind?,
                                           force: options[:force], skip: options[:skip],
                                           pretend: options[:pretend] }
      end

      def setup_react_dependencies
        if options[:pretend]
          say_status :pretend, "Skipping React dependency setup in --pretend mode", :yellow
          return
        end

        setup_js_dependencies
      end

      def add_ci_workflow
        return if options[:pretend]

        ci_path = ".github/workflows/ci.yml"
        # Generators may run non-interactively (CI, scripts), so we never want Thor's
        # `template` to prompt on conflict. Treat any existing workflow as "skip" by
        # default; users who want to overwrite must pass --force explicitly. --skip
        # falls into the same path because the desired outcome is identical.
        if File.exist?(File.join(destination_root, ci_path)) && !options[:force]
          say_status :skip, "#{ci_path} already exists (pass --force to overwrite)", :yellow
          return
        end

        package_json = GeneratorMessages.read_package_json(destination_root)
        package_manager = GeneratorMessages.detect_package_manager(
          app_root: destination_root,
          package_json:
        )
        # Scope the lockfile check to the detected manager: a generic "any lockfile exists" check
        # would emit `cache: "pnpm"` in CI when only `yarn.lock` is on disk, breaking setup-node.
        has_lockfile = GeneratorMessages.lockfile_for_manager?(package_manager, app_root: destination_root)
        # `pnpm/action-setup@v4` requires an explicit `version:` unless package.json declares
        # `packageManager: pnpm@...`. Only ask the question for pnpm projects — other managers
        # never read this flag — and require a pnpm-specific declaration so an env-override to
        # pnpm while package.json declares a different manager still gets the version pin.
        pnpm_version_declared = package_manager == "pnpm" &&
                                GeneratorMessages.package_manager_declared?(
                                  app_root: destination_root,
                                  manager: "pnpm",
                                  package_json:
                                )
        has_active_record = File.exist?(File.join(destination_root, "config/database.yml"))
        has_rspec = File.exist?(File.join(destination_root, "spec/rails_helper.rb")) ||
                    File.exist?(File.join(destination_root, "spec/spec_helper.rb"))
        template("templates/base/base/.github/workflows/ci.yml.tt", ci_path,
                 { package_manager:, has_lockfile:,
                   pnpm_version_declared:,
                   pnpm_fallback_version: CI_PNPM_FALLBACK_VERSION,
                   has_active_record:, has_rspec:,
                   precompile_hook_command: shakapacker_precompile_hook_command(environment: "test") })
        @ci_workflow_generated = true
      end

      # RAILS_ENV=production runs the hook with production Rails config, while
      # NODE_ENV=production makes Shakapacker emit a minified production bundle.
      def default_package_json_scripts
        {
          "build" => shakapacker_build_command(env: "RAILS_ENV=production NODE_ENV=production"),
          "build:test" => shakapacker_build_command(env: "RAILS_ENV=test NODE_ENV=test", environment: "test")
        }
      end

      def add_package_json_scripts
        return if options[:pretend]

        package_json_path = File.join(destination_root, "package.json")
        return unless File.exist?(package_json_path)

        original_text = File.read(package_json_path)
        existing_scripts = JSON.parse(original_text)["scripts"] || {}
        scripts_to_add = default_package_json_scripts.reject { |key, _| existing_scripts.key?(key) }

        if scripts_to_add.empty?
          say_status :skip, "build scripts already present in package.json", :yellow
          return
        end

        updated_text = inject_scripts_into_package_json(original_text, scripts_to_add, existing_scripts)
        File.write(package_json_path, updated_text)
        say_status :append, "📝 Added build scripts (#{scripts_to_add.keys.join(', ')}) to package.json", :yellow
      rescue JSON::ParserError => e
        GeneratorMessages.add_warning("⚠️  Could not parse package.json to add scripts: #{e.message}")
      rescue Errno::EACCES, Errno::ENOENT => e
        GeneratorMessages.add_warning("⚠️  Failed to add build scripts to package.json: #{e.message}")
      end

      # Inserts new entries into the existing "scripts" object without rewriting the rest of
      # package.json, so Prettier-formatted files only see the added lines in the diff.
      # Falls back to a structured rewrite when the "scripts" key is absent or when the
      # scripts object can't be located unambiguously (e.g. malformed JSON).
      #
      # Relies on the JSON invariant that `"scripts": {` cannot appear unescaped inside a
      # preceding string value — in valid JSON the `"` characters are escaped as `\"`, so
      # the regex can never falsely match a substring nested in a string literal.
      def inject_scripts_into_package_json(original_text, scripts_to_add, existing_scripts)
        opener = original_text.match(/"scripts"\s*:\s*\{/m)
        return rewrite_package_json_with_scripts(original_text, scripts_to_add, existing_scripts) unless opener

        inner_start = opener.end(0)
        inner_end = find_matching_brace(original_text, inner_start)
        return rewrite_package_json_with_scripts(original_text, scripts_to_add, existing_scripts) unless inner_end

        inner = original_text[inner_start...inner_end]
        # Detect the indent of the "scripts" key wherever it appears (any object position),
        # not only when it's the first key. Defaults to two spaces so the closing `}` of the
        # rebuilt scripts block lines up under "scripts" instead of being emitted at column 0.
        object_indent = original_text[/\n([ \t]*)"scripts"/, 1] || "  "
        entry_indent = inner[/\n([ \t]+)"/, 1] || "#{object_indent}  "
        new_entries = scripts_to_add.map { |key, value| %(#{entry_indent}#{key.to_json}: #{value.to_json}) }

        rebuilt_inner =
          if existing_scripts.any?
            trimmed = inner.sub(/\s*\z/, "")
            separator = trimmed.end_with?(",") ? "" : ","
            "#{trimmed}#{separator}\n#{new_entries.join(",\n")}\n#{object_indent}"
          else
            "\n#{new_entries.join(",\n")}\n#{object_indent}"
          end

        "#{original_text[0...opener.begin(0)]}\"scripts\": {#{rebuilt_inner}}#{original_text[(inner_end + 1)..]}"
      end

      # Returns the index of the `}` that closes the `{` whose body starts at `start`,
      # or nil if the object is unterminated. Tracks brace depth while stepping through
      # JSON string literals so `}` characters inside script values (e.g.
      # "lint": "eslint '{src,test}/**/*.js'") do not match a non-matching brace.
      def find_matching_brace(text, start)
        depth = 1
        i = start
        while i < text.length
          case text[i]
          when '"'
            i = skip_json_string(text, i)
            return nil unless i
          when "{"
            depth += 1
            i += 1
          when "}"
            depth -= 1
            return i if depth.zero?

            i += 1
          else
            i += 1
          end
        end
        nil
      end

      # Given an index pointing at the opening `"` of a JSON string, returns the index
      # just past the closing `"`. Honours `\"` and `\\` escapes. Returns nil if the
      # string is unterminated.
      def skip_json_string(text, start)
        i = start + 1
        while i < text.length
          case text[i]
          when "\\"
            i += 2
          when '"'
            return i + 1
          else
            i += 1
          end
        end
        nil
      end

      # Used only when the "scripts" key is missing entirely or the regex can't locate it.
      # This path does reformat the whole file, but it's rare — a Rails package.json with
      # no scripts key at all is unusual.
      def rewrite_package_json_with_scripts(original_text, scripts_to_add, existing_scripts)
        content = JSON.parse(original_text)
        content["scripts"] = existing_scripts.merge(scripts_to_add)
        indent = original_text[/\A\{\n(\s+)/, 1] || "  "
        "#{JSON.pretty_generate(content, indent:)}\n"
      end

      def ensure_jsx_in_js_compatibility
        return if options[:pretend]
        return unless using_swc?
        return unless jsx_in_js_files_present?

        say "⚙️  Detected JSX in .js files; switching shakapacker javascript_transpiler to babel for compatibility",
            :yellow
        set_javascript_transpiler_to_babel
        babel_loader_added = add_packages(["babel-loader"], dev: true)
        babel_preset_added = add_babel_react_dependencies
        return if babel_loader_added && babel_preset_added

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Babel compatibility dependencies may be incomplete after switching from SWC.
          Please verify `babel-loader` and `@babel/preset-react` are installed.
        MSG
      end

      # NOTE: other requirements for existing files such as .gitignore or application.
      # js(.coffee) are not checked by this method, but instead produce warning messages
      # and allow the build to continue
      def installation_prerequisites_met?
        warn_if_unsupported_env_package_manager

        # Non-blocking: warn about dirty worktree but don't prevent installation.
        # A clean tree makes the generator diff easier to review, but blocking would
        # be too strict for a generator that creates many new files.
        has_worktree_issues = ReactOnRails::GitUtils.warn_if_uncommitted_changes(
          GeneratorMessages, git_installed: cli_exists?("git")
        )

        # missing_pro_gem? may auto-install the gem (mutating Gemfile), so only run
        # it on a clean worktree. On a dirty tree, use the read-only pro_gem_installed?
        # check to catch a missing gem without triggering auto-install.
        if has_worktree_issues && use_pro? && !pro_gem_installed?
          required_flag = pro_requirement_flag
          GeneratorMessages.add_error(<<~MSG.strip)
            🚫 react_on_rails_pro gem is required for #{required_flag} but is not installed.
            Auto-install was skipped because the worktree has uncommitted changes.
            Please add it manually:
              gem 'react_on_rails_pro', '#{pro_gem_version_requirement}'
            Then run: bundle install
          MSG
          return false
        end

        !(missing_node? || missing_package_manager? || unsupported_tailwind_shakapacker? ||
          (!has_worktree_issues && missing_pro_gem?))
      end

      def warn_if_unsupported_env_package_manager
        env_value = ENV.fetch("REACT_ON_RAILS_PACKAGE_MANAGER", nil)&.strip
        return if env_value.nil? || env_value.empty?
        return if GeneratorMessages.supported_package_manager?(env_value.downcase)

        supported = GeneratorMessages::SUPPORTED_PACKAGE_MANAGERS.join(", ")
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  REACT_ON_RAILS_PACKAGE_MANAGER='#{env_value}' is not a supported package manager.
          Supported values: #{supported}.
          Falling through to package.json / lockfile / npm-default detection.
        MSG
      end

      def missing_node?
        unless ReactOnRails::Utils.command_available?("node")
          error = <<~MSG.strip
            🚫 Node.js is required but not found on your system.

            Please install Node.js before continuing:
            • Download from: https://nodejs.org/en/
            • Recommended: Use a version manager like nvm, fnm, or volta
            • Minimum required version: Node.js 18+

            After installation, restart your terminal and try again.
          MSG
          GeneratorMessages.add_error(error)
          return true
        end

        # Check Node.js version if available
        check_node_version
        false
      end

      def unsupported_tailwind_shakapacker?
        return false unless use_tailwind?
        return false if ReactOnRails::PackerUtils.shakapacker_version_requirement_met?(
          MINIMUM_SHAKAPACKER_VERSION_FOR_TAILWIND_LAYOUT
        )

        GeneratorMessages.add_error(<<~MSG.strip)
          🚫 Tailwind layout wiring requires Shakapacker >= #{MINIMUM_SHAKAPACKER_VERSION_FOR_TAILWIND_LAYOUT}.

          Installed version: #{ReactOnRails::PackerUtils.shakapacker_version}
          Upgrade shakapacker or omit --tailwind.
        MSG
        true
      end

      def check_node_version
        node_version = `node --version 2>/dev/null`.strip
        return if node_version.blank?

        # Extract major version number (e.g., "v18.17.0" -> 18)
        major_version = node_version[/v(\d+)/, 1]&.to_i
        return unless major_version

        return unless major_version < 18

        warning = <<~MSG.strip
          ⚠️  Node.js version #{node_version} detected.

          React on Rails recommends Node.js 18+ for best compatibility.
          You may experience issues with older versions.

          Consider upgrading: https://nodejs.org/en/
        MSG
        GeneratorMessages.add_warning(warning)
      end

      def shakapacker_just_installed?
        !!(options.shakapacker_just_installed? || @shakapacker_just_installed)
      end

      def ensure_shakapacker_installed
        @shakapacker_setup_incomplete = false
        return if shakapacker_configured?

        if options[:pretend]
          say_status :pretend, "Skipping automatic Shakapacker installation in --pretend mode", :yellow
          return
        end

        print_shakapacker_setup_banner
        gemfile_ok = ensure_shakapacker_in_gemfile
        @shakapacker_setup_incomplete = true unless gemfile_ok

        # NOTE: File.exist?/File.read use Dir.pwd (not destination_root) because
        # Rails generators always run from the destination root. This is consistent
        # with other relative-path file checks in this generator (e.g. shakapacker_configured?).
        yml_content_before = File.exist?(SHAKAPACKER_YML_PATH) ? File.read(SHAKAPACKER_YML_PATH) : nil

        if install_shakapacker
          finalize_shakapacker_setup(yml_content_before)
        else
          @shakapacker_setup_incomplete = true
        end
      end

      # Checks whether "shakapacker" is explicitly declared in this project's Gemfile.
      # We only check the Gemfile text, not lockfile or dependencies, because
      # shakapacker might be present as a dependency of react_on_rails but not
      # properly configured for this specific Rails application.
      def shakapacker_in_gemfile?
        gem_name = "shakapacker"
        shakapacker_in_gemfile_text?(gem_name)
      end

      def add_bin_scripts
        replace_stock_rails_bin_dev!

        # Copy bin scripts from templates
        template_bin_path = "#{__dir__}/templates/base/base/bin"
        # Always exclude `dev` from the bulk copy; it is handled explicitly below
        # so we can patch DEFAULT_ROUTE and AUTO_OPEN_BROWSER_ONCE after copying.
        directory_options = { exclude_pattern: %r{/dev(?:\.tt)?\z} }
        directory template_bin_path, "bin", directory_options

        if preserve_existing_bin_dev?
          if use_rsc? && !options.redux? && !options.new_app?
            say_status :warn,
                       "Custom bin/dev detected: update DEFAULT_ROUTE to \"#{HELLO_SERVER_ROUTE}\" manually for --rsc",
                       :yellow
          end
        else
          copy_file("#{template_bin_path}/dev", "bin/dev")
          gsub_file "bin/dev", /^DEFAULT_ROUTE = .*$/, "DEFAULT_ROUTE = #{default_bin_dev_route.inspect}"
          gsub_file "bin/dev", /^AUTO_OPEN_BROWSER_ONCE = .*$/, "AUTO_OPEN_BROWSER_ONCE = #{options.new_app?}"
        end

        # `directory` and `gsub_file` above are Thor actions that already honor
        # --pretend. Only the raw Ruby filesystem calls below need an explicit guard.
        if options[:pretend]
          say_status :pretend, "Skipping chmod on bin scripts in --pretend mode", :yellow
          return
        end

        # Make these and only these files executable. Use destination_root so
        # chmod remains correct even if an earlier generator step changed Dir.pwd.
        files_to_become_executable = bin_scripts_to_chmod(template_bin_path)
        File.chmod(0o755, *files_to_become_executable)
      end

      # Consumer-scoped AI-agent guidance written into the generated app. The canonical
      # AGENTS.md content lives in templates/agent_files/ and is the single source of truth;
      # create-react-on-rails-app gets it for free because it delegates to this generator.
      # Each file is copied only when absent so we never clobber an app's existing agent files.
      AGENT_FILES = %w[
        AGENTS.md
        CLAUDE.md
        .cursor/rules/react-on-rails.mdc
        .github/copilot-instructions.md
      ].freeze
      private_constant :AGENT_FILES

      def add_agent_files
        return unless options.agent_files?

        # AGENTS.md is the canonical file the editor pointers (CLAUDE.md, Cursor, Copilot) all
        # reference. If the app already has its own AGENTS.md, it may document unrelated
        # conventions, so leave it untouched AND skip the pointer files rather than emit editor
        # guidance pointing at an AGENTS.md we did not write.
        if File.exist?(File.join(destination_root, "AGENTS.md"))
          say_status :skip, "AGENTS.md already exists; leaving it and the editor pointer files untouched", :yellow
          return
        end

        AGENT_FILES.each do |relative_path|
          if File.exist?(File.join(destination_root, relative_path))
            say_status :skip, "#{relative_path} already exists; leaving it untouched", :yellow
            next
          end

          copy_file("templates/agent_files/#{relative_path}", relative_path)
        end
      end

      def replace_stock_rails_bin_dev!
        @preserve_existing_bin_dev = false

        unless stock_rails_bin_dev?
          if File.exist?("bin/dev")
            say_status :skip, "bin/dev exists but does not match a stock Rails template; keeping existing file", :yellow
            @preserve_existing_bin_dev = true
          end
          return
        end

        if options[:pretend] || options[:skip]
          say_status :skip, "Detected stock Rails bin/dev; leaving existing file in place for --pretend/--skip", :yellow
          @preserve_existing_bin_dev = true
          return
        end

        say_status :replace, "Detected stock Rails bin/dev; installing React on Rails bin/dev", :yellow
        remove_file "bin/dev", verbose: false
      end

      def preserve_existing_bin_dev?
        # Set by replace_stock_rails_bin_dev! which always runs first via add_bin_scripts.
        # Explicitly coerce to boolean so nil (before initialization) is treated as false.
        !!@preserve_existing_bin_dev
      end

      def bin_scripts_to_chmod(template_bin_path)
        files = Dir.children(template_bin_path).reject { |filename| filename == "dev" }
        files << "dev" unless preserve_existing_bin_dev?
        files.map { |filename| File.join(destination_root, "bin/#{filename}") }
      end

      def default_bin_dev_route
        return "/" if options.new_app? && new_app_root_route_available?
        return "hello_server" if use_rsc? && !options.redux?

        "hello_world"
      end

      def new_app_root_route_available?
        root_route_present?
      end

      def stock_rails_bin_dev?
        return false unless File.exist?("bin/dev")

        content = normalize_bin_dev_content(File.read("bin/dev"))
        content == normalize_bin_dev_content(STOCK_RAILS_BIN_DEV) || legacy_foreman_bin_dev?(content)
      end

      def add_post_install_message
        if shakapacker_setup_incomplete?
          GeneratorMessages.add_warning(incomplete_installation_message)
          return
        end

        # Determine what route and component will be created by the generator
        if use_rsc? && !options.redux?
          # RSC without Redux: HelloServer replaces HelloWorld
          route = HELLO_SERVER_ROUTE
          component_name = "HelloServer"
        else
          route = HELLO_WORLD_ROUTE
          component_name = options.redux? ? "HelloWorldApp" : "HelloWorld"
        end

        GeneratorMessages.add_info(GeneratorMessages.helpful_message_after_installation(
                                     component_name:,
                                     route:,
                                     pro: use_pro?,
                                     rsc: use_rsc?,
                                     shakapacker_just_installed: shakapacker_just_installed?,
                                     landing_page: options.new_app? && new_app_root_route_available?,
                                     ci_workflow_generated: @ci_workflow_generated == true,
                                     tailwind: use_tailwind?,
                                     app_root: destination_root
                                   ))
        GeneratorMessages.add_info(rsc_verification_message) if use_rsc?
      end

      def shakapacker_setup_incomplete?
        # Strict comparison keeps nil (unset) distinct from true.
        @shakapacker_setup_incomplete == true
      end

      def add_legacy_redux_install_warning
        return unless options.redux?

        legacy_docs_url = "https://reactonrails.com/docs/api-reference/generator-details/"
        legacy_guidance, legacy_command =
          if use_tailwind?
            [
              "Existing apps that need Redux with Tailwind should keep using the hidden install path:",
              "rails generate react_on_rails:install --redux --tailwind"
            ]
          else
            [
              "Existing apps that need the legacy Redux scaffold can use the hidden react_with_redux generator. " \
              "That generator is also legacy and emits its own warning:",
              "rails generate react_on_rails:react_with_redux"
            ]
          end

        GeneratorMessages.add_warning(<<~MSG.strip)
          The install --redux option is a hidden legacy Redux generator path and is not recommended
          for new React on Rails apps.
          Use the default install generator for new apps. #{legacy_guidance}

              #{legacy_command}

          For legacy Redux recovery details, see #{legacy_docs_url}.
          Runtime Redux APIs such as redux_store remain supported.
        MSG
      end

      def add_legacy_redux_install_warning_once
        return if @legacy_redux_install_warning_added

        # Set the flag after enqueueing so a failed warning add can be retried.
        add_legacy_redux_install_warning
        @legacy_redux_install_warning_added = true
      end

      def recovery_install_command
        flags = []
        flags << "--redux" if options.redux?
        flags << "--typescript" if options.typescript?
        # Echo the resolved bundler choice (normalized to --rspack/--no-rspack, so a --webpack
        # alias re-runs as --no-rspack) only when the user passed one explicitly. An unset choice
        # re-resolves to the fresh-install default on re-run, so we don't pin it here.
        flags << (using_rspack? ? "--rspack" : "--no-rspack") if bundler_flag_given?

        if options.rsc?
          flags << "--rsc"
        elsif options.pro?
          flags << "--pro"
        end

        # Preserve an explicit agent-files opt-out so the suggested re-run doesn't emit
        # AGENTS.md/editor files a user deliberately skipped (--agent-files defaults to on).
        flags << "--no-agent-files" unless options.agent_files?

        ["rails generate react_on_rails:install", *flags].join(" ")
      end

      def rsc_verification_message
        <<~MSG

          🔎 RSC Pro Verification:
          ─────────────────────────────────────────────────────────────────────────
          1. Start all processes: #{Rainbow('bin/dev').cyan}
          2. Visit: #{Rainbow("http://localhost:<port>/#{HELLO_SERVER_ROUTE}").cyan.underline}
          3. Confirm the page streams and the Like button hydrates on click.
        MSG
      end

      def recovery_working_tree_lines
        [
          "If this run created or changed files, clean up your working tree before rerunning",
          "(commit, stash, or discard the partial changes), or re-run with --ignore-warnings",
          "if you intentionally want to continue on a dirty tree."
        ]
      end

      def recovery_working_tree_note
        "#{recovery_working_tree_lines.join("\n")}\n"
      end

      def recovery_working_tree_step(step_number)
        first_line, *remaining_lines = recovery_working_tree_lines
        (["#{step_number}. #{first_line}"] + remaining_lines.map { |line| "   #{line}" }).join("\n")
      end

      def incomplete_installation_message
        package_install_step = "#{GeneratorMessages.detect_package_manager(app_root: destination_root)} install"

        <<~MSG

          ⚠️  React on Rails installation is incomplete.
          ─────────────────────────────────────────────────────────────────────────
          Shakapacker setup failed, so this app is not ready to run yet.
          Avoid running ./bin/dev until Shakapacker is installed successfully.
          Note: Some generator files may have been partially created during this run.

          Next steps:
          1. #{Rainbow('bundle install').cyan}
          2. #{Rainbow('bundle exec rails shakapacker:install').cyan}
          3. #{Rainbow(package_install_step).cyan}
          #{recovery_working_tree_step(4)}
          5. Re-run #{Rainbow(recovery_install_command).cyan}
             (add #{Rainbow('--force').cyan} to overwrite files if needed)

          Troubleshooting:
          • https://github.com/shakacode/shakapacker/blob/main/docs/installation.md
        MSG
      end

      def shakapacker_loaded_in_process?(gem_name)
        Gem.loaded_specs.key?(gem_name)
      end

      def shakapacker_in_lockfile?(gem_name)
        gem_in_lockfile?(gem_name)
      end

      def shakapacker_in_bundler_specs?(gem_name)
        require "bundler"
        Bundler.load.specs.any? { |s| s.name == gem_name }
      rescue StandardError
        false
      end

      def shakapacker_in_gemfile_text?(gem_name)
        # Always check the target app's Gemfile, not inherited BUNDLE_GEMFILE
        # See: https://github.com/shakacode/react_on_rails/issues/2287
        File.file?("Gemfile") &&
          File.foreach("Gemfile").any? { |l| l.match?(/^\s*gem\s+['"]#{Regexp.escape(gem_name)}['"]/) }
      end

      def cli_exists?(command)
        ReactOnRails::Utils.command_available?(command)
      end

      def normalize_bin_dev_content(content)
        content.gsub("\r\n", "\n").strip
      end

      def legacy_foreman_bin_dev?(content)
        LEGACY_FOREMAN_BIN_DEV_TEMPLATES.include?(content)
      end

      def shakapacker_binaries_exist?
        File.exist?("bin/shakapacker") && File.exist?("bin/shakapacker-dev-server")
      end

      def shakapacker_configured?
        # Check for essential shakapacker configuration files and binaries
        shakapacker_binaries_exist? &&
          File.exist?("config/shakapacker.yml") &&
          shakapacker_config_file_exists?
      end

      def shakapacker_config_file_exists?
        File.exist?("config/webpack/webpack.config.js") ||
          File.exist?("config/webpack/webpack.config.ts") ||
          File.exist?("config/rspack/rspack.config.js") ||
          File.exist?("config/rspack/rspack.config.ts")
      end

      def print_shakapacker_setup_banner
        say "\n#{set_color('=' * 80, :cyan)}"
        say set_color("🔧 SHAKAPACKER SETUP", :cyan, :bold)
        say set_color("=" * 80, :cyan)
      end

      def ensure_shakapacker_in_gemfile
        return true if shakapacker_in_gemfile?

        say "📝 Adding Shakapacker to Gemfile...", :yellow
        # Use with_unbundled_env to prevent inheriting BUNDLE_GEMFILE from parent process
        # See: https://github.com/shakacode/react_on_rails/issues/2287
        success = Bundler.with_unbundled_env { system("bundle add shakapacker --strict") }
        return true if success

        handle_shakapacker_gemfile_error
        false
      end

      def install_shakapacker
        say "⚙️  Installing Shakapacker (required for webpack integration)...", :yellow

        # First run bundle install to make shakapacker available
        # Use with_unbundled_env to prevent inheriting BUNDLE_GEMFILE from parent process
        say "📦 Running bundle install...", :yellow
        bundle_success = Bundler.with_unbundled_env { system("bundle install") }
        unless bundle_success
          handle_shakapacker_install_error
          return false
        end

        seed_package_manager_in_package_json_from_lockfile!

        # Then run the shakapacker installer.
        # Resolve the bundler via using_rspack?. shakapacker.yml doesn't exist yet at this point,
        # so the fresh-install default applies: an unset --rspack flag resolves to Rspack when
        # Shakapacker supports it (shakapacker_version_9_or_higher? is optimistically true on a
        # brand-new install where Shakapacker isn't loaded yet). Pass the resolved choice explicitly
        # so Shakapacker installs dependencies for the same bundler that React on Rails configures.
        assets_bundler = using_rspack? ? "rspack" : "webpack"
        shakapacker_install_env = { "SHAKAPACKER_ASSETS_BUNDLER" => assets_bundler }
        success = Bundler.with_unbundled_env do
          system(shakapacker_install_env, "bundle exec rails shakapacker:install")
        end
        if success
          resolve_browserslist_conflict_after_shakapacker_install
          true
        else
          handle_shakapacker_install_error
          false
        end
      end

      def seed_package_manager_in_package_json_from_lockfile!
        return unless File.exist?("package.json")

        package_json_content = JSON.parse(File.read("package.json"))
        return if package_json_content["packageManager"]

        manager = detect_package_manager_from_lockfiles
        return unless manager

        version = detect_package_manager_version(manager)
        return unless version

        package_json_content["packageManager"] = "#{manager}@#{version}"
        File.write("package.json", "#{JSON.pretty_generate(package_json_content)}\n")
        say "🔧 Added packageManager=#{manager}@#{version} to package.json before shakapacker:install", :yellow
      rescue JSON::ParserError => e
        GeneratorMessages.add_warning("⚠️  Could not parse package.json to set packageManager: #{e.message}")
      rescue StandardError => e
        GeneratorMessages.add_warning("⚠️  Failed to seed packageManager in package.json: #{e.message}")
      end

      def resolve_browserslist_conflict_after_shakapacker_install
        return unless File.exist?(".browserslistrc") && File.exist?("package.json")

        package_json_content = JSON.parse(File.read("package.json"))
        return unless package_json_content.key?("browserslist")

        package_json_content.delete("browserslist")
        File.write("package.json", "#{JSON.pretty_generate(package_json_content)}\n")
        say "🔧 Removed package.json browserslist because .browserslistrc is present", :yellow
      rescue JSON::ParserError => e
        GeneratorMessages.add_warning("⚠️  Could not parse package.json for browserslist cleanup: #{e.message}")
      rescue StandardError => e
        GeneratorMessages.add_warning("⚠️  Failed to clean browserslist conflict: #{e.message}")
      end

      def detect_package_manager_from_lockfiles
        GeneratorMessages.detect_package_manager_from_lockfiles
      end

      def detect_package_manager_version(package_manager)
        unless cli_exists?(package_manager)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  #{package_manager} lockfile found but `#{package_manager}` command is not available on PATH.
            Install #{package_manager} and re-run the generator.
          MSG
          return nil
        end

        stdout, stderr, status = Open3.capture3(package_manager, "--version")
        return stdout.strip if status.success?

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Failed to determine #{package_manager} version (#{stderr.strip}).
          Install #{package_manager} and re-run the generator.
        MSG
        nil
      rescue StandardError => e
        GeneratorMessages.add_warning("⚠️  Failed to detect #{package_manager} version: #{e.message}")
        nil
      end

      def finalize_shakapacker_setup(yml_content_before)
        say "✅ Shakapacker installed successfully!", :green
        say "=" * 80, :cyan
        say set_color("🚀 CONTINUING WITH REACT ON RAILS SETUP", :cyan, :bold)
        say "#{'=' * 80}\n", :cyan

        yml_content_after = File.exist?(SHAKAPACKER_YML_PATH) ? File.read(SHAKAPACKER_YML_PATH) : nil

        # Force-apply the RoR template only when shakapacker wrote a fresh config:
        #   nil  → new content  (fresh install: file didn't exist before)       → true
        #   old  → new content  (user said "y" to conflict prompt)              → true
        #   old  → same content (user said "n", kept their custom config)       → false
        #   old  → same content (user said "y" but file was already identical   → false
        #                        to Shakapacker's default; negligible in practice)
        #   nil  → nil          (installer succeeded but wrote nothing)         → false
        #
        # The nil→nil case is treated as "no change needed": if the installer
        # returned true but did not write the yml, we assume the file was already
        # correct and skip the force-overwrite. This is theoretically possible but
        # extremely unlikely given how Shakapacker's installer works.
        #
        # Note: if the user said "y" and shakapacker overwrote their yml, this
        # correctly re-applies the RoR template on top of shakapacker's fresh defaults.
        @shakapacker_just_installed = yml_content_before != yml_content_after
      end

      def handle_shakapacker_gemfile_error
        error = <<~MSG.strip
          🚫 Failed to add Shakapacker to your Gemfile.

          This could be due to:
          • Bundle installation issues
          • Network connectivity problems
          • Gemfile permissions

          Please try manually:
              bundle add shakapacker --strict

          #{recovery_working_tree_note}
          Then re-run: #{recovery_install_command}
        MSG
        GeneratorMessages.add_error(error)
        add_legacy_redux_install_warning_once
        raise Thor::Error, error unless options.ignore_warnings?
      end

      def handle_shakapacker_install_error
        error = <<~MSG.strip
          🚫 Failed to install Shakapacker automatically.

          This could be due to:
          • Missing Node.js or npm/yarn
          • Network connectivity issues
          • Incomplete bundle installation
          • Missing write permissions

          Troubleshooting steps:
          1. Ensure Node.js is installed: node --version
          2. Run: bundle install
          3. Try manually: bundle exec rails shakapacker:install
          4. Check for error output above
          #{recovery_working_tree_step(5)}
          6. Re-run: #{recovery_install_command}

          Need help? Visit: https://github.com/shakacode/shakapacker/blob/main/docs/installation.md
        MSG
        GeneratorMessages.add_error(error)
        add_legacy_redux_install_warning_once
        raise Thor::Error, error unless options.ignore_warnings?
      end

      def missing_package_manager?
        selected, source = GeneratorMessages.detect_package_manager_with_source(app_root: destination_root)
        return false if GeneratorMessages.package_manager_executable_available?(selected)

        available_package_managers = GeneratorMessages::SUPPORTED_PACKAGE_MANAGERS.select do |pm|
          pm != selected && GeneratorMessages.package_manager_executable_available?(pm)
        end

        if available_package_managers.empty?
          error = <<~MSG.strip
            🚫 No JavaScript package manager found on your system.

            #{package_manager_source_description(selected, source)}

            React on Rails requires a JavaScript package manager to install dependencies.
            Please install one of the following:

            • npm: Usually comes with Node.js (https://nodejs.org/en/)
            • yarn: npm install -g yarn (https://yarnpkg.com/)
            • pnpm: npm install -g pnpm (https://pnpm.io/)
            • bun: Install from https://bun.sh/

            After installation, restart your terminal and try again.
          MSG
          GeneratorMessages.add_error(error)
          return true
        end

        action_separator = %i[default env].include?(source) ? " or " : ", update the source above, or "
        error = <<~MSG.strip
          🚫 JavaScript package manager '#{selected}' was selected, but the command was not found.

          #{package_manager_source_description(selected, source)}
          Install '#{selected}'#{action_separator}set REACT_ON_RAILS_PACKAGE_MANAGER
          to one of the available package managers: #{available_package_managers.join(', ')}.
        MSG
        GeneratorMessages.add_error(error)
        true
      end

      def package_manager_source_description(selected, source)
        case source
        when :env
          "Selected via the REACT_ON_RAILS_PACKAGE_MANAGER environment variable."
        when :package_json
          "Selected via the `packageManager` field in package.json."
        when :lockfile
          lockfile = GeneratorMessages.lockfile_filename_for(selected, app_root: destination_root)
          lockfile ? "Selected via the #{lockfile} lockfile on disk." : "Selected via a lockfile on disk."
        when :default
          "Selected via the npm default fallback (no env var, packageManager field, or lockfile detected)."
        else
          raise ArgumentError, "Unknown package manager source: #{source.inspect}"
        end
      end

      def jsx_in_js_files_present?
        Dir.glob("app/javascript/**/*.js").any? do |path|
          content = File.read(path)
          content.match?(%r{<\s*[A-Za-z][\w:-]*(\s|>|/)}) || content.match?(/<\s*>/)
        rescue StandardError
          false
        end
      end

      def set_javascript_transpiler_to_babel
        shakapacker_config_path = "config/shakapacker.yml"
        return unless File.exist?(shakapacker_config_path)

        swc_transpiler_pattern = /^(\s*javascript_transpiler:\s*)["']?swc["']?(\s*(?:#.*)?)$/
        return unless File.read(shakapacker_config_path).match?(swc_transpiler_pattern)

        gsub_file(
          shakapacker_config_path,
          swc_transpiler_pattern,
          '\1"babel"\2'
        )
        @using_swc = false
      end

      def install_typescript_dependencies
        if options[:pretend]
          say_status :pretend, "Skipping TypeScript dependency installation in --pretend mode", :yellow
          return
        end

        say "📝 Installing TypeScript dependencies...", :yellow
        # Delegate to shared module for consistent dependency management
        add_typescript_dependencies
      end

      def create_css_module_types
        if options[:pretend]
          say_status :pretend, "Skipping CSS module type definitions in --pretend mode", :yellow
          return
        end

        say "📝 Creating CSS module type definitions...", :yellow

        css_module_types_path = File.join(shakapacker_source_path, "types", "css-modules.d.ts")
        css_module_types_content = <<~TS.strip
          // TypeScript definitions for CSS modules
          declare module "*.module.css" {
            const classes: { [key: string]: string };
            export default classes;
          }

          declare module "*.module.scss" {
            const classes: { [key: string]: string };
            export default classes;
          }

          declare module "*.module.sass" {
            const classes: { [key: string]: string };
            export default classes;
          }
        TS

        create_file(css_module_types_path, css_module_types_content)
        say "✅ Created CSS module type definitions", :green
      end

      def create_typescript_config
        if options[:pretend]
          say_status :pretend, "Skipping tsconfig.json creation in --pretend mode", :yellow
          return
        end

        if File.exist?("tsconfig.json")
          say "⚠️  tsconfig.json already exists, skipping creation", :yellow
          return
        end

        tsconfig_content = {
          "compilerOptions" => {
            "target" => "es2018",
            "allowJs" => true,
            "skipLibCheck" => true,
            "strict" => true,
            "noUncheckedIndexedAccess" => true,
            "forceConsistentCasingInFileNames" => true,
            "noFallthroughCasesInSwitch" => true,
            "module" => "esnext",
            "moduleResolution" => "bundler",
            "resolveJsonModule" => true,
            "isolatedModules" => true,
            "noEmit" => true,
            "jsx" => "react-jsx"
          },
          "include" => [
            File.join(shakapacker_source_path, "**/*")
          ]
        }

        File.write("tsconfig.json", JSON.pretty_generate(tsconfig_content))
        say "✅ Created tsconfig.json", :green
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
