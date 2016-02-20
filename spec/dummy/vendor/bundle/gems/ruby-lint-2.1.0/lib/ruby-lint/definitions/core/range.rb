# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Range') do |defs|
  defs.define_constant('Range') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('yaml_new') do |method|
      method.define_argument('klass')
      method.define_argument('tag')
      method.define_argument('val')
    end

    klass.define_method('yaml_tag_subclasses?')

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
    end

    klass.define_instance_method('begin')

    klass.define_instance_method('cover?') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('end')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('exclude_end?')

    klass.define_instance_method('first') do |method|
      method.define_optional_argument('n')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('include?') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('first')
      method.define_argument('last')
      method.define_optional_argument('exclude_end')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('last') do |method|
      method.define_optional_argument('n')
    end

    klass.define_instance_method('max')

    klass.define_instance_method('member?') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('min')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('step') do |method|
      method.define_optional_argument('step_size')
    end

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end
  end

  defs.define_constant('Range::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('receiver_or_size')
      method.define_optional_argument('method_name')
      method.define_rest_argument('method_args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next')

    klass.define_instance_method('next_values')

    klass.define_instance_method('peek')

    klass.define_instance_method('peek_values')

    klass.define_instance_method('rewind')

    klass.define_instance_method('size')

    klass.define_instance_method('with_index') do |method|
      method.define_optional_argument('offset')
    end
  end

  defs.define_constant('Range::SortedElement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('val')
      method.define_argument('sort_id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('sort_id')

    klass.define_instance_method('value')
  end
end
