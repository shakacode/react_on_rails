# frozen_string_literal: true

require "active_support/core_ext/string/output_safety"

module ReactOnRails
  # Utility class for JSON output operations
  class JsonOutput
    # Escapes a JSON string for safe HTML rendering
    # @param json [String, nil] The JSON string to escape
    # @return [String] The escaped JSON string
    def self.escape(json)
      return "" if json.nil?

      ERB::Util.json_escape(json)
    end
  end
end
