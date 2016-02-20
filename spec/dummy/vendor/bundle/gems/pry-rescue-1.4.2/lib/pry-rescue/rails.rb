require 'pry-rescue'
class PryRescue
  # A railtie that inserts PryRescue::Rack at the correct point in the
  # middleware chain.
  #
  # Just adding 'use PryRescue::Rack' inside your rails app will add
  # the middleware above the rails exception handling middleware,
  # and so it will not work.
  if defined?(::Rails)
    class Railtie < ::Rails::Railtie
      initializer "pry_rescue" do |app|
        app.config.middleware.use PryRescue::Rack
      end
    end
  end
end
