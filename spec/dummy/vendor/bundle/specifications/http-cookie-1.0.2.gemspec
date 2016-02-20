# -*- encoding: utf-8 -*-
# stub: http-cookie 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "http-cookie"
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Akinori MUSHA", "Aaron Patterson", "Eric Hodel", "Mike Dalessio"]
  s.date = "2013-09-10"
  s.description = "HTTP::Cookie is a Ruby library to handle HTTP Cookies based on RFC 6265.  It has with security, standards compliance and compatibility in mind, to behave just the same as today's major web browsers.  It has builtin support for the legacy cookies.txt and the latest cookies.sqlite formats of Mozilla Firefox, and its modular API makes it easy to add support for a new backend store."
  s.email = ["knu@idaemons.org", "aaronp@rubyforge.org", "drbrain@segment7.net", "mike.dalessio@gmail.com"]
  s.extra_rdoc_files = ["README.md", "LICENSE.txt"]
  s.files = ["LICENSE.txt", "README.md"]
  s.homepage = "https://github.com/sparklemotion/http-cookie"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "A Ruby library to handle HTTP Cookies based on RFC 6265"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<domain_name>, ["~> 0.5"])
      s.add_development_dependency(%q<sqlite3>, ["~> 1.3.3"])
      s.add_development_dependency(%q<bundler>, [">= 1.2.0"])
      s.add_development_dependency(%q<test-unit>, [">= 2.4.3"])
      s.add_development_dependency(%q<rake>, [">= 0.9.2.2"])
      s.add_development_dependency(%q<rdoc>, ["> 2.4.2"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
    else
      s.add_dependency(%q<domain_name>, ["~> 0.5"])
      s.add_dependency(%q<sqlite3>, ["~> 1.3.3"])
      s.add_dependency(%q<bundler>, [">= 1.2.0"])
      s.add_dependency(%q<test-unit>, [">= 2.4.3"])
      s.add_dependency(%q<rake>, [">= 0.9.2.2"])
      s.add_dependency(%q<rdoc>, ["> 2.4.2"])
      s.add_dependency(%q<simplecov>, [">= 0"])
    end
  else
    s.add_dependency(%q<domain_name>, ["~> 0.5"])
    s.add_dependency(%q<sqlite3>, ["~> 1.3.3"])
    s.add_dependency(%q<bundler>, [">= 1.2.0"])
    s.add_dependency(%q<test-unit>, [">= 2.4.3"])
    s.add_dependency(%q<rake>, [">= 0.9.2.2"])
    s.add_dependency(%q<rdoc>, ["> 2.4.2"])
    s.add_dependency(%q<simplecov>, [">= 0"])
  end
end
