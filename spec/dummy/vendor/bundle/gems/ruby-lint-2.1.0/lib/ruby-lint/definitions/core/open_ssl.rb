# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('OpenSSL') do |defs|
  defs.define_constant('OpenSSL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('Digest') do |method|
      method.define_argument('name')
    end

    klass.define_method('debug')

    klass.define_method('debug=')

    klass.define_method('errors')

    klass.define_method('fips_mode=')
  end

  defs.define_constant('OpenSSL::ASN1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('BMPString')

    klass.define_method('BitString')

    klass.define_method('Boolean')

    klass.define_method('EndOfContent')

    klass.define_method('Enumerated')

    klass.define_method('GeneralString')

    klass.define_method('GeneralizedTime')

    klass.define_method('GraphicString')

    klass.define_method('IA5String')

    klass.define_method('ISO64String')

    klass.define_method('Integer')

    klass.define_method('Null')

    klass.define_method('NumericString')

    klass.define_method('ObjectId')

    klass.define_method('OctetString')

    klass.define_method('PrintableString')

    klass.define_method('Sequence')

    klass.define_method('Set')

    klass.define_method('T61String')

    klass.define_method('UTCTime')

    klass.define_method('UTF8String')

    klass.define_method('UniversalString')

    klass.define_method('VideotexString')

    klass.define_method('decode')

    klass.define_method('decode_all')

    klass.define_method('traverse')
  end

  defs.define_constant('OpenSSL::ASN1::ASN1Data') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('infinite_length')

    klass.define_instance_method('infinite_length=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('tag')

    klass.define_instance_method('tag=')

    klass.define_instance_method('tag_class')

    klass.define_instance_method('tag_class=')

    klass.define_instance_method('to_der')

    klass.define_instance_method('value')

    klass.define_instance_method('value=')
  end

  defs.define_constant('OpenSSL::ASN1::ASN1Error') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::BIT_STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::BMPSTRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::BMPString') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::BOOLEAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::BitString') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

    klass.define_instance_method('unused_bits')

    klass.define_instance_method('unused_bits=')
  end

  defs.define_constant('OpenSSL::ASN1::Boolean') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::CHARACTER_STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::Constructive') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::ASN1Data', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each')

    klass.define_instance_method('initialize')

    klass.define_instance_method('tagging')

    klass.define_instance_method('tagging=')

    klass.define_instance_method('to_der')
  end

  defs.define_constant('OpenSSL::ASN1::Constructive::Enumerator') do |klass|
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

  defs.define_constant('OpenSSL::ASN1::Constructive::SortedElement') do |klass|
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

  defs.define_constant('OpenSSL::ASN1::EMBEDDED_PDV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::ENUMERATED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::EOC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::EXTERNAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::EndOfContent') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::ASN1Data', RubyLint.registry))

    klass.define_instance_method('initialize')
  end

  defs.define_constant('OpenSSL::ASN1::Enumerated') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::GENERALIZEDTIME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::GENERALSTRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::GRAPHICSTRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::GeneralString') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::GeneralizedTime') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::GraphicString') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::IA5STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::IA5String') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::INTEGER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::ISO64STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::ISO64String') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::Integer') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::NULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::NUMERICSTRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::Null') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::NumericString') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::OBJECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::OBJECT_DESCRIPTOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::OCTET_STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::ObjectId') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

    klass.define_method('register')

    klass.define_instance_method('ln')

    klass.define_instance_method('long_name')

    klass.define_instance_method('oid')

    klass.define_instance_method('short_name')

    klass.define_instance_method('sn')
  end

  defs.define_constant('OpenSSL::ASN1::OctetString') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::PRINTABLESTRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::Primitive') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::ASN1Data', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('tagging')

    klass.define_instance_method('tagging=')

    klass.define_instance_method('to_der')
  end

  defs.define_constant('OpenSSL::ASN1::PrintableString') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::REAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::RELATIVE_OID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::SEQUENCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::SET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::Sequence') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Constructive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::Sequence::Enumerator') do |klass|
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

  defs.define_constant('OpenSSL::ASN1::Sequence::SortedElement') do |klass|
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

  defs.define_constant('OpenSSL::ASN1::Set') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Constructive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::Set::Enumerator') do |klass|
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

  defs.define_constant('OpenSSL::ASN1::Set::SortedElement') do |klass|
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

  defs.define_constant('OpenSSL::ASN1::T61STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::T61String') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::UNIVERSALSTRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::UNIVERSAL_TAG_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::UTCTIME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::UTCTime') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::UTF8STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::UTF8String') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::UniversalString') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::VIDEOTEXSTRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::ASN1::VideotexString') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::ASN1::Primitive', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::BN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('generate_prime')

    klass.define_method('pseudo_rand')

    klass.define_method('pseudo_rand_range')

    klass.define_method('rand')

    klass.define_method('rand_range')

    klass.define_instance_method('%')

    klass.define_instance_method('*')

    klass.define_instance_method('**')

    klass.define_instance_method('+')

    klass.define_instance_method('-')

    klass.define_instance_method('/')

    klass.define_instance_method('<<')

    klass.define_instance_method('<=>')

    klass.define_instance_method('==')

    klass.define_instance_method('===')

    klass.define_instance_method('>>')

    klass.define_instance_method('bit_set?')

    klass.define_instance_method('clear_bit!')

    klass.define_instance_method('cmp')

    klass.define_instance_method('coerce')

    klass.define_instance_method('copy')

    klass.define_instance_method('eql?')

    klass.define_instance_method('gcd')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('lshift!')

    klass.define_instance_method('mask_bits!')

    klass.define_instance_method('mod_add')

    klass.define_instance_method('mod_exp')

    klass.define_instance_method('mod_inverse')

    klass.define_instance_method('mod_mul')

    klass.define_instance_method('mod_sqr')

    klass.define_instance_method('mod_sub')

    klass.define_instance_method('num_bits')

    klass.define_instance_method('num_bytes')

    klass.define_instance_method('odd?')

    klass.define_instance_method('one?')

    klass.define_instance_method('prime?')

    klass.define_instance_method('prime_fasttest?')

    klass.define_instance_method('rshift!')

    klass.define_instance_method('set_bit!')

    klass.define_instance_method('sqr')

    klass.define_instance_method('to_bn')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_int')

    klass.define_instance_method('to_s')

    klass.define_instance_method('ucmp')

    klass.define_instance_method('zero?')
  end

  defs.define_constant('OpenSSL::BNError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Buffering') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('each') do |method|
      method.define_optional_argument('eol')
    end

    klass.define_instance_method('each_byte')

    klass.define_instance_method('each_line') do |method|
      method.define_optional_argument('eol')
    end

    klass.define_instance_method('eof')

    klass.define_instance_method('eof?')

    klass.define_instance_method('flush')

    klass.define_instance_method('getc')

    klass.define_instance_method('gets') do |method|
      method.define_optional_argument('eol')
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('print') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('printf') do |method|
      method.define_argument('s')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('puts') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('read') do |method|
      method.define_optional_argument('size')
      method.define_optional_argument('buf')
    end

    klass.define_instance_method('read_nonblock') do |method|
      method.define_argument('maxlen')
      method.define_optional_argument('buf')
    end

    klass.define_instance_method('readchar')

    klass.define_instance_method('readline') do |method|
      method.define_optional_argument('eol')
    end

    klass.define_instance_method('readlines') do |method|
      method.define_optional_argument('eol')
    end

    klass.define_instance_method('readpartial') do |method|
      method.define_argument('maxlen')
      method.define_optional_argument('buf')
    end

    klass.define_instance_method('sync')

    klass.define_instance_method('sync=')

    klass.define_instance_method('ungetc') do |method|
      method.define_argument('c')
    end

    klass.define_instance_method('write') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('write_nonblock') do |method|
      method.define_argument('s')
    end
  end

  defs.define_constant('OpenSSL::Buffering::BLOCK_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Buffering::Enumerator') do |klass|
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

  defs.define_constant('OpenSSL::Buffering::SortedElement') do |klass|
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

  defs.define_constant('OpenSSL::Cipher') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('ciphers')

    klass.define_instance_method('auth_data=')

    klass.define_instance_method('auth_tag')

    klass.define_instance_method('auth_tag=')

    klass.define_instance_method('authenticated?')

    klass.define_instance_method('block_size')

    klass.define_instance_method('decrypt')

    klass.define_instance_method('encrypt')

    klass.define_instance_method('final')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('iv=')

    klass.define_instance_method('iv_len')

    klass.define_instance_method('key=')

    klass.define_instance_method('key_len')

    klass.define_instance_method('key_len=')

    klass.define_instance_method('name')

    klass.define_instance_method('padding=')

    klass.define_instance_method('pkcs5_keyivgen')

    klass.define_instance_method('random_iv')

    klass.define_instance_method('random_key')

    klass.define_instance_method('reset')

    klass.define_instance_method('update')
  end

  defs.define_constant('OpenSSL::Cipher::AES') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::AES128') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mode')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::AES192') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mode')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::AES256') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mode')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::BF') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5::AES') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5::AES128') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mode')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5::AES192') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mode')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5::AES256') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mode')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5::BF') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5::Cipher') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Cipher::CAST5::CipherError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Cipher::CAST5::DES') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5::IDEA') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5::RC2') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5::RC4') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::CAST5::RC5') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::Cipher') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Cipher::CipherError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Cipher::DES') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::IDEA') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::RC2') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::RC4') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Cipher::RC5') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Cipher', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Config') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('get_key_string') do |method|
      method.define_argument('data')
      method.define_argument('section')
      method.define_argument('key')
    end

    klass.define_method('load') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('parse') do |method|
      method.define_argument('str')
    end

    klass.define_method('parse_config') do |method|
      method.define_argument('io')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('section')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('section')
      method.define_argument('pairs')
    end

    klass.define_instance_method('add_value') do |method|
      method.define_argument('section')
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('data')

    klass.define_instance_method('each')

    klass.define_instance_method('get_value') do |method|
      method.define_argument('section')
      method.define_argument('key')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('filename')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('section') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('sections')

    klass.define_instance_method('to_s')

    klass.define_instance_method('value') do |method|
      method.define_argument('arg1')
      method.define_optional_argument('arg2')
    end
  end

  defs.define_constant('OpenSSL::Config::DEFAULT_CONFIG_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Config::Enumerator') do |klass|
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

  defs.define_constant('OpenSSL::Config::SortedElement') do |klass|
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

  defs.define_constant('OpenSSL::ConfigError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Digest') do |klass|
    klass.inherits(defs.constant_proxy('Digest::Class', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('digest') do |method|
      method.define_argument('name')
      method.define_argument('data')
    end

    klass.define_instance_method('<<')

    klass.define_instance_method('block_length')

    klass.define_instance_method('digest_length')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('name')

    klass.define_instance_method('reset')

    klass.define_instance_method('update')
  end

  defs.define_constant('OpenSSL::Digest::DSS') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::DSS1') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::Digest') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::DigestError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Digest::MD2') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::DSS') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::DSS1') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::Digest') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::DigestError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Digest::MD4::MD2') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::MD5') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::MDC2') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::RIPEMD160') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::SHA') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::SHA1') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::SHA224') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::SHA256') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::SHA384') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD4::SHA512') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MD5') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::MDC2') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::RIPEMD160') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::SHA') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::SHA1') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::SHA224') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::SHA256') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::SHA384') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Digest::SHA512') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::Digest', RubyLint.registry))

    klass.define_method('digest') do |method|
      method.define_argument('data')
    end

    klass.define_method('hexdigest') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('OpenSSL::Engine') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('by_id')

    klass.define_method('cleanup')

    klass.define_method('engines')

    klass.define_method('load')

    klass.define_instance_method('cipher')

    klass.define_instance_method('cmds')

    klass.define_instance_method('ctrl_cmd')

    klass.define_instance_method('digest')

    klass.define_instance_method('finish')

    klass.define_instance_method('id')

    klass.define_instance_method('inspect')

    klass.define_instance_method('load_private_key')

    klass.define_instance_method('load_public_key')

    klass.define_instance_method('name')

    klass.define_instance_method('set_default')
  end

  defs.define_constant('OpenSSL::Engine::EngineError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Engine::METHOD_ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Engine::METHOD_CIPHERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Engine::METHOD_DH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Engine::METHOD_DIGESTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Engine::METHOD_DSA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Engine::METHOD_NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Engine::METHOD_RAND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Engine::METHOD_RSA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::HMAC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('digest')

    klass.define_method('hexdigest')

    klass.define_instance_method('<<')

    klass.define_instance_method('digest')

    klass.define_instance_method('hexdigest')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('inspect')

    klass.define_instance_method('reset')

    klass.define_instance_method('to_s')

    klass.define_instance_method('update')
  end

  defs.define_constant('OpenSSL::HMACError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Netscape') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Netscape::SPKI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('challenge')

    klass.define_instance_method('challenge=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('public_key')

    klass.define_instance_method('public_key=')

    klass.define_instance_method('sign')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_text')

    klass.define_instance_method('verify')
  end

  defs.define_constant('OpenSSL::Netscape::SPKIError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::BasicResponse') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('add_nonce')

    klass.define_instance_method('add_status')

    klass.define_instance_method('copy_nonce')

    klass.define_instance_method('initialize')

    klass.define_instance_method('sign')

    klass.define_instance_method('status')

    klass.define_instance_method('verify')
  end

  defs.define_constant('OpenSSL::OCSP::CertificateId') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('cmp')

    klass.define_instance_method('cmp_issuer')

    klass.define_instance_method('initialize')

    klass.define_instance_method('serial')
  end

  defs.define_constant('OpenSSL::OCSP::NOCASIGN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::NOCERTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::NOCHAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::NOCHECKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::NODELEGATED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::NOEXPLICIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::NOINTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::NOSIGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::NOTIME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::NOVERIFY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::OCSPError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::RESPID_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::RESPONSE_STATUS_INTERNALERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::RESPONSE_STATUS_MALFORMEDREQUEST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::RESPONSE_STATUS_SIGREQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::RESPONSE_STATUS_SUCCESSFUL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::RESPONSE_STATUS_TRYLATER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::RESPONSE_STATUS_UNAUTHORIZED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::REVOKED_STATUS_AFFILIATIONCHANGED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::REVOKED_STATUS_CACOMPROMISE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::REVOKED_STATUS_CERTIFICATEHOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::REVOKED_STATUS_CESSATIONOFOPERATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::REVOKED_STATUS_KEYCOMPROMISE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::REVOKED_STATUS_NOSTATUS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::REVOKED_STATUS_REMOVEFROMCRL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::REVOKED_STATUS_SUPERSEDED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::REVOKED_STATUS_UNSPECIFIED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::Request') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('add_certid')

    klass.define_instance_method('add_nonce')

    klass.define_instance_method('certid')

    klass.define_instance_method('check_nonce')

    klass.define_instance_method('initialize')

    klass.define_instance_method('sign')

    klass.define_instance_method('to_der')

    klass.define_instance_method('verify')
  end

  defs.define_constant('OpenSSL::OCSP::Response') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('create')

    klass.define_instance_method('basic')

    klass.define_instance_method('initialize')

    klass.define_instance_method('status')

    klass.define_instance_method('status_string')

    klass.define_instance_method('to_der')
  end

  defs.define_constant('OpenSSL::OCSP::TRUSTOTHER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::V_CERTSTATUS_GOOD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::V_CERTSTATUS_REVOKED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::V_CERTSTATUS_UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::V_RESPID_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OCSP::V_RESPID_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OPENSSL_FIPS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OPENSSL_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OPENSSL_VERSION_NUMBER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::OpenSSLError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS12') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('create')

    klass.define_instance_method('ca_certs')

    klass.define_instance_method('certificate')

    klass.define_instance_method('initialize')

    klass.define_instance_method('key')

    klass.define_instance_method('to_der')
  end

  defs.define_constant('OpenSSL::PKCS12::PKCS12Error') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS5') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('pbkdf2_hmac')

    klass.define_method('pbkdf2_hmac_sha1')
  end

  defs.define_constant('OpenSSL::PKCS5::PKCS5Error') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('encrypt')

    klass.define_method('read_smime')

    klass.define_method('sign')

    klass.define_method('write_smime')

    klass.define_instance_method('add_certificate')

    klass.define_instance_method('add_crl')

    klass.define_instance_method('add_data')

    klass.define_instance_method('add_recipient')

    klass.define_instance_method('add_signer')

    klass.define_instance_method('certificates')

    klass.define_instance_method('certificates=')

    klass.define_instance_method('cipher=')

    klass.define_instance_method('crls')

    klass.define_instance_method('crls=')

    klass.define_instance_method('data')

    klass.define_instance_method('data=')

    klass.define_instance_method('decrypt')

    klass.define_instance_method('detached')

    klass.define_instance_method('detached=')

    klass.define_instance_method('detached?')

    klass.define_instance_method('error_string')

    klass.define_instance_method('error_string=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('recipients')

    klass.define_instance_method('signers')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_s')

    klass.define_instance_method('type')

    klass.define_instance_method('type=')

    klass.define_instance_method('verify')
  end

  defs.define_constant('OpenSSL::PKCS7::BINARY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7::DETACHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7::NOATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7::NOCERTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7::NOCHAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7::NOINTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7::NOSIGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7::NOSMIMECAP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7::NOVERIFY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7::PKCS7Error') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKCS7::RecipientInfo') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('enc_key')

    klass.define_instance_method('initialize')

    klass.define_instance_method('issuer')

    klass.define_instance_method('serial')
  end

  defs.define_constant('OpenSSL::PKCS7::Signer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('initialize')

    klass.define_instance_method('issuer')

    klass.define_instance_method('name')

    klass.define_instance_method('serial')

    klass.define_instance_method('signed_time')
  end

  defs.define_constant('OpenSSL::PKCS7::SignerInfo') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('initialize')

    klass.define_instance_method('issuer')

    klass.define_instance_method('name')

    klass.define_instance_method('serial')

    klass.define_instance_method('signed_time')
  end

  defs.define_constant('OpenSSL::PKCS7::TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('read')
  end

  defs.define_constant('OpenSSL::PKey::DH') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::PKey::PKey', RubyLint.registry))

    klass.define_method('generate')

    klass.define_instance_method('compute_key')

    klass.define_instance_method('export')

    klass.define_instance_method('g')

    klass.define_instance_method('g=')

    klass.define_instance_method('generate_key!')

    klass.define_instance_method('initialize')

    klass.define_instance_method('p')

    klass.define_instance_method('p=')

    klass.define_instance_method('params')

    klass.define_instance_method('params_ok?')

    klass.define_instance_method('priv_key')

    klass.define_instance_method('priv_key=')

    klass.define_instance_method('private?')

    klass.define_instance_method('pub_key')

    klass.define_instance_method('pub_key=')

    klass.define_instance_method('public?')

    klass.define_instance_method('public_key')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_text')
  end

  defs.define_constant('OpenSSL::PKey::DHError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::PKey::PKeyError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::DSA') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::PKey::PKey', RubyLint.registry))

    klass.define_method('generate')

    klass.define_instance_method('export')

    klass.define_instance_method('g')

    klass.define_instance_method('g=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('p')

    klass.define_instance_method('p=')

    klass.define_instance_method('params')

    klass.define_instance_method('priv_key')

    klass.define_instance_method('priv_key=')

    klass.define_instance_method('private?')

    klass.define_instance_method('pub_key')

    klass.define_instance_method('pub_key=')

    klass.define_instance_method('public?')

    klass.define_instance_method('public_key')

    klass.define_instance_method('q')

    klass.define_instance_method('q=')

    klass.define_instance_method('syssign')

    klass.define_instance_method('sysverify')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_text')
  end

  defs.define_constant('OpenSSL::PKey::DSAError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::PKey::PKeyError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::EC') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::PKey::PKey', RubyLint.registry))

    klass.define_method('builtin_curves')

    klass.define_instance_method('check_key')

    klass.define_instance_method('dh_compute_key')

    klass.define_instance_method('dsa_sign_asn1')

    klass.define_instance_method('dsa_verify_asn1')

    klass.define_instance_method('export')

    klass.define_instance_method('generate_key')

    klass.define_instance_method('group')

    klass.define_instance_method('group=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('private_key')

    klass.define_instance_method('private_key=')

    klass.define_instance_method('private_key?')

    klass.define_instance_method('public_key')

    klass.define_instance_method('public_key=')

    klass.define_instance_method('public_key?')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_text')
  end

  defs.define_constant('OpenSSL::PKey::EC::Group') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('==')

    klass.define_instance_method('asn1_flag')

    klass.define_instance_method('asn1_flag=')

    klass.define_instance_method('cofactor')

    klass.define_instance_method('curve_name')

    klass.define_instance_method('degree')

    klass.define_instance_method('eql?')

    klass.define_instance_method('generator')

    klass.define_instance_method('initialize')

    klass.define_instance_method('order')

    klass.define_instance_method('point_conversion_form')

    klass.define_instance_method('point_conversion_form=')

    klass.define_instance_method('seed')

    klass.define_instance_method('seed=')

    klass.define_instance_method('set_generator')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_text')
  end

  defs.define_constant('OpenSSL::PKey::EC::Group::Error') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::EC::NAMED_CURVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::EC::Point') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('==')

    klass.define_instance_method('eql?')

    klass.define_instance_method('group')

    klass.define_instance_method('infinity?')

    klass.define_instance_method('initialize')

    klass.define_instance_method('invert!')

    klass.define_instance_method('make_affine!')

    klass.define_instance_method('mul')

    klass.define_instance_method('on_curve?')

    klass.define_instance_method('set_to_infinity!')

    klass.define_instance_method('to_bn')
  end

  defs.define_constant('OpenSSL::PKey::EC::Point::Error') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::ECError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::PKey::PKeyError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::PKey') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('initialize')

    klass.define_instance_method('sign')

    klass.define_instance_method('verify')
  end

  defs.define_constant('OpenSSL::PKey::PKeyError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::RSA') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::PKey::PKey', RubyLint.registry))

    klass.define_method('generate')

    klass.define_instance_method('d')

    klass.define_instance_method('d=')

    klass.define_instance_method('dmp1')

    klass.define_instance_method('dmp1=')

    klass.define_instance_method('dmq1')

    klass.define_instance_method('dmq1=')

    klass.define_instance_method('e')

    klass.define_instance_method('e=')

    klass.define_instance_method('export')

    klass.define_instance_method('initialize')

    klass.define_instance_method('iqmp')

    klass.define_instance_method('iqmp=')

    klass.define_instance_method('n')

    klass.define_instance_method('n=')

    klass.define_instance_method('p')

    klass.define_instance_method('p=')

    klass.define_instance_method('params')

    klass.define_instance_method('private?')

    klass.define_instance_method('private_decrypt')

    klass.define_instance_method('private_encrypt')

    klass.define_instance_method('public?')

    klass.define_instance_method('public_decrypt')

    klass.define_instance_method('public_encrypt')

    klass.define_instance_method('public_key')

    klass.define_instance_method('q')

    klass.define_instance_method('q=')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_text')
  end

  defs.define_constant('OpenSSL::PKey::RSA::NO_PADDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::RSA::PKCS1_PADDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::RSA::SSLV23_PADDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::PKey::RSAError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::PKey::PKeyError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::Random') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('egd')

    klass.define_method('egd_bytes')

    klass.define_method('load_random_file')

    klass.define_method('pseudo_bytes')

    klass.define_method('random_add')

    klass.define_method('random_bytes')

    klass.define_method('seed')

    klass.define_method('status?')

    klass.define_method('write_random_file')

    klass.define_instance_method('egd')

    klass.define_instance_method('egd_bytes')

    klass.define_instance_method('load_random_file')

    klass.define_instance_method('pseudo_bytes')

    klass.define_instance_method('random_add')

    klass.define_instance_method('random_bytes')

    klass.define_instance_method('seed')

    klass.define_instance_method('status?')

    klass.define_instance_method('write_random_file')
  end

  defs.define_constant('OpenSSL::Random::RandomError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('verify_certificate_identity') do |method|
      method.define_argument('cert')
      method.define_argument('hostname')
    end
  end

  defs.define_constant('OpenSSL::SSL::Nonblock') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_CIPHER_SERVER_PREFERENCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_DONT_INSERT_EMPTY_FRAGMENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_EPHEMERAL_RSA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_MICROSOFT_BIG_SSLV3_BUFFER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_MICROSOFT_SESS_ID_BUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_MSIE_SSLV2_RSA_PADDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NETSCAPE_CA_DN_BUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NETSCAPE_CHALLENGE_BUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NO_COMPRESSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NO_SSLv2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NO_SSLv3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NO_TICKET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NO_TLSv1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NO_TLSv1_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_NO_TLSv1_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_PKCS1_CHECK_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_PKCS1_CHECK_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_SINGLE_DH_USE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_SINGLE_ECDH_USE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_SSLEAY_080_CLIENT_DH_BUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_SSLREF2_REUSE_CERT_TYPE_BUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_TLS_BLOCK_PADDING_BUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_TLS_D5_BUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::OP_TLS_ROLLBACK_BUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('ca_file')

    klass.define_instance_method('ca_file=')

    klass.define_instance_method('ca_path')

    klass.define_instance_method('ca_path=')

    klass.define_instance_method('cert')

    klass.define_instance_method('cert=')

    klass.define_instance_method('cert_store')

    klass.define_instance_method('cert_store=')

    klass.define_instance_method('ciphers')

    klass.define_instance_method('ciphers=')

    klass.define_instance_method('client_ca')

    klass.define_instance_method('client_ca=')

    klass.define_instance_method('client_cert_cb')

    klass.define_instance_method('client_cert_cb=')

    klass.define_instance_method('extra_chain_cert')

    klass.define_instance_method('extra_chain_cert=')

    klass.define_instance_method('flush_sessions')

    klass.define_instance_method('initialize')

    klass.define_instance_method('key')

    klass.define_instance_method('key=')

    klass.define_instance_method('npn_protocols')

    klass.define_instance_method('npn_protocols=')

    klass.define_instance_method('npn_select_cb')

    klass.define_instance_method('npn_select_cb=')

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('renegotiation_cb')

    klass.define_instance_method('renegotiation_cb=')

    klass.define_instance_method('servername_cb')

    klass.define_instance_method('servername_cb=')

    klass.define_instance_method('session_add')

    klass.define_instance_method('session_cache_mode')

    klass.define_instance_method('session_cache_mode=')

    klass.define_instance_method('session_cache_size')

    klass.define_instance_method('session_cache_size=')

    klass.define_instance_method('session_cache_stats')

    klass.define_instance_method('session_get_cb')

    klass.define_instance_method('session_get_cb=')

    klass.define_instance_method('session_id_context')

    klass.define_instance_method('session_id_context=')

    klass.define_instance_method('session_new_cb')

    klass.define_instance_method('session_new_cb=')

    klass.define_instance_method('session_remove')

    klass.define_instance_method('session_remove_cb')

    klass.define_instance_method('session_remove_cb=')

    klass.define_instance_method('set_params') do |method|
      method.define_optional_argument('params')
    end

    klass.define_instance_method('setup')

    klass.define_instance_method('ssl_timeout')

    klass.define_instance_method('ssl_timeout=')

    klass.define_instance_method('ssl_version=')

    klass.define_instance_method('timeout')

    klass.define_instance_method('timeout=')

    klass.define_instance_method('tmp_dh_callback')

    klass.define_instance_method('tmp_dh_callback=')

    klass.define_instance_method('verify_callback')

    klass.define_instance_method('verify_callback=')

    klass.define_instance_method('verify_depth')

    klass.define_instance_method('verify_depth=')

    klass.define_instance_method('verify_mode')

    klass.define_instance_method('verify_mode=')
  end

  defs.define_constant('OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext::DEFAULT_PARAMS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext::METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext::SESSION_CACHE_BOTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext::SESSION_CACHE_CLIENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext::SESSION_CACHE_NO_AUTO_CLEAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext::SESSION_CACHE_NO_INTERNAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext::SESSION_CACHE_NO_INTERNAL_LOOKUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext::SESSION_CACHE_NO_INTERNAL_STORE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext::SESSION_CACHE_OFF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLContext::SESSION_CACHE_SERVER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLServer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('OpenSSL::SSL::SocketForwarder', RubyLint.registry))

    klass.define_instance_method('accept')

    klass.define_instance_method('close')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('svr')
      method.define_argument('ctx')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('listen') do |method|
      method.define_optional_argument('backlog')
    end

    klass.define_instance_method('shutdown') do |method|
      method.define_optional_argument('how')
    end

    klass.define_instance_method('start_immediately')

    klass.define_instance_method('start_immediately=')

    klass.define_instance_method('to_io')
  end

  defs.define_constant('OpenSSL::SSL::SSLSocket') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('OpenSSL::SSL::Nonblock', RubyLint.registry))
    klass.inherits(defs.constant_proxy('OpenSSL::SSL::SocketForwarder', RubyLint.registry))
    klass.inherits(defs.constant_proxy('OpenSSL::Buffering', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('accept')

    klass.define_instance_method('accept_nonblock')

    klass.define_instance_method('cert')

    klass.define_instance_method('cipher')

    klass.define_instance_method('client_ca')

    klass.define_instance_method('connect')

    klass.define_instance_method('connect_nonblock')

    klass.define_instance_method('context')

    klass.define_instance_method('hostname')

    klass.define_instance_method('hostname=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('io')

    klass.define_instance_method('npn_protocol')

    klass.define_instance_method('peer_cert')

    klass.define_instance_method('peer_cert_chain')

    klass.define_instance_method('pending')

    klass.define_instance_method('post_connection_check') do |method|
      method.define_argument('hostname')
    end

    klass.define_instance_method('session')

    klass.define_instance_method('session=')

    klass.define_instance_method('session_reused?')

    klass.define_instance_method('ssl_version')

    klass.define_instance_method('state')

    klass.define_instance_method('sync_close')

    klass.define_instance_method('sync_close=')

    klass.define_instance_method('sysclose')

    klass.define_instance_method('sysread')

    klass.define_instance_method('syswrite')

    klass.define_instance_method('to_io')

    klass.define_instance_method('verify_result')
  end

  defs.define_constant('OpenSSL::SSL::SSLSocket::BLOCK_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SSLSocket::Enumerator') do |klass|
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

  defs.define_constant('OpenSSL::SSL::SSLSocket::SortedElement') do |klass|
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

  defs.define_constant('OpenSSL::SSL::Session') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('==')

    klass.define_instance_method('id')

    klass.define_instance_method('initialize')

    klass.define_instance_method('time')

    klass.define_instance_method('time=')

    klass.define_instance_method('timeout')

    klass.define_instance_method('timeout=')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_text')
  end

  defs.define_constant('OpenSSL::SSL::Session::SessionError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::SocketForwarder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('addr')

    klass.define_instance_method('closed?')

    klass.define_instance_method('do_not_reverse_lookup=') do |method|
      method.define_argument('flag')
    end

    klass.define_instance_method('fcntl') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('getsockopt') do |method|
      method.define_argument('level')
      method.define_argument('optname')
    end

    klass.define_instance_method('peeraddr')

    klass.define_instance_method('setsockopt') do |method|
      method.define_argument('level')
      method.define_argument('optname')
      method.define_argument('optval')
    end
  end

  defs.define_constant('OpenSSL::SSL::VERIFY_CLIENT_ONCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::VERIFY_NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::SSL::VERIFY_PEER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Attribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('initialize')

    klass.define_instance_method('oid')

    klass.define_instance_method('oid=')

    klass.define_instance_method('to_der')

    klass.define_instance_method('value')

    klass.define_instance_method('value=')
  end

  defs.define_constant('OpenSSL::X509::AttributeError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::CRL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('add_extension')

    klass.define_instance_method('add_revoked')

    klass.define_instance_method('extensions')

    klass.define_instance_method('extensions=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('issuer')

    klass.define_instance_method('issuer=')

    klass.define_instance_method('last_update')

    klass.define_instance_method('last_update=')

    klass.define_instance_method('next_update')

    klass.define_instance_method('next_update=')

    klass.define_instance_method('revoked')

    klass.define_instance_method('revoked=')

    klass.define_instance_method('sign')

    klass.define_instance_method('signature_algorithm')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_text')

    klass.define_instance_method('verify')

    klass.define_instance_method('version')

    klass.define_instance_method('version=')
  end

  defs.define_constant('OpenSSL::X509::CRLError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Certificate') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('add_extension')

    klass.define_instance_method('check_private_key')

    klass.define_instance_method('extensions')

    klass.define_instance_method('extensions=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('inspect')

    klass.define_instance_method('issuer')

    klass.define_instance_method('issuer=')

    klass.define_instance_method('not_after')

    klass.define_instance_method('not_after=')

    klass.define_instance_method('not_before')

    klass.define_instance_method('not_before=')

    klass.define_instance_method('public_key')

    klass.define_instance_method('public_key=')

    klass.define_instance_method('serial')

    klass.define_instance_method('serial=')

    klass.define_instance_method('sign')

    klass.define_instance_method('signature_algorithm')

    klass.define_instance_method('subject')

    klass.define_instance_method('subject=')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_text')

    klass.define_instance_method('verify')

    klass.define_instance_method('version')

    klass.define_instance_method('version=')
  end

  defs.define_constant('OpenSSL::X509::CertificateError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::DEFAULT_CERT_AREA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::DEFAULT_CERT_DIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::DEFAULT_CERT_DIR_ENV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::DEFAULT_CERT_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::DEFAULT_CERT_FILE_ENV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::DEFAULT_PRIVATE_DIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Extension') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('critical=')

    klass.define_instance_method('critical?')

    klass.define_instance_method('initialize')

    klass.define_instance_method('oid')

    klass.define_instance_method('oid=')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_h')

    klass.define_instance_method('to_s')

    klass.define_instance_method('value')

    klass.define_instance_method('value=')
  end

  defs.define_constant('OpenSSL::X509::ExtensionError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::ExtensionFactory') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('config')

    klass.define_instance_method('config=')

    klass.define_instance_method('create_ext')

    klass.define_instance_method('create_ext_from_array') do |method|
      method.define_argument('ary')
    end

    klass.define_instance_method('create_ext_from_hash') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('create_ext_from_string') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('create_extension') do |method|
      method.define_rest_argument('arg')
    end

    klass.define_instance_method('crl')

    klass.define_instance_method('crl=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('issuer_certificate')

    klass.define_instance_method('issuer_certificate=')

    klass.define_instance_method('subject_certificate')

    klass.define_instance_method('subject_certificate=')

    klass.define_instance_method('subject_request')

    klass.define_instance_method('subject_request=')
  end

  defs.define_constant('OpenSSL::X509::Name') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('parse') do |method|
      method.define_argument('str')
      method.define_optional_argument('template')
    end

    klass.define_method('parse_openssl') do |method|
      method.define_argument('str')
      method.define_optional_argument('template')
    end

    klass.define_method('parse_rfc2253') do |method|
      method.define_argument('str')
      method.define_optional_argument('template')
    end

    klass.define_instance_method('<=>')

    klass.define_instance_method('add_entry')

    klass.define_instance_method('cmp')

    klass.define_instance_method('eql?')

    klass.define_instance_method('hash')

    klass.define_instance_method('hash_old')

    klass.define_instance_method('initialize')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('OpenSSL::X509::Name::COMPAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::DEFAULT_OBJECT_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::MULTILINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::OBJECT_TYPE_TEMPLATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::ONELINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('expand_hexstring') do |method|
      method.define_argument('str')
    end

    klass.define_method('expand_pair') do |method|
      method.define_argument('str')
    end

    klass.define_method('expand_value') do |method|
      method.define_argument('str1')
      method.define_argument('str2')
      method.define_argument('str3')
    end

    klass.define_method('scan') do |method|
      method.define_argument('dn')
    end
  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN::AttributeType') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN::AttributeValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN::HexChar') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN::HexPair') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN::HexString') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN::Pair') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN::QuoteChar') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN::Special') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN::StringChar') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Name::RFC2253DN::TypeAndValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::NameError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::PURPOSE_ANY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::PURPOSE_CRL_SIGN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::PURPOSE_NS_SSL_SERVER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::PURPOSE_OCSP_HELPER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::PURPOSE_SMIME_ENCRYPT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::PURPOSE_SMIME_SIGN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::PURPOSE_SSL_CLIENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::PURPOSE_SSL_SERVER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Request') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('add_attribute')

    klass.define_instance_method('attributes')

    klass.define_instance_method('attributes=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize_copy')

    klass.define_instance_method('public_key')

    klass.define_instance_method('public_key=')

    klass.define_instance_method('sign')

    klass.define_instance_method('signature_algorithm')

    klass.define_instance_method('subject')

    klass.define_instance_method('subject=')

    klass.define_instance_method('to_der')

    klass.define_instance_method('to_pem')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_text')

    klass.define_instance_method('verify')

    klass.define_instance_method('version')

    klass.define_instance_method('version=')
  end

  defs.define_constant('OpenSSL::X509::RequestError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Revoked') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('add_extension')

    klass.define_instance_method('extensions')

    klass.define_instance_method('extensions=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('serial')

    klass.define_instance_method('serial=')

    klass.define_instance_method('time')

    klass.define_instance_method('time=')
  end

  defs.define_constant('OpenSSL::X509::RevokedError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::Store') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('add_cert')

    klass.define_instance_method('add_crl')

    klass.define_instance_method('add_file')

    klass.define_instance_method('add_path')

    klass.define_instance_method('chain')

    klass.define_instance_method('error')

    klass.define_instance_method('error_string')

    klass.define_instance_method('flags=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('purpose=')

    klass.define_instance_method('set_default_paths')

    klass.define_instance_method('time=')

    klass.define_instance_method('trust=')

    klass.define_instance_method('verify')

    klass.define_instance_method('verify_callback')

    klass.define_instance_method('verify_callback=')
  end

  defs.define_constant('OpenSSL::X509::StoreContext') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('chain')

    klass.define_instance_method('cleanup')

    klass.define_instance_method('current_cert')

    klass.define_instance_method('current_crl')

    klass.define_instance_method('error')

    klass.define_instance_method('error=')

    klass.define_instance_method('error_depth')

    klass.define_instance_method('error_string')

    klass.define_instance_method('flags=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('purpose=')

    klass.define_instance_method('time=')

    klass.define_instance_method('trust=')

    klass.define_instance_method('verify')
  end

  defs.define_constant('OpenSSL::X509::StoreError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::TRUST_COMPAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::TRUST_EMAIL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::TRUST_OBJECT_SIGN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::TRUST_OCSP_REQUEST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::TRUST_OCSP_SIGN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::TRUST_SSL_CLIENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::TRUST_SSL_SERVER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_AKID_ISSUER_SERIAL_MISMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_AKID_SKID_MISMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_APPLICATION_VERIFICATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_CERT_CHAIN_TOO_LONG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_CERT_HAS_EXPIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_CERT_NOT_YET_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_CERT_REJECTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_CERT_REVOKED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_CERT_SIGNATURE_FAILURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_CERT_UNTRUSTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_CRL_HAS_EXPIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_CRL_NOT_YET_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_CRL_SIGNATURE_FAILURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_INVALID_CA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_INVALID_PURPOSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_KEYUSAGE_NO_CERTSIGN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_OUT_OF_MEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_PATH_LENGTH_EXCEEDED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_SELF_SIGNED_CERT_IN_CHAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_SUBJECT_ISSUER_MISMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_UNABLE_TO_GET_CRL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_UNABLE_TO_GET_ISSUER_CERT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_FLAG_CRL_CHECK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_FLAG_CRL_CHECK_ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenSSL::X509::V_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
