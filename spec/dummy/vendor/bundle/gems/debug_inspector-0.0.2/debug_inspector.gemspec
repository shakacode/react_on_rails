# -*- encoding: utf-8 -*-
require File.expand_path('../lib/debug_inspector/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = "debug_inspector"
  s.version = DebugInspector::VERSION
  s.authors = ["John Mair (banisterfiend)"]
  s.email = ["jrmair@gmail.com"]
  s.homepage = "https://github.com/banister/debug_inspector"
  s.summary = "A Ruby wrapper for the MRI 2.0 debug_inspector API"
  s.description = s.summary
  s.files         = `git ls-files`.split("\n")
  s.platform = Gem::Platform::RUBY
  s.extensions = ["ext/debug_inspector/extconf.rb"]
end
