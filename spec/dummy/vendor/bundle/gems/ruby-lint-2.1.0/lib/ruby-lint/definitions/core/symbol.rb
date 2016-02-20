# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Symbol') do |defs|
  defs.define_constant('Symbol') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ImmediateValue', RubyLint.registry))

    klass.define_method('===') do |method|
      method.define_argument('obj')
    end

    klass.define_method('all_symbols')

    klass.define_method('yaml_new') do |method|
      method.define_argument('klass')
      method.define_argument('tag')
      method.define_argument('val')
    end

    klass.define_method('yaml_tag_subclasses?')

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('=~') do |method|
      method.define_argument('pattern')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('index')
      method.define_optional_argument('other')
    end

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
    end

    klass.define_instance_method('capitalize')

    klass.define_instance_method('casecmp') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('downcase')

    klass.define_instance_method('empty?')

    klass.define_instance_method('encoding')

    klass.define_instance_method('id2name')

    klass.define_instance_method('index')

    klass.define_instance_method('inspect')

    klass.define_instance_method('intern')

    klass.define_instance_method('is_constant?')

    klass.define_instance_method('is_cvar?')

    klass.define_instance_method('is_ivar?')

    klass.define_instance_method('length')

    klass.define_instance_method('match') do |method|
      method.define_argument('pattern')
    end

    klass.define_instance_method('next')

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('slice') do |method|
      method.define_argument('index')
      method.define_optional_argument('other')
    end

    klass.define_instance_method('succ')

    klass.define_instance_method('swapcase')

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('to_proc')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_sym')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('upcase')
  end
end
