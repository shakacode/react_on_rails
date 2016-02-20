case RUBY_ENGINE
when 'rbx'
  require 'web_console/integration/rubinius'
when 'jruby'
  require 'web_console/integration/jruby'
when 'ruby'
  require 'web_console/integration/cruby'
end
