# vim: syntax=ruby
load 'tasks/this.rb'

This.name     = "launchy"
This.author   = "Jeremy Hinegardner"
This.email    = "jeremy@copiousfreetime.org"
This.homepage = "http://github.com/copiousfreetime/#{ This.name }"

This.ruby_gemspec do |spec|
  spec.add_dependency( 'addressable', '~> 2.3')

  spec.add_development_dependency( 'rake'     , '~> 10.1')
  spec.add_development_dependency( 'minitest' , '~> 5.0' )
  spec.add_development_dependency( 'rdoc'     , '~> 4.1' )
  
  spec.licenses = ['ISC']
end

This.java_gemspec( This.ruby_gemspec ) do |spec|
  spec.add_dependency( 'spoon', '~> 0.0.1' )

  spec.licenses = ['ISC']
end

load 'tasks/default.rake'
