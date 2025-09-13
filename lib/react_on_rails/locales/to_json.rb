# frozen_string_literal: true
# Copyright (c) 2015–2025 ShakaCode, LLC
# SPDX-License-Identifier: MIT


require "erb"

module ReactOnRails
  module Locales
    class ToJson < Base
      private

      def file_format
        "json"
      end

      def template_translations
        @translations
      end

      def template_default
        @defaults
      end
    end
  end
end