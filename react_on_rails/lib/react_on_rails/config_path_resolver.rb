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

      shakapacker_config_dir = shakapacker_webpack_config_directory
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

    def shakapacker_webpack_config_directory
      require "shakapacker"
      path = Shakapacker.config.assets_bundler_config_path.to_s
      return nil if path.empty?

      directory = File.dirname(path)
      rails_root = Rails.root.to_s
      directory.start_with?("#{rails_root}/") ? directory.sub("#{rails_root}/", "") : directory
    rescue LoadError, StandardError
      nil
    end
  end
end
