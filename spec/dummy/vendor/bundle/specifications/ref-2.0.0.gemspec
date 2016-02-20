# -*- encoding: utf-8 -*-
# stub: ref 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ref"
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Brian Durand", "The Ruby Concurrency Team"]
  s.date = "2015-07-10"
  s.description = "Library that implements weak, soft, and strong references in Ruby that work across multiple runtimes (MRI,Jruby and Rubinius). Also includes implementation of maps/hashes that use references and a reference queue."
  s.email = ["bbdurand@gmail.com", "concurrent-ruby@googlegroups.com"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md"]
  s.homepage = "http://github.com/ruby-concurrency/ref"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--charset=UTF-8", "--main", "README.md"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.5.1"
  s.summary = "Library that implements weak, soft, and strong references in Ruby."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version
end
