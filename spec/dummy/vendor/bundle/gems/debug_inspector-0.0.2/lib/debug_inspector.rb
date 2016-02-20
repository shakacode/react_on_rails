require 'rbconfig'

dlext = RbConfig::CONFIG['DLEXT']

begin
  require "debug_inspector.#{dlext}"
rescue LoadError
end

