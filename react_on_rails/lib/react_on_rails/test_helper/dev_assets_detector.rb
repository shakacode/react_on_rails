# frozen_string_literal: true

require "json"
require "yaml"
require "erb"
require "pathname"

module ReactOnRails
  module TestHelper
    # Detects whether development webpack assets can be reused for tests,
    # avoiding redundant compilation when `bin/dev static` is already running.
    #
    # When `bin/dev static` runs webpack in watch mode, it writes compiled assets
    # to the development output directory (e.g., public/packs). If those assets
    # are fresh (newer than all source files) and not HMR artifacts, tests can
    # reuse them instead of running a separate build_test_command.
    #
    # This makes `bundle exec rspec` "just work" when `bin/dev static` is running,
    # with no environment variables or extra commands needed.
    class DevAssetsDetector
      class << self
        # Attempts to detect and activate development assets for test use.
        #
        # When successful:
        # - Overrides Shakapacker's test config to point at dev output
        # - Clears manifest cache so tests read the dev manifest
        # - Returns true
        #
        # When dev assets aren't usable (HMR mode, stale, missing):
        # - Returns false with no side effects
        def try_activate_dev_assets!
          detector = new
          result = detector.check
          return false unless result

          apply_shakapacker_override!(result)
          print_activation_message(result)
          true
        rescue StandardError => e
          warn "React on Rails: Dev asset detection failed: #{e.message}" if ENV["DEBUG"]
          false
        end

        private

        def apply_shakapacker_override!(result)
          config = ::Shakapacker.config

          # Replace the frozen data hash with one pointing test output at dev output
          new_data = config.send(:data).dup
          new_data[:public_output_path] = result[:dev_output_relative]
          config.instance_variable_set(:@data, new_data.freeze)

          # Clear cached manifest so it reloads from the new path
          shakapacker_instance = ::Shakapacker.instance
          return unless shakapacker_instance.instance_variable_defined?(:@manifest)

          shakapacker_instance.remove_instance_variable(:@manifest)
        end

        def print_activation_message(result)
          puts <<~MSG

            ====> React on Rails: Reusing development assets from #{result[:dev_output_relative]}
                  (detected fresh static-mode webpack output, skipping test compilation)

          MSG
        end
      end

      # Checks if development assets are reusable for tests.
      #
      # Returns a hash with dev output info if reusable, nil otherwise.
      def check
        shakapacker_yml = load_shakapacker_yml
        return nil unless shakapacker_yml

        dev_output_relative, dev_full_path = resolve_dev_output(shakapacker_yml)
        return nil unless dev_output_relative

        manifest_path = dev_full_path.join("manifest.json")
        return nil unless manifest_usable?(manifest_path)

        {
          dev_output_relative: dev_output_relative,
          dev_full_path: dev_full_path,
          manifest_path: manifest_path
        }
      end

      private

      def load_shakapacker_yml
        path = project_root.join("config", "shakapacker.yml")
        return nil unless path.exist?

        YAML.safe_load(ERB.new(path.read).result, permitted_classes: [Symbol])
      rescue StandardError => e
        warn "React on Rails: Could not parse shakapacker.yml: #{e.message}" if ENV["DEBUG"]
        nil
      end

      # Returns [dev_output_relative, dev_full_path] or nil if dev/test share the same path
      def resolve_dev_output(shakapacker_yml)
        dev_config = resolve_env_config(shakapacker_yml, "development")
        test_config = resolve_env_config(shakapacker_yml, "test")

        dev_output_relative = dev_config["public_output_path"] || "packs"
        test_output_relative = test_config["public_output_path"] || "packs"

        # If already using the same path, no override needed
        return nil if dev_output_relative == test_output_relative

        public_root = dev_config["public_root_path"] || "public"
        dev_full_path = project_root.join(public_root, dev_output_relative)

        [dev_output_relative, dev_full_path]
      end

      def manifest_usable?(manifest_path)
        manifest_path.exist? && !hmr_manifest?(manifest_path) && assets_fresh?(manifest_path)
      end

      def resolve_env_config(yml, env)
        default_config = yml["default"] || {}
        env_config = yml[env] || {}
        default_config.merge(env_config)
      end

      def project_root
        @project_root ||= if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
                            Rails.root
                          else
                            Pathname.new(Dir.pwd)
                          end
      end

      # HMR manifests contain URLs (http://localhost:3035/packs/...) instead of
      # relative paths (/packs/...). Tests can't use HMR assets because they're
      # served from webpack-dev-server's memory, not the filesystem.
      def hmr_manifest?(manifest_path)
        manifest = JSON.parse(File.read(manifest_path))
        manifest.values.any? { |v| v.to_s.match?(%r{\Ahttps?://}) }
      rescue JSON::ParserError
        true # Unparseable manifest is not usable
      end

      # Dev assets are fresh if the manifest is newer than all source files.
      # This matches the same mtime comparison used by WebpackAssetsStatusChecker.
      def assets_fresh?(manifest_path)
        source_path = ReactOnRails::Utils.source_path
        source_files = make_source_file_list(source_path)

        # No source files = nothing to compare against, consider fresh
        return true if source_files.empty?

        most_recent_source = source_files.map { |f| File.mtime(f) }.max
        manifest_mtime = File.mtime(manifest_path)

        manifest_mtime >= most_recent_source
      end

      def make_source_file_list(source_path)
        Dir.glob(File.join(source_path, "**", "*"))
           .reject { |f| f.include?("/node_modules/") || File.directory?(f) }
      end
    end
  end
end
