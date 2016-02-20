# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'parslet'
  s.version = '1.7.1'

  s.authors = ['Kaspar Schiess']
  s.email = 'kaspar.schiess@absurd.li'
  s.extra_rdoc_files = ['README']
  s.files = %w(HISTORY.txt LICENSE Rakefile README parslet.gemspec) + Dir.glob("{lib,spec,example}/**/*")
  s.homepage = 'http://kschiess.github.io/parslet'
  s.license = 'MIT'
  s.rdoc_options = ['--main', 'README']
  s.require_paths = ['lib']
  s.summary = 'Parser construction library with great error reporting in Ruby.'  
  
  s.add_dependency 'blankslate', '>= 2.0', '<= 4.0'
end
