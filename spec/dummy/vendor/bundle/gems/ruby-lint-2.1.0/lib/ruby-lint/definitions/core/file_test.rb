# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('FileTest') do |defs|
  defs.define_constant('FileTest') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('blockdev?') do |method|
      method.define_argument('path')
    end

    klass.define_method('chardev?') do |method|
      method.define_argument('path')
    end

    klass.define_method('directory?') do |method|
      method.define_argument('path')
    end

    klass.define_method('executable?') do |method|
      method.define_argument('path')
    end

    klass.define_method('executable_real?') do |method|
      method.define_argument('path')
    end

    klass.define_method('exist?') do |method|
      method.define_argument('path')
    end

    klass.define_method('exists?') do |method|
      method.define_argument('path')
    end

    klass.define_method('file?') do |method|
      method.define_argument('path')
    end

    klass.define_method('grpowned?') do |method|
      method.define_argument('path')
    end

    klass.define_method('identical?') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_method('owned?') do |method|
      method.define_argument('path')
    end

    klass.define_method('pipe?') do |method|
      method.define_argument('path')
    end

    klass.define_method('readable?') do |method|
      method.define_argument('path')
    end

    klass.define_method('readable_real?') do |method|
      method.define_argument('path')
    end

    klass.define_method('setgid?') do |method|
      method.define_argument('path')
    end

    klass.define_method('setuid?') do |method|
      method.define_argument('path')
    end

    klass.define_method('size') do |method|
      method.define_argument('path')
    end

    klass.define_method('size?') do |method|
      method.define_argument('path')
    end

    klass.define_method('socket?') do |method|
      method.define_argument('path')
    end

    klass.define_method('sticky?') do |method|
      method.define_argument('path')
    end

    klass.define_method('symlink?') do |method|
      method.define_argument('path')
    end

    klass.define_method('writable?') do |method|
      method.define_argument('path')
    end

    klass.define_method('writable_real?') do |method|
      method.define_argument('path')
    end

    klass.define_method('zero?') do |method|
      method.define_argument('path')
    end
  end
end
