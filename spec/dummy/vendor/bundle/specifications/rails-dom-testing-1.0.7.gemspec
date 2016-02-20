# -*- encoding: utf-8 -*-
# stub: rails-dom-testing 1.0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "rails-dom-testing"
  s.version = "1.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Rafael Mendon\u{e7}a Fran\u{e7}a", "Kasper Timm Hansen"]
  s.date = "2015-08-14"
  s.description = " This gem can compare doms and assert certain elements exists in doms using Nokogiri. "
  s.email = ["rafaelmfranca@gmail.com", "kaspth@gmail.com"]
  s.homepage = "https://github.com/rails/rails-dom-testing"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Dom and Selector assertions for Rails applications"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.6.0"])
      s.add_runtime_dependency(%q<activesupport>, ["< 5.0", ">= 4.2.0.beta"])
      s.add_runtime_dependency(%q<rails-deprecated_sanitizer>, [">= 1.0.1"])
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
    else
      s.add_dependency(%q<nokogiri>, ["~> 1.6.0"])
      s.add_dependency(%q<activesupport>, ["< 5.0", ">= 4.2.0.beta"])
      s.add_dependency(%q<rails-deprecated_sanitizer>, [">= 1.0.1"])
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
    end
  else
    s.add_dependency(%q<nokogiri>, ["~> 1.6.0"])
    s.add_dependency(%q<activesupport>, ["< 5.0", ">= 4.2.0.beta"])
    s.add_dependency(%q<rails-deprecated_sanitizer>, [">= 1.0.1"])
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
  end
end
