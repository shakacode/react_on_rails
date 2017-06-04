# frozen_string_literal: true

require "active_support/core_ext/string/output_safety"

module ReactOnRails
  class JsonOutput
    ESCAPE_REPLACEMENT = {
      "&" => '\u0026',
      ">" => '\u003e',
      "<" => '\u003c',
      "\u2028" => '\u2028',
      "\u2029" => '\u2029'
    }.freeze
    ESCAPE_REGEXP = /[\u2028\u2029&><]/u

    def self.escape(json)
      return escape_without_erb_util(json) if Utils.rails_version_less_than_4_1_1

      ERB::Util.json_escape(json)
    end

    def self.escape_without_erb_util(json)
      # https://github.com/rails/rails/blob/60257141462137331387d0e34931555cf0720886/activesupport/lib/active_support/core_ext/string/output_safety.rb#L113

      json.to_s.gsub(ESCAPE_REGEXP, ESCAPE_REPLACEMENT)
    end
  end
end
