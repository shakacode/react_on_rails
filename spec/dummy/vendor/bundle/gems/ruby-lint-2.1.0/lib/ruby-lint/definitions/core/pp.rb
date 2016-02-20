# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('PP') do |defs|
  defs.define_constant('PP') do |klass|
    klass.inherits(defs.constant_proxy('PrettyPrint', RubyLint.registry))
    klass.inherits(defs.constant_proxy('PP::PPMethods', RubyLint.registry))

    klass.define_method('mcall') do |method|
      method.define_argument('obj')
      method.define_argument('mod')
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('pp') do |method|
      method.define_argument('obj')
      method.define_optional_argument('out')
      method.define_optional_argument('width')
    end

    klass.define_method('sharing_detection')

    klass.define_method('sharing_detection=')

    klass.define_method('singleline_pp') do |method|
      method.define_argument('obj')
      method.define_optional_argument('out')
    end
  end

  defs.define_constant('PP::Breakable') do |klass|
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

  defs.define_constant('PP::Group') do |klass|
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

  defs.define_constant('PP::GroupQueue') do |klass|
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

  defs.define_constant('PP::ObjectMixin') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('pretty_print_inspect')

    klass.define_instance_method('pretty_print_instance_variables')
  end

  defs.define_constant('PP::PPMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('check_inspect_key') do |method|
      method.define_argument('id')
    end

    klass.define_instance_method('comma_breakable')

    klass.define_instance_method('guard_inspect_key')

    klass.define_instance_method('object_address_group') do |method|
      method.define_argument('obj')
      method.define_block_argument('block')
    end

    klass.define_instance_method('object_group') do |method|
      method.define_argument('obj')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pop_inspect_key') do |method|
      method.define_argument('id')
    end

    klass.define_instance_method('pp') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('pp_hash') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('pp_object') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('push_inspect_key') do |method|
      method.define_argument('id')
    end

    klass.define_instance_method('seplist') do |method|
      method.define_argument('list')
      method.define_optional_argument('sep')
      method.define_optional_argument('iter_method')
    end
  end

  defs.define_constant('PP::PPMethods::PointerFormat') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PP::PPMethods::PointerMask') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PP::PointerFormat') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PP::PointerMask') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PP::SingleLine') do |klass|
    klass.inherits(defs.constant_proxy('PrettyPrint::SingleLine', RubyLint.registry))
    klass.inherits(defs.constant_proxy('PP::PPMethods', RubyLint.registry))

  end

  defs.define_constant('PP::SingleLine::PointerFormat') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PP::SingleLine::PointerMask') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('PP::Text') do |klass|
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
