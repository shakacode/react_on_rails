# frozen_string_literal: true

require "erb"

module ReactOnRails
  module Locales
    class ToJs < Base
      LEGACY_DEFAULT_IMPORT = /\A\s*import\s+\{\s*defineMessages\s*\}\s+from\s+["']react-intl["'];?/
      private_constant :LEGACY_DEFAULT_IMPORT

      private

      def file_format
        "js"
      end

      def generated_files_obsolete?
        # obsolete? only calls this after all output files exist; if the file disappears, regenerate.
        first_significant_line = nil
        File.foreach(file("default")) do |line|
          next if line.match?(/\A\s*\z/)

          first_significant_line = line
          break
        end

        !!first_significant_line&.match?(LEGACY_DEFAULT_IMPORT)
      rescue Errno::ENOENT
        true
      end
    end
  end
end
