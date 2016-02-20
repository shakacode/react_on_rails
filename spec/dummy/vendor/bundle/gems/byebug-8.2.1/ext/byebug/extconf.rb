if RUBY_VERSION < '2.0'
  STDERR.print("Ruby version is too old\n")
  exit(1)
end

require 'mkmf'

makefile_config = RbConfig::MAKEFILE_CONFIG

makefile_config['CC'] = ENV['CC'] if ENV['CC']

makefile_config['CFLAGS'] << ' -Wall -Werror'
makefile_config['CFLAGS'] << ' -gdwarf-2 -g3 -O0' if ENV['debug']

if makefile_config['CC'] =~ /clang/
  makefile_config['CFLAGS'] << ' -Wno-unknown-warning-option'
end

dir_config('ruby')
with_cflags(makefile_config['CFLAGS']) { create_makefile('byebug/byebug') }
