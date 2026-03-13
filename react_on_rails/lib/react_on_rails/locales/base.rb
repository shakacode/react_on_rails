# frozen_string_literal: true

require "erb"

module ReactOnRails
  module Locales
    # Compiles locale YAML files into JavaScript or JSON for use with React on Rails i18n.
    #
    # Reads YAML locale files from +config.i18n_yml_dir+ (or Rails i18n load path),
    # generates output files in +config.i18n_dir+, and skips generation when output
    # files are already up-to-date (unless +force+ is true).
    #
    # @param force [Boolean] when true, regenerate even if output files are current
    # @return [ReactOnRails::Locales::ToJs, ReactOnRails::Locales::ToJson] the converter instance
    # @raise [ReactOnRails::Error] if configured directories do not exist
    #
    # @example Basic usage (skips if up-to-date)
    #   ReactOnRails::Locales.compile
    #
    # @example Force regeneration
    #   ReactOnRails::Locales.compile(force: true)
    def self.compile(force: false)
      config = ReactOnRails.configuration
      check_config_directory_exists(
        directory: config.i18n_dir, key_name: "config.i18n_dir",
        remove_if: "not using the React on Rails i18n feature"
      )
      check_config_directory_exists(
        directory: config.i18n_yml_dir, key_name: "config.i18n_yml_dir",
        remove_if: "not using this i18n with React on Rails, or if you want to use all translation files"
      )
      if config.i18n_output_format&.downcase == "js"
        ReactOnRails::Locales::ToJs.new(force: force)
      else
        ReactOnRails::Locales::ToJson.new(force: force)
      end
    end

    def self.check_config_directory_exists(directory:, key_name:, remove_if:)
      return if directory.nil?
      return if Dir.exist?(directory)

      msg = <<~MSG
        Error configuring /config/initializers/react_on_rails.rb: invalid value for `#{key_name}`.
        Directory does not exist: #{directory}. Set to value to nil or comment it
        out if #{remove_if}.
      MSG
      raise ReactOnRails::Error, msg
    end

    private_class_method :check_config_directory_exists

    class Base
      def initialize(force: false)
        return if i18n_dir.nil?

        if locale_files.empty?
          puts "Warning: No locale files found in #{i18n_yml_dir || 'Rails i18n load path'}"
          return
        end

        if !force && !obsolete?
          puts "Locale files are up to date, skipping generation. " \
               "Use 'rake react_on_rails:locale force=true' to force regeneration."
          return
        end

        @translations, @defaults = generate_translations
        convert
        puts "Generated locale files in #{i18n_dir}"
      end

      private

      def file_format; end

      def obsolete?
        return true if exist_files.length != files.length # Some files missing
        return true if exist_files.empty?

        files_are_outdated
      end

      def exist_files
        @exist_files ||= files.select { |file| File.exist?(file) }
      end

      def files_are_outdated
        latest_yml = locale_files.map { |file| File.mtime(file) }.max
        earliest = exist_files.map { |file| File.mtime(file) }.min
        latest_yml > earliest
      end

      def file_names
        %w[translations default]
      end

      def files
        @files ||= file_names.map { |n| file(n) }
      end

      def file(name)
        "#{i18n_dir}/#{name}.#{file_format}"
      end

      def locale_files
        @locale_files ||= if i18n_yml_dir.present?
                            Dir["#{i18n_yml_dir}/**/*.yml"]
                          else
                            ReactOnRails::Utils.truthy_presence(
                              Rails.application && Rails.application.config.i18n.load_path
                            ).presence
                          end
      end

      def i18n_dir
        @i18n_dir ||= ReactOnRails.configuration.i18n_dir
      end

      def i18n_yml_dir
        @i18n_yml_dir ||= ReactOnRails.configuration.i18n_yml_dir
      end

      def default_locale
        @default_locale ||= I18n.default_locale.to_s || "en"
      end

      def convert
        file_names.each do |name|
          template = send(:"template_#{name}")
          path = file(name)
          generate_file(template, path)
        end
      end

      def generate_file(template, path)
        result = ERB.new(template).result
        File.write(path, result)
      end

      def generate_translations
        translations = {}
        defaults = {}
        locale_files.each do |f|
          safe_load_options = ReactOnRails.configuration.i18n_yml_safe_load_options || {}
          translation = YAML.safe_load(File.open(f), **safe_load_options)
          key = translation.keys[0]
          val = flatten(translation[key])
          translations = translations.deep_merge(key => val)
          defaults = defaults.deep_merge(flatten_defaults(val)) if key == default_locale
        rescue Psych::Exception => e
          raise ReactOnRails::Error, <<~MSG
            Error parsing #{f}: #{e.message}
            Consider fixing unsafe YAML or permitting with config.i18n_yml_safe_load_options
          MSG
        end
        [translations.to_json, defaults.to_json]
      end

      def format(input)
        input.to_s.tr(".", "_").camelize(:lower).to_sym
      end

      def flatten_defaults(val)
        flatten(val).each_with_object({}) do |(k, v), h|
          key = format(k)
          h[key] = { id: k, defaultMessage: v }
        end
      end

      def flatten(translations)
        translations.each_with_object({}) do |(k, v), h|
          if v.is_a? Hash
            flatten(v).map { |hk, hv| h[:"#{k}.#{hk}"] = hv }
          elsif v.is_a?(String)
            h[k] = v.gsub("%{", "{")
          elsif !v.is_a?(Array)
            h[k] = v
          end
        end
      end

      def template_translations
        <<-JS.strip_heredoc
          export const translations = #{@translations};
        JS
      end

      def template_default
        <<-JS.strip_heredoc
          import { defineMessages } from 'react-intl';

          const defaultLocale = '#{default_locale}';

          const defaultMessages = defineMessages(#{@defaults});

          export { defaultMessages, defaultLocale };
        JS
      end
    end
  end
end
