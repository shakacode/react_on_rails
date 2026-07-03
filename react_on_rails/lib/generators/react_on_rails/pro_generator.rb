# frozen_string_literal: true

require "rails/generators"
require "tempfile"
require "fileutils"
require_relative "generator_helper"
require_relative "generator_messages"
require_relative "js_dependency_manager"
require_relative "pro_setup"
require "react_on_rails/pro_migration"

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
        original_gemfile_content_before_prerequisites = read_current_gemfile_content

        # When invoked by install_generator, skip prerequisites (parent already validated)
        if options[:invoked_by_install] || prerequisites_met?
          return unless options[:invoked_by_install] || swap_base_gem_for_pro_in_gemfile(
            original_gemfile_content_for_rollback: original_gemfile_content_before_prerequisites
          )

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

      def read_current_gemfile_content
        gemfile_path = File.join(destination_root, "Gemfile")
        return unless File.exist?(gemfile_path)

        File.read(gemfile_path)
      rescue StandardError
        nil
      end

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
      def swap_base_gem_for_pro_in_gemfile(original_gemfile_content_for_rollback: nil)
        gemfile_path = File.join(destination_root, "Gemfile")
        unless File.exist?(gemfile_path)
          add_missing_gemfile_warning(gemfile_path)
          return false
        end

        gemfile_content = File.read(gemfile_path)
        has_pro_gem_entry = ReactOnRails::ProMigration.pro_gem_entry?(gemfile_content)
        had_pro_gem_entry_before_prerequisites =
          original_gemfile_content_for_rollback &&
          ReactOnRails::ProMigration.pro_gem_entry?(original_gemfile_content_for_rollback)
        gemfile_lines = gemfile_content.lines
        updated_lines = []
        base_gem_entry_found = false
        base_gem_entries_removed = false
        line_index = 0

        while line_index < gemfile_lines.length
          line = gemfile_lines[line_index]
          base_gem_declaration = ReactOnRails::ProMigration.base_gem_declaration_at(gemfile_lines, line_index)

          unless base_gem_declaration
            updated_lines << line
            line_index += 1
            next
          end

          base_gem_entry_found = true

          if has_pro_gem_entry
            base_gem_entries_removed = true
          else
            updated_lines << build_pro_gem_replacement_line(
              indentation: base_gem_declaration[:indentation],
              quote: base_gem_declaration[:quote],
              suffix: base_gem_declaration[:trailing_suffix],
              parenthesized_gem_call: base_gem_declaration[:parenthesized_gem_call]
            )
          end

          line_index = base_gem_declaration[:next_index]
        end

        updated_content = updated_lines.join
        if updated_content == gemfile_content
          unless base_gem_entry_found || had_pro_gem_entry_before_prerequisites
            rollback_message = rollback_gemfile_after_failed_swap_precondition(
              gemfile_path:,
              original_gemfile_content: original_gemfile_content_for_rollback,
              current_gemfile_content: gemfile_content
            )
            add_missing_react_on_rails_gem_warning(rollback_message:)
            return false
          end

          return true
        end

        if options[:pretend]
          say_status :pretend, "Would replace react_on_rails with react_on_rails_pro in Gemfile", :yellow
          return true
        end

        original_gemfile_content = original_gemfile_content_for_rollback || gemfile_content
        atomic_write_file(gemfile_path, updated_content)
        if base_gem_entries_removed
          say(
            "ℹ️  Existing react_on_rails_pro Gemfile entry detected; " \
            "removed the now-stale react_on_rails entries",
            :yellow
          )
        else
          say "✅ Replaced react_on_rails with react_on_rails_pro in Gemfile", :green
        end
        bundle_install_after_gem_swap(
          gemfile_path:,
          original_gemfile_content:
        )
      rescue StandardError => e
        add_gemfile_update_warning(gemfile_path, e)
        false
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      def atomic_write_file(path, content)
        original_mode = File.file?(path) ? File.stat(path).mode & 0o777 : nil
        temp_file = Tempfile.new([File.basename(path), ".tmp"], File.dirname(path))
        temp_path = temp_file.path

        temp_file.write(content)
        temp_file.flush
        temp_file.fsync
        temp_file.close
        FileUtils.mv(temp_path, path)
        File.chmod(original_mode, path) if original_mode
        temp_path = nil
      ensure
        temp_file&.close unless temp_file&.closed?
        File.delete(temp_path) if temp_path && File.exist?(temp_path)
      end

      def bundle_install_after_gem_swap(
        gemfile_path: File.join(destination_root, "Gemfile"),
        original_gemfile_content: nil
      )
        if options[:pretend]
          say_status :pretend, "Skipping bundle install in --pretend mode", :yellow
          return true
        end

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

        return true if install_status&.success?

        rollback_message = rollback_gemfile_after_failed_bundle_install(
          gemfile_path:,
          original_gemfile_content:
        )

        add_bundle_install_failure_warning(install_status, rollback_message)
        false
      rescue StandardError => e
        rollback_message = rollback_gemfile_after_failed_bundle_install(
          gemfile_path:,
          original_gemfile_content:
        )

        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Could not run automatic bundle install: #{e.class}: #{e.message}

          #{rollback_message}
          Please run manually:
            bundle install
        MSG
        false
      end

      def add_bundle_install_failure_warning(install_status, rollback_message)
        failure_header = if install_status.nil?
                           "⚠️  Automatic bundle install timed out after #{ProSetup::AUTO_INSTALL_TIMEOUT} seconds."
                         else
                           "⚠️  Automatic bundle install failed after swapping Gemfile entries."
                         end

        GeneratorMessages.add_warning(<<~MSG.strip)
          #{failure_header}

          #{rollback_message}
          Please run manually:
            bundle install
        MSG
      end

      def rollback_gemfile_after_failed_bundle_install(gemfile_path:, original_gemfile_content:)
        return "Gemfile remains updated with react_on_rails_pro." unless original_gemfile_content

        atomic_write_file(gemfile_path, original_gemfile_content)
        "Gemfile has been reverted to its previous react_on_rails entry."
      rescue StandardError => e
        "Could not revert Gemfile automatically (#{e.class}: #{e.message}). " \
        "Gemfile remains updated with react_on_rails_pro."
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

          atomic_write_file(file, updated_content)
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
        js_extensions = ReactOnRails::ProMigration::JS_SOURCE_EXTENSIONS.join(",")
        ReactOnRails::ProMigration::JS_SOURCE_ROOTS.flat_map do |root|
          root_path = File.join(destination_root, root)
          next [] unless Dir.exist?(root_path)

          Dir.glob(File.join(root_path, "**", "*.{#{js_extensions}}"))
             .reject { |f| f.include?("/node_modules/") }
        end.uniq
      end

      STATIC_IMPORT_SPECIFIER_PATTERN = %r{
        (?<prefix>
          \A\s*(?:/\*.*?\*/\s*)?(?:import|export)(?:\s+type)?\s+.*?\s+from\s+|
          \A\s*[\w\}\],\*\$\s]+\s+from\s+
        )
        (?<quote>["'])
        react-on-rails(?!-pro)
        (?=(?:["']|/))
      }x

      DYNAMIC_OR_REQUIRE_SPECIFIER_PATTERN = %r{
        (?<prefix>
          (?<!["'`])\bimport\s*\(\s*(?:/\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)*|
          (?<!["'`])\brequire\s*\(\s*(?:/\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)*
        )
        (?<quote>["'])
        react-on-rails(?!-pro)
        (?=(?:["']|/))
      }x

      SIDE_EFFECT_IMPORT_PATTERN = %r{
        \A(?<prefix>\s*(?:/\*.*?\*/\s*)*import\s+)
        (?<quote>["'])
        react-on-rails(?!-pro)
        (?=(?:["']|/))
      }x

      # Explicit allowlist of documented Jest/Vitest APIs whose first argument is a module specifier.
      # Keep destructive rewrites narrow; the doctor can warn more broadly if needed.
      JEST_MODULE_SPECIFIER_METHOD_PATTERN = ReactOnRails::ProMigration::JEST_MODULE_SPECIFIER_METHOD_PATTERN
      VITEST_MODULE_SPECIFIER_METHOD_PATTERN = ReactOnRails::ProMigration::VITEST_MODULE_SPECIFIER_METHOD_PATTERN

      MOCK_CALL_PATTERN = %r{
        (?<prefix>
          (?<!["'`])\b(?:
            jest\.(?:#{JEST_MODULE_SPECIFIER_METHOD_PATTERN})
            |
            vi\.(?:#{VITEST_MODULE_SPECIFIER_METHOD_PATTERN})
          )
          \s*
          (?:<[^;\n]*>\s*)?
          \s*\(\s*
        )
        (?<quote>["'])
        react-on-rails(?!-pro)
        (?=(?:["']|/))
      }x

      DECLARE_MODULE_PATTERN = %r{
        \A(?<prefix>\s*(?:export\s+)?declare\s+module\s+)
        (?<quote>["'])
        react-on-rails(?!-pro)
        (?=(?:["']|/))
      }x

      BASE_PACKAGE_REWRITE_PATTERNS = [
        STATIC_IMPORT_SPECIFIER_PATTERN,
        DYNAMIC_OR_REQUIRE_SPECIFIER_PATTERN,
        SIDE_EFFECT_IMPORT_PATTERN,
        MOCK_CALL_PATTERN,
        DECLARE_MODULE_PATTERN
      ].freeze
      GEMFILE_STRING_DELIMITERS = ["'", '"', "`"].freeze

      def rewrite_react_on_rails_module_specifiers(content)
        rewrite_non_comment_lines(content) do |line|
          rewrite_outside_inline_template_literals(line) do |line_without_templates|
            rewrite_base_package_patterns(line_without_templates)
          end
        end
      end

      def rewrite_base_package_patterns(line)
        BASE_PACKAGE_REWRITE_PATTERNS.reduce(line) do |result, pattern|
          result.gsub(pattern) do
            "#{Regexp.last_match[:prefix]}#{Regexp.last_match[:quote]}react-on-rails-pro"
          end
        end
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

      def add_missing_react_on_rails_gem_warning(rollback_message: nil)
        rollback_section = rollback_message ? "\n\n#{rollback_message}" : ""
        GeneratorMessages.add_warning(<<~MSG.strip)
          ⚠️  Could not find react_on_rails or react_on_rails_pro in Gemfile.

          If this app declares the gem in a .gemspec or another included file,
          please update it manually:
            replace react_on_rails with react_on_rails_pro
          #{rollback_section}
        MSG
      end

      def rollback_gemfile_after_failed_swap_precondition(
        gemfile_path: File.join(destination_root, "Gemfile"),
        original_gemfile_content: nil,
        current_gemfile_content: nil
      )
        return nil unless original_gemfile_content
        return nil if original_gemfile_content == current_gemfile_content

        atomic_write_file(gemfile_path, original_gemfile_content)
        "Gemfile has been reverted to its pre-generator state."
      rescue StandardError => e
        "Could not revert Gemfile automatically (#{e.class}: #{e.message}). " \
        "Gemfile remains updated with react_on_rails_pro."
      end

      # rubocop:disable Metrics/AbcSize, Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/MethodLength
      # rubocop:disable Metrics/PerceivedComplexity
      def rewrite_non_comment_lines(content, &block)
        in_block_comment = false
        in_multiline_template_literal = false
        pending_multiline_module_call_depth = 0
        pending_multiline_static_import_specifier = false

        content.lines.map do |line|
          stripped = line.lstrip
          line_for_template_literal_state = line_for_template_literal_tracking(line, in_block_comment:)
          line_contains_unescaped_backtick =
            line_has_unescaped_backtick?(line, line_for_tracking: line_for_template_literal_state)

          if in_multiline_template_literal || line_contains_unescaped_backtick
            line_for_state_update = in_multiline_template_literal ? line : line_for_template_literal_state
            updated_template_literal_state =
              update_multiline_template_literal_state(in_multiline_template_literal, line_for_state_update)

            if in_multiline_template_literal && !updated_template_literal_state
              rewritten_line, pending_multiline_module_call_depth, pending_multiline_static_import_specifier =
                rewrite_line_after_template_literal_close(
                  line,
                  pending_multiline_module_call_depth,
                  pending_multiline_static_import_specifier, &block
                )
              in_multiline_template_literal = updated_template_literal_state
              in_block_comment = unclosed_block_comment_starts?(rewritten_line)
              rewritten_line
            elsif line_contains_unescaped_backtick
              rewritten_line, pending_multiline_module_call_depth, pending_multiline_static_import_specifier =
                rewrite_line_before_template_literal_open(
                  line,
                  pending_multiline_module_call_depth,
                  pending_multiline_static_import_specifier,
                  in_block_comment:, &block
                )
              in_multiline_template_literal = updated_template_literal_state
              in_block_comment = unclosed_block_comment_starts?(rewritten_line)
              rewritten_line
            else
              in_multiline_template_literal = updated_template_literal_state
              line
            end
          elsif in_block_comment
            if stripped.include?("*/")
              in_block_comment = false
              rewritten_line, pending_multiline_module_call_depth, pending_multiline_static_import_specifier =
                rewrite_line_after_block_comment_close(
                  line,
                  pending_multiline_module_call_depth,
                  pending_multiline_static_import_specifier, &block
                )
              in_block_comment = true if unclosed_block_comment_starts?(rewritten_line)
              rewritten_line
            else
              line
            end
          elsif stripped.start_with?("/*")
            if stripped.include?("*/")
              rewritten_line, pending_multiline_module_call_depth, pending_multiline_static_import_specifier =
                rewrite_and_track_line(
                  line,
                  pending_multiline_module_call_depth,
                  pending_multiline_static_import_specifier, &block
                )
              in_block_comment = true if unclosed_block_comment_starts?(rewritten_line)
              rewritten_line
            else
              in_block_comment = true
              line
            end
          elsif stripped.start_with?("//") || stripped.match?(/\A\*\s/)
            line
          else
            rewritten_line, pending_multiline_module_call_depth, pending_multiline_static_import_specifier =
              rewrite_and_track_line(
                line,
                pending_multiline_module_call_depth,
                pending_multiline_static_import_specifier, &block
              )
            in_block_comment = true if unclosed_block_comment_starts?(rewritten_line)
            rewritten_line
          end
        end.join
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/AbcSize, Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/MethodLength

      def unclosed_block_comment_starts?(line)
        line_without_inline_comment = line_without_string_literals_and_inline_comments(line)
        comment_balance = 0
        scan_index = 0

        while scan_index < line_without_inline_comment.length
          next_opening = line_without_inline_comment.index("/*", scan_index)
          next_closing = line_without_inline_comment.index("*/", scan_index)

          break unless next_opening || next_closing

          if next_opening && (!next_closing || next_opening < next_closing)
            comment_balance += 1
            scan_index = next_opening + 2
          else
            comment_balance -= 1 if comment_balance.positive?
            scan_index = next_closing + 2
          end
        end

        comment_balance.positive?
      end

      MODULE_SPECIFIER_CALL_START_PATTERN = /
        (?<![\w$])(?:import|require)\s*\(
        |
        (?<!["'`])\b(?:
          jest\.(?:#{JEST_MODULE_SPECIFIER_METHOD_PATTERN})
          |
          vi\.(?:#{VITEST_MODULE_SPECIFIER_METHOD_PATTERN})
        )
          \s*
          (?:<[^;\n]*>\s*)?
          \s*\(
      /x

      MODULE_SPECIFIER_CALL_WITH_STRING_PATTERN = %r{
        (?<!["'`])\b(?:import|require)\s*\(\s*(?:/\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)*["']
        |
        (?<!["'`])\b(?:
          jest\.(?:#{JEST_MODULE_SPECIFIER_METHOD_PATTERN})
          |
          vi\.(?:#{VITEST_MODULE_SPECIFIER_METHOD_PATTERN})
        )
          \s*
          (?:<[^;\n]*>\s*)?
          \s*\(\s*
          (?:/\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)*
          ["']
      }x

      def starts_pending_multiline_module_call?(line)
        line_without_literals = line_without_string_literals_and_inline_comments(line)
        return false unless line_without_literals.match?(MODULE_SPECIFIER_CALL_START_PATTERN)

        !line.match?(MODULE_SPECIFIER_CALL_WITH_STRING_PATTERN)
      end

      PENDING_MODULE_SPECIFIER_PATTERN = %r{(?<quote>["'])react-on-rails(?!-pro)(?=(?:["']|/))}

      def rewrite_pending_module_specifier(line)
        match = line.match(PENDING_MODULE_SPECIFIER_PATTERN)
        return line unless match

        rewritten_line = line.sub(PENDING_MODULE_SPECIFIER_PATTERN) do
          "#{Regexp.last_match[:quote]}react-on-rails-pro"
        end

        rewrite_statement_suffix_after_pending_module_specifier(rewritten_line, match)
      end

      def rewrite_statement_suffix_after_pending_module_specifier(line, pending_match)
        closing_quote_index = line.index(pending_match[:quote], pending_match.end(0))
        return line unless closing_quote_index

        suffix = line[(closing_quote_index + 1)..].to_s
        separator_match = suffix.match(/\A(?<separator>\s*;\s*)/)
        return line unless separator_match

        suffix_code = suffix[separator_match.end(0)..].to_s
        rewritten_suffix_code = rewrite_base_package_patterns(suffix_code)
        "#{line[0..closing_quote_index]}#{separator_match[:separator]}#{rewritten_suffix_code}"
      end

      # Rewrites one non-comment line (fragment) via the given block, then threads the
      # multiline-static-import and multiline-module-call tracking state through it.
      # Returns [rewritten_line, module_call_depth, static_import_specifier] so callers
      # keep the loop-local state assignment explicit rather than mutating shared state.
      def rewrite_and_track_line(line, pending_depth, pending_multiline_static_import_specifier)
        rewritten_line = yield line
        rewritten_line, pending_multiline_static_import_specifier =
          update_pending_multiline_static_import_tracking(rewritten_line, pending_multiline_static_import_specifier)
        rewritten_line, pending_depth =
          update_pending_multiline_module_call_tracking(rewritten_line, pending_depth)
        [rewritten_line, pending_depth, pending_multiline_static_import_specifier]
      end

      def update_pending_multiline_module_call_tracking(line, pending_depth)
        if pending_depth.positive?
          rewritten_line = rewrite_pending_module_specifier(line)
          updated_depth = pending_depth + module_call_parenthesis_delta(rewritten_line)
          updated_depth = 0 if rewritten_line != line
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
          /\A\s*(?:(?:import|export)(?:\s+type)?\b.*\bfrom|import|export|[\w\}\],\*\$\s]+\s+from)\s*\z/
        )
        return false if line.match?(%r{\bfrom\s*(?:/\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)*["']})
        return false if line.match?(%r{\A\s*import\s*(?:/\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)*["']})

        true
      end

      def module_call_parenthesis_delta(line, from_module_call_start: false)
        line_without_literals = line_without_string_literals_and_inline_comments(line)
        line_to_measure = if from_module_call_start
                            match = line_without_literals.match(MODULE_SPECIFIER_CALL_START_PATTERN)
                            match ? "(#{line_without_literals[match.end(0)..]}" : line_without_literals
                          else
                            line_without_literals
                          end

        line_to_measure.count("(") - line_to_measure.count(")")
      end

      def line_without_string_literals_and_inline_comments(line, strip_ruby_comments: false)
        line_without_strings = line.gsub(
          /"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`/,
          ""
        )
        line_without_comments = line_without_strings.sub(%r{//.*$}, "")
        return line_without_comments unless strip_ruby_comments

        line_without_comments.sub(/\s*#.*$/, "")
      end

      def rewrite_outside_inline_template_literals(line)
        template_placeholders = []
        line_without_inline_templates = line.gsub(/`(?:\\.|[^`\\])*`/) do |template_literal|
          placeholder = "__ROR_TEMPLATE_LITERAL_PLACEHOLDER_#{template_placeholders.length}__"
          template_placeholders << [placeholder, template_literal]
          placeholder
        end

        rewritten_line = yield line_without_inline_templates
        template_placeholders.each do |placeholder, template_literal|
          rewritten_line = rewritten_line.sub(placeholder) { template_literal }
        end
        rewritten_line
      end

      def line_for_template_literal_tracking(line, in_block_comment: false)
        line_without_quoted_literals = line.gsub(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/, "")
        line_for_comment_aware_template_tracking(
          line_without_quoted_literals,
          in_block_comment:
        )
      end

      def line_for_comment_aware_template_tracking(line, in_block_comment:)
        tracked_line = +""
        scan_index = 0

        while scan_index < line.length
          if in_block_comment
            closing_index = line.index("*/", scan_index)
            return tracked_line unless closing_index

            in_block_comment = false
            scan_index = closing_index + 2
          elsif line[scan_index, 2] == "//"
            break
          elsif line[scan_index, 2] == "/*"
            in_block_comment = true
            scan_index += 2
          else
            tracked_line << line[scan_index]
            scan_index += 1
          end
        end

        tracked_line
      end

      def line_has_unescaped_backtick?(line, line_for_tracking: nil)
        line_to_track = line_for_tracking || line_for_template_literal_tracking(line)
        update_multiline_template_literal_state(false, line_to_track)
      end

      def update_multiline_template_literal_state(in_multiline_template_literal, line)
        backticks = line.each_char.with_index.count do |char, index|
          char == "`" && !character_escaped?(line, index)
        end
        return in_multiline_template_literal if backticks.even?

        !in_multiline_template_literal
      end

      def character_escaped?(line, index)
        backslash_count = 0
        scan_index = index - 1

        while scan_index >= 0 && line[scan_index] == "\\"
          backslash_count += 1
          scan_index -= 1
        end

        backslash_count.odd?
      end

      def rewrite_line_after_block_comment_close(line, pending_depth, pending_multiline_static_import_specifier, &)
        closing_index = line.index("*/")
        return [line, pending_depth, pending_multiline_static_import_specifier] unless closing_index
        return [line, pending_depth, pending_multiline_static_import_specifier] if closing_index >= line.length - 2

        comment_prefix = line[0, closing_index + 2]
        line_fragment = line[(closing_index + 2)..]
        rewritten_fragment, pending_depth, pending_multiline_static_import_specifier =
          rewrite_and_track_line(line_fragment, pending_depth, pending_multiline_static_import_specifier, &)
        ["#{comment_prefix}#{rewritten_fragment}", pending_depth, pending_multiline_static_import_specifier]
      end

      def rewrite_line_after_template_literal_close(line, pending_depth, pending_multiline_static_import_specifier,
                                                    &)
        closing_index = first_unescaped_backtick_index(line)
        return [line, pending_depth, pending_multiline_static_import_specifier] unless closing_index
        return [line, pending_depth, pending_multiline_static_import_specifier] if closing_index >= line.length - 1

        template_literal_prefix = line[0, closing_index + 1]
        line_fragment = line[(closing_index + 1)..]
        rewritten_fragment, pending_depth, pending_multiline_static_import_specifier =
          rewrite_and_track_line(line_fragment, pending_depth, pending_multiline_static_import_specifier, &)
        ["#{template_literal_prefix}#{rewritten_fragment}", pending_depth, pending_multiline_static_import_specifier]
      end

      def rewrite_line_before_template_literal_open(
        line,
        pending_depth,
        pending_multiline_static_import_specifier,
        in_block_comment: false,
        &
      )
        opening_index = opening_backtick_index_for_multiline_start(line, in_block_comment:)
        return [line, pending_depth, pending_multiline_static_import_specifier] unless opening_index&.positive?

        line_prefix = line[0, opening_index]
        template_literal_suffix = line[opening_index..]
        rewritten_prefix, pending_depth, pending_multiline_static_import_specifier =
          rewrite_and_track_line(line_prefix, pending_depth, pending_multiline_static_import_specifier, &)
        ["#{rewritten_prefix}#{template_literal_suffix}", pending_depth, pending_multiline_static_import_specifier]
      end

      def first_unescaped_backtick_index(line)
        unescaped_backtick_indexes(line, skip_comments: true).first
      end

      def opening_backtick_index_for_multiline_start(line, in_block_comment: false)
        backtick_indexes = unescaped_backtick_indexes(line, in_block_comment:)
        return nil if backtick_indexes.empty? || backtick_indexes.length.even?

        backtick_indexes.last
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def unescaped_backtick_indexes(line, in_block_comment: false, skip_comments: false)
        quote_state = nil
        backtick_indexes = []

        scan_index = 0
        while scan_index < line.length
          if in_block_comment
            closing_index = line.index("*/", scan_index)
            break unless closing_index

            in_block_comment = false
            scan_index = closing_index + 2
            next
          end

          char = line[scan_index]
          quote_state = next_quote_state(quote_state, char, line, scan_index)
          if quote_state
            scan_index += 1
            next
          end

          unless skip_comments
            break if line[scan_index, 2] == "//"

            if line[scan_index, 2] == "/*"
              in_block_comment = true
              scan_index += 2
              next
            end
          end

          backtick_indexes << scan_index if char == "`" && !character_escaped?(line, scan_index)
          scan_index += 1
        end

        backtick_indexes
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def next_quote_state(current_state, char, line, index)
        if current_state
          return nil if char == current_state && !character_escaped?(line, index)

          return current_state
        end

        return char if ["'", '"'].include?(char)

        nil
      end

      def build_pro_gem_replacement_line(indentation:, quote:, suffix:, parenthesized_gem_call: false)
        normalized_suffix = suffix || "\n"
        normalized_suffix = "#{normalized_suffix}\n" unless normalized_suffix.end_with?("\n")

        has_user_version_pin = normalized_suffix.match?(/\A\s*,\s*(?:#[^\n]*\n\s*)*["']/)
        version_arg = has_user_version_pin ? "" : ", #{quote}#{pro_gem_version_requirement}#{quote}"

        if parenthesized_gem_call
          normalized_suffix = remove_parenthesized_gem_call_closing_parenthesis(normalized_suffix)
        end
        normalized_suffix = "\n" if normalized_suffix.match?(/\A,\s*\n\z/)

        "#{indentation}gem #{quote}react_on_rails_pro#{quote}#{version_arg}#{normalized_suffix}"
      end

      def remove_parenthesized_gem_call_closing_parenthesis(suffix)
        closing_index = parenthesized_gem_call_closing_parenthesis_index(suffix)
        return suffix unless closing_index

        prefix = suffix[0...closing_index]
        rest = suffix[(closing_index + 1)..].to_s
        return "#{prefix.rstrip} #{rest.lstrip}" if closing_parenthesis_line_has_postfix_code?(rest)

        "#{prefix.chomp}#{rest}"
      end

      def closing_parenthesis_line_has_postfix_code?(rest)
        stripped_rest = rest.lstrip
        !stripped_rest.empty? && !stripped_rest.start_with?("#", "\n", "\r")
      end

      # The suffix starts after the gem name but still inside the original `gem(...)` call,
      # so the matching call-closing parenthesis is found by starting at depth 1.
      def parenthesized_gem_call_closing_parenthesis_index(suffix)
        depth = 1
        quote = nil
        scan_index = 0

        while scan_index < suffix.length
          char = suffix[scan_index]

          if quote
            quote = nil if char == quote && !character_escaped?(suffix, scan_index)
          else
            scan_index, depth, quote, closing_index =
              next_parenthesized_gem_suffix_scan_state(suffix, scan_index, depth)
            return closing_index if closing_index
            return nil unless scan_index
          end

          scan_index += 1
        end

        nil
      end

      def next_parenthesized_gem_suffix_scan_state(suffix, scan_index, depth)
        char = suffix[scan_index]
        return [scan_index, depth, char, nil] if GEMFILE_STRING_DELIMITERS.include?(char)
        return [suffix.index("\n", scan_index), depth, nil, nil] if char == "#"
        return [scan_index, depth + 1, nil, nil] if char == "("
        return parenthesized_gem_suffix_closing_state(scan_index, depth) if char == ")"

        [scan_index, depth, nil, nil]
      end

      def parenthesized_gem_suffix_closing_state(scan_index, depth)
        next_depth = depth - 1
        [scan_index, next_depth, nil, next_depth.zero? ? scan_index : nil]
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
