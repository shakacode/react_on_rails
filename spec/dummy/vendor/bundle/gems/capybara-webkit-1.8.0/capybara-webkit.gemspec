$:.push File.expand_path("../lib", __FILE__)
require "capybara/webkit/version"

Gem::Specification.new do |s|
  s.name     = "capybara-webkit"
  s.version  = Capybara::Driver::Webkit::VERSION.dup
  s.authors  = ["thoughtbot", "Joe Ferris", "Matt Horan", "Matt Mongeau",
                "Mike Burns", "Jason Morrison"]
  s.email    = "support@thoughtbot.com"
  s.homepage = "http://github.com/thoughtbot/capybara-webkit"
  s.summary  = "Headless Webkit driver for Capybara"
  s.license  = 'MIT'

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {spec,features}/*`.split("\n")
  s.require_path = "lib"

  s.extensions = "extconf.rb"

  s.required_ruby_version = ">= 1.9.0"

  s.add_runtime_dependency("capybara", ">= 2.3.0", "< 2.7.0")
  s.add_runtime_dependency("json")

  s.add_development_dependency("rspec", "~> 2.14.0")
  # Sinatra is used by Capybara's TestApp
  s.add_development_dependency("sinatra")
  s.add_development_dependency("mini_magick")
  s.add_development_dependency("rake")
  s.add_development_dependency("appraisal", "~> 0.4.0")
  s.add_development_dependency("selenium-webdriver")
  s.add_development_dependency("launchy")
end

