# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Comparable') do |defs|
  defs.define_constant('Comparable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('compare_int') do |method|
      method.define_argument('int')
    end

    klass.define_instance_method('<') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<=') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>=') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('between?') do |method|
      method.define_argument('min')
      method.define_argument('max')
    end
  end
end
