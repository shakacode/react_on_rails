# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('SecureRandom') do |defs|
  defs.define_constant('SecureRandom') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('base64') do |method|
      method.define_optional_argument('n')
    end

    klass.define_method('hex') do |method|
      method.define_optional_argument('n')
    end

    klass.define_method('lastWin32ErrorMessage')

    klass.define_method('random_bytes') do |method|
      method.define_optional_argument('n')
    end

    klass.define_method('random_number') do |method|
      method.define_optional_argument('n')
    end

    klass.define_method('urlsafe_base64') do |method|
      method.define_optional_argument('n')
      method.define_optional_argument('padding')
    end

    klass.define_method('uuid')
  end
end
