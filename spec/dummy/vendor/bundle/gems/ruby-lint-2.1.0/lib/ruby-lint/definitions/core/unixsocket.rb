# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('UNIXSocket') do |defs|
  defs.define_constant('UNIXSocket') do |klass|
    klass.inherits(defs.constant_proxy('BasicSocket', RubyLint.registry))
    klass.inherits(defs.constant_proxy('IO::TransferIO', RubyLint.registry))

    klass.define_method('pair') do |method|
      method.define_optional_argument('type')
      method.define_optional_argument('protocol')
    end

    klass.define_method('socketpair') do |method|
      method.define_optional_argument('type')
      method.define_optional_argument('protocol')
    end

    klass.define_instance_method('addr')

    klass.define_instance_method('from_descriptor') do |method|
      method.define_argument('fixnum')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('path')

    klass.define_instance_method('peeraddr')

    klass.define_instance_method('recv_io') do |method|
      method.define_optional_argument('klass')
      method.define_optional_argument('mode')
    end

    klass.define_instance_method('recvfrom') do |method|
      method.define_argument('bytes_read')
      method.define_optional_argument('flags')
    end
  end

  defs.define_constant('UNIXSocket::ACCMODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::APPEND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::BINARY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::BidirectionalPipe') do |klass|
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

  defs.define_constant('UNIXSocket::CREAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::EAGAINWaitReadable') do |klass|
    klass.inherits(defs.constant_proxy('Errno::EAGAIN', RubyLint.registry))
    klass.inherits(defs.constant_proxy('IO::WaitReadable', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::EAGAINWaitWritable') do |klass|
    klass.inherits(defs.constant_proxy('Errno::EAGAIN', RubyLint.registry))
    klass.inherits(defs.constant_proxy('IO::WaitWritable', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::EXCL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::EachReader') do |klass|
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

  defs.define_constant('UNIXSocket::Enumerator') do |klass|
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

  defs.define_constant('UNIXSocket::FD_CLOEXEC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::FFI') do |klass|
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

  defs.define_constant('UNIXSocket::FNM_CASEFOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::FNM_DOTMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::FNM_NOESCAPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::FNM_PATHNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::FNM_SYSCASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::F_GETFD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::F_GETFL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::F_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::F_SETFD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::F_SETFL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::InternalBuffer') do |klass|
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

  defs.define_constant('UNIXSocket::LOCK_EX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::LOCK_NB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::LOCK_SH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::LOCK_UN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::NOCTTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::NONBLOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::NULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::RDONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::RDWR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::R_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::Readable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::SEEK_CUR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::SEEK_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::SEEK_SET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::SYNC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::Socketable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accept')
  end

  defs.define_constant('UNIXSocket::SortedElement') do |klass|
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

  defs.define_constant('UNIXSocket::StreamCopier') do |klass|
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

  defs.define_constant('UNIXSocket::TRUNC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::TransferIO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('recv_fd')

    klass.define_instance_method('send_io')
  end

  defs.define_constant('UNIXSocket::WRONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::W_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::WaitReadable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::WaitWritable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::Writable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('UNIXSocket::X_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
