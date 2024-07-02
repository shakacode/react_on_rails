# frozen_string_literal: true

require "net/http"
require "net/http/post/multipart"
require "uri"
require "persistent_http"

module ReactOnRailsPro
  class Request
    class << self
      def reset_connection
        @connection = create_connection
      end

      def render_code(path, js_code, send_bundle)
        Rails.logger.info { "[ReactOnRailsPro] Perform rendering request #{path}" }
        perform_request(path, form_with_code(js_code, send_bundle))
      end

      def upload_assets
        Rails.logger.info { "[ReactOnRailsPro] Uploading assets" }
        perform_request("/upload-assets", form_with_assets_and_bundle)
      end

      def asset_exists_on_vm_renderer?(filename)
        Rails.logger.info { "[ReactOnRailsPro] Sending request to check if file exist on node-renderer: #{filename}" }
        response = perform_request("/asset-exists?filename=#{filename}", common_form_data)
        JSON.parse(response.body)["exists"] == true
      end

      private

      def connection
        @connection ||= create_connection
      end

      def perform_request(path, form)
        available_retries = ReactOnRailsPro.configuration.renderer_request_retry_limit
        retry_request = true
        while retry_request
          begin
            response = connection.request(Net::HTTP::Post::Multipart.new(path, form))
            retry_request = false
          rescue Timeout::Error => e
            # Testing timeout catching:
            # https://github.com/shakacode/react_on_rails_pro/pull/136#issue-463421204
            if available_retries.zero?
              raise ReactOnRailsPro::Error, "Time out error when getting the response on: #{path}.\n" \
                                            "Original error:\n#{e}\n#{e.backtrace}"
            end
            Rails.logger.info do
              "[ReactOnRailsPro] Timed out trying to connect to the Node Renderer. " \
                "Retrying #{available_retries} more times..."
            end
            available_retries -= 1
            next
          rescue StandardError => e
            raise ReactOnRailsPro::Error, "Can't connect to NodeRenderer renderer: #{path}.\n" \
                                          "Original error:\n#{e}\n#{e.backtrace}"
          end
        end

        Rails.logger.info { "[ReactOnRailsPro] Node Renderer responded" }

        case response.code
        when "412"
          # 412 is a protocol error, meaning the server and renderer are running incompatible versions
          # of React on Rails.
          raise ReactOnRailsPro::Error, response.body
        else
          response
        end
      end

      def form_with_code(js_code, send_bundle)
        form = common_form_data
        form["renderingRequest"] = js_code
        if send_bundle
          renderer_bundle_file_name = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool.renderer_bundle_file_name
          form["bundle"] = UploadIO.new(
            File.new(ReactOnRails::Utils.server_bundle_js_file_path),
            "text/javascript",
            renderer_bundle_file_name
          )

          populate_form_with_assets_to_copy(form)
        end
        form
      end

      def populate_form_with_assets_to_copy(form)
        if ReactOnRailsPro.configuration.assets_to_copy.present?
          ReactOnRailsPro.configuration.assets_to_copy.each_with_index do |asset_path, idx|
            Rails.logger.info { "[ReactOnRailsPro] Uploading asset #{asset_path}" }
            unless File.exist?(asset_path)
              warn "Asset not found #{asset_path}"
              next
            end

            content_type = ReactOnRailsPro::Utils.mine_type_from_file_name(asset_path)

            # File.new is very important so that UploadIO does not have confusion over a Pathname
            # vs. a file path. I.e., Pathname objects don't work.
            form["assetsToCopy#{idx}"] = UploadIO.new(File.new(asset_path), content_type, asset_path)
          end
        end
        form
      end

      def form_with_assets_and_bundle
        form = common_form_data
        populate_form_with_assets_to_copy(form)

        src_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
        raise ReactOnRails::Error, "Bundle not found #{src_bundle_path}" unless File.exist?(src_bundle_path)

        renderer_bundle_file_name = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool.renderer_bundle_file_name
        form["bundle"] = UploadIO.new(File.new(src_bundle_path), "text/javascript",
                                      renderer_bundle_file_name)
        form
      end

      def common_form_data
        {
          "gemVersion" => ReactOnRailsPro::VERSION,
          "protocolVersion" => "1.0.0",
          "password" => ReactOnRailsPro.configuration.renderer_password
        }
      end

      def create_connection
        Rails.logger.info do
          "[ReactOnRailsPro] Setting up Node Renderer connection to #{ReactOnRailsPro.configuration.renderer_url}"
        end

        # NOTE: there are multiple similar gems
        # We use https://github.com/bpardee/persistent_http/blob/master/lib/persistent_http.rb
        # Not: https://github.com/drbrain/net-http-persistent
        PersistentHTTP.new(
          name: "ReactOnRailsProNodeRendererClient",
          logger: Rails.logger,
          pool_size: ReactOnRailsPro.configuration.renderer_http_pool_size,
          pool_timeout: ReactOnRailsPro.configuration.renderer_http_pool_timeout,
          warn_timeout: ReactOnRailsPro.configuration.renderer_http_pool_warn_timeout,

          # https://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html#attribute-i-read_timeout
          # https://github.com/bpardee/persistent_http/blob/master/lib/persistent_http/connection.rb#L168
          read_timeout: ReactOnRailsPro.configuration.ssr_timeout,
          force_retry: true,
          url: ReactOnRailsPro.configuration.renderer_url
        )
      rescue StandardError => e
        message = <<~MSG
          [ReactOnRailsPro] Error creating PersistentHTTP connection.
          renderer_http_pool_size = #{ReactOnRailsPro.configuration.renderer_http_pool_size}
          renderer_http_pool_timeout = #{ReactOnRailsPro.configuration.renderer_http_pool_timeout}
          renderer_http_pool_warn_timeout = #{ReactOnRailsPro.configuration.renderer_http_pool_warn_timeout}
          renderer_url = #{ReactOnRailsPro.configuration.renderer_url}
          Be sure to use a url that contains the protocol of http or https.
          Original error is
          #{e}
        MSG
        raise ReactOnRailsPro::Error, message
      end
    end
  end
end
