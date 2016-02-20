# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('String') do |defs|
  defs.define_constant('String') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('JSON::Ext::Generator::GeneratorMethods::String', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('__allocate__')

    klass.define_method('allocate')

    klass.define_method('clone')

    klass.define_method('dup')

    klass.define_method('from_bytearray') do |method|
      method.define_argument('bytes')
      method.define_argument('start')
      method.define_argument('count')
    end

    klass.define_method('from_codepoint') do |method|
      method.define_argument('code')
      method.define_argument('enc')
    end

    klass.define_method('pattern') do |method|
      method.define_argument('size')
      method.define_argument('str')
    end

    klass.define_method('try_convert') do |method|
      method.define_argument('obj')
    end

    klass.define_method('yaml_new') do |method|
      method.define_argument('klass')
      method.define_argument('tag')
      method.define_argument('val')
    end

    klass.define_method('yaml_tag_subclasses?')

    klass.define_instance_method('%') do |method|
      method.define_argument('args')
    end

    klass.define_instance_method('*') do |method|
      method.define_argument('num')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('=~') do |method|
      method.define_argument('pattern')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('index')
      method.define_optional_argument('other')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('index')
      method.define_argument('count_or_replacement')
      method.define_optional_argument('replacement')
    end

    klass.define_instance_method('__crypt__') do |method|
      method.define_argument('other_str')
    end

    klass.define_instance_method('__data__')

    klass.define_instance_method('__data__=')

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
    end

    klass.define_instance_method('append') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('apply_and!') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('ascii_only=')

    klass.define_instance_method('ascii_only?')

    klass.define_instance_method('b')

    klass.define_instance_method('block_scanf') do |method|
      method.define_argument('fstr')
      method.define_block_argument('b')
    end

    klass.define_instance_method('byte_append') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('bytes')

    klass.define_instance_method('bytesize')

    klass.define_instance_method('byteslice') do |method|
      method.define_argument('index_or_range')
      method.define_optional_argument('length')
    end

    klass.define_instance_method('capitalize')

    klass.define_instance_method('capitalize!')

    klass.define_instance_method('casecmp') do |method|
      method.define_argument('to')
    end

    klass.define_instance_method('center') do |method|
      method.define_argument('width')
      method.define_optional_argument('padding')
    end

    klass.define_instance_method('chars')

    klass.define_instance_method('chomp') do |method|
      method.define_optional_argument('separator')
    end

    klass.define_instance_method('chomp!') do |method|
      method.define_optional_argument('sep')
    end

    klass.define_instance_method('chop')

    klass.define_instance_method('chop!')

    klass.define_instance_method('chr')

    klass.define_instance_method('chr_at') do |method|
      method.define_argument('byte')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('clone')

    klass.define_instance_method('codepoints')

    klass.define_instance_method('compare_substring') do |method|
      method.define_argument('other')
      method.define_argument('start')
      method.define_argument('size')
    end

    klass.define_instance_method('concat') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('convert_float')

    klass.define_instance_method('count') do |method|
      method.define_rest_argument('strings')
    end

    klass.define_instance_method('count_table') do |method|
      method.define_rest_argument('strings')
    end

    klass.define_instance_method('crypt') do |method|
      method.define_argument('other_str')
    end

    klass.define_instance_method('data')

    klass.define_instance_method('data=')

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('strings')
    end

    klass.define_instance_method('delete!') do |method|
      method.define_rest_argument('strings')
    end

    klass.define_instance_method('downcase')

    klass.define_instance_method('downcase!')

    klass.define_instance_method('dump')

    klass.define_instance_method('dup')

    klass.define_instance_method('each_byte')

    klass.define_instance_method('each_char')

    klass.define_instance_method('each_codepoint')

    klass.define_instance_method('each_line') do |method|
      method.define_optional_argument('sep')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('encode') do |method|
      method.define_optional_argument('to')
      method.define_optional_argument('from')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('encode!') do |method|
      method.define_optional_argument('to')
      method.define_optional_argument('from')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('encoding')

    klass.define_instance_method('encoding=')

    klass.define_instance_method('end_with?') do |method|
      method.define_rest_argument('suffixes')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('ext') do |method|
      method.define_optional_argument('newext')
    end

    klass.define_instance_method('find_character') do |method|
      method.define_argument('offset')
    end

    klass.define_instance_method('find_string') do |method|
      method.define_argument('pattern')
      method.define_argument('start')
    end

    klass.define_instance_method('find_string_reverse') do |method|
      method.define_argument('pattern')
      method.define_argument('start')
    end

    klass.define_instance_method('force_encoding') do |method|
      method.define_argument('enc')
    end

    klass.define_instance_method('funcall_style')

    klass.define_instance_method('getbyte') do |method|
      method.define_argument('index')
    end

    klass.define_instance_method('gsub') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('replacement')
    end

    klass.define_instance_method('gsub!') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('replacement')
    end

    klass.define_instance_method('hex')

    klass.define_instance_method('include?') do |method|
      method.define_argument('needle')
    end

    klass.define_instance_method('index') do |method|
      method.define_argument('str')
      method.define_optional_argument('start')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('arg')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('initialize_copy') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('insert') do |method|
      method.define_argument('index')
      method.define_argument('other')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('intern')

    klass.define_instance_method('is_binary_data?')

    klass.define_instance_method('is_complex_yaml?')

    klass.define_instance_method('iseuc')

    klass.define_instance_method('isjis')

    klass.define_instance_method('issjis')

    klass.define_instance_method('isutf8')

    klass.define_instance_method('kconv') do |method|
      method.define_argument('to_enc')
      method.define_optional_argument('from_enc')
    end

    klass.define_instance_method('length')

    klass.define_instance_method('lines') do |method|
      method.define_optional_argument('sep')
    end

    klass.define_instance_method('ljust') do |method|
      method.define_argument('width')
      method.define_optional_argument('padding')
    end

    klass.define_instance_method('lstrip')

    klass.define_instance_method('lstrip!')

    klass.define_instance_method('match') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('pos')
    end

    klass.define_instance_method('modify!')

    klass.define_instance_method('next')

    klass.define_instance_method('next!')

    klass.define_instance_method('num_bytes')

    klass.define_instance_method('num_bytes=') do |method|
      method.define_argument('bytes')
    end

    klass.define_instance_method('oct')

    klass.define_instance_method('ord')

    klass.define_instance_method('parse_csv') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('partition') do |method|
      method.define_optional_argument('pattern')
    end

    klass.define_instance_method('pathmap') do |method|
      method.define_optional_argument('spec')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pathmap_explode')

    klass.define_instance_method('pathmap_partial') do |method|
      method.define_argument('n')
    end

    klass.define_instance_method('pathmap_replace') do |method|
      method.define_argument('patterns')
      method.define_block_argument('block')
    end

    klass.define_instance_method('prefix?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('prepend') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('quote')

    klass.define_instance_method('replace') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('reverse')

    klass.define_instance_method('reverse!')

    klass.define_instance_method('rindex') do |method|
      method.define_argument('sub')
      method.define_optional_argument('finish')
    end

    klass.define_instance_method('rjust') do |method|
      method.define_argument('width')
      method.define_optional_argument('padding')
    end

    klass.define_instance_method('rpartition') do |method|
      method.define_argument('pattern')
    end

    klass.define_instance_method('rstrip')

    klass.define_instance_method('rstrip!')

    klass.define_instance_method('sans_arguments')

    klass.define_instance_method('scan') do |method|
      method.define_argument('pattern')
    end

    klass.define_instance_method('scanf') do |method|
      method.define_argument('fstr')
      method.define_block_argument('b')
    end

    klass.define_instance_method('secure_compare') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('setbyte') do |method|
      method.define_argument('index')
      method.define_argument('byte')
    end

    klass.define_instance_method('shared!')

    klass.define_instance_method('shellescape')

    klass.define_instance_method('shellsplit')

    klass.define_instance_method('shorten!') do |method|
      method.define_argument('size')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('slice') do |method|
      method.define_argument('index')
      method.define_optional_argument('other')
    end

    klass.define_instance_method('slice!') do |method|
      method.define_argument('one')
      method.define_optional_argument('two')
    end

    klass.define_instance_method('snake_case')

    klass.define_instance_method('split') do |method|
      method.define_optional_argument('pattern')
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('squeeze') do |method|
      method.define_rest_argument('strings')
    end

    klass.define_instance_method('squeeze!') do |method|
      method.define_rest_argument('strings')
    end

    klass.define_instance_method('start_with?') do |method|
      method.define_rest_argument('prefixes')
    end

    klass.define_instance_method('strip')

    klass.define_instance_method('strip!')

    klass.define_instance_method('sub') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('replacement')
    end

    klass.define_instance_method('sub!') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('replacement')
    end

    klass.define_instance_method('substring') do |method|
      method.define_argument('start')
      method.define_argument('count')
    end

    klass.define_instance_method('succ')

    klass.define_instance_method('succ!')

    klass.define_instance_method('suffix?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('sum') do |method|
      method.define_optional_argument('bits')
    end

    klass.define_instance_method('swapcase')

    klass.define_instance_method('swapcase!')

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('to_ast') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('line')
    end

    klass.define_instance_method('to_c')

    klass.define_instance_method('to_f')

    klass.define_instance_method('to_i') do |method|
      method.define_optional_argument('base')
    end

    klass.define_instance_method('to_inum') do |method|
      method.define_argument('base')
      method.define_argument('check')
    end

    klass.define_instance_method('to_r')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_sexp') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('line')
    end

    klass.define_instance_method('to_str')

    klass.define_instance_method('to_sub_replacement') do |method|
      method.define_argument('result')
      method.define_argument('match')
    end

    klass.define_instance_method('to_sym')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('toeuc')

    klass.define_instance_method('tojis')

    klass.define_instance_method('tolocale')

    klass.define_instance_method('tosjis')

    klass.define_instance_method('toutf16')

    klass.define_instance_method('toutf32')

    klass.define_instance_method('toutf8')

    klass.define_instance_method('tr') do |method|
      method.define_argument('source')
      method.define_argument('replacement')
    end

    klass.define_instance_method('tr!') do |method|
      method.define_argument('source')
      method.define_argument('replacement')
    end

    klass.define_instance_method('tr_cpp')

    klass.define_instance_method('tr_expand!') do |method|
      method.define_argument('limit')
      method.define_argument('invalid_as_empty')
    end

    klass.define_instance_method('tr_s') do |method|
      method.define_argument('source')
      method.define_argument('replacement')
    end

    klass.define_instance_method('tr_s!') do |method|
      method.define_argument('source')
      method.define_argument('replacement')
    end

    klass.define_instance_method('tr_trans') do |method|
      method.define_argument('source')
      method.define_argument('replacement')
      method.define_argument('squeeze')
    end

    klass.define_instance_method('transform') do |method|
      method.define_argument('tbl')
    end

    klass.define_instance_method('unpack') do |method|
      method.define_argument('directives')
    end

    klass.define_instance_method('unspace')

    klass.define_instance_method('upcase')

    klass.define_instance_method('upcase!')

    klass.define_instance_method('upto') do |method|
      method.define_argument('stop')
      method.define_optional_argument('exclusive')
    end

    klass.define_instance_method('valid_encoding=')

    klass.define_instance_method('valid_encoding?')
  end

  defs.define_constant('String::ControlCharacters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('String::ControlPrintValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('String::Extend') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create')
  end
end
