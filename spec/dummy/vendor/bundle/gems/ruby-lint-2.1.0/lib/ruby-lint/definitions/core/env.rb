# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.2

RubyLint.registry.register('ENV') do |defs|
  defs.define_constant('ENV') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))
    klass.instance!
  end
end
