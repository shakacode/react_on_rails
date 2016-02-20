# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('ThreadGroup') do |defs|
  defs.define_constant('ThreadGroup') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('thread')
    end

    klass.define_instance_method('enclose')

    klass.define_instance_method('enclosed?')

    klass.define_instance_method('initialize')

    klass.define_instance_method('list')

    klass.define_instance_method('remove') do |method|
      method.define_argument('thread')
    end
  end

  defs.define_constant('ThreadGroup::Default') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
