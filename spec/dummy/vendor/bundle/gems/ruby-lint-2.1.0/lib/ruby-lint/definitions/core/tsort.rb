# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('TSort') do |defs|
  defs.define_constant('TSort') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each_strongly_connected_component')

    klass.define_instance_method('each_strongly_connected_component_from') do |method|
      method.define_argument('node')
      method.define_optional_argument('id_map')
      method.define_optional_argument('stack')
    end

    klass.define_instance_method('strongly_connected_components')

    klass.define_instance_method('tsort')

    klass.define_instance_method('tsort_each')

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('tsort_each_node')
  end

  defs.define_constant('TSort::Cyclic') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end
end
