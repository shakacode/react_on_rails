# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.2

RubyLint.registry.register('STDOUT') do |defs|
  defs.define_constant('STDOUT') do |klass|
    klass.inherits(defs.constant_proxy('IO', RubyLint.registry))
    klass.instance!
  end
end
