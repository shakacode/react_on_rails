# frozen_string_literal: true

module ReactOnRails
  module Generators
    module ShakapackerPrecompileHookHelper
      SHAKAPACKER_YML_PATH = "config/shakapacker.yml"
      DEFAULT_PRECOMPILE_HOOK_COMMAND = "bin/shakapacker-precompile-hook"
      COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER = /^(\s*)#\s*precompile_hook:\s*~\s*$/
      ERB_PRECOMPILE_HOOK = /^\s+precompile_hook:\s*.*<%/
      private_constant :SHAKAPACKER_YML_PATH, :DEFAULT_PRECOMPILE_HOOK_COMMAND,
                       :COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER, :ERB_PRECOMPILE_HOOK

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
        return false if normalize_precompile_hook(effective_precompile_hook(config, environment))
        return false if environment_effective_raw_erb_precompile_hook?(content, config, environment)
        return false unless content.match?(COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER)

        materialized_content = content.gsub(
          COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER,
          "\\1precompile_hook: '#{DEFAULT_PRECOMPILE_HOOK_COMMAND}'"
        )
        config = parse_shakapacker_yml_content(materialized_content)
        normalize_precompile_hook(effective_precompile_hook(config, environment)) == DEFAULT_PRECOMPILE_HOOK_COMMAND
      rescue StandardError
        false
      end

      def active_precompile_hook_configured?(content)
        config = parse_shakapacker_yml_content(content)
        sections = shakapacker_yml_sections(content)
        section_index = shakapacker_yml_section_index(sections)
        anchor_index = shakapacker_yml_anchor_index(sections)

        # The generator materializes all placeholders at once, so one direct or
        # inherited active hook keeps the whole file under Shakapacker control.
        sections.any? do |section|
          next false unless section.match?(COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER)

          section_effective_active_precompile_hook?(section, config, section_index, anchor_index)
        end
      end

      def shakapacker_yml_sections(content)
        # Split at top-level YAML keys; standalone top-level comments become harmless one-line sections.
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
          raw_erb_precompile_hook_in_section_tree?(section_name, section_index, anchor_index)
      end

      def environment_effective_raw_erb_precompile_hook?(content, config, environment)
        sections = shakapacker_yml_sections(content)
        section_name = shakapacker_config_key?(config, environment) ? environment.to_s : "production"

        raw_erb_precompile_hook_in_section_tree?(
          section_name, shakapacker_yml_section_index(sections), shakapacker_yml_anchor_index(sections)
        )
      end

      def shakapacker_yml_section_name(section)
        section.match(/\A([A-Za-z0-9_-]+):(?:\s|$)/)&.[](1)
      end

      def raw_erb_precompile_hook_in_section_tree?(section_name, section_index, anchor_index, visited = {})
        return false if visited[section_name]

        visited[section_name] = true
        section = section_index[section_name]
        return false unless section
        return true if section.match?(ERB_PRECOMPILE_HOOK)

        shakapacker_yml_section_merge_aliases(section).any? do |anchor_name|
          inherited_section_name = anchor_index[anchor_name]
          inherited_section_name &&
            raw_erb_precompile_hook_in_section_tree?(inherited_section_name, section_index, anchor_index, visited)
        end
      end

      def shakapacker_yml_section_merge_aliases(section)
        section.each_line.grep(/^\s+<<:/).flat_map { |line| line.scan(/\*([A-Za-z0-9_-]+)/).flatten }
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
      rescue StandardError
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
        parse_shakapacker_yml_after_alias_keyword_error(e, rendered_content || content)
      rescue ScriptError, StandardError
        {}
      end

      def render_shakapacker_yml_erb(content)
        require "erb"

        ERB.new(content).result
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
  end
end
