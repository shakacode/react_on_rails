# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('ObjectSpace') do |defs|
  defs.define_constant('ObjectSpace') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('_id2ref') do |method|
      method.define_argument('id')
    end

    klass.define_method('define_finalizer') do |method|
      method.define_argument('obj')
      method.define_optional_argument('prc')
    end

    klass.define_method('each_object') do |method|
      method.define_optional_argument('what')
    end

    klass.define_method('find_object') do |method|
      method.define_argument('query')
      method.define_argument('callable')
    end

    klass.define_method('find_references') do |method|
      method.define_argument('obj')
    end

    klass.define_method('garbage_collect')

    klass.define_method('run_finalizers')

    klass.define_method('undefine_finalizer') do |method|
      method.define_argument('obj')
    end
  end
end
