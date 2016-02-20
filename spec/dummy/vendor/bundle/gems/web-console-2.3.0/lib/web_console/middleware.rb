require 'active_support/core_ext/string/strip'

module WebConsole
  class Middleware
    TEMPLATES_PATH = File.expand_path('../templates', __FILE__)

    cattr_accessor :mount_point
    @@mount_point = '/__web_console'

    cattr_accessor :whiny_requests
    @@whiny_requests = true

    def initialize(app)
      @app = app
    end

    def call(env)
      app_exception = catch :app_exception do
        request = create_regular_or_whiny_request(env)
        return @app.call(env) unless request.from_whitelited_ip?

        if id = id_for_repl_session_update(request)
          return update_repl_session(id, request)
        elsif id = id_for_repl_session_stack_frame_change(request)
          return change_stack_trace(id, request)
        end

        status, headers, body = @app.call(env)

        if exception = env['web_console.exception']
          session = Session.from_exception(exception)
        elsif binding = env['web_console.binding']
          session = Session.from_binding(binding)
        end

        if session && acceptable_content_type?(headers)
          response = Response.new(body, status, headers)
          template = Template.new(env, session)

          response.headers["X-Web-Console-Session-Id"] = session.id
          response.headers["X-Web-Console-Mount-Point"] = mount_point
          response.write(template.render('index'))
          response.finish
        else
          [ status, headers, body ]
        end
      end
    rescue => e
      WebConsole.logger.error("\n#{e.class}: #{e}\n\tfrom #{e.backtrace.join("\n\tfrom ")}")
      raise e
    ensure
      raise app_exception if Exception === app_exception
    end

    private

      def acceptable_content_type?(headers)
        Mime::Type.parse(headers['Content-Type']).first == Mime::HTML
      end

      def json_response(opts = {})
        status  = opts.fetch(:status, 200)
        headers = { 'Content-Type' => 'application/json; charset = utf-8' }
        body    = yield.to_json

        Rack::Response.new(body, status, headers).finish
      end

      def json_response_with_session(id, request, opts = {})
        return respond_with_unacceptable_request unless request.acceptable?
        return respond_with_unavailable_session(id) unless session = Session.find(id)

        json_response(opts) { yield session }
      end

      def create_regular_or_whiny_request(env)
        request = Request.new(env)
        whiny_requests ? WhinyRequest.new(request) : request
      end

      def repl_sessions_re
        @_repl_sessions_re ||= %r{#{mount_point}/repl_sessions/(?<id>[^/]+)}
      end

      def update_re
        @_update_re ||= %r{#{repl_sessions_re}\z}
      end

      def binding_change_re
        @_binding_change_re ||= %r{#{repl_sessions_re}/trace\z}
      end

      def id_for_repl_session_update(request)
        if request.xhr? && request.put?
          update_re.match(request.path) { |m| m[:id] }
        end
      end

      def id_for_repl_session_stack_frame_change(request)
        if request.xhr? && request.post?
          binding_change_re.match(request.path) { |m| m[:id] }
        end
      end

      def update_repl_session(id, request)
        json_response_with_session(id, request) do |session|
          { output: session.eval(request.params[:input]) }
        end
      end

      def change_stack_trace(id, request)
        json_response_with_session(id, request) do |session|
          session.switch_binding_to(request.params[:frame_id])

          { ok: true }
        end
      end

      def respond_with_unavailable_session(id)
        json_response(status: 404) do
          { output: format(I18n.t('errors.unavailable_session'), id: id)}
        end
      end

      def respond_with_unacceptable_request
        json_response(status: 406) do
          { output: I18n.t('errors.unacceptable_request') }
        end
      end

      def call_app(env)
        @app.call(env)
      rescue => e
        throw :app_exception, e
      end
  end
end
