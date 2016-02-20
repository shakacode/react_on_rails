# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('PrettyPrint') do |defs|
  defs.define_constant('PrettyPrint') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('format') do |method|
      method.define_optional_argument('output')
      method.define_optional_argument('maxwidth')
      method.define_optional_argument('newline')
      method.define_optional_argument('genspace')
    end

    klass.define_method('singleline_format') do |method|
      method.define_optional_argument('output')
      method.define_optional_argument('maxwidth')
      method.define_optional_argument('newline')
      method.define_optional_argument('genspace')
    end

    klass.define_instance_method('break_outmost_groups')

    klass.define_instance_method('breakable') do |method|
      method.define_optional_argument('sep')
      method.define_optional_argument('width')
    end

    klass.define_instance_method('current_group')

    klass.define_instance_method('fill_breakable') do |method|
      method.define_optional_argument('sep')
      method.define_optional_argument('width')
    end

    klass.define_instance_method('first?')

    klass.define_instance_method('flush')

    klass.define_instance_method('genspace')

    klass.define_instance_method('group') do |method|
      method.define_optional_argument('indent')
      method.define_optional_argument('open_obj')
      method.define_optional_argument('close_obj')
      method.define_optional_argument('open_width')
      method.define_optional_argument('close_width')
    end

    klass.define_instance_method('group_queue')

    klass.define_instance_method('group_sub')

    klass.define_instance_method('indent')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('output')
      method.define_optional_argument('maxwidth')
      method.define_optional_argument('newline')
      method.define_block_argument('genspace')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('maxwidth')

    klass.define_instance_method('nest') do |method|
      method.define_argument('indent')
    end

    klass.define_instance_method('newline')

    klass.define_instance_method('output')

    klass.define_instance_method('text') do |method|
      method.define_argument('obj')
      method.define_optional_argument('width')
    end
  end

  defs.define_constant('PrettyPrint::Breakable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('indent')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('sep')
      method.define_argument('width')
      method.define_argument('q')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('obj')

    klass.define_instance_method('output') do |method|
      method.define_argument('out')
      method.define_argument('output_width')
    end

    klass.define_instance_method('width')
  end

  defs.define_constant('PrettyPrint::Group') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('break')

    klass.define_instance_method('break?')

    klass.define_instance_method('breakables')

    klass.define_instance_method('depth')

    klass.define_instance_method('first?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('depth')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('PrettyPrint::GroupQueue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('delete') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('deq')

    klass.define_instance_method('enq') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('groups')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('PrettyPrint::SingleLine') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('breakable') do |method|
      method.define_optional_argument('sep')
      method.define_optional_argument('width')
    end

    klass.define_instance_method('first?')

    klass.define_instance_method('flush')

    klass.define_instance_method('group') do |method|
      method.define_optional_argument('indent')
      method.define_optional_argument('open_obj')
      method.define_optional_argument('close_obj')
      method.define_optional_argument('open_width')
      method.define_optional_argument('close_width')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('output')
      method.define_optional_argument('maxwidth')
      method.define_optional_argument('newline')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('nest') do |method|
      method.define_argument('indent')
    end

    klass.define_instance_method('text') do |method|
      method.define_argument('obj')
      method.define_optional_argument('width')
    end
  end

  defs.define_constant('PrettyPrint::Text') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('obj')
      method.define_argument('width')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('output') do |method|
      method.define_argument('out')
      method.define_argument('output_width')
    end

    klass.define_instance_method('width')
  end
end
