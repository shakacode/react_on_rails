module ReactOnRails
  class Engine < ::Rails::Engine
    config.to_prepare do
      ReactOnRails::ServerRenderingPool.reset_pool
    end
  end
end
