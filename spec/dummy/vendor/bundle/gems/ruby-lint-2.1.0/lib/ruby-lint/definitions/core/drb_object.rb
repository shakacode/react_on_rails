# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('DRbObject') do |defs|
  defs.define_constant('DRbObject') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('_load') do |method|
      method.define_argument('s')
    end

    klass.define_method('new_with') do |method|
      method.define_argument('uri')
      method.define_argument('ref')
    end

    klass.define_method('new_with_uri') do |method|
      method.define_argument('uri')
    end

    klass.define_method('prepare_backtrace') do |method|
      method.define_argument('uri')
      method.define_argument('result')
    end

    klass.define_method('with_friend') do |method|
      method.define_argument('uri')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('__drbref')

    klass.define_instance_method('__drburi')

    klass.define_instance_method('_dump') do |method|
      method.define_argument('lv')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('obj')
      method.define_optional_argument('uri')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('msg_id')
      method.define_rest_argument('a')
      method.define_block_argument('b')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('msg_id')
      method.define_optional_argument('priv')
    end
  end
end
