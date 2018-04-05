# frozen_string_literal: true

require "erb"

module ReactOnRails
  class LocalesToJs
    def initialize
      return if i18n_dir.nil?
      return unless obsolete?
      @translations, @defaults = generate_translations
      convert
    end

    private

    def obsolete?
      return true if exist_js_files.empty?
      js_files_are_outdated
    end

    def exist_js_files
      @exist_js_files ||= js_files.select(&File.method(:exist?))
    end

    def js_files_are_outdated
      latest_yml = locale_files.map(&File.method(:mtime)).max
      earliest_js = exist_js_files.map(&File.method(:mtime)).min
      latest_yml > earliest_js
    end

    def js_file_names
      %w[translations default]
    end

    def js_files
      @js_files ||= js_file_names.map { |n| js_file(n) }
    end

    def js_file(name)
      "#{i18n_dir}/#{name}.js"
    end

    def locale_files
      @locale_files ||= begin
        if i18n_yml_dir.present?
          Dir["#{i18n_yml_dir}/**/*.yml"]
        else
          ReactOnRails::Utils.truthy_presence(
            Rails.application && Rails.application.config.i18n.load_path
          ).presence
        end
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
      js_file_names.each do |name|
        template = send("template_#{name}")
        path = js_file(name)
        generate_js_file(template, path)
      end
    end

    def generate_js_file(template, path)
      result = ERB.new(template).result()
      File.open(path, "w") do |f|
        f.write(result)
      end
    end

    def generate_translations
      translations = {}
      defaults = {}
      locale_files.each do |f|
        translation = YAML.safe_load(File.open(f))
        key = translation.keys[0]
        val = flatten(translation[key])
        translations = translations.deep_merge(key => val)
        defaults = defaults.deep_merge(flatten_defaults(val)) if key == default_locale
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
          flatten(v).map { |hk, hv| h["#{k}.#{hk}".to_sym] = hv }
        else
          h[k] = v.gsub("%{", "{")
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

        const defaultLocale = \'#{default_locale}\';

        const defaultMessages = defineMessages(#{@defaults});

        export { defaultMessages, defaultLocale };
      JS
    end
  end
end
