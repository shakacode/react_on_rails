# frozen_string_literal: true

require "httpx"

module ReactOnRailsPro
  module RSCCache
    # Revalidates a cache tag on the node renderer, causing all cached RSC
    # fragments associated with that tag to be evicted across all workers.
    #
    # @param tag [String] The cache tag to invalidate
    # @raise [ReactOnRailsPro::Error] if the node renderer is unreachable or returns an error
    def self.revalidate_tag(tag)
      config = ReactOnRailsPro.configuration
      url = "#{config.renderer_url}/cache/revalidate-tag"

      body = { "tag" => tag }
      body["password"] = config.renderer_password if config.renderer_password.present?

      response = HTTPX.post(url, form: body)
      error = response.error

      if error
        raise ReactOnRailsPro::Error,
              "[ReactOnRailsPro] Failed to revalidate cache tag '#{tag}' on the node renderer " \
              "at #{config.renderer_url}: #{error.message}"
      end

      unless response.status == 200
        raise ReactOnRailsPro::Error,
              "[ReactOnRailsPro] Failed to revalidate cache tag '#{tag}' on the node renderer " \
              "at #{config.renderer_url}: HTTP #{response.status}"
      end

      Rails.logger.info { "[ReactOnRailsPro] Revalidated cache tag '#{tag}' on node renderer" }
      true
    end
  end
end
