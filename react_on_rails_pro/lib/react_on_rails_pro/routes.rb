# frozen_string_literal: true

module ReactOnRailsPro
  module Routes
    def rsc_payload_route(
      path: ReactOnRailsPro.configuration.rsc_payload_generation_url_path,
      controller: "react_on_rails_pro/rsc_payload",
      **
    )
      get("#{path}/:component_name", to: "#{controller}#rsc_payload", **)
    end
  end
end
