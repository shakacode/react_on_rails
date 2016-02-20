require 'pry-rescue'

class PryRescue
  # A Rack middleware that wraps each web request in Pry::rescue.
  class Rack
    # Instantiate the middleware
    #
    # @param [#call] app
    def initialize(app)
      @app = app
    end

    # Handle a web request
    # @param [Rack::Env] env
    def call(env)
      Pry::rescue{ @app.call(env) }
    end
  end
end
