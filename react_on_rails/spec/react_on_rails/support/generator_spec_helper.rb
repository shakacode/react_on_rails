# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../simplecov_helper"
require "generator_spec/test_case"

Dir["#{File.expand_path('../support/shared_examples', __dir__)}/*.rb"].each { |file| require file }
generators_glob = File.expand_path("../../../lib/generators/react_on_rails/*_generator.rb", __dir__)
Dir[generators_glob.to_s].each { |file| require file }
include ReactOnRails::Generators # rubocop:disable Style/MixinUsage

RSpec.configure do |config|
  config.after do
    GeneratorMessages.clear
  end
end

def simulate_existing_rails_files(options)
  simulate_existing_file(".gitignore") if options.fetch(:gitignore, true)
  if options.fetch(:hello_world_file, false)
    simulate_existing_file(
      "app/views/hello_world/index.html.erb",
      "<%= react_component('HelloWorldApp', props: @hello_world_props, prerender: false) %>"
    )
  end
  simulate_existing_file("Gemfile", "")
  simulate_existing_file("config/routes.rb", "Rails.application.routes.draw do\nend\n")
  simulate_existing_file("config/application.rb",
                         "module Gentest\nclass Application < Rails::Application\nend\nend)")

  return unless options.fetch(:spec, true)

  simulate_existing_dir("spec")
  simulate_existing_file("spec/rails_helper.rb",
                         "RSpec.configure do |config|\nend\n")
end

def simulate_npm_files(options)
  return unless options.fetch(:package_json, false)

  package_json = "package.json"
  package_json_data = <<~JSON
    {
      "name": "foo",
      "private": true,
      "scripts": {
        "foo": "bar"
      },
      "dependencies": {
        "foo": "^0",
        "react-on-rails": "5.2.0",
        "bar": "^0"
      },
      "devDependencies": {
      }
    }
  JSON
  simulate_existing_file(package_json, package_json_data)
end

# Expects an array of strings, such as "--redux"
def run_generator_test_with_args(args, options = {})
  prepare_destination # this completely wipes the `destination` directory
  simulate_existing_rails_files(options)
  simulate_npm_files(options)
  yield if block_given?

  Dir.chdir(destination_root) do
    # WARNING: std out is swallowed from running the generator during tests
    run_generator(args + ["--ignore-warnings", "--force"])
  end
end

# Simulate having an existing file for cases where the generator needs to modify, not create, a file
def simulate_existing_file(file, data = "some existing text\n")
  # raise "File #{file} already exists in call to simulate_existing_file" if File.exist?(file)
  path = Pathname.new(File.join(destination_root, file))
  mkdir_p(path.dirname)
  File.open(path, "w+") do |f|
    f.puts(data) if data.present?
  end
end

# Simulate having an existing directory for cases where the generator needs to add a file to a directory
# that will definitely already exist
def simulate_existing_dir(dirname)
  path = File.join(destination_root, dirname)
  mkdir_p(path)
end

def simulate_existing_layout(layout_name, content)
  simulate_existing_file("app/views/layouts/#{layout_name}.html.erb", content)
end

def simulate_layout_with_pack_tags(layout_name = "hello_world", stylesheet_tag:, javascript_tag:)
  simulate_existing_layout(layout_name, <<~ERB)
    <!DOCTYPE html>
    <html>
      <head>
        #{stylesheet_tag}
        #{javascript_tag}
      </head>
      <body>
        <%= yield %>
      </body>
    </html>
  ERB
end

def simulate_canonical_pack_tag_layout(layout_name = "hello_world")
  simulate_layout_with_pack_tags(
    layout_name,
    stylesheet_tag: "<%= stylesheet_pack_tag %>",
    javascript_tag: "<%= javascript_pack_tag %>"
  )
end

def simulate_named_pack_tag_layout(layout_name = "hello_world")
  simulate_layout_with_pack_tags(
    layout_name,
    stylesheet_tag: '<%= stylesheet_pack_tag "application" %>',
    javascript_tag: '<%= javascript_pack_tag "application" %>'
  )
end

def simulate_layout_missing_stylesheet_pack_tag(layout_name = "hello_world")
  simulate_existing_layout(layout_name, <<~ERB)
    <!DOCTYPE html>
    <html>
      <head>
        <%= javascript_pack_tag "application" %>
      </head>
      <body>
        <%= yield %>
      </body>
    </html>
  ERB
end

def simulate_hello_world_controller(layout_name = "hello_world")
  simulate_existing_file("app/controllers/hello_world_controller.rb", <<~RUBY)
    class HelloWorldController < ApplicationController
      layout "#{layout_name}"

      def index
      end
    end
  RUBY
end

def assert_directory_with_keep_file(dir)
  assert_directory dir
  assert_file File.join(dir, ".keep")
end

# Simulates base-install webpack configs (use_pro? = false, use_rsc? = false).
# Contains all structural elements that Pro gsub transforms target.
# Used by Pro generator tests to verify standalone upgrade transforms.
def simulate_base_webpack_files
  simulate_existing_file("config/webpack/serverWebpackConfig.js", base_server_webpack_content)
  simulate_existing_file("config/webpack/ServerClientOrBoth.js",
                         server_client_or_both_content(destructured_import: false))
end

# Simulates Pro-transformed webpack configs (after Pro generator, before RSC).
# Contains extractLoader, object exports, destructured imports — all RSC patterns target these.
# Used by RSC generator tests to verify standalone upgrade transforms.
def simulate_pro_webpack_files
  simulate_existing_file("config/webpack/serverWebpackConfig.js", pro_server_webpack_content)
  simulate_existing_file("config/webpack/ServerClientOrBoth.js",
                         server_client_or_both_content(destructured_import: true))
  simulate_existing_file("config/webpack/clientWebpackConfig.js", base_client_webpack_content)
end

# Simulates a legacy Pro webpack setup with function export style.
# This reflects older Pro installs that predate object exports with extractLoader.
def simulate_legacy_pro_webpack_files
  simulate_existing_file("config/webpack/serverWebpackConfig.js", legacy_pro_server_webpack_content)
  simulate_existing_file("config/webpack/ServerClientOrBoth.js",
                         server_client_or_both_content(destructured_import: false))
  simulate_existing_file("config/webpack/clientWebpackConfig.js", base_client_webpack_content)
end

# Simulates base-install webpack configs for an rspack project.
# Mirrors simulate_base_webpack_files but in config/rspack/ with rspack shakapacker.yml.
# Used by standalone generator tests (e.g. ProGenerator) on existing rspack projects.
def simulate_rspack_base_webpack_files
  simulate_rspack_shakapacker_yml
  simulate_existing_file("config/rspack/serverWebpackConfig.js", base_server_webpack_content)
  simulate_existing_file("config/rspack/ServerClientOrBoth.js",
                         server_client_or_both_content(destructured_import: false))
end

# Simulates Pro-transformed webpack configs for an rspack project.
# Mirrors simulate_pro_webpack_files but in config/rspack/ with rspack shakapacker.yml.
# Used by RSC generator tests to verify standalone upgrade transforms on rspack projects.
def simulate_rspack_pro_webpack_files
  simulate_rspack_shakapacker_yml
  simulate_existing_file("config/rspack/serverWebpackConfig.js", pro_server_webpack_content)
  simulate_existing_file("config/rspack/ServerClientOrBoth.js",
                         server_client_or_both_content(destructured_import: true))
  simulate_existing_file("config/rspack/clientWebpackConfig.js", base_client_webpack_content)
end

# Simulates a legacy Pro webpack setup for an rspack project.
# Mirrors simulate_legacy_pro_webpack_files but in config/rspack/ with rspack shakapacker.yml.
def simulate_rspack_legacy_pro_webpack_files
  simulate_rspack_shakapacker_yml
  simulate_existing_file("config/rspack/serverWebpackConfig.js", legacy_pro_server_webpack_content)
  simulate_existing_file("config/rspack/ServerClientOrBoth.js",
                         server_client_or_both_content(destructured_import: false))
  simulate_existing_file("config/rspack/clientWebpackConfig.js", base_client_webpack_content)
end

# Simulates config/shakapacker.yml configured for rspack.
# This makes rspack_configured_in_project? return true for standalone generators
# that detect the bundler via YAML (RscGenerator, ProGenerator).
def simulate_rspack_shakapacker_yml
  simulate_existing_file("config/shakapacker.yml", <<~YAML)
    default: &default
      source_path: app/javascript
      assets_bundler: rspack
    development:
      <<: *default
    test:
      <<: *default
    production:
      <<: *default
  YAML
end

# -- fixture data, not logic
def base_server_webpack_content
  <<~JS
    const { merge, config } = require('shakapacker');
    const commonWebpackConfig = require('./commonWebpackConfig');

    const bundler = config.assets_bundler === 'rspack'
      ? require('@rspack/core')
      : require('webpack');

    const configureServer = () => {
      const serverWebpackConfig = commonWebpackConfig();

      serverWebpackConfig.output = {
        filename: 'server-bundle.js',
        globalObject: 'this',
        // If using the React on Rails Pro node server renderer, uncomment the next line
        // libraryTarget: 'commonjs2',
        path: serverBundleOutputPath,
      };

      serverWebpackConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));

      const rules = serverWebpackConfig.module.rules;
      rules.forEach((rule) => {
        if (Array.isArray(rule.use)) {
          const cssLoader = rule.use.find((item) => {
            let testValue = '';
            if (typeof item === 'string') {
              testValue = item;
            } else if (item && typeof item.loader === 'string') {
              testValue = item.loader;
            }
            return testValue.includes('css-loader');
          });
          if (cssLoader && cssLoader.options && cssLoader.options.modules) {
            cssLoader.options.modules = {
              ...(typeof cssLoader.options.modules === 'object' ? cssLoader.options.modules : {}),
              exportOnlyLocals: true,
            };
          }
        }
      });

      serverWebpackConfig.devtool = 'eval';

      // If using the default 'web', then libraries like Emotion and loadable-components
      // break with SSR. The fix is to use a node renderer and change the target.
      // If using the React on Rails Pro node server renderer, uncomment the next line
      // serverWebpackConfig.target = 'node'

      return serverWebpackConfig;
    };

    module.exports = configureServer;
  JS
end

def pro_server_webpack_content
  <<~JS
    const { merge, config } = require('shakapacker');
    const commonWebpackConfig = require('./commonWebpackConfig');

    const bundler = config.assets_bundler === 'rspack'
      ? require('@rspack/core')
      : require('webpack');

    function extractLoader(rule, loaderName) {
      if (!Array.isArray(rule.use)) return null;
      return rule.use.find((item) => {
        const testValue = typeof item === 'string' ? item : item.loader;
        return testValue && testValue.includes(loaderName);
      });
    }

    const configureServer = () => {
      const serverWebpackConfig = commonWebpackConfig();

      serverWebpackConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));

      serverWebpackConfig.target = 'node';
      serverWebpackConfig.node = false;

      return serverWebpackConfig;
    };

    module.exports = {
      default: configureServer,
      extractLoader,
    };
  JS
end

def legacy_pro_server_webpack_content
  <<~JS
    const { merge, config } = require('shakapacker');
    const commonWebpackConfig = require('./commonWebpackConfig');

    const bundler = config.assets_bundler === 'rspack'
      ? require('@rspack/core')
      : require('webpack');

    const configureServer = () => {
      const serverWebpackConfig = commonWebpackConfig();

      serverWebpackConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));
      serverWebpackConfig.target = 'node';
      serverWebpackConfig.node = false;

      return serverWebpackConfig;
    };

    module.exports = configureServer;
  JS
end

def server_client_or_both_content(destructured_import:)
  import_line = if destructured_import
                  "const { default: serverWebpackConfig } = require('./serverWebpackConfig');"
                else
                  "const serverWebpackConfig = require('./serverWebpackConfig');"
                end

  <<~JS
    const clientWebpackConfig = require('./clientWebpackConfig');
    #{import_line}

    const serverClientOrBoth = (envSpecific) => {
      const clientConfig = clientWebpackConfig();
      const serverConfig = serverWebpackConfig();

      if (envSpecific) {
        envSpecific(clientConfig, serverConfig);
      }

      let result;
      if (process.env.WEBPACK_SERVE || process.env.CLIENT_BUNDLE_ONLY) {
        // eslint-disable-next-line no-console
        console.log('[React on Rails] Creating only the client bundles.');
        result = clientConfig;
      } else if (process.env.SERVER_BUNDLE_ONLY) {
        // eslint-disable-next-line no-console
        console.log('[React on Rails] Creating only the server bundle.');
        result = serverConfig;
      } else {
        // default is the standard client and server build
        // eslint-disable-next-line no-console
        console.log('[React on Rails] Creating both client and server bundles.');
        result = [clientConfig, serverConfig];
      }

      return result;
    };

    module.exports = serverClientOrBoth;
  JS
end

def base_client_webpack_content
  <<~JS
    const commonWebpackConfig = require('./commonWebpackConfig');

    const configureClient = () => {
      const clientConfig = commonWebpackConfig();
      delete clientConfig.entry['server-bundle'];

      return clientConfig;
    };

    module.exports = configureClient;
  JS
end
