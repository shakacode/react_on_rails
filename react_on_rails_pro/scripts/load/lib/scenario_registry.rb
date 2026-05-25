# frozen_string_literal: true

require_relative "scenarios/standard_render"
require_relative "scenarios/streaming_render"
require_relative "scenarios/incremental_async"

module RendererHarness
  SCENARIO_REGISTRY = {
    "standard_render" => Scenarios::StandardRender,
    "streaming_render" => Scenarios::StreamingRender,
    "incremental_async" => Scenarios::IncrementalAsync
  }.freeze
end
