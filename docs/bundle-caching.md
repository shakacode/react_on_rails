# Bundle Caching

## Why?
Building webpack bundles is often time-consuming, and the same bundles are built many times.
For example, you might build the production bundles during CI, then for a Review app, then
for Staging, and maybe even for Production. Or you might want to deploy a small Ruby only
change to production, but you will have to wait minutes for your bundles to be built again.

## Solution
React on Rails 2.1.0 introduces bundle caching based on a digest of all the source files, defined
in the `config/webpacker.yml` file, plus other files defined with `config.dependency_globs` and
excluding any files from `config.excluded_dependency_globs`. Creating this hash key takes at most a
few seconds for even large projects. Additionally, the cache key takes into account the NODE_ENV and
the RAILS_ENV.

This cache key is used for saving files to some remote storage, typically S3.

## Configuration

### 1. React on Rails Configuration
First, we need to tell React on Rails to use a custom build module. In
`config/initializers/react_on_rails`, set this value:

```ruby
config.build_production_command = ReactOnRailsPro::AssetsPrecompile
```

### 2. React on Rails Pro Configuration
Next, we need to configure the `config/initializers/react_on_rails_pro.rb` with some module,
say called S3BundleCacheAdapter.

```
config.remote_bundle_cache_adapter = S3BundleCacheAdapter
```

This module needs three class methods: `build`, `fetch`, `upload`. See two examples of this below.

## Disabling via an ENV value
Once configured for bundle caching, ReactOnRailsPro::AssetsPrecompile's caching functionality
can be disabled by setting ENV["DISABLE_PRECOMPILE_CACHE"] equal to "true"

### Examples of `remote_bundle_cache_adapter`:

#### S3BundleCacheAdapter
Example of a module for custom methods for the `remote_bundle_cache_adapter`.

Note, S3UploadService is your own code that fetches and uploads.

```ruby
class S3BundleCacheAdapter
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
