# frozen_string_literal: true

module ReactOnRails
  module ConfigPathResolver
    private

    def resolved_package_json_path
      node_modules_location = ReactOnRails.configuration.node_modules_location.to_s
      return "package.json" if node_modules_location.empty? || node_modules_location == Rails.root.to_s

      Rails.root.join(node_modules_location, "package.json").to_s
    end

    def resolved_webpack_config_path
      webpack_config_candidates.find { |path| File.exist?(path) }
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

      candidates << "config/webpack/webpack.config.js"
      candidates << "config/webpack/webpack.config.ts"
      candidates << "config/rspack/rspack.config.js"
      candidates << "config/rspack/rspack.config.ts"
      candidates.uniq
    end

    def shakapacker_assets_bundler_config_path
      require "shakapacker"
      path = Shakapacker.config.assets_bundler_config_path.to_s
      return nil if path.empty?

      rails_root = Rails.root.to_s
      path.start_with?("#{rails_root}/") ? path.sub("#{rails_root}/", "") : path
    rescue LoadError, StandardError
      nil
    end

    def shakapacker_webpack_config_directory(config_path = nil)
      path = config_path || shakapacker_assets_bundler_config_path
      return nil unless path

      File.dirname(path)
    end
  end
end
