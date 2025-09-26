# frozen_string_literal: true

module AsyncComponentHelpers
  ASYNC_COMPONENTS_DELAYS = [[1000, 2000], [3000], [1000], [2000]].freeze

  def async_component_rendered_message(suspense_boundary, component)
    component_name = suspense_boundary == 3 ? "Server Component" : "Async Component #{component + 1}"
    delay = ASYNC_COMPONENTS_DELAYS[suspense_boundary][component]
    "RealComponent rendered #{component_name} from Suspense Boundary#{suspense_boundary + 1} " \
      "(#{delay}ms server side delay)"
  end

  def async_component_hydrated_message(suspense_boundary, component)
    component_name = suspense_boundary == 3 ? "Server Component" : "Async Component #{component + 1}"
    delay = ASYNC_COMPONENTS_DELAYS[suspense_boundary][component]
    "RealComponent has been mounted #{component_name} from " \
      "Suspense Boundary#{suspense_boundary + 1} (#{delay}ms server side delay)"
  end

  def async_loading_component_message(suspense_boundary)
    "LoadingComponent rendered Loading Server Component on Suspense Boundary#{suspense_boundary + 1}"
  end
end

RSpec.configure do |config|
  config.include AsyncComponentHelpers, type: :system
end
