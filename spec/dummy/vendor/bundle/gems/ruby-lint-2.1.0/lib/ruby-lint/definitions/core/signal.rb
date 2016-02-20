# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Signal') do |defs|
  defs.define_constant('Signal') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('list')

    klass.define_method('run_handler') do |method|
      method.define_argument('sig')
    end

    klass.define_method('trap') do |method|
      method.define_argument('sig')
      method.define_optional_argument('prc')
    end
  end

  defs.define_constant('Signal::Names') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Signal::Numbers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
