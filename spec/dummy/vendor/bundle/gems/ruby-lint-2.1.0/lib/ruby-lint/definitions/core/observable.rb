# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Observable') do |defs|
  defs.define_constant('Observable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_observer') do |method|
      method.define_argument('observer')
      method.define_optional_argument('func')
    end

    klass.define_instance_method('changed') do |method|
      method.define_optional_argument('state')
    end

    klass.define_instance_method('changed?')

    klass.define_instance_method('count_observers')

    klass.define_instance_method('delete_observer') do |method|
      method.define_argument('observer')
    end

    klass.define_instance_method('delete_observers')

    klass.define_instance_method('notify_observers') do |method|
      method.define_rest_argument('arg')
    end
  end
end
