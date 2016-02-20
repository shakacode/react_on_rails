# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Set') do |defs|
  defs.define_constant('Set') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('ary')
    end

    klass.define_instance_method('&') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('^') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('add') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('add?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('classify')

    klass.define_instance_method('clear')

    klass.define_instance_method('collect!')

    klass.define_instance_method('delete') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('delete?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('delete_if')

    klass.define_instance_method('difference') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('divide') do |method|
      method.define_block_argument('func')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('empty?')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('flatten')

    klass.define_instance_method('flatten!')

    klass.define_instance_method('flatten_merge') do |method|
      method.define_argument('set')
      method.define_optional_argument('seen')
    end

    klass.define_instance_method('freeze')

    klass.define_instance_method('hash')

    klass.define_instance_method('include?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('enum')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('intersection') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('keep_if')

    klass.define_instance_method('length')

    klass.define_instance_method('map!')

    klass.define_instance_method('member?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('pp')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('pp')
    end

    klass.define_instance_method('proper_subset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('proper_superset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('reject!')

    klass.define_instance_method('replace') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('select!')

    klass.define_instance_method('size')

    klass.define_instance_method('subset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('subtract') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('superset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('taint')

    klass.define_instance_method('to_a')

    klass.define_instance_method('union') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('untaint')

    klass.define_instance_method('|') do |method|
      method.define_argument('enum')
    end
  end

  defs.define_constant('Set::Enumerator') do |klass|
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

  defs.define_constant('Set::InspectKey') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Set::SortedElement') do |klass|
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
