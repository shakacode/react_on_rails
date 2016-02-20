# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Vector') do |defs|
  defs.define_constant('Vector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Matrix::CoercionHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ExceptionForMatrix', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('array')
    end

    klass.define_method('elements') do |method|
      method.define_argument('array')
      method.define_optional_argument('copy')
    end

    klass.define_method('included') do |method|
      method.define_argument('mod')
    end

    klass.define_instance_method('*') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('/') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('Fail') do |method|
      method.define_optional_argument('err')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('Raise') do |method|
      method.define_optional_argument('err')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('i')
    end

    klass.define_instance_method('clone')

    klass.define_instance_method('coerce') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('collect') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('collect2') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('component') do |method|
      method.define_argument('i')
    end

    klass.define_instance_method('covector')

    klass.define_instance_method('cross_product') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('each2') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('element') do |method|
      method.define_argument('i')
    end

    klass.define_instance_method('elements')

    klass.define_instance_method('elements_to_f')

    klass.define_instance_method('elements_to_i')

    klass.define_instance_method('elements_to_r')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('array')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inner_product') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('magnitude')

    klass.define_instance_method('map') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('map2') do |method|
      method.define_argument('v')
      method.define_block_argument('block')
    end

    klass.define_instance_method('norm')

    klass.define_instance_method('normalize')

    klass.define_instance_method('r')

    klass.define_instance_method('size')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Vector::Enumerator') do |klass|
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

  defs.define_constant('Vector::ErrDimensionMismatch') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Vector::ErrNotRegular') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Vector::ErrOperationNotDefined') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Vector::ErrOperationNotImplemented') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Vector::SortedElement') do |klass|
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

  defs.define_constant('Vector::ZeroVectorError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end
end
