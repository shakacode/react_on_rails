# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Mutex') do |defs|
  defs.define_constant('Mutex') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('lock')

    klass.define_instance_method('locked?')

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('bunk')
    end

    klass.define_instance_method('sleep') do |method|
      method.define_optional_argument('duration')
    end

    klass.define_instance_method('synchronize')

    klass.define_instance_method('try_lock')

    klass.define_instance_method('unlock')
  end
end
