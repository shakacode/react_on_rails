# -*- encoding: utf-8 -*-
# stub: mime-types 2.99 ruby lib

Gem::Specification.new do |s|
  s.name = "mime-types"
  s.version = "2.99"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Austin Ziegler"]
  s.date = "2015-11-21"
  s.description = "The mime-types library provides a library and registry for information about\nMIME content type definitions. It can be used to determine defined filename\nextensions for MIME types, or to use filename extensions to look up the likely\nMIME type definitions.\n\nThis is release 2.99, the deprecation version of mime-types 2.x, where\ndeprecation warnings are noisy and data that has been deprecated is now no\nlonger available. The data is both dropped from the data files and is stubbed\nout as empty or +nil+ values as appropriate.\n\nmime-types-2.6 was the last version of mime-types 2.x with newly available\nfeatures, and mime-types 2.99 will only receive quarterly updates to the IANA\nregistered MIME media types plus any security updates that may be required.\n\nIf the loss of the deprecated data matters, be sure to set your dependency\nappropriately:\n\n   gem 'mime-types', '~> 2.6, < 2.99'"
  s.email = ["halostatue@gmail.com"]
  s.extra_rdoc_files = ["Code-of-Conduct.rdoc", "Contributing.rdoc", "History-Types.rdoc", "History.rdoc", "Licence.rdoc", "Manifest.txt", "README.rdoc", "docs/COPYING.txt", "docs/artistic.txt"]
  s.files = ["Code-of-Conduct.rdoc", "Contributing.rdoc", "History-Types.rdoc", "History.rdoc", "Licence.rdoc", "Manifest.txt", "README.rdoc", "docs/COPYING.txt", "docs/artistic.txt"]
  s.homepage = "https://github.com/mime-types/ruby-mime-types/"
  s.licenses = ["MIT", "Artistic 2.0", "GPL-2"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.rubygems_version = "2.5.1"
  s.summary = "The mime-types library provides a library and registry for information about MIME content type definitions"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>, ["~> 5.8"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.6"])
      s.add_development_dependency(%q<hoe-rubygems>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-autotest>, ["~> 1.0"])
      s.add_development_dependency(%q<minitest-focus>, ["~> 1.0"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<fivemat>, ["~> 1.3"])
      s.add_development_dependency(%q<minitest-rg>, ["~> 5.2"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_development_dependency(%q<coveralls>, ["~> 0.8"])
      s.add_development_dependency(%q<hoe>, ["~> 3.14"])
    else
      s.add_dependency(%q<minitest>, ["~> 5.8"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_dependency(%q<hoe-git>, ["~> 1.6"])
      s.add_dependency(%q<hoe-rubygems>, ["~> 1.0"])
      s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_dependency(%q<minitest-autotest>, ["~> 1.0"])
      s.add_dependency(%q<minitest-focus>, ["~> 1.0"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<fivemat>, ["~> 1.3"])
      s.add_dependency(%q<minitest-rg>, ["~> 5.2"])
      s.add_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_dependency(%q<coveralls>, ["~> 0.8"])
      s.add_dependency(%q<hoe>, ["~> 3.14"])
    end
  else
    s.add_dependency(%q<minitest>, ["~> 5.8"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
    s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
    s.add_dependency(%q<hoe-git>, ["~> 1.6"])
    s.add_dependency(%q<hoe-rubygems>, ["~> 1.0"])
    s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
    s.add_dependency(%q<minitest-autotest>, ["~> 1.0"])
    s.add_dependency(%q<minitest-focus>, ["~> 1.0"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<fivemat>, ["~> 1.3"])
    s.add_dependency(%q<minitest-rg>, ["~> 5.2"])
    s.add_dependency(%q<simplecov>, ["~> 0.7"])
    s.add_dependency(%q<coveralls>, ["~> 0.8"])
    s.add_dependency(%q<hoe>, ["~> 3.14"])
  end
end
