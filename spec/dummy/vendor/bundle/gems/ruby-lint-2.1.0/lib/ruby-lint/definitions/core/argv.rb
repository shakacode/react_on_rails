# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.2

RubyLint.registry.register('ARGV') do |defs|
  defs.define_constant('ARGV') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))
    klass.instance!
  end
end
