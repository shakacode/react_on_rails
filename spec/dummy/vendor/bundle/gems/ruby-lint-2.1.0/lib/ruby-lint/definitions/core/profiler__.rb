# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Profiler__') do |defs|
  defs.define_constant('Profiler__') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('options') do |method|
      method.define_argument('opts')
    end

    klass.define_method('print_profile') do |method|
      method.define_argument('f')
    end

    klass.define_method('start_profile')

    klass.define_method('stop_profile')
  end
end
