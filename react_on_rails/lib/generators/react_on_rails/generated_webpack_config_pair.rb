# frozen_string_literal: true

require "erb"

module ReactOnRails
  module Generators
    # Recognizes whole current generated pairs without interpreting application JavaScript.
    # Every interpolation comes from these fixed variants, never from the input files.
    class GeneratedWebpackConfigPair
      TEMPLATE_ROOT = File.expand_path("templates/base/base/config/webpack", __dir__)
      FILENAMES = %w[serverWebpackConfig.js ServerClientOrBoth.js].freeze
      DOCUMENTATION_MESSAGE = "// The source code including full typescript support is available at:"
      # pro, rsc, rspack: the latter affects source text only when RSC is enabled.
      MODES = [[false, false, false], [true, false, false], [true, true, false], [true, true, true]].freeze

      def self.pro_upgrade(contents)
        shakapacker_versions = [false, true]
        MODES.each do |pro, rsc, rspack|
          shakapacker_versions.each do |shakapacker9|
            pair = new(pro:, rsc:, rspack:, shakapacker9:)
            next unless pair.contents == contents

            return contents if pro

            return new(pro: true, rsc:, rspack:, shakapacker9:).contents
          end
        end
        nil
      rescue StandardError, SyntaxError
        # Missing templates or a newly introduced ERB dependency make recognition unknown.
        # No input file has been touched; the caller supplies manual migration instructions.
        nil
      end

      def initialize(pro:, rsc:, rspack:, shakapacker9:)
        @pro = pro
        @rsc = rsc
        @rspack = rspack
        @shakapacker9 = shakapacker9
      end

      def contents
        FILENAMES.map do |filename|
          template = File.read(File.join(TEMPLATE_ROOT, "#{filename}.tt"))
          ERB.new(template, trim_mode: "-").result(template_binding).b
        end
      end

      private

      def template_binding
        binding
      end

      def config
        { message: DOCUMENTATION_MESSAGE }
      end

      def add_documentation_reference(message, source)
        "#{message}\n#{source}"
      end

      def use_pro?
        @pro
      end

      def use_rsc?
        @rsc
      end

      def shakapacker_version_9_or_higher?
        @shakapacker9
      end

      def rsc_plugin_class_name
        @rspack ? "RSCRspackPlugin" : "RSCWebpackPlugin"
      end

      def rsc_plugin_import_path
        @rspack ? "react-on-rails-rsc/RspackPlugin" : "react-on-rails-rsc/WebpackPlugin"
      end
    end
  end
end
