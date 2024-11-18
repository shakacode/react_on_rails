# frozen_string_literal: true

require "uri"
require "httpx"
require_relative "stream_request"

module ReactOnRailsPro
  class Request # rubocop:disable Metrics/ClassLength
    class << self
      def reset_connection
        @connection&.close
        @connection = create_connection
      end

      def render_code(path, js_code, send_bundle)
        Rails.logger.info { "[ReactOnRailsPro] Perform rendering request #{path}" }
        perform_request(path, form: form_with_code(js_code, send_bundle))
      end

      def render_code_as_stream(path, js_code)
        Rails.logger.info { "[ReactOnRailsPro] Perform rendering request as a stream #{path}" }
        ReactOnRailsPro::StreamRequest.create do |send_bundle|
          perform_request(path, form: form_with_code(js_code, send_bundle), stream: true)
        end
      end

      def upload_assets
        Rails.logger.info { "[ReactOnRailsPro] Uploading assets" }
        perform_request("/upload-assets", form: form_with_assets_and_bundle)
      end

      def asset_exists_on_vm_renderer?(filename)
        Rails.logger.info { "[ReactOnRailsPro] Sending request to check if file exist on node-renderer: #{filename}" }
        response = perform_request("/asset-exists?filename=#{filename}", json: common_form_data)
        JSON.parse(response.body)["exists"] == true
      end

      private

      def connection
        @connection ||= create_connection
      end

      def perform_request(path, **post_options) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
        available_retries = ReactOnRailsPro.configuration.renderer_request_retry_limit
        retry_request = true
        while retry_request
          begin
            start_time = Time.now
            response = connection.post(path, **post_options)
            raise response.error if response.is_a?(HTTPX::ErrorResponse)

            request_time = Time.now - start_time
            warn_timeout = ReactOnRailsPro.configuration.renderer_http_pool_warn_timeout
            if request_time > warn_timeout
              Rails.logger.warn "Request to #{path} took #{request_time} seconds, expected at most #{warn_timeout}."
            end
            retry_request = false
          rescue HTTPX::TimeoutError => e
            # Testing timeout catching:
            # https://github.com/shakacode/react_on_rails_pro/pull/136#issue-463421204
            if available_retries.zero?
              raise ReactOnRailsPro::Error, "Time out error when getting the response on: #{path}.\n" \
                                            "Original error:\n#{e}\n#{e.backtrace}"
            end
            Rails.logger.info do
              "[ReactOnRailsPro] Timed out trying to make a request to the Node Renderer. " \
                "Retrying #{available_retries} more times..."
            end
            available_retries -= 1
            next
          rescue HTTPX::Error => e # Connection errors or other unexpected errors
            # Such errors are handled by ReactOnRailsPro::StreamRequest instead
            raise if e.is_a?(HTTPX::HTTPError) && post_options[:stream]

            raise ReactOnRailsPro::Error,
                  "Node renderer request failed: #{path}.\nOriginal error:\n#{e}\n#{e.backtrace}"
          end
        end

        Rails.logger.info { "[ReactOnRailsPro] Node Renderer responded" }

        # +response+ can also be an +HTTPX::ErrorResponse+ or an +HTTPX::StreamResponse+, which don't have +#status+.
        if response.is_a?(HTTPX::Response) && response.status == ReactOnRailsPro::STATUS_INCOMPATIBLE
          raise ReactOnRailsPro::Error, response.body
        end

        response
      end

      def form_with_code(js_code, send_bundle)
        form = common_form_data
        form["renderingRequest"] = js_code
        populate_form_with_bundle_and_assets(form, check_bundle: false) if send_bundle
        form
      end

      def populate_form_with_bundle_and_assets(form, check_bundle:)
        server_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
        if check_bundle && !File.exist?(server_bundle_path)
          raise ReactOnRailsPro::Error, "Bundle not found #{server_bundle_path}"
        end

        renderer_bundle_file_name = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool.renderer_bundle_file_name
        form["bundle"] = {
          body: Pathname.new(server_bundle_path),
          content_type: "text/javascript",
          filename: renderer_bundle_file_name
        }

        if ReactOnRailsPro.configuration.assets_to_copy.present?
          ReactOnRailsPro.configuration.assets_to_copy.each_with_index do |asset_path, idx|
            Rails.logger.info { "[ReactOnRailsPro] Uploading asset #{asset_path}" }
            unless File.exist?(asset_path)
              warn "Asset not found #{asset_path}"
              next
            end

            content_type = ReactOnRailsPro::Utils.mine_type_from_file_name(asset_path)

            form["assetsToCopy#{idx}"] = {
              body: Pathname.new(asset_path),
              content_type: content_type,
              filename: File.basename(asset_path)
            }
          end
        end
        form
      end

      def form_with_assets_and_bundle
        form = common_form_data
        populate_form_with_bundle_and_assets(form, check_bundle: true)
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

        HTTPX
          # For persistent connections we want retries,
          # so the requests don't just fail if the other side closes the connection
          # https://honeyryderchuck.gitlab.io/httpx/wiki/Persistent
          .plugin(:retries, max_retries: 1, retry_change_requests: true)
          .plugin(:stream)
          # See https://www.rubydoc.info/gems/httpx/1.3.3/HTTPX%2FOptions:initialize for the available options
          .with(
            origin: ReactOnRailsPro.configuration.renderer_url,
            # Version of HTTP protocol to use by default in the absence of protocol negotiation
            fallback_protocol: "h2",
            max_concurrent_requests: ReactOnRailsPro.configuration.renderer_http_pool_size,
            persistent: true,
            # Other timeouts supported https://honeyryderchuck.gitlab.io/httpx/wiki/Timeouts:
            # :write_timeout
            # :request_timeout
            # :operation_timeout
            # :keep_alive_timeout
            timeout: {
              connect_timeout: ReactOnRailsPro.configuration.renderer_http_pool_timeout,
              read_timeout: ReactOnRailsPro.configuration.ssr_timeout
            }
          )
      rescue StandardError => e
        message = <<~MSG
          [ReactOnRailsPro] Error creating HTTPX connection.
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
