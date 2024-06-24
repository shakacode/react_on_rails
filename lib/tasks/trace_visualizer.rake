# frozen_string_literal: true

namespace :react_on_rails do
  task trace_visualizer: :environment do
    require 'rack/handler/puma'  # Using Puma as the server
    Rack::Handler::Puma.run TraceVisualizer::Engine, Port: 5200 do |server|
      puts 'Serving Trace Visualizer on http://localhost:5200'
      trap(:INT) do
        server.stop
        puts 'Shutting down server'
      end
    end
  end
end
