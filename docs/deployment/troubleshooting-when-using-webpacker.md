## Context

Rails: 5.0.2
react_on_rails: upgraded from 6.6.0 to 9.0.3

## The failure

Rspec failing with

```text
Failure/Error: raise Webpacker::Manifest::MissingEntryError, missing_file_from_manifest_error(name)

     Webpacker::Manifest::MissingEntryError:
       Webpacker can't find webpack-bundle.js in /home/user/ws/pp/code/pp-core-checkout_spa_update_npm/public/webpack-test/manifest.json. Possible causes:
       1. You want to set webpacker.yml value of compile to true for your environment
          unless you are using the `webpack -w` or the webpack-dev-server.
       2. Webpack has not yet re-run to reflect updates.
       3. You have misconfigured Webpacker's config/webpacker.yml file.
       4. Your Webpack configuration is not creating a manifest.
       Your manifest contains:
       {
         "main.css": "/webpack-test/main-bundle.css",
         "main.js": "/webpack-test/main-dde0e05a2817931424c3.js"
       }
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/webpacker-3.0.1/lib/webpacker/manifest.rb:44:in `handle_missing_entry'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/webpacker-3.0.1/lib/webpacker/manifest.rb:40:in `find'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/webpacker-3.0.1/lib/webpacker/manifest.rb:27:in `lookup'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/utils.rb:145:in `bundle_js_file_path_from_webpacker'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/utils.rb:90:in `bundle_js_file_path'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper/webpack_assets_status_checker.rb:56:in `block in all_compiled_assets'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper/webpack_assets_status_checker.rb:55:in `map'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper/webpack_assets_status_checker.rb:55:in `all_compiled_assets'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper/webpack_assets_status_checker.rb:35:in `stale_generated_webpack_files'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper/ensure_assets_compiled.rb:34:in `call'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper.rb:85:in `ensure_assets_compiled'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper.rb:39:in `block (2 levels) in configure_rspec_to_compile_assets'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/rspec-core-3.5.4/lib/rspec/core/example.rb:443:in `instance_exec'
...
```

At the same time, dev/prod environments work fine (with extra Webpack calling step outside Rails).

## Configs

### webpack.config.js

See [Shakapacker Webpack Configuration](https://github.com/shakacode/shakapacker/blob/master/README.md#webpack-configuration).

### config/webpacker.yml

is default from sample application v9.x

### config/initializers/react_on_rails.rb

```ruby
  ...
  # Define the files we need to check for webpack compilation when running tests.
  config.webpack_generated_files = %w( webpack-bundle.js main-bundle.css )
  ...
```

## The problem

When `ReactOnRails.configuration.webpack_generated_files` is specified, it prevents usage of `manifest.json`

## Solution

Removing of `config.webpack_generated_files` from `config/initializers/react_on_rails.rb` resolving issue.
