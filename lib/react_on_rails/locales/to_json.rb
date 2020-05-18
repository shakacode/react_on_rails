# frozen_string_literal: true

require "erb"

module ReactOnRails
  module Locales
    class ToJson < Base
      def initialize
        super
      end

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
