# frozen_string_literal: true

TraceVisualizer::Engine.routes.draw do
  get "/", to: "trace_visualizer#index"
end
