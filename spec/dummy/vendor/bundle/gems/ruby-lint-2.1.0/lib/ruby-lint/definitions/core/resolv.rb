# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Resolv') do |defs|
  defs.define_constant('Resolv') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('each_address') do |method|
      method.define_argument('name')
      method.define_block_argument('block')
    end

    klass.define_method('each_name') do |method|
      method.define_argument('address')
      method.define_block_argument('proc')
    end

    klass.define_method('getaddress') do |method|
      method.define_argument('name')
    end

    klass.define_method('getaddresses') do |method|
      method.define_argument('name')
    end

    klass.define_method('getname') do |method|
      method.define_argument('address')
    end

    klass.define_method('getnames') do |method|
      method.define_argument('address')
    end

    klass.define_instance_method('each_address') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('each_name') do |method|
      method.define_argument('address')
    end

    klass.define_instance_method('getaddress') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('getaddresses') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('getname') do |method|
      method.define_argument('address')
    end

    klass.define_instance_method('getnames') do |method|
      method.define_argument('address')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('resolvers')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Resolv::AddressRegex') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate_request_id') do |method|
      method.define_argument('host')
      method.define_argument('port')
    end

    klass.define_method('bind_random_port') do |method|
      method.define_argument('udpsock')
      method.define_optional_argument('bind_host')
    end

    klass.define_method('free_request_id') do |method|
      method.define_argument('host')
      method.define_argument('port')
      method.define_argument('id')
    end

    klass.define_method('open') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('random') do |method|
      method.define_argument('arg')
    end

    klass.define_method('rangerand') do |method|
      method.define_argument('range')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('each_address') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('each_name') do |method|
      method.define_argument('address')
    end

    klass.define_instance_method('each_resource') do |method|
      method.define_argument('name')
      method.define_argument('typeclass')
      method.define_block_argument('proc')
    end

    klass.define_instance_method('extract_resources') do |method|
      method.define_argument('msg')
      method.define_argument('name')
      method.define_argument('typeclass')
    end

    klass.define_instance_method('getaddress') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('getaddresses') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('getname') do |method|
      method.define_argument('address')
    end

    klass.define_instance_method('getnames') do |method|
      method.define_argument('address')
    end

    klass.define_instance_method('getresource') do |method|
      method.define_argument('name')
      method.define_argument('typeclass')
    end

    klass.define_instance_method('getresources') do |method|
      method.define_argument('name')
      method.define_argument('typeclass')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('config_info')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lazy_initialize')

    klass.define_instance_method('make_tcp_requester') do |method|
      method.define_argument('host')
      method.define_argument('port')
    end

    klass.define_instance_method('make_udp_requester')

    klass.define_instance_method('timeouts=') do |method|
      method.define_argument('values')
    end
  end

  defs.define_constant('Resolv::DNS::Config') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('default_config_hash') do |method|
      method.define_optional_argument('filename')
    end

    klass.define_method('parse_resolv_conf') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('generate_candidates') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('generate_timeouts')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('config_info')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lazy_initialize')

    klass.define_instance_method('nameserver_port')

    klass.define_instance_method('resolv') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('single?')

    klass.define_instance_method('timeouts=') do |method|
      method.define_argument('values')
    end
  end

  defs.define_constant('Resolv::DNS::Config::InitialTimeout') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Config::NXDomain') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::ResolvError', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Config::OtherResolvError') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::ResolvError', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::DecodeError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::EncodeError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Label') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('split') do |method|
      method.define_argument('arg')
    end
  end

  defs.define_constant('Resolv::DNS::Label::Str') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('downcase')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('string')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('string')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Resolv::DNS::Message') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('decode') do |method|
      method.define_argument('m')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('aa')

    klass.define_instance_method('aa=')

    klass.define_instance_method('add_additional') do |method|
      method.define_argument('name')
      method.define_argument('ttl')
      method.define_argument('data')
    end

    klass.define_instance_method('add_answer') do |method|
      method.define_argument('name')
      method.define_argument('ttl')
      method.define_argument('data')
    end

    klass.define_instance_method('add_authority') do |method|
      method.define_argument('name')
      method.define_argument('ttl')
      method.define_argument('data')
    end

    klass.define_instance_method('add_question') do |method|
      method.define_argument('name')
      method.define_argument('typeclass')
    end

    klass.define_instance_method('additional')

    klass.define_instance_method('answer')

    klass.define_instance_method('authority')

    klass.define_instance_method('each_additional')

    klass.define_instance_method('each_answer')

    klass.define_instance_method('each_authority')

    klass.define_instance_method('each_question')

    klass.define_instance_method('each_resource')

    klass.define_instance_method('encode')

    klass.define_instance_method('id')

    klass.define_instance_method('id=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('opcode')

    klass.define_instance_method('opcode=')

    klass.define_instance_method('qr')

    klass.define_instance_method('qr=')

    klass.define_instance_method('question')

    klass.define_instance_method('ra')

    klass.define_instance_method('ra=')

    klass.define_instance_method('rcode')

    klass.define_instance_method('rcode=')

    klass.define_instance_method('rd')

    klass.define_instance_method('rd=')

    klass.define_instance_method('tc')

    klass.define_instance_method('tc=')
  end

  defs.define_constant('Resolv::DNS::Message::MessageDecoder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('get_bytes') do |method|
      method.define_optional_argument('len')
    end

    klass.define_instance_method('get_label')

    klass.define_instance_method('get_labels') do |method|
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('get_length16')

    klass.define_instance_method('get_name')

    klass.define_instance_method('get_question')

    klass.define_instance_method('get_rr')

    klass.define_instance_method('get_string')

    klass.define_instance_method('get_string_list')

    klass.define_instance_method('get_unpack') do |method|
      method.define_argument('template')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('data')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Resolv::DNS::Message::MessageEncoder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('put_bytes') do |method|
      method.define_argument('d')
    end

    klass.define_instance_method('put_label') do |method|
      method.define_argument('d')
    end

    klass.define_instance_method('put_labels') do |method|
      method.define_argument('d')
    end

    klass.define_instance_method('put_length16')

    klass.define_instance_method('put_name') do |method|
      method.define_argument('d')
    end

    klass.define_instance_method('put_pack') do |method|
      method.define_argument('template')
      method.define_rest_argument('d')
    end

    klass.define_instance_method('put_string') do |method|
      method.define_argument('d')
    end

    klass.define_instance_method('put_string_list') do |method|
      method.define_argument('ds')
    end

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Resolv::DNS::Name') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('i')
    end

    klass.define_instance_method('absolute?')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('labels')
      method.define_optional_argument('absolute')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('length')

    klass.define_instance_method('subdomain_of?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Resolv::DNS::OpCode') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::OpCode::IQuery') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::OpCode::Notify') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::OpCode::Query') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::OpCode::Status') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::OpCode::Update') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Port') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Query') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end
  end

  defs.define_constant('Resolv::DNS::RCode') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::BADALG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::BADKEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::BADMODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::BADNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::BADSIG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::BADTIME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::BADVERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::FormErr') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::NXDomain') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::NXRRSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::NoError') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::NotAuth') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::NotImp') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::NotZone') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::Refused') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::ServFail') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::YXDomain') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RCode::YXRRSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RequestID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::RequestIDMutex') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Requester') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('initialize')

    klass.define_instance_method('request') do |method|
      method.define_argument('sender')
      method.define_argument('tout')
    end
  end

  defs.define_constant('Resolv::DNS::Requester::ConnectedUDP') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Requester', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('host')
      method.define_optional_argument('port')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('recv_reply') do |method|
      method.define_argument('readable_socks')
    end

    klass.define_instance_method('sender') do |method|
      method.define_argument('msg')
      method.define_argument('data')
      method.define_optional_argument('host')
      method.define_optional_argument('port')
    end
  end

  defs.define_constant('Resolv::DNS::Requester::ConnectedUDP::RequestError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Requester::ConnectedUDP::Sender') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Requester::Sender', RubyLint.registry))

    klass.define_instance_method('data')

    klass.define_instance_method('send')
  end

  defs.define_constant('Resolv::DNS::Requester::ConnectedUDP::TCP') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Requester', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('host')
      method.define_optional_argument('port')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('recv_reply') do |method|
      method.define_argument('readable_socks')
    end

    klass.define_instance_method('sender') do |method|
      method.define_argument('msg')
      method.define_argument('data')
      method.define_optional_argument('host')
      method.define_optional_argument('port')
    end
  end

  defs.define_constant('Resolv::DNS::Requester::ConnectedUDP::UnconnectedUDP') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Requester', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('nameserver_port')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('recv_reply') do |method|
      method.define_argument('readable_socks')
    end

    klass.define_instance_method('sender') do |method|
      method.define_argument('msg')
      method.define_argument('data')
      method.define_argument('host')
      method.define_optional_argument('port')
    end
  end

  defs.define_constant('Resolv::DNS::Requester::RequestError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Requester::Sender') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('msg')
      method.define_argument('data')
      method.define_argument('sock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Resolv::DNS::Requester::TCP') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Requester', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('host')
      method.define_optional_argument('port')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('recv_reply') do |method|
      method.define_argument('readable_socks')
    end

    klass.define_instance_method('sender') do |method|
      method.define_argument('msg')
      method.define_argument('data')
      method.define_optional_argument('host')
      method.define_optional_argument('port')
    end
  end

  defs.define_constant('Resolv::DNS::Requester::UnconnectedUDP') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Requester', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('nameserver_port')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('recv_reply') do |method|
      method.define_argument('readable_socks')
    end

    klass.define_instance_method('sender') do |method|
      method.define_argument('msg')
      method.define_argument('data')
      method.define_argument('host')
      method.define_optional_argument('port')
    end
  end

  defs.define_constant('Resolv::DNS::Resource') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Query', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_method('get_class') do |method|
      method.define_argument('type_value')
      method.define_argument('class_value')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('ttl')
  end

  defs.define_constant('Resolv::DNS::Resource::ANY') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Query', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::CNAME') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource::DomainName', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::ClassHash') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::ClassInsensitiveTypes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::ClassValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::DomainName') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')
  end

  defs.define_constant('Resolv::DNS::Resource::Generic') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('type_value')
      method.define_argument('class_value')
    end

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('data')

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Resolv::DNS::Resource::HINFO') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('cpu')

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('cpu')
      method.define_argument('os')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('os')
  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::ANY') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Query', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::CNAME') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource::DomainName', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::ClassHash') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::ClassInsensitiveTypes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::ClassValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::DomainName') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')
  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::Generic') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('type_value')
      method.define_argument('class_value')
    end

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('data')

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('data')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::IN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::MINFO') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('emailbx')

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('rmailbx')
      method.define_argument('emailbx')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('rmailbx')
  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::MX') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('exchange')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('preference')
      method.define_argument('exchange')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('preference')
  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::NS') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource::DomainName', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::PTR') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource::DomainName', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::SOA') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('expire')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mname')
      method.define_argument('rname')
      method.define_argument('serial')
      method.define_argument('refresh')
      method.define_argument('retry_')
      method.define_argument('expire')
      method.define_argument('minimum')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('minimum')

    klass.define_instance_method('mname')

    klass.define_instance_method('refresh')

    klass.define_instance_method('retry')

    klass.define_instance_method('rname')

    klass.define_instance_method('serial')
  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::TXT') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('data')

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('first_string')
      method.define_rest_argument('rest_strings')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('strings')
  end

  defs.define_constant('Resolv::DNS::Resource::HINFO::TypeValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::IN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::MINFO') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('emailbx')

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('rmailbx')
      method.define_argument('emailbx')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('rmailbx')
  end

  defs.define_constant('Resolv::DNS::Resource::MX') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('exchange')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('preference')
      method.define_argument('exchange')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('preference')
  end

  defs.define_constant('Resolv::DNS::Resource::NS') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource::DomainName', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::PTR') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource::DomainName', RubyLint.registry))

  end

  defs.define_constant('Resolv::DNS::Resource::SOA') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('expire')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mname')
      method.define_argument('rname')
      method.define_argument('serial')
      method.define_argument('refresh')
      method.define_argument('retry_')
      method.define_argument('expire')
      method.define_argument('minimum')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('minimum')

    klass.define_instance_method('mname')

    klass.define_instance_method('refresh')

    klass.define_instance_method('retry')

    klass.define_instance_method('rname')

    klass.define_instance_method('serial')
  end

  defs.define_constant('Resolv::DNS::Resource::TXT') do |klass|
    klass.inherits(defs.constant_proxy('Resolv::DNS::Resource', RubyLint.registry))

    klass.define_method('decode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('data')

    klass.define_instance_method('encode_rdata') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('first_string')
      method.define_rest_argument('rest_strings')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('strings')
  end

  defs.define_constant('Resolv::DNS::UDPSize') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::DefaultResolver') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::Hosts') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each_address') do |method|
      method.define_argument('name')
      method.define_block_argument('proc')
    end

    klass.define_instance_method('each_name') do |method|
      method.define_argument('address')
      method.define_block_argument('proc')
    end

    klass.define_instance_method('getaddress') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('getaddresses') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('getname') do |method|
      method.define_argument('address')
    end

    klass.define_instance_method('getnames') do |method|
      method.define_argument('address')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('filename')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lazy_initialize')
  end

  defs.define_constant('Resolv::Hosts::DefaultFileName') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::IPv4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('address')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('address')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('to_name')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Resolv::IPv4::Regex') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::IPv4::Regex256') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::IPv6') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('address')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('address')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('to_name')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Resolv::IPv6::Regex') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::IPv6::Regex_6Hex4Dec') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::IPv6::Regex_8Hex') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::IPv6::Regex_CompressedHex') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::IPv6::Regex_CompressedHex4Dec') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Resolv::ResolvError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Resolv::ResolvTimeout') do |klass|
    klass.inherits(defs.constant_proxy('Timeout::Error', RubyLint.registry))

  end
end
