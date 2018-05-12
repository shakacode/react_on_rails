Here is the full set of config options. This file is `/config/initializers/react_on_rails.rb`

```ruby
# frozen_string_literal: true

# NOTE: you typically will leave the commented out configurations set to their defaults.
# Thus, you only need to pay careful attention to the non-commented settings in this file.
ReactOnRails.configure do |config|
  # `trace`: General debugging flag.
  # The default is true for development, off otherwise.
  # With true, you get detailed logs of rendering and stack traces if you call setTimout, 
  # setInterval, clearTimout when server rendering.
  config.trace = Rails.env.development?


  # defaults to "" (top level)
  #
  config.node_modules_location = ""

  # This configures the script to run to build the production assets by webpack. Set this to nil
  # if you don't want react_on_rails building this file for you.
  config.build_production_command = "RAILS_ENV=production bin/webpack"

  ################################################################################
  ################################################################################
  # TEST CONFIGURATION OPTIONS
  # Below options are used with the use of this test helper:
  # ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  ################################################################################

  # If you are using this in your spec_helper.rb (or rails_helper.rb):
  #
  # ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  #
  # with rspec then this controls what yarn command is run
  # to automatically refresh your webpack assets on every test run.
  #
  config.build_test_command = "RAILS_ENV=test bin/webpack"

  # Directory where your generated assets go. All generated assets must go to the same directory.
  # If you are using webpacker, this value will come from your config/webpacker.yml file. 
  # This is the default in webpacker.yml:
  #   public_output_path: packs-test
  # which means files in /public/packs-test
  #
  # Alternately, you may configure this. It is relative to your Rails root directory.
  # A custom, non-webpacker, config might use something like:
  #
  # config.generated_assets_dir = File.join(%w[public webpack], Rails.env)
  # This setting should not be used if using webpacker. 

  # The test helper needs to know where your JavaScript files exist. The default is configured
  # by your config/webpacker.yml soure_path:
  # source_path: app/javascript
  #
  # If you have a non-default `node_modules_location`, that is assumed to be the location of your source
  # files.

  # Define the files we need to check for webpack compilation when running tests.
  # The default is `%w( manifest.json )` as will be sufficient for most webpacker builds.
  #
  config.webpack_generated_files = %w( manifest.json )
  
  # You can optionally add values to your rails_context. See example below for RenderingExtension
  # config.rendering_extension = RenderingExtension

  ################################################################################
  ################################################################################
  # SERVER RENDERING OPTIONS
  ################################################################################
  # This is the file used for server rendering of React when using `(prerender: true)`
  # If you are never using server rendering, you should set this to "".
  # Note, there is only one server bundle, unlike JavaScript where you want to minimize the size
  # of the JS sent to the client. For the server rendering, React on Rails creates a pool of
  # JavaScript execution instances which should handle any component requested.
  #
  # While you may configure this to be the same as your client bundle file, this file is typically
  # different.
  #
  config.server_bundle_js_file = "server-bundle.js"

  # If set to true, this forces Rails to reload the server bundle if it is modified
  # Default value is Rails.env.development?
  #
  config.development_mode = Rails.env.development?

  # For server rendering so that it replays in the browser console.
  # This can be set to false so that server side messages are not displayed in the browser.
  # Default is true. Be cautious about turning this off.
  # Default value is true
  # 
  config.replay_console = true

  # Default is true. Logs server rendering messages to Rails.logger.info. If false, you'll only
  # see the server rendering messages in the browser console.
  #
  config.logging_on_server = true

  # Default is to false to NOT raise exception on server if the JS code throws.
  # Reason is that it's easier to debug this when you get the error over to the client.
  # 
  config.raise_on_prerender_error = false

  ################################################################################
  # Server Renderer Configuration for ExecJS
  ################################################################################
  # The default server rendering is ExecJS, probably using the mini_racer gem
  # If you wish to use an alternative Node server rendering for higher performance, 
  # contact justin@shakacode.com for details.
  # 
  # For ExecJS:
  # You can configure your pool of JS virtual machines and specify where it should load code:
  # On MRI, use `mini_racer` for the best performance
  # (see [discussion](https://github.com/reactjs/react-rails/pull/290))
  # On MRI, you'll get a deadlock with `pool_size` > 1
  # If you're using JRuby, you can increase `pool_size` to have real multi-threaded rendering.
  config.server_renderer_pool_size = 1 # increase if you're on JRuby
  config.server_renderer_timeout = 20 # seconds

  ################################################################################
  # I18N OPTIONS
  ################################################################################
  # Replace the following line to the location where you keep translation.js & default.js for use
  # by the npm packages react-intl. Be sure this directory exists!
  # config.i18n_dir = Rails.root.join("client", "app", "libs", "i18n")
  # If not using the i18n feature, then leave this section commented out or set the value
  # of config.i18n_dir to nil.
  #
  # Replace the following line to the location where you keep your client i18n yml files
  # that will source for automatic generation on translations.js & default.js
  # By default(without this option) all yaml files from Rails.root.join("config", "locales")
  # and installed gems are loaded
  config.i18n_yml_dir = Rails.root.join("config", "locales", "client")
  
  ################################################################################
  ################################################################################
  # CLIENT RENDERING OPTIONS
  # Below options can be overriden by passing options to the react_on_rails
  # `render_component` view helper method.
  ################################################################################
  # default is false
  config.prerender = false
end

```

Example of a RenderingExtension for custom values in the `rails_context`:

```ruby
module RenderingExtension

  # Return a Hash that contains custom values from the view context that will get merged with
  # the standard rails_context values and passed to all calls to generator functions used by the
  # react_component and redux_store view helpers
  def self.custom_context(view_context)
    {
     somethingUseful: view_context.session[:something_useful]
    }
  end
end
```


