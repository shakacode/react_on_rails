# -*- encoding: utf-8 -*-
# stub: rails-deprecated_sanitizer 1.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "rails-deprecated_sanitizer"
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Kasper Timm Hansen"]
  s.date = "2014-09-25"
  s.email = ["kaspth@gmail.com"]
  s.homepage = "https://github.com/rails/rails-deprecated_sanitizer"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Deprecated sanitizer API extracted from Action View."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 4.2.0.alpha"])
      s.add_development_dependency(%q<bundler>, ["~> 1.6"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 4.2.0.alpha"])
      s.add_dependency(%q<bundler>, ["~> 1.6"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 4.2.0.alpha"])
    s.add_dependency(%q<bundler>, ["~> 1.6"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
