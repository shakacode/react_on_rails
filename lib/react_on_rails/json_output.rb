# frozen_string_literal: true

require "active_support/core_ext/string/output_safety"

module ReactOnRails
  class JsonOutput
    def self.escape(json)
      ERB::Util.json_escape(json)
    end
  end
end
