# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.10.n219

RubyLint.registry.register('Sinatra') do |defs|
  defs.define_constant('Sinatra') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('helpers') do |method|
      method.define_rest_argument('extensions')
      method.define_block_argument('block')
    end

    klass.define_method('new') do |method|
      method.define_optional_argument('base')
      method.define_optional_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_method('register') do |method|
      method.define_rest_argument('extensions')
      method.define_block_argument('block')
    end

    klass.define_method('use') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Sinatra::Application') do |klass|
    klass.inherits(defs.constant_proxy('Sinatra::Base', RubyLint.registry))

    klass.define_method('app_file')

    klass.define_method('app_file=') do |method|
      method.define_argument('val')
    end

    klass.define_method('app_file?')

    klass.define_method('logging')

    klass.define_method('logging=') do |method|
      method.define_argument('val')
    end

    klass.define_method('logging?')

    klass.define_method('method_override')

    klass.define_method('method_override=') do |method|
      method.define_argument('val')
    end

    klass.define_method('method_override?')

    klass.define_method('register') do |method|
      method.define_rest_argument('extensions')
      method.define_block_argument('block')
    end

    klass.define_method('run')

    klass.define_method('run=') do |method|
      method.define_argument('val')
    end

    klass.define_method('run?')

    klass.define_method('session_secret')

    klass.define_method('session_secret=') do |method|
      method.define_argument('val')
    end

    klass.define_method('session_secret?')
  end

  defs.define_constant('Sinatra::Application::ContentTyped') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('content_type')

    klass.define_instance_method('content_type=')
  end

  defs.define_constant('Sinatra::Application::Context') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('app')

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('context') do |method|
      method.define_argument('env')
      method.define_optional_argument('app')
    end

    klass.define_instance_method('for')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app_f')
      method.define_argument('app_r')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('recontext') do |method|
      method.define_argument('app')
    end
  end

  defs.define_constant('Sinatra::Application::DEFAULT_SEP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Application::ESCAPE_HTML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Application::ESCAPE_HTML_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Application::HTTP_STATUS_CODES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Application::HeaderHash') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_optional_argument('hash')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('k')
      method.define_argument('v')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('include?') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('hash')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('member?') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('merge!') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('replace') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('to_hash')
  end

  defs.define_constant('Sinatra::Application::KeySpaceConstrainedParams') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('limit')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('to_params_hash')
  end

  defs.define_constant('Sinatra::Application::Multipart') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('build_multipart') do |method|
      method.define_argument('params')
      method.define_optional_argument('first')
    end

    klass.define_method('parse_multipart') do |method|
      method.define_argument('env')
    end
  end

  defs.define_constant('Sinatra::Application::OkJson') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('abbrev') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('arrenc') do |method|
      method.define_argument('a')
    end

    klass.define_instance_method('arrparse') do |method|
      method.define_argument('ts')
    end

    klass.define_instance_method('decode') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('eat') do |method|
      method.define_argument('typ')
      method.define_argument('ts')
    end

    klass.define_instance_method('encode') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('falsetok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('hexdec4') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('keyenc') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('lex') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('nibble') do |method|
      method.define_argument('c')
    end

    klass.define_instance_method('nulltok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('numenc') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('numtok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('objenc') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('objparse') do |method|
      method.define_argument('ts')
    end

    klass.define_instance_method('pairparse') do |method|
      method.define_argument('ts')
    end

    klass.define_instance_method('strenc') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('strtok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('subst') do |method|
      method.define_argument('u1')
      method.define_argument('u2')
    end

    klass.define_instance_method('surrogate?') do |method|
      method.define_argument('u')
    end

    klass.define_instance_method('textparse') do |method|
      method.define_argument('ts')
    end

    klass.define_instance_method('tok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('truetok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('ucharcopy') do |method|
      method.define_argument('t')
      method.define_argument('s')
      method.define_argument('i')
    end

    klass.define_instance_method('ucharenc') do |method|
      method.define_argument('a')
      method.define_argument('i')
      method.define_argument('u')
    end

    klass.define_instance_method('unquote') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('valenc') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('valparse') do |method|
      method.define_argument('ts')
    end
  end

  defs.define_constant('Sinatra::Application::STATUS_WITH_NO_ENTITY_BODY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Application::SYMBOL_TO_STATUS_CODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Application::Stream') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('defer') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('schedule') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('callback') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('closed?')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('front')
    end

    klass.define_instance_method('errback') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('scheduler')
      method.define_optional_argument('keep_open')
      method.define_block_argument('back')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Sinatra::Application::URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Base') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Sinatra::Templates', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Sinatra::Helpers', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rack::Utils', RubyLint.registry))

    klass.define_method('absolute_redirects')

    klass.define_method('absolute_redirects=') do |method|
      method.define_argument('val')
    end

    klass.define_method('absolute_redirects?')

    klass.define_method('add_charset')

    klass.define_method('add_charset=') do |method|
      method.define_argument('val')
    end

    klass.define_method('add_charset?')

    klass.define_method('add_filter') do |method|
      method.define_argument('type')
      method.define_optional_argument('path')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('after') do |method|
      method.define_optional_argument('path')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('app_file')

    klass.define_method('app_file=') do |method|
      method.define_argument('val')
    end

    klass.define_method('app_file?')

    klass.define_method('before') do |method|
      method.define_optional_argument('path')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('bind')

    klass.define_method('bind=') do |method|
      method.define_argument('val')
    end

    klass.define_method('bind?')

    klass.define_method('build') do |method|
      method.define_argument('app')
    end

    klass.define_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_method('caller_files')

    klass.define_method('caller_locations')

    klass.define_method('condition') do |method|
      method.define_optional_argument('name')
      method.define_block_argument('block')
    end

    klass.define_method('configure') do |method|
      method.define_rest_argument('envs')
      method.define_block_argument('block')
    end

    klass.define_method('default_encoding')

    klass.define_method('default_encoding=') do |method|
      method.define_argument('val')
    end

    klass.define_method('default_encoding?')

    klass.define_method('delete') do |method|
      method.define_argument('path')
      method.define_optional_argument('opts')
      method.define_block_argument('bk')
    end

    klass.define_method('development?')

    klass.define_method('disable') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_method('dump_errors')

    klass.define_method('dump_errors=') do |method|
      method.define_argument('val')
    end

    klass.define_method('dump_errors?')

    klass.define_method('empty_path_info')

    klass.define_method('empty_path_info=') do |method|
      method.define_argument('val')
    end

    klass.define_method('empty_path_info?')

    klass.define_method('enable') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_method('environment')

    klass.define_method('environment=') do |method|
      method.define_argument('val')
    end

    klass.define_method('environment?')

    klass.define_method('error') do |method|
      method.define_rest_argument('codes')
      method.define_block_argument('block')
    end

    klass.define_method('errors')

    klass.define_method('extensions')

    klass.define_method('filters')

    klass.define_method('force_encoding') do |method|
      method.define_argument('data')
      method.define_optional_argument('encoding')
    end

    klass.define_method('get') do |method|
      method.define_argument('path')
      method.define_optional_argument('opts')
      method.define_block_argument('block')
    end

    klass.define_method('head') do |method|
      method.define_argument('path')
      method.define_optional_argument('opts')
      method.define_block_argument('bk')
    end

    klass.define_method('helpers') do |method|
      method.define_rest_argument('extensions')
      method.define_block_argument('block')
    end

    klass.define_method('inline_templates=') do |method|
      method.define_optional_argument('file')
    end

    klass.define_method('layout') do |method|
      method.define_optional_argument('name')
      method.define_block_argument('block')
    end

    klass.define_method('link') do |method|
      method.define_argument('path')
      method.define_optional_argument('opts')
      method.define_block_argument('bk')
    end

    klass.define_method('lock')

    klass.define_method('lock=') do |method|
      method.define_argument('val')
    end

    klass.define_method('lock?')

    klass.define_method('logging')

    klass.define_method('logging=') do |method|
      method.define_argument('val')
    end

    klass.define_method('logging?')

    klass.define_method('method_override')

    klass.define_method('method_override=') do |method|
      method.define_argument('val')
    end

    klass.define_method('method_override?')

    klass.define_method('methodoverride=') do |method|
      method.define_argument('val')
    end

    klass.define_method('methodoverride?')

    klass.define_method('middleware')

    klass.define_method('mime_type') do |method|
      method.define_argument('type')
      method.define_optional_argument('value')
    end

    klass.define_method('mime_types') do |method|
      method.define_argument('type')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('bk')

      method.returns { |object| object.instance }
    end

    klass.define_method('new!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('not_found') do |method|
      method.define_block_argument('block')
    end

    klass.define_method('options') do |method|
      method.define_argument('path')
      method.define_optional_argument('opts')
      method.define_block_argument('bk')
    end

    klass.define_method('patch') do |method|
      method.define_argument('path')
      method.define_optional_argument('opts')
      method.define_block_argument('bk')
    end

    klass.define_method('port')

    klass.define_method('port=') do |method|
      method.define_argument('val')
    end

    klass.define_method('port?')

    klass.define_method('post') do |method|
      method.define_argument('path')
      method.define_optional_argument('opts')
      method.define_block_argument('bk')
    end

    klass.define_method('prefixed_redirects')

    klass.define_method('prefixed_redirects=') do |method|
      method.define_argument('val')
    end

    klass.define_method('prefixed_redirects?')

    klass.define_method('production?')

    klass.define_method('protection')

    klass.define_method('protection=') do |method|
      method.define_argument('val')
    end

    klass.define_method('protection?')

    klass.define_method('prototype')

    klass.define_method('public=') do |method|
      method.define_argument('value')
    end

    klass.define_method('public_dir')

    klass.define_method('public_dir=') do |method|
      method.define_argument('value')
    end

    klass.define_method('public_folder')

    klass.define_method('public_folder=') do |method|
      method.define_argument('val')
    end

    klass.define_method('public_folder?')

    klass.define_method('put') do |method|
      method.define_argument('path')
      method.define_optional_argument('opts')
      method.define_block_argument('bk')
    end

    klass.define_method('quit!') do |method|
      method.define_argument('server')
      method.define_argument('handler_name')
    end

    klass.define_method('raise_errors')

    klass.define_method('raise_errors=') do |method|
      method.define_argument('val')
    end

    klass.define_method('raise_errors?')

    klass.define_method('register') do |method|
      method.define_rest_argument('extensions')
      method.define_block_argument('block')
    end

    klass.define_method('reload_templates')

    klass.define_method('reload_templates=') do |method|
      method.define_argument('val')
    end

    klass.define_method('reload_templates?')

    klass.define_method('reset!')

    klass.define_method('root')

    klass.define_method('root=') do |method|
      method.define_argument('val')
    end

    klass.define_method('root?')

    klass.define_method('routes')

    klass.define_method('run')

    klass.define_method('run!') do |method|
      method.define_optional_argument('options')
    end

    klass.define_method('run=') do |method|
      method.define_argument('val')
    end

    klass.define_method('run?')

    klass.define_method('running')

    klass.define_method('running=') do |method|
      method.define_argument('val')
    end

    klass.define_method('running?')

    klass.define_method('server')

    klass.define_method('server=') do |method|
      method.define_argument('val')
    end

    klass.define_method('server?')

    klass.define_method('session_secret')

    klass.define_method('session_secret=') do |method|
      method.define_argument('val')
    end

    klass.define_method('session_secret?')

    klass.define_method('sessions')

    klass.define_method('sessions=') do |method|
      method.define_argument('val')
    end

    klass.define_method('sessions?')

    klass.define_method('set') do |method|
      method.define_argument('option')
      method.define_optional_argument('value')
      method.define_optional_argument('ignore_setter')
      method.define_block_argument('block')
    end

    klass.define_method('settings')

    klass.define_method('show_exceptions')

    klass.define_method('show_exceptions=') do |method|
      method.define_argument('val')
    end

    klass.define_method('show_exceptions?')

    klass.define_method('static')

    klass.define_method('static=') do |method|
      method.define_argument('val')
    end

    klass.define_method('static?')

    klass.define_method('static_cache_control')

    klass.define_method('static_cache_control=') do |method|
      method.define_argument('val')
    end

    klass.define_method('static_cache_control?')

    klass.define_method('template') do |method|
      method.define_argument('name')
      method.define_block_argument('block')
    end

    klass.define_method('templates')

    klass.define_method('test?')

    klass.define_method('threaded')

    klass.define_method('threaded=') do |method|
      method.define_argument('val')
    end

    klass.define_method('threaded?')

    klass.define_method('unlink') do |method|
      method.define_argument('path')
      method.define_optional_argument('opts')
      method.define_block_argument('bk')
    end

    klass.define_method('use') do |method|
      method.define_argument('middleware')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('use_code')

    klass.define_method('use_code=') do |method|
      method.define_argument('val')
    end

    klass.define_method('use_code?')

    klass.define_method('views')

    klass.define_method('views=') do |method|
      method.define_argument('val')
    end

    klass.define_method('views?')

    klass.define_method('x_cascade')

    klass.define_method('x_cascade=') do |method|
      method.define_argument('val')
    end

    klass.define_method('x_cascade?')

    klass.define_instance_method('app')

    klass.define_instance_method('app=')

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('call!') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('env')

    klass.define_instance_method('env=')

    klass.define_instance_method('forward')

    klass.define_instance_method('halt') do |method|
      method.define_rest_argument('response')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('app')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')

    klass.define_instance_method('params')

    klass.define_instance_method('params=')

    klass.define_instance_method('pass') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('request')

    klass.define_instance_method('request=')

    klass.define_instance_method('response')

    klass.define_instance_method('response=')

    klass.define_instance_method('settings')

    klass.define_instance_method('template_cache')
  end

  defs.define_constant('Sinatra::Base::ContentTyped') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('content_type')

    klass.define_instance_method('content_type=')
  end

  defs.define_constant('Sinatra::Base::Context') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('app')

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('context') do |method|
      method.define_argument('env')
      method.define_optional_argument('app')
    end

    klass.define_instance_method('for')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app_f')
      method.define_argument('app_r')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('recontext') do |method|
      method.define_argument('app')
    end
  end

  defs.define_constant('Sinatra::Base::DEFAULT_SEP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Base::ESCAPE_HTML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Base::ESCAPE_HTML_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Base::HTTP_STATUS_CODES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Base::HeaderHash') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_optional_argument('hash')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('k')
      method.define_argument('v')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('include?') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('hash')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('member?') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('merge!') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('replace') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('to_hash')
  end

  defs.define_constant('Sinatra::Base::KeySpaceConstrainedParams') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('limit')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('to_params_hash')
  end

  defs.define_constant('Sinatra::Base::Multipart') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('build_multipart') do |method|
      method.define_argument('params')
      method.define_optional_argument('first')
    end

    klass.define_method('parse_multipart') do |method|
      method.define_argument('env')
    end
  end

  defs.define_constant('Sinatra::Base::OkJson') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('abbrev') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('arrenc') do |method|
      method.define_argument('a')
    end

    klass.define_instance_method('arrparse') do |method|
      method.define_argument('ts')
    end

    klass.define_instance_method('decode') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('eat') do |method|
      method.define_argument('typ')
      method.define_argument('ts')
    end

    klass.define_instance_method('encode') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('falsetok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('hexdec4') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('keyenc') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('lex') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('nibble') do |method|
      method.define_argument('c')
    end

    klass.define_instance_method('nulltok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('numenc') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('numtok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('objenc') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('objparse') do |method|
      method.define_argument('ts')
    end

    klass.define_instance_method('pairparse') do |method|
      method.define_argument('ts')
    end

    klass.define_instance_method('strenc') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('strtok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('subst') do |method|
      method.define_argument('u1')
      method.define_argument('u2')
    end

    klass.define_instance_method('surrogate?') do |method|
      method.define_argument('u')
    end

    klass.define_instance_method('textparse') do |method|
      method.define_argument('ts')
    end

    klass.define_instance_method('tok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('truetok') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('ucharcopy') do |method|
      method.define_argument('t')
      method.define_argument('s')
      method.define_argument('i')
    end

    klass.define_instance_method('ucharenc') do |method|
      method.define_argument('a')
      method.define_argument('i')
      method.define_argument('u')
    end

    klass.define_instance_method('unquote') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('valenc') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('valparse') do |method|
      method.define_argument('ts')
    end
  end

  defs.define_constant('Sinatra::Base::STATUS_WITH_NO_ENTITY_BODY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Base::SYMBOL_TO_STATUS_CODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Base::Stream') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('defer') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('schedule') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('callback') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('closed?')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('front')
    end

    klass.define_instance_method('errback') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('scheduler')
      method.define_optional_argument('keep_open')
      method.define_block_argument('back')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Sinatra::Base::URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::CommonLogger') do |klass|
    klass.inherits(defs.constant_proxy('Rack::CommonLogger', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end
  end

  defs.define_constant('Sinatra::CommonLogger::FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Delegator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('delegate') do |method|
      method.define_rest_argument('methods')
    end

    klass.define_method('target')

    klass.define_method('target=')
  end

  defs.define_constant('Sinatra::ExtendedRack') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end
  end

  defs.define_constant('Sinatra::ExtendedRack::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Sinatra::ExtendedRack::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Sinatra::ExtendedRack::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Sinatra::ExtendedRack::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::ExtendedRack::SortedElement') do |klass|
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

  defs.define_constant('Sinatra::ExtendedRack::Tms') do |klass|
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

  defs.define_constant('Sinatra::Helpers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attachment') do |method|
      method.define_optional_argument('filename')
      method.define_optional_argument('disposition')
    end

    klass.define_instance_method('back')

    klass.define_instance_method('body') do |method|
      method.define_optional_argument('value')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cache_control') do |method|
      method.define_rest_argument('values')
    end

    klass.define_instance_method('client_error?')

    klass.define_instance_method('content_type') do |method|
      method.define_optional_argument('type')
      method.define_optional_argument('params')
    end

    klass.define_instance_method('error') do |method|
      method.define_argument('code')
      method.define_optional_argument('body')
    end

    klass.define_instance_method('etag') do |method|
      method.define_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('expires') do |method|
      method.define_argument('amount')
      method.define_rest_argument('values')
    end

    klass.define_instance_method('headers') do |method|
      method.define_optional_argument('hash')
    end

    klass.define_instance_method('informational?')

    klass.define_instance_method('last_modified') do |method|
      method.define_argument('time')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('mime_type') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('not_found') do |method|
      method.define_optional_argument('body')
    end

    klass.define_instance_method('not_found?')

    klass.define_instance_method('redirect') do |method|
      method.define_argument('uri')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('redirect?')

    klass.define_instance_method('send_file') do |method|
      method.define_argument('path')
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('server_error?')

    klass.define_instance_method('session')

    klass.define_instance_method('status') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('stream') do |method|
      method.define_optional_argument('keep_open')
    end

    klass.define_instance_method('success?')

    klass.define_instance_method('time_for') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('to') do |method|
      method.define_optional_argument('addr')
      method.define_optional_argument('absolute')
      method.define_optional_argument('add_script_name')
    end

    klass.define_instance_method('uri') do |method|
      method.define_optional_argument('addr')
      method.define_optional_argument('absolute')
      method.define_optional_argument('add_script_name')
    end

    klass.define_instance_method('url') do |method|
      method.define_optional_argument('addr')
      method.define_optional_argument('absolute')
      method.define_optional_argument('add_script_name')
    end
  end

  defs.define_constant('Sinatra::Helpers::Stream') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('defer') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('schedule') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('callback') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('closed?')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('front')
    end

    klass.define_instance_method('errback') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('scheduler')
      method.define_optional_argument('keep_open')
      method.define_block_argument('back')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Sinatra::NotFound') do |klass|
    klass.inherits(defs.constant_proxy('NameError', RubyLint.registry))

    klass.define_instance_method('http_status')
  end

  defs.define_constant('Sinatra::Request') do |klass|
    klass.inherits(defs.constant_proxy('Rack::Request', RubyLint.registry))

    klass.define_instance_method('accept')

    klass.define_instance_method('accept?') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('forwarded?')

    klass.define_instance_method('idempotent?')

    klass.define_instance_method('link?')

    klass.define_instance_method('preferred_type') do |method|
      method.define_rest_argument('types')
    end

    klass.define_instance_method('safe?')

    klass.define_instance_method('secure?')

    klass.define_instance_method('unlink?')
  end

  defs.define_constant('Sinatra::Request::AcceptEntry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('entry')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('params')

    klass.define_instance_method('params=')

    klass.define_instance_method('priority')

    klass.define_instance_method('respond_to?') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('to_s') do |method|
      method.define_optional_argument('full')
    end

    klass.define_instance_method('to_str')
  end

  defs.define_constant('Sinatra::Request::DEFAULT_PORTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Request::FORM_DATA_MEDIA_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Request::HEADER_PARAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Request::HEADER_VALUE_WITH_PARAMS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Request::PARSEABLE_DATA_MEDIA_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Response') do |klass|
    klass.inherits(defs.constant_proxy('Rack::Response', RubyLint.registry))

    klass.define_instance_method('body=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('finish')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Sinatra::Response::Helpers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('bad_request?')

    klass.define_instance_method('client_error?')

    klass.define_instance_method('content_length')

    klass.define_instance_method('content_type')

    klass.define_instance_method('forbidden?')

    klass.define_instance_method('headers')

    klass.define_instance_method('include?') do |method|
      method.define_argument('header')
    end

    klass.define_instance_method('informational?')

    klass.define_instance_method('invalid?')

    klass.define_instance_method('location')

    klass.define_instance_method('method_not_allowed?')

    klass.define_instance_method('not_found?')

    klass.define_instance_method('ok?')

    klass.define_instance_method('original_headers')

    klass.define_instance_method('redirect?')

    klass.define_instance_method('redirection?')

    klass.define_instance_method('server_error?')

    klass.define_instance_method('successful?')

    klass.define_instance_method('unprocessable?')
  end

  defs.define_constant('Sinatra::ShowExceptions') do |klass|
    klass.inherits(defs.constant_proxy('Rack::ShowExceptions', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Sinatra::ShowExceptions::CONTEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::ShowExceptions::TEMPLATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Templates') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('builder') do |method|
      method.define_optional_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('coffee') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('creole') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('erb') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('erubis') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('find_template') do |method|
      method.define_argument('views')
      method.define_argument('name')
      method.define_argument('engine')
    end

    klass.define_instance_method('haml') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('less') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('liquid') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('markaby') do |method|
      method.define_optional_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('markdown') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('nokogiri') do |method|
      method.define_optional_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rabl') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('radius') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('rdoc') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('sass') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('scss') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('slim') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('stylus') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('textile') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('wlang') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('yajl') do |method|
      method.define_argument('template')
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
    end
  end

  defs.define_constant('Sinatra::Templates::ContentTyped') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('content_type')

    klass.define_instance_method('content_type=')
  end

  defs.define_constant('Sinatra::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sinatra::Wrapper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('helpers')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('stack')
      method.define_argument('instance')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('settings')
  end
end
