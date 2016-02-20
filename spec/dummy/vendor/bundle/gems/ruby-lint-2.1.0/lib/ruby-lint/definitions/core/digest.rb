# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Digest') do |defs|
  defs.define_constant('Digest') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('const_missing') do |method|
      method.define_argument('name')
    end

    klass.define_method('hexencode')
  end

  defs.define_constant('Digest::Base') do |klass|
    klass.inherits(defs.constant_proxy('Digest::Class', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('<<')

    klass.define_instance_method('block_length')

    klass.define_instance_method('digest_length')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('reset')

    klass.define_instance_method('update')
  end

  defs.define_constant('Digest::Class') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Digest::Instance', RubyLint.registry))

    klass.define_method('base64digest') do |method|
      method.define_argument('str')
      method.define_rest_argument('args')
    end

    klass.define_method('digest')

    klass.define_method('file') do |method|
      method.define_argument('name')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end
  end

  defs.define_constant('Digest::Instance') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<')

    klass.define_instance_method('==')

    klass.define_instance_method('base64digest') do |method|
      method.define_optional_argument('str')
    end

    klass.define_instance_method('base64digest!')

    klass.define_instance_method('block_length')

    klass.define_instance_method('digest')

    klass.define_instance_method('digest!')

    klass.define_instance_method('digest_length')

    klass.define_instance_method('file') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('hexdigest!')

    klass.define_instance_method('inspect')

    klass.define_instance_method('length')

    klass.define_instance_method('new')

    klass.define_instance_method('reset')

    klass.define_instance_method('size')

    klass.define_instance_method('to_s')

    klass.define_instance_method('update')
  end

  defs.define_constant('Digest::MD5') do |klass|
    klass.inherits(defs.constant_proxy('Digest::Base', RubyLint.registry))

  end

  defs.define_constant('Digest::SHA1') do |klass|
    klass.inherits(defs.constant_proxy('Digest::Base', RubyLint.registry))

  end

  defs.define_constant('Digest::SHA2') do |klass|
    klass.inherits(defs.constant_proxy('Digest::Class', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('block_length')

    klass.define_instance_method('digest_length')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('bitlen')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('reset')

    klass.define_instance_method('update') do |method|
      method.define_argument('str')
    end
  end

  defs.define_constant('Digest::SHA256') do |klass|
    klass.inherits(defs.constant_proxy('Digest::Base', RubyLint.registry))

  end

  defs.define_constant('Digest::SHA384') do |klass|
    klass.inherits(defs.constant_proxy('Digest::Base', RubyLint.registry))

  end

  defs.define_constant('Digest::SHA512') do |klass|
    klass.inherits(defs.constant_proxy('Digest::Base', RubyLint.registry))

  end
end
