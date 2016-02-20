# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('DRbIdConv') do |defs|
  defs.define_constant('DRbIdConv') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_id') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('to_obj') do |method|
      method.define_argument('ref')
    end
  end
end
