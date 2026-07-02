# frozen_string_literal: true

require "erb"

module ReactOnRails
  module Locales
    class ToJs < Base
      LEGACY_DEFAULT_IMPORT = /\A\s*import\s+\{\s*defineMessages\s*\}\s+from\s+["']react-intl["'];?/
      private_constant :LEGACY_DEFAULT_IMPORT

      CURRENT_DEFAULT_LOCALE = /\A\s*const\s+defaultLocale\s*=/
      private_constant :CURRENT_DEFAULT_LOCALE

      private

      def file_format
        "js"
      end

      def generated_files_obsolete?
        # obsolete? only calls this after all output files exist; if the file disappears, regenerate.
        File.foreach(file("default")) do |line|
          next if line.match?(/\A\s*\z/)

          return true if line.match?(LEGACY_DEFAULT_IMPORT)
          return false if line.match?(CURRENT_DEFAULT_LOCALE)
        end

        false
      rescue Errno::ENOENT
        true
      end
    end
  end
end
