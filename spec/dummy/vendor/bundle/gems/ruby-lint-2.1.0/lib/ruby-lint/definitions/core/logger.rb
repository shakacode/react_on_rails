# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Logger') do |defs|
  defs.define_constant('Logger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Logger::Severity', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('add') do |method|
      method.define_argument('severity')
      method.define_optional_argument('message')
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('datetime_format')

    klass.define_instance_method('datetime_format=') do |method|
      method.define_argument('datetime_format')
    end

    klass.define_instance_method('debug') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('debug?')

    klass.define_instance_method('error') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('error?')

    klass.define_instance_method('fatal') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('fatal?')

    klass.define_instance_method('formatter')

    klass.define_instance_method('formatter=')

    klass.define_instance_method('info') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('info?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('logdev')
      method.define_optional_argument('shift_age')
      method.define_optional_argument('shift_size')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('level')

    klass.define_instance_method('level=')

    klass.define_instance_method('log') do |method|
      method.define_argument('severity')
      method.define_optional_argument('message')
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('progname')

    klass.define_instance_method('progname=')

    klass.define_instance_method('sev_threshold')

    klass.define_instance_method('sev_threshold=')

    klass.define_instance_method('unknown') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('warn') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('warn?')
  end

  defs.define_constant('Logger::Application') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Logger::Severity', RubyLint.registry))

    klass.define_instance_method('appname')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('appname')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('level=') do |method|
      method.define_argument('level')
    end

    klass.define_instance_method('log') do |method|
      method.define_argument('severity')
      method.define_optional_argument('message')
      method.define_block_argument('block')
    end

    klass.define_instance_method('log=') do |method|
      method.define_argument('logdev')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('logger=') do |method|
      method.define_argument('logger')
    end

    klass.define_instance_method('set_log') do |method|
      method.define_argument('logdev')
      method.define_optional_argument('shift_age')
      method.define_optional_argument('shift_size')
    end

    klass.define_instance_method('start')
  end

  defs.define_constant('Logger::Application::DEBUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Application::ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Application::FATAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Application::INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Application::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Application::WARN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::DEBUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Error') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

  end

  defs.define_constant('Logger::FATAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Formatter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('severity')
      method.define_argument('time')
      method.define_argument('progname')
      method.define_argument('msg')
    end

    klass.define_instance_method('datetime_format')

    klass.define_instance_method('datetime_format=')

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Logger::Formatter::Format') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::LogDevice') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('dev')

    klass.define_instance_method('filename')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('log')
      method.define_optional_argument('opt')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('write') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('Logger::LogDevice::LogDeviceMutex') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('MonitorMixin', RubyLint.registry))

  end

  defs.define_constant('Logger::LogDevice::LogDeviceMutex::ConditionVariable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('monitor')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('signal')

    klass.define_instance_method('wait') do |method|
      method.define_optional_argument('timeout')
    end

    klass.define_instance_method('wait_until')

    klass.define_instance_method('wait_while')
  end

  defs.define_constant('Logger::LogDevice::SiD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::ProgName') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::SEV_LABEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Severity') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Severity::DEBUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Severity::ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Severity::FATAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Severity::INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Severity::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::Severity::WARN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::ShiftingError') do |klass|
    klass.inherits(defs.constant_proxy('Logger::Error', RubyLint.registry))

  end

  defs.define_constant('Logger::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Logger::WARN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
