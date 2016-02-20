# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Matrix') do |defs|
  defs.define_constant('Matrix') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Matrix::CoercionHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ExceptionForMatrix', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('I') do |method|
      method.define_argument('n')
    end

    klass.define_method('[]') do |method|
      method.define_rest_argument('rows')
    end

    klass.define_method('build') do |method|
      method.define_argument('row_count')
      method.define_optional_argument('column_count')
    end

    klass.define_method('column_vector') do |method|
      method.define_argument('column')
    end

    klass.define_method('columns') do |method|
      method.define_argument('columns')
    end

    klass.define_method('diagonal') do |method|
      method.define_rest_argument('values')
    end

    klass.define_method('empty') do |method|
      method.define_optional_argument('row_count')
      method.define_optional_argument('column_count')
    end

    klass.define_method('identity') do |method|
      method.define_argument('n')
    end

    klass.define_method('included') do |method|
      method.define_argument('mod')
    end

    klass.define_method('row_vector') do |method|
      method.define_argument('row')
    end

    klass.define_method('rows') do |method|
      method.define_argument('rows')
      method.define_optional_argument('copy')
    end

    klass.define_method('scalar') do |method|
      method.define_argument('n')
      method.define_argument('value')
    end

    klass.define_method('unit') do |method|
      method.define_argument('n')
    end

    klass.define_method('zero') do |method|
      method.define_argument('row_count')
      method.define_optional_argument('column_count')
    end

    klass.define_instance_method('*') do |method|
      method.define_argument('m')
    end

    klass.define_instance_method('**') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('m')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('m')
    end

    klass.define_instance_method('/') do |method|
      method.define_argument('other')
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
      method.define_argument('j')
    end

    klass.define_instance_method('clone')

    klass.define_instance_method('coerce') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('collect') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('column') do |method|
      method.define_argument('j')
    end

    klass.define_instance_method('column_count')

    klass.define_instance_method('column_size')

    klass.define_instance_method('column_vectors')

    klass.define_instance_method('component') do |method|
      method.define_argument('i')
      method.define_argument('j')
    end

    klass.define_instance_method('conj')

    klass.define_instance_method('conjugate')

    klass.define_instance_method('det')

    klass.define_instance_method('det_e')

    klass.define_instance_method('determinant')

    klass.define_instance_method('determinant_e')

    klass.define_instance_method('diagonal?')

    klass.define_instance_method('each') do |method|
      method.define_optional_argument('which')
    end

    klass.define_instance_method('each_with_index') do |method|
      method.define_optional_argument('which')
    end

    klass.define_instance_method('eigen')

    klass.define_instance_method('eigensystem')

    klass.define_instance_method('element') do |method|
      method.define_argument('i')
      method.define_argument('j')
    end

    klass.define_instance_method('elements_to_f')

    klass.define_instance_method('elements_to_i')

    klass.define_instance_method('elements_to_r')

    klass.define_instance_method('empty?')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('find_index') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('hermitian?')

    klass.define_instance_method('imag')

    klass.define_instance_method('imaginary')

    klass.define_instance_method('index') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('rows')
      method.define_optional_argument('column_count')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('inv')

    klass.define_instance_method('inverse')

    klass.define_instance_method('lower_triangular?')

    klass.define_instance_method('lup')

    klass.define_instance_method('lup_decomposition')

    klass.define_instance_method('map') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('minor') do |method|
      method.define_rest_argument('param')
    end

    klass.define_instance_method('normal?')

    klass.define_instance_method('orthogonal?')

    klass.define_instance_method('permutation?')

    klass.define_instance_method('rank')

    klass.define_instance_method('rank_e')

    klass.define_instance_method('real')

    klass.define_instance_method('real?')

    klass.define_instance_method('rect')

    klass.define_instance_method('rectangular')

    klass.define_instance_method('regular?')

    klass.define_instance_method('round') do |method|
      method.define_optional_argument('ndigits')
    end

    klass.define_instance_method('row') do |method|
      method.define_argument('i')
      method.define_block_argument('block')
    end

    klass.define_instance_method('row_count')

    klass.define_instance_method('row_size')

    klass.define_instance_method('row_vectors')

    klass.define_instance_method('rows')

    klass.define_instance_method('singular?')

    klass.define_instance_method('square?')

    klass.define_instance_method('symmetric?')

    klass.define_instance_method('t')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')

    klass.define_instance_method('tr')

    klass.define_instance_method('trace')

    klass.define_instance_method('transpose')

    klass.define_instance_method('unitary?')

    klass.define_instance_method('upper_triangular?')

    klass.define_instance_method('zero?')
  end

  defs.define_constant('Matrix::CoercionHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('coerce_to') do |method|
      method.define_argument('obj')
      method.define_argument('cls')
      method.define_argument('meth')
    end

    klass.define_method('coerce_to_int') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('Matrix::ConversionHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Matrix::EigenvalueDecomposition') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('d')

    klass.define_instance_method('eigenvalue_matrix')

    klass.define_instance_method('eigenvalues')

    klass.define_instance_method('eigenvector_matrix')

    klass.define_instance_method('eigenvector_matrix_inv')

    klass.define_instance_method('eigenvectors')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('a')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_ary')

    klass.define_instance_method('v')

    klass.define_instance_method('v_inv')
  end

  defs.define_constant('Matrix::Enumerator') do |klass|
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

  defs.define_constant('Matrix::ErrDimensionMismatch') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Matrix::ErrNotRegular') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Matrix::ErrOperationNotDefined') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Matrix::ErrOperationNotImplemented') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Matrix::LUPDecomposition') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Matrix::ConversionHelper', RubyLint.registry))

    klass.define_instance_method('det')

    klass.define_instance_method('determinant')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('a')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('l')

    klass.define_instance_method('p')

    klass.define_instance_method('pivots')

    klass.define_instance_method('singular?')

    klass.define_instance_method('solve') do |method|
      method.define_argument('b')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_ary')

    klass.define_instance_method('u')
  end

  defs.define_constant('Matrix::SELECTORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Matrix::Scalar') do |klass|
    klass.inherits(defs.constant_proxy('Numeric', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Matrix::CoercionHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ExceptionForMatrix', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('mod')
    end

    klass.define_instance_method('*') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('**') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('/') do |method|
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

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Matrix::Scalar::ErrDimensionMismatch') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Matrix::Scalar::ErrNotRegular') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Matrix::Scalar::ErrOperationNotDefined') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Matrix::Scalar::ErrOperationNotImplemented') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Matrix::SortedElement') do |klass|
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
