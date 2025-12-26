# Bundle Caching

## Why?

Building webpack bundles is often time-consuming, and the same bundles are built many times.
For example, you might build the production bundles during CI, then for a Review app, then
for Staging, and maybe even for Production. Or you might want to deploy a small Ruby only
change to production, but you will have to wait minutes for your bundles to be built again.

## Solution

React on Rails 2.1.0 introduces bundle caching based on a digest of all the source files, defined
in the `config/shakapacker.yml` file, plus other files defined with `config.dependency_globs` and
excluding any files from `config.excluded_dependency_globs`. Creating this hash key takes at most a
few seconds for even large projects. Additionally, the cache key includes

1. NODE_ENV
2. Version of React on Rails Pro
3. Configurable additional env values by supplying an array in method cache_keys on the `remote_bundle_cache_adapter`. See examples below.

This cache key is used for saving files to some remote storage, typically S3.

## Bonus for local development with multiple directories building production builds

Bundle caching can help save time if you have multiple directories for the same repository.

The bundles are cached in `Rails.root.join('tmp', 'bundle_cache')`

So, if you have sibling directories for the same project, you can make a sym link so both directories use the same bundle cache directory.

```
cd my_project2/tmp
ln -s ../../my_project/tmp/bundle_cache
```

## Configuration

### 1. React on Rails Configuration

First, we need to tell React on Rails to use a custom build module. In
`config/initializers/react_on_rails`, set this value:

```ruby
config.build_production_command = ReactOnRailsPro::AssetsPrecompile
```

Alternatively, if you need to run something after the files are built or extracted from the cache, you can do something like this:

```ruby
ReactOnRails.configure do |config|
  # This configures the script to run to build the production assets by webpack. Set this to nil
  # if you don't want react_on_rails building this file for you.
  config.build_production_command = CustomBuildCommand
end
```

And define it like this:

```ruby
module CustomBuildCommand
  def self.call
    ReactOnRailsPro::AssetsPrecompile.call
    Rake::Task['react_on_rails_pro:pre_stage_bundle_for_node_renderer'].invoke
  end
end
```

### 2. React on Rails Pro Configuration

Next, we need to configure the `config/initializers/react_on_rails_pro.rb` with some module,
say called S3BundleCacheAdapter.

```
config.remote_bundle_cache_adapter = S3BundleCacheAdapter
```

This module needs four class methods: `cache_keys` (optional), `build`, `fetch`, `upload`. See two
examples of this below.

Also, add whatever file the remote_bundle_cache_adapter module is defined in to `config.dependency_globs`.

If there are any other files for which changes should bust the fragment cache for
cached_react_component and cached_react_component_hash, add those as well to `config.dependency_globs`. This should include any files used to generate the JSON props, webpack and/or Shakapacker configuration files, and package lockfiles.

To simplify your configuration, entire directories can be added to `config.dependency_globs` & then any irrelevant files or subdirectories can be added to `config.excluded_dependency_globs`

For example:

```ruby
  config.dependency_globs = [ File.join(Rails.root, "app", "views", "**", "*.jbuilder") ]
  config.excluded_dependency_globs = [ File.join(Rails.root, "app", "views", "**", "dont_hash_this.jbuilder") ]
```

will hash all files in `app/views` that have the `jbuilder` extension except for any file named `dont_hash_this.jbuilder`.

The goal is that Ruby only changes that don't affect your webpack bundles don't change the cache keys, and anything that could affect the bundles MUST change the cache keys!

### 3. Remove any call to rake task `react_on_rails_pro:pre_stage_bundle_for_node_renderer`

This task is called automaticaly if you're using bundle caching.

```ruby
  Rake::Task['react_on_rails_pro:pre_stage_bundle_for_node_renderer'].invoke
```

#### Custom ENV cache keys

Check your webpack config for the webpack.DefinePlugin. That allows JS code to use
`process.env.MY_ENV_VAR` resulting in bundles that differ depending on the ENV value set.

Thus, if you access these `process.env.MY_ENV_VAR` in your JS code, then you need to include such
ENV vars in return value of the `cache keys` method.

A much better approach than accessing `process.env` is to use the
`config/initializers/react_on_rails.rb` setting for the`config.rendering_extension` to always
pass some values into the rendering props.

See [our railsContext docs](https://www.shakacode.com/react-on-rails/docs/basics/render-functions-and-railscontext/#customization-of-the-railscontext) for more details.

Also, if your webpack build process depends on any ENV values, then you will also need to add those
to return value of the `cache_keys` method.

Note, the NODE_ENV value is always included in the cache_keys.

Another use of the ENV values would be a cache version, so incrementing this ENV value
would force a new cache value.

## Disabling via an ENV value

Once configured for bundle caching, ReactOnRailsPro::AssetsPrecompile's caching functionality
can be disabled by setting ENV["DISABLE_PRECOMPILE_CACHE"] equal to "true"

### Examples of `remote_bundle_cache_adapter`:

#### S3BundleCacheAdapter

Example of a module for custom methods for the `remote_bundle_cache_adapter`.

Note, S3UploadService is your own code that fetches and uploads.

```ruby
class S3BundleCacheAdapter
  # Optional
  # return an Array of Strings that should get added to the cache key.
  # These are values to put in the cache key based on either using the webpack.DefinePlugin
  # or webpack compilation varying by the ENV values.
  # See the use of the webpack.DefinePlugin. That allows JS code to use
  # process.env.MY_ENV_VAR resulting in bundles that differ depending on the ENV value set
  # when building the bundles.
  # Note, NODE_ENV is automatically included in the default cache key.
  # Also, we can have an ENV value be a cache version, so incrementing this ENV value
  # would force a new cache value.
  def self.cache_keys
    [Rails.env, ENV['SOME_ENV_VALUE']]
  end

  # return value is unused
  # This command should build the bundles
  def self.build
    Rake.sh(ReactOnRails::Utils.prepend_cd_node_modules_directory('yarn start build.prod').to_s)
  end

  # parameter zipped_bundles_filename will be a string
  # should return the zipped file as a string if successful & nil if not
  def self.fetch(zipped_bundles_filename:)
    result = S3UploadService.new.fetch_object(zipped_bundles_filename)
    result.get.body.read if result
  end

  # Optional: method to return an array of extra files paths, that require caching.
  # These files get placed at the `extra_files` directory at the top of the zipfile
  # and are moved to the original places after unzipping the bundles.
  def self.extra_files_to_cache
      [ Rails.root.join("app", "javascript", "utils", "operationStore.json") ]
  end

  # parameter zipped_bundles_filepath will be a Pathname
  # return value is unused
  def self.upload(zipped_bundles_filepath:)
    return unless ENV['UPLOAD_BUNDLES_TO_S3'] == 'true'

    zipped_bundles_filename = zipped_bundles_filepath.basename.to_s
    puts "Bundles are being uploaded to s3 as #{zipped_bundles_filename}"
    starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    S3UploadService.new.upload_object(zipped_bundles_filename,
                                      File.read(zipped_bundles_filepath, mode: 'rb'),
                                      'application/zip', expiration_months: 12)
    ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = (ending - starting).round(2)
    puts "Bundles uploaded to s3 as #{zipped_bundles_filename} in #{elapsed} seconds"
  end
end
```

#### LocalBundleCacheAdapter

Example of a module for custom methods for the `remote_bundle_cache_adapter` that does not save files
remotely. Only local files are used.

```ruby
class LocalBundleCacheAdapter
  def self.cache_keys
    # if no additional cache keys, return an empty array
    []
  end

  def self.build
    Rake.sh(ReactOnRails::Utils.prepend_cd_node_modules_directory('yarn start build.prod').to_s)
  end

  def self.fetch(zipped_bundles_filename:)
    # no-op
  end

  def self.upload(zipped_bundles_filepath:)
    # no-op
  end
end
```
