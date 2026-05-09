# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require_relative "../../../lib/react_on_rails/config_path_resolver"

RSpec.describe ReactOnRails::ConfigPathResolver do
  describe "#warn_missing_package_root" do
    let(:resolver_class) do
      Class.new do
        include ReactOnRails::ConfigPathResolver

        public :warn_missing_package_root
      end
    end

    it "raises a clear error when the includer does not provide add_warning" do
      resolver = resolver_class.new

      expect { resolver.warn_missing_package_root("/missing/client") }
        .to raise_error(NoMethodError, /must implement #add_warning\(message\)/)
    end
  end
end
