# react-on-rails-renderer
Node rendering for React on Rails

## Setup for react_on_rails application

To configure existing `react_on_rails` application to use **Node rendering**, do the following:

1. Add ruby gem to your **Gemfile**. Since the repository is private, you can generate and use **OAuth** token:
```ruby
gem "react_on_rails_renderer", git: "https://[your-github-token]:x-oauth-basic@github.com/shakacode/react-on-rails-renderer.git"
```
2. Run `bundle install`.
3. Currently you have to monkeypatch `ReactOnRails::ServerRenderingPool` module at the end of `initializers/react_on_rails`:
```ruby
module ReactOnRails
  module ServerRenderingPool
    class << self
      def pool
        if ReactOnRails.configuration.server_render_method == "NodeJS"
          ServerRenderingPool::Node
        elsif ReactOnRails.configuration.server_render_method == "NodeJSHttp"
          ReactOnRailsRenderer::RenderingPool
        else
          ServerRenderingPool::Exec
        end
      end

      # rubocop:disable Style/MethodMissing
      def method_missing(sym, *args, &block)
        pool.send sym, *args, &block
      end
    end
  end
end
```
4. Set `config.server_render_method = "NodeJSHttp"` in your  `ReactOnRails.configure` block.

5. Create `initializers/react_on_rails_renderer` initializer and configure connection to **renderer server**:
```ruby
ReactOnRailsRenderer.configure do |config|
  config.renderer_protocol = "https"
  config.renderer_host = "[your-renderer-host-without-protocol-and-port]"
  config.renderer_port = 443
end
```
