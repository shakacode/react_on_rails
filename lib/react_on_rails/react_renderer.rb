# Kudos to react-rails for how to do the polyfill of the console!
# https://github.com/reactjs/react-rails/blob/master/lib/react/server_rendering/sprockets_renderer.rb

# require 'react_on_rails/server_rendering_pool'

module ReactOnRails
  class ReactRenderer
    # js_code: JavaScript expression that returns a string.
    # Returns an Array:
    # [0]: string of HTML for direct insertion on the page by evaluating js_code
    # [1]: console messages
    #   Note, js_code does not have to be based on React.
    # js_code MUST RETURN json stringify array of two elements
    # Calling code will probably call 'html_safe' on return value before rendering to the view.
    def self.server_render_js_with_console_logging(js_code, options = {})
      if ENV["TRACE_REACT_ON_RAILS"].present? # Set to anything to print generated code.
        puts "Z" * 80
        puts "react_renderer.rb: 92"
        puts "wrote file tmp/server-generated.js"
        File.write("tmp/server-generated.js", js_code)
        puts "Z" * 80
      end

      json_string = ReactOnRails::ServerRenderingPool.eval_js(js_code)
      # element 0 is the html, element 1 is the script tag for the server console output
      result = JSON.parse(json_string)

      if ReactOnRails.configuration.logging_on_server
        console_script = result[1]
        console_script_lines = console_script.split("\n")
        console_script_lines = console_script_lines[2..-2]
        re = /console\.log\.apply\(console, \["\[SERVER\] (?<msg>.*)"\]\);/
        if console_script_lines
          console_script_lines.each do |line|
            match = re.match(line)
            if match
              Rails.logger.info { "[react_on_rails] #{match[:msg]}" }
            end
          end
        end
      end
      result
    end
  end
end
