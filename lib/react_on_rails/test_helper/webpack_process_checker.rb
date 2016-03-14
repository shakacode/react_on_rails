# You can replace this implementation with your own for use by the
# ReactOnRails::TestHelper.ensure_assets_compiled helper
module ReactOnRails
  module TestHelper
    class WebpackProcessChecker
      def initialize
        @printed_once = {}
        @needs_client_compile = true
        @needs_server_compile = Utils.server_rendering_is_enabled?
        @wait_longer = false
      end

      # Return true if we should keep waiting
      # type is either client or server
      def client_running?
        client_running = check_running_for_type("client")
        return false unless client_running
      end

      def server_running?
        if Utils.server_rendering_is_enabled?
          return true if check_running_for_type("server")
        end
        false
      end

      def hot_running?
        _response = `pgrep -fl 'babel-node +server-rails-hot.js'`
        Utils.last_process_completed_successfully?
      end

      private

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
