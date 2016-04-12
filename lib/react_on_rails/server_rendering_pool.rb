require "connection_pool"
require_relative "server_rendering_pool/exec"
require_relative "server_rendering_pool/node"

# Based on the react-rails gem.
# None of these methods should be called directly.
# See app/helpers/react_on_rails_helper.rb
module ReactOnRails
  module ServerRenderingPool
    class << self
      def pool
        if ReactOnRails.configuration.server_render_method == "NodeJS"
          ServerRenderingPool::Node
        else
          ServerRenderingPool::Exec
        end
      end

      def method_missing(sym, *args, &block)
        pool.send sym, *args, &block
      end
    end
  end
end
