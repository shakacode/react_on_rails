# frozen_string_literal: true

# Copyright (c) 2015–2025 ShakaCode, LLC
# SPDX-License-Identifier: MIT

require "active_support/core_ext/string/output_safety"

module ReactOnRails
  class JsonOutput
    def self.escape(json)
      ERB::Util.json_escape(json)
    end
  end
end
