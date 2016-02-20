# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name        'tins'
  author      'Florian Frank'
  email       'flori@ping.de'
  homepage    "https://github.com/flori/#{name}"
  summary     'Useful stuff.'
  description 'All the stuff that isn\'t good/big enough for a real library.'
  test_dir    'tests'
  test_files.concat Dir["#{test_dir}/*_test.rb"]
  ignore      '.*.sw[pon]', 'pkg', 'Gemfile.lock', '.rvmrc', 'coverage', '.rbx',
    '.AppleDouble', '.DS_Store', 'tags', '.bundle'

  readme      'README.md'
  licenses << 'MIT'

  development_dependency 'test-unit', '~>2.5'
end
