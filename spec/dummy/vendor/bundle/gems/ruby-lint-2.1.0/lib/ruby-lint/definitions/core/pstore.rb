# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('PStore') do |defs|
  defs.define_constant('PStore') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('abort')

    klass.define_instance_method('commit')

    klass.define_instance_method('delete') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('fetch') do |method|
      method.define_argument('name')
      method.define_optional_argument('default')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('file')
      method.define_optional_argument('thread_safe')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('path')

    klass.define_instance_method('root?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('roots')

    klass.define_instance_method('transaction') do |method|
      method.define_optional_argument('read_only')
      method.define_block_argument('block')
    end

    klass.define_instance_method('ultra_safe')

    klass.define_instance_method('ultra_safe=')
  end

  defs.define_constant('PStore::EMPTY_MARSHAL_CHECKSUM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PStore::EMPTY_MARSHAL_DATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PStore::EMPTY_STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PStore::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('PStore::RDWR_ACCESS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PStore::RD_ACCESS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PStore::WR_ACCESS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
