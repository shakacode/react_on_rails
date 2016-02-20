require 'mkmf'
create_makefile('libv8')

require File.expand_path '../location', __FILE__
location = with_config('system-v8') ? Libv8::Location::System.new : Libv8::Location::Vendor.new

exit location.install!
