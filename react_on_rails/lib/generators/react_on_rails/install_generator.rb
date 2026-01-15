# frozen_string_literal: true

require "rails/generators"
require "json"
require "bundler"
require_relative "generator_helper"
require_relative "generator_messages"
require_relative "js_dependency_manager"

module ReactOnRails
  module Generators
    # rubocop:disable Metrics/ClassLength
    class InstallGenerator < Rails::Generators::Base
      include GeneratorHelper
      include JsDependencyManager

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

      # Removed: --skip-shakapacker-install (Shakapacker is now a required dependency)

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
          # Only add the post install message if not using Redux
          # Redux generator handles its own messages
          add_post_install_message unless options.redux?
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

      def print_generator_messages
        GeneratorMessages.messages.each do |message|
          puts message
          puts "" # Blank line after each message for readability
        end
      end

      def invoke_generators
        ensure_shakapacker_installed
        if options.typescript?
          install_typescript_dependencies
          create_css_module_types
          create_typescript_config
        end
        invoke "react_on_rails:base", [],
               { typescript: options.typescript?, redux: options.redux?, rspack: options.rspack?,
                 pro: options.pro?, rsc: options.rsc? }

        # Component generator logic:
        # - --rsc without --redux: Skip HelloWorld, HelloServer will be generated in setup_rsc
        # - --rsc with --redux: Generate HelloWorldApp (user explicitly wants Redux) + HelloServer
        # - Without --rsc: Normal behavior (HelloWorld or HelloWorldApp based on --redux)
        if options.redux?
          invoke "react_on_rails:react_with_redux", [], { typescript: options.typescript? }
        elsif !use_rsc?
          # Only generate HelloWorld if RSC is not enabled
          # For RSC, HelloServer replaces HelloWorld as the example component
          invoke "react_on_rails:react_no_redux", [], { typescript: options.typescript? }
        end

        setup_react_dependencies
        warn_about_react_version_for_rsc
        setup_pro if use_pro?
        setup_rsc if use_rsc?
      end

      def setup_react_dependencies
        setup_js_dependencies
      end

      # NOTE: other requirements for existing files such as .gitignore or application.
      # js(.coffee) are not checked by this method, but instead produce warning messages
      # and allow the build to continue
      def installation_prerequisites_met?
        !(missing_node? || missing_package_manager? || missing_pro_gem? ||
          ReactOnRails::GitUtils.uncommitted_changes?(GeneratorMessages))
      end

      # Check if Pro gem is required but not installed
      # Returns true (prerequisite NOT met) if --pro or --rsc flag is used but gem is missing
      def missing_pro_gem?
        return false unless use_pro?
        return false if pro_gem_installed?

        error = <<~MSG.strip
          🚫 React on Rails Pro gem is required for #{use_rsc? ? '--rsc' : '--pro'} flag.

          The Pro gem must be installed before running this generator.

          Installation steps:
          1. Add to your Gemfile:
               gem 'react_on_rails_pro', '~> 16.2'

          2. Run: bundle install

          3. Re-run this generator with your original flags.

          Try Pro free! Email justin@shakacode.com for an evaluation license.
          More info: https://www.shakacode.com/react-on-rails-pro/
        MSG
        # TODO: Update URL to licenses.shakacode.com when the self-service licensing app is deployed
        GeneratorMessages.add_error(error)
        true
      end

      # Warn if React version is not compatible with RSC
      # RSC requires React 19.0.x specifically (not 19.1.x or later)
      def warn_about_react_version_for_rsc
        return unless use_rsc?

        react_version = detect_react_version
        return if react_version.nil? # React not installed yet, will be installed by generator

        # Check if React version is 19.0.x
        major, minor, patch = react_version.split(".").map(&:to_i)

        if major != 19 || minor != 0
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  RSC requires React 19.0.x (detected: #{react_version})

            React Server Components in React on Rails Pro currently only supports
            React 19.0.x. React 19.1.x and later are not yet supported.

            To upgrade React:
              npm install react@19.0.3 react-dom@19.0.3

            Or with your package manager:
              pnpm add react@19.0.3 react-dom@19.0.3
              yarn add react@19.0.3 react-dom@19.0.3
          MSG
        elsif patch < 3
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  React #{react_version} has known security vulnerabilities.

            Please upgrade to at least React 19.0.3:
              npm install react@19.0.3 react-dom@19.0.3

            See: CVE-2025-55182, CVE-2025-67779
          MSG
        end
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

      def ensure_shakapacker_installed
        return if shakapacker_configured?

        print_shakapacker_setup_banner
        ensure_shakapacker_in_gemfile
        install_shakapacker
        finalize_shakapacker_setup
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

        # Make these and only these files executable
        files_to_copy = []
        Dir.chdir(template_bin_path) do
          files_to_copy.concat(Dir.glob("*"))
        end
        files_to_become_executable = files_to_copy.map { |filename| "bin/#{filename}" }

        File.chmod(0o755, *files_to_become_executable)
      end

      def add_post_install_message
        # Determine what route will be created by the generator
        route = "hello_world" # This is the hardcoded route from base_generator.rb
        component_name = options.redux? ? "HelloWorldApp" : "HelloWorld"

        GeneratorMessages.add_info(GeneratorMessages.helpful_message_after_installation(
                                     component_name: component_name,
                                     route: route
                                   ))
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
          File.exist?("config/webpack/webpack.config.js")
      end

      def print_shakapacker_setup_banner
        puts Rainbow("\n#{'=' * 80}").cyan
        puts Rainbow("🔧 SHAKAPACKER SETUP").cyan.bold
        puts Rainbow("=" * 80).cyan
      end

      def ensure_shakapacker_in_gemfile
        return if shakapacker_in_gemfile?

        puts Rainbow("📝 Adding Shakapacker to Gemfile...").yellow
        # Use with_unbundled_env to prevent inheriting BUNDLE_GEMFILE from parent process
        # See: https://github.com/shakacode/react_on_rails/issues/2287
        success = Bundler.with_unbundled_env { system("bundle add shakapacker --strict") }
        return if success

        handle_shakapacker_gemfile_error
      end

      def install_shakapacker
        puts Rainbow("⚙️  Installing Shakapacker (required for webpack integration)...").yellow

        # First run bundle install to make shakapacker available
        # Use with_unbundled_env to prevent inheriting BUNDLE_GEMFILE from parent process
        puts Rainbow("📦 Running bundle install...").yellow
        bundle_success = Bundler.with_unbundled_env { system("bundle install") }
        unless bundle_success
          handle_shakapacker_install_error
          return
        end

        # Then run the shakapacker installer
        success = Bundler.with_unbundled_env { system("bundle exec rails shakapacker:install") }
        return if success

        handle_shakapacker_install_error
      end

      def finalize_shakapacker_setup
        puts Rainbow("✅ Shakapacker installed successfully!").green
        puts Rainbow("=" * 80).cyan
        puts Rainbow("🚀 CONTINUING WITH REACT ON RAILS SETUP").cyan.bold
        puts "#{Rainbow('=' * 80).cyan}\n"

        # Create marker file so base generator can avoid copying shakapacker.yml
        File.write(".shakapacker_just_installed", "")
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

          Then re-run: rails generate react_on_rails:install
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
          5. Re-run: rails generate react_on_rails:install

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
        puts Rainbow("📝 Installing TypeScript dependencies...").yellow
        # Delegate to shared module for consistent dependency management
        add_typescript_dependencies
      end

      def create_css_module_types
        puts Rainbow("📝 Creating CSS module type definitions...").yellow

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
        puts Rainbow("✅ Created CSS module type definitions").green
      end

      def create_typescript_config
        if File.exist?("tsconfig.json")
          puts Rainbow("⚠️  tsconfig.json already exists, skipping creation").yellow
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
        puts Rainbow("✅ Created tsconfig.json").green
      end

      # Pro setup methods

      def setup_pro
        puts Rainbow("\n#{'=' * 80}").cyan
        puts Rainbow("🚀 REACT ON RAILS PRO SETUP").cyan.bold
        puts Rainbow("=" * 80).cyan

        create_pro_initializer
        create_node_renderer
        add_pro_to_procfile
        # NOTE: Pro npm dependencies are added in add_js_dependencies (js_dependency_manager.rb)
        # to ensure single npm install run with all dependencies

        puts Rainbow("=" * 80).cyan
        puts Rainbow("✅ React on Rails Pro setup complete!").green
        puts Rainbow("=" * 80).cyan
      end

      def create_pro_initializer
        initializer_path = "config/initializers/react_on_rails_pro.rb"

        if File.exist?(File.join(destination_root, initializer_path))
          puts Rainbow("ℹ️  #{initializer_path} already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating React on Rails Pro initializer...").yellow

        pro_template_path = "templates/pro/base/config/initializers/react_on_rails_pro.rb.tt"
        template(pro_template_path, initializer_path)

        puts Rainbow("✅ Created #{initializer_path}").green
      end

      def create_node_renderer
        node_renderer_path = "client/node-renderer.js"

        if File.exist?(File.join(destination_root, node_renderer_path))
          puts Rainbow("ℹ️  #{node_renderer_path} already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating Node Renderer bootstrap...").yellow

        # Ensure client directory exists
        FileUtils.mkdir_p("client")

        template_path = "templates/pro/base/client/node-renderer.js"
        copy_file(template_path, node_renderer_path)

        puts Rainbow("✅ Created #{node_renderer_path}").green
      end

      def add_pro_to_procfile
        procfile_path = File.join(destination_root, "Procfile.dev")

        # Check if Procfile.dev exists
        unless File.exist?(procfile_path)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Procfile.dev not found. Skipping Node Renderer process addition.

            You'll need to add the Node Renderer to your process manager manually:
              node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node client/node-renderer.js
          MSG
          return
        end

        # Check if node-renderer is already in Procfile.dev (idempotency)
        if File.read(procfile_path).include?("node-renderer:")
          puts Rainbow("ℹ️  Node Renderer already in Procfile.dev, skipping").yellow
          return
        end

        puts Rainbow("📝 Adding Node Renderer to Procfile.dev...").yellow

        node_renderer_line = <<~PROCFILE

          # React on Rails Pro - Node Renderer for SSR
          node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node client/node-renderer.js
        PROCFILE

        append_to_file("Procfile.dev", node_renderer_line)

        puts Rainbow("✅ Added Node Renderer to Procfile.dev").green
      end

      # RSC setup methods

      def setup_rsc
        puts Rainbow("\n#{'=' * 80}").magenta
        puts Rainbow("🚀 REACT SERVER COMPONENTS SETUP").magenta.bold
        puts Rainbow("=" * 80).magenta

        create_rsc_webpack_config
        add_rsc_to_procfile
        create_hello_server_component
        create_hello_server_controller
        create_hello_server_view
        add_rsc_routes
        # NOTE: RSC npm dependencies are added in add_js_dependencies (js_dependency_manager.rb)
        # to ensure single npm install run with all dependencies

        puts Rainbow("=" * 80).magenta
        puts Rainbow("✅ React Server Components setup complete!").green
        puts Rainbow("=" * 80).magenta
      end

      def create_rsc_webpack_config
        webpack_config_path = "config/webpack/rscWebpackConfig.js"

        if File.exist?(File.join(destination_root, webpack_config_path))
          puts Rainbow("ℹ️  #{webpack_config_path} already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating RSC webpack config...").yellow

        rsc_template_path = "templates/rsc/base/config/webpack/rscWebpackConfig.js.tt"
        template(rsc_template_path, webpack_config_path)

        puts Rainbow("✅ Created #{webpack_config_path}").green
      end

      def add_rsc_to_procfile
        procfile_path = File.join(destination_root, "Procfile.dev")

        # Check if Procfile.dev exists
        unless File.exist?(procfile_path)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Procfile.dev not found. Skipping RSC bundle watcher addition.

            You'll need to add the RSC bundle watcher to your process manager manually:
              rsc-bundle: RSC_BUNDLE_ONLY=yes bin/shakapacker --watch
          MSG
          return
        end

        # Check if RSC watcher is already in Procfile.dev (idempotency)
        if File.read(procfile_path).include?("RSC_BUNDLE_ONLY")
          puts Rainbow("ℹ️  RSC bundle watcher already in Procfile.dev, skipping").yellow
          return
        end

        puts Rainbow("📝 Adding RSC bundle watcher to Procfile.dev...").yellow

        rsc_watcher_line = <<~PROCFILE

          # React on Rails Pro - RSC bundle watcher
          rsc-bundle: RSC_BUNDLE_ONLY=yes bin/shakapacker --watch
        PROCFILE

        append_to_file("Procfile.dev", rsc_watcher_line)

        puts Rainbow("✅ Added RSC bundle watcher to Procfile.dev").green
      end

      def create_hello_server_component
        hello_server_dir = "app/javascript/src/HelloServer"
        ror_components_dir = "#{hello_server_dir}/ror_components"
        components_dir = "#{hello_server_dir}/components"
        ext = component_extension(options)

        # Check if HelloServer already exists (check both jsx and tsx)
        if File.exist?(File.join(destination_root, "#{ror_components_dir}/HelloServer.jsx")) ||
           File.exist?(File.join(destination_root, "#{ror_components_dir}/HelloServer.tsx"))
          puts Rainbow("ℹ️  HelloServer component already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating HelloServer component...").yellow

        # Create directories
        empty_directory(ror_components_dir)
        empty_directory(components_dir)

        # Copy component files (uses jsx or tsx based on --typescript flag)
        copy_file("templates/rsc/base/app/javascript/src/HelloServer/ror_components/HelloServer.#{ext}",
                  "#{ror_components_dir}/HelloServer.#{ext}")
        copy_file("templates/rsc/base/app/javascript/src/HelloServer/components/HelloServer.#{ext}",
                  "#{components_dir}/HelloServer.#{ext}")

        puts Rainbow("✅ Created HelloServer component").green
      end

      def create_hello_server_controller
        controller_path = "app/controllers/hello_server_controller.rb"

        if File.exist?(File.join(destination_root, controller_path))
          puts Rainbow("ℹ️  HelloServerController already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating HelloServerController...").yellow

        copy_file("templates/rsc/base/app/controllers/hello_server_controller.rb", controller_path)

        puts Rainbow("✅ Created #{controller_path}").green
      end

      def create_hello_server_view
        view_path = "app/views/hello_server/index.html.erb"

        if File.exist?(File.join(destination_root, view_path))
          puts Rainbow("ℹ️  HelloServer view already exists, skipping").yellow
          return
        end

        puts Rainbow("📝 Creating HelloServer view...").yellow

        # Create views directory if needed
        empty_directory("app/views/hello_server")

        copy_file("templates/rsc/base/app/views/hello_server/index.html.erb", view_path)

        puts Rainbow("✅ Created #{view_path}").green
      end

      def add_rsc_routes
        routes_file = File.join(destination_root, "config/routes.rb")
        routes_content = File.read(routes_file)

        # Check if RSC routes already exist
        if routes_content.include?("rsc_payload_route")
          puts Rainbow("ℹ️  RSC routes already exist, skipping").yellow
          return
        end

        puts Rainbow("📝 Adding RSC routes...").yellow

        # Add rsc_payload_route (required for RSC payload requests)
        route "rsc_payload_route"

        # Add HelloServer route (RSC counterpart to hello_world)
        route "get 'hello_server', to: 'hello_server#index'"

        puts Rainbow("✅ Added RSC routes to config/routes.rb").green
      end

      # rubocop:enable Metrics/ClassLength
    end
  end
end
