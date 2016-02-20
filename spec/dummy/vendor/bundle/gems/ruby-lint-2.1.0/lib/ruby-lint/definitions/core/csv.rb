# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('CSV') do |defs|
  defs.define_constant('CSV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('filter') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('foreach') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('generate') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('generate_line') do |method|
      method.define_argument('row')
      method.define_optional_argument('options')
    end

    klass.define_method('instance') do |method|
      method.define_optional_argument('data')
      method.define_optional_argument('options')
    end

    klass.define_method('open') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('parse') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('parse_line') do |method|
      method.define_argument('line')
      method.define_optional_argument('options')
    end

    klass.define_method('read') do |method|
      method.define_argument('path')
      method.define_rest_argument('options')
    end

    klass.define_method('readlines') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('table') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('row')
    end

    klass.define_instance_method('add_row') do |method|
      method.define_argument('row')
    end

    klass.define_instance_method('binmode') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('binmode?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('close') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('close_read') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('close_write') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('closed?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('col_sep')

    klass.define_instance_method('convert') do |method|
      method.define_optional_argument('name')
      method.define_block_argument('converter')
    end

    klass.define_instance_method('converters')

    klass.define_instance_method('each')

    klass.define_instance_method('encoding')

    klass.define_instance_method('eof') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('eof?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('external_encoding') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('fcntl') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('field_size_limit')

    klass.define_instance_method('fileno') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('flock') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('flush') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('force_quotes?')

    klass.define_instance_method('fsync') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('gets')

    klass.define_instance_method('header_convert') do |method|
      method.define_optional_argument('name')
      method.define_block_argument('converter')
    end

    klass.define_instance_method('header_converters')

    klass.define_instance_method('header_row?')

    klass.define_instance_method('headers')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('data')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('internal_encoding') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('ioctl') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('isatty') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('lineno')

    klass.define_instance_method('path') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pid') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pos') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pos=') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('puts') do |method|
      method.define_argument('row')
    end

    klass.define_instance_method('quote_char')

    klass.define_instance_method('read')

    klass.define_instance_method('readline')

    klass.define_instance_method('readlines')

    klass.define_instance_method('reopen') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('return_headers?')

    klass.define_instance_method('rewind')

    klass.define_instance_method('row_sep')

    klass.define_instance_method('seek') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('shift')

    klass.define_instance_method('skip_blanks?')

    klass.define_instance_method('skip_lines')

    klass.define_instance_method('stat') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('string') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sync') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sync=') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tell') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('to_i') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('to_io') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('truncate') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tty?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('unconverted_fields?')

    klass.define_instance_method('write_headers?')
  end

  defs.define_constant('CSV::ConverterEncoding') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CSV::Converters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CSV::DEFAULT_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CSV::DateMatcher') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CSV::DateTimeMatcher') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CSV::Enumerator') do |klass|
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

  defs.define_constant('CSV::FieldInfo') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('header')

    klass.define_instance_method('header=')

    klass.define_instance_method('index')

    klass.define_instance_method('index=')

    klass.define_instance_method('line')

    klass.define_instance_method('line=')
  end

  defs.define_constant('CSV::FieldInfo::Enumerator') do |klass|
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

  defs.define_constant('CSV::FieldInfo::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('CSV::FieldInfo::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('CSV::FieldInfo::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CSV::FieldInfo::SortedElement') do |klass|
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

  defs.define_constant('CSV::FieldInfo::Tms') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('cstime')

    klass.define_instance_method('cstime=')

    klass.define_instance_method('cutime')

    klass.define_instance_method('cutime=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('utime')
      method.define_optional_argument('stime')
      method.define_optional_argument('cutime')
      method.define_optional_argument('cstime')
      method.define_optional_argument('tutime')
      method.define_optional_argument('tstime')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('stime')

    klass.define_instance_method('stime=')

    klass.define_instance_method('tstime')

    klass.define_instance_method('tstime=')

    klass.define_instance_method('tutime')

    klass.define_instance_method('tutime=')

    klass.define_instance_method('utime')

    klass.define_instance_method('utime=')
  end

  defs.define_constant('CSV::HeaderConverters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CSV::MalformedCSVError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

  end

  defs.define_constant('CSV::Row') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('header_or_index')
      method.define_optional_argument('minimum_index')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('header_or_index')
      method.define_optional_argument('minimum_index')
    end

    klass.define_instance_method('delete_if') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('empty?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('fetch') do |method|
      method.define_argument('header')
      method.define_rest_argument('varargs')
    end

    klass.define_instance_method('field') do |method|
      method.define_argument('header_or_index')
      method.define_optional_argument('minimum_index')
    end

    klass.define_instance_method('field?') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('field_row?')

    klass.define_instance_method('fields') do |method|
      method.define_rest_argument('headers_and_or_indices')
    end

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('header')
    end

    klass.define_instance_method('header?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('header_row?')

    klass.define_instance_method('headers')

    klass.define_instance_method('include?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('index') do |method|
      method.define_argument('header')
      method.define_optional_argument('minimum_index')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('headers')
      method.define_argument('fields')
      method.define_optional_argument('header_row')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('key?') do |method|
      method.define_argument('header')
    end

    klass.define_instance_method('length') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('member?') do |method|
      method.define_argument('header')
    end

    klass.define_instance_method('push') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('row')

    klass.define_instance_method('size') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('to_csv') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('to_hash')

    klass.define_instance_method('to_s') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('values_at') do |method|
      method.define_rest_argument('headers_and_or_indices')
    end
  end

  defs.define_constant('CSV::Row::Enumerator') do |klass|
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

  defs.define_constant('CSV::Row::SortedElement') do |klass|
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

  defs.define_constant('CSV::SortedElement') do |klass|
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

  defs.define_constant('CSV::Table') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('row_or_array')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('index_or_header')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('index_or_header')
      method.define_argument('value')
    end

    klass.define_instance_method('by_col')

    klass.define_instance_method('by_col!')

    klass.define_instance_method('by_col_or_row')

    klass.define_instance_method('by_col_or_row!')

    klass.define_instance_method('by_row')

    klass.define_instance_method('by_row!')

    klass.define_instance_method('delete') do |method|
      method.define_argument('index_or_header')
    end

    klass.define_instance_method('delete_if') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('empty?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('headers')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('array_of_rows')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('length') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('mode')

    klass.define_instance_method('push') do |method|
      method.define_rest_argument('rows')
    end

    klass.define_instance_method('size') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('table')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_csv') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('to_s') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('values_at') do |method|
      method.define_rest_argument('indices_or_headers')
    end
  end

  defs.define_constant('CSV::Table::Enumerator') do |klass|
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

  defs.define_constant('CSV::Table::SortedElement') do |klass|
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

  defs.define_constant('CSV::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
