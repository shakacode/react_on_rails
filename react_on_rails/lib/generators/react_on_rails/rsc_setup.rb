# frozen_string_literal: true

require_relative "generator_messages"

module ReactOnRails
  module Generators
    # Provides RSC (React Server Components) setup functionality for React on Rails generators.
    #
    # This module extracts RSC-specific setup methods that can be shared between:
    # - InstallGenerator (when --rsc flag is used)
    # - RscGenerator (standalone generator for upgrading existing Pro apps)
    #
    # == Required Dependencies
    # Including classes must provide (typically via Rails::Generators::Base):
    # - destination_root: Path to the target Rails application
    # - template, copy_file, append_to_file, empty_directory, route: Thor file manipulation methods
    # - options: Generator options hash (for options.typescript?)
    #
    # Including classes must also include GeneratorHelper which provides:
    # - use_rsc?: Feature flag helper
    # - component_extension: Returns 'jsx' or 'tsx' based on TypeScript option
    # - detect_react_version: Detects installed React version
    #
    module RscSetup # rubocop:disable Metrics/ModuleLength
      DEFAULT_LAYOUT_NAME = "react_on_rails_default"
      LEGACY_LAYOUT_NAME = "hello_world"
      RSC_FALLBACK_LAYOUT_NAME = "react_on_rails_rsc"
      RSC_GENERATED_LAYOUT_NAME_PATTERN = /\Areact_on_rails_rsc(?:_[2-9]\d*)?\z/
      MAX_LAYOUT_NAME_ATTEMPTS = 99

      # Main entry point for RSC setup.
      # Orchestrates creation of all RSC-related files and configuration.
      #
      # Creates:
      # - config/webpack/rscWebpackConfig.js (config/rspack/ when using rspack)
      # - Procfile.dev entry for RSC bundle watcher
      # - HelloServer component (jsx or tsx based on --typescript flag)
      # - HelloServerController
      # - HelloServer view
      # - RSC routes
      #
      # @note NPM dependencies are handled separately by JsDependencyManager
      def setup_rsc
        print_rsc_setup_banner

        add_rsc_config_to_pro_initializer
        create_rsc_webpack_config
        update_webpack_configs_for_rsc
        add_rsc_to_procfile
        create_hello_server_component
        create_hello_server_controller
        create_hello_server_view
        add_rsc_routes

        print_rsc_complete_banner
      end

      # Warn if React version is not compatible with RSC.
      # RSC requires React 19.0.x specifically (not 19.1.x or later).
      #
      # @param force [Boolean] When true, always performs the check.
      #   When false (default), only checks if RSC is enabled (use_rsc? returns true).
      #   Use force: true in standalone generators where RSC is always the purpose.
      def warn_about_react_version_for_rsc(force: false)
        return unless force || use_rsc?

        react_version = detect_react_version
        return if react_version.nil? # React not installed yet, will be installed by generator

        major, minor, patch = react_version.split(".").map(&:to_i)

        if major != 19 || minor != 0
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  RSC requires React 19.0.x (detected: #{react_version})

            React Server Components in React on Rails Pro currently only supports
            React 19.0.x. React 19.1.x and later are not yet supported.

            To install a compatible React version:
              npm install react@~19.0.4 react-dom@~19.0.4
          MSG
        elsif patch < 4
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  React #{react_version} is below the recommended minimum for RSC.

            Please upgrade to at least React 19.0.4:
              npm install react@19.0.4 react-dom@19.0.4

            react-server-dom-webpack 19.0.0–19.0.3 has known vulnerabilities
            (CVE-2025-55182, CVE-2025-67779, CVE-2026-23864) fixed in 19.0.4+.
          MSG
        end
      end

      private

      def add_rsc_config_to_pro_initializer
        initializer_path = "config/initializers/react_on_rails_pro.rb"
        full_path = File.join(destination_root, initializer_path)

        unless File.exist?(full_path)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Pro initializer not found at #{initializer_path}. Skipping RSC config.

            RSC requires React on Rails Pro. Run the Pro generator first:
              rails g react_on_rails:pro
          MSG
          return
        end

        content = File.read(full_path)

        if content.include?("enable_rsc_support")
          say "ℹ️  RSC config already in Pro initializer, skipping", :yellow
          return
        end

        say "📝 Adding RSC config to Pro initializer...", :yellow

        rsc_config = <<-CONFIG

  # React Server Components configuration
  config.enable_rsc_support = true
  config.rsc_bundle_js_file = "rsc-bundle.js"
  config.rsc_payload_generation_url_path = "rsc_payload/"
        CONFIG

        # Insert before the final 'end'
        gsub_file(initializer_path, /^end\s*\z/, "#{rsc_config}end")

        say "✅ Added RSC config to #{initializer_path}", :green
      end

      def print_rsc_setup_banner
        say "\n#{set_color('=' * 80, :magenta)}"
        say set_color("🚀 REACT SERVER COMPONENTS SETUP", :magenta, :bold)
        say set_color("=" * 80, :magenta)
      end

      def print_rsc_complete_banner
        say set_color("=" * 80, :magenta)
        say "✅ React Server Components setup complete!", :green
        say set_color("=" * 80, :magenta)
      end

      def create_rsc_webpack_config
        webpack_config_path = destination_config_path("config/webpack/rscWebpackConfig.js")

        if File.exist?(File.join(destination_root, webpack_config_path))
          say "ℹ️  #{webpack_config_path} already exists, skipping", :yellow
          return
        end

        say "📝 Creating RSC webpack config...", :yellow

        rsc_template_path = "templates/rsc/base/config/webpack/rscWebpackConfig.js.tt"
        template(rsc_template_path, webpack_config_path)

        say "✅ Created #{webpack_config_path}", :green
      end

      def add_rsc_to_procfile
        procfile_path = File.join(destination_root, "Procfile.dev")

        unless File.exist?(procfile_path)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Procfile.dev not found. Skipping RSC bundle watcher addition.

            You'll need to add the RSC bundle watcher to your process manager manually:
              rsc-bundle: RSC_BUNDLE_ONLY=yes bin/shakapacker --watch
          MSG
          return
        end

        if File.read(procfile_path).include?("RSC_BUNDLE_ONLY")
          say "ℹ️  RSC bundle watcher already in Procfile.dev, skipping", :yellow
          return
        end

        say "📝 Adding RSC bundle watcher to Procfile.dev...", :yellow

        rsc_watcher_line = <<~PROCFILE

          # React on Rails Pro - RSC bundle watcher
          rsc-bundle: RSC_BUNDLE_ONLY=yes bin/shakapacker --watch
        PROCFILE

        append_to_file("Procfile.dev", rsc_watcher_line)

        say "✅ Added RSC bundle watcher to Procfile.dev", :green
      end

      def create_hello_server_component
        hello_server_dir = "app/javascript/src/HelloServer"
        ror_components_dir = "#{hello_server_dir}/ror_components"
        components_dir = "#{hello_server_dir}/components"
        ext = component_extension(options)

        # Check if HelloServer already exists (check both jsx and tsx)
        if File.exist?(File.join(destination_root, "#{ror_components_dir}/HelloServer.jsx")) ||
           File.exist?(File.join(destination_root, "#{ror_components_dir}/HelloServer.tsx"))
          say "ℹ️  HelloServer component already exists, skipping", :yellow
          return
        end

        say "📝 Creating HelloServer component...", :yellow

        # Create directories
        empty_directory(ror_components_dir)
        empty_directory(components_dir)

        # Copy component files (uses jsx or tsx based on --typescript flag)
        copy_file("templates/rsc/base/app/javascript/src/HelloServer/ror_components/HelloServer.#{ext}",
                  "#{ror_components_dir}/HelloServer.#{ext}")
        copy_file("templates/rsc/base/app/javascript/src/HelloServer/components/HelloServer.#{ext}",
                  "#{components_dir}/HelloServer.#{ext}")
        copy_file("templates/rsc/base/app/javascript/src/HelloServer/components/LikeButton.#{ext}",
                  "#{components_dir}/LikeButton.#{ext}")

        say "✅ Created HelloServer component", :green
      end

      def create_hello_server_controller
        controller_path = "app/controllers/hello_server_controller.rb"

        if File.exist?(File.join(destination_root, controller_path))
          say "ℹ️  HelloServerController already exists, skipping", :yellow
          return
        end

        say "📝 Creating HelloServerController...", :yellow

        layout_name = resolve_hello_server_layout_name
        template("templates/rsc/base/app/controllers/hello_server_controller.rb.tt",
                 controller_path,
                 layout_name: layout_name)

        say "✅ Created #{controller_path}", :green
      end

      def create_hello_server_view
        view_path = "app/views/hello_server/index.html.erb"

        if File.exist?(File.join(destination_root, view_path))
          say "ℹ️  HelloServer view already exists, skipping", :yellow
          return
        end

        say "📝 Creating HelloServer view...", :yellow

        # Create views directory if needed
        empty_directory("app/views/hello_server")

        copy_file("templates/rsc/base/app/views/hello_server/index.html.erb", view_path)

        say "✅ Created #{view_path}", :green
      end

      def add_rsc_routes
        routes_file = File.join(destination_root, "config/routes.rb")

        unless File.exist?(routes_file)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  config/routes.rb not found. Skipping RSC routes.

            You'll need to add the following routes manually:
              rsc_payload_route
              get 'hello_server', to: 'hello_server#index'
          MSG
          return
        end

        routes_content = File.read(routes_file)

        if routes_content.include?("rsc_payload_route")
          say "ℹ️  RSC routes already exist, skipping", :yellow
          return
        end

        say "📝 Adding RSC routes...", :yellow

        # Add rsc_payload_route (required for RSC payload requests)
        route "rsc_payload_route"

        # Add HelloServer route (RSC counterpart to hello_world)
        route "get 'hello_server', to: 'hello_server#index'"

        say "✅ Added RSC routes to config/routes.rb", :green
      end

      # Update webpack configs to enable RSC support.
      # This is needed for standalone RSC upgrades where the base install
      # created webpack configs without RSC settings enabled.
      #
      # Updates:
      # - ServerClientOrBoth.js: RSC imports, rscConfig, RSC_BUNDLE_ONLY handling
      # - serverWebpackConfig.js: RSCWebpackPlugin import, rscBundle param, plugin
      # - clientWebpackConfig.js: RSCWebpackPlugin import, plugin
      def update_webpack_configs_for_rsc
        say "📝 Updating webpack configs for RSC...", :yellow

        update_server_client_or_both_for_rsc
        update_server_webpack_config_for_rsc
        update_client_webpack_config_for_rsc

        verify_rsc_webpack_transforms
        say "✅ Updated webpack configs for RSC", :green
      end

      def update_server_client_or_both_for_rsc
        config_path = resolve_server_client_or_both_path
        return unless config_path

        content = File.read(File.join(destination_root, config_path))

        # Skip if RSC is already configured
        return if content.include?("rscWebpackConfig")

        # Add RSC import after serverWebpackConfig import
        gsub_file(
          config_path,
          %r{(const (?:\{ default: serverWebpackConfig \}|serverWebpackConfig) = require\('\./serverWebpackConfig'\);)},
          "\\1\nconst rscWebpackConfig = require('./rscWebpackConfig');"
        )

        # Add rscConfig variable after serverConfig (with blank line separator)
        gsub_file(
          config_path,
          /^(\s*const serverConfig = serverWebpackConfig\(\);)$/,
          "\\1\n\n  const rscConfig = rscWebpackConfig();"
        )

        # Update envSpecific call to include rscConfig
        gsub_file(
          config_path,
          /envSpecific\(clientConfig, serverConfig\);/,
          "envSpecific(clientConfig, serverConfig, rscConfig);"
        )

        # Add RSC_BUNDLE_ONLY handling before the else block
        rsc_bundle_handling = <<~JS.chomp
          } else if (process.env.RSC_BUNDLE_ONLY) {
              // eslint-disable-next-line no-console
              console.log('[React on Rails] Creating only the RSC bundle.');
              result = rscConfig;
        JS
        gsub_file(
          config_path,
          %r{\n(\s*\} else \{\s*\n\s*// default is the standard client and server build)},
          "\n  #{rsc_bundle_handling}\n\\1"
        )

        # Update default multi-bundle output to include RSC
        gsub_file(
          config_path,
          /console\.log\('\[React on Rails\] Creating both client and server bundles\.'\);/,
          "console.log('[React on Rails] Creating client, server, and RSC bundles.');"
        )
        gsub_file(
          config_path,
          /result = \[clientConfig, serverConfig\];/,
          "result = [clientConfig, serverConfig, rscConfig];"
        )
      end

      def update_server_webpack_config_for_rsc
        config_path = destination_config_path("config/webpack/serverWebpackConfig.js")
        full_path = File.join(destination_root, config_path)

        return unless File.exist?(full_path)

        content = File.read(full_path)

        # Skip if RSCWebpackPlugin is already configured
        return if content.include?("RSCWebpackPlugin")

        # Add RSCWebpackPlugin import after bundler require
        gsub_file(
          config_path,
          %r{(const bundler = config\.assets_bundler.*\n.*require\('@rspack/core'\).*\n.*: require\('webpack'\);)},
          "\\1\nconst { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');"
        )

        # Add rscBundle parameter to configureServer function
        gsub_file(
          config_path,
          /^const configureServer = \(\) => \{/,
          "// rscBundle parameter: when true, skips RSCWebpackPlugin (RSC bundle doesn't need it)\n" \
          "const configureServer = (rscBundle = false) => {"
        )

        # Add RSCWebpackPlugin to plugins before LimitChunkCountPlugin (matches template ordering)
        rsc_plugin_code = "// Add RSC plugin for server bundle (handles client component references)\n  " \
                          "// Skip for RSC bundle - it doesn't need RSCWebpackPlugin\n  " \
                          "if (!rscBundle) {\n    " \
                          "serverWebpackConfig.plugins.push(new RSCWebpackPlugin({ isServer: true }));\n  " \
                          "}"
        gsub_file(
          config_path,
          /(serverWebpackConfig\.plugins\.unshift\(new bundler\.optimize\.LimitChunkCountPlugin.*\);)/,
          "#{rsc_plugin_code}\n  \\1"
        )
      end

      def update_client_webpack_config_for_rsc
        config_path = destination_config_path("config/webpack/clientWebpackConfig.js")
        full_path = File.join(destination_root, config_path)

        return unless File.exist?(full_path)

        content = File.read(full_path)

        # Skip if RSCWebpackPlugin is already configured
        return if content.include?("RSCWebpackPlugin")

        # Add RSCWebpackPlugin import after commonWebpackConfig import
        gsub_file(
          config_path,
          %r{(const commonWebpackConfig = require\('\./commonWebpackConfig'\);)},
          "\\1\nconst { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');"
        )

        # Add RSCWebpackPlugin to client config before return statement
        rsc_plugin_code = "  // Add React Server Components plugin for client bundle\n  " \
                          "clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));"
        gsub_file(
          config_path,
          /^( *return clientConfig;)$/,
          "#{rsc_plugin_code}\n\n\\1"
        )
      end

      def verify_rsc_webpack_transforms
        missing = []
        missing.concat(check_rsc_server_config)
        missing.concat(check_rsc_client_config)
        missing.concat(check_rsc_scob_config)
        return if missing.empty?

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Some RSC webpack transforms may not have applied correctly.

          Missing expected patterns:
          #{missing.map { |m| "  - #{m}" }.join("\n")}

          This can happen if your webpack config has been customized.
          Please verify your webpack configs manually.
        MSG
      end

      def check_rsc_server_config
        path = File.join(destination_root, destination_config_path("config/webpack/serverWebpackConfig.js"))
        return [] unless File.exist?(path)

        content = File.read(path)
        missing = []
        missing << "RSCWebpackPlugin in serverWebpackConfig.js" unless content.include?("RSCWebpackPlugin")
        missing << "rscBundle parameter in serverWebpackConfig.js" unless content.include?("rscBundle")
        missing
      end

      def check_rsc_client_config
        path = File.join(destination_root, destination_config_path("config/webpack/clientWebpackConfig.js"))
        return [] unless File.exist?(path)

        content = File.read(path)
        content.include?("RSCWebpackPlugin") ? [] : ["RSCWebpackPlugin in clientWebpackConfig.js"]
      end

      def check_rsc_scob_config
        scob_path = resolve_server_client_or_both_path
        return [] unless scob_path

        content = File.read(File.join(destination_root, scob_path))
        content.include?("rscWebpackConfig") ? [] : ["rscWebpackConfig in ServerClientOrBoth.js"]
      end

      def resolve_hello_server_layout_name
        classification_by_layout = candidate_layout_names.to_h do |layout_name|
          [layout_name, classify_hello_server_layout(layout_name)]
        end

        reusable_layout_name = find_reusable_hello_server_layout_name(classification_by_layout)
        return reusable_layout_name if reusable_layout_name

        create_new_hello_server_layout(
          skipped_layout_paths: skipped_existing_layout_paths(classification_by_layout)
        )
      end

      def find_reusable_hello_server_layout_name(classification_by_layout)
        declared_layout_name = hello_world_controller_layout_name

        if reusable_layout_classification?(classification_by_layout[declared_layout_name])
          announce_reused_hello_server_layout(declared_layout_name, classification_by_layout[declared_layout_name])
          return declared_layout_name
        end

        preferred_layout_name = first_layout_name_with_classification(
          classification_by_layout,
          :canonical,
          excluding: declared_layout_name
        )
        return preferred_layout_name if preferred_layout_name

        first_layout_name_with_reusable_classification(
          classification_by_layout,
          excluding: declared_layout_name
        )
      end

      def first_layout_name_with_classification(classification_by_layout, expected_classification, excluding: nil)
        classification_by_layout.each do |layout_name, classification|
          next if layout_name == excluding
          next unless classification == expected_classification

          announce_reused_hello_server_layout(layout_name, classification)
          return layout_name
        end

        nil
      end

      def first_layout_name_with_reusable_classification(classification_by_layout, excluding: nil)
        classification_by_layout.each do |layout_name, classification|
          next if layout_name == excluding
          next unless reusable_layout_classification?(classification)

          announce_reused_hello_server_layout(layout_name, classification)
          return layout_name
        end

        nil
      end

      def announce_reused_hello_server_layout(layout_name, classification)
        message = +"ℹ️  Reusing existing #{layout_name} layout for HelloServerController"
        message << " (new generated layouts use empty pack tags by default)" if classification == :reusable
        say message, :yellow
      end

      def candidate_layout_names
        [
          hello_world_controller_layout_name,
          DEFAULT_LAYOUT_NAME,
          LEGACY_LAYOUT_NAME,
          *existing_rsc_layout_names
        ].compact.uniq
      end

      def hello_world_controller_layout_name
        return @hello_world_controller_layout_name if defined?(@hello_world_controller_layout_name)

        controller_path = File.join(destination_root, "app/controllers/hello_world_controller.rb")
        @hello_world_controller_layout_name = if File.exist?(controller_path)
                                                extract_declared_layout_name(File.read(controller_path))
                                              end
      end

      def extract_declared_layout_name(controller_content)
        match = controller_content.match(/^\s*layout(?:\s+|\s*\(\s*)(?:"([^"]+)"|'([^']+)')(?=\s*(?:\)|,|#|$))/)
        match&.captures&.compact&.first
      end

      def existing_rsc_layout_names
        Dir.glob(File.join(destination_root, "app/views/layouts/react_on_rails_rsc*.html.erb"))
           .map { |path| File.basename(path, ".html.erb") }
           .select { |layout_name| generated_rsc_layout_name?(layout_name) }
      end

      def generated_rsc_layout_name?(layout_name)
        layout_name.match?(RSC_GENERATED_LAYOUT_NAME_PATTERN)
      end

      def classify_hello_server_layout(layout_name)
        layout_path = layout_destination_path(layout_name)
        full_path = File.join(destination_root, layout_path)
        return :missing unless File.exist?(full_path)

        layout_content = File.read(full_path)
        return :missing_pack_tags unless layout_has_required_pack_tags?(layout_content)

        return :canonical if layout_uses_canonical_pack_tags?(layout_content)

        :reusable
      end

      def skipped_existing_layout_paths(classification_by_layout)
        classification_by_layout.filter_map do |layout_name, classification|
          layout_path = layout_destination_path(layout_name)
          full_path = File.join(destination_root, layout_path)

          next unless File.exist?(full_path)
          next if reusable_layout_classification?(classification)

          layout_path
        end
      end

      def layout_destination_path(layout_name)
        "app/views/layouts/#{layout_name}.html.erb"
      end

      def layout_has_required_pack_tags?(layout_content)
        pack_tag_present?(layout_content, "javascript_pack_tag") &&
          pack_tag_present?(layout_content, "stylesheet_pack_tag")
      end

      def layout_uses_canonical_pack_tags?(layout_content)
        pack_tag_without_names?(layout_content, "javascript_pack_tag") &&
          pack_tag_without_names?(layout_content, "stylesheet_pack_tag")
      end

      def reusable_layout_classification?(classification)
        %i[canonical reusable].include?(classification)
      end

      def pack_tag_present?(layout_content, helper_name)
        pack_tag_arguments(layout_content, helper_name).any?
      end

      def pack_tag_without_names?(layout_content, helper_name)
        arguments = pack_tag_arguments(layout_content, helper_name)
        arguments.any? && arguments.all? do |pack_tag_arguments|
          pack_tag_arguments_without_names?(pack_tag_arguments)
        end
      end

      def pack_tag_arguments(layout_content, helper_name)
        arguments_pattern = '\s*(?:\((?:(?!%>).)*?\)|(?:(?!%>).)*?)'
        pattern = /<%=\s*#{Regexp.escape(helper_name)}(?=\s|\(|%>)(?<arguments>#{arguments_pattern})?\s*%>/m

        arguments = []
        layout_content.scan(pattern) do
          arguments << Regexp.last_match[:arguments]
        end

        arguments
      end

      def pack_tag_arguments_without_names?(arguments)
        normalized_arguments = strip_wrapping_parentheses(arguments.to_s.strip)
        return true if normalized_arguments.empty?

        normalized_arguments.match?(/\A(?:\*\*[A-Za-z_]\w*|[a-z_]\w*\s*:.*)\z/m)
      end

      def strip_wrapping_parentheses(arguments)
        return arguments unless arguments.start_with?("(") && arguments.end_with?(")")

        arguments[1...-1].strip
      end

      def create_new_hello_server_layout(skipped_layout_paths: [])
        layout_name = next_available_hello_server_layout_name
        layout_path = layout_destination_path(layout_name)

        announce_skipped_layout_fallback(skipped_layout_paths, layout_path) if skipped_layout_paths.any?

        say "📝 Creating #{layout_path} for HelloServerController...", :yellow
        empty_directory("app/views/layouts")
        copy_file("templates/base/base/app/views/layouts/react_on_rails_default.html.erb", layout_path)
        say "✅ Created #{layout_path}", :green

        layout_name
      end

      def announce_skipped_layout_fallback(skipped_layout_paths, new_layout_path)
        skipped_paths = skipped_layout_paths.map { |path| "  - #{path}" }.join("\n")

        say <<~MSG, :yellow
          ℹ️  Found existing layout file(s) in your app that were not reused for HelloServerController:
          #{skipped_paths}

          Those file(s) do not include both `stylesheet_pack_tag` and `javascript_pack_tag`, so the generator
          will create #{new_layout_path} instead of overwriting them.
          New generated layouts use empty pack tags by default.
        MSG
      end

      def next_available_hello_server_layout_name
        default_layout_path = File.join(destination_root, layout_destination_path(DEFAULT_LAYOUT_NAME))
        return DEFAULT_LAYOUT_NAME unless File.exist?(default_layout_path)

        fallback_layout_path = File.join(destination_root, layout_destination_path(RSC_FALLBACK_LAYOUT_NAME))
        return RSC_FALLBACK_LAYOUT_NAME unless File.exist?(fallback_layout_path)

        (2..MAX_LAYOUT_NAME_ATTEMPTS).each do |suffix|
          layout_name = "#{RSC_FALLBACK_LAYOUT_NAME}_#{suffix}"
          return layout_name unless File.exist?(File.join(destination_root, layout_destination_path(layout_name)))
        end

        raise "Could not find an available RSC layout name after #{MAX_LAYOUT_NAME_ATTEMPTS} attempts."
      end
    end
  end
end
