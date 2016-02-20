# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('GetoptLong') do |defs|
  defs.define_constant('GetoptLong') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each')

    klass.define_instance_method('each_option')

    klass.define_instance_method('error')

    klass.define_instance_method('error?')

    klass.define_instance_method('error_message')

    klass.define_instance_method('get')

    klass.define_instance_method('get_option')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arguments')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('ordering')

    klass.define_instance_method('ordering=') do |method|
      method.define_argument('ordering')
    end

    klass.define_instance_method('quiet')

    klass.define_instance_method('quiet=')

    klass.define_instance_method('quiet?')

    klass.define_instance_method('set_error') do |method|
      method.define_argument('type')
      method.define_argument('message')
    end

    klass.define_instance_method('set_options') do |method|
      method.define_rest_argument('arguments')
    end

    klass.define_instance_method('terminate')

    klass.define_instance_method('terminated?')
  end

  defs.define_constant('GetoptLong::ARGUMENT_FLAGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::AmbiguousOption') do |klass|
    klass.inherits(defs.constant_proxy('GetoptLong::Error', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::InvalidOption') do |klass|
    klass.inherits(defs.constant_proxy('GetoptLong::Error', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::MissingArgument') do |klass|
    klass.inherits(defs.constant_proxy('GetoptLong::Error', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::NO_ARGUMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::NeedlessArgument') do |klass|
    klass.inherits(defs.constant_proxy('GetoptLong::Error', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::OPTIONAL_ARGUMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::ORDERINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::PERMUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::REQUIRED_ARGUMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::REQUIRE_ORDER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::RETURN_IN_ORDER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::STATUS_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::STATUS_TERMINATED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GetoptLong::STATUS_YET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
