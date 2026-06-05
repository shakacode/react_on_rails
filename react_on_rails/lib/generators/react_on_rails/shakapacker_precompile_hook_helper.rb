# frozen_string_literal: true

module ReactOnRails
  module Generators
    module ShakapackerPrecompileHookHelper
      SHAKAPACKER_YML_PATH = "config/shakapacker.yml"
      DEFAULT_PRECOMPILE_HOOK_COMMAND = "bin/shakapacker-precompile-hook"
      COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER = /^(\s*)#\s*precompile_hook:\s*~\s*$/
      # Unquoted YAML null/boolean scalars parse as nil/false/true, so they are inactive unless quoted.
      # The /i flag intentionally covers YAML scalar aliases such as Null, TRUE, No, and OFF.
      ACTIVE_PRECOMPILE_HOOK = /
        ^\s+precompile_hook:\s*
        (?:
          "[^"]+"
          | '[^']+'
          | (?!(?:~|null|true|false|yes|no|on|off)\s*(?:\#|$)) [^#\s][^#\n]*
        )
      /ix
      private_constant :SHAKAPACKER_YML_PATH, :DEFAULT_PRECOMPILE_HOOK_COMMAND,
                       :COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER, :ACTIVE_PRECOMPILE_HOOK

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
        return hook_command if generated_precompile_hook?(hook_command)

        return unless generated_precompile_hook_will_be_configured?(shakapacker_config_path, environment: environment)

        DEFAULT_PRECOMPILE_HOOK_COMMAND
      end

      def generated_precompile_hook_will_be_configured?(shakapacker_config_path, environment:)
        return false unless shakapacker_supports_precompile_hook?

        content = File.read(shakapacker_config_path)
        return false if active_precompile_hook_configured?(content)
        return false unless content.match?(COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER)

        materialized_content = content.gsub(
          COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER,
          "\\1precompile_hook: '#{DEFAULT_PRECOMPILE_HOOK_COMMAND}'"
        )
        config = parse_shakapacker_yml_content(materialized_content)
        generated_precompile_hook?(
          normalize_precompile_hook(effective_precompile_hook(config, environment))
        )
      rescue StandardError
        false
      end

      def active_precompile_hook_configured?(content)
        config = parse_shakapacker_yml_content(content)

        # The generator materializes all placeholders at once, so one direct or
        # inherited active hook keeps the whole file under Shakapacker control.
        shakapacker_yml_sections(content).any? do |section|
          next false unless section.match?(COMMENTED_PRECOMPILE_HOOK_PLACEHOLDER)

          section.match?(ACTIVE_PRECOMPILE_HOOK) || section_inherits_active_precompile_hook?(section, config)
        end
      end

      def shakapacker_yml_sections(content)
        # Split at every top-level YAML key so each environment block is evaluated independently.
        # Standalone top-level comments become harmless one-line sections.
        content.each_line.slice_before { |line| line.match?(/^\S/) }.map(&:join)
      end

      def section_inherits_active_precompile_hook?(section, config)
        section_name = shakapacker_yml_section_name(section)
        return false unless section_name

        !normalize_precompile_hook(effective_precompile_hook(config, section_name)).nil?
      end

      def shakapacker_yml_section_name(section)
        section.match(/\A([A-Za-z0-9_-]+):(?:\s|$)/)&.[](1)
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

      def generated_precompile_hook?(hook_command)
        hook_command == DEFAULT_PRECOMPILE_HOOK_COMMAND
      end

      def parse_shakapacker_yml(path)
        parse_shakapacker_yml_content(File.read(path))
      rescue StandardError
        {}
      end

      def parse_shakapacker_yml_content(content)
        require "yaml"

        return YAML.safe_load(content, permitted_classes: [Symbol], aliases: true) if yaml_safe_load_supports_aliases?
        return {} if yaml_content_uses_aliases?(content)

        YAML.safe_load(content, permitted_classes: [Symbol])
      rescue ArgumentError => e
        return {} if yaml_alias_keyword_error?(e) && yaml_content_uses_aliases?(content)
        return YAML.safe_load(content, permitted_classes: [Symbol]) if yaml_alias_keyword_error?(e)

        {}
      rescue StandardError
        {}
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
