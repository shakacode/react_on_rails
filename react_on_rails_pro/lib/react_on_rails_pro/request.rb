# frozen_string_literal: true

require "uri"
require "httpx"
require_relative "stream_request"

module ReactOnRailsPro
  class Request # rubocop:disable Metrics/ClassLength
    class << self
      def reset_connection
        @connection&.close
        @connection_without_retries&.close
        @connection = create_connection
        @connection_without_retries = create_connection(enable_retries: false)
      end

      def render_code(path, js_code, send_bundle)
        Rails.logger.info { "[ReactOnRailsPro] Perform rendering request #{path}" }
        form = form_with_code(js_code, send_bundle)
        perform_request(path, form: form)
      end

      def render_code_as_stream(path, js_code, is_rsc_payload:)
        Rails.logger.info { "[ReactOnRailsPro] Perform rendering request as a stream #{path}" }
        if is_rsc_payload && !ReactOnRailsPro.configuration.enable_rsc_support
          raise ReactOnRailsPro::Error,
                "RSC support is not enabled. Please set enable_rsc_support to true in your " \
                "config/initializers/react_on_rails_pro.rb file before " \
                "rendering any RSC payload."
        end

        ReactOnRailsPro::StreamRequest.create do |send_bundle|
          form = form_with_code(js_code, send_bundle)
          perform_request(path, form: form, stream: true)
        end
      end

      def upload_assets
        Rails.logger.info { "[ReactOnRailsPro] Uploading assets" }

        # Check if server bundle exists before trying to upload assets
        server_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
        unless File.exist?(server_bundle_path)
          raise ReactOnRailsPro::Error, "Server bundle not found at #{server_bundle_path}. " \
                                        "Please build your bundles before uploading assets."
        end

        # Create a list of bundle timestamps to send to the node renderer
        pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
        target_bundles = [pool.server_bundle_hash]

        # Add RSC bundle if enabled
        if ReactOnRailsPro.configuration.enable_rsc_support
          rsc_bundle_path = ReactOnRailsPro::Utils.rsc_bundle_js_file_path
          unless File.exist?(rsc_bundle_path)
            raise ReactOnRailsPro::Error, "RSC bundle not found at #{rsc_bundle_path}. " \
                                          "Please build your bundles before uploading assets."
          end
          target_bundles << pool.rsc_bundle_hash
        end

        form = form_with_assets_and_bundle
        form["targetBundles"] = target_bundles

        perform_request("/upload-assets", form: form)
      end

      def asset_exists_on_vm_renderer?(filename)
        Rails.logger.info { "[ReactOnRailsPro] Sending request to check if file exist on node-renderer: #{filename}" }

        form_data = common_form_data

        # Add targetBundles from the current bundle hash and RSC bundle hash
        pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
        target_bundles = [pool.server_bundle_hash]

        target_bundles << pool.rsc_bundle_hash if ReactOnRailsPro.configuration.enable_rsc_support

        form_data["targetBundles"] = target_bundles

        response = perform_request("/asset-exists?filename=#{filename}", json: form_data)
        JSON.parse(response.body)["exists"] == true
      end

      private

      # NOTE: We maintain two separate HTTP connection pools to handle streaming vs non-streaming requests.
      # This doubles the memory footprint (e.g., if renderer_http_pool_size is 10, we use 20 total connections).
      # This tradeoff is acceptable to prevent body duplication in streaming responses.

      def connection
        @connection ||= create_connection
      end

      def connection_without_retries
        @connection_without_retries ||= create_connection(enable_retries: false)
      end

      def perform_request(path, **post_options) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        # For streaming requests, use connection without retries to prevent body duplication
        # The StreamRequest class handles retries properly by starting fresh requests
        conn = connection

        available_retries = ReactOnRailsPro.configuration.renderer_request_retry_limit
        retry_request = true
        while retry_request
          begin
            start_time = Time.now
            response = conn.post(path, **post_options)
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
        pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool

        add_bundle_to_form(
          form,
          bundle_path: ReactOnRails::Utils.server_bundle_js_file_path,
          bundle_file_name: pool.renderer_bundle_file_name,
          bundle_hash: pool.server_bundle_hash,
          check_bundle: check_bundle
        )

        if ReactOnRailsPro.configuration.enable_rsc_support
          add_bundle_to_form(
            form,
            bundle_path: ReactOnRailsPro::Utils.rsc_bundle_js_file_path,
            bundle_file_name: pool.rsc_renderer_bundle_file_name,
            bundle_hash: pool.rsc_bundle_hash,
            check_bundle: check_bundle
          )
        end

        add_assets_to_form(form)
      end

      def add_bundle_to_form(form, bundle_path:, bundle_file_name:, bundle_hash:, check_bundle:)
        raise ReactOnRailsPro::Error, "Bundle not found #{bundle_path}" if check_bundle && !File.exist?(bundle_path)

        form["bundle_#{bundle_hash}"] = {
          body: get_form_body_for_file(bundle_path),
          content_type: "text/javascript",
          filename: bundle_file_name
        }
      end

      def add_assets_to_form(form)
        assets_to_copy = (ReactOnRailsPro.configuration.assets_to_copy || []).dup
        # react_client_manifest and react_server_manifest files are needed to generate react server components payload
        if ReactOnRailsPro.configuration.enable_rsc_support
          assets_to_copy << ReactOnRailsPro::Utils.react_client_manifest_file_path
          assets_to_copy << ReactOnRailsPro::Utils.react_server_client_manifest_file_path
        end

        return form unless assets_to_copy.present?

        assets_to_copy.each_with_index do |asset_path, idx|
          Rails.logger.info { "[ReactOnRailsPro] Uploading asset #{asset_path}" }
          unless http_url?(asset_path) || File.exist?(asset_path)
            warn "Asset not found #{asset_path}"
            next
          end

          content_type = ReactOnRailsPro::Utils.mine_type_from_file_name(asset_path)

          begin
            form["assetsToCopy#{idx}"] = {
              body: get_form_body_for_file(asset_path),
              content_type: content_type,
              filename: File.basename(asset_path)
            }
          rescue StandardError => e
            warn "[ReactOnRailsPro] Error uploading asset #{asset_path}: #{e}"
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
        ReactOnRailsPro::Utils.common_form_data
      end

      def create_connection(enable_retries: true)
        url = ReactOnRailsPro.configuration.renderer_url
        Rails.logger.info do
          "[ReactOnRailsPro] Setting up Node Renderer connection to #{url}"
        end

        http_client = HTTPX
        # For persistent connections we want retries,
        # so the requests don't just fail if the other side closes the connection
        # https://honeyryderchuck.gitlab.io/httpx/wiki/Persistent
        # However, for streaming requests, retries cause body duplication
        # See https://github.com/shakacode/react_on_rails/issues/1895
        http_client = http_client.plugin(:retries, max_retries: 1, retry_change_requests: true) if enable_retries
        http_client
          .plugin(:stream)
          # See https://www.rubydoc.info/gems/httpx/1.3.3/HTTPX%2FOptions:initialize for the available options
          .with(
            origin: url,
            # Version of HTTP protocol to use by default in the absence of protocol negotiation
            fallback_protocol: "h2",
            persistent: true,
            pool_options: {
              max_connections_per_origin: ReactOnRailsPro.configuration.renderer_http_pool_size
            },
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
          renderer_url = #{url}
          Be sure to use a url that contains the protocol of http or https.
          Original error is
          #{e}
        MSG
        raise ReactOnRailsPro::Error, message
      end

      def get_form_body_for_file(path)
        # Handles the case when the file is served from the dev server
        if http_url?(path)
          unless Rails.env.development?
            raise ReactOnRailsPro::Error,
                  "Not expected to get HTTP url for bundle or assets in production mode"
          end

          response = HTTPX.get(path)
          response.body
        else
          Pathname.new(path)
        end
      end

      def http_url?(path)
        path.to_s.match?(%r{https?://})
      end
    end
  end
end
