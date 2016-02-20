# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Shellwords') do |defs|
  defs.define_constant('Shellwords') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('escape') do |method|
      method.define_argument('str')
    end

    klass.define_method('join') do |method|
      method.define_argument('array')
    end

    klass.define_method('shellescape') do |method|
      method.define_argument('str')
    end

    klass.define_method('shelljoin') do |method|
      method.define_argument('array')
    end

    klass.define_method('shellsplit') do |method|
      method.define_argument('line')
    end

    klass.define_method('shellwords') do |method|
      method.define_argument('line')
    end

    klass.define_method('split') do |method|
      method.define_argument('line')
    end
  end
end
