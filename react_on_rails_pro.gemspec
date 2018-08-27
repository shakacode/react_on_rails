# rubocop:disable Metrics/BlockLength
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "react_on_rails_pro/version"

Gem::Specification.new do |s|
  s.name          = "react_on_rails_pro"
  s.version       = ReactOnRailsPro::VERSION
  s.authors       = ["Justin Gordon"]
  s.email         = ["justin@shakacode.com"]

  s.summary       = "Rails with react server rendering with webpack. Performance helpers"
  s.description   = "See README.md"
  s.homepage      = "https://github.com/shakacode/react_on_rails_pro"
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0")
                                     .reject { |f|
                                       f.match(%r{^(test|spec|features|tmp|node_modules|packages|coverage)/})
                                     }
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 2.1.0"

  s.add_dependency "react_on_rails", ">= 11.1.2"
  s.add_dependency "addressable"
  s.add_dependency "connection_pool"
  s.add_dependency "execjs", "~> 2.5"
  s.add_dependency "multipart-post", "~> 2"
  s.add_dependency "persistent_http", "~> 2"
  s.add_dependency "rails", ">= 3.2"
  s.add_dependency "rainbow"
  s.add_development_dependency "awesome_print"
  s.add_development_dependency "binding_of_caller"
  s.add_development_dependency "bundler", "~> 1.10"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "gem-release"
  s.add_development_dependency "generator_spec"
  s.add_development_dependency "listen"
  s.add_development_dependency "pry"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "pry-doc"
  s.add_development_dependency "pry-rescue"
  s.add_development_dependency "pry-stack_explorer"
  s.add_development_dependency "pry-state"
  s.add_development_dependency "pry-toys"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec"
end
# rubocop:enable Metrics/BlockLength
