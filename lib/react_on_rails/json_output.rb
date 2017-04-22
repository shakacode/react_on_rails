require 'active_support/core_ext/string/output_safety'

module ReactOnRails
  class JsonOutput
    ESCAPE_REPLACEMENT = { "&" => '\u0026', ">" => '\u003e', "<" => '\u003c', "\u2028" => '\u2028', "\u2029" => '\u2029' }
    ESCAPE_REGEXP = /[\u2028\u2029&><]/u

    def initialize(json)
      @json = json
    end

    def escaped
      return escaped_without_erb_utils if Utils::rails_version_less_than("4.2")

      ERB::Util.json_escape(@json)
    end

    def escaped_without_erb_utils
      # https://github.com/rails/rails/blob/60257141462137331387d0e34931555cf0720886/activesupport/lib/active_support/core_ext/string/output_safety.rb#L113

      @json.to_s.gsub(ESCAPE_REGEXP, ESCAPE_REPLACEMENT)
    end
  end
end
