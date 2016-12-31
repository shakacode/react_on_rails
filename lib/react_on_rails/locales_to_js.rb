require "erb"

module ReactOnRails
  class LocalesToJs
    def initialize
      return unless obsolete?
      @translations, @defaults = generate_translations
      convert
    end

    private

    def obsolete?
      @obsolete ||= (latest_file_names - i18n_js_files.map { |f| f.tr("_", ".") }).present?
    end

    def latest_file_names
      files = locale_files + i18n_js_files.map { |f| send("path_#{f}").to_s }
                                          .select { |f| File.exist?(f) }
      files = files.sort_by { |f| File.mtime(f) }
      files.last(2).map { |f| File.basename(f) }
    end

    def convert
      i18n_js_files.each do |f|
        template = send("template_#{f}")
        path = send("path_#{f}")
        create_js_file(template, path)
      end
    end

    def i18n_js_files
      %w(translations_js default_js)
    end

    def create_js_file(template, path)
      result = ERB.new(template).result()
      File.open(path, "w") do |f|
        f.write(result)
      end
    end

    def generate_translations
      translations = {}
      defaults = {}
      locale_files.each do |f|
        translation = YAML.load(File.open(f))
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
          h[k] = v
        end
      end
    end

    def i18n_dir
      @i18n_dir ||= ReactOnRails.configuration.i18n_dir
    end

    def locale_files
      @locale_files ||= Rails.application.config.i18n.load_path
    end

    def default_locale
      @default_locale ||= I18n.default_locale.to_s || "en"
    end

    def path_translations_js
      i18n_dir + "translations.js"
    end

    def path_default_js
      i18n_dir + "default.js"
    end

    def template_translations_js
      <<-JS
export const translations = #{@translations};
      JS
    end

    def template_default_js
      <<-JS
import { defineMessages } from 'react-intl';

const defaultLocale = \'#{default_locale}\';

const defaultMessages = defineMessages(#{@defaults});

export { defaultMessages, defaultLocale };
      JS
    end
  end
end
