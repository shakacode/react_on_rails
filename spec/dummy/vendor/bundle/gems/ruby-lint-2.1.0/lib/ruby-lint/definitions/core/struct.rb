# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Struct') do |defs|
  defs.define_constant('Struct') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('_specialize') do |method|
      method.define_argument('attrs')
    end

    klass.define_method('length')

    klass.define_method('make_struct') do |method|
      method.define_argument('name')
      method.define_argument('attrs')
    end

    klass.define_method('members')

    klass.define_method('new') do |method|
      method.define_argument('klass_name')
      method.define_rest_argument('attrs')

      method.returns { |object| object.instance }
    end

    klass.define_method('subclass_new') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('yaml_new') do |method|
      method.define_argument('klass')
      method.define_argument('tag')
      method.define_argument('val')
    end

    klass.define_method('yaml_tag_class_name')

    klass.define_method('yaml_tag_read_class') do |method|
      method.define_argument('name')
    end

    klass.define_method('yaml_tag_subclasses?')

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('var')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('var')
      method.define_argument('obj')
    end

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('each_pair')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('instance_variables')

    klass.define_instance_method('length')

    klass.define_instance_method('members')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('select')

    klass.define_instance_method('size')

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_h')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('values')

    klass.define_instance_method('values_at') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Struct::Enumerator') do |klass|
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

  defs.define_constant('Struct::SortedElement') do |klass|
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
