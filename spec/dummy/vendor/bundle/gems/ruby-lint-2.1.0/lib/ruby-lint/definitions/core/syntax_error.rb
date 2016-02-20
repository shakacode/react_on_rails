# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('SyntaxError') do |defs|
  defs.define_constant('SyntaxError') do |klass|
    klass.inherits(defs.constant_proxy('ScriptError', RubyLint.registry))

    klass.define_method('from') do |method|
      method.define_argument('message')
      method.define_argument('column')
      method.define_argument('line')
      method.define_argument('code')
      method.define_argument('file')
    end

    klass.define_instance_method('code')

    klass.define_instance_method('code=')

    klass.define_instance_method('column')

    klass.define_instance_method('column=')

    klass.define_instance_method('file')

    klass.define_instance_method('file=')

    klass.define_instance_method('line')

    klass.define_instance_method('line=')

    klass.define_instance_method('reason')
  end
end
