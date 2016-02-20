# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('File') do |defs|
  defs.define_constant('File') do |klass|
    klass.inherits(defs.constant_proxy('IO', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('absolute_path') do |method|
      method.define_argument('obj')
      method.define_optional_argument('dir')
    end

    klass.define_method('atime') do |method|
      method.define_argument('path')
    end

    klass.define_method('basename') do |method|
      method.define_argument('path')
      method.define_optional_argument('ext')
    end

    klass.define_method('blockdev?') do |method|
      method.define_argument('path')
    end

    klass.define_method('chardev?') do |method|
      method.define_argument('path')
    end

    klass.define_method('chmod') do |method|
      method.define_argument('mode')
      method.define_rest_argument('paths')
    end

    klass.define_method('chown') do |method|
      method.define_argument('owner')
      method.define_argument('group')
      method.define_rest_argument('paths')
    end

    klass.define_method('clamp_short') do |method|
      method.define_argument('value')
    end

    klass.define_method('ctime') do |method|
      method.define_argument('path')
    end

    klass.define_method('delete') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_method('directory?') do |method|
      method.define_argument('io_or_path')
    end

    klass.define_method('dirname') do |method|
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

    klass.define_method('expand_path') do |method|
      method.define_argument('path')
      method.define_optional_argument('dir')
    end

    klass.define_method('extname') do |method|
      method.define_argument('path')
    end

    klass.define_method('file?') do |method|
      method.define_argument('path')
    end

    klass.define_method('fnmatch') do |method|
      method.define_argument('pattern')
      method.define_argument('path')
      method.define_optional_argument('flags')
    end

    klass.define_method('fnmatch?') do |method|
      method.define_argument('pattern')
      method.define_argument('path')
      method.define_optional_argument('flags')
    end

    klass.define_method('ftype') do |method|
      method.define_argument('path')
    end

    klass.define_method('grpowned?') do |method|
      method.define_argument('path')
    end

    klass.define_method('identical?') do |method|
      method.define_argument('orig')
      method.define_argument('copy')
    end

    klass.define_method('join') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('last_nonslash') do |method|
      method.define_argument('path')
      method.define_optional_argument('start')
    end

    klass.define_method('lchmod') do |method|
      method.define_argument('mode')
      method.define_rest_argument('paths')
    end

    klass.define_method('lchown') do |method|
      method.define_argument('owner')
      method.define_argument('group')
      method.define_rest_argument('paths')
    end

    klass.define_method('link') do |method|
      method.define_argument('from')
      method.define_argument('to')
    end

    klass.define_method('lstat') do |method|
      method.define_argument('path')
    end

    klass.define_method('mtime') do |method|
      method.define_argument('path')
    end

    klass.define_method('owned?') do |method|
      method.define_argument('file_name')
    end

    klass.define_method('path') do |method|
      method.define_argument('obj')
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

    klass.define_method('readlink') do |method|
      method.define_argument('path')
    end

    klass.define_method('realdirpath') do |method|
      method.define_argument('path')
      method.define_optional_argument('basedir')
    end

    klass.define_method('realpath') do |method|
      method.define_argument('path')
      method.define_optional_argument('basedir')
    end

    klass.define_method('rename') do |method|
      method.define_argument('from')
      method.define_argument('to')
    end

    klass.define_method('setgid?') do |method|
      method.define_argument('file_name')
    end

    klass.define_method('setuid?') do |method|
      method.define_argument('file_name')
    end

    klass.define_method('size') do |method|
      method.define_argument('io_or_path')
    end

    klass.define_method('size?') do |method|
      method.define_argument('io_or_path')
    end

    klass.define_method('socket?') do |method|
      method.define_argument('path')
    end

    klass.define_method('split') do |method|
      method.define_argument('path')
    end

    klass.define_method('stat') do |method|
      method.define_argument('path')
    end

    klass.define_method('sticky?') do |method|
      method.define_argument('file_name')
    end

    klass.define_method('symlink') do |method|
      method.define_argument('from')
      method.define_argument('to')
    end

    klass.define_method('symlink?') do |method|
      method.define_argument('path')
    end

    klass.define_method('syscopy') do |method|
      method.define_argument('from')
      method.define_argument('to')
    end

    klass.define_method('to_ast') do |method|
      method.define_argument('name')
      method.define_optional_argument('line')
    end

    klass.define_method('to_sexp') do |method|
      method.define_argument('name')
      method.define_optional_argument('line')
    end

    klass.define_method('truncate') do |method|
      method.define_argument('path')
      method.define_argument('length')
    end

    klass.define_method('umask') do |method|
      method.define_optional_argument('mask')
    end

    klass.define_method('unlink') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_method('utime') do |method|
      method.define_argument('a_in')
      method.define_argument('m_in')
      method.define_rest_argument('paths')
    end

    klass.define_method('world_readable?') do |method|
      method.define_argument('path')
    end

    klass.define_method('world_writable?') do |method|
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

    klass.define_instance_method('atime')

    klass.define_instance_method('chmod') do |method|
      method.define_argument('mode')
    end

    klass.define_instance_method('chown') do |method|
      method.define_argument('owner')
      method.define_argument('group')
    end

    klass.define_instance_method('ctime')

    klass.define_instance_method('flock') do |method|
      method.define_argument('const')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path_or_fd')
      method.define_optional_argument('mode')
      method.define_optional_argument('perm')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('lstat')

    klass.define_instance_method('mtime')

    klass.define_instance_method('path')

    klass.define_instance_method('reopen') do |method|
      method.define_argument('other')
      method.define_optional_argument('mode')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('stat')

    klass.define_instance_method('to_path')

    klass.define_instance_method('truncate') do |method|
      method.define_argument('length')
    end
  end

  defs.define_constant('File::ACCMODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::ALT_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::APPEND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::BINARY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::BidirectionalPipe') do |klass|
    klass.inherits(defs.constant_proxy('IO', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('close_read')

    klass.define_instance_method('close_write')

    klass.define_instance_method('closed?')

    klass.define_instance_method('print') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('printf') do |method|
      method.define_argument('fmt')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('putc') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('puts') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('set_pipe_info') do |method|
      method.define_argument('write')
    end

    klass.define_instance_method('syswrite') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('write') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('write_nonblock') do |method|
      method.define_argument('data')
    end
  end

  defs.define_constant('File::CASEFOLD_FILESYSTEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::CREAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::ACCMODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::APPEND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::BINARY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::CREAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::EXCL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::FD_CLOEXEC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::FNM_CASEFOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::FNM_DOTMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::FNM_NOESCAPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::FNM_PATHNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::FNM_SYSCASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::F_GETFD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::F_GETFL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::F_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::F_SETFD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::F_SETFL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::LOCK_EX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::LOCK_NB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::LOCK_SH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::LOCK_UN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::NOCTTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::NONBLOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::NULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::RDONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::RDWR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::R_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::SYNC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::TRUNC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::WRONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::W_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Constants::X_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::DOSISH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::EAGAINWaitReadable') do |klass|
    klass.inherits(defs.constant_proxy('Errno::EAGAIN', RubyLint.registry))
    klass.inherits(defs.constant_proxy('IO::WaitReadable', RubyLint.registry))

  end

  defs.define_constant('File::EAGAINWaitWritable') do |klass|
    klass.inherits(defs.constant_proxy('Errno::EAGAIN', RubyLint.registry))
    klass.inherits(defs.constant_proxy('IO::WaitWritable', RubyLint.registry))

  end

  defs.define_constant('File::EXCL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::EachReader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('io')
      method.define_argument('buffer')
      method.define_argument('separator')
      method.define_argument('limit')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('read_all')

    klass.define_instance_method('read_to_limit')

    klass.define_instance_method('read_to_separator')

    klass.define_instance_method('read_to_separator_with_limit')
  end

  defs.define_constant('File::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('receiver_or_size')
      method.define_optional_argument('method_name')
      method.define_rest_argument('method_args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next')

    klass.define_instance_method('next_values')

    klass.define_instance_method('peek')

    klass.define_instance_method('peek_values')

    klass.define_instance_method('rewind')

    klass.define_instance_method('size')

    klass.define_instance_method('with_index') do |method|
      method.define_optional_argument('offset')
    end
  end

  defs.define_constant('File::FD_CLOEXEC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::FFI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_typedef') do |method|
      method.define_argument('current')
      method.define_argument('add')
    end

    klass.define_method('config') do |method|
      method.define_argument('name')
    end

    klass.define_method('config_hash') do |method|
      method.define_argument('name')
    end

    klass.define_method('errno')

    klass.define_method('find_type') do |method|
      method.define_argument('name')
    end

    klass.define_method('generate_function') do |method|
      method.define_argument('ptr')
      method.define_argument('name')
      method.define_argument('args')
      method.define_argument('ret')
    end

    klass.define_method('generate_trampoline') do |method|
      method.define_argument('obj')
      method.define_argument('name')
      method.define_argument('args')
      method.define_argument('ret')
    end

    klass.define_method('size_to_type') do |method|
      method.define_argument('size')
    end

    klass.define_method('type_size') do |method|
      method.define_argument('type')
    end
  end

  defs.define_constant('File::FNM_CASEFOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::FNM_DOTMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::FNM_NOESCAPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::FNM_PATHNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::FNM_SYSCASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::F_GETFD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::F_GETFL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::F_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::F_SETFD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::F_SETFL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::FileError') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

  end

  defs.define_constant('File::InternalBuffer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('channel')

    klass.define_instance_method('discard') do |method|
      method.define_argument('skip')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('empty_to') do |method|
      method.define_argument('io')
    end

    klass.define_instance_method('exhausted?')

    klass.define_instance_method('fill') do |method|
      method.define_argument('io')
    end

    klass.define_instance_method('fill_from') do |method|
      method.define_argument('io')
      method.define_optional_argument('skip')
    end

    klass.define_instance_method('find') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('discard')
    end

    klass.define_instance_method('full?')

    klass.define_instance_method('getbyte') do |method|
      method.define_argument('io')
    end

    klass.define_instance_method('getchar') do |method|
      method.define_argument('io')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('put_back') do |method|
      method.define_argument('chr')
    end

    klass.define_instance_method('read_to_char_boundary') do |method|
      method.define_argument('io')
      method.define_argument('str')
    end

    klass.define_instance_method('reset!')

    klass.define_instance_method('shift') do |method|
      method.define_optional_argument('count')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('start')

    klass.define_instance_method('total')

    klass.define_instance_method('unseek!') do |method|
      method.define_argument('io')
    end

    klass.define_instance_method('unshift') do |method|
      method.define_argument('str')
      method.define_argument('start_pos')
    end

    klass.define_instance_method('unused')

    klass.define_instance_method('used')

    klass.define_instance_method('write_synced?')
  end

  defs.define_constant('File::LOCK_EX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::LOCK_NB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::LOCK_SH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::LOCK_UN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::NOCTTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::NONBLOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::NULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::NoFileError') do |klass|
    klass.inherits(defs.constant_proxy('File::FileError', RubyLint.registry))

  end

  defs.define_constant('File::PATH_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::POSIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('access')

    klass.define_method('chdir')

    klass.define_method('chmod')

    klass.define_method('chown')

    klass.define_method('chroot')

    klass.define_method('dup')

    klass.define_method('endgrent')

    klass.define_method('endpwent')

    klass.define_method('errno')

    klass.define_method('errno=')

    klass.define_method('fchmod')

    klass.define_method('fchown')

    klass.define_method('fcntl')

    klass.define_method('flock')

    klass.define_method('free')

    klass.define_method('fsync')

    klass.define_method('getcwd')

    klass.define_method('getegid')

    klass.define_method('geteuid')

    klass.define_method('getgid')

    klass.define_method('getgrent')

    klass.define_method('getgrgid')

    klass.define_method('getgrnam')

    klass.define_method('getgroups')

    klass.define_method('getpgid')

    klass.define_method('getpgrp')

    klass.define_method('getpid')

    klass.define_method('getppid')

    klass.define_method('getpriority')

    klass.define_method('getpwent')

    klass.define_method('getpwnam')

    klass.define_method('getpwuid')

    klass.define_method('getrlimit')

    klass.define_method('getuid')

    klass.define_method('initgroups')

    klass.define_method('ioctl')

    klass.define_method('isatty')

    klass.define_method('kill')

    klass.define_method('lchmod')

    klass.define_method('lchown')

    klass.define_method('link')

    klass.define_method('major')

    klass.define_method('malloc')

    klass.define_method('memcpy')

    klass.define_method('memset')

    klass.define_method('minor')

    klass.define_method('mkdir')

    klass.define_method('readlink')

    klass.define_method('realloc')

    klass.define_method('rename')

    klass.define_method('rmdir')

    klass.define_method('setegid')

    klass.define_method('seteuid')

    klass.define_method('setgid')

    klass.define_method('setgrent')

    klass.define_method('setgroups')

    klass.define_method('setpgid')

    klass.define_method('setpriority')

    klass.define_method('setpwent')

    klass.define_method('setregid')

    klass.define_method('setresgid')

    klass.define_method('setresuid')

    klass.define_method('setreuid')

    klass.define_method('setrlimit')

    klass.define_method('setsid')

    klass.define_method('setuid')

    klass.define_method('symlink')

    klass.define_method('umask')

    klass.define_method('unlink')

    klass.define_method('utimes')
  end

  defs.define_constant('File::PermissionError') do |klass|
    klass.inherits(defs.constant_proxy('File::FileError', RubyLint.registry))

  end

  defs.define_constant('File::PrivateDir') do |klass|
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

  defs.define_constant('File::RDONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::RDWR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::R_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Readable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::SEEK_CUR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::SEEK_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::SEEK_SET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::SYNC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Separator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Socketable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accept')
  end

  defs.define_constant('File::SortedElement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('val')
      method.define_argument('sort_id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('sort_id')

    klass.define_instance_method('value')
  end

  defs.define_constant('File::Stat') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('fstat') do |method|
      method.define_argument('fd')
    end

    klass.define_method('lstat') do |method|
      method.define_argument('path')
    end

    klass.define_method('stat') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('atime')

    klass.define_instance_method('blksize')

    klass.define_instance_method('blockdev?')

    klass.define_instance_method('blocks')

    klass.define_instance_method('chardev?')

    klass.define_instance_method('ctime')

    klass.define_instance_method('dev')

    klass.define_instance_method('dev_major')

    klass.define_instance_method('dev_minor')

    klass.define_instance_method('directory?')

    klass.define_instance_method('executable?')

    klass.define_instance_method('executable_real?')

    klass.define_instance_method('file?')

    klass.define_instance_method('ftype')

    klass.define_instance_method('gid')

    klass.define_instance_method('grpowned?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('ino')

    klass.define_instance_method('inspect')

    klass.define_instance_method('mode')

    klass.define_instance_method('mtime')

    klass.define_instance_method('nlink')

    klass.define_instance_method('owned?')

    klass.define_instance_method('path')

    klass.define_instance_method('pipe?')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('rdev')

    klass.define_instance_method('rdev_major')

    klass.define_instance_method('rdev_minor')

    klass.define_instance_method('readable?')

    klass.define_instance_method('readable_real?')

    klass.define_instance_method('setgid?')

    klass.define_instance_method('setuid?')

    klass.define_instance_method('size')

    klass.define_instance_method('size?')

    klass.define_instance_method('socket?')

    klass.define_instance_method('sticky?')

    klass.define_instance_method('symlink?')

    klass.define_instance_method('uid')

    klass.define_instance_method('world_readable?')

    klass.define_instance_method('world_writable?')

    klass.define_instance_method('writable?')

    klass.define_instance_method('writable_real?')

    klass.define_instance_method('zero?')
  end

  defs.define_constant('File::Stat::S_IFBLK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IFCHR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IFDIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IFIFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IFLNK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IFMT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IFREG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IFSOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IFWHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IRGRP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IROTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IRUGO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IRUSR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_ISGID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_ISUID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_ISVTX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IWGRP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IWOTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IWUGO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IWUSR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IXGRP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IXOTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IXUGO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Stat::S_IXUSR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::StreamCopier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('from')
      method.define_argument('to')
      method.define_argument('length')
      method.define_argument('offset')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('read_method') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('run')

    klass.define_instance_method('to_io') do |method|
      method.define_argument('obj')
      method.define_argument('mode')
    end
  end

  defs.define_constant('File::TRUNC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::TransferIO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('recv_fd')

    klass.define_instance_method('send_io')
  end

  defs.define_constant('File::UnableToStat') do |klass|
    klass.inherits(defs.constant_proxy('File::FileError', RubyLint.registry))

  end

  defs.define_constant('File::WRONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::W_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::WaitReadable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::WaitWritable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::Writable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('File::X_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
