# How to conditionally render server side based on the device type

In general, we want to use CSS to do mobile responsive layouts.

However, sometimes we want to have layouts sufficiently different that we can't do this via CSS. If we didn't do server rendering, we can check the device type on the client side. However, if we're doing server rendering, we need to send this data to the client code from the Rails server so that the server rendering can account for this.

Here's an example:

## config/initializers/react_on_rails.rb

```ruby
module RenderingExtension
  # Return a Hash that contains custom values from the view context that will get passed to
  # all calls to react_component and redux_store for rendering
  def self.custom_context(view_context)
    if view_context.controller.is_a?(ActionMailer::Base)
      {}
    else
      {
        desktop: !(view_context.browser.device.tablet? || view_context.browser.device.mobile?),
        tablet: view_context.browser.device.tablet?,
        mobile: view_context.browser.device.mobile? || false
      }
    end
  end
end

# Shown below are the defaults for configuration
ReactOnRails.configure do |config|
  # See https://github.com/shakacode/react_on_rails/blob/master/docs/guides/configuration.md for the rest

  # This allows you to add additional values to the Rails Context. Implement one static method
  # called `custom_context(view_context)` and return a Hash.
  config.rendering_extension = RenderingExtension
end
```

Note, full details of the React on Rails configuration are [here in docs/basics/configuration.md](https://shakacode.com/react-on-rails/docs/guides/configuration/).

See the doc file [render-functions-and-railscontext.md](./render-functions-and-railscontext.md#rails-context) for how your client-side code uses the device information
