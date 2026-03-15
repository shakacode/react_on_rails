# frozen_string_literal: true

require "rails/generators"
require "json"
require "bundler"
require_relative "generator_helper"
require_relative "generator_messages"
require_relative "js_dependency_manager"
require_relative "pro_setup"
require_relative "rsc_setup"
# Load-path require: git_utils lives under react_on_rails/lib, not relative to this generator directory.
require "react_on_rails/git_utils"

module ReactOnRails
  module Generators
    # TODO: Extract more modules to reduce class length below 150 lines.
    #       Candidates: ShakapackerSetup (~100 lines), TypeScriptSetup (~60 lines),
    #       ValidationHelpers (~80 lines for Node/package manager checks).
    # rubocop:disable Metrics/ClassLength
    class InstallGenerator < Rails::Generators::Base
      include GeneratorHelper
      include JsDependencyManager
      include ProSetup
      include RscSetup

      # fetch USAGE file for details generator description
      source_root(File.expand_path(__dir__))

      # --redux
      class_option :redux,
                   type: :boolean,
                   default: false,
                   desc: "Install Redux package and Redux version of Hello World Example. Default: false",
                   aliases: "-R"

      # --typescript
      class_option :typescript,
                   type: :boolean,
                   default: false,
                   desc: "Generate TypeScript files and install TypeScript dependencies. Default: false",
                   aliases: "-T"

      # --rspack
      class_option :rspack,
                   type: :boolean,
                   default: false,
                   desc: "Use Rspack instead of Webpack as the bundler. Default: false"

      # --ignore-warnings
      class_option :ignore_warnings,
                   type: :boolean,
                   default: false,
                   desc: "Skip warnings. Default: false"

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

      # Removed: --skip-shakapacker-install (Shakapacker is now a required dependency)

      SHAKAPACKER_YML_PATH = "config/shakapacker.yml"

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
          add_bin_scripts
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
        print_generator_messages
      end

      # Everything here is not run automatically b/c it's private

      private

      def invoke_generators
        ensure_shakapacker_installed
        if options.typescript?
          install_typescript_dependencies
          create_css_module_types
          create_typescript_config
        end
        # `invoke` instantiates child generators with a fresh options hash, so
        # --pretend/--force/--skip must be forwarded explicitly at each boundary.
        invoke "react_on_rails:base", [],
               { typescript: options.typescript?, redux: options.redux?, rspack: options.rspack?,
                 pro: options.pro?, rsc: options.rsc?,
                 shakapacker_just_installed: shakapacker_just_installed?,
                 force: options[:force], skip: options[:skip], pretend: options[:pretend] }

        # Component generator logic:
        # - --rsc without --redux: Skip HelloWorld, HelloServer will be generated in setup_rsc
        # - --rsc with --redux: Generate HelloWorldApp (user explicitly wants Redux) + HelloServer
        # - Without --rsc: Normal behavior (HelloWorld or HelloWorldApp based on --redux)
        if options.redux?
          invoke "react_on_rails:react_with_redux", [], { typescript: options.typescript?,
                                                          invoked_by_install: true,
                                                          force: options[:force], skip: options[:skip],
                                                          pretend: options[:pretend] }
        elsif !use_rsc?
          # Only generate HelloWorld if RSC is not enabled
          # For RSC, HelloServer replaces HelloWorld as the example component
          invoke "react_on_rails:react_no_redux", [], { typescript: options.typescript?,
                                                        force: options[:force], skip: options[:skip],
                                                        pretend: options[:pretend] }
        end

        setup_react_dependencies

        # Invoke standalone Pro/RSC generators when flags are used
        # Pass invoked_by_install: true so they skip message printing (we handle it)
        if use_pro?
          invoke "react_on_rails:pro", [], { invoked_by_install: true,
                                             force: options[:force], skip: options[:skip],
                                             pretend: options[:pretend] }
        end
        return unless use_rsc?

        invoke "react_on_rails:rsc", [], { typescript: options.typescript?, invoked_by_install: true,
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

      # NOTE: other requirements for existing files such as .gitignore or application.
      # js(.coffee) are not checked by this method, but instead produce warning messages
      # and allow the build to continue
      def installation_prerequisites_met?
        # Check uncommitted_changes? before missing_pro_gem? so that
        # auto-install does not mutate the Gemfile on a dirty working tree.
        !(missing_node? || missing_package_manager? ||
          ReactOnRails::GitUtils.uncommitted_changes?(GeneratorMessages) || missing_pro_gem?)
      end

      def missing_node?
        node_missing = ReactOnRails::Utils.running_on_windows? ? `where node`.blank? : `which node`.blank?

        if node_missing
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
        # Copy bin scripts from templates
        template_bin_path = "#{__dir__}/templates/base/base/bin"
        directory template_bin_path, "bin"

        # For --rsc without --redux, hello_world doesn't exist — update DEFAULT_ROUTE
        if use_rsc? && !options.redux?
          gsub_file "bin/dev", 'DEFAULT_ROUTE = "hello_world"', 'DEFAULT_ROUTE = "hello_server"'
        end

        # `directory` and `gsub_file` above are Thor actions that already honor
        # --pretend. Only the raw Ruby filesystem calls below need an explicit guard.
        if options[:pretend]
          say_status :pretend, "Skipping chmod on bin scripts in --pretend mode", :yellow
          return
        end

        # Make these and only these files executable
        files_to_copy = []
        Dir.chdir(template_bin_path) do
          files_to_copy.concat(Dir.glob("*"))
        end
        files_to_become_executable = files_to_copy.map { |filename| "bin/#{filename}" }

        File.chmod(0o755, *files_to_become_executable)
      end

      def add_post_install_message
        if shakapacker_setup_incomplete?
          GeneratorMessages.add_warning(incomplete_installation_message)
          return
        end

        # Determine what route and component will be created by the generator
        if use_rsc? && !options.redux?
          # RSC without Redux: HelloServer replaces HelloWorld
          route = "hello_server"
          component_name = "HelloServer"
        else
          route = "hello_world"
          component_name = options.redux? ? "HelloWorldApp" : "HelloWorld"
        end

        GeneratorMessages.add_info(GeneratorMessages.helpful_message_after_installation(
                                     component_name: component_name,
                                     route: route,
                                     rsc: use_rsc?,
                                     shakapacker_just_installed: shakapacker_just_installed?
                                   ))
      end

      def shakapacker_setup_incomplete?
        # Strict comparison keeps nil (unset) distinct from true.
        @shakapacker_setup_incomplete == true
      end

      def recovery_install_command
        flags = []
        flags << "--redux" if options.redux?
        flags << "--typescript" if options.typescript?
        flags << "--rspack" if options.rspack?

        if use_rsc?
          flags << "--rsc"
        elsif options.pro?
          flags << "--pro"
        end

        ["rails generate react_on_rails:install", *flags].join(" ")
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
        package_install_step = "#{GeneratorMessages.detect_package_manager} install"

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
        system("which #{command} > /dev/null 2>&1")
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

        # Then run the shakapacker installer
        # Use options.rspack? directly (not using_rspack?): shakapacker.yml doesn't exist yet at this
        # point, so using_rspack? would fall back to rspack_configured_in_project? which returns false,
        # causing Shakapacker to install webpack configs into config/webpack/ instead of rspack.
        shakapacker_install_env = options.rspack? ? { "SHAKAPACKER_ASSETS_BUNDLER" => "rspack" } : {}
        success = Bundler.with_unbundled_env do
          system(shakapacker_install_env, "bundle exec rails shakapacker:install")
        end
        if success
          true
        else
          handle_shakapacker_install_error
          false
        end
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
        raise Thor::Error, error unless options.ignore_warnings?
      end

      def missing_package_manager?
        package_managers = %w[npm pnpm yarn bun]
        missing = package_managers.none? { |pm| cli_exists?(pm) }

        if missing
          error = <<~MSG.strip
            🚫 No JavaScript package manager found on your system.

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

        false
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

        # Ensure the types directory exists
        FileUtils.mkdir_p("app/javascript/types")

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

        File.write("app/javascript/types/css-modules.d.ts", css_module_types_content)
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
            "app/javascript/**/*"
          ]
        }

        File.write("tsconfig.json", JSON.pretty_generate(tsconfig_content))
        say "✅ Created tsconfig.json", :green
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
