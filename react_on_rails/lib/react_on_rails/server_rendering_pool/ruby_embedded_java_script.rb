# frozen_string_literal: true

require "open-uri"
require "execjs"
require "react_on_rails/length_prefixed_parser"
require "react_on_rails/lenient_json"

module ReactOnRails
  module ServerRenderingPool
    # rubocop:disable Metrics/ClassLength
    class RubyEmbeddedJavaScript
      # Error classes that signal Rails could not reach the renderer process (e.g. the
      # Pro Node renderer configured via REACT_RENDERER_URL) rather than the renderer
      # evaluating the bundle and the bundle itself failing. See issue #3604.
      #
      # Errno::EPERM is intentionally NOT in this list: it is a general "Operation not
      # permitted" error (file permissions, process signals, privileged-port binds), so a
      # class match — especially across the #cause chain — would misclassify a non-network
      # EPERM (e.g. a bundle file read wrapped in ReactOnRails::Error) as a renderer
      # connection failure. The sandboxed connect(2) EPERM from issue #3604 is matched
      # instead by the "connect(2) for" branch of RENDERER_CONNECTION_ERROR_REGEX below
      # (its message is "Operation not permitted - connect(2) for host:port").
      RENDERER_CONNECTION_ERROR_CLASSES = [
        SocketError,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::EHOSTUNREACH,
        Errno::ENETUNREACH,
        Errno::ETIMEDOUT,
        Errno::EPIPE
      ].freeze

      # Renderer-anchored connection signatures, used only as a fallback for failures that
      # survive as text rather than as one of the Errno classes above. The Pro renderer
      # client re-wraps transport failures as "<Connection|Time out> error on renderer
      # request: ...", and raw Errno messages carry the "connect(2) for host:port" shape.
      # These patterns are deliberately narrow (anchored to renderer/socket wording) so a
      # genuine in-process bundle error whose text merely mentions a connection — e.g. a
      # component's own failed `fetch` during SSR reporting "ECONNREFUSED" — is NOT
      # misclassified as a renderer connectivity problem. Structured cases are handled by
      # the Errno classes above, checked across the error's #cause chain. See issue #3604.
      RENDERER_CONNECTION_ERROR_REGEX = /
        connect\(2\)\sfor
        | Failed\sto\sopen\sTCP\sconnection
        | error\son\srenderer\srequest
      /xi

      class << self
        def reset_pool
          @js_context_pool = ConnectionPool.new(
            size: ReactOnRails.configuration.server_renderer_pool_size,
            timeout: ReactOnRails.configuration.server_renderer_timeout
          ) { create_js_context }
        end

        def reset_pool_if_server_bundle_was_modified
          return unless ReactOnRails.configuration.development_mode

          # RSC (React Server Components) bundle changes are not monitored here since:
          # 1. RSC is only supported in the Pro version of React on Rails
          # 2. This RubyEmbeddedJavaScript pool is used exclusively in the non-Pro version
          # 3. This pool uses ExecJS for JavaScript evaluation which does not support RSC
          if ReactOnRails::Utils.server_bundle_path_is_http?
            return if @server_bundle_url == ReactOnRails::Utils.server_bundle_js_file_path

            @server_bundle_url = ReactOnRails::Utils.server_bundle_js_file_path
          else
            file_mtime = File.mtime(ReactOnRails::Utils.server_bundle_js_file_path)
            @server_bundle_timestamp ||= file_mtime
            return if @server_bundle_timestamp == file_mtime

            @server_bundle_timestamp = file_mtime
          end
          ReactOnRails::ServerRenderingPool.reset_pool
        end

        # js_code: JavaScript expression that returns a string.
        # render_options: lib/react_on_rails/react_component/render_options.rb
        # Using these options:
        #    trace: saves the executed JS to a file, used in development
        #    logging_on_server: put on server logs, not just in browser console
        #
        # Returns a Hash:
        #   html: string of HTML for direct insertion on the page by evaluating js_code
        #   consoleReplayScript: script for replaying console
        #   hasErrors: true if server rendering errors
        # Note, js_code does not have to be based on React.
        # js_code MUST RETURN json stringify Object
        # Calling code will probably call 'html_safe' on return value before rendering to the view.
        def exec_server_render_js(js_code, render_options, js_evaluator = nil)
          js_evaluator ||= self
          if render_options.trace
            @file_index ||= 1
            trace_js_code_used("Evaluating code to server render.", js_code,
                               "tmp/server-generated-#{@file_index % 10}.js")
            @file_index += 1
          end
          begin
            result = if render_options.streaming?
                       js_evaluator.eval_streaming_js(js_code, render_options)
                     else
                       js_evaluator.eval_js(js_code, render_options)
                     end
          rescue ReactOnRails::ServerBundleLoadError
            raise
          rescue StandardError => err
            msg = if renderer_connection_error?(err)
                    renderer_connection_error_message(err)
                  else
                    server_bundle_evaluation_error_message(err)
                  end
            msg = "#{msg}\n#{Utils.default_troubleshooting_section}\n"
            raise ReactOnRails::Error, msg, err.backtrace
          end

          return parse_render_result(result, render_options) unless render_options.streaming?

          # Streamed chunks are Hashes (from LengthPrefixedParser in stream_request.rb).
          # Just replay console messages and pass through.
          result.transform do |chunk|
            replay_console_to_rails_logger(chunk, render_options)
            chunk
          end
        end

        def trace_js_code_used(msg, js_code, file_name = "tmp/server-generated.js", force: false)
          return unless ReactOnRails.configuration.trace || force

          # Set to anything to print generated code.
          File.write(file_name, js_code)
          msg = <<~MSG
            #{'Z' * 80}
            [react_on_rails] #{msg}
            JavaScript code used: #{file_name}
            #{'Z' * 80}
          MSG
          if force
            Rails.logger.error(msg)
          else
            Rails.logger.info(msg)
          end
        end

        def eval_js(js_code, _render_options)
          @js_context_pool.with do |js_context|
            js_context.eval(js_code)
          end
        end

        def read_bundle_js_code
          server_js_file = ReactOnRails::Utils.server_bundle_js_file_path
          if ReactOnRails::Utils.server_bundle_path_is_http?
            file_url_to_string(server_js_file)
          else
            File.read(server_js_file)
          end
        rescue StandardError => e
          msg = "You specified server rendering JS file: #{server_js_file}, but it cannot be " \
                "read. You may set the server_bundle_js_file in your configuration to be \"\" to " \
                "avoid this warning.\nError is: #{e}\n\n#{Utils.default_troubleshooting_section}"
          raise ReactOnRails::ServerBundleLoadError, msg
        end

        def create_js_context
          return if ReactOnRails.configuration.server_bundle_js_file.blank?

          bundle_js_code = read_bundle_js_code
          base_js_code = <<~JS
            #{console_polyfill}
            #{execjs_timer_polyfills}
            #{bundle_js_code};
          JS

          file_name = "tmp/base_js_code.js"
          begin
            if ReactOnRails.configuration.trace
              Rails.logger.info do
                "[react_on_rails] Created JavaScript context with file " \
                  "#{ReactOnRails::Utils.server_bundle_js_file_path}"
              end
            end
            ExecJS.compile(base_js_code)
          rescue StandardError => e
            msg = "ERROR when compiling base_js_code! " \
                  "See file #{file_name} to " \
                  "correlate line numbers of error. Error is\n\n#{e.message}" \
                  "\n\n#{e.backtrace.join("\n")}" \
                  "\n\n#{Utils.default_troubleshooting_section}"
            Rails.logger.error(msg)
            trace_js_code_used("Error when compiling JavaScript code for the context.", base_js_code,
                               file_name, force: true)
            raise e
          end
        end

        def execjs_timer_polyfills
          <<~JS
            function getStackTrace () {
              var stack;
              try {
                throw new Error('');
              }
              catch (error) {
                stack = error.stack || '';
              }
              stack = stack.split('\\n').map(function (line) { return line.trim(); });
              return stack.splice(stack[0] == 'Error' ? 2 : 1);
            }

            function setInterval() {
              #{undefined_for_exec_js_logging('setInterval')}
            }

            function setTimeout() {
              #{undefined_for_exec_js_logging('setTimeout')}
            }

            function clearTimeout() {
              #{undefined_for_exec_js_logging('clearTimeout')}
            }
          JS
        end

        def undefined_for_exec_js_logging(function_name)
          if ReactOnRails.configuration.trace
            "console.error('[React on Rails Rendering] #{function_name} is not defined for server rendering.');\n  " \
              "console.error(getStackTrace().join('\\n'));"
          else
            ""
          end
        end

        # Reimplement console methods for replaying on the client
        # Save a handle to the original console if needed.
        def console_polyfill
          <<~JS
            var debugConsole = console;
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

        private

        # Distinguishes "Rails could not reach the renderer" from "the renderer evaluated
        # the bundle and the bundle failed". The connection Errno (ECONNREFUSED, ECONNRESET, ...)
        # is checked across err and its #cause chain because the Pro renderer client
        # re-wraps the original Errno inside its own error; a narrow message check then
        # catches connection failures that only survive as text. See issue #3604.
        def renderer_connection_error?(err)
          return false if server_bundle_load_error_in_chain?(err)

          connection_error_class_in_chain?(err) ||
            connection_error_message_in_chain?(err)
        end

        def server_bundle_load_error_in_chain?(err)
          each_in_cause_chain(err) do |current|
            return true if current.is_a?(ReactOnRails::ServerBundleLoadError)
          end
          false
        end

        # Walks err and its #cause chain looking for a known connection Errno, so a wrapped
        # error (e.g. ReactOnRailsPro::Error -> ConnectionError -> Errno::ECONNREFUSED) is
        # still recognised.
        def connection_error_class_in_chain?(err)
          each_in_cause_chain(err) do |current|
            return true if RENDERER_CONNECTION_ERROR_CLASSES.any? { |klass| current.is_a?(klass) }
          end
          false
        end

        def connection_error_message_in_chain?(err)
          each_in_cause_chain(err) do |current|
            return true if current.message.to_s.match?(RENDERER_CONNECTION_ERROR_REGEX)
          end
          false
        end

        # Yields err and each error in its #cause chain. Identity-guarded (Set of object_ids)
        # so a self-referential cause cannot loop.
        def each_in_cause_chain(err)
          seen = Set.new
          current = err
          while current && seen.add?(current.object_id)
            yield current
            current = current.cause
          end
        end

        def renderer_connection_error_message(err)
          target = renderer_target_from_error(err)
          configured_var, configured_url = configured_renderer_url
          configured_line = if configured_url
                              "#{configured_var} is currently \"#{configured_url}\" — confirm it matches the " \
                                "renderer's host and port (RENDERER_HOST / RENDERER_PORT)"
                            else
                              "REACT_RENDERER_URL is not set — set it to the renderer's host and port " \
                                "(RENDERER_HOST / RENDERER_PORT, e.g. http://127.0.0.1:3800)"
                            end

          <<~MSG
            React on Rails could not connect to the Node renderer#{" at #{target}" if target}.
            ===============================================================
            Caught error:
            #{err.message}
            ===============================================================
            This is a renderer connection failure, not a webpack/server-bundle evaluation error.
            The bundle was not evaluated because the renderer could not be reached.

            Check, in order:
            - the renderer process is running and listening#{" on #{target}" if target}
            - #{configured_line}
            - CI keeps the renderer process alive for the duration of the test step
            - localhost vs 127.0.0.1 vs IPv6 (::1) differences between Rails and the renderer

            Only after confirming renderer connectivity should you investigate bundle
            registration or webpack configuration.
          MSG
        end

        def server_bundle_evaluation_error_message(err)
          msg = <<~MSG
            Error evaluating server bundle. Check your webpack configuration.
            ===============================================================
            Caught error:
            #{err.message}
            ===============================================================
          MSG

          if err.message.include?("ReferenceError: self is not defined")
            msg << "\nError indicates that you may have code-splitting incorrectly enabled.\n"
          end
          msg
        end

        # Best-effort extraction of the host/port (or URL) Rails attempted to reach, so the
        # connection error can name the actual target. Walks the #cause chain because the Pro
        # renderer client wraps the original Errno (whose message carries "connect(2) for
        # host:port") inside a generic outer error. Falls back to the configured renderer URL.
        def renderer_target_from_error(err)
          each_in_cause_chain(err) do |current|
            target = target_from_message(current.message)
            # Sanitize here too: a target scraped from the message can itself be a full URL
            # with embedded credentials (e.g. "TCP connection to https://user:pw@host:3800").
            return sanitized_renderer_url(target) if target
          end
          configured_renderer_url.last
        end

        # Resolves the configured renderer URL and the env var it came from, so the headline
        # target and the checklist line stay consistent. A blank (present-but-empty) value is
        # treated as unset, and the legacy RENDERER_URL alias is the fallback. Credentials are
        # stripped for safe display. Returns [var_name, sanitized_url] or [nil, nil].
        def configured_renderer_url
          %w[REACT_RENDERER_URL RENDERER_URL].each do |var|
            value = ENV.fetch(var, nil)
            return [var, sanitized_renderer_url(value)] unless value.nil? || value.empty?
          end
          [nil, nil]
        end

        def target_from_message(message)
          message = message.to_s
          [
            /connect\(2\) for (?<target>[^\s,)]+)/,
            /TCP connection to (?<target>[^\s,)]+)/,
            %r{(?<target>https?://[^\s,"')]+)}
          ].each do |regex|
            match = message.match(regex)
            # Trim trailing prose punctuation (e.g. a sentence-final "." or ":") that the
            # broad capture classes can otherwise absorb.
            return match[:target].delete('"').sub(/[.;:]+\z/, "") if match
          end
          nil
        end

        # Strips any embedded credentials from a configured renderer URL before it is
        # interpolated into an error message, so a password in the URL (a supported config
        # convenience, e.g. https://:password@host:3800) cannot leak into logs or error
        # trackers. Mirrors ReactOnRailsPro::Configuration#strip_renderer_url_userinfo.
        def sanitized_renderer_url(url)
          return url if url.nil? || url.empty?

          uri = URI.parse(url)
          return url if uri.userinfo.nil?

          # URI rejects a password without a user, so clear password first.
          uri.password = nil
          uri.user = nil
          uri.to_s
        rescue URI::InvalidURIError
          # Best-effort strip of the common user:pass@ form so a URL that URI rejects as
          # malformed still doesn't leak a password into the message or logs.
          url.to_s.gsub(%r{//[^/@]*@}, "//")
        end

        def file_url_to_string(url)
          response = Net::HTTP.get_response(URI.parse(url))
          content_type_header = response["content-type"]
          match = content_type_header.match(/\A.*; charset=(?<encoding>.*)\z/)
          encoding_type = match[:encoding]
          response.body.force_encoding(encoding_type)
        rescue StandardError => e
          msg = "file_url_to_string #{url} failed\nError is: #{e}\n\n#{Utils.default_troubleshooting_section}"
          raise ReactOnRails::ServerBundleLoadError, msg
        end

        def parse_render_result(result_string, render_options)
          # Auto-detect format: length-prefixed (contains tab) or legacy JSON.
          # ExecJS with older bundles may return JSON; node renderer returns length-prefixed.
          result = if result_string.to_s.include?("\t")
                     ReactOnRails::LengthPrefixedParser.parse_one_chunk_result(result_string)
                   else
                     # LenientJson repairs lone-surrogate escapes the JS renderer can emit (#4710).
                     ReactOnRails::LenientJson.parse(result_string.to_s)
                   end
          replay_console_to_rails_logger(result, render_options)
          result
        rescue StandardError => e
          raise ReactOnRails::JsonParseError.new(parse_error: e, json: result_string)
        end

        def replay_console_to_rails_logger(result, render_options)
          return unless render_options.logging_on_server

          console_script = result["consoleReplayScript"]
          return if console_script.nil? || console_script.empty?

          # Regular expression to match console.log or console.error calls with SERVER prefix
          re = /console\.(?:log|error|info|warn)\.apply\(console, \["\[SERVER\] (?<msg>.*)"\]\);/
          console_script.split("\n").each do |line|
            match = re.match(line)
            # Log matched messages to Rails logger with react_on_rails prefix
            Rails.logger.info { "[react_on_rails] #{match[:msg]}" } if match
          end
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
