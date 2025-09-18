# frozen_string_literal: true

# /*
#  * Copyright (c) 2025 Shakacode
#  *
#  * This file, and all other files in this directory, are NOT licensed under the MIT license.
#  *
#  * This file is part of React on Rails Pro.
#  *
#  * Unauthorized copying, modification, distribution, or use of this file, via any medium,
#  * is strictly prohibited. It is proprietary and confidential.
#  *
#  * For the full license agreement, see:
#  * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
#  */

module ReactOnRails
  module ProFeatures
    module Helper
      IMMEDIATE_HYDRATION_PRO_WARNING = "[REACT ON RAILS] The 'immediate_hydration' feature requires a " \
                                        "React on Rails Pro license. " \
                                        "Please visit https://shakacode.com/react-on-rails-pro to learn more."

      # This method is responsible for generating the necessary attributes and script tags
      # for the immediate_hydration feature. It is enabled only when a valid
      # React on Rails Pro license is detected.
      def apply_immediate_hydration_if_supported(component_specification_tag, render_options)
        return component_specification_tag unless render_options.immediate_hydration && support_pro_features?

        # Add data attribute
        component_specification_tag.gsub!("<script ", '<script data-immediate-hydration="true" ')

        # Add immediate invocation script
        component_specification_tag.concat(
          content_tag(:script, %(
            typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsComponentLoaded('#{render_options.dom_id}');
          ).html_safe)
        )
      end

      # Similar logic for redux_store
      def apply_store_immediate_hydration_if_supported(store_hydration_data, redux_store_data)
        return store_hydration_data unless redux_store_data[:immediate_hydration] && support_pro_features?

        # Add data attribute
        store_hydration_data.gsub!("<script ", '<script data-immediate-hydration="true" ')

        # Add immediate invocation script
        store_hydration_data.concat(
          content_tag(:script, <<~JS.strip_heredoc.html_safe
            typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsStoreLoaded('#{redux_store_data[:store_name]}');
          JS
          )
        )
      end

      # Checks if React on Rails Pro features are available
      # @return [Boolean] true if Pro license is valid, false otherwise
      def support_pro_features?
        ReactOnRails::Utils.react_on_rails_pro_licence_valid?
      end

      def pro_warning_badge_if_needed(immediate_hydration)
        return "".html_safe unless immediate_hydration
        return "".html_safe if support_pro_features?

        puts IMMEDIATE_HYDRATION_PRO_WARNING
        Rails.logger.warn IMMEDIATE_HYDRATION_PRO_WARNING

        tooltip_text = "The 'immediate_hydration' feature requires a React on Rails Pro license. Click to learn more."

        badge_html = <<~HTML
          <a href="https://shakacode.com/react-on-rails-pro" target="_blank" rel="noopener noreferrer" title="#{tooltip_text}">
            <div style="position: fixed; top: 0; right: 0; width: 180px; height: 180px; overflow: hidden; z-index: 9999; pointer-events: none;">
              <div style="position: absolute; top: 50px; right: -40px; transform: rotate(45deg); background-color: rgba(220, 53, 69, 0.85); color: white; padding: 7px 40px; text-align: center; font-weight: bold; font-family: sans-serif; font-size: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.3); pointer-events: auto;">
                React On Rails Pro Required
              </div>
            </div>
          </a>
        HTML
        badge_html.strip.html_safe
      end
    end
  end
end
