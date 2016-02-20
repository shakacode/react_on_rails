# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('IO') do |defs|
  defs.define_constant('IO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Unmarshalable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('File::Constants', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('binread') do |method|
      method.define_argument('file')
      method.define_optional_argument('length')
      method.define_optional_argument('offset')
    end

    klass.define_method('binwrite') do |method|
      method.define_argument('file')
      method.define_argument('string')
      method.define_rest_argument('args')
    end

    klass.define_method('connect_pipe') do |method|
      method.define_argument('lhs')
      method.define_argument('rhs')
    end

    klass.define_method('copy_stream') do |method|
      method.define_argument('from')
      method.define_argument('to')
      method.define_optional_argument('max_length')
      method.define_optional_argument('offset')
    end

    klass.define_method('fnmatch') do |method|
      method.define_argument('pattern')
      method.define_argument('path')
      method.define_argument('flags')
    end

    klass.define_method('for_fd') do |method|
      method.define_argument('fd')
      method.define_optional_argument('mode')
      method.define_optional_argument('options')
    end

    klass.define_method('foreach') do |method|
      method.define_argument('name')
      method.define_optional_argument('separator')
      method.define_optional_argument('limit')
      method.define_optional_argument('options')
    end

    klass.define_method('max_open_fd')

    klass.define_method('normalize_options') do |method|
      method.define_argument('mode')
      method.define_argument('options')
    end

    klass.define_method('open') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('open_with_mode') do |method|
      method.define_argument('path')
      method.define_argument('mode')
      method.define_argument('perm')
    end

    klass.define_method('parse_mode') do |method|
      method.define_argument('mode')
    end

    klass.define_method('pipe') do |method|
      method.define_optional_argument('external')
      method.define_optional_argument('internal')
      method.define_optional_argument('options')
    end

    klass.define_method('popen') do |method|
      method.define_argument('str')
      method.define_optional_argument('mode')
      method.define_optional_argument('options')
    end

    klass.define_method('prim_truncate') do |method|
      method.define_argument('name')
      method.define_argument('offset')
    end

    klass.define_method('read') do |method|
      method.define_argument('name')
      method.define_optional_argument('length_or_options')
      method.define_optional_argument('offset')
      method.define_optional_argument('options')
    end

    klass.define_method('read_encode') do |method|
      method.define_argument('io')
      method.define_argument('str')
    end

    klass.define_method('readlines') do |method|
      method.define_argument('name')
      method.define_optional_argument('separator')
      method.define_optional_argument('limit')
      method.define_optional_argument('options')
    end

    klass.define_method('select') do |method|
      method.define_optional_argument('readables')
      method.define_optional_argument('writables')
      method.define_optional_argument('errorables')
      method.define_optional_argument('timeout')
    end

    klass.define_method('select_primitive') do |method|
      method.define_argument('readables')
      method.define_argument('writables')
      method.define_argument('errorables')
      method.define_argument('timeout')
    end

    klass.define_method('setup') do |method|
      method.define_argument('io')
      method.define_argument('fd')
      method.define_optional_argument('mode')
      method.define_optional_argument('sync')
    end

    klass.define_method('sysopen') do |method|
      method.define_argument('path')
      method.define_optional_argument('mode')
      method.define_optional_argument('perm')
    end

    klass.define_method('try_convert') do |method|
      method.define_argument('obj')
    end

    klass.define_method('write') do |method|
      method.define_argument('file')
      method.define_argument('string')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('advise') do |method|
      method.define_argument('advice')
      method.define_optional_argument('offset')
      method.define_optional_argument('len')
    end

    klass.define_instance_method('autoclose=') do |method|
      method.define_argument('autoclose')
    end

    klass.define_instance_method('autoclose?')

    klass.define_instance_method('binmode')

    klass.define_instance_method('binmode?')

    klass.define_instance_method('buffer_empty?')

    klass.define_instance_method('bytes')

    klass.define_instance_method('chars')

    klass.define_instance_method('close')

    klass.define_instance_method('close_on_exec=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('close_on_exec?')

    klass.define_instance_method('close_read')

    klass.define_instance_method('close_write')

    klass.define_instance_method('closed?')

    klass.define_instance_method('codepoints')

    klass.define_instance_method('descriptor')

    klass.define_instance_method('descriptor=')

    klass.define_instance_method('dup')

    klass.define_instance_method('each') do |method|
      method.define_optional_argument('sep_or_limit')
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('each_byte')

    klass.define_instance_method('each_char')

    klass.define_instance_method('each_codepoint')

    klass.define_instance_method('each_line') do |method|
      method.define_optional_argument('sep_or_limit')
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('ensure_open')

    klass.define_instance_method('ensure_open_and_readable')

    klass.define_instance_method('ensure_open_and_writable')

    klass.define_instance_method('eof')

    klass.define_instance_method('eof!')

    klass.define_instance_method('eof?')

    klass.define_instance_method('expect') do |method|
      method.define_argument('pat')
      method.define_optional_argument('timeout')
    end

    klass.define_instance_method('external')

    klass.define_instance_method('external=')

    klass.define_instance_method('external_encoding')

    klass.define_instance_method('fcntl') do |method|
      method.define_argument('command')
      method.define_optional_argument('arg')
    end

    klass.define_instance_method('fileno')

    klass.define_instance_method('flush')

    klass.define_instance_method('fsync')

    klass.define_instance_method('getbyte')

    klass.define_instance_method('getc')

    klass.define_instance_method('gets') do |method|
      method.define_optional_argument('sep_or_limit')
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('increment_lineno')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('fd')
      method.define_optional_argument('mode')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('internal')

    klass.define_instance_method('internal=')

    klass.define_instance_method('internal_encoding')

    klass.define_instance_method('ioctl') do |method|
      method.define_argument('command')
      method.define_optional_argument('arg')
    end

    klass.define_instance_method('isatty')

    klass.define_instance_method('lineno')

    klass.define_instance_method('lineno=') do |method|
      method.define_argument('line_number')
    end

    klass.define_instance_method('lines') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('mode')

    klass.define_instance_method('mode=')

    klass.define_instance_method('pid')

    klass.define_instance_method('pid=')

    klass.define_instance_method('pipe=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('pipe?')

    klass.define_instance_method('pos')

    klass.define_instance_method('pos=') do |method|
      method.define_argument('offset')
    end

    klass.define_instance_method('prim_close')

    klass.define_instance_method('prim_ftruncate') do |method|
      method.define_argument('offset')
    end

    klass.define_instance_method('prim_seek') do |method|
      method.define_argument('amount')
      method.define_argument('whence')
    end

    klass.define_instance_method('prim_write') do |method|
      method.define_argument('str')
    end

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

    klass.define_instance_method('query') do |method|
      method.define_argument('which')
    end

    klass.define_instance_method('raw_write') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('read') do |method|
      method.define_optional_argument('length')
      method.define_optional_argument('buffer')
    end

    klass.define_instance_method('read_bom_byte')

    klass.define_instance_method('read_nonblock') do |method|
      method.define_argument('size')
      method.define_optional_argument('buffer')
    end

    klass.define_instance_method('read_primitive') do |method|
      method.define_argument('number_of_bytes')
    end

    klass.define_instance_method('readbyte')

    klass.define_instance_method('readchar')

    klass.define_instance_method('readline') do |method|
      method.define_optional_argument('sep')
    end

    klass.define_instance_method('readlines') do |method|
      method.define_optional_argument('sep')
    end

    klass.define_instance_method('readpartial') do |method|
      method.define_argument('size')
      method.define_optional_argument('buffer')
    end

    klass.define_instance_method('reopen') do |method|
      method.define_argument('other')
      method.define_optional_argument('mode')
    end

    klass.define_instance_method('reopen_io') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('reopen_path') do |method|
      method.define_argument('string')
      method.define_argument('mode')
    end

    klass.define_instance_method('reset_buffering')

    klass.define_instance_method('rewind')

    klass.define_instance_method('scanf') do |method|
      method.define_argument('str')
      method.define_block_argument('b')
    end

    klass.define_instance_method('seek') do |method|
      method.define_argument('amount')
      method.define_optional_argument('whence')
    end

    klass.define_instance_method('set_encoding') do |method|
      method.define_argument('external')
      method.define_optional_argument('internal')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('shutdown') do |method|
      method.define_argument('how')
    end

    klass.define_instance_method('socket_recv') do |method|
      method.define_argument('bytes')
      method.define_argument('flags')
      method.define_argument('type')
    end

    klass.define_instance_method('stat')

    klass.define_instance_method('strip_bom')

    klass.define_instance_method('sync')

    klass.define_instance_method('sync=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('sysread') do |method|
      method.define_argument('number_of_bytes')
      method.define_optional_argument('buffer')
    end

    klass.define_instance_method('sysseek') do |method|
      method.define_argument('amount')
      method.define_optional_argument('whence')
    end

    klass.define_instance_method('syswrite') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('tell')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_io')

    klass.define_instance_method('tty?')

    klass.define_instance_method('ttyname')

    klass.define_instance_method('ungetbyte') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('ungetc') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('write') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('write_nonblock') do |method|
      method.define_argument('data')
    end
  end

  defs.define_constant('IO::ACCMODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::APPEND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::BINARY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::CREAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::EXCL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::EachReader') do |klass|
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

  defs.define_constant('IO::Enumerator') do |klass|
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

  defs.define_constant('IO::FD_CLOEXEC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::FFI') do |klass|
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

  defs.define_constant('IO::FNM_CASEFOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::FNM_DOTMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::FNM_NOESCAPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::FNM_PATHNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::FNM_SYSCASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::F_GETFD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::F_GETFL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::F_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::F_SETFD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::F_SETFL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::LOCK_EX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::LOCK_NB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::LOCK_SH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::LOCK_UN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::NOCTTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::NONBLOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::NULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::RDONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::RDWR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::R_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::Readable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::SEEK_CUR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::SEEK_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::SEEK_SET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::SYNC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::Socketable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accept')
  end

  defs.define_constant('IO::SortedElement') do |klass|
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

  defs.define_constant('IO::StreamCopier') do |klass|
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

  defs.define_constant('IO::TRUNC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::TransferIO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('recv_fd')

    klass.define_instance_method('send_io')
  end

  defs.define_constant('IO::WRONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::W_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::WaitReadable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::WaitWritable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::Writable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IO::X_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
