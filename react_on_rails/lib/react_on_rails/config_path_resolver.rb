# frozen_string_literal: true

module ReactOnRails
  module ConfigPathResolver
    WEBPACK_CONFIG_CANDIDATE_PATHS = %w[
      config/webpack/webpack.config.js
      config/webpack/webpack.config.ts
    ].freeze
    RSPACK_CONFIG_CANDIDATE_PATHS = %w[
      config/rspack/rspack.config.js
      config/rspack/rspack.config.ts
    ].freeze
    DEFAULT_BUNDLER_CONFIG_CANDIDATE_PATHS = (
      WEBPACK_CONFIG_CANDIDATE_PATHS + RSPACK_CONFIG_CANDIDATE_PATHS
    ).freeze

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

      shakapacker_config_dir = shakapacker_webpack_config_directory(shakapacker_config_path)
      if shakapacker_config_dir
        candidates.concat(%w[js ts cjs mjs].flat_map do |ext|
          [
            File.join(shakapacker_config_dir, "webpack.config.#{ext}"),
            File.join(shakapacker_config_dir, "rspack.config.#{ext}")
          ]
        end)
      end

      candidates.concat(DEFAULT_BUNDLER_CONFIG_CANDIDATE_PATHS)
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
          if rails_root.empty? || rails_root == "/" || !path.start_with?("#{rails_root}/")
            path
          else
            path.sub("#{rails_root}/", "")
          end
        end
      rescue LoadError, StandardError
        nil
      end
    end

    def shakapacker_webpack_config_directory(config_path)
      return nil unless config_path

      directory = File.dirname(config_path)
      directory == "." ? nil : directory
    end
  end
end
