# frozen_string_literal: true

module ReactOnRails
  module ProHelper
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
                                                "data-store-dependencies" =>
                                                  render_options.store_dependencies&.to_json,
                                                "data-immediate-hydration" =>
                                                  (render_options.immediate_hydration ? true : nil))

      # Add immediate invocation script if immediate hydration is enabled
      if render_options.immediate_hydration
        # Escape dom_id for JavaScript context
        escaped_dom_id = escape_javascript(render_options.dom_id)
        immediate_script = content_tag(:script, %(
  typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsComponentLoaded('#{escaped_dom_id}');
).html_safe)
        "#{component_specification_tag}\n#{immediate_script}".html_safe
      else
        component_specification_tag
      end
    end

    # Generates the complete store hydration script tag.
    # Handles both immediate hydration (Pro feature) and standard cases.
    def generate_store_script(redux_store_data)
      pro_options_check_result = ReactOnRails::ProUtils.disable_pro_render_options_if_not_licensed(redux_store_data)
      redux_store_data = pro_options_check_result[:raw_options]

      store_hydration_data = content_tag(:script,
                                         json_safe_and_pretty(redux_store_data[:props]).html_safe,
                                         type: "application/json",
                                         "data-js-react-on-rails-store" => redux_store_data[:store_name].html_safe,
                                         "data-immediate-hydration" =>
                                           (redux_store_data[:immediate_hydration] ? true : nil))

      # Add immediate invocation script if immediate hydration is enabled and Pro license is valid
      if redux_store_data[:immediate_hydration]
        # Escape store_name for JavaScript context
        escaped_store_name = escape_javascript(redux_store_data[:store_name])
        immediate_script = content_tag(:script, <<~JS.strip_heredoc.html_safe
          typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsStoreLoaded('#{escaped_store_name}');
        JS
        )
        "#{store_hydration_data}\n#{immediate_script}".html_safe
      else
        store_hydration_data
      end
    end
  end
end
