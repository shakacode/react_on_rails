# frozen_string_literal: true

# /*
#  * Copyright (c) 2025 Shakacode LLC
#  *
#  * This file is NOT licensed under the MIT (open source) license.
#  * It is part of the React on Rails Pro offering and is licensed separately.
#  *
#  * Unauthorized copying, modification, distribution, or use of this file,
#  * via any medium, is strictly prohibited without a valid license agreement
#  * from Shakacode LLC.
#  *
#  * For licensing terms, please see:
#  * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
#  */

require "action_view"

module ReactOnRailsPro
  module Helper
    extend ActionView::Helpers::TagHelper
    extend ActionView::Helpers::JavaScriptHelper

    # Enhances component script data with immediate hydration support
    # @param script_attrs [Hash] Base script tag attributes
    # @param script_content [String] Script content (not used in current implementation)
    # @param render_options [ReactOnRails::ReactComponent::RenderOptions] Render options
    # @return [Hash] Enhanced script attributes and additional scripts
    def self.enhance_component_script_data(script_attrs:, script_content:, render_options:)
      _ = script_content # Mark as intentionally unused
      if render_options.immediate_hydration
        # Add data attribute for immediate hydration
        script_attrs["data-immediate-hydration"] = true

        # Add immediate invocation script
        escaped_dom_id = escape_javascript(render_options.dom_id)
        immediate_script = content_tag(:script, %(
  typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsComponentLoaded('#{escaped_dom_id}');
        ).html_safe)

        return {
          script_attrs: script_attrs,
          additional_scripts: [immediate_script]
        }
      end

      { script_attrs: script_attrs, additional_scripts: [] }
    end

    # Enhances store script data with immediate hydration support
    # @param script_attrs [Hash] Base script tag attributes
    # @param script_content [String] Script content (not used in current implementation)
    # @param redux_store_data [Hash] Redux store data including store_name and props
    # @return [Hash] Enhanced script attributes and additional scripts
    def self.enhance_store_script_data(script_attrs:, script_content:, redux_store_data:)
      _ = script_content # Mark as intentionally unused
      if redux_store_data[:immediate_hydration]
        # Add data attribute for immediate hydration
        script_attrs["data-immediate-hydration"] = true

        # Add immediate invocation script
        escaped_store_name = escape_javascript(redux_store_data[:store_name])
        immediate_script = content_tag(:script, %(
  typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsStoreLoaded('#{escaped_store_name}');
        ).html_safe)

        return {
          script_attrs: script_attrs,
          additional_scripts: [immediate_script]
        }
      end

      { script_attrs: script_attrs, additional_scripts: [] }
    end
  end
end
