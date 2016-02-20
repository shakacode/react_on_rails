# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('GC') do |defs|
  defs.define_constant('GC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('count')

    klass.define_method('disable')

    klass.define_method('enable')

    klass.define_method('run') do |method|
      method.define_argument('force')
    end

    klass.define_method('start')

    klass.define_method('stat')

    klass.define_method('stress')

    klass.define_method('stress=') do |method|
      method.define_argument('flag')
    end

    klass.define_instance_method('garbage_collect')
  end

  defs.define_constant('GC::Profiler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('clear')

    klass.define_method('disable')

    klass.define_method('enable')

    klass.define_method('enabled?')

    klass.define_method('report') do |method|
      method.define_optional_argument('out')
    end

    klass.define_method('result')

    klass.define_method('total_time')
  end
end
