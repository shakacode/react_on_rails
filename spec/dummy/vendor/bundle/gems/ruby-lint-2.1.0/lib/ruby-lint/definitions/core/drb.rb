# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('DRb') do |defs|
  defs.define_constant('DRb') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('config')

    klass.define_method('current_server')

    klass.define_method('fetch_server') do |method|
      method.define_argument('uri')
    end

    klass.define_method('front')

    klass.define_method('here?') do |method|
      method.define_argument('uri')
    end

    klass.define_method('install_acl') do |method|
      method.define_argument('acl')
    end

    klass.define_method('install_id_conv') do |method|
      method.define_argument('idconv')
    end

    klass.define_method('mutex')

    klass.define_method('primary_server')

    klass.define_method('primary_server=')

    klass.define_method('regist_server') do |method|
      method.define_argument('server')
    end

    klass.define_method('remove_server') do |method|
      method.define_argument('server')
    end

    klass.define_method('start_service') do |method|
      method.define_optional_argument('uri')
      method.define_optional_argument('front')
      method.define_optional_argument('config')
    end

    klass.define_method('stop_service')

    klass.define_method('thread')

    klass.define_method('to_id') do |method|
      method.define_argument('obj')
    end

    klass.define_method('to_obj') do |method|
      method.define_argument('ref')
    end

    klass.define_method('uri')
  end

  defs.define_constant('DRb::DRbArray') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('_load') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_argument('lv')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('ary')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('DRb::DRbBadScheme') do |klass|
    klass.inherits(defs.constant_proxy('DRb::DRbError', RubyLint.registry))

  end

  defs.define_constant('DRb::DRbBadURI') do |klass|
    klass.inherits(defs.constant_proxy('DRb::DRbError', RubyLint.registry))

  end

  defs.define_constant('DRb::DRbConn') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('open') do |method|
      method.define_argument('remote_uri')
    end

    klass.define_instance_method('alive?')

    klass.define_instance_method('close')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('remote_uri')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('send_message') do |method|
      method.define_argument('ref')
      method.define_argument('msg_id')
      method.define_argument('arg')
      method.define_argument('block')
    end

    klass.define_instance_method('uri')
  end

  defs.define_constant('DRb::DRbConn::POOL_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DRb::DRbConnError') do |klass|
    klass.inherits(defs.constant_proxy('DRb::DRbError', RubyLint.registry))

  end

  defs.define_constant('DRb::DRbError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

  end

  defs.define_constant('DRb::DRbIdConv') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('to_id') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('to_obj') do |method|
      method.define_argument('ref')
    end
  end

  defs.define_constant('DRb::DRbMessage') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('dump') do |method|
      method.define_argument('obj')
      method.define_optional_argument('error')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load') do |method|
      method.define_argument('soc')
    end

    klass.define_instance_method('recv_reply') do |method|
      method.define_argument('stream')
    end

    klass.define_instance_method('recv_request') do |method|
      method.define_argument('stream')
    end

    klass.define_instance_method('send_reply') do |method|
      method.define_argument('stream')
      method.define_argument('succ')
      method.define_argument('result')
    end

    klass.define_instance_method('send_request') do |method|
      method.define_argument('stream')
      method.define_argument('ref')
      method.define_argument('msg_id')
      method.define_argument('arg')
      method.define_argument('b')
    end
  end

  defs.define_constant('DRb::DRbObject') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('_load') do |method|
      method.define_argument('s')
    end

    klass.define_method('new_with') do |method|
      method.define_argument('uri')
      method.define_argument('ref')
    end

    klass.define_method('new_with_uri') do |method|
      method.define_argument('uri')
    end

    klass.define_method('prepare_backtrace') do |method|
      method.define_argument('uri')
      method.define_argument('result')
    end

    klass.define_method('with_friend') do |method|
      method.define_argument('uri')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('__drbref')

    klass.define_instance_method('__drburi')

    klass.define_instance_method('_dump') do |method|
      method.define_argument('lv')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('obj')
      method.define_optional_argument('uri')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('msg_id')
      method.define_rest_argument('a')
      method.define_block_argument('b')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('msg_id')
      method.define_optional_argument('priv')
    end
  end

  defs.define_constant('DRb::DRbProtocol') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_protocol') do |method|
      method.define_argument('prot')
    end

    klass.define_method('auto_load') do |method|
      method.define_argument('uri')
      method.define_argument('config')
    end

    klass.define_method('open') do |method|
      method.define_argument('uri')
      method.define_argument('config')
      method.define_optional_argument('first')
    end

    klass.define_method('open_server') do |method|
      method.define_argument('uri')
      method.define_argument('config')
      method.define_optional_argument('first')
    end

    klass.define_method('uri_option') do |method|
      method.define_argument('uri')
      method.define_argument('config')
      method.define_optional_argument('first')
    end
  end

  defs.define_constant('DRb::DRbRemoteError') do |klass|
    klass.inherits(defs.constant_proxy('DRb::DRbError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('error')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('reason')
  end

  defs.define_constant('DRb::DRbServer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('default_acl') do |method|
      method.define_argument('acl')
    end

    klass.define_method('default_argc_limit') do |method|
      method.define_argument('argc')
    end

    klass.define_method('default_id_conv') do |method|
      method.define_argument('idconv')
    end

    klass.define_method('default_load_limit') do |method|
      method.define_argument('sz')
    end

    klass.define_method('default_safe_level') do |method|
      method.define_argument('level')
    end

    klass.define_method('make_config') do |method|
      method.define_optional_argument('hash')
    end

    klass.define_method('verbose')

    klass.define_method('verbose=') do |method|
      method.define_argument('on')
    end

    klass.define_instance_method('alive?')

    klass.define_instance_method('check_insecure_method') do |method|
      method.define_argument('obj')
      method.define_argument('msg_id')
    end

    klass.define_instance_method('config')

    klass.define_instance_method('front')

    klass.define_instance_method('here?') do |method|
      method.define_argument('uri')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('uri')
      method.define_optional_argument('front')
      method.define_optional_argument('config_or_acl')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('safe_level')

    klass.define_instance_method('stop_service')

    klass.define_instance_method('thread')

    klass.define_instance_method('to_id') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('to_obj') do |method|
      method.define_argument('ref')
    end

    klass.define_instance_method('uri')

    klass.define_instance_method('verbose')

    klass.define_instance_method('verbose=') do |method|
      method.define_argument('v')
    end
  end

  defs.define_constant('DRb::DRbServer::INSECURE_METHOD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DRb::DRbServer::InvokeMethod') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('DRb::DRbServer::InvokeMethod18Mixin', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('drb_server')
      method.define_argument('client')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('perform')
  end

  defs.define_constant('DRb::DRbServer::InvokeMethod18Mixin') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('block_yield') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('perform_with_block')
  end

  defs.define_constant('DRb::DRbServerNotFound') do |klass|
    klass.inherits(defs.constant_proxy('DRb::DRbError', RubyLint.registry))

  end

  defs.define_constant('DRb::DRbTCPSocket') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('getservername')

    klass.define_method('open') do |method|
      method.define_argument('uri')
      method.define_argument('config')
    end

    klass.define_method('open_server') do |method|
      method.define_argument('uri')
      method.define_argument('config')
    end

    klass.define_method('open_server_inaddr_any') do |method|
      method.define_argument('host')
      method.define_argument('port')
    end

    klass.define_method('parse_uri') do |method|
      method.define_argument('uri')
    end

    klass.define_method('uri_option') do |method|
      method.define_argument('uri')
      method.define_argument('config')
    end

    klass.define_instance_method('accept')

    klass.define_instance_method('alive?')

    klass.define_instance_method('close')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('uri')
      method.define_argument('soc')
      method.define_optional_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('peeraddr')

    klass.define_instance_method('recv_reply')

    klass.define_instance_method('recv_request')

    klass.define_instance_method('send_reply') do |method|
      method.define_argument('succ')
      method.define_argument('result')
    end

    klass.define_instance_method('send_request') do |method|
      method.define_argument('ref')
      method.define_argument('msg_id')
      method.define_argument('arg')
      method.define_argument('b')
    end

    klass.define_instance_method('set_sockopt') do |method|
      method.define_argument('soc')
    end

    klass.define_instance_method('stream')

    klass.define_instance_method('uri')
  end

  defs.define_constant('DRb::DRbURIOption') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('option')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('option')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('DRb::DRbUndumped') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_dump') do |method|
      method.define_argument('dummy')
    end
  end

  defs.define_constant('DRb::DRbUnknown') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('_load') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_argument('lv')
    end

    klass.define_instance_method('buf')

    klass.define_instance_method('exception')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('err')
      method.define_argument('buf')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('reload')
  end

  defs.define_constant('DRb::DRbUnknownError') do |klass|
    klass.inherits(defs.constant_proxy('DRb::DRbError', RubyLint.registry))

    klass.define_method('_load') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_argument('lv')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('unknown')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('unknown')
  end
end
