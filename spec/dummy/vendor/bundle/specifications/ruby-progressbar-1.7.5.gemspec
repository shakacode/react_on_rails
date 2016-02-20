# -*- encoding: utf-8 -*-
# stub: ruby-progressbar 1.7.5 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-progressbar"
  s.version = "1.7.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["thekompanee", "jfelchner"]
  s.date = "2015-03-25"
  s.description = "Ruby/ProgressBar is an extremely flexible text progress bar library for Ruby.\nThe output can be customized with a flexible formatting system including:\npercentage, bars of various formats, elapsed time and estimated time remaining.\n"
  s.email = "support@thekompanee.com"
  s.homepage = "https://github.com/jfelchner/ruby-progressbar"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Ruby/ProgressBar is a flexible text progress bar library for Ruby."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 3.1"])
      s.add_development_dependency(%q<rspectacular>, ["~> 0.21.6"])
      s.add_development_dependency(%q<fuubar>, ["~> 2.0"])
      s.add_development_dependency(%q<warning_filter>, ["~> 0.0.2"])
      s.add_development_dependency(%q<timecop>, ["~> 0.6.0"])
      s.add_development_dependency(%q<codeclimate-test-reporter>, ["~> 0.3.0"])
    else
      s.add_dependency(%q<rspec>, ["~> 3.1"])
      s.add_dependency(%q<rspectacular>, ["~> 0.21.6"])
      s.add_dependency(%q<fuubar>, ["~> 2.0"])
      s.add_dependency(%q<warning_filter>, ["~> 0.0.2"])
      s.add_dependency(%q<timecop>, ["~> 0.6.0"])
      s.add_dependency(%q<codeclimate-test-reporter>, ["~> 0.3.0"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 3.1"])
    s.add_dependency(%q<rspectacular>, ["~> 0.21.6"])
    s.add_dependency(%q<fuubar>, ["~> 2.0"])
    s.add_dependency(%q<warning_filter>, ["~> 0.0.2"])
    s.add_dependency(%q<timecop>, ["~> 0.6.0"])
    s.add_dependency(%q<codeclimate-test-reporter>, ["~> 0.3.0"])
  end
end
