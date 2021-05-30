# frozen_string_literal: true

module ReactOnRailsPro
  class AssetsPrecompile
    include Singleton

    def remote_bundle_cache_adapter
      unless ReactOnRailsPro.configuration.remote_bundle_cache_adapter.is_a?(Module)
        raise ReactOnRailsPro::Error, "config.remote_bundle_cache_adapter must have a module assigned"
      end

      ReactOnRailsPro.configuration.remote_bundle_cache_adapter
    end

    def zipped_bundles_filename
      "precompile-cache.#{bundles_cache_key}.production.gz"
    end

    def zipped_bundles_filepath
      @zipped_bundles_filepath ||=
        begin
          FileUtils.mkdir_p(Rails.root.join("tmp", "bundle_cache"))
          Rails.root.join("tmp", "bundle_cache", zipped_bundles_filename)
        end
    end

    def bundles_cache_key
      @bundles_cache_key ||=
        begin
          ReactOnRailsPro::Utils.rorp_puts "Calculating digest of bundle dependencies."
          starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          cache_dependencies = [Webpacker.config.source_path.join("**", "*")]
                               .union(ReactOnRailsPro.configuration.dependency_globs)
          # Note, digest_of_globs removes excluded globs
          digest = ReactOnRailsPro::Utils.digest_of_globs(cache_dependencies)
          # Include the NODE_ENV and RAILS_ENV in the digest
          env_cache_keys = [
            ReactOnRailsPro::VERSION,
            ENV["NODE_ENV"]
          ]
          env_cache_keys += remote_bundle_cache_adapter.cache_keys
          env_cache_keys.compact.each { |value| digest.update(value) }

          result = digest.hexdigest
          ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          elapsed = (ending - starting).round(2)
          ReactOnRailsPro::Utils.rorp_puts "Completed calculating digest of bundle dependencies in #{elapsed} seconds."
          result
        end
    end

    def build_bundles
      remote_bundle_cache_adapter.build
    rescue RuntimeError
      ReactOnRailsPro::Utils.rorp_puts "The custom config.remote_bundle_cache_adapter 'build' method raised an error:"
      raise
    end

    def self.call
      instance.build_or_fetch_bundles
    end

    def build_or_fetch_bundles
      if disable_precompile_cache?
        build_bundles
        return
      end

      begin
        bundles_fetched = fetch_and_unzip_cached_bundles
      rescue RuntimeError => e
        ReactOnRailsPro::Utils.rorp_puts "An error occurred while attempting to fetch cached bundles."
        ReactOnRailsPro::Utils.rorp_puts "This will be evaluated as a bundle cache miss."
        ReactOnRailsPro::Utils.rorp_puts e.message
        puts e.backtrace.join('\n')
        bundles_fetched = false
      end

      return if bundles_fetched

      build_bundles

      begin
        cache_bundles
      rescue RuntimeError => e
        ReactOnRailsPro::Utils.rorp_puts "An error occurred while attempting to cache the built bundles."
        ReactOnRailsPro::Utils.rorp_puts e.message
        puts e.backtrace.join('\n')
      end
    end

    def disable_precompile_cache?
      ENV["DISABLE_PRECOMPILE_CACHE"] == "true"
    end

    def fetch_bundles
      ReactOnRailsPro::Utils.rorp_puts "Checking for a cached bundle: #{zipped_bundles_filename}"
      begin
        fetch_result = remote_bundle_cache_adapter.fetch(zipped_bundles_filename)
      rescue RuntimeError
        message = "An error was raised by the custom config.remote_bundle_cache_adapter 'fetch'"\
                  " method when called with { zipped_bundles_filename: #{zipped_bundles_filename} }"
        ReactOnRailsPro::Utils.rorp_puts message
        raise
      end

      if fetch_result
        ReactOnRailsPro::Utils.rorp_puts "Remote bundle cache detected. Bundles will be restored to local cache."
        File.open(zipped_bundles_filepath, "wb") { |file| file.write(fetch_result) }
        true
      else
        ReactOnRailsPro::Utils.rorp_puts "Remote bundle cache not found."
        false
      end
    end

    def fetch_and_unzip_cached_bundles
      if File.exist?(zipped_bundles_filepath)
        ReactOnRailsPro::Utils.rorp_puts "Found a local cache of bundles: #{zipped_bundles_filepath}"
        result = true
      else
        result = fetch_bundles
      end

      if File.exist?(zipped_bundles_filepath)
        ReactOnRailsPro::Utils.rorp_puts "gunzipping bundle cache: #{zipped_bundles_filepath}"
        public_output_path = Webpacker.config.public_output_path
        FileUtils.mkdir_p(public_output_path)
        Dir.chdir(public_output_path) do
          Rake.sh "tar -xzf #{zipped_bundles_filepath}"
        end
        ReactOnRailsPro::Utils.rorp_puts "gunzipped bundle cache: #{zipped_bundles_filepath} to #{public_output_path}"
      end
      result
    end

    def cache_bundles
      public_output_path = Webpacker.config.public_output_path
      ReactOnRailsPro::Utils.rorp_puts "Gzipping built bundles to #{zipped_bundles_filepath} with "\
        "files in #{public_output_path}"
      Dir.chdir(public_output_path) do
        Rake.sh "tar -czf #{zipped_bundles_filepath} --auto-compress -C "\
                "#{Webpacker.config.public_output_path} ."
      end
      ReactOnRailsPro::Utils.rorp_puts "Bundles will be uploaded to remote bundle cache as #{zipped_bundles_filename}"
      begin
        remote_bundle_cache_adapter.upload(zipped_bundles_filepath)
      rescue RuntimeError
        message = "An error was raised by the custom config.remote_bundle_cache_adapter 'upload'"\
                  " method when called with zipped_bundles_filepath: #{zipped_bundles_filepath}"
        ReactOnRailsPro::Utils.rorp_puts message
        raise
      end
    end
  end
end
