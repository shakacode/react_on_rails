# You can replace this implementation with your own for use by the
# ReactOnRails::TestHelper.ensure_assets_compiled helper
module ReactOnRails
  module TestHelper
    class WebpackProcessChecker
      def initialize
        @printed_once = {}
      end

      def running?
        client_running = check_running_for_type("client")
        return client_running unless Utils.server_rendering_is_enabled?

        server_running = check_running_for_type("server")
        fail_if_only_running_for_one_type(client_running, server_running)

        client_running && server_running
      end

      private

      # We only want to do this if server rendering is enabled.
      def fail_if_only_running_for_one_type(client_running, server_running)
        return unless client_running ^ server_running
        fail "\n\nError: detected webpack is not running for both types of assets:\n"\
         "***Webpack Client Process Running?: #{client_running}\n"\
         "***Webpack Server Process Running?: #{server_running}"
      end

      def check_running_for_type(type)
        type = type.to_sym

        response = `pgrep -fl 'bin/webpack\s(\\-w|\\-\\-watch)\s\\-\\-config\s.*#{type}.*\\.js'`
        is_running = Utils.last_process_completed_successfully?

        if is_running
          if @printed_once.empty?
            puts "\nDetected Webpack processes running to rebuild your generated files:"
          end
          unless @printed_once[type]
            puts "#{type}:  #{response}"
            @printed_once[type] = true
          end
        end

        is_running
      end
    end
  end
end
