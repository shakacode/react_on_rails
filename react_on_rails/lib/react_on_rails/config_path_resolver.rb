# frozen_string_literal: true

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

    private

    def resolved_package_json_path
      node_modules_location = ReactOnRails.configuration.node_modules_location.to_s
      return "package.json" if node_modules_location.empty? || node_modules_location == Rails.root.to_s

      Rails.root.join(node_modules_location, "package.json").to_s
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
          [
            File.join(shakapacker_config_dir, "webpack.config.#{ext}"),
            File.join(shakapacker_config_dir, "rspack.config.#{ext}")
          ]
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
      return @shakapacker_assets_bundler_config_path if defined?(@shakapacker_assets_bundler_config_path)

      @shakapacker_assets_bundler_config_path = begin
        require "shakapacker"
        path = Shakapacker.config.assets_bundler_config_path.to_s
        if path.empty?
          nil
        else
          rails_root = Rails.root.to_s
          if rails_root.empty? || rails_root == "/"
            path
          else
            rails_root_prefix = "#{rails_root}/"
            normalized_path = path.start_with?(rails_root_prefix) ? path.delete_prefix(rails_root_prefix) : path
            normalized_path.empty? ? nil : normalized_path
          end
        end
      rescue LoadError, StandardError
        # Doctor/install checks should degrade gracefully when Shakapacker is
        # missing or partially configured; callers fall back to discovered
        # default config candidates when this cannot be resolved.
        nil
      end
    end

    def bundler_config_directory(config_path)
      return nil unless config_path

      directory = File.dirname(config_path)
      directory == "." ? nil : directory
    end
  end
end
