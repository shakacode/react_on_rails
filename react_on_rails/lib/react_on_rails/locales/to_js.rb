# frozen_string_literal: true

require "erb"

module ReactOnRails
  module Locales
    class ToJs < Base
      private

      def file_format
        "js"
      end

      def generated_files_obsolete?
        # obsolete? only calls this after all output files exist; if the file disappears, regenerate.
        default_source = File.read(file("default"))

        default_source.match?(/^\s*import\s+\{\s*defineMessages\s*\}\s+from\s+["']react-intl["'];?/)
      rescue Errno::ENOENT
        true
      end
    end
  end
end
