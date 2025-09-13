# frozen_string_literal: true
# Copyright (c) 2015–2025 ShakaCode, LLC
# SPDX-License-Identifier: MIT


require "erb"

module ReactOnRails
  module Locales
    class ToJs < Base
      private

      def file_format
        "js"
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