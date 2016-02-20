# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Exception') do |defs|
  defs.define_constant('Exception') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('exception') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('yaml_new') do |method|
      method.define_argument('klass')
      method.define_argument('tag')
      method.define_argument('val')
    end

    klass.define_method('yaml_tag_subclasses?')

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('__initialize__') do |method|
      method.define_optional_argument('message')
    end

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
    end

    klass.define_instance_method('awesome_backtrace')

    klass.define_instance_method('backtrace')

    klass.define_instance_method('backtrace?')

    klass.define_instance_method('capture_backtrace!') do |method|
      method.define_optional_argument('offset')
    end

    klass.define_instance_method('exception') do |method|
      method.define_optional_argument('message')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('message')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('location')

    klass.define_instance_method('locations')

    klass.define_instance_method('locations=')

    klass.define_instance_method('message')

    klass.define_instance_method('parent')

    klass.define_instance_method('parent=')

    klass.define_instance_method('render') do |method|
      method.define_optional_argument('header')
      method.define_optional_argument('io')
      method.define_optional_argument('color')
    end

    klass.define_instance_method('set_backtrace') do |method|
      method.define_argument('bt')
    end

    klass.define_instance_method('set_context') do |method|
      method.define_argument('ctx')
    end

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('to_yaml_properties')
  end
end
