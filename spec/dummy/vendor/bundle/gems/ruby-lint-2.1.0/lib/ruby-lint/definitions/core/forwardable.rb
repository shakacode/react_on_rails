# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Forwardable') do |defs|
  defs.define_constant('Forwardable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('debug')

    klass.define_method('debug=')

    klass.define_instance_method('def_delegator') do |method|
      method.define_argument('accessor')
      method.define_argument('method')
      method.define_optional_argument('ali')
    end

    klass.define_instance_method('def_delegators') do |method|
      method.define_argument('accessor')
      method.define_rest_argument('methods')
    end

    klass.define_instance_method('def_instance_delegator') do |method|
      method.define_argument('accessor')
      method.define_argument('method')
      method.define_optional_argument('ali')
    end

    klass.define_instance_method('def_instance_delegators') do |method|
      method.define_argument('accessor')
      method.define_rest_argument('methods')
    end

    klass.define_instance_method('delegate') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('instance_delegate') do |method|
      method.define_argument('hash')
    end
  end

  defs.define_constant('Forwardable::FILE_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Forwardable::FORWARDABLE_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
