# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"
require_relative "generator_messages"
require_relative "js_dependency_manager"
require_relative "pro_setup"

module ReactOnRails
  module Generators
    # rubocop:disable Metrics/ClassLength
    class ProGenerator < Rails::Generators::Base
      include GeneratorHelper
      include JsDependencyManager
      include ProSetup

      source_root File.expand_path(__dir__)

      def self.usage_path
        File.expand_path("pro/USAGE", __dir__)
      end

      # Hidden option for when invoked from install_generator
      # Skips prerequisite checks and message printing (parent handles both)
      class_option :invoked_by_install,
                   type: :boolean,
                   default: false,
                   hide: true

      def run_generator
        # When invoked by install_generator, skip prerequisites (parent already validated)
        if options[:invoked_by_install] || prerequisites_met?
          swap_base_gem_for_pro_in_gemfile unless options[:invoked_by_install]
          setup_pro
          add_pro_npm_dependencies
          update_imports_to_pro_package unless options[:invoked_by_install]
          print_success_message unless options[:invoked_by_install]
        else
          GeneratorMessages.add_error(<<~MSG.strip)
            🚫 React on Rails Pro generator prerequisites not met!

            Please resolve the issues listed above before continuing.
          MSG
        end
      ensure
        print_generator_messages unless options[:invoked_by_install]
      end

      private

      def prerequisites_met?
        !(missing_base_installation? || missing_pro_gem?(force: true))
      end

      def missing_base_installation?
        return false if base_react_on_rails_installed?

        GeneratorMessages.add_error(<<~MSG.strip)
          🚫 React on Rails is not installed in this application.

          This generator adds Pro features to an existing React on Rails app.
          Please run the base installer first:

            rails g react_on_rails:install

          Then re-run this generator to add Pro features.
        MSG
        true
      end

      def base_react_on_rails_installed?
        File.exist?(File.join(destination_root, "config/initializers/react_on_rails.rb"))
      end

      def add_pro_npm_dependencies
        say "📝 Adding Pro npm dependencies...", :yellow
        add_pro_dependencies
        say "✅ Pro npm dependencies added", :green
      end

      # rubocop:disable Metrics/AbcSize
      def swap_base_gem_for_pro_in_gemfile
        gemfile_path = File.join(destination_root, "Gemfile")
        unless File.exist?(gemfile_path)
          add_missing_gemfile_warning(gemfile_path)
          return
        end

        gemfile_content = File.read(gemfile_path)
        pro_gem_pattern = /^\s*gem\s+["']react_on_rails_pro["']/
        base_gem_pattern = /^(\s*)gem\s+(["'])react_on_rails\2(?=\s*(?:,|#|$))/

        has_pro_gem_entry = gemfile_content.match?(pro_gem_pattern)
        gemfile_lines = gemfile_content.lines
        updated_lines = []
        pro_entry_added = has_pro_gem_entry
        line_index = 0

        while line_index < gemfile_lines.length
          line = gemfile_lines[line_index]
          match = line.match(base_gem_pattern)

          unless match
            updated_lines << line
            line_index += 1
            next
          end

          unless pro_entry_added
            indentation = match[1]
            quote = match[2]
            updated_lines << "#{indentation}gem #{quote}react_on_rails_pro#{quote}, " \
                             "#{quote}~> #{recommended_pro_gem_version}#{quote}\n"
            pro_entry_added = true
          end

          # Consume multiline gem declarations that continue with trailing commas.
          line_index += 1
          current_line = line
          while line_index < gemfile_lines.length && line_continues_with_comma?(current_line)
            current_line = gemfile_lines[line_index]
            line_index += 1
          end
        end

        updated_content = updated_lines.join
        return if updated_content == gemfile_content

        File.write(gemfile_path, updated_content)
        say "✅ Replaced react_on_rails with react_on_rails_pro in Gemfile", :green
        bundle_install_after_gem_swap
      end
      # rubocop:enable Metrics/AbcSize

      def bundle_install_after_gem_swap
        say "📦 Running bundle install after Gemfile update...", :yellow
        install_status = Bundler.with_unbundled_env do
          gemfile_path = File.join(destination_root, "Gemfile")
          pid = Process.spawn(
            { "BUNDLE_GEMFILE" => gemfile_path },
            "bundle",
            "install",
            out: $stdout,
            err: $stderr,
            chdir: destination_root
          )
          wait_for_bundle_process(pid)
        end

        return if install_status&.success?

        if install_status.nil?
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Automatic bundle install timed out after #{ProSetup::AUTO_INSTALL_TIMEOUT} seconds.

            Gemfile has been updated with react_on_rails_pro.
            Please run manually:
              bundle install
          MSG
          return
        end

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Automatic bundle install failed after swapping Gemfile entries.

          Gemfile has been updated with react_on_rails_pro.
          Please run manually:
            bundle install
        MSG
      rescue StandardError => e
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Could not run automatic bundle install: #{e.message}

          Please run manually:
            bundle install
        MSG
      end

      def update_imports_to_pro_package
        files = js_files_for_import_update
        updated_files = files.count do |file|
          content = File.read(file)
          updated_content = rewrite_react_on_rails_module_specifiers(content)
          next false if updated_content == content

          File.write(file, updated_content)
          true
        end

        return if updated_files.zero?

        say "✅ Updated react-on-rails imports in #{updated_files} file(s)", :green
      end

      def js_files_for_import_update
        js_extensions = %w[js jsx ts tsx mjs cjs vue svelte].join(",")
        %w[app/javascript app/frontend frontend javascript client].flat_map do |root|
          root_path = File.join(destination_root, root)
          next [] unless Dir.exist?(root_path)

          Dir.glob(File.join(root_path, "**", "*.{#{js_extensions}}"))
        end.uniq
      end

      def rewrite_react_on_rails_module_specifiers(content)
        module_specifier_pattern = %r{
          (?<prefix>
            \bfrom\s+|
            \bimport\s*\(\s*|
            \brequire\s*\(\s*
          )
          (?<quote>["'])
          react-on-rails(?!-pro)
          (?=(?:["']|/))
        }x

        side_effect_import_pattern = %r{
          \A(?<prefix>\s*import\s+)
          (?<quote>["'])
          react-on-rails(?!-pro)
          (?=(?:["']|/))
        }x

        rewrite_non_comment_lines(content) do |line|
          rewritten_line = line.gsub(module_specifier_pattern) do
            "#{Regexp.last_match[:prefix]}#{Regexp.last_match[:quote]}react-on-rails-pro"
          end

          rewritten_line.gsub(side_effect_import_pattern) do
            "#{Regexp.last_match[:prefix]}#{Regexp.last_match[:quote]}react-on-rails-pro"
          end
        end
      end

      def line_continues_with_comma?(line)
        line.rstrip.match?(/,\s*(?:#.*)?\z/)
      end

      def add_missing_gemfile_warning(gemfile_path)
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Could not find Gemfile at #{gemfile_path}.

          Skipping automatic react_on_rails -> react_on_rails_pro Gemfile swap.
          Please update your Gemfile manually if your app uses a non-standard Gemfile path.
        MSG
      end

      def rewrite_non_comment_lines(content)
        in_block_comment = false

        content.lines.map do |line|
          stripped = line.lstrip

          if in_block_comment
            in_block_comment = false if stripped.include?("*/")
            line
          elsif stripped.start_with?("/*")
            in_block_comment = !stripped.include?("*/")
            line
          elsif stripped.start_with?("//", "*")
            line
          else
            rewritten_line = yield line
            in_block_comment = true if stripped.include?("/*") && !stripped.include?("*/")
            rewritten_line
          end
        end.join
      end

      def print_success_message
        route = if File.exist?(File.join(destination_root, "app/controllers/hello_server_controller.rb"))
                  "hello_server"
                else
                  "hello_world"
                end

        GeneratorMessages.add_info(<<~MSG)
          Next steps:
          1. Set your license: export REACT_ON_RAILS_PRO_LICENSE=your_token
          2. Start the app: bin/dev (or foreman start -f Procfile.dev)
          3. Visit http://localhost:3000/#{route}
          4. The Node Renderer will start on port 3800

          Documentation: https://reactonrails.com/docs/pro/
        MSG
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
