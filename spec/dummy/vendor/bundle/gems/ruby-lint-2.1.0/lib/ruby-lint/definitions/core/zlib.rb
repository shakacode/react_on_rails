# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Zlib') do |defs|
  defs.define_constant('Zlib') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('adler32')

    klass.define_method('adler32_combine')

    klass.define_method('crc32')

    klass.define_method('crc32_combine')

    klass.define_method('crc_table')

    klass.define_method('deflate')

    klass.define_method('inflate')

    klass.define_method('zlib_version')
  end

  defs.define_constant('Zlib::ASCII') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::BEST_COMPRESSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::BEST_SPEED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::BINARY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::BufError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::DEFAULT_COMPRESSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::DEFAULT_STRATEGY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::DEF_MEM_LEVEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::DataError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::Deflate') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::ZStream', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('deflate')

    klass.define_instance_method('<<')

    klass.define_instance_method('deflate')

    klass.define_instance_method('flush')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('params')

    klass.define_instance_method('set_dictionary')
  end

  defs.define_constant('Zlib::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Zlib::FILTERED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::FINISH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::FIXED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::FULL_FLUSH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::GzipFile') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('wrap')

    klass.define_instance_method('close')

    klass.define_instance_method('closed?')

    klass.define_instance_method('comment')

    klass.define_instance_method('crc')

    klass.define_instance_method('finish')

    klass.define_instance_method('level')

    klass.define_instance_method('mtime')

    klass.define_instance_method('orig_name')

    klass.define_instance_method('os_code')

    klass.define_instance_method('sync')

    klass.define_instance_method('sync=')

    klass.define_instance_method('to_io')
  end

  defs.define_constant('Zlib::GzipFile::CRCError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::GzipFile::Error') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::Error', RubyLint.registry))

    klass.define_instance_method('input')

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Zlib::GzipFile::LengthError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::GzipFile::NoFooter') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::GzipReader') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('open')

    klass.define_instance_method('bytes')

    klass.define_instance_method('each')

    klass.define_instance_method('each_byte')

    klass.define_instance_method('each_char')

    klass.define_instance_method('each_line')

    klass.define_instance_method('eof')

    klass.define_instance_method('eof?')

    klass.define_instance_method('getbyte')

    klass.define_instance_method('getc')

    klass.define_instance_method('gets')

    klass.define_instance_method('initialize')

    klass.define_instance_method('lineno')

    klass.define_instance_method('lineno=')

    klass.define_instance_method('lines')

    klass.define_instance_method('pos')

    klass.define_instance_method('read')

    klass.define_instance_method('readbyte')

    klass.define_instance_method('readchar')

    klass.define_instance_method('readline')

    klass.define_instance_method('readlines')

    klass.define_instance_method('readpartial')

    klass.define_instance_method('rewind')

    klass.define_instance_method('tell')

    klass.define_instance_method('ungetbyte')

    klass.define_instance_method('ungetc')

    klass.define_instance_method('unused')
  end

  defs.define_constant('Zlib::GzipReader::CRCError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::GzipReader::Enumerator') do |klass|
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

  defs.define_constant('Zlib::GzipReader::Error') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::Error', RubyLint.registry))

    klass.define_instance_method('input')

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Zlib::GzipReader::LengthError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::GzipReader::NoFooter') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::GzipReader::SortedElement') do |klass|
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

  defs.define_constant('Zlib::GzipWriter') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('open')

    klass.define_instance_method('<<')

    klass.define_instance_method('comment=')

    klass.define_instance_method('flush')

    klass.define_instance_method('initialize')

    klass.define_instance_method('mtime=')

    klass.define_instance_method('orig_name=')

    klass.define_instance_method('pos')

    klass.define_instance_method('print')

    klass.define_instance_method('printf')

    klass.define_instance_method('putc')

    klass.define_instance_method('puts')

    klass.define_instance_method('tell')

    klass.define_instance_method('write')
  end

  defs.define_constant('Zlib::GzipWriter::CRCError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::GzipWriter::Error') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::Error', RubyLint.registry))

    klass.define_instance_method('input')

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Zlib::GzipWriter::LengthError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::GzipWriter::NoFooter') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::GzipFile::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::HUFFMAN_ONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::Inflate') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::ZStream', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('inflate')

    klass.define_instance_method('<<')

    klass.define_instance_method('add_dictionary')

    klass.define_instance_method('inflate')

    klass.define_instance_method('initialize')

    klass.define_instance_method('set_dictionary')

    klass.define_instance_method('sync')

    klass.define_instance_method('sync_point?')
  end

  defs.define_constant('Zlib::MAX_MEM_LEVEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::MAX_WBITS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::MemError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::NO_COMPRESSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::NO_FLUSH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::NeedDict') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_AMIGA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_ATARI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_CODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_CPM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_MACOS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_MSDOS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_OS2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_QDOS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_RISCOS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_TOPS20') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_UNIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_VMCMS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_VMS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_WIN32') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::OS_ZSYSTEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::RLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::SYNC_FLUSH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::StreamEnd') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::StreamError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::VersionError') do |klass|
    klass.inherits(defs.constant_proxy('Zlib::Error', RubyLint.registry))

  end

  defs.define_constant('Zlib::ZLIB_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Zlib::ZStream') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('adler')

    klass.define_instance_method('avail_in')

    klass.define_instance_method('avail_out')

    klass.define_instance_method('avail_out=')

    klass.define_instance_method('close')

    klass.define_instance_method('closed?')

    klass.define_instance_method('data_type')

    klass.define_instance_method('end')

    klass.define_instance_method('ended?')

    klass.define_instance_method('finish')

    klass.define_instance_method('finished?')

    klass.define_instance_method('flush_next_in')

    klass.define_instance_method('flush_next_out')

    klass.define_instance_method('reset')

    klass.define_instance_method('stream_end?')

    klass.define_instance_method('total_in')

    klass.define_instance_method('total_out')
  end
end
