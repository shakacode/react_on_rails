# frozen_string_literal: true

module ReactOnRails
  module ProHelper
    # Generates the complete component specification script tag.
    # For Pro users, includes an inline script for immediate hydration during streaming.
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
                                                "data-hydrate-on" =>
                                                  hydrate_on_data_attribute_value(render_options),
                                                "data-ssr-identifier-prefix" =>
                                                  (render_options.html_streaming? ? render_options.dom_id : nil),
                                                "data-store-dependencies" =>
                                                  render_options.store_dependencies&.to_json,
                                                "data-generated-stylesheet-hrefs" =>
                                                  generated_stylesheet_hrefs_json(render_options))

      # Add immediate invocation script for Pro users to enable hydration during streaming
      spec_tag = if ReactOnRails::Utils.react_on_rails_pro?
                   # Escape dom_id for JavaScript context
                   escaped_dom_id = escape_javascript(render_options.dom_id)
                   nonce = csp_nonce
                   script_options = nonce.present? ? { nonce: } : {}
                   immediate_script = content_tag(:script, %(
          typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsComponentLoaded('#{escaped_dom_id}');
        ).html_safe, script_options)
                   "#{component_specification_tag}\n#{immediate_script}"
                 else
                   component_specification_tag
                 end

      spec_tag.html_safe
    end

    def hydrate_on_data_attribute_value(render_options)
      return unless render_options.internal_option(:hydrate_on) || render_options.hydrate_on != :immediate

      render_options.hydrate_on
    end

    def generated_stylesheet_hrefs_json(render_options)
      return unless ReactOnRails::Utils.react_on_rails_pro?
      return unless render_options.auto_load_bundle

      pack_name = "generated/#{render_options.react_component_name}"
      sources = preload_sources_for_stylesheet_pack(pack_name)
      hrefs = unique_preload_sources_by_href(sources).map { |source| source.fetch(:href) }
      hrefs.to_json if hrefs.present?
    end

    # Generates the complete store hydration script tag.
    # For Pro users, includes an inline script for immediate hydration during streaming.
    def generate_store_script(redux_store_data)
      store_hydration_data = content_tag(:script,
                                         json_safe_and_pretty(redux_store_data[:props]).html_safe,
                                         type: "application/json",
                                         "data-js-react-on-rails-store" => redux_store_data[:store_name])

      # Add immediate invocation script for Pro users to enable hydration during streaming
      store_hydration_scripts = if ReactOnRails::Utils.react_on_rails_pro?
                                  # Escape store_name for JavaScript context
                                  escaped_store_name = escape_javascript(redux_store_data[:store_name])
                                  nonce = csp_nonce
                                  script_options = nonce.present? ? { nonce: } : {}
                                  immediate_script = content_tag(
                                    :script,
                                    <<~JS.html_safe,
                                      typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsStoreLoaded('#{escaped_store_name}');
                                    JS
                                    script_options
                                  )
                                  "#{store_hydration_data}\n#{immediate_script}"
                                else
                                  store_hydration_data
                                end

      store_hydration_scripts.html_safe
    end
  end
end
