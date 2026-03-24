# frozen_string_literal: true

require "rails/generators"
require "tempfile"
require "fileutils"
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

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def swap_base_gem_for_pro_in_gemfile
        gemfile_path = File.join(destination_root, "Gemfile")
        unless File.exist?(gemfile_path)
          add_missing_gemfile_warning(gemfile_path)
          return
        end

        gemfile_content = File.read(gemfile_path)
        pro_gem_pattern = /^\s*gem(?:\s+|\(\s*)["']react_on_rails_pro["']/
        base_gem_pattern = /^(\s*)gem(?:\s+|\(\s*)(["'])react_on_rails\2(?=\s*(?:,|\)|#|$))/

        has_pro_gem_entry = gemfile_content.match?(pro_gem_pattern)
        gemfile_lines = gemfile_content.lines
        updated_lines = []
        pro_entry_added = has_pro_gem_entry
        line_index = 0

        while line_index < gemfile_lines.length
          line = gemfile_lines[line_index]
          multiline_parenthesized_match = match_multiline_parenthesized_base_gem(gemfile_lines, line_index)

          if multiline_parenthesized_match
            unless pro_entry_added
              indentation = multiline_parenthesized_match[:indentation]
              quote = multiline_parenthesized_match[:quote]
              updated_lines << "#{indentation}gem #{quote}react_on_rails_pro#{quote}, " \
                               "#{quote}~> #{recommended_pro_gem_version}#{quote}\n"
              pro_entry_added = true
            end

            line_index = multiline_parenthesized_match[:next_index]
            next
          end

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
          while line_index < gemfile_lines.length &&
                line_continues_with_comma?(current_line) &&
                gem_declaration_continues_on_next_line?(gemfile_lines[line_index])
            next_line = gemfile_lines[line_index]
            current_line = next_line unless comment_or_blank_line?(next_line)
            line_index += 1
          end
        end

        updated_content = updated_lines.join
        return if updated_content == gemfile_content

        if has_pro_gem_entry
          say "ℹ️  Existing react_on_rails_pro Gemfile entry detected; preserving current version constraint", :yellow
        end

        if options[:pretend]
          say_status :pretend, "Would replace react_on_rails with react_on_rails_pro in Gemfile", :yellow
          return
        end

        atomic_write_file(gemfile_path, updated_content)
        say "✅ Replaced react_on_rails with react_on_rails_pro in Gemfile", :green
        bundle_install_after_gem_swap
      rescue StandardError => e
        add_gemfile_update_warning(gemfile_path, e)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      def atomic_write_file(path, content)
        temp_file = Tempfile.new([File.basename(path), ".tmp"], File.dirname(path))
        temp_path = temp_file.path

        temp_file.write(content)
        temp_file.flush
        temp_file.fsync
        temp_file.close
        FileUtils.mv(temp_path, path)
        temp_path = nil
      ensure
        temp_file&.close unless temp_file&.closed?
        File.delete(temp_path) if temp_path && File.exist?(temp_path)
      end

      def bundle_install_after_gem_swap
        if options[:pretend]
          say_status :pretend, "Skipping bundle install in --pretend mode", :yellow
          return
        end

        gemfile_path = File.join(destination_root, "Gemfile")
        say "📦 Running bundle install after Gemfile update...", :yellow
        install_status = Bundler.with_unbundled_env do
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
          ⚠️  Could not run automatic bundle install: #{e.class}: #{e.message}

          Please run manually:
            bundle install
        MSG
      end

      def update_imports_to_pro_package
        files = js_files_for_import_update
        updated_files = 0

        files.each do |file|
          content = File.read(file)
          updated_content = rewrite_react_on_rails_module_specifiers(content)
          next if updated_content == content

          if options[:pretend]
            say_status :pretend, "Would update react-on-rails imports in #{file}", :yellow
            updated_files += 1
            next
          end

          File.write(file, updated_content)
          updated_files += 1
        rescue StandardError => e
          GeneratorMessages.add_warning(<<~MSG.strip)
            ⚠️  Could not update imports in #{file}: #{e.class}: #{e.message}

            Please update react-on-rails imports to react-on-rails-pro manually.
          MSG
        end

        if updated_files.zero?
          say "ℹ️  No react-on-rails imports required updates", :yellow
          return
        end

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
        static_import_specifier_pattern = %r{
          (?<prefix>
            \A\s*(?:/\*.*?\*/\s*)?import(?:\s+type)?\s+.*?\s+from\s+|
            \A\s*[\w\}\],\*\$\s]+\s+from\s+
          )
          (?<quote>["'])
          react-on-rails(?!-pro)
          (?=(?:["']|/))
        }x

        dynamic_or_require_specifier_pattern = %r{
          (?<prefix>
            (?<!["'`])\bimport\s*\(\s*(?:/\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)*|
            (?<!["'`])\brequire\s*\(\s*
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
          rewritten_line = line.gsub(static_import_specifier_pattern) do
            "#{Regexp.last_match[:prefix]}#{Regexp.last_match[:quote]}react-on-rails-pro"
          end

          rewritten_line = rewritten_line.gsub(dynamic_or_require_specifier_pattern) do
            "#{Regexp.last_match[:prefix]}#{Regexp.last_match[:quote]}react-on-rails-pro"
          end

          rewritten_line.gsub(side_effect_import_pattern) do
            "#{Regexp.last_match[:prefix]}#{Regexp.last_match[:quote]}react-on-rails-pro"
          end
        end
      end

      def line_continues_with_comma?(line)
        line_without_comment = line.sub(/\s*#.*$/, "").rstrip
        line_without_comment.end_with?(",")
      end

      def gem_declaration_continues_on_next_line?(line)
        stripped = line.lstrip
        return true if stripped.empty?

        !stripped.match?(/\Agem(?:\s|\()/)
      end

      def comment_or_blank_line?(line)
        stripped = line.lstrip
        stripped.empty? || stripped.start_with?("#")
      end

      def add_missing_gemfile_warning(gemfile_path)
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Could not find Gemfile at #{gemfile_path}.

          Skipping automatic react_on_rails -> react_on_rails_pro Gemfile swap.
          Please update your Gemfile manually if your app uses a non-standard Gemfile path.
        MSG
      end

      def add_gemfile_update_warning(gemfile_path, error)
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Could not update Gemfile at #{gemfile_path}: #{error.class}: #{error.message}

          Skipping automatic react_on_rails -> react_on_rails_pro Gemfile swap.
          Please update your Gemfile manually.
        MSG
      end

      # rubocop:disable Metrics/AbcSize, Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/MethodLength
      # rubocop:disable Metrics/PerceivedComplexity, Style/ExplicitBlockArgument
      def rewrite_non_comment_lines(content)
        in_block_comment = false
        pending_multiline_module_call_depth = 0
        pending_multiline_static_import_specifier = false

        content.lines.map do |line|
          stripped = line.lstrip

          if in_block_comment
            if stripped.include?("*/")
              in_block_comment = false
              rewritten_line, pending_multiline_module_call_depth, pending_multiline_static_import_specifier =
                rewrite_line_after_block_comment_close(
                  line,
                  pending_multiline_module_call_depth,
                  pending_multiline_static_import_specifier
                ) { |line_fragment| yield line_fragment }
              in_block_comment = true if unclosed_block_comment_starts?(rewritten_line)
              rewritten_line
            else
              line
            end
          elsif stripped.start_with?("/*")
            if stripped.include?("*/")
              rewritten_line = yield line
              rewritten_line, pending_multiline_static_import_specifier =
                update_pending_multiline_static_import_tracking(
                  rewritten_line,
                  pending_multiline_static_import_specifier
                )
              rewritten_line, pending_multiline_module_call_depth =
                update_pending_multiline_module_call_tracking(rewritten_line, pending_multiline_module_call_depth)
              in_block_comment = true if unclosed_block_comment_starts?(line)
              rewritten_line
            else
              in_block_comment = true
              line
            end
          elsif stripped.start_with?("//") || stripped.match?(/\A\*\s/)
            line
          else
            rewritten_line = yield line
            rewritten_line, pending_multiline_static_import_specifier =
              update_pending_multiline_static_import_tracking(
                rewritten_line,
                pending_multiline_static_import_specifier
              )
            rewritten_line, pending_multiline_module_call_depth =
              update_pending_multiline_module_call_tracking(rewritten_line, pending_multiline_module_call_depth)
            in_block_comment = true if unclosed_block_comment_starts?(line)
            rewritten_line
          end
        end.join
      end
      # rubocop:enable Metrics/PerceivedComplexity, Style/ExplicitBlockArgument
      # rubocop:enable Metrics/AbcSize, Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/MethodLength

      def unclosed_block_comment_starts?(line)
        line_without_inline_comment = line_without_string_literals_and_inline_comments(line)
        opening_index = line_without_inline_comment.index("/*")
        return false unless opening_index

        line_without_inline_comment.index("*/", opening_index + 2).nil?
      end

      def starts_pending_multiline_module_call?(line)
        line_without_literals = line_without_string_literals_and_inline_comments(line)
        return false unless line_without_literals.match?(/(?<![\w$])(?:import|require)\s*\(/)

        !line.match?(%r{(?<!["'`])\b(?:import|require)\s*\(\s*(?:/\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)*["']})
      end

      def rewrite_pending_module_specifier(line)
        line.sub(%r{(?<quote>["'])react-on-rails(?!-pro)(?=(?:["']|/))}) do
          "#{Regexp.last_match[:quote]}react-on-rails-pro"
        end
      end

      def update_pending_multiline_module_call_tracking(line, pending_depth)
        if pending_depth.positive?
          rewritten_line = rewrite_pending_module_specifier(line)
          updated_depth = pending_depth + module_call_parenthesis_delta(rewritten_line)
          updated_depth = 0 if updated_depth <= 0
          [rewritten_line, updated_depth]
        elsif starts_pending_multiline_module_call?(line)
          initial_depth = module_call_parenthesis_delta(line, from_module_call_start: true)
          [line, initial_depth.positive? ? initial_depth : 0]
        else
          [line, pending_depth]
        end
      end

      def update_pending_multiline_static_import_tracking(line, pending_multiline_static_import_specifier)
        rewritten_line = line
        if pending_multiline_static_import_specifier
          rewritten_line = rewrite_pending_module_specifier(rewritten_line)
          pending_multiline_static_import_specifier = false
        end

        if starts_pending_multiline_static_import_specifier?(rewritten_line)
          pending_multiline_static_import_specifier = true
        end

        [rewritten_line, pending_multiline_static_import_specifier]
      end

      def starts_pending_multiline_static_import_specifier?(line)
        line_without_literals = line_without_string_literals_and_inline_comments(line)
        return false unless line_without_literals.match?(
          /\A\s*(?:import(?:\s+type)?\b.*\bfrom|import|[\w\}\],\*\$\s]+\s+from)\s*\z/
        )
        return false if line.match?(%r{\bfrom\s*(?:/\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)*["']})
        return false if line.match?(%r{\A\s*import\s*(?:/\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)*["']})

        true
      end

      def module_call_parenthesis_delta(line, from_module_call_start: false)
        line_without_literals = line_without_string_literals_and_inline_comments(line)
        line_to_measure = if from_module_call_start
                            line_without_literals.sub(/\A.*?(?<![\w$])(?:import|require)\s*\(/, "(")
                          else
                            line_without_literals
                          end

        line_to_measure.count("(") - line_to_measure.count(")")
      end

      def line_without_string_literals_and_inline_comments(line)
        line_without_strings = line.gsub(
          /"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`/,
          ""
        )
        line_without_strings.sub(%r{//.*$}, "")
      end

      def rewrite_line_after_block_comment_close(line, pending_depth, pending_multiline_static_import_specifier)
        closing_index = line.index("*/")
        return [line, pending_depth, pending_multiline_static_import_specifier] unless closing_index
        return [line, pending_depth, pending_multiline_static_import_specifier] if closing_index >= line.length - 2

        comment_prefix = line[0, closing_index + 2]
        line_fragment = line[(closing_index + 2)..]
        rewritten_fragment = yield line_fragment
        rewritten_fragment, pending_multiline_static_import_specifier =
          update_pending_multiline_static_import_tracking(rewritten_fragment, pending_multiline_static_import_specifier)
        rewritten_fragment, pending_depth =
          update_pending_multiline_module_call_tracking(rewritten_fragment, pending_depth)
        ["#{comment_prefix}#{rewritten_fragment}", pending_depth, pending_multiline_static_import_specifier]
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def match_multiline_parenthesized_base_gem(lines, start_index)
        start_line = lines[start_index]
        start_match = start_line.match(/^(\s*)gem\s*\(\s*(?:#.*)?$/)
        return nil unless start_match

        line_index = start_index + 1
        found_base_gem_name = false
        base_gem_quote = nil

        while line_index < lines.length
          line = lines[line_index]

          if line.include?(")")
            return nil unless found_base_gem_name

            return { indentation: start_match[1], quote: base_gem_quote, next_index: line_index + 1 }
          end

          if comment_or_blank_line?(line)
            line_index += 1
            next
          end

          if !found_base_gem_name &&
             (gem_name_match = line.match(/^\s*(["'])react_on_rails\1(?=\s*(?:,|\)|#|$))/))
            found_base_gem_name = true
            base_gem_quote = gem_name_match[1]
            line_index += 1
            next
          end

          return nil unless found_base_gem_name

          line_index += 1
        end

        nil
      end
      # rubocop:enable Metrics/CyclomaticComplexity

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
