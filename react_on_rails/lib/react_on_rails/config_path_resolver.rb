# frozen_string_literal: true

module ReactOnRails
  module ConfigPathResolver
    private

    def resolved_package_json_path
      node_modules_location = ReactOnRails.configuration.node_modules_location.to_s
      return "package.json" if node_modules_location.empty? || node_modules_location == Rails.root.to_s

      File.join(node_modules_location, "package.json")
    rescue StandardError
      "package.json"
    end

    def resolved_webpack_config_path
      webpack_config_candidates.find { |path| File.exist?(path) }
    end

    def webpack_config_candidates
      candidates = ["config/webpack/webpack.config.js"]

      shakapacker_config_dir = shakapacker_webpack_config_directory
      if shakapacker_config_dir
        candidates.concat(%w[js ts cjs mjs].map { |ext| File.join(shakapacker_config_dir, "webpack.config.#{ext}") })
      end

      candidates.concat(Dir.glob("config/**/webpack.config.{js,ts,cjs,mjs}"))
      candidates.uniq
    end

    def shakapacker_webpack_config_directory
      require "shakapacker"
      path = Shakapacker.config.assets_bundler_config_path.to_s
      return nil if path.empty?

      rails_root = Rails.root.to_s
      path.start_with?("#{rails_root}/") ? path.sub("#{rails_root}/", "") : path
    rescue LoadError, StandardError
      nil
    end
  end
end
