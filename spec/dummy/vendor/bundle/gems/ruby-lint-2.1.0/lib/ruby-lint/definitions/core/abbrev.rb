# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Abbrev') do |defs|
  defs.define_constant('Abbrev') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('abbrev') do |method|
      method.define_argument('words')
      method.define_optional_argument('pattern')
    end
  end
end
