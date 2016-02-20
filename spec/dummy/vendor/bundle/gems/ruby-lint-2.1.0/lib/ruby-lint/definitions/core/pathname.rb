# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Pathname') do |defs|
  defs.define_constant('Pathname') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('getwd')

    klass.define_method('glob') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('pwd')

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('absolute?')

    klass.define_instance_method('ascend')

    klass.define_instance_method('atime')

    klass.define_instance_method('basename') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('binread') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('blockdev?')

    klass.define_instance_method('chardev?')

    klass.define_instance_method('children') do |method|
      method.define_optional_argument('with_directory')
    end

    klass.define_instance_method('chmod') do |method|
      method.define_argument('mode')
    end

    klass.define_instance_method('chown') do |method|
      method.define_argument('owner')
      method.define_argument('group')
    end

    klass.define_instance_method('cleanpath') do |method|
      method.define_optional_argument('consider_symlink')
    end

    klass.define_instance_method('ctime')

    klass.define_instance_method('delete')

    klass.define_instance_method('descend')

    klass.define_instance_method('directory?')

    klass.define_instance_method('dirname')

    klass.define_instance_method('each_child') do |method|
      method.define_optional_argument('with_directory')
      method.define_block_argument('b')
    end

    klass.define_instance_method('each_entry') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('each_filename')

    klass.define_instance_method('each_line') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('entries')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('executable?')

    klass.define_instance_method('executable_real?')

    klass.define_instance_method('exist?')

    klass.define_instance_method('expand_path') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('extname')

    klass.define_instance_method('file?')

    klass.define_instance_method('find') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('fnmatch') do |method|
      method.define_argument('pattern')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('fnmatch?') do |method|
      method.define_argument('pattern')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('freeze')

    klass.define_instance_method('ftype')

    klass.define_instance_method('grpowned?')

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('join') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('lchmod') do |method|
      method.define_argument('mode')
    end

    klass.define_instance_method('lchown') do |method|
      method.define_argument('owner')
      method.define_argument('group')
    end

    klass.define_instance_method('lstat')

    klass.define_instance_method('make_link') do |method|
      method.define_argument('old')
    end

    klass.define_instance_method('make_symlink') do |method|
      method.define_argument('old')
    end

    klass.define_instance_method('mkdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('mkpath')

    klass.define_instance_method('mountpoint?')

    klass.define_instance_method('mtime')

    klass.define_instance_method('open') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('opendir') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('owned?')

    klass.define_instance_method('parent')

    klass.define_instance_method('pipe?')

    klass.define_instance_method('read') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('readable?')

    klass.define_instance_method('readable_real?')

    klass.define_instance_method('readlines') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('readlink')

    klass.define_instance_method('realdirpath') do |method|
      method.define_optional_argument('basedir')
    end

    klass.define_instance_method('realpath') do |method|
      method.define_optional_argument('basedir')
    end

    klass.define_instance_method('relative?')

    klass.define_instance_method('relative_path_from') do |method|
      method.define_argument('base_directory')
    end

    klass.define_instance_method('rename') do |method|
      method.define_argument('to')
    end

    klass.define_instance_method('rmdir')

    klass.define_instance_method('rmtree')

    klass.define_instance_method('root?')

    klass.define_instance_method('setgid?')

    klass.define_instance_method('setuid?')

    klass.define_instance_method('size')

    klass.define_instance_method('size?')

    klass.define_instance_method('socket?')

    klass.define_instance_method('split')

    klass.define_instance_method('stat')

    klass.define_instance_method('sticky?')

    klass.define_instance_method('sub') do |method|
      method.define_argument('pattern')
      method.define_rest_argument('rest')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sub_ext') do |method|
      method.define_argument('repl')
    end

    klass.define_instance_method('symlink?')

    klass.define_instance_method('sysopen') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('taint')

    klass.define_instance_method('to_path')

    klass.define_instance_method('to_s')

    klass.define_instance_method('truncate') do |method|
      method.define_argument('length')
    end

    klass.define_instance_method('unlink')

    klass.define_instance_method('untaint')

    klass.define_instance_method('utime') do |method|
      method.define_argument('atime')
      method.define_argument('mtime')
    end

    klass.define_instance_method('world_readable?')

    klass.define_instance_method('world_writable?')

    klass.define_instance_method('writable?')

    klass.define_instance_method('writable_real?')

    klass.define_instance_method('zero?')
  end

  defs.define_constant('Pathname::SAME_PATHS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Pathname::SEPARATOR_LIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Pathname::SEPARATOR_PAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Pathname::TO_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
