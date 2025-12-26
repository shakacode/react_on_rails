# frozen_string_literal: true

require "json"
require "digest"
require "fileutils"

module ReactOnRailsPro
  # Caches fetched license tokens to disk.
  # Persists across app restarts to reduce API calls.
  # Validates that cached token belongs to the currently configured license_key.
  class LicenseCache
    CACHE_FILENAME = "react_on_rails_pro_license.cache"

    class << self
      def read
        return nil unless cache_path.exist?

        data = JSON.parse(File.read(cache_path))

        return nil unless valid_for_current_key?(data)

        data
      rescue JSON::ParserError, Errno::ENOENT
        nil
      end

      def write(data)
        FileUtils.mkdir_p(cache_dir)

        cache_data = data.merge(
          "license_key_hash" => current_key_hash,
          "fetched_at" => Time.now.iso8601
        )

        File.write(cache_path, JSON.pretty_generate(cache_data))
        File.chmod(0o600, cache_path)
      rescue StandardError => e
        Rails.logger.warn { "[ReactOnRailsPro] Failed to write license cache: #{e.message}" }
      end

      def token
        read&.dig("token")
      end

      def fetched_at
        timestamp = read&.dig("fetched_at")
        Time.parse(timestamp) if timestamp
      rescue ArgumentError
        nil
      end

      def expires_at
        timestamp = read&.dig("expires_at")
        Time.parse(timestamp) if timestamp
      rescue ArgumentError
        nil
      end

      private

      def valid_for_current_key?(data)
        stored_hash = data["license_key_hash"]
        return false if stored_hash.nil?

        stored_hash == current_key_hash
      end

      def current_key_hash
        key = ReactOnRailsPro.configuration.license_key
        return nil if key.nil?

        Digest::SHA256.hexdigest(key)[0..15]
      end

      def cache_dir
        Rails.root.join("tmp")
      end

      def cache_path
        cache_dir.join(CACHE_FILENAME)
      end
    end
  end
end
