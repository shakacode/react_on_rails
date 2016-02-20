# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('CGI') do |defs|
  defs.define_constant('CGI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('accept_charset')

    klass.define_method('accept_charset=') do |method|
      method.define_argument('accept_charset')
    end

    klass.define_method('parse') do |method|
      method.define_argument('query')
    end

    klass.define_instance_method('accept_charset')

    klass.define_instance_method('header') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('http_header') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('nph?')

    klass.define_instance_method('out') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('print') do |method|
      method.define_rest_argument('options')
    end
  end

  defs.define_constant('CGI::CR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::Cookie') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_method('parse') do |method|
      method.define_argument('raw_cookie')
    end

    klass.define_instance_method('domain')

    klass.define_instance_method('domain=')

    klass.define_instance_method('expires')

    klass.define_instance_method('expires=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('name')
      method.define_rest_argument('value')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('path')

    klass.define_instance_method('path=')

    klass.define_instance_method('secure')

    klass.define_instance_method('secure=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('value')

    klass.define_instance_method('value=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('CGI::Cookie::Enumerator') do |klass|
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

  defs.define_constant('CGI::Cookie::SortedElement') do |klass|
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

  defs.define_constant('CGI::EOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::HTTP_STATUS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::InvalidEncoding') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

  end

  defs.define_constant('CGI::LF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::MAX_MULTIPART_COUNT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::MAX_MULTIPART_LENGTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::NEEDS_BINMODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::PATH_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::QueryExtension') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('accept')

    klass.define_instance_method('accept_charset')

    klass.define_instance_method('accept_encoding')

    klass.define_instance_method('accept_language')

    klass.define_instance_method('auth_type')

    klass.define_instance_method('cache_control')

    klass.define_instance_method('content_length')

    klass.define_instance_method('content_type')

    klass.define_instance_method('cookies')

    klass.define_instance_method('cookies=')

    klass.define_instance_method('create_body') do |method|
      method.define_argument('is_large')
    end

    klass.define_instance_method('files')

    klass.define_instance_method('from')

    klass.define_instance_method('gateway_interface')

    klass.define_instance_method('has_key?') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('host')

    klass.define_instance_method('include?') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('key?') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('keys') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('multipart?')

    klass.define_instance_method('negotiate')

    klass.define_instance_method('params')

    klass.define_instance_method('params=') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('path_info')

    klass.define_instance_method('path_translated')

    klass.define_instance_method('pragma')

    klass.define_instance_method('query_string')

    klass.define_instance_method('raw_cookie')

    klass.define_instance_method('raw_cookie2')

    klass.define_instance_method('referer')

    klass.define_instance_method('remote_addr')

    klass.define_instance_method('remote_host')

    klass.define_instance_method('remote_ident')

    klass.define_instance_method('remote_user')

    klass.define_instance_method('request_method')

    klass.define_instance_method('script_name')

    klass.define_instance_method('server_name')

    klass.define_instance_method('server_port')

    klass.define_instance_method('server_protocol')

    klass.define_instance_method('server_software')

    klass.define_instance_method('unescape_filename?')

    klass.define_instance_method('user_agent')
  end

  defs.define_constant('CGI::REVISION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::Util') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('escape') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('escapeElement') do |method|
      method.define_argument('string')
      method.define_rest_argument('elements')
    end

    klass.define_instance_method('escapeHTML') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('escape_element') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('escape_html') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('h') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('pretty') do |method|
      method.define_argument('string')
      method.define_optional_argument('shift')
    end

    klass.define_instance_method('rfc1123_date') do |method|
      method.define_argument('time')
    end

    klass.define_instance_method('unescape') do |method|
      method.define_argument('string')
      method.define_optional_argument('encoding')
    end

    klass.define_instance_method('unescapeElement') do |method|
      method.define_argument('string')
      method.define_rest_argument('elements')
    end

    klass.define_instance_method('unescapeHTML') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('unescape_element') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('unescape_html') do |method|
      method.define_argument('str')
    end
  end

  defs.define_constant('CGI::Util::RFC822_DAYS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::Util::RFC822_MONTHS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('CGI::Util::TABLE_FOR_ESCAPE_HTML__') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
