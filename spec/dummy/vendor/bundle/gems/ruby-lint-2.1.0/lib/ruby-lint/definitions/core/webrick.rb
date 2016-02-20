# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('WEBrick') do |defs|
  defs.define_constant('WEBrick') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::AccessLog') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('escape') do |method|
      method.define_argument('data')
    end

    klass.define_method('format') do |method|
      method.define_argument('format_string')
      method.define_argument('params')
    end

    klass.define_method('setup_params') do |method|
      method.define_argument('config')
      method.define_argument('req')
      method.define_argument('res')
    end
  end

  defs.define_constant('WEBrick::AccessLog::AGENT_LOG_FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::AccessLog::AccessLogError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::AccessLog::CLF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::AccessLog::CLF_TIME_FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::AccessLog::COMBINED_LOG_FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::AccessLog::COMMON_LOG_FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::AccessLog::REFERER_LOG_FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::BasicLog') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('debug') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('debug?')

    klass.define_instance_method('error') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('error?')

    klass.define_instance_method('fatal') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('fatal?')

    klass.define_instance_method('info') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('info?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('log_file')
      method.define_optional_argument('level')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('level')

    klass.define_instance_method('level=')

    klass.define_instance_method('log') do |method|
      method.define_argument('level')
      method.define_argument('data')
    end

    klass.define_instance_method('warn') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('warn?')
  end

  defs.define_constant('WEBrick::BasicLog::DEBUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::BasicLog::ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::BasicLog::FATAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::BasicLog::INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::BasicLog::WARN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::CR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::CRLF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Config') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Config::BasicAuth') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Config::DigestAuth') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Config::FileHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Config::General') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Config::HTTP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Config::LIBDIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Cookie') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('parse') do |method|
      method.define_argument('str')
    end

    klass.define_method('parse_set_cookie') do |method|
      method.define_argument('str')
    end

    klass.define_method('parse_set_cookies') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('comment')

    klass.define_instance_method('comment=')

    klass.define_instance_method('domain')

    klass.define_instance_method('domain=')

    klass.define_instance_method('expires')

    klass.define_instance_method('expires=') do |method|
      method.define_argument('t')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('value')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('max_age')

    klass.define_instance_method('max_age=')

    klass.define_instance_method('name')

    klass.define_instance_method('path')

    klass.define_instance_method('path=')

    klass.define_instance_method('secure')

    klass.define_instance_method('secure=')

    klass.define_instance_method('to_s')

    klass.define_instance_method('value')

    klass.define_instance_method('value=')

    klass.define_instance_method('version')

    klass.define_instance_method('version=')
  end

  defs.define_constant('WEBrick::Daemon') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('start')
  end

  defs.define_constant('WEBrick::GenericServer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('config')
      method.define_optional_argument('default')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('listen') do |method|
      method.define_argument('address')
      method.define_argument('port')
    end

    klass.define_instance_method('listeners')

    klass.define_instance_method('logger')

    klass.define_instance_method('run') do |method|
      method.define_argument('sock')
    end

    klass.define_instance_method('shutdown')

    klass.define_instance_method('start') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('status')

    klass.define_instance_method('stop')

    klass.define_instance_method('tokens')
  end

  defs.define_constant('WEBrick::HTMLUtils') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('escape') do |method|
      method.define_argument('string')
    end
  end

  defs.define_constant('WEBrick::HTTPAuth') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('_basic_auth') do |method|
      method.define_argument('req')
      method.define_argument('res')
      method.define_argument('realm')
      method.define_argument('req_field')
      method.define_argument('res_field')
      method.define_argument('err_type')
      method.define_argument('block')
    end

    klass.define_method('basic_auth') do |method|
      method.define_argument('req')
      method.define_argument('res')
      method.define_argument('realm')
      method.define_block_argument('block')
    end

    klass.define_method('proxy_basic_auth') do |method|
      method.define_argument('req')
      method.define_argument('res')
      method.define_argument('realm')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('WEBrick::HTTPAuth::Authenticator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('logger')

    klass.define_instance_method('realm')

    klass.define_instance_method('userdb')
  end

  defs.define_constant('WEBrick::HTTPAuth::Authenticator::AuthException') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::Authenticator::AuthScheme') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::Authenticator::RequestField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::Authenticator::ResponseField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::Authenticator::ResponseInfoField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::BasicAuth') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('WEBrick::HTTPAuth::Authenticator', RubyLint.registry))

    klass.define_method('make_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
      method.define_argument('pass')
    end

    klass.define_instance_method('authenticate') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('challenge') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('config')
      method.define_optional_argument('default')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('realm')

    klass.define_instance_method('userdb')
  end

  defs.define_constant('WEBrick::HTTPAuth::BasicAuth::AuthException') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::BasicAuth::AuthScheme') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::BasicAuth::RequestField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::BasicAuth::ResponseField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::BasicAuth::ResponseInfoField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('WEBrick::HTTPAuth::Authenticator', RubyLint.registry))

    klass.define_method('make_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
      method.define_argument('pass')
    end

    klass.define_instance_method('algorithm')

    klass.define_instance_method('authenticate') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('challenge') do |method|
      method.define_argument('req')
      method.define_argument('res')
      method.define_optional_argument('stale')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('config')
      method.define_optional_argument('default')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('qop')
  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::AuthException') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::AuthScheme') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::MustParams') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::MustParamsAuth') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::OpaqueInfo') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('nc')

    klass.define_instance_method('nc=')

    klass.define_instance_method('nonce')

    klass.define_instance_method('nonce=')

    klass.define_instance_method('time')

    klass.define_instance_method('time=')
  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::OpaqueInfo::Enumerator') do |klass|
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

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::OpaqueInfo::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::OpaqueInfo::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::OpaqueInfo::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::OpaqueInfo::SortedElement') do |klass|
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

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::OpaqueInfo::Tms') do |klass|
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

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::RequestField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::ResponseField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::DigestAuth::ResponseInfoField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::Htdigest') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('WEBrick::HTTPAuth::UserDB', RubyLint.registry))

    klass.define_instance_method('delete_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('flush') do |method|
      method.define_optional_argument('output')
    end

    klass.define_instance_method('get_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
      method.define_argument('reload_db')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('reload')

    klass.define_instance_method('set_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
      method.define_argument('pass')
    end
  end

  defs.define_constant('WEBrick::HTTPAuth::Htgroup') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('group')
      method.define_argument('members')
    end

    klass.define_instance_method('flush') do |method|
      method.define_optional_argument('output')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('members') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('reload')
  end

  defs.define_constant('WEBrick::HTTPAuth::Htpasswd') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('WEBrick::HTTPAuth::UserDB', RubyLint.registry))

    klass.define_instance_method('delete_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('flush') do |method|
      method.define_optional_argument('output')
    end

    klass.define_instance_method('get_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
      method.define_argument('reload_db')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('reload')

    klass.define_instance_method('set_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
      method.define_argument('pass')
    end
  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyAuthenticator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyAuthenticator::AuthException') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyAuthenticator::InfoField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyAuthenticator::RequestField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyAuthenticator::ResponseField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyBasicAuth') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPAuth::BasicAuth', RubyLint.registry))
    klass.inherits(defs.constant_proxy('WEBrick::HTTPAuth::ProxyAuthenticator', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyBasicAuth::AuthException') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyBasicAuth::AuthScheme') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyBasicAuth::InfoField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyBasicAuth::RequestField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyBasicAuth::ResponseField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyBasicAuth::ResponseInfoField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyDigestAuth') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPAuth::DigestAuth', RubyLint.registry))
    klass.inherits(defs.constant_proxy('WEBrick::HTTPAuth::ProxyAuthenticator', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyDigestAuth::AuthException') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyDigestAuth::AuthScheme') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyDigestAuth::InfoField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyDigestAuth::MustParams') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyDigestAuth::MustParamsAuth') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyDigestAuth::OpaqueInfo') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('nc')

    klass.define_instance_method('nc=')

    klass.define_instance_method('nonce')

    klass.define_instance_method('nonce=')

    klass.define_instance_method('time')

    klass.define_instance_method('time=')
  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyDigestAuth::RequestField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyDigestAuth::ResponseField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::ProxyDigestAuth::ResponseInfoField') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPAuth::UserDB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('auth_type')

    klass.define_instance_method('auth_type=')

    klass.define_instance_method('get_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
      method.define_optional_argument('reload_db')
    end

    klass.define_instance_method('make_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
      method.define_argument('pass')
    end

    klass.define_instance_method('set_passwd') do |method|
      method.define_argument('realm')
      method.define_argument('user')
      method.define_argument('pass')
    end
  end

  defs.define_constant('WEBrick::HTTPRequest') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('header_name')
    end

    klass.define_instance_method('accept')

    klass.define_instance_method('accept_charset')

    klass.define_instance_method('accept_encoding')

    klass.define_instance_method('accept_language')

    klass.define_instance_method('addr')

    klass.define_instance_method('attributes')

    klass.define_instance_method('body') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('content_length')

    klass.define_instance_method('content_type')

    klass.define_instance_method('continue')

    klass.define_instance_method('cookies')

    klass.define_instance_method('each')

    klass.define_instance_method('fixup')

    klass.define_instance_method('header')

    klass.define_instance_method('host')

    klass.define_instance_method('http_version')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('keep_alive')

    klass.define_instance_method('keep_alive?')

    klass.define_instance_method('meta_vars')

    klass.define_instance_method('parse') do |method|
      method.define_optional_argument('socket')
    end

    klass.define_instance_method('path')

    klass.define_instance_method('path_info')

    klass.define_instance_method('path_info=')

    klass.define_instance_method('peeraddr')

    klass.define_instance_method('port')

    klass.define_instance_method('query')

    klass.define_instance_method('query_string')

    klass.define_instance_method('query_string=')

    klass.define_instance_method('raw_header')

    klass.define_instance_method('remote_ip')

    klass.define_instance_method('request_line')

    klass.define_instance_method('request_method')

    klass.define_instance_method('request_time')

    klass.define_instance_method('request_uri')

    klass.define_instance_method('script_name')

    klass.define_instance_method('script_name=')

    klass.define_instance_method('server_name')

    klass.define_instance_method('ssl?')

    klass.define_instance_method('to_s')

    klass.define_instance_method('unparsed_uri')

    klass.define_instance_method('user')

    klass.define_instance_method('user=')
  end

  defs.define_constant('WEBrick::HTTPRequest::BODY_CONTAINABLE_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPRequest::MAX_URI_LENGTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPRequest::PrivateNetworkRegexp') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPResponse') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('field')
      method.define_argument('value')
    end

    klass.define_instance_method('body')

    klass.define_instance_method('body=')

    klass.define_instance_method('chunked=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('chunked?')

    klass.define_instance_method('config')

    klass.define_instance_method('content_length')

    klass.define_instance_method('content_length=') do |method|
      method.define_argument('len')
    end

    klass.define_instance_method('content_type')

    klass.define_instance_method('content_type=') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('cookies')

    klass.define_instance_method('each')

    klass.define_instance_method('filename')

    klass.define_instance_method('filename=')

    klass.define_instance_method('header')

    klass.define_instance_method('http_version')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('keep_alive')

    klass.define_instance_method('keep_alive=')

    klass.define_instance_method('keep_alive?')

    klass.define_instance_method('reason_phrase')

    klass.define_instance_method('reason_phrase=')

    klass.define_instance_method('request_http_version')

    klass.define_instance_method('request_http_version=')

    klass.define_instance_method('request_method')

    klass.define_instance_method('request_method=')

    klass.define_instance_method('request_uri')

    klass.define_instance_method('request_uri=')

    klass.define_instance_method('send_body') do |method|
      method.define_argument('socket')
    end

    klass.define_instance_method('send_header') do |method|
      method.define_argument('socket')
    end

    klass.define_instance_method('send_response') do |method|
      method.define_argument('socket')
    end

    klass.define_instance_method('sent_size')

    klass.define_instance_method('set_error') do |method|
      method.define_argument('ex')
      method.define_optional_argument('backtrace')
    end

    klass.define_instance_method('set_redirect') do |method|
      method.define_argument('status')
      method.define_argument('url')
    end

    klass.define_instance_method('setup_header')

    klass.define_instance_method('status')

    klass.define_instance_method('status=') do |method|
      method.define_argument('status')
    end

    klass.define_instance_method('status_line')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('WEBrick::HTTPServer') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::GenericServer', RubyLint.registry))

    klass.define_instance_method('access_log') do |method|
      method.define_argument('config')
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('do_OPTIONS') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('config')
      method.define_optional_argument('default')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lookup_server') do |method|
      method.define_argument('req')
    end

    klass.define_instance_method('mount') do |method|
      method.define_argument('dir')
      method.define_argument('servlet')
      method.define_rest_argument('options')
    end

    klass.define_instance_method('mount_proc') do |method|
      method.define_argument('dir')
      method.define_optional_argument('proc')
      method.define_block_argument('block')
    end

    klass.define_instance_method('run') do |method|
      method.define_argument('sock')
    end

    klass.define_instance_method('search_servlet') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('service') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('umount') do |method|
      method.define_argument('dir')
    end

    klass.define_instance_method('unmount') do |method|
      method.define_argument('dir')
    end

    klass.define_instance_method('virtual_host') do |method|
      method.define_argument('server')
    end
  end

  defs.define_constant('WEBrick::HTTPServer::MountTable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('dir')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('dir')
      method.define_argument('val')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('dir')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('scan') do |method|
      method.define_argument('path')
    end
  end

  defs.define_constant('WEBrick::HTTPServerError') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::ServerError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPServlet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPServlet::AbstractServlet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('get_instance') do |method|
      method.define_argument('server')
      method.define_rest_argument('options')
    end

    klass.define_instance_method('do_GET') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('do_HEAD') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('do_OPTIONS') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('server')
      method.define_rest_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('service') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end
  end

  defs.define_constant('WEBrick::HTTPServlet::CGIHandler') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPServlet::AbstractServlet', RubyLint.registry))

    klass.define_instance_method('do_GET') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('do_POST') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('server')
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('WEBrick::HTTPServlet::CGIHandler::CGIRunner') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPServlet::CGIHandler::Ruby') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPServlet::DefaultFileHandler') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPServlet::AbstractServlet', RubyLint.registry))

    klass.define_instance_method('do_GET') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('server')
      method.define_argument('local_path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('make_partial_content') do |method|
      method.define_argument('req')
      method.define_argument('res')
      method.define_argument('filename')
      method.define_argument('filesize')
    end

    klass.define_instance_method('not_modified?') do |method|
      method.define_argument('req')
      method.define_argument('res')
      method.define_argument('mtime')
      method.define_argument('etag')
    end

    klass.define_instance_method('prepare_range') do |method|
      method.define_argument('range')
      method.define_argument('filesize')
    end
  end

  defs.define_constant('WEBrick::HTTPServlet::ERBHandler') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPServlet::AbstractServlet', RubyLint.registry))

    klass.define_instance_method('do_GET') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('do_POST') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('server')
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('WEBrick::HTTPServlet::FileHandler') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPServlet::AbstractServlet', RubyLint.registry))

    klass.define_method('add_handler') do |method|
      method.define_argument('suffix')
      method.define_argument('handler')
    end

    klass.define_method('remove_handler') do |method|
      method.define_argument('suffix')
    end

    klass.define_instance_method('do_GET') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('do_OPTIONS') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('do_POST') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('server')
      method.define_argument('root')
      method.define_optional_argument('options')
      method.define_optional_argument('default')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('service') do |method|
      method.define_argument('req')
      method.define_argument('res')
    end
  end

  defs.define_constant('WEBrick::HTTPServlet::FileHandler::HandlerTable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPServlet::HTTPServletError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPServlet::ProcHandler') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPServlet::AbstractServlet', RubyLint.registry))

    klass.define_instance_method('do_GET') do |method|
      method.define_argument('request')
      method.define_argument('response')
    end

    klass.define_instance_method('do_POST') do |method|
      method.define_argument('request')
      method.define_argument('response')
    end

    klass.define_instance_method('get_instance') do |method|
      method.define_argument('server')
      method.define_rest_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('proc')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('WEBrick::HTTPStatus') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_argument('code')
    end

    klass.define_method('client_error?') do |method|
      method.define_argument('code')
    end

    klass.define_method('error?') do |method|
      method.define_argument('code')
    end

    klass.define_method('info?') do |method|
      method.define_argument('code')
    end

    klass.define_method('reason_phrase') do |method|
      method.define_argument('code')
    end

    klass.define_method('redirect?') do |method|
      method.define_argument('code')
    end

    klass.define_method('server_error?') do |method|
      method.define_argument('code')
    end

    klass.define_method('success?') do |method|
      method.define_argument('code')
    end
  end

  defs.define_constant('WEBrick::HTTPStatus::Accepted') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Success', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::BadGateway') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ServerError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::BadRequest') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::ClientError') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Error', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::CodeToError') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Conflict') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Continue') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Info', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Created') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Success', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::EOFError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Error') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Status', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::ExpectationFailed') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::FailedDependency') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Forbidden') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Found') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Redirect', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::GatewayTimeout') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ServerError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Gone') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::HTTPVersionNotSupported') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ServerError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Info') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Status', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::InsufficientStorage') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ServerError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::InternalServerError') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ServerError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::LengthRequired') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Locked') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::MethodNotAllowed') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::MovedPermanently') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Redirect', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::MultiStatus') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Success', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::MultipleChoices') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Redirect', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::NetworkAuthenticationRequired') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ServerError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::NoContent') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Success', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::NonAuthoritativeInformation') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Success', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::NotAcceptable') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::NotFound') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::NotImplemented') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ServerError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::NotModified') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Redirect', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::OK') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Success', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::PartialContent') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Success', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::PaymentRequired') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::PreconditionFailed') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::PreconditionRequired') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::ProxyAuthenticationRequired') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_ACCEPTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_BAD_GATEWAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_BAD_REQUEST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_CONFLICT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_CONTINUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_CREATED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_EXPECTATION_FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_FAILED_DEPENDENCY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_FORBIDDEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_GATEWAY_TIMEOUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_GONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_HTTP_VERSION_NOT_SUPPORTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_INSUFFICIENT_STORAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_INTERNAL_SERVER_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_LENGTH_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_LOCKED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_METHOD_NOT_ALLOWED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_MOVED_PERMANENTLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_MULTIPLE_CHOICES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_MULTI_STATUS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_NETWORK_AUTHENTICATION_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_NON_AUTHORITATIVE_INFORMATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_NOT_ACCEPTABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_NOT_IMPLEMENTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_NOT_MODIFIED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_NO_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_PARTIAL_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_PAYMENT_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_PRECONDITION_FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_PRECONDITION_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_PROXY_AUTHENTICATION_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_REQUEST_ENTITY_TOO_LARGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_REQUEST_HEADER_FIELDS_TOO_LARGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_REQUEST_RANGE_NOT_SATISFIABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_REQUEST_TIMEOUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_REQUEST_URI_TOO_LARGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_RESET_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_SEE_OTHER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_SERVICE_UNAVAILABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_SWITCHING_PROTOCOLS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_TEMPORARY_REDIRECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_TOO_MANY_REQUESTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_UNAUTHORIZED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_UNPROCESSABLE_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_UNSUPPORTED_MEDIA_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_UPGRADE_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RC_USE_PROXY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Redirect') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Status', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RequestEntityTooLarge') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RequestHeaderFieldsTooLarge') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RequestRangeNotSatisfiable') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RequestTimeout') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::RequestURITooLarge') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::ResetContent') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Success', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::SeeOther') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Redirect', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::ServerError') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Error', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::ServiceUnavailable') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ServerError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Status') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_method('code')

    klass.define_method('reason_phrase')

    klass.define_instance_method('code')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('reason_phrase')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('WEBrick::HTTPStatus::StatusMessage') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Success') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Status', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::SwitchingProtocols') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Info', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::TemporaryRedirect') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Redirect', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::TooManyRequests') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::Unauthorized') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::UnprocessableEntity') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::UnsupportedMediaType') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::UpgradeRequired') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::ClientError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPStatus::UseProxy') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::HTTPStatus::Redirect', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPUtils') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('_escape') do |method|
      method.define_argument('str')
      method.define_argument('regex')
    end

    klass.define_method('_make_regex') do |method|
      method.define_argument('str')
    end

    klass.define_method('_make_regex!') do |method|
      method.define_argument('str')
    end

    klass.define_method('_unescape') do |method|
      method.define_argument('str')
      method.define_argument('regex')
    end

    klass.define_method('dequote') do |method|
      method.define_argument('str')
    end

    klass.define_method('escape') do |method|
      method.define_argument('str')
    end

    klass.define_method('escape8bit') do |method|
      method.define_argument('str')
    end

    klass.define_method('escape_form') do |method|
      method.define_argument('str')
    end

    klass.define_method('escape_path') do |method|
      method.define_argument('str')
    end

    klass.define_method('load_mime_types') do |method|
      method.define_argument('file')
    end

    klass.define_method('mime_type') do |method|
      method.define_argument('filename')
      method.define_argument('mime_tab')
    end

    klass.define_method('normalize_path') do |method|
      method.define_argument('path')
    end

    klass.define_method('parse_form_data') do |method|
      method.define_argument('io')
      method.define_argument('boundary')
    end

    klass.define_method('parse_header') do |method|
      method.define_argument('raw')
    end

    klass.define_method('parse_query') do |method|
      method.define_argument('str')
    end

    klass.define_method('parse_qvalues') do |method|
      method.define_argument('value')
    end

    klass.define_method('parse_range_header') do |method|
      method.define_argument('ranges_specifier')
    end

    klass.define_method('quote') do |method|
      method.define_argument('str')
    end

    klass.define_method('split_header_value') do |method|
      method.define_argument('str')
    end

    klass.define_method('unescape') do |method|
      method.define_argument('str')
    end

    klass.define_method('unescape_form') do |method|
      method.define_argument('str')
    end
  end

  defs.define_constant('WEBrick::HTTPUtils::DefaultMimeTypes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPUtils::ESCAPED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPUtils::FormData') do |klass|
    klass.inherits(defs.constant_proxy('String', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('key')
    end

    klass.define_instance_method('append_data') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('each_data')

    klass.define_instance_method('filename')

    klass.define_instance_method('filename=')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('list')

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('next_data')

    klass.define_instance_method('next_data=')

    klass.define_instance_method('to_ary')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('WEBrick::HTTPUtils::FormData::Complexifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('WEBrick::HTTPUtils::FormData::ControlCharacters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPUtils::FormData::ControlPrintValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPUtils::FormData::EmptyHeader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPUtils::FormData::EmptyRawHeader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPUtils::FormData::Rationalizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('WEBrick::HTTPUtils::NONASCII') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPUtils::UNESCAPED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPUtils::UNESCAPED_FORM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPUtils::UNESCAPED_PCHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::HTTPVersion') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('convert') do |method|
      method.define_argument('version')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('version')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('major')

    klass.define_instance_method('major=')

    klass.define_instance_method('minor')

    klass.define_instance_method('minor=')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('WEBrick::LF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Log') do |klass|
    klass.inherits(defs.constant_proxy('WEBrick::BasicLog', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('log_file')
      method.define_optional_argument('level')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('log') do |method|
      method.define_argument('level')
      method.define_argument('data')
    end

    klass.define_instance_method('time_format')

    klass.define_instance_method('time_format=')
  end

  defs.define_constant('WEBrick::Log::DEBUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Log::ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Log::FATAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Log::INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Log::WARN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::ServerError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('WEBrick::SimpleServer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('start')
  end

  defs.define_constant('WEBrick::Utils') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create_listeners') do |method|
      method.define_argument('address')
      method.define_argument('port')
      method.define_optional_argument('logger')
    end

    klass.define_method('getservername')

    klass.define_method('random_string') do |method|
      method.define_argument('len')
    end

    klass.define_method('set_close_on_exec') do |method|
      method.define_argument('io')
    end

    klass.define_method('set_non_blocking') do |method|
      method.define_argument('io')
    end

    klass.define_method('su') do |method|
      method.define_argument('user')
    end

    klass.define_method('timeout') do |method|
      method.define_argument('seconds')
      method.define_optional_argument('exception')
    end
  end

  defs.define_constant('WEBrick::Utils::RAND_CHARS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::Utils::TimeoutHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Singleton', RubyLint.registry))

    klass.define_method('cancel') do |method|
      method.define_argument('id')
    end

    klass.define_method('instance')

    klass.define_method('register') do |method|
      method.define_argument('seconds')
      method.define_argument('exception')
    end

    klass.define_instance_method('cancel') do |method|
      method.define_argument('thread')
      method.define_argument('id')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('interrupt') do |method|
      method.define_argument('thread')
      method.define_argument('id')
      method.define_argument('exception')
    end

    klass.define_instance_method('register') do |method|
      method.define_argument('thread')
      method.define_argument('time')
      method.define_argument('exception')
    end
  end

  defs.define_constant('WEBrick::Utils::TimeoutHandler::SingletonClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('clone')
  end

  defs.define_constant('WEBrick::Utils::TimeoutHandler::TimeoutMutex') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WEBrick::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
