require "mkmf"

$CPPFLAGS = ""

dir_config("gl")
dir_config("zlib")

include_path = $CPPFLAGS.gsub("-I", "").strip
libs = $LIBPATH.map { |path| "-L#{path}"}.join(" ").strip

unless include_path.empty?
  ENV["CAPYBARA_WEBKIT_INCLUDE_PATH"] = include_path
end

unless libs.empty?
  ENV["CAPYBARA_WEBKIT_LIBS"] = libs
end

require File.join(File.expand_path(File.dirname(__FILE__)), "lib", "capybara_webkit_builder")
CapybaraWebkitBuilder.build_all
