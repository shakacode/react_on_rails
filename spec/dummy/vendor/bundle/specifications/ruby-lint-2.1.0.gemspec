# -*- encoding: utf-8 -*-
# stub: ruby-lint 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-lint"
  s.version = "2.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Yorick Peterse"]
  s.date = "2016-01-22"
  s.description = "A linter and static code analysis tool for Ruby."
  s.email = "yorickpeterse@gmail.com"
  s.executables = ["ruby-lint"]
  s.files = ["bin/ruby-lint"]
  s.homepage = "https://github.com/yorickpeterse/ruby-lint/"
  s.licenses = ["MPL-2.0"]
  s.post_install_message = "Please report any issues at: https://github.com/YorickPeterse/ruby-lint/issues/new"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.5.1"
  s.summary = "A linter and static code analysis tool for Ruby."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<parser>, ["~> 2.2"])
      s.add_runtime_dependency(%q<slop>, [">= 3.4.7", "~> 3.4"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 3.0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<kramdown>, [">= 0"])
      s.add_development_dependency(%q<redcard>, [">= 0"])
    else
      s.add_dependency(%q<parser>, ["~> 2.2"])
      s.add_dependency(%q<slop>, [">= 3.4.7", "~> 3.4"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 3.0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<kramdown>, [">= 0"])
      s.add_dependency(%q<redcard>, [">= 0"])
    end
  else
    s.add_dependency(%q<parser>, ["~> 2.2"])
    s.add_dependency(%q<slop>, [">= 3.4.7", "~> 3.4"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 3.0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<kramdown>, [">= 0"])
    s.add_dependency(%q<redcard>, [">= 0"])
  end
end
