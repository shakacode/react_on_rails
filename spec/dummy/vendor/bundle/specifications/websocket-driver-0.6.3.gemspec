# -*- encoding: utf-8 -*-
# stub: websocket-driver 0.6.3 ruby lib
# stub: ext/websocket-driver/extconf.rb

Gem::Specification.new do |s|
  s.name = "websocket-driver"
  s.version = "0.6.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["James Coglan"]
  s.date = "2015-11-06"
  s.email = "jcoglan@gmail.com"
  s.extensions = ["ext/websocket-driver/extconf.rb"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md", "ext/websocket-driver/extconf.rb"]
  s.homepage = "http://github.com/faye/websocket-driver-ruby"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--main", "README.md", "--markup", "markdown"]
  s.rubygems_version = "2.5.1"
  s.summary = "WebSocket protocol handler with pluggable I/O"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<websocket-extensions>, [">= 0.1.0"])
      s.add_development_dependency(%q<eventmachine>, [">= 0"])
      s.add_development_dependency(%q<permessage_deflate>, [">= 0"])
      s.add_development_dependency(%q<rake-compiler>, ["~> 0.8.0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<websocket-extensions>, [">= 0.1.0"])
      s.add_dependency(%q<eventmachine>, [">= 0"])
      s.add_dependency(%q<permessage_deflate>, [">= 0"])
      s.add_dependency(%q<rake-compiler>, ["~> 0.8.0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<websocket-extensions>, [">= 0.1.0"])
    s.add_dependency(%q<eventmachine>, [">= 0"])
    s.add_dependency(%q<permessage_deflate>, [">= 0"])
    s.add_dependency(%q<rake-compiler>, ["~> 0.8.0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
