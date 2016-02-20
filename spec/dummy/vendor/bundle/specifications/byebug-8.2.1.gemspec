# -*- encoding: utf-8 -*-
# stub: byebug 8.2.1 ruby lib
# stub: ext/byebug/extconf.rb

Gem::Specification.new do |s|
  s.name = "byebug"
  s.version = "8.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["David Rodriguez", "Kent Sibilev", "Mark Moseley"]
  s.date = "2015-11-26"
  s.description = "Byebug is a Ruby 2 debugger. It's implemented using the\n    Ruby 2 TracePoint C API for execution control and the Debug Inspector C API\n    for call stack navigation.  The core component provides support that\n    front-ends can build on. It provides breakpoint handling and bindings for\n    stack frames among other things and it comes with an easy to use command\n    line interface."
  s.email = "deivid.rodriguez@mail.com"
  s.executables = ["byebug"]
  s.extensions = ["ext/byebug/extconf.rb"]
  s.extra_rdoc_files = ["CHANGELOG.md", "CONTRIBUTING.md", "README.md", "GUIDE.md"]
  s.files = ["CHANGELOG.md", "CONTRIBUTING.md", "GUIDE.md", "README.md", "bin/byebug", "ext/byebug/extconf.rb"]
  s.homepage = "http://github.com/deivid-rodriguez/byebug"
  s.licenses = ["BSD"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0")
  s.rubygems_version = "2.5.1"
  s.summary = "Ruby 2.0 fast debugger - base + CLI"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.7"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.7"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.7"])
  end
end
