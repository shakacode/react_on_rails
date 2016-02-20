# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Base64') do |defs|
  defs.define_constant('Base64') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('decode64') do |method|
      method.define_argument('str')
    end

    klass.define_method('encode64') do |method|
      method.define_argument('bin')
    end

    klass.define_method('strict_decode64') do |method|
      method.define_argument('str')
    end

    klass.define_method('strict_encode64') do |method|
      method.define_argument('bin')
    end

    klass.define_method('urlsafe_decode64') do |method|
      method.define_argument('str')
    end

    klass.define_method('urlsafe_encode64') do |method|
      method.define_argument('bin')
    end
  end
end
