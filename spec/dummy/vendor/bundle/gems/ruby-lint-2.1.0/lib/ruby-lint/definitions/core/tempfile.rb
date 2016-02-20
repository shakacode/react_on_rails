# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('Tempfile') do |defs|
  defs.define_constant('Tempfile') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('basename')
      method.define_rest_argument('rest')
    end

    klass.define_method('open') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('_close')

    klass.define_instance_method('close') do |method|
      method.define_optional_argument('unlink_now')
    end

    klass.define_instance_method('close!')

    klass.define_instance_method('delete')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('basename')
      method.define_rest_argument('rest')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('length')

    klass.define_instance_method('open')

    klass.define_instance_method('path')

    klass.define_instance_method('size')

    klass.define_instance_method('unlink')
  end

  defs.define_constant('Tempfile::RUBYGEMS_ACTIVATION_MONITOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Tempfile::Remover') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('data')

      method.returns { |object| object.instance }
    end
  end
end
