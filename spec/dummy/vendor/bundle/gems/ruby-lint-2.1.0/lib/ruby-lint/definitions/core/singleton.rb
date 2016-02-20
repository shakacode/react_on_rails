# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Singleton') do |defs|
  defs.define_constant('Singleton') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('__init__') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_optional_argument('depth')
    end

    klass.define_instance_method('clone')

    klass.define_instance_method('dup')
  end

  defs.define_constant('Singleton::SingletonClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('clone')
  end
end
