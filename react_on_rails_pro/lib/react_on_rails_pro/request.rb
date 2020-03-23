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
        Rails.logger.info { "[ReactOnRailsPro] Sending request to check if file exist on vm-renderer: #{filename}" }
        response = perform_request("/asset-exists?filename=#{filename}", common_form_data)
        JSON.parse(response.body)["exists"] == true
      end

      private

      def connection
        @connection ||= create_connection
      end

      def perform_request(path, form)
        begin
          response = connection.request(Net::HTTP::Post::Multipart.new(path, form))
        rescue StandardError => e
          raise ReactOnRailsPro::Error, "Can't connect to VmRenderer renderer: #{path}.\n"\
                "Original error:\n#{e}\n#{e.backtrace}"
        end

        Rails.logger.info { "[ReactOnRailsPro] VM renderer responded" }

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
          renderer_bundle_file_name = ReactOnRailsPro::ServerRenderingPool::VmRenderingPool.renderer_bundle_file_name
          form["bundle"] = UploadIO.new(
            File.new(ReactOnRails::Utils.server_bundle_js_file_path),
            "application/javascript",
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
            raise ReactOnRails::Error, "Asset not found #{asset_path}" unless File.exist?(asset_path)

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

        renderer_bundle_file_name = ReactOnRailsPro::ServerRenderingPool::VmRenderingPool.renderer_bundle_file_name
        form["bundle"] = UploadIO.new(File.new(src_bundle_path), "application/javascript",
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
          "[ReactOnRailsPro] Setting up VM Renderer connection to #{ReactOnRailsPro.configuration.renderer_url}"
        end

        # NOTE: there are multiple similar gems
        # We use https://github.com/bpardee/persistent_http/blob/master/lib/persistent_http.rb
        # Not: https://github.com/drbrain/net-http-persistent
        PersistentHTTP.new(
          name: "ReactOnRailsProVmRendererClient",
          logger: Rails.logger,
          pool_size: ReactOnRailsPro.configuration.renderer_http_pool_size,
          pool_timeout: ReactOnRailsPro.configuration.renderer_http_pool_timeout,
          warn_timeout: ReactOnRailsPro.configuration.renderer_http_pool_warn_timeout,
          force_retry: true,
          url: ReactOnRailsPro.configuration.renderer_url
        )
      end
    end
  end
end
