# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('GServer') do |defs|
  defs.define_constant('GServer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('in_service?') do |method|
      method.define_argument('port')
      method.define_optional_argument('host')
    end

    klass.define_method('stop') do |method|
      method.define_argument('port')
      method.define_optional_argument('host')
    end

    klass.define_instance_method('audit')

    klass.define_instance_method('audit=')

    klass.define_instance_method('connecting') do |method|
      method.define_argument('client')
    end

    klass.define_instance_method('connections')

    klass.define_instance_method('debug')

    klass.define_instance_method('debug=')

    klass.define_instance_method('disconnecting') do |method|
      method.define_argument('clientPort')
    end

    klass.define_instance_method('error') do |method|
      method.define_argument('detail')
    end

    klass.define_instance_method('host')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('port')
      method.define_optional_argument('host')
      method.define_optional_argument('maxConnections')
      method.define_optional_argument('stdlog')
      method.define_optional_argument('audit')
      method.define_optional_argument('debug')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('join')

    klass.define_instance_method('log') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('maxConnections')

    klass.define_instance_method('port')

    klass.define_instance_method('serve') do |method|
      method.define_argument('io')
    end

    klass.define_instance_method('shutdown')

    klass.define_instance_method('start') do |method|
      method.define_optional_argument('maxConnections')
    end

    klass.define_instance_method('starting')

    klass.define_instance_method('stdlog')

    klass.define_instance_method('stdlog=')

    klass.define_instance_method('stop')

    klass.define_instance_method('stopped?')

    klass.define_instance_method('stopping')
  end

  defs.define_constant('GServer::DEFAULT_HOST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
