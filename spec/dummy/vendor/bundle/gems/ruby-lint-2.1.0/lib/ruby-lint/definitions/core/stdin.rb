# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.2

RubyLint.registry.register('STDIN') do |defs|
  defs.define_constant('STDIN') do |klass|
    klass.inherits(defs.constant_proxy('IO', RubyLint.registry))
    klass.instance!
  end
end
