# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Rational') do |defs|
  defs.define_constant('Rational') do |klass|
    klass.inherits(defs.constant_proxy('Numeric', RubyLint.registry))

    klass.define_method('yaml_new') do |method|
      method.define_argument('klass')
      method.define_argument('tag')
      method.define_argument('val')
    end

    klass.define_method('yaml_tag_subclasses?')

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

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('abs')

    klass.define_instance_method('ceil') do |method|
      method.define_optional_argument('precision')
    end

    klass.define_instance_method('coerce') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('denominator')

    klass.define_instance_method('div') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('divide') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('floor') do |method|
      method.define_optional_argument('precision')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('num')
      method.define_argument('den')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('numerator')

    klass.define_instance_method('quo') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('rationalize') do |method|
      method.define_optional_argument('eps')
    end

    klass.define_instance_method('round') do |method|
      method.define_optional_argument('precision')
    end

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('to_f')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_r')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('truncate') do |method|
      method.define_optional_argument('precision')
    end
  end
end
