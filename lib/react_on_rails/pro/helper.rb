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

module ReactOnRails::Pro
  module Helper
    IMMEDIATE_HYDRATION_PRO_WARNING = "[REACT ON RAILS] The 'immediate_hydration' feature requires a " \
                                      "React on Rails Pro license. " \
                                      "Please visit https://shakacode.com/react-on-rails-pro to learn more."

    # Generates the complete component specification script tag.
    # Handles both immediate hydration (Pro feature) and standard cases.
    def generate_component_script(render_options)
      # Setup the page_loaded_js, which is the same regardless of prerendering or not!
      # The reason is that React is smart about not doing extra work if the server rendering did its job.
      component_specification_tag = content_tag(:script,
        json_safe_and_pretty(render_options.client_props).html_safe,
        type: "application/json",
        class: "js-react-on-rails-component",
        id: "js-react-on-rails-component-#{render_options.dom_id}",
        "data-component-name" => render_options.react_component_name,
        "data-trace" => (render_options.trace ? true : nil),
        "data-dom-id" => render_options.dom_id,
        "data-store-dependencies" => render_options.store_dependencies&.to_json,
        "data-immediate-hydration" =>
          (render_options.immediate_hydration ? true : nil))

      # Add immediate invocation script if immediate hydration is enabled
      spec_tag = if render_options.immediate_hydration
        # Escape dom_id for JavaScript context
        escaped_dom_id = escape_javascript(render_options.dom_id)
        immediate_script = content_tag(:script, %(
          typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsComponentLoaded('#{escaped_dom_id}');
        ).html_safe)
        "#{component_specification_tag}\n#{immediate_script}"
      else
        component_specification_tag
      end

      pro_warning_badge = pro_warning_badge_if_needed(render_options.explicitly_disabled_pro_options)
      "#{pro_warning_badge}\n#{spec_tag}".html_safe
    end

    # Generates the complete store hydration script tag.
    # Handles both immediate hydration (Pro feature) and standard cases.
    def generate_store_script(redux_store_data)
      pro_options_check_result = ReactOnRails::Pro::Utils.disable_pro_render_options_if_not_licensed(redux_store_data)
      redux_store_data = pro_options_check_result[:raw_options]
      explicitly_disabled_pro_options = pro_options_check_result[:explicitly_disabled_pro_options]

      store_hydration_data = content_tag(:script,
        json_safe_and_pretty(redux_store_data[:props]).html_safe,
        type: "application/json",
        "data-js-react-on-rails-store" => redux_store_data[:store_name].html_safe,
        "data-immediate-hydration" =>
          (redux_store_data[:immediate_hydration] ? true : nil))

      # Add immediate invocation script if immediate hydration is enabled and Pro license is valid
      store_hydration_scripts =if redux_store_data[:immediate_hydration]
        # Escape store_name for JavaScript context
        escaped_store_name = escape_javascript(redux_store_data[:store_name])
        immediate_script = content_tag(:script, <<~JS.strip_heredoc.html_safe
          typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsStoreLoaded('#{escaped_store_name}');
        JS
        )
        "#{store_hydration_data}\n#{immediate_script}"
      else
        store_hydration_data
      end

      pro_warning_badge = pro_warning_badge_if_needed(explicitly_disabled_pro_options)
      "#{pro_warning_badge}\n#{store_hydration_scripts}".html_safe
    end

    def pro_warning_badge_if_needed(explicitly_disabled_pro_options)
      return "" unless explicitly_disabled_pro_options.any?

      disabled_features_message = disabled_pro_features_message(explicitly_disabled_pro_options)
      warning_message = "[REACT ON RAILS] #{disabled_features_message}" + "\n" +
                        "Please visit https://shakacode.com/react-on-rails-pro to learn more."
      puts warning_message
      Rails.logger.warn warning_message

      tooltip_text = "#{disabled_features_message} Click to learn more."

      badge_html = <<~HTML.strip
        <a href="https://shakacode.com/react-on-rails-pro" target="_blank" rel="noopener noreferrer" title="#{tooltip_text}">
          <div style="position: fixed; top: 0; right: 0; width: 180px; height: 180px; overflow: hidden; z-index: 9999; pointer-events: none;">
            <div style="position: absolute; top: 50px; right: -40px; transform: rotate(45deg); background-color: rgba(220, 53, 69, 0.85); color: white; padding: 7px 40px; text-align: center; font-weight: bold; font-family: sans-serif; font-size: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.3); pointer-events: auto;">
              React On Rails Pro Required
            </div>
          </div>
        </a>
      HTML
      badge_html
    end

    def disabled_pro_features_message(explicitly_disabled_pro_options)
      return "".html_safe unless explicitly_disabled_pro_options.any?

      feature_list = explicitly_disabled_pro_options.join(', ')
      feature_word = explicitly_disabled_pro_options.size == 1 ? "feature" : "features"
      "The '#{feature_list}' #{feature_word} #{explicitly_disabled_pro_options.size == 1 ? 'requires' : 'require'} a " \
      "React on Rails Pro license. "
    end
  end
end
