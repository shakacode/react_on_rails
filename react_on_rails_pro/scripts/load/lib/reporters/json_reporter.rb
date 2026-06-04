# frozen_string_literal: true

require "json"
require "fileutils"

module RendererHarness
  module Reporters
    module JsonReporter
      module_function

      def write(path, payload)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, JSON.pretty_generate(payload))
      end
    end
  end
end
