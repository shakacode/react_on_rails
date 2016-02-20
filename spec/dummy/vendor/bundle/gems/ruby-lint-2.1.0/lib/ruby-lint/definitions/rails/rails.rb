# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('Rails') do |defs|
  defs.define_constant('Rails') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('application')

    klass.define_method('application=')

    klass.define_method('backtrace_cleaner')

    klass.define_method('cache')

    klass.define_method('cache=')

    klass.define_method('configuration')

    klass.define_method('env')

    klass.define_method('env=') do |method|
      method.define_argument('environment')
    end

    klass.define_method('groups') do |method|
      method.define_rest_argument('groups')
    end

    klass.define_method('initialize!')

    klass.define_method('initialized?')

    klass.define_method('logger')

    klass.define_method('logger=')

    klass.define_method('public_path')

    klass.define_method('root')

    klass.define_method('version')
  end

  defs.define_constant('Rails::Application') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Engine', RubyLint.registry))

    klass.define_method('inherited') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('add_lib_to_load_path!')

    klass.define_instance_method('allow_concurrency?')

    klass.define_instance_method('assets')

    klass.define_instance_method('assets=')

    klass.define_instance_method('build_middleware_stack')

    klass.define_instance_method('build_original_fullpath') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('config')

    klass.define_instance_method('default_middleware_stack')

    klass.define_instance_method('default_url_options') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('default_url_options=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('env_config')

    klass.define_instance_method('helpers_paths')

    klass.define_instance_method('initialize')

    klass.define_instance_method('initialize!') do |method|
      method.define_optional_argument('group')
    end

    klass.define_instance_method('initialized?')

    klass.define_instance_method('initializers')

    klass.define_instance_method('key_generator')

    klass.define_instance_method('load_rack_cache')

    klass.define_instance_method('ordered_railties')

    klass.define_instance_method('railties_initializers') do |method|
      method.define_argument('current')
    end

    klass.define_instance_method('reload_dependencies?')

    klass.define_instance_method('reload_routes!')

    klass.define_instance_method('reloaders')

    klass.define_instance_method('require_environment!')

    klass.define_instance_method('routes_reloader')

    klass.define_instance_method('run_console_blocks') do |method|
      method.define_argument('app')
    end

    klass.define_instance_method('run_generators_blocks') do |method|
      method.define_argument('app')
    end

    klass.define_instance_method('run_runner_blocks') do |method|
      method.define_argument('app')
    end

    klass.define_instance_method('run_tasks_blocks') do |method|
      method.define_argument('app')
    end

    klass.define_instance_method('sandbox')

    klass.define_instance_method('sandbox=')

    klass.define_instance_method('sandbox?')

    klass.define_instance_method('show_exceptions_app')

    klass.define_instance_method('to_app')

    klass.define_instance_method('watchable_args')
  end

  defs.define_constant('Rails::Application::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Application::Bootstrap') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Application::Bootstrap::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initializer') do |method|
      method.define_argument('name')
      method.define_optional_argument('opts')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('initializers')

    klass.define_instance_method('initializers_chain')

    klass.define_instance_method('initializers_for') do |method|
      method.define_argument('binding')
    end
  end

  defs.define_constant('Rails::Application::Bootstrap::Collection') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('initializer')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tsort_each_node')
  end

  defs.define_constant('Rails::Application::Bootstrap::Initializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after')

    klass.define_instance_method('before')

    klass.define_instance_method('belongs_to?') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('bind') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Rails::Application::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initializer') do |method|
      method.define_argument('name')
      method.define_optional_argument('opts')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('initializers')

    klass.define_instance_method('initializers_chain')

    klass.define_instance_method('initializers_for') do |method|
      method.define_argument('binding')
    end
  end

  defs.define_constant('Rails::Application::Collection') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('initializer')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tsort_each_node')
  end

  defs.define_constant('Rails::Application::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Application::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Engine::Configuration', RubyLint.registry))

    klass.define_instance_method('allow_concurrency')

    klass.define_instance_method('allow_concurrency=')

    klass.define_instance_method('asset_host')

    klass.define_instance_method('asset_host=')

    klass.define_instance_method('assets=')

    klass.define_instance_method('autoflush_log')

    klass.define_instance_method('autoflush_log=')

    klass.define_instance_method('beginning_of_week')

    klass.define_instance_method('beginning_of_week=')

    klass.define_instance_method('cache_classes')

    klass.define_instance_method('cache_classes=')

    klass.define_instance_method('cache_store')

    klass.define_instance_method('cache_store=')

    klass.define_instance_method('colorize_logging')

    klass.define_instance_method('colorize_logging=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('consider_all_requests_local')

    klass.define_instance_method('consider_all_requests_local=')

    klass.define_instance_method('console')

    klass.define_instance_method('console=')

    klass.define_instance_method('database_configuration')

    klass.define_instance_method('eager_load')

    klass.define_instance_method('eager_load=')

    klass.define_instance_method('encoding')

    klass.define_instance_method('encoding=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('exceptions_app')

    klass.define_instance_method('exceptions_app=')

    klass.define_instance_method('file_watcher')

    klass.define_instance_method('file_watcher=')

    klass.define_instance_method('filter_parameters')

    klass.define_instance_method('filter_parameters=')

    klass.define_instance_method('filter_redirect')

    klass.define_instance_method('filter_redirect=')

    klass.define_instance_method('force_ssl')

    klass.define_instance_method('force_ssl=')

    klass.define_instance_method('helpers_paths')

    klass.define_instance_method('helpers_paths=')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('log_formatter')

    klass.define_instance_method('log_formatter=')

    klass.define_instance_method('log_level')

    klass.define_instance_method('log_level=')

    klass.define_instance_method('log_tags')

    klass.define_instance_method('log_tags=')

    klass.define_instance_method('logger')

    klass.define_instance_method('logger=')

    klass.define_instance_method('paths')

    klass.define_instance_method('railties_order')

    klass.define_instance_method('railties_order=')

    klass.define_instance_method('relative_url_root')

    klass.define_instance_method('relative_url_root=')

    klass.define_instance_method('reload_classes_only_on_change')

    klass.define_instance_method('reload_classes_only_on_change=')

    klass.define_instance_method('secret_key_base')

    klass.define_instance_method('secret_key_base=')

    klass.define_instance_method('secret_token')

    klass.define_instance_method('secret_token=')

    klass.define_instance_method('serve_static_assets')

    klass.define_instance_method('serve_static_assets=')

    klass.define_instance_method('session_options')

    klass.define_instance_method('session_options=')

    klass.define_instance_method('session_store') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('ssl_options')

    klass.define_instance_method('ssl_options=')

    klass.define_instance_method('static_cache_control')

    klass.define_instance_method('static_cache_control=')

    klass.define_instance_method('threadsafe!')

    klass.define_instance_method('time_zone')

    klass.define_instance_method('time_zone=')

    klass.define_instance_method('whiny_nils=') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('Rails::Application::Finisher') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Application::Finisher::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initializer') do |method|
      method.define_argument('name')
      method.define_optional_argument('opts')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('initializers')

    klass.define_instance_method('initializers_chain')

    klass.define_instance_method('initializers_for') do |method|
      method.define_argument('binding')
    end
  end

  defs.define_constant('Rails::Application::Finisher::Collection') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('initializer')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tsort_each_node')
  end

  defs.define_constant('Rails::Application::Finisher::Initializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after')

    klass.define_instance_method('before')

    klass.define_instance_method('belongs_to?') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('bind') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Rails::Application::Initializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after')

    klass.define_instance_method('before')

    klass.define_instance_method('belongs_to?') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('bind') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Rails::Application::Railties') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('engines')

    klass.define_instance_method('-') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('_all')

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('engines') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('engines_with_deprecation') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('engines_without_deprecation') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Rails::Application::RoutesReloader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('execute') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute_if_updated') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('paths')

    klass.define_instance_method('reload!')

    klass.define_instance_method('route_sets')

    klass.define_instance_method('updated?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Rails::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Configuration::Generators') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('aliases')

    klass.define_instance_method('aliases=')

    klass.define_instance_method('colorize_logging')

    klass.define_instance_method('colorize_logging=')

    klass.define_instance_method('fallbacks')

    klass.define_instance_method('fallbacks=')

    klass.define_instance_method('hidden_namespaces')

    klass.define_instance_method('hide_namespace') do |method|
      method.define_argument('namespace')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('templates')

    klass.define_instance_method('templates=')
  end

  defs.define_constant('Rails::Configuration::MiddlewareStackProxy') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('insert') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('insert_after') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('insert_before') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('merge_into') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('swap') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('use') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Rails::DeprecatedConstant') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Deprecation::DeprecatedConstantProxy', RubyLint.registry))

    klass.define_method('deprecate') do |method|
      method.define_argument('old')
      method.define_argument('current')
    end
  end

  defs.define_constant('Rails::Engine') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie', RubyLint.registry))

    klass.define_method('called_from')

    klass.define_method('called_from=')

    klass.define_method('eager_load!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('endpoint') do |method|
      method.define_optional_argument('endpoint')
    end

    klass.define_method('engine_name') do |method|
      method.define_optional_argument('name')
    end

    klass.define_method('find') do |method|
      method.define_argument('path')
    end

    klass.define_method('inherited') do |method|
      method.define_argument('base')
    end

    klass.define_method('isolate_namespace') do |method|
      method.define_argument('mod')
    end

    klass.define_method('isolated')

    klass.define_method('isolated=')

    klass.define_method('isolated?')

    klass.define_instance_method('_all_autoload_once_paths')

    klass.define_instance_method('_all_autoload_paths')

    klass.define_instance_method('_all_load_paths')

    klass.define_instance_method('app')

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('config')

    klass.define_instance_method('default_middleware_stack')

    klass.define_instance_method('eager_load!')

    klass.define_instance_method('endpoint')

    klass.define_instance_method('engine_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('env_config')

    klass.define_instance_method('find_root_with_flag') do |method|
      method.define_argument('flag')
      method.define_optional_argument('default')
    end

    klass.define_instance_method('has_migrations?')

    klass.define_instance_method('helpers')

    klass.define_instance_method('helpers_paths')

    klass.define_instance_method('initialize')

    klass.define_instance_method('isolated?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('load_console') do |method|
      method.define_optional_argument('app')
    end

    klass.define_instance_method('load_generators') do |method|
      method.define_optional_argument('app')
    end

    klass.define_instance_method('load_runner') do |method|
      method.define_optional_argument('app')
    end

    klass.define_instance_method('load_seed')

    klass.define_instance_method('load_tasks') do |method|
      method.define_optional_argument('app')
    end

    klass.define_instance_method('middleware') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('paths') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('railties')

    klass.define_instance_method('root') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('routes')

    klass.define_instance_method('routes?')

    klass.define_instance_method('run_tasks_blocks') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('Rails::Engine::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Engine::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initializer') do |method|
      method.define_argument('name')
      method.define_optional_argument('opts')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('initializers')

    klass.define_instance_method('initializers_chain')

    klass.define_instance_method('initializers_for') do |method|
      method.define_argument('binding')
    end
  end

  defs.define_constant('Rails::Engine::Collection') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('initializer')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tsort_each_node')
  end

  defs.define_constant('Rails::Engine::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Engine::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configuration', RubyLint.registry))

    klass.define_instance_method('autoload_once_paths')

    klass.define_instance_method('autoload_once_paths=')

    klass.define_instance_method('autoload_paths')

    klass.define_instance_method('autoload_paths=')

    klass.define_instance_method('eager_load_paths')

    klass.define_instance_method('eager_load_paths=')

    klass.define_instance_method('generators')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('root')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('middleware')

    klass.define_instance_method('middleware=')

    klass.define_instance_method('paths')

    klass.define_instance_method('root')

    klass.define_instance_method('root=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Rails::Engine::Initializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after')

    klass.define_instance_method('before')

    klass.define_instance_method('belongs_to?') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('bind') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Rails::Engine::Railties') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('engines')

    klass.define_instance_method('-') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('_all')

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('engines') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('engines_with_deprecation') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('engines_without_deprecation') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Rails::Engine::Railties::Enumerator') do |klass|
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

  defs.define_constant('Rails::Engine::Railties::SortedElement') do |klass|
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

  defs.define_constant('Rails::Info') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('framework_version') do |method|
      method.define_argument('framework')
    end

    klass.define_method('frameworks')

    klass.define_method('inspect')

    klass.define_method('properties')

    klass.define_method('properties=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('property') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
    end

    klass.define_method('to_html')

    klass.define_method('to_s')

    klass.define_instance_method('properties')

    klass.define_instance_method('properties=') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('Rails::InfoController') do |klass|
    klass.inherits(defs.constant_proxy('ActionController::Base', RubyLint.registry))

    klass.define_method('_helpers')

    klass.define_method('_layout')

    klass.define_method('_layout_conditions')

    klass.define_method('_process_action_callbacks')

    klass.define_method('_view_paths')

    klass.define_method('middleware_stack')

    klass.define_instance_method('_layout_from_proc')

    klass.define_instance_method('index')

    klass.define_instance_method('local_request?')

    klass.define_instance_method('properties')

    klass.define_instance_method('require_local!')

    klass.define_instance_method('routes')
  end

  defs.define_constant('Rails::InfoController::ACTION_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::All') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_update_filter') do |method|
      method.define_argument('filter_options')
      method.define_argument('new_options')
    end

    klass.define_instance_method('apply') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('chain=')

    klass.define_instance_method('clone') do |method|
      method.define_argument('chain')
      method.define_argument('klass')
    end

    klass.define_instance_method('deprecate_per_key_option') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('duplicates?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('chain')
      method.define_argument('filter')
      method.define_argument('kind')
      method.define_argument('options')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('kind=')

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('_kind')
      method.define_argument('_filter')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_id')

    klass.define_instance_method('normalize_options!') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('raw_filter')

    klass.define_instance_method('raw_filter=')

    klass.define_instance_method('recompile!') do |method|
      method.define_argument('_options')
    end
  end

  defs.define_constant('Rails::InfoController::CallbackChain') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('compile')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('Rails::InfoController::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_set_wrapper_options') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('inherited') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('wrap_parameters') do |method|
      method.define_argument('name_or_model_or_options')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Rails::InfoController::Collector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::Collector', RubyLint.registry))

    klass.define_instance_method('all') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('any') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('custom') do |method|
      method.define_argument('mime_type')
      method.define_block_argument('block')
    end

    klass.define_instance_method('format')

    klass.define_instance_method('format=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mimes')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('negotiate_format') do |method|
      method.define_argument('request')
    end

    klass.define_instance_method('order')

    klass.define_instance_method('order=')

    klass.define_instance_method('response')
  end

  defs.define_constant('Rails::InfoController::ConfigMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache_store')

    klass.define_instance_method('cache_store=') do |method|
      method.define_argument('store')
    end
  end

  defs.define_constant('Rails::InfoController::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::InheritableOptions', RubyLint.registry))

    klass.define_method('compile_methods!') do |method|
      method.define_argument('keys')
    end

    klass.define_instance_method('compile_methods!')
  end

  defs.define_constant('Rails::InfoController::DEFAULT_PROTECTED_INSTANCE_VARIABLES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::DEFAULT_SEND_FILE_DISPOSITION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::DEFAULT_SEND_FILE_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::EXCLUDE_PARAMETERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::FileBody') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_path')
  end

  defs.define_constant('Rails::InfoController::Fragments') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('expire_fragment') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('fragment_cache_key') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('fragment_exist?') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('instrument_fragment_cache') do |method|
      method.define_argument('name')
      method.define_argument('key')
    end

    klass.define_instance_method('read_fragment') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('write_fragment') do |method|
      method.define_argument('key')
      method.define_argument('content')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Rails::InfoController::INSTANCE_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::MODULES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::MODULE_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from_hash') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('include')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('format')
      method.define_argument('include')
      method.define_argument('exclude')
      method.define_argument('klass')
      method.define_argument('model')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lock')

    klass.define_instance_method('locked?')

    klass.define_instance_method('model')

    klass.define_instance_method('name')

    klass.define_instance_method('synchronize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('try_lock')

    klass.define_instance_method('unlock')
  end

  defs.define_constant('Rails::InfoController::ProtectionMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::REDIRECT_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::RENDERERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::InfoController::URL_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Initializable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('initializers')

    klass.define_instance_method('run_initializers') do |method|
      method.define_optional_argument('group')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Rails::Initializable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initializer') do |method|
      method.define_argument('name')
      method.define_optional_argument('opts')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('initializers')

    klass.define_instance_method('initializers_chain')

    klass.define_instance_method('initializers_for') do |method|
      method.define_argument('binding')
    end
  end

  defs.define_constant('Rails::Initializable::Initializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after')

    klass.define_instance_method('before')

    klass.define_instance_method('belongs_to?') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('bind') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Rails::Paths') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Paths::Path') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('autoload!')

    klass.define_instance_method('autoload?')

    klass.define_instance_method('autoload_once!')

    klass.define_instance_method('autoload_once?')

    klass.define_instance_method('children')

    klass.define_instance_method('concat') do |method|
      method.define_argument('paths')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('eager_load!')

    klass.define_instance_method('eager_load?')

    klass.define_instance_method('existent')

    klass.define_instance_method('existent_directories')

    klass.define_instance_method('expanded')

    klass.define_instance_method('first')

    klass.define_instance_method('glob')

    klass.define_instance_method('glob=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('root')
      method.define_argument('current')
      method.define_argument('paths')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('last')

    klass.define_instance_method('load_path!')

    klass.define_instance_method('load_path?')

    klass.define_instance_method('push') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('skip_autoload!')

    klass.define_instance_method('skip_autoload_once!')

    klass.define_instance_method('skip_eager_load!')

    klass.define_instance_method('skip_load_path!')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_ary')

    klass.define_instance_method('unshift') do |method|
      method.define_argument('path')
    end
  end

  defs.define_constant('Rails::Paths::Path::Enumerator') do |klass|
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

  defs.define_constant('Rails::Paths::Path::SortedElement') do |klass|
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

  defs.define_constant('Rails::Paths::Root') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('path')
      method.define_argument('value')
    end

    klass.define_instance_method('add') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('all_paths')

    klass.define_instance_method('autoload_once')

    klass.define_instance_method('autoload_paths')

    klass.define_instance_method('eager_load')

    klass.define_instance_method('filter_by') do |method|
      method.define_argument('constraint')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('keys')

    klass.define_instance_method('load_paths')

    klass.define_instance_method('path')

    klass.define_instance_method('path=')

    klass.define_instance_method('values')

    klass.define_instance_method('values_at') do |method|
      method.define_rest_argument('list')
    end
  end

  defs.define_constant('Rails::Rack') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Rack::Debugger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Rails::Rack::LogTailer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_optional_argument('log')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('tail!')
  end

  defs.define_constant('Rails::Rack::Logger') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::LogSubscriber', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('call_app') do |method|
      method.define_argument('request')
      method.define_argument('env')
    end

    klass.define_instance_method('compute_tags') do |method|
      method.define_argument('request')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')
      method.define_optional_argument('taggers')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('started_request_message') do |method|
      method.define_argument('request')
    end
  end

  defs.define_constant('Rails::Rack::Logger::BLACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Rack::Logger::BLUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Rack::Logger::BOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Rack::Logger::CLEAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Rack::Logger::CYAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Rack::Logger::GREEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Rack::Logger::MAGENTA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Rack::Logger::RED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Rack::Logger::WHITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Rack::Logger::YELLOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Railtie') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rails::Initializable', RubyLint.registry))

    klass.define_method('abstract_railtie?')

    klass.define_method('console') do |method|
      method.define_block_argument('blk')
    end

    klass.define_method('generate_railtie_name') do |method|
      method.define_argument('class_or_module')
    end

    klass.define_method('generators') do |method|
      method.define_block_argument('blk')
    end

    klass.define_method('inherited') do |method|
      method.define_argument('base')
    end

    klass.define_method('railtie_name') do |method|
      method.define_optional_argument('name')
    end

    klass.define_method('rake_tasks') do |method|
      method.define_block_argument('blk')
    end

    klass.define_method('runner') do |method|
      method.define_block_argument('blk')
    end

    klass.define_method('subclasses')

    klass.define_instance_method('config')

    klass.define_instance_method('railtie_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('railtie_namespace')

    klass.define_instance_method('run_console_blocks') do |method|
      method.define_argument('app')
    end

    klass.define_instance_method('run_generators_blocks') do |method|
      method.define_argument('app')
    end

    klass.define_instance_method('run_runner_blocks') do |method|
      method.define_argument('app')
    end

    klass.define_instance_method('run_tasks_blocks') do |method|
      method.define_argument('app')
    end
  end

  defs.define_constant('Rails::Railtie::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::Railtie::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initializer') do |method|
      method.define_argument('name')
      method.define_optional_argument('opts')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('initializers')

    klass.define_instance_method('initializers_chain')

    klass.define_instance_method('initializers_for') do |method|
      method.define_argument('binding')
    end
  end

  defs.define_constant('Rails::Railtie::Collection') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('initializer')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tsort_each_node')
  end

  defs.define_constant('Rails::Railtie::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('eager_load_namespaces')

    klass.define_instance_method('after_initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('app_generators')

    klass.define_instance_method('app_middleware')

    klass.define_instance_method('before_configuration') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_eager_load') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('eager_load_namespaces')

    klass.define_instance_method('initialize')

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('to_prepare') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('to_prepare_blocks')

    klass.define_instance_method('watchable_dirs')

    klass.define_instance_method('watchable_files')
  end

  defs.define_constant('Rails::Railtie::Initializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after')

    klass.define_instance_method('before')

    klass.define_instance_method('belongs_to?') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('bind') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Rails::TestUnitRailtie') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configurable', RubyLint.registry))

  end

  defs.define_constant('Rails::TestUnitRailtie::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::TestUnitRailtie::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('config') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('configure') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('inherited') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('instance')

    klass.define_instance_method('method_missing') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Rails::TestUnitRailtie::Collection') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('initializer')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tsort_each_node')
  end

  defs.define_constant('Rails::TestUnitRailtie::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::TestUnitRailtie::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('eager_load_namespaces')

    klass.define_instance_method('after_initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('app_generators')

    klass.define_instance_method('app_middleware')

    klass.define_instance_method('before_configuration') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_eager_load') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('eager_load_namespaces')

    klass.define_instance_method('initialize')

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('to_prepare') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('to_prepare_blocks')

    klass.define_instance_method('watchable_dirs')

    klass.define_instance_method('watchable_files')
  end

  defs.define_constant('Rails::TestUnitRailtie::Initializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after')

    klass.define_instance_method('before')

    klass.define_instance_method('belongs_to?') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('bind') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Rails::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::VERSION::MAJOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::VERSION::MINOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::VERSION::PRE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::VERSION::STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::VERSION::TINY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController') do |klass|
    klass.inherits(defs.constant_proxy('ActionController::Base', RubyLint.registry))

    klass.define_method('_helpers')

    klass.define_method('_layout')

    klass.define_method('_layout_conditions')

    klass.define_method('_view_paths')

    klass.define_method('middleware_stack')

    klass.define_instance_method('index')
  end

  defs.define_constant('Rails::WelcomeController::ACTION_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::All') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_update_filter') do |method|
      method.define_argument('filter_options')
      method.define_argument('new_options')
    end

    klass.define_instance_method('apply') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('chain=')

    klass.define_instance_method('clone') do |method|
      method.define_argument('chain')
      method.define_argument('klass')
    end

    klass.define_instance_method('deprecate_per_key_option') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('duplicates?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('chain')
      method.define_argument('filter')
      method.define_argument('kind')
      method.define_argument('options')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('kind=')

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('_kind')
      method.define_argument('_filter')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_id')

    klass.define_instance_method('normalize_options!') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('raw_filter')

    klass.define_instance_method('raw_filter=')

    klass.define_instance_method('recompile!') do |method|
      method.define_argument('_options')
    end
  end

  defs.define_constant('Rails::WelcomeController::CallbackChain') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('compile')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('Rails::WelcomeController::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_set_wrapper_options') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('inherited') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('wrap_parameters') do |method|
      method.define_argument('name_or_model_or_options')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Rails::WelcomeController::Collector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::Collector', RubyLint.registry))

    klass.define_instance_method('all') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('any') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('custom') do |method|
      method.define_argument('mime_type')
      method.define_block_argument('block')
    end

    klass.define_instance_method('format')

    klass.define_instance_method('format=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mimes')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('negotiate_format') do |method|
      method.define_argument('request')
    end

    klass.define_instance_method('order')

    klass.define_instance_method('order=')

    klass.define_instance_method('response')
  end

  defs.define_constant('Rails::WelcomeController::ConfigMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache_store')

    klass.define_instance_method('cache_store=') do |method|
      method.define_argument('store')
    end
  end

  defs.define_constant('Rails::WelcomeController::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::InheritableOptions', RubyLint.registry))

    klass.define_method('compile_methods!') do |method|
      method.define_argument('keys')
    end

    klass.define_instance_method('compile_methods!')
  end

  defs.define_constant('Rails::WelcomeController::DEFAULT_PROTECTED_INSTANCE_VARIABLES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::DEFAULT_SEND_FILE_DISPOSITION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::DEFAULT_SEND_FILE_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::EXCLUDE_PARAMETERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::FileBody') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_path')
  end

  defs.define_constant('Rails::WelcomeController::Fragments') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('expire_fragment') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('fragment_cache_key') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('fragment_exist?') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('instrument_fragment_cache') do |method|
      method.define_argument('name')
      method.define_argument('key')
    end

    klass.define_instance_method('read_fragment') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('write_fragment') do |method|
      method.define_argument('key')
      method.define_argument('content')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Rails::WelcomeController::INSTANCE_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::MODULES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::MODULE_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from_hash') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('include')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('format')
      method.define_argument('include')
      method.define_argument('exclude')
      method.define_argument('klass')
      method.define_argument('model')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lock')

    klass.define_instance_method('locked?')

    klass.define_instance_method('model')

    klass.define_instance_method('name')

    klass.define_instance_method('synchronize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('try_lock')

    klass.define_instance_method('unlock')
  end

  defs.define_constant('Rails::WelcomeController::ProtectionMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::REDIRECT_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::RENDERERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Rails::WelcomeController::URL_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
