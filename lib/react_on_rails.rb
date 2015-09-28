require "rails"

require "react_on_rails/version"
require "react_on_rails/configuration"
require "react_on_rails/server_rendering_pool"
module ReactOnRails
  class Engine < ::Rails::Engine
    config.to_prepare do
      ReactOnRails::ServerRenderingPool.reset_pool
    end
  end
end
