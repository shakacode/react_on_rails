require 'action_view'
require 'action_dispatch'
require 'active_support/core_ext/string/access'
require 'json'
require 'web_console/whitelist'
require 'web_console/request'
require 'web_console/view'
require 'web_console/testing/helper'

module WebConsole
  module Testing
    class FakeMiddleware
      I18n.load_path.concat(Dir[Helper.gem_root.join('lib/web_console/locales/*.yml')])

      DEFAULT_HEADERS = { "Content-Type" => "application/javascript" }

      def initialize(opts)
        @headers        = opts.fetch(:headers, DEFAULT_HEADERS)
        @req_path_regex = opts[:req_path_regex]
        @view_path      = opts[:view_path]
      end

      def call(env)
        [ 200, @headers, [ render(req_path(env)) ] ]
      end

      def view
        @view ||= View.new(@view_path)
      end

      private

        # extract target path from REQUEST_PATH
        def req_path(env)
          env["REQUEST_PATH"].match(@req_path_regex)[1]
        end

        def render(template)
          view.render(template: template, layout: nil)
        end
    end
  end
end
