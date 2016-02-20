##
# Constant: Object
# Created:  2013-04-01 18:33:54 +0200
# Platform: rbx 2.0.0.rc1
#
RubyLint.registry.register('Object') do |defs|
  defs.define_constant('Object') do |klass|
    klass.inherits(defs.constant_proxy('BasicObject', RubyLint.registry))

    klass.define_method('__class_init__')

    klass.define_method('yaml_tag') do |method|
      method.define_argument('url')
    end

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
      method.define_optional_argument('strip_ivars')
    end

    klass.define_instance_method('__show__')

    klass.define_instance_method('psych_to_yaml') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('to_yaml_properties')
  end
end
