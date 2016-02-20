# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('ExceptionForMatrix') do |defs|
  defs.define_constant('ExceptionForMatrix') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('mod')
    end

    klass.define_instance_method('Fail') do |method|
      method.define_optional_argument('err')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('Raise') do |method|
      method.define_optional_argument('err')
      method.define_rest_argument('rest')
    end
  end

  defs.define_constant('ExceptionForMatrix::ErrDimensionMismatch') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ExceptionForMatrix::ErrNotRegular') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ExceptionForMatrix::ErrOperationNotDefined') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ExceptionForMatrix::ErrOperationNotImplemented') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end
end
