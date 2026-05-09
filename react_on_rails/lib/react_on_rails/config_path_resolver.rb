# frozen_string_literal: true

require "set"

module ReactOnRails
  module ConfigPathResolver
    # Keep JS before TS to match generator defaults and to prefer the
    # JavaScript config deterministically when both variants are present.
    WEBPACK_DEFAULT_CONFIG_CANDIDATES = %w[
      config/webpack/webpack.config.js
      config/webpack/webpack.config.ts
    ].freeze
    RSPACK_DEFAULT_CONFIG_CANDIDATES = %w[
      config/rspack/rspack.config.js
      config/rspack/rspack.config.ts
    ].freeze
    ALL_DEFAULT_CONFIG_CANDIDATES = (WEBPACK_DEFAULT_CONFIG_CANDIDATES + RSPACK_DEFAULT_CONFIG_CANDIDATES).freeze

    # Public so Doctor can delegate to a SystemChecker instance and share the
    # same warning de-dupe registry across resolver callers.
    def config_path_warning_registry
      @config_path_warning_registry ||= {
        package_roots: Set.new,
        package_json_paths: Set.new
      }
    end

    private

    def resolved_package_json_path(package_root = resolved_package_root)
      resolved_package_path("package.json", package_root)
    end

    def resolved_package_root
      node_modules_location = ReactOnRails.configuration.node_modules_location.to_s

      resolved_location = Pathname.new(node_modules_location).cleanpath
      # cleanpath normalizes redundant separators and ".." without resolving symlinks;
      # realpath is intentionally skipped to avoid filesystem I/O on every call.
      # Relative paths like "../client" remain valid diagnostics targets and are
      # not constrained to stay within Rails.root.
      return Rails.root.to_s if resolved_location == Pathname.new(".")
      return resolved_location.to_s if resolved_location.absolute?

      Rails.root.join(resolved_location).to_s
    end

    def resolved_package_path(filename, package_root = resolved_package_root)
      File.join(package_root, filename)
    end

    def package_root_missing?(package_root)
      !Dir.exist?(package_root)
    end

    def package_json_path_for(detection_target, package_root = resolved_package_root)
      package_json_path = resolved_package_json_path(package_root)
      return package_json_path if File.exist?(package_json_path)

      if package_root_missing?(package_root)
        warn_missing_package_root(package_root)
      else
        warn_missing_package_json(package_json_path, detection_target)
      end
      nil
    end

    # Including classes must provide #add_warning(message). Classes that route
    # warnings into another object's message list can override
    # #config_path_warning_registry to share de-dupe state with that sink.
    # Overrides must return a Hash with :package_roots and :package_json_paths
    # keys whose values respond to #add?, such as Set instances.
    def warn_missing_package_root(package_root)
      return unless warned_package_roots.add?(package_root)

      add_config_path_warning(missing_package_root_warning(package_root))
    end

    def missing_package_root_warning(package_root)
      "⚠️  node_modules_location points to #{package_root}, but that directory does not exist; " \
        "all diagnostics that read from it are skipped. Check config/initializers/react_on_rails.rb."
    end

    def warn_missing_package_json(package_json_path, detection_target)
      return unless warned_package_json_paths.add?(package_json_path)

      add_config_path_warning(missing_package_json_warning(package_json_path, detection_target))
    end

    def missing_package_json_warning(package_json_path, detection_target)
      "⚠️  #{package_json_path} not found; cannot detect #{detection_target}. " \
        "Check config/initializers/react_on_rails.rb."
    end

    def warned_package_roots
      config_path_warning_registry[:package_roots]
    end

    def warned_package_json_paths
      config_path_warning_registry[:package_json_paths]
    end

    def add_config_path_warning(message)
      unless respond_to?(:add_warning, true)
        raise NoMethodError,
              "#{self.class} must implement #add_warning(message) to include ReactOnRails::ConfigPathResolver"
      end

      add_warning(message)
    end

    def resolved_webpack_config_path
      webpack_config_candidates.find { |path| File.file?(path) }
    end

    def webpack_config_candidates
      candidates = []
      shakapacker_config_path = shakapacker_assets_bundler_config_path
      candidates << shakapacker_config_path if shakapacker_config_path

      shakapacker_config_dir = bundler_config_directory(shakapacker_config_path)
      if shakapacker_config_dir
        candidates.concat(%w[js ts cjs mjs].flat_map do |ext|
          # Skip only the exact shakapacker path; still probe sibling
          # standard-name configs (for example rspack when shakapacker points to
          # webpack in the same directory).
          [
            File.join(shakapacker_config_dir, "webpack.config.#{ext}"),
            File.join(shakapacker_config_dir, "rspack.config.#{ext}")
          ].reject { |path| path == shakapacker_config_path }
        end)
      end

      # Default fallback candidates intentionally mirror generator defaults
      # (`.js` / `.ts`), while `.cjs` / `.mjs` are probed only within resolved
      # shakapacker config directories above.
      candidates.concat(WEBPACK_DEFAULT_CONFIG_CANDIDATES)
      candidates.concat(RSPACK_DEFAULT_CONFIG_CANDIDATES)
      candidates.uniq
    end

    def shakapacker_assets_bundler_config_path
      # Use instance_variable_defined? instead of ||= so nil results are cached
      # and we do not retry require/rescue work on each call.
      if instance_variable_defined?(:@shakapacker_assets_bundler_config_path)
        return @shakapacker_assets_bundler_config_path
      end

      require "shakapacker"
      @shakapacker_assets_bundler_config_path = normalize_shakapacker_assets_bundler_config_path(
        Shakapacker.config.assets_bundler_config_path.to_s
      )
    rescue LoadError, NameError
      # Doctor/install checks should degrade gracefully when Shakapacker is
      # missing; callers fall back to discovered default config candidates.
      @shakapacker_assets_bundler_config_path = nil
    rescue StandardError => e
      message = "ReactOnRails could not read Shakapacker assets_bundler_config_path: #{e.class}: #{e.message}"
      warn(message) unless Rails.logger
      Rails.logger&.debug do
        message
      end
      @shakapacker_assets_bundler_config_path = nil
    end

    def normalize_shakapacker_assets_bundler_config_path(path)
      return nil if path.empty?

      rails_root = Rails.root.to_s
      return path if rails_root.empty? || rails_root == "/"

      # NOTE: Prefix normalization assumes matching separators and does not
      # normalize Windows-style `\` vs `/` path variants.
      rails_root_prefix = "#{rails_root}/"
      normalized_path = path.start_with?(rails_root_prefix) ? path.delete_prefix(rails_root_prefix) : path
      normalized_path.empty? ? nil : normalized_path
    end

    def bundler_config_directory(config_path)
      return nil unless config_path

      directory = File.dirname(config_path)
      directory == "." ? nil : directory
    end
  end
end
