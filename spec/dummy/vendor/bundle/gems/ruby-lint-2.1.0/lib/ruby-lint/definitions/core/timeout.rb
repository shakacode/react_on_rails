# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Timeout') do |defs|
  defs.define_constant('Timeout') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_timeout') do |method|
      method.define_argument('time')
      method.define_argument('exc')
    end

    klass.define_method('timeout') do |method|
      method.define_argument('sec')
      method.define_optional_argument('exception')
    end

    klass.define_method('watch_channel')
  end

  defs.define_constant('Timeout::Error') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

  end

  defs.define_constant('Timeout::TimeoutRequest') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('abort')

    klass.define_instance_method('cancel')

    klass.define_instance_method('elapsed') do |method|
      method.define_argument('time')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('secs')
      method.define_argument('thr')
      method.define_argument('exc')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('left')

    klass.define_instance_method('thread')
  end
end
