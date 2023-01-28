Here is the full set of config options. This file is `/config/initializers/react_on_rails.rb`

First, you should have a `/config/webpacker.yml` setup.

Here is the setup when using the recommended `/client` directory for your node_modules and source files:

```yaml
# Note: Base output directory of /public is assumed for static files
default: &default
  compile: false
  # Used in your webpack configuration. Must be created in the
  # public_output_path folder
  manifest: manifest.json
  cache_manifest: false

  # Source path is used to check if webpack compilation needs to be run for `compile: true`
  source_path: client/app

development:
  <<: *default
  # Generated files for development, in /public/webpack/dev
  public_output_path: webpack/dev

test:
  <<: *default
  # Ensure that webpacker invokes webpack to build files for tests if not using the
  #   ReactOnRails rspec helper.
  compile: true

  # Generated files for tests, in /public/webpack/test
  public_output_path: webpack/test

production:
  <<: *default
  # Generated files for production, in /public/webpack/production
  public_output_path: webpack/production
  cache_manifest: true
```

Here's a representative `/config/initializers/react_on_rails.rb` setup when using this `/client` directory
for all client files, including your sources and node_modules.


```ruby
# frozen_string_literal: true

# NOTE: you typically will leave the commented out configurations set to their defaults.
# Thus, you only need to pay careful attention to the non-commented settings in this file.
ReactOnRails.configure do |config|
  # You can optionally add values to your rails_context. This object is passed
  # every time a component renders.
  # See below for an example definition of RenderingExtension
  config.rendering_extension = RenderingExtension
  
  # `trace`: General debugging flag.
  # The default is true for development, off otherwise.
  # With true, you get detailed logs of rendering and stack traces if you call setTimout,
  # setInterval, clearTimout when server rendering.
  config.trace = Rails.env.development? # default

  # Configure if default DOM IDs have a random value or are fixed.
  # false ==> Sets the dom id to "#{react_component_name}-react-component"
  # true ==> Adds "-#{SecureRandom.uuid}" to that ID
  # If you might use multiple instances of the same React component on a Rails page, then
  # it is convenient to set this to true or else you have to either manually set the ids to
  # avoid collisions. Most newer apps will have only one instance of a component on a page,
  # so this should be false in most cases.
  # This value can be overridden for a given call to react_component
  config.random_dom_id = true # default

  # defaults to "" (top level)
  config.node_modules_location = "client" # If using webpacker you should use "".

  # If you're using the standard rails/webpacker configuration of webpack, then rails/webpacker
  # will automatically modify or create an assets:precompile task to build your assets. If so,
  # set this value to nil.  Alternatively, you can specify `config.build_production_command`
  # to have react_on_rails invoke a command for you during assets:precompile.
  # The command is either a script or a module containing a class method `call`
  # In this example, the module BuildProductionCommand would have a class method `call`.
  config.build_production_command = "RAILS_ENV=production bin/webpacker"

  # NOTE:
  # When specifying `build_production_command`, you need to disable `rails/webpacker` 
  # configuration by setting `webpacker_precompile: false` in your `config/webpacker.yml` file.

  # See bottom for an example of the BuildProductionCommand module.
  # config.build_production_command = BuildProductionCommand
  # If you wish to utilize ReactOnRailsPro production bundle caching logic, then use
  # config.build_production_command = ReactOnRailsPro::AssetsPrecompile
  # and be sure to check ReactOnRailsPro's configuration documentation!

  ################################################################################
  ################################################################################
  # SERVER RENDERING OPTIONS
  ################################################################################
  # This is the file used for server rendering of React when using `(prerender: true)`
  # If you are not using server rendering, you should set this to `nil`.
  # Note, there is only one server bundle, unlike JavaScript where you want to minimize the size
  # of the JS sent to the client. For the server rendering, React on Rails creates a pool of
  # JavaScript execution instances which should handle any component requested.
  #
  # While you may configure this to be the same as your client bundle file, this file is typically
  # different. Note, be sure to include the exact file name with the ".js" if you are not hashing this file.
  # If you are hashing this file (supposing you are using the same file for client rendering), then
  # you should include a name that matches your bundle name in your webpack config.
  config.server_bundle_js_file = "server-bundle.js"
  
  # `prerender` means server-side rendering
  # default is false. This is an option for view helpers `render_component` and `render_component_hash`.
  # Set to true to change the default value to true. 
  config.prerender = false

  # THE BELOW OPTIONS FOR SERVER-SIDE RENDERING RARELY NEED CHANGING
  #
  # This value only affects server-side rendering when using the webpack-dev-server
  # If you are hashing the server bundle and you want to use the same bundle for client and server,
  # you'd set this to `true` so that React on Rails reads the server bundle from the webpack-dev-server.
  # Normally, you have different bundles for client and server, thus, the default is false.
  # Furthermore, if you are not hashing the server bundle (not in the manifest.json), then React on Rails
  # will only look for the server bundle to be created in the typical file location, typically by
  # a `webpack --watch` process.
  # If true, ensure that in config/webpacker.yml that you have both dev_server.hmr and
  # dev_server.inline set to false.
  config.same_bundle_for_client_and_server = false

  # If set to true, this forces Rails to reload the server bundle if it is modified
  # Default value is Rails.env.development?
  # You probably will never change this.
  config.development_mode = Rails.env.development?

  # For server rendering so that the server-side console replays in the browser console.
  # This can be set to false so that server side messages are not displayed in the browser.
  # Default is true. Be cautious about turning this off, as it can make debugging difficult.
  # Default value is true
  config.replay_console = true

  # Default is true. Logs server rendering messages to Rails.logger.info. If false, you'll only
  # see the server rendering messages in the browser console.
  config.logging_on_server = true

  # Default is true only for development? to raise exception on server if the JS code throws for
  # server rendering. The reason is that the server logs will show the error and force you to fix
  # any server rendering issues immediately during development.
  config.raise_on_prerender_error = Rails.env.development?

  # This configuration allows logic to be applied to client rendered props, such as stripping props that are only used during server rendering.
  # Add a module with an adjust_props_for_client_side_hydration method that expects the component's name & props hash
  # See below for an example definition of RenderingPropsExtension
  config.rendering_props_extension = RenderingPropsExtension

  ################################################################################
  # Server Renderer Configuration for ExecJS
  ################################################################################
  # The default server rendering is ExecJS, by default using Node.js runtime
  # If you wish to use an alternative Node server rendering for higher performance,
  # contact justin@shakacode.com for details.
  #
  # For ExecJS:
  # You can configure your pool of JS virtual machines and specify where it should load code:
  # On MRI, use `node.js` runtime for the best performance
  # (see https://github.com/shakacode/react_on_rails/issues/1438)
  # Also see https://github.com/shakacode/react_on_rails/issues/1457#issuecomment-1165026717 if using `mini_racer`
  # On MRI, you'll get a deadlock with `pool_size` > 1
  # If you're using JRuby, you can increase `pool_size` to have real multi-threaded rendering.
  config.server_renderer_pool_size = 1 # increase if you're on JRuby
  config.server_renderer_timeout = 20 # seconds

  ################################################################################
  ################################################################################
  # FILE SYSTEM BASED COMPONENT REGISTRY
  # `render_component` and `render_component_hash` view helper methods can
  # auto-load the bundle for the generated component, to avoid having to specify the
  # bundle manually for each view with the component.
  ################################################################################
  # components_subdirectory is the name of the subdirectory matched to detect and register components automatically
  # The default is nil. You can enable the feature by updating it in the next line.
  config.components_subdirectory = nil
  # Change to a value like this example to enable this feature 
  # config.components_subdirectory = "ror_components"

  # Default configuration to auto loading bundles for components.
  # default is false. The default can be overrident as an option in calls to view helpers
  # `render_component` and `render_component_hash`. You may set to true to change the default to auto loading.
  config.auto_load_bundle = false

  ################################################################################
  # I18N OPTIONS
  ################################################################################
  # Replace the following line to the location where you keep translation.js & default.js for use
  # by the npm packages react-intl. Be sure this directory exists!
  # config.i18n_dir = Rails.root.join("client", "app", "libs", "i18n")
  #
  # If not using the i18n feature, then leave this section commented out or set the value
  # of config.i18n_dir to nil.
  #
  # Replace the following line to the location where you keep your client i18n yml files
  # that will source for automatic generation on translations.js & default.js
  # By default(without this option) all yaml files from Rails.root.join("config", "locales")
  # and installed gems are loaded
  config.i18n_yml_dir = Rails.root.join("config", "locales")

  # Possible output formats are js and json
  # The default format is json
  config.i18n_output_format = 'json'

  ################################################################################
  ################################################################################
  # TEST CONFIGURATION OPTIONS
  # Below options are used with the use of this test helper:
  # ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  #
  # NOTE:
  # Instead of using this test helper, you may ensure fresh test files using rails/webpacker via:
  # 1. Have `config/webpacker/test.js` exporting an array of objects to configure both client and server bundles.
  # 2. Set the compile option to true in config/webpacker.yml for env test
  ################################################################################

  # If you are using this in your spec_helper.rb (or rails_helper.rb):
  #
  # ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  #
  # with rspec then this controls what yarn command is run
  # to automatically refresh your webpack assets on every test run.
  #
  config.build_test_command = "RAILS_ENV=test bin/webpacker"

  # CONFIGURE YOUR SOURCE FILES
  # The test helper needs to know where your JavaScript files exist. The value is configured
  # by your config/webpacker.yml source_path:
  # source_path: client/app # if using recommended /client directory
  #
  # Define the files we need to check for webpack compilation when running tests.
  # The default is `%w( manifest.json )` as will be sufficient for most webpacker builds.
  # However, if you are generating a server bundle that is NOT hashed (present in manifest.json),
  # then include the file in this list like this:
  config.webpack_generated_files = %w( server-bundle.js manifest.json )
  # Note, be sure NOT to include your server-bundle.js if it is hashed, or else React on Rails will
  # think the server-bundle.js is missing every time for test runs.
end
```

Example of a ReactOnRailsConfig module for `client_props_extension`:

```ruby
module RenderingPropsExtension
  # The modify_props method will be called by ReactOnRails::ReactComponent::RenderOptions if config.client_props_extension is defined
  def self.adjust_props_for_client_side_hydration(component_name, props)
    component_name == 'HelloWorld' ? props.except(:server_side_only) : props
  end
end
```

Example of a ReactOnRailsConfig module for `production_build_command`:

```ruby
module BuildProductionCommand
  include FileUtils
  # The call method will be called during assets:precompile
  def self.call
    sh "bin/webpacker"
  end
end
```

Example of a RenderingExtension for custom values in the `rails_context`:

```ruby
module RenderingExtension

  # Return a Hash that contains custom values from the view context that will get merged with
  # the standard rails_context values and passed to all calls to Render-Functions used by the
  # react_component and redux_store view helpers
  def self.custom_context(view_context)
    {
     somethingUseful: view_context.session[:something_useful]
    }
  end
end
```
