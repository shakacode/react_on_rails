# frozen_string_literal: true

require "webpacker"

module ReactOnRails
  module WebpackerHelper
    include Webpacker::Helper

    def load_pack_for_component(component_name)
      component_pack_file = generated_components_pack(component_name)
      is_component_pack_present = File.exist?("#{component_pack_file}.jsx")
      is_development = ENV["RAILS_ENV"] == "development"

      if is_development && !is_component_pack_present
        ReactOnRails::PacksGenerator.generate
        raise_generated_missing_pack_warning(component_name)
      end

      ReactOnRails::PacksGenerator.raise_nested_entries_disabled unless ReactOnRails::WebpackerUtils.nested_entries?

      append_javascript_pack_tag "generated/#{component_name}"
      append_stylesheet_pack_tag "generated/#{component_name}"
    end

    def generated_components_pack(component_name)
      "#{ReactOnRails::WebpackerUtils.webpacker_source_entry_path}/generated/#{component_name}"
    end

    def raise_generated_missing_pack_warning(component_name)
      msg = <<~MSG
        **ERROR** ReactOnRails: Generated missing pack for Component: #{component_name}. Please refresh the webpage \
        once webpack has finished generating the bundles. If the problem persists
        1. Verify `components_subdirectory` is configured in `config/initializers/react_on_rails`.
        2. Component: #{component_name} is placed inside the configured `components_subdirectory`.
      MSG

      raise ReactOnRails::Error, msg
    end
  end
end
