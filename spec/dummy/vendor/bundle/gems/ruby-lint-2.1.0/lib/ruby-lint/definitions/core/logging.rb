# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Logging') do |defs|
  defs.define_constant('Logging') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('log_close')

    klass.define_method('log_open')

    klass.define_method('logfile') do |method|
      method.define_argument('file')
    end

    klass.define_method('message') do |method|
      method.define_rest_argument('s')
    end

    klass.define_method('open')

    klass.define_method('postpone')

    klass.define_method('quiet')

    klass.define_method('quiet=')
  end
end
