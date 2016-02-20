# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Scanf') do |defs|
  defs.define_constant('Scanf') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Scanf::FormatSpecifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('conversion')

    klass.define_instance_method('count_space?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('str')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('letter')

    klass.define_instance_method('match') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('matched')

    klass.define_instance_method('matched_string')

    klass.define_instance_method('mid_match?')

    klass.define_instance_method('re_string')

    klass.define_instance_method('to_re')

    klass.define_instance_method('to_s')

    klass.define_instance_method('width')
  end

  defs.define_constant('Scanf::FormatString') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('str')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('last_match_tried')

    klass.define_instance_method('last_spec')

    klass.define_instance_method('last_spec_tried')

    klass.define_instance_method('match') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('matched_count')

    klass.define_instance_method('prune') do |method|
      method.define_optional_argument('n')
    end

    klass.define_instance_method('space')

    klass.define_instance_method('spec_count')

    klass.define_instance_method('string_left')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Scanf::FormatString::REGEX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Scanf::FormatString::SPECIFIERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
