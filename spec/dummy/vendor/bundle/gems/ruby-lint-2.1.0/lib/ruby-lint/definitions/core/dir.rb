# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Dir') do |defs|
  defs.define_constant('Dir') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('patterns')
    end

    klass.define_method('allocate')

    klass.define_method('chdir') do |method|
      method.define_optional_argument('path')
    end

    klass.define_method('chroot') do |method|
      method.define_argument('path')
    end

    klass.define_method('delete') do |method|
      method.define_argument('path')
    end

    klass.define_method('entries') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_method('exist?') do |method|
      method.define_argument('path')
    end

    klass.define_method('exists?') do |method|
      method.define_argument('path')
    end

    klass.define_method('foreach') do |method|
      method.define_argument('path')
    end

    klass.define_method('getwd')

    klass.define_method('glob') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('flags')
    end

    klass.define_method('glob_split') do |method|
      method.define_argument('pattern')
    end

    klass.define_method('home') do |method|
      method.define_optional_argument('user')
    end

    klass.define_method('join_path') do |method|
      method.define_argument('p1')
      method.define_argument('p2')
      method.define_argument('dirsep')
    end

    klass.define_method('mkdir') do |method|
      method.define_argument('path')
      method.define_optional_argument('mode')
    end

    klass.define_method('mktmpdir') do |method|
      method.define_optional_argument('prefix_suffix')
      method.define_rest_argument('rest')
    end

    klass.define_method('open') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_method('pwd')

    klass.define_method('rmdir') do |method|
      method.define_argument('path')
    end

    klass.define_method('tmpdir')

    klass.define_method('unlink') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('closed?')

    klass.define_instance_method('each')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('path')

    klass.define_instance_method('pos')

    klass.define_instance_method('pos=') do |method|
      method.define_argument('position')
    end

    klass.define_instance_method('read')

    klass.define_instance_method('rewind')

    klass.define_instance_method('seek') do |method|
      method.define_argument('position')
    end

    klass.define_instance_method('tell')

    klass.define_instance_method('to_path')
  end
end
