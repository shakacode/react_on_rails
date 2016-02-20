require File.expand_path('../lib/ruby-lint/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'ruby-lint'
  s.version     = RubyLint::VERSION
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.authors     = ['Yorick Peterse']
  s.email       = 'yorickpeterse@gmail.com'
  s.summary     = 'A linter and static code analysis tool for Ruby.'
  s.homepage    = 'https://github.com/yorickpeterse/ruby-lint/'
  s.description = s.summary
  s.license     = 'MPL-2.0'

  s.post_install_message = 'Please report any issues at: ' \
    'https://github.com/YorickPeterse/ruby-lint/issues/new'

  s.files = Dir.glob([
    'checksum/*.*',
    'doc/**/*.*',
    'lib/**/*.*',
    '.yardopts',
    'CONTRIBUTING.md',
    'LICENSE',
    'README.md',
    '*.gemspec'
  ])

  s.executables = ['ruby-lint']

  s.has_rdoc              = 'yard'
  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'parser', ['~> 2.2']
  s.add_dependency 'slop', ['~> 3.4', '>= 3.4.7']

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'json'
  s.add_development_dependency 'kramdown'
  s.add_development_dependency 'redcard'
end
