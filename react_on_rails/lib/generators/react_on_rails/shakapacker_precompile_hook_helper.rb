# frozen_string_literal: true

module ReactOnRails
  module Generators
    # rubocop:disable Metrics/ModuleLength
    module ShakapackerPrecompileHookHelper
      SHAKAPACKER_YML_PATH = "config/shakapacker.yml"
      DEFAULT_PRECOMPILE_HOOK_COMMAND = "bin/shakapacker-precompile-hook"
      COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER = /^(\s*)#\s*precompile_hook:\s*~\s*$/
      RAW_PRECOMPILE_HOOK_VALUE = /^\s+precompile_hook:\s*(.*?)\s*$/
      TOP_LEVEL_SECTION_HEADER = /\A([A-Za-z0-9_-]+):(?:\s|$)/
      TOP_LEVEL_SECTION_ANCHOR = /\A[A-Za-z0-9_-]+:\s*&([A-Za-z0-9_-]+)/
      # YAML boolean scalars, including truthy values, are not valid shell commands.
      UNQUOTED_INACTIVE_PRECOMPILE_HOOK_VALUE = /\A(?:|~|null|false|true|yes|no|on|off)\z/i
      SHAKAPACKER_YML_QUOTE_CHARACTERS = ['"', "'"].freeze
      class ShakapackerYmlErbError < StandardError; end
      ShakapackerYmlDocument = Struct.new(:sections, :section_index, :anchor_index, keyword_init: true)
      private_constant :SHAKAPACKER_YML_PATH, :DEFAULT_PRECOMPILE_HOOK_COMMAND,
                       :COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER, :RAW_PRECOMPILE_HOOK_VALUE,
                       :TOP_LEVEL_SECTION_HEADER, :TOP_LEVEL_SECTION_ANCHOR,
                       :UNQUOTED_INACTIVE_PRECOMPILE_HOOK_VALUE, :SHAKAPACKER_YML_QUOTE_CHARACTERS,
                       :ShakapackerYmlErbError, :ShakapackerYmlDocument

      private

      def shakapacker_build_command(env:, environment: "production", app_root: shakapacker_hook_app_root)
        hook_command = shakapacker_precompile_hook_command(app_root:, environment:)
        shakapacker_command = "#{env} bin/shakapacker"
        return shakapacker_command unless hook_command

        "#{env} #{hook_command} && SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true #{shakapacker_command}"
      end

      def shakapacker_precompile_hook_command(environment:, app_root: shakapacker_hook_app_root)
        shakapacker_config_path = File.join(app_root, SHAKAPACKER_YML_PATH)
        return DEFAULT_PRECOMPILE_HOOK_COMMAND unless File.exist?(shakapacker_config_path)

        config = parse_shakapacker_yml(shakapacker_config_path)
        hook_command = normalize_precompile_hook(effective_precompile_hook(config, environment))
        return hook_command if hook_command == DEFAULT_PRECOMPILE_HOOK_COMMAND

        return unless generated_precompile_hook_will_be_configured?(shakapacker_config_path, environment:)

        DEFAULT_PRECOMPILE_HOOK_COMMAND
      end

      def generated_precompile_hook_will_be_configured?(shakapacker_config_path, environment:)
        return false unless shakapacker_supports_precompile_hook?

        content = File.read(shakapacker_config_path)
        config = parse_shakapacker_yml_content(content)
        document = shakapacker_yml_document(content)
        active_hook = normalize_precompile_hook(effective_precompile_hook(config, environment))
        return false if active_hook
        return false if environment_effective_raw_precompile_hook?(document, config, environment)
        return false unless content.match?(COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER)

        materialized_content = content.gsub(
          COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER,
          "\\1precompile_hook: '#{DEFAULT_PRECOMPILE_HOOK_COMMAND}'"
        )
        config = parse_shakapacker_yml_content(materialized_content)
        normalize_precompile_hook(effective_precompile_hook(config, environment)) == DEFAULT_PRECOMPILE_HOOK_COMMAND
      rescue StandardError
        # ERB evaluation failures already warned; materialization fails closed.
        false
      end

      def active_precompile_hook_configured?(content)
        # Parse rendered ERB for effective hook values, but inspect raw YAML
        # sections so conditional ERB hook declarations are still detectable.
        config = parse_shakapacker_yml_content(content)
        document = shakapacker_yml_document(content)

        # configure_precompile_hook_in_shakapacker rewrites every placeholder
        # with one gsub. If any placeholder section already resolves to a direct
        # or inherited active hook, leave the file unchanged rather than
        # partially materializing generated hooks in other sections.
        active_hook_configured = document.sections.any? do |section|
          next false unless section.match?(COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER)

          section_effective_active_precompile_hook?(section, config, document.section_index, document.anchor_index)
        end
        warn_existing_precompile_hook_placeholder_skip if active_hook_configured
        active_hook_configured
      rescue ShakapackerYmlErbError
        true
      end

      def warn_existing_precompile_hook_placeholder_skip
        return unless respond_to?(:say_status, true)

        say_status :warning,
                   "Existing direct or inherited precompile_hook found in a section with a placeholder.",
                   :yellow
        say_status :warning,
                   "Skipping generated precompile_hook placeholder updates; " \
                   "configure remaining sections manually if needed.",
                   :yellow
      end

      def shakapacker_yml_document(content)
        sections = shakapacker_yml_sections(content)
        ShakapackerYmlDocument.new(
          sections:,
          section_index: shakapacker_yml_section_index(sections),
          anchor_index: shakapacker_yml_anchor_index(sections)
        )
      end

      def shakapacker_yml_sections(content)
        # Split at top-level YAML mapping keys and standalone ERB wrapper lines.
        # Top-level comments and document separators become harmless single-line
        # sections with no recognized name.
        content.each_line.slice_before { |line| line.match?(/^\S/) }.map(&:join)
      end

      def shakapacker_yml_section_index(sections)
        sections.filter_map { |section| (name = shakapacker_yml_section_name(section)) && [name, section] }.to_h
      end

      def shakapacker_yml_anchor_index(sections)
        sections.filter_map do |section|
          anchor_name = shakapacker_yml_section_anchor(section)
          [anchor_name, shakapacker_yml_section_name(section)] if anchor_name
        end.to_h
      end

      def section_effective_active_precompile_hook?(section, config, section_index, anchor_index)
        section_name = shakapacker_yml_section_name(section)
        return false unless section_name

        !normalize_precompile_hook(effective_precompile_hook(config, section_name)).nil? ||
          raw_active_precompile_hook_in_section_tree?(section_name, section_index, anchor_index)
      end

      def environment_effective_raw_precompile_hook?(document, config, environment)
        section_name = shakapacker_effective_section_name(document, config, environment)

        # `document` carries prebuilt raw section indexes from the caller.
        raw_active_precompile_hook_in_section_tree?(
          section_name, document.section_index, document.anchor_index
        )
      end

      def shakapacker_effective_section_name(document, config, environment)
        return environment.to_s if shakapacker_config_key?(config, environment)
        return environment.to_s if document.section_index.key?(environment.to_s)

        "production"
      end

      def shakapacker_yml_section_name(section)
        shakapacker_yml_section_header_source(section).match(TOP_LEVEL_SECTION_HEADER)&.[](1)
      end

      def shakapacker_yml_section_anchor(section)
        shakapacker_yml_section_header_source(section).match(TOP_LEVEL_SECTION_ANCHOR)&.[](1)
      end

      def shakapacker_yml_section_header_source(section)
        line = section.each_line.first.to_s.lstrip

        while line.start_with?("<%")
          erb_end = line.index("%>")
          break unless erb_end

          line = line[(erb_end + 2)..].to_s.lstrip
        end

        line
      end

      def raw_active_precompile_hook_in_section_tree?(section_name, section_index, anchor_index, visited = {})
        raw_precompile_hook_state_in_section_tree(section_name, section_index, anchor_index, visited) == :active
      end

      def raw_precompile_hook_state_in_section_tree(section_name, section_index, anchor_index, visited = {})
        return nil if visited[section_name]

        # Mutate this path's cycle state; recursive merge branches receive duped
        # hashes so sibling aliases do not hide one another.
        visited[section_name] = true
        section = section_index[section_name]
        return nil unless section

        local_state = raw_precompile_hook_state(section)
        return local_state if local_state

        shakapacker_yml_section_merge_aliases(section).each do |anchor_name|
          inherited_section_name = anchor_index[anchor_name]
          next unless inherited_section_name

          inherited_state = raw_precompile_hook_state_in_section_tree(
            inherited_section_name, section_index, anchor_index, visited.dup
          )
          return inherited_state if inherited_state
        end

        nil
      end

      def raw_precompile_hook_state(section)
        child_indent = shakapacker_yml_section_child_indent(section)
        return nil unless child_indent

        precompile_hook_values = section.each_line.filter_map do |line|
          next unless shakapacker_yml_section_child_line?(line, child_indent)

          raw_precompile_hook_value(line)
        end
        return nil if precompile_hook_values.empty?

        raw_precompile_hook_value_state(precompile_hook_values.last)
      end

      def raw_precompile_hook_value(line)
        raw_value = line.match(RAW_PRECOMPILE_HOOK_VALUE)&.[](1)
        return nil unless raw_value

        strip_shakapacker_yml_inline_comment(raw_value).strip
      end

      def strip_shakapacker_yml_inline_comment(value)
        value.each_char.with_index do |char, index|
          next unless char == "#"
          next unless shakapacker_yml_inline_comment_start?(value, index)
          next if shakapacker_yml_quoted_at?(value, index)

          return value[0...index].rstrip
        end

        value.rstrip
      end

      def shakapacker_yml_inline_comment_start?(value, index)
        index.zero? || value[index - 1].match?(/\s/)
      end

      def shakapacker_yml_quoted_at?(value, target_index)
        quote = nil
        index = 0

        while index < target_index
          char = value[index]
          if quote
            if shakapacker_yml_escaped_quote?(value, index, quote)
              index += 2
              next
            end
            quote = nil if char == quote
          elsif SHAKAPACKER_YML_QUOTE_CHARACTERS.include?(char)
            quote = char
          end

          index += 1
        end

        !quote.nil?
      end

      def shakapacker_yml_escaped_quote?(value, index, quote)
        (quote == '"' && value[index] == "\\") ||
          (quote == "'" && value[index] == "'" && value[index + 1] == "'")
      end

      def raw_precompile_hook_value_state(raw_value)
        unquoted_value = unquote_shakapacker_yml_scalar(raw_value)
        return :active if unquoted_value.include?("<%")
        return :inactive if unquoted_value.empty?
        return :active if quoted_shakapacker_yml_scalar?(raw_value)
        return :active unless raw_value.match?(UNQUOTED_INACTIVE_PRECOMPILE_HOOK_VALUE)

        :inactive
      end

      def quoted_shakapacker_yml_scalar?(value)
        return true if value.length >= 2 && value.start_with?('"') && value.end_with?('"')
        return true if value.length >= 2 && value.start_with?("'") && value.end_with?("'")

        false
      end

      def unquote_shakapacker_yml_scalar(value)
        return value[1...-1] if value.length >= 2 && value.start_with?('"') && value.end_with?('"')
        return value[1...-1] if value.length >= 2 && value.start_with?("'") && value.end_with?("'")

        value
      end

      def shakapacker_yml_section_child_indent(section)
        section.each_line.drop(1).filter_map do |line|
          next if line.strip.empty? || line.match?(/^\s*#/)

          indent = line[/\A */].length
          indent if indent.positive?
        end.min
      end

      def shakapacker_yml_section_child_line?(line, child_indent)
        line[/\A */].length == child_indent
      end

      def shakapacker_yml_section_merge_aliases(section)
        child_indent = shakapacker_yml_section_child_indent(section)
        return [] unless child_indent

        lines = section.each_line.to_a
        merge_alias_groups = []
        lines.each_with_index do |line, index|
          match = line.match(/^(\s+)<<:\s*(.*)$/)
          next unless match
          next unless match[1].length == child_indent

          aliases = match[2].scan(/\*([A-Za-z0-9_-]+)/).flatten
          aliases.concat(shakapacker_yml_block_merge_aliases(lines[(index + 1)..], match[1].length))
          merge_alias_groups << aliases
        end
        # Later duplicate << keys override earlier ones in the rendered mapping.
        merge_alias_groups.reverse.flatten
      end

      def shakapacker_yml_block_merge_aliases(lines, merge_indent)
        lines.each_with_object([]) do |line, aliases|
          next if line.strip.empty? || line.match?(/^\s*#/)

          break aliases if line[/\A */].length <= merge_indent

          match = line.match(/^\s*-\s+\*([A-Za-z0-9_-]+)/)
          aliases << match[1] if match
        end
      end

      def effective_precompile_hook(config, environment)
        environment_section = shakapacker_config_section(config, environment)
        unless shakapacker_config_key?(config, environment)
          environment_section = shakapacker_config_section(config, "production")
        end

        shakapacker_config_value(environment_section, "precompile_hook")
      end

      def shakapacker_config_section(config, section)
        return {} unless config.respond_to?(:fetch)

        section_config = config.fetch(section, config.fetch(section.to_sym, {}))
        section_config.respond_to?(:key?) ? section_config : {}
      end

      def shakapacker_config_key?(section, key)
        return false unless section.respond_to?(:key?)

        section.key?(key) || section.key?(key.to_sym)
      end

      def shakapacker_config_value(section, key)
        return section[key] if section.key?(key)
        return section[key.to_sym] if section.key?(key.to_sym)

        nil
      end

      def normalize_precompile_hook(hook)
        return nil if hook.nil? || hook == false || hook == true || hook.to_s.empty?

        hook.to_s.strip
      end

      def parse_shakapacker_yml(path)
        parse_shakapacker_yml_content(File.read(path))
      rescue ShakapackerYmlErbError
        # render_shakapacker_yml_erb already warned; file-level parsing stays tolerant.
        empty_shakapacker_yml_config
      rescue StandardError
        {}
      end

      def empty_shakapacker_yml_config
        {}
      end

      def parse_shakapacker_yml_content(content)
        require "yaml"

        rendered_content = render_shakapacker_yml_erb(content)
        YAML.safe_load(rendered_content, permitted_classes: [Symbol], aliases: true)
      rescue ShakapackerYmlErbError
        raise
      rescue ArgumentError => e
        # The gemspec floor is Ruby >= 3.3.0, which bundles Psych >= 5.x, where the
        # `aliases:` keyword is always supported. An ArgumentError here means an
        # unusually old, explicitly pinned Psych (< 3.1) lacks that keyword. Surface
        # this loudly rather than swallowing it into {}, which would silently discard
        # the entire shakapacker.yml and fall back to defaults.
        raise ArgumentError, "Could not parse #{SHAKAPACKER_YML_PATH}: #{e.message}. " \
                             "psych >= 3.1 (bundled with Ruby >= 2.6) is required for YAML alias support."
      rescue ScriptError, StandardError
        {}
      end

      def render_shakapacker_yml_erb(content)
        require "erb"

        # TOPLEVEL_BINDING matches Rails config ERB evaluation closely enough for
        # ENV/Rails constants. ERB can execute side-effectful Ruby here under the
        # developer-invoked trust model Rails config ERB already uses. Missing app
        # helpers or runtime failures fail closed and skip writes.
        ERB.new(content).result(TOPLEVEL_BINDING)
      rescue ScriptError, StandardError => e
        warn_shakapacker_yml_erb_error(e)
        raise ShakapackerYmlErbError, "Could not evaluate ERB in #{SHAKAPACKER_YML_PATH}: #{e.message}"
      end

      def warn_shakapacker_yml_erb_error(error)
        return unless respond_to?(:say_status, true)

        say_status :warning,
                   "Could not evaluate ERB in #{SHAKAPACKER_YML_PATH}: #{error.class}: #{error.message}",
                   :yellow
        say_status :warning,
                   "Skipping generated precompile_hook updates so custom Shakapacker config is not overwritten.",
                   :yellow
      end

      def shakapacker_supports_precompile_hook?
        return true unless defined?(ReactOnRails::PackerUtils)

        ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")
      rescue StandardError
        false
      end

      def shakapacker_hook_app_root
        return destination_root if respond_to?(:destination_root)

        Dir.pwd
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
