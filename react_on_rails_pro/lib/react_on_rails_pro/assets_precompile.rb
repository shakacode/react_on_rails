# frozen_string_literal: true

module ReactOnRailsPro
  class AssetsPrecompile # rubocop:disable Metrics/ClassLength
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
          cache_dependencies = [Shakapacker.config.source_path.join("**", "*")]
                               .union(ReactOnRailsPro.configuration.dependency_globs)
          # Note, digest_of_globs removes excluded globs
          digest = ReactOnRailsPro::Utils.digest_of_globs(cache_dependencies)
          # Include the NODE_ENV in the digest
          env_cache_keys = [
            ReactOnRailsPro::VERSION,
            ENV.fetch("RAILS_ENV", nil),
            ENV.fetch("NODE_ENV", nil)
          ]

          if remote_bundle_cache_adapter.respond_to?(:cache_keys)
            env_cache_keys += remote_bundle_cache_adapter.cache_keys
          end
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

      ReactOnRailsPro::PrepareNodeRenderBundles.call if ReactOnRailsPro.configuration.node_renderer?
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
        message = "An error was raised by the custom config.remote_bundle_cache_adapter 'fetch' " \
                  "method when called with { zipped_bundles_filename: #{zipped_bundles_filename} }"
        ReactOnRailsPro::Utils.rorp_puts message
        raise
      end

      if fetch_result
        ReactOnRailsPro::Utils.rorp_puts "Remote bundle cache detected. Bundles will be restored to local cache."
        File.binwrite(zipped_bundles_filepath, fetch_result)
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
        public_output_path = Shakapacker.config.public_output_path
        FileUtils.mkdir_p(public_output_path)
        Dir.chdir(public_output_path) do
          Rake.sh "tar -xzf #{zipped_bundles_filepath}"
        end

        ReactOnRailsPro::Utils.rorp_puts "gunzipped bundle cache: #{zipped_bundles_filepath} to #{public_output_path}"

        extract_extra_files_from_cache_dir
      end
      result
    end

    def extra_files_path
      Rails.root.join(Shakapacker.config.public_output_path, "extra_files")
    end

    def copy_extra_files_to_cache_dir
      return unless remote_bundle_cache_adapter.respond_to?(:extra_files_to_cache)

      FileUtils.mkdir_p(extra_files_path)
      copied_extra_files_paths = []

      remote_bundle_cache_adapter.extra_files_to_cache.each do |file_path|
        if file_path.file?
          copy_file_to_extra_files_cache_dir(file_path)
          copied_extra_files_paths.push(file_path.relative_path_from(Rails.root).to_s)
        else
          ReactOnRailsPro::Utils.rorp_puts "Extra file: #{file_path}, doesn't exist. Skipping"
        end
      end

      ReactOnRailsPro::Utils.rorp_puts "Copied extra files: #{copied_extra_files_paths.join(', ')} " \
                                       "to extra_files cache dir"
    end

    def copy_file_to_extra_files_cache_dir(source_path)
      destination_file_path = convert_to_destination(source_path)
      FileUtils.cp(source_path, destination_file_path)
    end

    def convert_to_destination(source)
      new_file_name = source.relative_path_from(Rails.root).each_filename.to_a.join("---")
      extra_files_path.join(new_file_name)
    end

    def extract_extra_files_from_cache_dir
      return unless File.exist?(extra_files_path)

      extracted_extra_files_paths = []
      Dir.each_child(extra_files_path) do |file_name|
        file_path_parts = file_name.split("---")
        source_file_path = extra_files_path.join(file_name)
        destination_file_path = Rails.root.join(*file_path_parts)
        FileUtils.mv(source_file_path, destination_file_path)
        extracted_extra_files_paths.push(destination_file_path.relative_path_from(Rails.root).to_s)
      end

      ReactOnRailsPro::Utils.rorp_puts "Extracted extra files: #{extracted_extra_files_paths.join(', ')} " \
                                       "from extra_files cache dir"
      remove_extra_files_cache_dir
    end

    def cache_bundles
      begin
        copy_extra_files_to_cache_dir
        public_output_path = Shakapacker.config.public_output_path
        ReactOnRailsPro::Utils.rorp_puts "Gzipping built bundles to #{zipped_bundles_filepath} with " \
                                         "files in #{public_output_path}"
        Dir.chdir(public_output_path) do
          Rake.sh "tar -czf #{zipped_bundles_filepath} --auto-compress -C " \
                  "#{Shakapacker.config.public_output_path} ."
        end
      rescue StandardError => e
        ReactOnRailsPro::Utils.rorp_puts "An error occurred while attempting to zip the built bundles."
        ReactOnRailsPro::Utils.rorp_puts e.message
        puts e.backtrace.join('\n')
      ensure
        remove_extra_files_cache_dir
      end

      ReactOnRailsPro::Utils.rorp_puts "Bundles will be uploaded to remote bundle cache as #{zipped_bundles_filename}"

      begin
        remote_bundle_cache_adapter.upload(zipped_bundles_filepath)
      rescue RuntimeError
        message = "An error was raised by the custom config.remote_bundle_cache_adapter 'upload' " \
                  "method when called with zipped_bundles_filepath: #{zipped_bundles_filepath}"
        ReactOnRailsPro::Utils.rorp_puts message
        raise
      end
    end

    def remove_extra_files_cache_dir
      FileUtils.rm_f(extra_files_path)
    end
  end
end
