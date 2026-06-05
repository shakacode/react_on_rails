# frozen_string_literal: true

module ReactOnRails
  module Generators
    # rubocop:disable Metrics/ModuleLength
    module ShakapackerPrecompileHookHelper
      SHAKAPACKER_YML_PATH = "config/shakapacker.yml"
      DEFAULT_PRECOMPILE_HOOK_COMMAND = "bin/shakapacker-precompile-hook"
      COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER = /^(\s*)#\s*precompile_hook:\s*~\s*$/
      RAW_PRECOMPILE_HOOK_VALUE = /^\s+precompile_hook:\s*([^#]*?)\s*(?:#.*)?$/
      UNQUOTED_INACTIVE_PRECOMPILE_HOOK_VALUE = /\A(?:|~|null|false|true|yes|no|on|off)\z/i
      class ShakapackerYmlErbError < StandardError; end
      ShakapackerYmlDocument = Struct.new(:sections, :section_index, :anchor_index, keyword_init: true)
      private_constant :SHAKAPACKER_YML_PATH, :DEFAULT_PRECOMPILE_HOOK_COMMAND,
                       :COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER, :RAW_PRECOMPILE_HOOK_VALUE,
                       :UNQUOTED_INACTIVE_PRECOMPILE_HOOK_VALUE,
                       :ShakapackerYmlErbError, :ShakapackerYmlDocument

      private

      def shakapacker_build_command(env:, environment: "production", app_root: shakapacker_hook_app_root)
        hook_command = shakapacker_precompile_hook_command(app_root: app_root, environment: environment)
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

        return unless generated_precompile_hook_will_be_configured?(shakapacker_config_path, environment: environment)

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
      rescue ShakapackerYmlErbError
        # render_shakapacker_yml_erb already warned; materialization fails closed.
        fail_closed_generated_precompile_hook
      rescue StandardError
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

      def fail_closed_generated_precompile_hook
        false
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
          sections: sections,
          section_index: shakapacker_yml_section_index(sections),
          anchor_index: shakapacker_yml_anchor_index(sections)
        )
      end

      def shakapacker_yml_sections(content)
        # Split at top-level YAML mapping keys. Top-level comments and document
        # separators become harmless single-line sections with no recognized name.
        content.each_line.slice_before { |line| line.match?(/^\S/) }.map(&:join)
      end

      def shakapacker_yml_section_index(sections)
        sections.filter_map { |section| (name = shakapacker_yml_section_name(section)) && [name, section] }.to_h
      end

      def shakapacker_yml_anchor_index(sections)
        sections.filter_map do |section|
          match = section.match(/\A[A-Za-z0-9_-]+:\s*&([A-Za-z0-9_-]+)/)
          [match[1], shakapacker_yml_section_name(section)] if match
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
        section.match(/\A([A-Za-z0-9_-]+):(?:\s|$)/)&.[](1)
      end

      def raw_active_precompile_hook_in_section_tree?(section_name, section_index, anchor_index, visited = {})
        raw_precompile_hook_state_in_section_tree(section_name, section_index, anchor_index, visited) == :active
      end

      def raw_precompile_hook_state_in_section_tree(section_name, section_index, anchor_index, visited = {})
        return nil if visited[section_name]

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

          line.match(RAW_PRECOMPILE_HOOK_VALUE)&.[](1)
        end
        return nil if precompile_hook_values.empty?

        raw_value = unquote_shakapacker_yml_scalar(precompile_hook_values.last.strip)
        return :active if raw_value.include?("<%")
        return :active unless raw_value.match?(UNQUOTED_INACTIVE_PRECOMPILE_HOOK_VALUE)

        :inactive
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
        if yaml_safe_load_supports_aliases?
          return YAML.safe_load(rendered_content, permitted_classes: [Symbol], aliases: true)
        end
        return {} if yaml_content_uses_aliases?(rendered_content)

        YAML.safe_load(rendered_content, permitted_classes: [Symbol])
      rescue ArgumentError => e
        parse_shakapacker_yml_after_alias_keyword_error(e, rendered_content)
      rescue ShakapackerYmlErbError
        raise
      rescue ScriptError, StandardError
        {}
      end

      def render_shakapacker_yml_erb(content)
        require "erb"

        # TOPLEVEL_BINDING matches Rails config ERB evaluation closely enough for
        # ENV/Rails constants. The tradeoff is that evaluation uses this
        # process's top-level scope rather than an app-isolated binding, so
        # unavailable app helpers or side effects fail closed and skip writes.
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

      def parse_shakapacker_yml_after_alias_keyword_error(error, content)
        return {} unless yaml_alias_keyword_error?(error)
        return {} if yaml_content_uses_aliases?(content)

        YAML.safe_load(content, permitted_classes: [Symbol])
      end

      def yaml_safe_load_supports_aliases?
        YAML.method(:safe_load).parameters.any? do |type, name|
          type == :keyrest || (type == :key && name == :aliases)
        end
      rescue StandardError
        false
      end

      def yaml_alias_keyword_error?(error)
        error.message.include?("aliases")
      end

      def yaml_content_uses_aliases?(content)
        require "psych"

        yaml_node_uses_aliases?(Psych.parse_stream(content))
      rescue StandardError
        true
      end

      def yaml_node_uses_aliases?(node)
        return false unless node
        return true if node.respond_to?(:anchor) && node.anchor
        return true if defined?(Psych::Nodes::Alias) && node.is_a?(Psych::Nodes::Alias)
        return false unless node.respond_to?(:children)

        node.children.any? { |child| yaml_node_uses_aliases?(child) }
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
