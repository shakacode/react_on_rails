require 'binding_of_caller'

require 'active_support/lazy_load_hooks'
require 'active_support/logger'

require 'web_console/integration'
require 'web_console/railtie'
require 'web_console/errors'
require 'web_console/helper'
require 'web_console/evaluator'
require 'web_console/session'
require 'web_console/template'
require 'web_console/middleware'
require 'web_console/whitelist'
require 'web_console/request'
require 'web_console/response'
require 'web_console/view'
require 'web_console/whiny_request'

module WebConsole
  mattr_accessor :logger
  @@logger = ActiveSupport::Logger.new($stderr)

  ActiveSupport.run_load_hooks(:web_console, self)
end
