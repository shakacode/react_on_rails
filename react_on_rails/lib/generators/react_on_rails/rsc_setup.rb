# frozen_string_literal: true

require_relative "generator_messages"
require_relative "demo_page_config"
require_relative "rsc_setup/client_references"
require_relative "rsc_setup/layouts"

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
      include DemoPageConfig
      include ClientReferences
      include Layouts

      DEFAULT_LAYOUT_NAME = "react_on_rails_default"
      LEGACY_LAYOUT_NAME = "hello_world"
      RSC_FALLBACK_LAYOUT_NAME = "react_on_rails_rsc"
      RSC_GENERATED_LAYOUT_NAME_PATTERN = /\Areact_on_rails_rsc(?:_(?:[2-9]|[1-9]\d+))?\z/
      MAX_LAYOUT_NAME_ATTEMPTS = 99
      RSC_MANIFEST_HELPER_IMPORT = "const { addRSCManifestPlugin } = require('./rscManifestPlugin');"
      RSC_WEBPACK_PLUGIN_IMPORT_PATTERN =
        %r{
          ^const\s+
          (?:\{\s*RSCWebpackPlugin\s*\}|RSCWebpackPlugin)\s*=\s*
          require\((['"])react-on-rails-rsc/WebpackPlugin\1\)
          (?:\.RSCWebpackPlugin)?;?(?:\s*//[^\n]*)?$
        }x
      RSC_MANIFEST_HELPER_IMPORT_PATTERN =
        %r{
          ^const\s+\{\s*addRSCManifestPlugin\s*\}\s*=\s*
          require\((['"])\./rscManifestPlugin\1\);?(?:\s*//[^\n]*)?$
        }x

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
        create_rsc_manifest_plugin
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

      def create_rsc_manifest_plugin
        plugin_path = destination_config_path("config/webpack/rscManifestPlugin.js")

        if File.exist?(File.join(destination_root, plugin_path))
          say "ℹ️  #{plugin_path} already exists, skipping", :yellow
          return
        end

        say "📝 Creating RSC manifest plugin helper...", :yellow

        template("templates/base/base/config/webpack/rscManifestPlugin.js.tt", plugin_path)

        say "✅ Created #{plugin_path}", :green
      end

      def add_rsc_to_procfile
        procfile_path = File.join(destination_root, "Procfile.dev")

        unless File.exist?(procfile_path)
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Procfile.dev not found. Skipping RSC bundle watcher addition.

            You'll need to add the RSC bundle watcher to your process manager manually:
              rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker-watch --watch
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
          rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker-watch --watch
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

        template("templates/rsc/base/app/views/hello_server/index.html.erb.tt",
                 view_path,
                 build_hello_server_view_config(
                   landing_page: new_app_landing_page_available?,
                   redux_demo: options[:redux]
                 ))

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
      # - serverWebpackConfig.js: RSC manifest plugin helper import, rscBundle param, plugin
      # - clientWebpackConfig.js: RSC manifest plugin helper import, plugin
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
        original_content = content

        fallback_import_pattern = server_bundler_fallback_import_pattern

        # Skip if the current helper-based RSC manifest wiring is already configured.
        return if existing_rsc_manifest_helper_invocation_handled?(
          config_path, content, "serverWebpackConfig", fallback_import_pattern, is_server: true
        )

        return if migrate_or_block_rsc_webpack_plugin?(
          config_path, content, "serverWebpackConfig", fallback_import_pattern, true
        )

        # Intentionally non-fatal: if scoped `rscClientReferences` setup fails (missing anchor,
        # blocked by later imports, or conflicting existing definition), we still add the helper
        # import and plugin call. The helper falls back to scanning `config.source_path` at
        # runtime, so the config remains functional without scoped references.
        return unless server_config_ready_for_manifest_helper?(config_path, content, original_content)

        ensure_rsc_client_references_setup(config_path, content, is_server: true, plugin_pending: true)
        content = File.read(full_path)
        unless add_rsc_manifest_helper_import(config_path, content, fallback_import_pattern)
          rollback_incomplete_rsc_manifest_setup(
            config_path,
            original_content,
            reason: "missing helper import anchor"
          )
          return
        end

        # Add rscBundle parameter to configureServer function
        gsub_file(
          config_path,
          server_configure_without_rsc_bundle_pattern,
          "// rscBundle parameter: when true, skips manifest generation (RSC bundle doesn't need it)\n" \
          "const configureServer = (rscBundle = false) => {"
        )
        content = File.read(full_path)

        # Add RSC manifest generation before LimitChunkCountPlugin (matches template ordering)
        rsc_plugin_code = server_rsc_manifest_plugin_code(content)
        gsub_file(
          config_path,
          server_limit_chunk_count_plugin_anchor,
          "#{rsc_plugin_code}\n  \\1"
        )
      end

      def server_bundler_fallback_import_pattern
        rsc_client_references_setup_import_pattern(is_server: true)
      end

      def server_limit_chunk_count_plugin_anchor
        # This intentionally matches only the generated serverWebpackConfig.js shape. Custom configs that move or
        # rewrite LimitChunkCountPlugin will fail the guarded update and receive the rollback/warning path.
        Regexp.new(
          "(serverWebpackConfig\\.plugins\\.unshift\\(\\s*" \
          "new bundler\\.optimize\\.LimitChunkCountPlugin[\\s\\S]*?\\);)"
        )
      end

      def server_configure_without_rsc_bundle_pattern
        /^const configureServer\s*=\s*\(\s*\)\s*=>\s*\{/
      end

      def server_configure_with_rsc_bundle_pattern
        /^const configureServer\s*=\s*\(\s*rscBundle\s*=\s*false\s*\)\s*=>\s*\{/
      end

      def rewritable_server_configure_signature?(content)
        content.match?(server_configure_without_rsc_bundle_pattern) ||
          content.match?(server_configure_with_rsc_bundle_pattern)
      end

      def server_config_ready_for_manifest_helper?(config_path, content, original_content)
        unless content.match?(server_limit_chunk_count_plugin_anchor)
          rollback_incomplete_rsc_manifest_setup(config_path, original_content)
          return false
        end

        return true if rewritable_server_configure_signature?(content)

        rollback_incomplete_rsc_manifest_setup(
          config_path,
          original_content,
          reason: "configureServer signature was not recognized"
        )
        false
      end

      def server_rsc_manifest_plugin_code(content)
        plugin_options = rsc_manifest_plugin_options(content, true)
        "// Add RSC plugin for server bundle (handles client component references)\n  " \
          "// Skip for RSC bundle - it doesn't need manifest generation\n  " \
          "if (!rscBundle) {\n    " \
          "addRSCManifestPlugin(serverWebpackConfig, #{plugin_options});\n  " \
          "}"
      end

      def update_client_webpack_config_for_rsc
        config_path = destination_config_path("config/webpack/clientWebpackConfig.js")
        full_path = File.join(destination_root, config_path)

        return unless File.exist?(full_path)

        content = File.read(full_path)
        original_content = content

        fallback_import_pattern = %r{(const commonWebpackConfig = require\(['"]\./commonWebpackConfig['"]\);)}

        # Skip if the current helper-based RSC manifest wiring is already configured.
        return if existing_rsc_manifest_helper_invocation_handled?(
          config_path, content, "clientConfig", fallback_import_pattern, is_server: false
        )

        return if migrate_or_block_rsc_webpack_plugin?(
          config_path, content, "clientConfig", fallback_import_pattern, false
        )

        # Intentionally non-fatal: if scoped `rscClientReferences` setup fails (missing anchor,
        # blocked by later imports, or conflicting existing definition), we still add the helper
        # import and plugin call. The helper falls back to scanning `config.source_path` at
        # runtime, so the config remains functional without scoped references.
        ensure_rsc_client_references_setup(config_path, content, is_server: false, plugin_pending: true)
        content = File.read(full_path)
        unless add_rsc_manifest_helper_import(config_path, content, fallback_import_pattern)
          rollback_incomplete_rsc_manifest_setup(
            config_path,
            original_content,
            reason: "missing helper import anchor"
          )
          return
        end

        content = File.read(full_path)
        unless content.match?(/^( *return clientConfig;)$/)
          rollback_incomplete_rsc_manifest_setup(config_path, original_content)
          return
        end

        # Add RSC manifest generation to client config before return statement
        rsc_plugin_code = "  // Add React Server Components plugin for client bundle\n  " \
                          "addRSCManifestPlugin(clientConfig, #{rsc_manifest_plugin_options(content, false)});"
        gsub_file(
          config_path,
          /^( *return clientConfig;)$/,
          "#{rsc_plugin_code}\n\n\\1"
        )
      end

      def migrate_rsc_webpack_plugin_to_manifest_helper(config_path, content, bundler_config_name:,
                                                        fallback_import_pattern:, is_server:)
        original_content = content
        update_existing_rsc_webpack_config(config_path, content, is_server: is_server)
        content = File.read(File.join(destination_root, config_path))
        unless rsc_manifest_plugin_sections_ready?(content, is_server: is_server)
          rollback_incomplete_rsc_manifest_setup(
            config_path,
            original_content,
            reason: "missing top-level clientReferences in the existing RSCWebpackPlugin options"
          )
          return
        end
        unless replace_rsc_webpack_plugin_pushes_with_helper(config_path, content, bundler_config_name,
                                                             is_server: is_server)
          warn_rsc_manifest_helper_migration_failed(config_path)
          return
        end

        content = File.read(File.join(destination_root, config_path))
        return if replace_rsc_webpack_plugin_import_with_helper(config_path, content, fallback_import_pattern)

        rollback_incomplete_rsc_manifest_setup(config_path, original_content)
      end

      def rsc_manifest_plugin_sections_ready?(content, is_server:)
        sections = rsc_plugin_option_sections(content, is_server: is_server)
        return false if sections.empty?

        sections.all? do |section|
          rsc_plugin_body_has_top_level_key?(section.fetch(:body), "clientReferences")
        end
      end

      def replace_rsc_webpack_plugin_pushes_with_helper(config_path, content, bundler_config_name, is_server:)
        helper_invocation_exists = rsc_manifest_helper_invocation?(content, bundler_config_name)
        replacements = rsc_plugin_option_sections(content, is_server: is_server).filter_map do |section|
          replacement_range = rsc_plugin_push_replacement_range(content, section, bundler_config_name)
          next unless replacement_range

          replacement =
            if helper_invocation_exists
              ""
            else
              options_body = normalize_rsc_manifest_helper_options_body(section.fetch(:body))
              "addRSCManifestPlugin(#{bundler_config_name}, {#{options_body}});"
            end
          [replacement_range, replacement]
        end
        return false if replacements.empty?

        rewritten = content.dup
        replacements.reverse_each do |range, replacement|
          rewritten[range] = replacement
        end

        # Refuse a partial migration: if any `new RSCWebpackPlugin(...)` invocation still
        # exists after the planned rewrites (opposite `isServer:` target in the same file,
        # or a `plugins.push(...)` shape that didn't match), replacing the import would
        # leave a `ReferenceError` at build time. Bail without writing — the caller treats
        # this the same as the "no matches" case (warn + preserve scoped clientReferences
        # for manual migration).
        return false if rsc_webpack_plugin_invocation?(rewritten)

        write_existing_rsc_config(config_path, rewritten, action: :rewrite)
      end

      def rsc_plugin_push_replacement_range(content, section, bundler_config_name)
        prefix = content[0...section.fetch(:call_start)]
        prefix_pattern = /#{Regexp.escape(bundler_config_name)}\.plugins\.push\(\s*\z/m
        prefix_match = prefix.match(prefix_pattern)
        return unless prefix_match

        suffix = content[section.fetch(:call_end)..]
        suffix_match = suffix.match(/\A\s*,?\s*\);/)
        return unless suffix_match

        prefix_match.begin(0)...(section.fetch(:call_end) + suffix_match.end(0))
      end

      def normalize_rsc_manifest_helper_options_body(body)
        return body unless body.include?("\n")

        strip_indent = rsc_manifest_helper_options_body_strip_indent(body)
        return body if strip_indent.empty?

        body.lines.map do |line|
          line.start_with?(strip_indent) ? line.delete_prefix(strip_indent) : line
        end.join
      end

      def rsc_manifest_helper_options_body_strip_indent(body)
        indents = body.lines.filter_map do |line|
          next if line.strip.empty?

          line[/\A[ \t]*/]
        end
        return "" if indents.empty?

        common_indent = indents.reduce do |common, indent|
          common_string_prefix(common, indent)
        end
        closing_indent = body[/\n([ \t]*)\z/, 1] || ""

        return common_indent unless common_indent.start_with?(closing_indent)

        common_indent.delete_prefix(closing_indent)
      end

      def common_string_prefix(left, right)
        index = 0
        index += 1 while index < left.length && index < right.length && left[index] == right[index]
        left[0...index]
      end

      def replace_rsc_webpack_plugin_import_with_helper(config_path, content, fallback_import_pattern)
        if content.match?(RSC_WEBPACK_PLUGIN_IMPORT_PATTERN)
          if rsc_manifest_helper_import?(content)
            write_existing_rsc_config(
              config_path,
              remove_rsc_webpack_plugin_import_line(content),
              action: :rewrite
            )
          else
            gsub_file(config_path, RSC_WEBPACK_PLUGIN_IMPORT_PATTERN, RSC_MANIFEST_HELPER_IMPORT)
          end
          return true
        end

        add_rsc_manifest_helper_import(config_path, content, fallback_import_pattern)
      end

      def warn_rsc_manifest_helper_migration_failed(config_path)
        GeneratorMessages.add_warning(
          "Skipped RSC manifest helper migration for #{config_path}: one or more RSCWebpackPlugin push calls " \
          "could not be rewritten automatically (no matching push shape, or a mixed server/client invocation " \
          "in the same file). Scoped clientReferences setup was preserved; please migrate the plugin call to " \
          "addRSCManifestPlugin manually."
        )
      end

      def migrate_or_block_rsc_webpack_plugin?(
        config_path,
        content,
        bundler_config_name,
        fallback_import_pattern,
        is_server
      )
        return false unless rsc_webpack_plugin_invocation?(content)

        migrate_rsc_webpack_plugin_to_manifest_helper(
          config_path,
          content,
          bundler_config_name: bundler_config_name,
          fallback_import_pattern: fallback_import_pattern,
          is_server: is_server
        )
        # Always returns true after seeing an RSCWebpackPlugin invocation so the
        # caller's `return if ...` exits whether migration succeeded or rolled back.
        # Re-entering fresh setup after an ambiguous invocation would compound an
        # already-broken config; even a rolled-back attempt must block that path.
        true
      end

      def existing_rsc_manifest_helper_invocation_handled?(
        config_path,
        content,
        bundler_config_name,
        fallback_import_pattern,
        is_server:
      )
        return false unless rsc_manifest_helper_invocation?(content, bundler_config_name)
        return false if rsc_webpack_plugin_invocation?(content)

        warn_rsc_manifest_helper_import_missing(config_path) unless
          add_rsc_manifest_helper_import(config_path, content, fallback_import_pattern)
        content = File.read(File.join(destination_root, config_path))
        ensure_scoped_rsc_client_references_for_existing_helper(
          config_path, content, bundler_config_name, is_server: is_server
        )
        true
      end

      def ensure_scoped_rsc_client_references_for_existing_helper(
        config_path,
        content,
        bundler_config_name,
        is_server:
      )
        return unless rsc_manifest_helper_uses_scoped_client_references?(content, bundler_config_name)
        return if scoped_rsc_client_references_defined?(content)

        ensure_rsc_client_references_setup(config_path, content, is_server: is_server)
      end

      def rsc_manifest_helper_uses_scoped_client_references?(content, bundler_config_name)
        rsc_manifest_helper_option_sections(content, bundler_config_name).any? do |body|
          rsc_plugin_body_has_top_level_scoped_client_references?(body)
        end
      end

      def warn_rsc_manifest_helper_import_missing(config_path)
        GeneratorMessages.add_warning(
          "RSC manifest helper call already exists in #{config_path}, but the helper import could not be " \
          "inserted automatically. Please add #{RSC_MANIFEST_HELPER_IMPORT} manually."
        )
      end

      def rsc_manifest_helper_invocation?(content, bundler_config_name)
        pattern = /\baddRSCManifestPlugin\s*\(\s*#{Regexp.escape(bundler_config_name)}\b/
        search_from = 0
        while (match = content.match(pattern, search_from))
          return true if js_code_position?(content, match.begin(0))

          search_from = match.end(0)
        end

        false
      end

      def rsc_client_references_configured?(content, bundler_config_name, is_server:)
        sections = rsc_manifest_helper_option_sections(content, bundler_config_name)
        return rsc_manifest_plugin_sections_ready?(content, is_server: is_server) if sections.empty?

        sections.all? do |body|
          if rsc_plugin_body_has_top_level_scoped_client_references?(body)
            scoped_rsc_client_references_defined?(content)
          else
            rsc_plugin_body_has_top_level_key?(body, "clientReferences")
          end
        end
      end

      def rsc_manifest_helper_option_sections(content, bundler_config_name)
        pattern = /\baddRSCManifestPlugin\s*\(\s*#{Regexp.escape(bundler_config_name)}\b/
        sections = []
        search_from = 0

        while (match = content.match(pattern, search_from))
          call_start = match.begin(0)
          after_config_name = match.end(0)
          unless js_code_position?(content, call_start)
            search_from = after_config_name
            next
          end

          comma_index = first_significant_js_index(content, after_config_name)
          options_start = if comma_index && content[comma_index] == ","
                            first_significant_js_index(content, comma_index + 1)
                          end
          unless options_start && content[options_start] == "{"
            search_from = after_config_name
            next
          end

          options_end = matching_js_closing_brace(content, options_start)
          unless options_end
            search_from = options_start + 1
            next
          end

          sections << content[(options_start + 1)...options_end]
          search_from = options_end + 1
        end

        sections
      end

      def add_rsc_manifest_helper_import(config_path, content, fallback_import_pattern)
        if rsc_manifest_helper_import?(content)
          remove_stale_rsc_webpack_plugin_import(config_path, content)
          return true
        end

        if content.match?(RSC_WEBPACK_PLUGIN_IMPORT_PATTERN)
          gsub_file(config_path, RSC_WEBPACK_PLUGIN_IMPORT_PATTERN, RSC_MANIFEST_HELPER_IMPORT)
          return true
        end
        return false unless content.match?(fallback_import_pattern)

        gsub_file(config_path, fallback_import_pattern, "\\1\n#{RSC_MANIFEST_HELPER_IMPORT}")
        true
      end

      def remove_stale_rsc_webpack_plugin_import(config_path, content)
        return if rsc_webpack_plugin_invocation?(content)
        return unless content.match?(RSC_WEBPACK_PLUGIN_IMPORT_PATTERN)

        write_existing_rsc_config(
          config_path,
          remove_rsc_webpack_plugin_import_line(content),
          action: :rewrite
        )
      end

      def remove_rsc_webpack_plugin_import_line(content)
        lines = content.lines
        import_index = lines.index { |line| line.match?(RSC_WEBPACK_PLUGIN_IMPORT_PATTERN) }
        return content unless import_index

        lines.delete_at(import_index)
        lines.delete_at(import_index) if adjacent_blank_line_after_removed_import?(lines, import_index)
        lines.join
      end

      def adjacent_blank_line_after_removed_import?(lines, import_index)
        return false unless lines[import_index]&.strip&.empty?
        return true if import_index.zero?

        lines[import_index - 1].strip.empty?
      end

      def rsc_manifest_helper_import?(content)
        search_from = 0
        while (match = content.match(RSC_MANIFEST_HELPER_IMPORT_PATTERN, search_from))
          return true if js_code_position?(content, match.begin(0))

          search_from = match.end(0)
        end

        false
      end

      def rsc_manifest_plugin_options(content, is_server)
        options = "isServer: #{is_server}"
        options += ", clientReferences: rscClientReferences" if scoped_rsc_client_references_defined?(content)
        "{ #{options} }"
      end

      def rollback_incomplete_rsc_manifest_setup(config_path, original_content, reason: nil)
        return if options[:pretend] || options[:skip]

        say_status(:revert, config_path, :yellow)
        File.write(File.join(destination_root, config_path), original_content)
        reason_text = reason ? " #{reason};" : ""
        GeneratorMessages.add_warning(
          "Reverted partial RSC manifest helper setup in #{config_path};#{reason_text} please add " \
          "addRSCManifestPlugin and clientReferences manually."
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
        unless rsc_manifest_helper_invocation?(content, "serverWebpackConfig")
          missing << "addRSCManifestPlugin in serverWebpackConfig.js"
        end
        unless rsc_manifest_helper_import?(content)
          missing << "addRSCManifestPlugin helper import in serverWebpackConfig.js"
        end
        unless rsc_client_references_configured?(content, "serverWebpackConfig", is_server: true)
          missing << "generated scoped clientReferences in serverWebpackConfig.js"
        end
        unless content.match?(server_configure_with_rsc_bundle_pattern)
          missing << "rscBundle parameter in serverWebpackConfig.js"
        end
        missing
      end

      def check_rsc_client_config
        path = File.join(destination_root, destination_config_path("config/webpack/clientWebpackConfig.js"))
        return [] unless File.exist?(path)

        content = File.read(path)
        missing = []
        unless rsc_manifest_helper_invocation?(content, "clientConfig")
          missing << "addRSCManifestPlugin in clientWebpackConfig.js"
        end
        unless rsc_manifest_helper_import?(content)
          missing << "addRSCManifestPlugin helper import in clientWebpackConfig.js"
        end
        unless rsc_client_references_configured?(content, "clientConfig", is_server: false)
          missing << "generated scoped clientReferences in clientWebpackConfig.js"
        end
        missing
      end

      def check_rsc_scob_config
        scob_path = resolve_server_client_or_both_path
        return [] unless scob_path

        content = File.read(File.join(destination_root, scob_path))
        content.include?("rscWebpackConfig") ? [] : ["rscWebpackConfig in ServerClientOrBoth.js"]
      end
    end
  end
end
