# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Queue') do |defs|
  defs.define_constant('Queue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('deq') do |method|
      method.define_optional_argument('non_block')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('enq') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('length')

    klass.define_instance_method('num_waiting')

    klass.define_instance_method('pop') do |method|
      method.define_optional_argument('non_block')
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('shift') do |method|
      method.define_optional_argument('non_block')
    end

    klass.define_instance_method('size')
  end
end
