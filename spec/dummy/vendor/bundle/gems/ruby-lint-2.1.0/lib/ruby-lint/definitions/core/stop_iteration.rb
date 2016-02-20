# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('StopIteration') do |defs|
  defs.define_constant('StopIteration') do |klass|
    klass.inherits(defs.constant_proxy('IndexError', RubyLint.registry))

    klass.define_instance_method('result')
  end
end
