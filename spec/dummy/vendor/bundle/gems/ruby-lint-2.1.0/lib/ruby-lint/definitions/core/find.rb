# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Find') do |defs|
  defs.define_constant('Find') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('find') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_method('prune')
  end
end
