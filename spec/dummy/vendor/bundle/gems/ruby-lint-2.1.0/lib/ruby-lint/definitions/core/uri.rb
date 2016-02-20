# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('URI') do |defs|
  defs.define_constant('URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('decode_www_form') do |method|
      method.define_argument('str')
      method.define_optional_argument('enc')
    end

    klass.define_method('decode_www_form_component') do |method|
      method.define_argument('str')
      method.define_optional_argument('enc')
    end

    klass.define_method('encode_www_form') do |method|
      method.define_argument('enum')
    end

    klass.define_method('encode_www_form_component') do |method|
      method.define_argument('str')
    end

    klass.define_method('extract') do |method|
      method.define_argument('str')
      method.define_optional_argument('schemes')
      method.define_block_argument('block')
    end

    klass.define_method('join') do |method|
      method.define_rest_argument('str')
    end

    klass.define_method('parse') do |method|
      method.define_argument('uri')
    end

    klass.define_method('regexp') do |method|
      method.define_optional_argument('schemes')
    end

    klass.define_method('scheme_list')

    klass.define_method('split') do |method|
      method.define_argument('uri')
    end
  end

  defs.define_constant('URI::ABS_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::ABS_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::ABS_URI_REF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::BadURIError') do |klass|
    klass.inherits(defs.constant_proxy('URI::Error', RubyLint.registry))

  end

  defs.define_constant('URI::DEFAULT_PARSER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::ESCAPED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('URI::Escape') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('decode') do |method|
      method.define_rest_argument('arg')
    end

    klass.define_instance_method('encode') do |method|
      method.define_rest_argument('arg')
    end

    klass.define_instance_method('escape') do |method|
      method.define_rest_argument('arg')
    end

    klass.define_instance_method('unescape') do |method|
      method.define_rest_argument('arg')
    end
  end

  defs.define_constant('URI::FRAGMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::FTP') do |klass|
    klass.inherits(defs.constant_proxy('URI::Generic', RubyLint.registry))
    klass.inherits(defs.constant_proxy('OpenURI::OpenRead', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('args')
    end

    klass.define_method('new2') do |method|
      method.define_argument('user')
      method.define_argument('password')
      method.define_argument('host')
      method.define_argument('port')
      method.define_argument('path')
      method.define_optional_argument('typecode')
      method.define_optional_argument('arg_check')
    end

    klass.define_instance_method('buffer_open') do |method|
      method.define_argument('buf')
      method.define_argument('proxy')
      method.define_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('path')

    klass.define_instance_method('set_path') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_typecode') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('typecode')

    klass.define_instance_method('typecode=') do |method|
      method.define_argument('typecode')
    end
  end

  defs.define_constant('URI::Generic') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('URI', RubyLint.registry))
    klass.inherits(defs.constant_proxy('URI::REGEXP', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('args')
    end

    klass.define_method('build2') do |method|
      method.define_argument('args')
    end

    klass.define_method('component')

    klass.define_method('default_port')

    klass.define_method('use_registry')

    klass.define_instance_method('+') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('absolute')

    klass.define_instance_method('absolute?')

    klass.define_instance_method('coerce') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('component')

    klass.define_instance_method('component_ary')

    klass.define_instance_method('default_port')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('find_proxy')

    klass.define_instance_method('fragment')

    klass.define_instance_method('fragment=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('hierarchical?')

    klass.define_instance_method('host')

    klass.define_instance_method('host=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('hostname')

    klass.define_instance_method('hostname=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('scheme')
      method.define_argument('userinfo')
      method.define_argument('host')
      method.define_argument('port')
      method.define_argument('registry')
      method.define_argument('path')
      method.define_argument('opaque')
      method.define_argument('query')
      method.define_argument('fragment')
      method.define_optional_argument('parser')
      method.define_optional_argument('arg_check')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('merge') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('merge!') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('normalize')

    klass.define_instance_method('normalize!')

    klass.define_instance_method('opaque')

    klass.define_instance_method('opaque=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('parser')

    klass.define_instance_method('password')

    klass.define_instance_method('password=') do |method|
      method.define_argument('password')
    end

    klass.define_instance_method('path')

    klass.define_instance_method('path=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('port')

    klass.define_instance_method('port=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('query')

    klass.define_instance_method('query=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('registry')

    klass.define_instance_method('registry=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('relative?')

    klass.define_instance_method('route_from') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('route_to') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('scheme')

    klass.define_instance_method('scheme=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('select') do |method|
      method.define_rest_argument('components')
    end

    klass.define_instance_method('set_fragment') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_host') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_opaque') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_password') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_path') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_port') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_query') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_registry') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_scheme') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_user') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_userinfo') do |method|
      method.define_argument('user')
      method.define_optional_argument('password')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('user')

    klass.define_instance_method('user=') do |method|
      method.define_argument('user')
    end

    klass.define_instance_method('userinfo')

    klass.define_instance_method('userinfo=') do |method|
      method.define_argument('userinfo')
    end
  end

  defs.define_constant('URI::HOST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTML5ASCIIINCOMPAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTP') do |klass|
    klass.inherits(defs.constant_proxy('URI::Generic', RubyLint.registry))
    klass.inherits(defs.constant_proxy('OpenURI::OpenRead', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('args')
    end

    klass.define_instance_method('buffer_open') do |method|
      method.define_argument('buf')
      method.define_argument('proxy')
      method.define_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('request_uri')
  end

  defs.define_constant('URI::HTTPS') do |klass|
    klass.inherits(defs.constant_proxy('URI::HTTP', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::ABS_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::ABS_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::ABS_URI_REF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::BadURIError') do |klass|
    klass.inherits(defs.constant_proxy('URI::Error', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::COMPONENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::DEFAULT_PARSER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::DEFAULT_PORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::ESCAPED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::Escape') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('decode') do |method|
      method.define_rest_argument('arg')
    end

    klass.define_instance_method('encode') do |method|
      method.define_rest_argument('arg')
    end

    klass.define_instance_method('escape') do |method|
      method.define_rest_argument('arg')
    end

    klass.define_instance_method('unescape') do |method|
      method.define_rest_argument('arg')
    end
  end

  defs.define_constant('URI::HTTPS::FRAGMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::FTP') do |klass|
    klass.inherits(defs.constant_proxy('URI::Generic', RubyLint.registry))
    klass.inherits(defs.constant_proxy('OpenURI::OpenRead', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('args')
    end

    klass.define_method('new2') do |method|
      method.define_argument('user')
      method.define_argument('password')
      method.define_argument('host')
      method.define_argument('port')
      method.define_argument('path')
      method.define_optional_argument('typecode')
      method.define_optional_argument('arg_check')
    end

    klass.define_instance_method('buffer_open') do |method|
      method.define_argument('buf')
      method.define_argument('proxy')
      method.define_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('path')

    klass.define_instance_method('set_path') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_typecode') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('typecode')

    klass.define_instance_method('typecode=') do |method|
      method.define_argument('typecode')
    end
  end

  defs.define_constant('URI::HTTPS::Generic') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('URI', RubyLint.registry))
    klass.inherits(defs.constant_proxy('URI::REGEXP', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('args')
    end

    klass.define_method('build2') do |method|
      method.define_argument('args')
    end

    klass.define_method('component')

    klass.define_method('default_port')

    klass.define_method('use_registry')

    klass.define_instance_method('+') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('absolute')

    klass.define_instance_method('absolute?')

    klass.define_instance_method('coerce') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('component')

    klass.define_instance_method('component_ary')

    klass.define_instance_method('default_port')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('find_proxy')

    klass.define_instance_method('fragment')

    klass.define_instance_method('fragment=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('hierarchical?')

    klass.define_instance_method('host')

    klass.define_instance_method('host=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('hostname')

    klass.define_instance_method('hostname=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('scheme')
      method.define_argument('userinfo')
      method.define_argument('host')
      method.define_argument('port')
      method.define_argument('registry')
      method.define_argument('path')
      method.define_argument('opaque')
      method.define_argument('query')
      method.define_argument('fragment')
      method.define_optional_argument('parser')
      method.define_optional_argument('arg_check')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('merge') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('merge!') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('normalize')

    klass.define_instance_method('normalize!')

    klass.define_instance_method('opaque')

    klass.define_instance_method('opaque=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('parser')

    klass.define_instance_method('password')

    klass.define_instance_method('password=') do |method|
      method.define_argument('password')
    end

    klass.define_instance_method('path')

    klass.define_instance_method('path=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('port')

    klass.define_instance_method('port=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('query')

    klass.define_instance_method('query=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('registry')

    klass.define_instance_method('registry=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('relative?')

    klass.define_instance_method('route_from') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('route_to') do |method|
      method.define_argument('oth')
    end

    klass.define_instance_method('scheme')

    klass.define_instance_method('scheme=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('select') do |method|
      method.define_rest_argument('components')
    end

    klass.define_instance_method('set_fragment') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_host') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_opaque') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_password') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_path') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_port') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_query') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_registry') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_scheme') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_user') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_userinfo') do |method|
      method.define_argument('user')
      method.define_optional_argument('password')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('user')

    klass.define_instance_method('user=') do |method|
      method.define_argument('user')
    end

    klass.define_instance_method('userinfo')

    klass.define_instance_method('userinfo=') do |method|
      method.define_argument('userinfo')
    end
  end

  defs.define_constant('URI::HTTPS::HOST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::HTML5ASCIIINCOMPAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::HTTP') do |klass|
    klass.inherits(defs.constant_proxy('URI::Generic', RubyLint.registry))
    klass.inherits(defs.constant_proxy('OpenURI::OpenRead', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('args')
    end

    klass.define_instance_method('buffer_open') do |method|
      method.define_argument('buf')
      method.define_argument('proxy')
      method.define_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('request_uri')
  end

  defs.define_constant('URI::HTTPS::InvalidComponentError') do |klass|
    klass.inherits(defs.constant_proxy('URI::Error', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::InvalidURIError') do |klass|
    klass.inherits(defs.constant_proxy('URI::Error', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::LDAP') do |klass|
    klass.inherits(defs.constant_proxy('URI::Generic', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('args')
    end

    klass.define_instance_method('attributes')

    klass.define_instance_method('attributes=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('dn')

    klass.define_instance_method('dn=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('extensions')

    klass.define_instance_method('extensions=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hierarchical?')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('scope')

    klass.define_instance_method('scope=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_attributes') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_dn') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_extensions') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_filter') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_scope') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('URI::HTTPS::LDAPS') do |klass|
    klass.inherits(defs.constant_proxy('URI::LDAP', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::MailTo') do |klass|
    klass.inherits(defs.constant_proxy('URI::Generic', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('args')
    end

    klass.define_instance_method('headers')

    klass.define_instance_method('headers=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('set_headers') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_to') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('to')

    klass.define_instance_method('to=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('to_mailtext')

    klass.define_instance_method('to_rfc822text')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('URI::HTTPS::OPAQUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::PORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::Parser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('URI::REGEXP', RubyLint.registry))

    klass.define_instance_method('escape') do |method|
      method.define_argument('str')
      method.define_optional_argument('unsafe')
    end

    klass.define_instance_method('extract') do |method|
      method.define_argument('str')
      method.define_optional_argument('schemes')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('opts')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('join') do |method|
      method.define_rest_argument('uris')
    end

    klass.define_instance_method('make_regexp') do |method|
      method.define_optional_argument('schemes')
    end

    klass.define_instance_method('parse') do |method|
      method.define_argument('uri')
    end

    klass.define_instance_method('pattern')

    klass.define_instance_method('regexp')

    klass.define_instance_method('split') do |method|
      method.define_argument('uri')
    end

    klass.define_instance_method('unescape') do |method|
      method.define_argument('str')
      method.define_optional_argument('escaped')
    end
  end

  defs.define_constant('URI::HTTPS::QUERY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::REGISTRY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::REL_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::REL_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::REL_URI_REF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::SCHEME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::TBLDECWWWCOMP_') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::TBLENCWWWCOMP_') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::UNSAFE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::URI_REF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::USERINFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::USE_REGISTRY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::Util') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('make_components_hash') do |method|
      method.define_argument('klass')
      method.define_argument('array_hash')
    end
  end

  defs.define_constant('URI::HTTPS::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::VERSION_CODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::HTTPS::WFKV_') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::InvalidComponentError') do |klass|
    klass.inherits(defs.constant_proxy('URI::Error', RubyLint.registry))

  end

  defs.define_constant('URI::InvalidURIError') do |klass|
    klass.inherits(defs.constant_proxy('URI::Error', RubyLint.registry))

  end

  defs.define_constant('URI::LDAP') do |klass|
    klass.inherits(defs.constant_proxy('URI::Generic', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('args')
    end

    klass.define_instance_method('attributes')

    klass.define_instance_method('attributes=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('dn')

    klass.define_instance_method('dn=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('extensions')

    klass.define_instance_method('extensions=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hierarchical?')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('scope')

    klass.define_instance_method('scope=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_attributes') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_dn') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_extensions') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_filter') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_scope') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('URI::LDAPS') do |klass|
    klass.inherits(defs.constant_proxy('URI::LDAP', RubyLint.registry))

  end

  defs.define_constant('URI::MailTo') do |klass|
    klass.inherits(defs.constant_proxy('URI::Generic', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('args')
    end

    klass.define_instance_method('headers')

    klass.define_instance_method('headers=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('set_headers') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('set_to') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('to')

    klass.define_instance_method('to=') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('to_mailtext')

    klass.define_instance_method('to_rfc822text')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('URI::OPAQUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::PORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::Parser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('URI::REGEXP', RubyLint.registry))

    klass.define_instance_method('escape') do |method|
      method.define_argument('str')
      method.define_optional_argument('unsafe')
    end

    klass.define_instance_method('extract') do |method|
      method.define_argument('str')
      method.define_optional_argument('schemes')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('opts')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('join') do |method|
      method.define_rest_argument('uris')
    end

    klass.define_instance_method('make_regexp') do |method|
      method.define_optional_argument('schemes')
    end

    klass.define_instance_method('parse') do |method|
      method.define_argument('uri')
    end

    klass.define_instance_method('pattern')

    klass.define_instance_method('regexp')

    klass.define_instance_method('split') do |method|
      method.define_argument('uri')
    end

    klass.define_instance_method('unescape') do |method|
      method.define_argument('str')
      method.define_optional_argument('escaped')
    end
  end

  defs.define_constant('URI::QUERY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::REGISTRY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::REL_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::REL_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::REL_URI_REF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::SCHEME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::TBLDECWWWCOMP_') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::TBLENCWWWCOMP_') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::UNSAFE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::URI_REF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::USERINFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::Util') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('make_components_hash') do |method|
      method.define_argument('klass')
      method.define_argument('array_hash')
    end
  end

  defs.define_constant('URI::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::VERSION_CODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('URI::WFKV_') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
