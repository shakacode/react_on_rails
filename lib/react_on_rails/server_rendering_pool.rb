require "connection_pool"

# Based on the react-rails gem.
# None of these methods should be called directly.
# See app/helpers/react_on_rails_helper.rb
module ReactOnRails
  class ServerRenderingPool
    def self.reset_pool
      options = { size: ReactOnRails.configuration.server_renderer_pool_size,
                  timeout: ReactOnRails.configuration.server_renderer_pool_size }
      @js_context_pools =
        ReactOnRails.configuration.server_bundle_js_files.each_with_object({}) do |server_bundle_js_file, hash|
          hash[server_bundle_js_file] = ConnectionPool.new(options) { create_js_context(server_bundle_js_file) }
        end
    end

    def self.reset_pool_if_server_bundle_was_modified
      return unless ReactOnRails.configuration.development_mode
      @server_bundle_timestamps ||= {}
      do_reset_pool = false
      ReactOnRails.configuration.server_bundle_js_files.each do |server_bundle_js_file|
        file_mtime = File.mtime(ReactOnRails::Utils.server_bundle_js_file_path(server_bundle_js_file))
        next if @server_bundle_timestamps[server_bundle_js_file] == file_mtime
        @server_bundle_timestamps[server_bundle_js_file] = file_mtime
        do_reset_pool = true
      end
      ReactOnRails::ServerRenderingPool.reset_pool if do_reset_pool
    end

    # js_code: JavaScript expression that returns a string.
    # Returns a Hash:
    #   html: string of HTML for direct insertion on the page by evaluating js_code
    #   consoleReplayScript: script for replaying console
    #   hasErrors: true if server rendering errors
    # Note, js_code does not have to be based on React.
    # js_code MUST RETURN json stringify Object
    # Calling code will probably call 'html_safe' on return value before rendering to the view.
    def self.server_render_js_with_console_logging(server_bundle_js_file, js_code)
      trace_message(js_code)
      json_string = eval_js(server_bundle_js_file, js_code)
      result = JSON.parse(json_string)
      if ReactOnRails.configuration.logging_on_server
        console_script = result["consoleReplayScript"]
        console_script_lines = console_script.split("\n")
        console_script_lines = console_script_lines[2..-2]
        re = /console\.log\.apply\(console, \["\[SERVER\] (?<msg>.*)"\]\);/
        if console_script_lines
          console_script_lines.each do |line|
            match = re.match(line)
            Rails.logger.info { "[react_on_rails] #{match[:msg]}" } if match
          end
        end
      end
      result
    end

    class << self
      private

      def trace_message(js_code, file_name = "tmp/server-generated.js")
        return unless ENV["TRACE_REACT_ON_RAILS"].present?
        # Set to anything to print generated code.
        puts "Z" * 80
        puts "react_renderer.rb: 92"
        puts "wrote file #{file_name}"
        File.write(file_name, js_code)
        puts "Z" * 80
      end

      def eval_js(server_js_file, js_code)
        server_js_file_context_pool = js_context_pool_for_file(server_js_file)
        raise "Bundle [#{server_js_file}] not set in js context pools" if server_js_file_context_pool.nil?
        server_js_file_context_pool.with do |js_context|
          result = js_context.eval(js_code)
          js_context.eval("console.history = []")
          result
        end
      end

      def js_context_pool_for_file(server_js_file)
        @js_context_pools[server_js_file]
      end

      def create_js_context(server_js_file)
        return unless server_js_file.present?

        server_js_file_path = ReactOnRails::Utils.server_bundle_js_file_path(server_js_file)
        if File.exist?(server_js_file_path)
          bundle_js_code = File.read(server_js_file_path)
          base_js_code = <<-JS
#{console_polyfill}
#{execjs_timer_polyfills}
          #{bundle_js_code};
          JS
          begin
            ExecJS.compile(base_js_code)
          rescue => e
            file_name = "tmp/base_js_code.js"
            msg = "ERROR when compiling base_js_code! See #{file_name} to "\
              "ERROR when compiling base_js_code! See #{file_name} to "\
              "correlate line numbers of error. Error is\n\n#{e.message}"\
              "\n\n#{e.backtrace.join("\n")}"
            puts msg
            Rails.logger.error(msg)
            trace_message(base_js_code, file_name)
            raise e
          end
        else
          msg = "You specified server rendering JS file: #{server_js_file}, but it cannot be "\
            "read. You may set the server_bundle_js_files in your configuration to be \"[]\" to "\
            "avoid this warning"
          Rails.logger.warn msg
          puts msg
          ExecJS.compile("")
        end
      end

      def execjs_timer_polyfills
        <<-JS
function setInterval() {
 console.error('setInterval is not defined for execJS. See https://github.com/sstephenson/execjs#faq');
}

function setTimeout() {
 console.error('setTimeout is not defined for execJS. See https://github.com/sstephenson/execjs#faq');
}
        JS
      end

      # Reimplement console methods for replaying on the client
      def console_polyfill
        <<-JS
var console = { history: [] };
['error', 'log', 'info', 'warn'].forEach(function (level) {
  console[level] = function () {
    var argArray = Array.prototype.slice.call(arguments);
    if (argArray.length > 0) {
      argArray[0] = '[SERVER] ' + argArray[0];
    }
    console.history.push({level: level, arguments: argArray});
  };
});
        JS
      end
    end
  end
end
