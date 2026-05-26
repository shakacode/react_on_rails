# frozen_string_literal: true

require_relative "scenarios/standard_render"
require_relative "scenarios/streaming_render"

module RendererHarness
  SCENARIO_REGISTRY = {
    "standard_render" => Scenarios::StandardRender,
    "streaming_render" => Scenarios::StreamingRender
  }.freeze
end
