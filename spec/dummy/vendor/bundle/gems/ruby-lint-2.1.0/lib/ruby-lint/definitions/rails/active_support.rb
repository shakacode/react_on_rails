# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('ActiveSupport') do |defs|
  defs.define_constant('ActiveSupport') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('encode_big_decimal_as_string') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('encode_big_decimal_as_string=') do |method|
      method.define_argument('arg')
    end

    klass.define_method('escape_html_entities_in_json') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('escape_html_entities_in_json=') do |method|
      method.define_argument('arg')
    end

    klass.define_method('execute_hook') do |method|
      method.define_argument('base')
      method.define_argument('options')
      method.define_argument('block')
    end

    klass.define_method('on_load') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('parse_json_times')

    klass.define_method('parse_json_times=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('run_load_hooks') do |method|
      method.define_argument('name')
      method.define_optional_argument('base')
    end

    klass.define_method('use_standard_json_time_format') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('use_standard_json_time_format=') do |method|
      method.define_argument('arg')
    end

    klass.define_method('version')

    klass.define_instance_method('parse_json_times')

    klass.define_instance_method('parse_json_times=') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('ActiveSupport::Autoload') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('extended') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('autoload') do |method|
      method.define_argument('const_name')
      method.define_optional_argument('path')
    end

    klass.define_instance_method('autoload_at') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('autoload_under') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('autoloads')

    klass.define_instance_method('eager_autoload')

    klass.define_instance_method('eager_load!')
  end

  defs.define_constant('ActiveSupport::BacktraceCleaner') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_filter') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('add_silencer') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('clean') do |method|
      method.define_argument('backtrace')
      method.define_optional_argument('kind')
    end

    klass.define_instance_method('filter') do |method|
      method.define_argument('backtrace')
      method.define_optional_argument('kind')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('remove_filters!')

    klass.define_instance_method('remove_silencers!')
  end

  defs.define_constant('ActiveSupport::BasicObject') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::ProxyObject', RubyLint.registry))

    klass.define_method('inherited') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('ActiveSupport::Benchmarkable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('benchmark') do |method|
      method.define_optional_argument('message')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('silence')
  end

  defs.define_constant('ActiveSupport::Cache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('expand_cache_key') do |method|
      method.define_argument('key')
      method.define_optional_argument('namespace')
    end

    klass.define_method('lookup_store') do |method|
      method.define_rest_argument('store_option')
    end
  end

  defs.define_constant('ActiveSupport::Cache::Entry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('dup_value!')

    klass.define_instance_method('expired?')

    klass.define_instance_method('expires_at')

    klass.define_instance_method('expires_at=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('size')

    klass.define_instance_method('value')
  end

  defs.define_constant('ActiveSupport::Cache::Entry::DEFAULT_COMPRESS_LIMIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Cache::FileStore') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Cache::Store', RubyLint.registry))

    klass.define_instance_method('cache_path')

    klass.define_instance_method('cleanup') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('clear') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('decrement') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('delete_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('delete_matched') do |method|
      method.define_argument('matcher')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('increment') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('cache_path')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('read_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('write_entry') do |method|
      method.define_argument('key')
      method.define_argument('entry')
      method.define_argument('options')
    end
  end

  defs.define_constant('ActiveSupport::Cache::FileStore::DIR_FORMATTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Cache::FileStore::EXCLUDED_DIRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Cache::FileStore::FILENAME_MAX_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Cache::MemCacheStore') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Cache::Store', RubyLint.registry))

    klass.define_method('build_mem_cache') do |method|
      method.define_rest_argument('addresses')
    end

    klass.define_instance_method('clear') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('decrement') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('delete_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('increment') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('addresses')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('read_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('read_multi') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('stats')

    klass.define_instance_method('write_entry') do |method|
      method.define_argument('key')
      method.define_argument('entry')
      method.define_argument('options')
    end
  end

  defs.define_constant('ActiveSupport::Cache::MemCacheStore::ESCAPE_KEY_CHARS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Cache::MemCacheStore::LocalCacheWithRaw') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('read_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('write_entry') do |method|
      method.define_argument('key')
      method.define_argument('entry')
      method.define_argument('options')
    end
  end

  defs.define_constant('ActiveSupport::Cache::MemoryStore') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Cache::Store', RubyLint.registry))

    klass.define_instance_method('cached_size') do |method|
      method.define_argument('key')
      method.define_argument('entry')
    end

    klass.define_instance_method('cleanup') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('clear') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('decrement') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('delete_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('delete_matched') do |method|
      method.define_argument('matcher')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('increment') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('prune') do |method|
      method.define_argument('target_size')
      method.define_optional_argument('max_time')
    end

    klass.define_instance_method('pruning?')

    klass.define_instance_method('read_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('synchronize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('write_entry') do |method|
      method.define_argument('key')
      method.define_argument('entry')
      method.define_argument('options')
    end
  end

  defs.define_constant('ActiveSupport::Cache::MemoryStore::PER_ENTRY_OVERHEAD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Cache::NullStore') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Cache::Store', RubyLint.registry))

    klass.define_instance_method('cleanup') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('clear') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('decrement') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('delete_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('delete_matched') do |method|
      method.define_argument('matcher')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('increment') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('read_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('write_entry') do |method|
      method.define_argument('key')
      method.define_argument('entry')
      method.define_argument('options')
    end
  end

  defs.define_constant('ActiveSupport::Cache::Store') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('instrument')

    klass.define_method('instrument=') do |method|
      method.define_argument('boolean')
    end

    klass.define_method('logger')

    klass.define_method('logger=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('cleanup') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('clear') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('decrement') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('delete_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('delete_matched') do |method|
      method.define_argument('matcher')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('exist?') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('fetch') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('increment') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key_matcher') do |method|
      method.define_argument('pattern')
      method.define_argument('options')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('logger=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('mute')

    klass.define_instance_method('options')

    klass.define_instance_method('read') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('read_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('read_multi') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('silence')

    klass.define_instance_method('silence!')

    klass.define_instance_method('silence?')

    klass.define_instance_method('write') do |method|
      method.define_argument('name')
      method.define_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('write_entry') do |method|
      method.define_argument('key')
      method.define_argument('entry')
      method.define_argument('options')
    end
  end

  defs.define_constant('ActiveSupport::Cache::Strategy') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Cache::Strategy::LocalCache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cleanup') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('clear') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('decrement') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('delete_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('increment') do |method|
      method.define_argument('name')
      method.define_optional_argument('amount')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('middleware')

    klass.define_instance_method('read_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('with_local_cache')

    klass.define_instance_method('write_entry') do |method|
      method.define_argument('key')
      method.define_argument('entry')
      method.define_argument('options')
    end
  end

  defs.define_constant('ActiveSupport::Cache::Strategy::LocalCache::LocalCacheRegistry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache_for') do |method|
      method.define_argument('local_cache_key')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('set_cache_for') do |method|
      method.define_argument('local_cache_key')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveSupport::Cache::Strategy::LocalCache::LocalStore') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Cache::Store', RubyLint.registry))

    klass.define_instance_method('clear') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('delete_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('read_entry') do |method|
      method.define_argument('key')
      method.define_argument('options')
    end

    klass.define_instance_method('synchronize')

    klass.define_instance_method('write_entry') do |method|
      method.define_argument('key')
      method.define_argument('value')
      method.define_argument('options')
    end
  end

  defs.define_constant('ActiveSupport::Cache::Strategy::LocalCache::Middleware') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('local_cache_key')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('local_cache_key')

    klass.define_instance_method('name')

    klass.define_instance_method('new') do |method|
      method.define_argument('app')
    end
  end

  defs.define_constant('ActiveSupport::Cache::UNIVERSAL_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::CachingKeyGenerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('generate_key') do |method|
      method.define_argument('salt')
      method.define_optional_argument('key_size')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('key_generator')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::Callbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('run_callbacks') do |method|
      method.define_argument('kind')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::Callbacks::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Callbacks::Callback') do |klass|
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

  defs.define_constant('ActiveSupport::Callbacks::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__callback_runner_name_cache')

    klass.define_instance_method('__define_callbacks') do |method|
      method.define_argument('kind')
      method.define_argument('object')
    end

    klass.define_instance_method('__generate_callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__reset_runner') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('__update_callbacks') do |method|
      method.define_argument('name')
      method.define_optional_argument('filters')
      method.define_optional_argument('block')
    end

    klass.define_instance_method('define_callbacks') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('reset_callbacks') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('set_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end

    klass.define_instance_method('skip_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::Concern') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('extended') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('append_features') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('included') do |method|
      method.define_optional_argument('base')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('config')
  end

  defs.define_constant('ActiveSupport::Configurable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('config')

    klass.define_instance_method('config_accessor') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('configure')
  end

  defs.define_constant('ActiveSupport::Dependencies') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('autoload_once_paths')

    klass.define_method('autoload_once_paths=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('autoload_paths')

    klass.define_method('autoload_paths=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('autoloaded_constants')

    klass.define_method('autoloaded_constants=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('constant_watch_stack')

    klass.define_method('constant_watch_stack=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('explicitly_unloadable_constants')

    klass.define_method('explicitly_unloadable_constants=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('history')

    klass.define_method('history=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('loaded')

    klass.define_method('loaded=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('log_activity')

    klass.define_method('log_activity=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('logger')

    klass.define_method('logger=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('mechanism')

    klass.define_method('mechanism=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('warnings_on_first_load')

    klass.define_method('warnings_on_first_load=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('autoload_module!') do |method|
      method.define_argument('into')
      method.define_argument('const_name')
      method.define_argument('qualified_name')
      method.define_argument('path_suffix')
    end

    klass.define_instance_method('autoload_once_paths')

    klass.define_instance_method('autoload_once_paths=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('autoload_paths')

    klass.define_instance_method('autoload_paths=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('autoloadable_module?') do |method|
      method.define_argument('path_suffix')
    end

    klass.define_instance_method('autoloaded?') do |method|
      method.define_argument('desc')
    end

    klass.define_instance_method('autoloaded_constants')

    klass.define_instance_method('autoloaded_constants=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('constant_watch_stack')

    klass.define_instance_method('constant_watch_stack=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('constantize') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('depend_on') do |method|
      method.define_argument('file_name')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('explicitly_unloadable_constants')

    klass.define_instance_method('explicitly_unloadable_constants=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('history')

    klass.define_instance_method('history=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('hook!')

    klass.define_instance_method('load?')

    klass.define_instance_method('load_file') do |method|
      method.define_argument('path')
      method.define_optional_argument('const_paths')
    end

    klass.define_instance_method('load_missing_constant') do |method|
      method.define_argument('from_mod')
      method.define_argument('const_name')
    end

    klass.define_instance_method('load_once_path?') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('loadable_constants_for_path') do |method|
      method.define_argument('path')
      method.define_optional_argument('bases')
    end

    klass.define_instance_method('loaded')

    klass.define_instance_method('loaded=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('log') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('log_activity')

    klass.define_instance_method('log_activity=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('log_activity?')

    klass.define_instance_method('log_call') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('logger=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('mark_for_unload') do |method|
      method.define_argument('const_desc')
    end

    klass.define_instance_method('mechanism')

    klass.define_instance_method('mechanism=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('new_constants_in') do |method|
      method.define_rest_argument('descs')
    end

    klass.define_instance_method('qualified_const_defined?') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('qualified_name_for') do |method|
      method.define_argument('mod')
      method.define_argument('name')
    end

    klass.define_instance_method('reference') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('remove_constant') do |method|
      method.define_argument('const')
    end

    klass.define_instance_method('remove_unloadable_constants!')

    klass.define_instance_method('require_or_load') do |method|
      method.define_argument('file_name')
      method.define_optional_argument('const_path')
    end

    klass.define_instance_method('safe_constantize') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('search_for_file') do |method|
      method.define_argument('path_suffix')
    end

    klass.define_instance_method('to_constant_name') do |method|
      method.define_argument('desc')
    end

    klass.define_instance_method('unhook!')

    klass.define_instance_method('warnings_on_first_load')

    klass.define_instance_method('warnings_on_first_load=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('will_unload?') do |method|
      method.define_argument('const_desc')
    end
  end

  defs.define_constant('ActiveSupport::Dependencies::Blamable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('blame_file!') do |method|
      method.define_argument('file')
    end

    klass.define_instance_method('blamed_files')

    klass.define_instance_method('copy_blame!') do |method|
      method.define_argument('exc')
    end

    klass.define_instance_method('describe_blame')
  end

  defs.define_constant('ActiveSupport::Dependencies::ClassCache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('clear!')

    klass.define_instance_method('empty?')

    klass.define_instance_method('get') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('safe_get') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('store') do |method|
      method.define_argument('klass')
    end
  end

  defs.define_constant('ActiveSupport::Dependencies::Loadable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('exclude_from') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('load') do |method|
      method.define_argument('file')
      method.define_optional_argument('wrap')
    end

    klass.define_instance_method('load_dependency') do |method|
      method.define_argument('file')
    end

    klass.define_instance_method('require') do |method|
      method.define_argument('file')
    end

    klass.define_instance_method('require_dependency') do |method|
      method.define_argument('file_name')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('require_or_load') do |method|
      method.define_argument('file_name')
    end

    klass.define_instance_method('unloadable') do |method|
      method.define_argument('const_desc')
    end
  end

  defs.define_constant('ActiveSupport::Dependencies::ModuleConstMissing') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('append_features') do |method|
      method.define_argument('base')
    end

    klass.define_method('exclude_from') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('const_missing') do |method|
      method.define_argument('const_name')
    end

    klass.define_instance_method('unloadable') do |method|
      method.define_optional_argument('const_desc')
    end
  end

  defs.define_constant('ActiveSupport::Dependencies::Reference') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Dependencies::WatchStack') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('new_constants')

    klass.define_instance_method('watch_namespaces') do |method|
      method.define_argument('namespaces')
    end

    klass.define_instance_method('watching?')
  end

  defs.define_constant('ActiveSupport::Dependencies::WatchStack::Enumerator') do |klass|
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

  defs.define_constant('ActiveSupport::Dependencies::WatchStack::SortedElement') do |klass|
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

  defs.define_constant('ActiveSupport::Deprecation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Deprecation::MethodWrapper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Deprecation::Reporting', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Deprecation::Behavior', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Deprecation::InstanceDelegator', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Singleton', RubyLint.registry))

    klass.define_method('behavior') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('behavior=') do |method|
      method.define_argument('arg')
    end

    klass.define_method('debug') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('debug=') do |method|
      method.define_argument('arg')
    end

    klass.define_method('deprecate_methods') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('deprecation_horizon') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('deprecation_horizon=') do |method|
      method.define_argument('arg')
    end

    klass.define_method('deprecation_warning') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('gem_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('gem_name=') do |method|
      method.define_argument('arg')
    end

    klass.define_method('initialize') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('instance')

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_method('silence') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('silenced') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('silenced=') do |method|
      method.define_argument('arg')
    end

    klass.define_method('warn') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('deprecation_horizon')

    klass.define_instance_method('deprecation_horizon=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('deprecation_horizon')
      method.define_optional_argument('gem_name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::Deprecation::Behavior') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('behavior')

    klass.define_instance_method('behavior=') do |method|
      method.define_argument('behavior')
    end

    klass.define_instance_method('debug')

    klass.define_instance_method('debug=')
  end

  defs.define_constant('ActiveSupport::Deprecation::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('include') do |method|
      method.define_argument('included_module')
    end

    klass.define_instance_method('method_added') do |method|
      method.define_argument('method_name')
    end
  end

  defs.define_constant('ActiveSupport::Deprecation::DEFAULT_BEHAVIORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Deprecation::DeprecatedConstantProxy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Deprecation::DeprecationProxy', RubyLint.registry))

    klass.define_instance_method('class')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('old_const')
      method.define_argument('new_const')
      method.define_optional_argument('deprecator')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::Deprecation::DeprecatedInstanceVariableProxy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Deprecation::DeprecationProxy', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('instance')
      method.define_argument('method')
      method.define_optional_argument('var')
      method.define_optional_argument('deprecator')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::Deprecation::DeprecatedObjectProxy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Deprecation::DeprecationProxy', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('object')
      method.define_argument('message')
      method.define_optional_argument('deprecator')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::Deprecation::DeprecationProxy') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')
  end

  defs.define_constant('ActiveSupport::Deprecation::InstanceDelegator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end
  end

  defs.define_constant('ActiveSupport::Deprecation::InstanceDelegator::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('include') do |method|
      method.define_argument('included_module')
    end

    klass.define_instance_method('method_added') do |method|
      method.define_argument('method_name')
    end
  end

  defs.define_constant('ActiveSupport::Deprecation::MethodWrapper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('deprecate_methods') do |method|
      method.define_argument('target_module')
      method.define_rest_argument('method_names')
    end
  end

  defs.define_constant('ActiveSupport::Deprecation::Reporting') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('deprecation_warning') do |method|
      method.define_argument('deprecated_method_name')
      method.define_optional_argument('message')
      method.define_optional_argument('caller_backtrace')
    end

    klass.define_instance_method('gem_name')

    klass.define_instance_method('gem_name=')

    klass.define_instance_method('silence')

    klass.define_instance_method('silenced')

    klass.define_instance_method('silenced=')

    klass.define_instance_method('warn') do |method|
      method.define_optional_argument('message')
      method.define_optional_argument('callstack')
    end
  end

  defs.define_constant('ActiveSupport::Deprecation::SingletonClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('clone')
  end

  defs.define_constant('ActiveSupport::DeprecationException') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::DescendantsTracker') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('clear')

    klass.define_method('descendants') do |method|
      method.define_argument('klass')
    end

    klass.define_method('direct_descendants') do |method|
      method.define_argument('klass')
    end

    klass.define_method('store_inherited') do |method|
      method.define_argument('klass')
      method.define_argument('descendant')
    end

    klass.define_instance_method('descendants')

    klass.define_instance_method('direct_descendants')

    klass.define_instance_method('inherited') do |method|
      method.define_argument('base')
    end
  end

  defs.define_constant('ActiveSupport::Duration') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::ProxyObject', RubyLint.registry))

    klass.define_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('-@')

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('ago') do |method|
      method.define_optional_argument('time')
    end

    klass.define_instance_method('as_json') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('from_now') do |method|
      method.define_optional_argument('time')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')
      method.define_argument('parts')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('is_a?') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('kind_of?') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('parts')

    klass.define_instance_method('parts=')

    klass.define_instance_method('since') do |method|
      method.define_optional_argument('time')
    end

    klass.define_instance_method('sum') do |method|
      method.define_argument('sign')
      method.define_optional_argument('time')
    end

    klass.define_instance_method('until') do |method|
      method.define_optional_argument('time')
    end

    klass.define_instance_method('value')

    klass.define_instance_method('value=')
  end

  defs.define_constant('ActiveSupport::FileUpdateChecker') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('execute')

    klass.define_instance_method('execute_if_updated')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('files')
      method.define_optional_argument('dirs')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated?')
  end

  defs.define_constant('ActiveSupport::Gzip') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('compress') do |method|
      method.define_argument('source')
      method.define_optional_argument('level')
      method.define_optional_argument('strategy')
    end

    klass.define_method('decompress') do |method|
      method.define_argument('source')
    end
  end

  defs.define_constant('ActiveSupport::Gzip::Stream') do |klass|
    klass.inherits(defs.constant_proxy('StringIO', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::Gzip::Stream::Data') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('encoding')

    klass.define_instance_method('encoding=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('string')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lineno')

    klass.define_instance_method('lineno=')

    klass.define_instance_method('pos')

    klass.define_instance_method('pos=')

    klass.define_instance_method('string')

    klass.define_instance_method('string=')
  end

  defs.define_constant('ActiveSupport::Gzip::Stream::Enumerator') do |klass|
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

  defs.define_constant('ActiveSupport::Gzip::Stream::SortedElement') do |klass|
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

  defs.define_constant('ActiveSupport::Gzip::Stream::Undefined') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::HashWithIndifferentAccess') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new_from_hash_copying_default') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('convert_key') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('convert_value') do |method|
      method.define_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('deep_stringify_keys')

    klass.define_instance_method('deep_stringify_keys!')

    klass.define_instance_method('deep_symbolize_keys')

    klass.define_instance_method('default') do |method|
      method.define_optional_argument('key')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('dup')

    klass.define_instance_method('extractable_options?')

    klass.define_instance_method('fetch') do |method|
      method.define_argument('key')
      method.define_rest_argument('extras')
    end

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('include?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('constructor')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('member?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('hash')
      method.define_block_argument('block')
    end

    klass.define_instance_method('merge!') do |method|
      method.define_argument('other_hash')
    end

    klass.define_instance_method('nested_under_indifferent_access')

    klass.define_instance_method('regular_update') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('regular_writer') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('replace') do |method|
      method.define_argument('other_hash')
    end

    klass.define_instance_method('reverse_merge') do |method|
      method.define_argument('other_hash')
    end

    klass.define_instance_method('reverse_merge!') do |method|
      method.define_argument('other_hash')
    end

    klass.define_instance_method('store') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('stringify_keys')

    klass.define_instance_method('stringify_keys!')

    klass.define_instance_method('symbolize_keys')

    klass.define_instance_method('to_hash')

    klass.define_instance_method('to_options!')

    klass.define_instance_method('update') do |method|
      method.define_argument('other_hash')
    end

    klass.define_instance_method('values_at') do |method|
      method.define_rest_argument('indices')
    end

    klass.define_instance_method('with_indifferent_access')
  end

  defs.define_constant('ActiveSupport::HashWithIndifferentAccess::Bucket') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('delete') do |method|
      method.define_argument('key')
      method.define_argument('key_hash')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('key')
      method.define_argument('key_hash')
      method.define_argument('value')
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key')

    klass.define_instance_method('key=')

    klass.define_instance_method('key_hash')

    klass.define_instance_method('key_hash=')

    klass.define_instance_method('link')

    klass.define_instance_method('link=')

    klass.define_instance_method('next')

    klass.define_instance_method('next=')

    klass.define_instance_method('previous')

    klass.define_instance_method('previous=')

    klass.define_instance_method('remove')

    klass.define_instance_method('state')

    klass.define_instance_method('state=')

    klass.define_instance_method('value')

    klass.define_instance_method('value=')
  end

  defs.define_constant('ActiveSupport::HashWithIndifferentAccess::Entries') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_method('allocate')

    klass.define_method('new') do |method|
      method.define_argument('cnt')

      method.returns { |object| object.instance }
    end

    klass.define_method('pattern') do |method|
      method.define_argument('size')
      method.define_argument('obj')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('tup')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('idx')
      method.define_argument('val')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_argument('depth')
    end

    klass.define_instance_method('at') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('copy_from') do |method|
      method.define_argument('other')
      method.define_argument('start')
      method.define_argument('length')
      method.define_argument('dest')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('start')
      method.define_argument('length')
      method.define_argument('object')
    end

    klass.define_instance_method('delete_at_index') do |method|
      method.define_argument('index')
    end

    klass.define_instance_method('dup')

    klass.define_instance_method('each')

    klass.define_instance_method('empty?')

    klass.define_instance_method('fields')

    klass.define_instance_method('first')

    klass.define_instance_method('insert_at_index') do |method|
      method.define_argument('index')
      method.define_argument('value')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('join') do |method|
      method.define_argument('sep')
      method.define_optional_argument('meth')
    end

    klass.define_instance_method('join_upto') do |method|
      method.define_argument('sep')
      method.define_argument('count')
      method.define_optional_argument('meth')
    end

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('put') do |method|
      method.define_argument('idx')
      method.define_argument('val')
    end

    klass.define_instance_method('reverse!') do |method|
      method.define_argument('start')
      method.define_argument('total')
    end

    klass.define_instance_method('shift')

    klass.define_instance_method('size')

    klass.define_instance_method('swap') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('ActiveSupport::HashWithIndifferentAccess::Enumerator') do |klass|
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

  defs.define_constant('ActiveSupport::HashWithIndifferentAccess::Iterator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next') do |method|
      method.define_argument('item')
    end
  end

  defs.define_constant('ActiveSupport::HashWithIndifferentAccess::MAX_ENTRIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::HashWithIndifferentAccess::MIN_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::HashWithIndifferentAccess::SortedElement') do |klass|
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

  defs.define_constant('ActiveSupport::HashWithIndifferentAccess::State') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from') do |method|
      method.define_argument('state')
    end

    klass.define_instance_method('compare_by_identity')

    klass.define_instance_method('compare_by_identity?')

    klass.define_instance_method('head')

    klass.define_instance_method('head=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('match?') do |method|
      method.define_argument('this_key')
      method.define_argument('this_hash')
      method.define_argument('other_key')
      method.define_argument('other_hash')
    end

    klass.define_instance_method('tail')

    klass.define_instance_method('tail=')
  end

  defs.define_constant('ActiveSupport::Inflector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('camelize') do |method|
      method.define_argument('term')
      method.define_optional_argument('uppercase_first_letter')
    end

    klass.define_instance_method('classify') do |method|
      method.define_argument('table_name')
    end

    klass.define_instance_method('constantize') do |method|
      method.define_argument('camel_cased_word')
    end

    klass.define_instance_method('dasherize') do |method|
      method.define_argument('underscored_word')
    end

    klass.define_instance_method('deconstantize') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('demodulize') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('foreign_key') do |method|
      method.define_argument('class_name')
      method.define_optional_argument('separate_class_name_and_id_with_underscore')
    end

    klass.define_instance_method('humanize') do |method|
      method.define_argument('lower_case_and_underscored_word')
    end

    klass.define_instance_method('inflections') do |method|
      method.define_optional_argument('locale')
    end

    klass.define_instance_method('ordinal') do |method|
      method.define_argument('number')
    end

    klass.define_instance_method('ordinalize') do |method|
      method.define_argument('number')
    end

    klass.define_instance_method('parameterize') do |method|
      method.define_argument('string')
      method.define_optional_argument('sep')
    end

    klass.define_instance_method('pluralize') do |method|
      method.define_argument('word')
      method.define_optional_argument('locale')
    end

    klass.define_instance_method('safe_constantize') do |method|
      method.define_argument('camel_cased_word')
    end

    klass.define_instance_method('singularize') do |method|
      method.define_argument('word')
      method.define_optional_argument('locale')
    end

    klass.define_instance_method('tableize') do |method|
      method.define_argument('class_name')
    end

    klass.define_instance_method('titleize') do |method|
      method.define_argument('word')
    end

    klass.define_instance_method('transliterate') do |method|
      method.define_argument('string')
      method.define_optional_argument('replacement')
    end

    klass.define_instance_method('underscore') do |method|
      method.define_argument('camel_cased_word')
    end
  end

  defs.define_constant('ActiveSupport::Inflector::Inflections') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('instance') do |method|
      method.define_optional_argument('locale')
    end

    klass.define_instance_method('acronym') do |method|
      method.define_argument('word')
    end

    klass.define_instance_method('acronym_regex')

    klass.define_instance_method('acronyms')

    klass.define_instance_method('clear') do |method|
      method.define_optional_argument('scope')
    end

    klass.define_instance_method('human') do |method|
      method.define_argument('rule')
      method.define_argument('replacement')
    end

    klass.define_instance_method('humans')

    klass.define_instance_method('initialize')

    klass.define_instance_method('irregular') do |method|
      method.define_argument('singular')
      method.define_argument('plural')
    end

    klass.define_instance_method('plural') do |method|
      method.define_argument('rule')
      method.define_argument('replacement')
    end

    klass.define_instance_method('plurals')

    klass.define_instance_method('singular') do |method|
      method.define_argument('rule')
      method.define_argument('replacement')
    end

    klass.define_instance_method('singulars')

    klass.define_instance_method('uncountable') do |method|
      method.define_rest_argument('words')
    end

    klass.define_instance_method('uncountables')
  end

  defs.define_constant('ActiveSupport::InheritableOptions') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::OrderedOptions', RubyLint.registry))

    klass.define_instance_method('inheritable_copy')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('parent')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::InheritableOptions::Bucket') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('delete') do |method|
      method.define_argument('key')
      method.define_argument('key_hash')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('key')
      method.define_argument('key_hash')
      method.define_argument('value')
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key')

    klass.define_instance_method('key=')

    klass.define_instance_method('key_hash')

    klass.define_instance_method('key_hash=')

    klass.define_instance_method('link')

    klass.define_instance_method('link=')

    klass.define_instance_method('next')

    klass.define_instance_method('next=')

    klass.define_instance_method('previous')

    klass.define_instance_method('previous=')

    klass.define_instance_method('remove')

    klass.define_instance_method('state')

    klass.define_instance_method('state=')

    klass.define_instance_method('value')

    klass.define_instance_method('value=')
  end

  defs.define_constant('ActiveSupport::InheritableOptions::Entries') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_method('allocate')

    klass.define_method('new') do |method|
      method.define_argument('cnt')

      method.returns { |object| object.instance }
    end

    klass.define_method('pattern') do |method|
      method.define_argument('size')
      method.define_argument('obj')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('tup')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('idx')
      method.define_argument('val')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_argument('depth')
    end

    klass.define_instance_method('at') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('copy_from') do |method|
      method.define_argument('other')
      method.define_argument('start')
      method.define_argument('length')
      method.define_argument('dest')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('start')
      method.define_argument('length')
      method.define_argument('object')
    end

    klass.define_instance_method('delete_at_index') do |method|
      method.define_argument('index')
    end

    klass.define_instance_method('dup')

    klass.define_instance_method('each')

    klass.define_instance_method('empty?')

    klass.define_instance_method('fields')

    klass.define_instance_method('first')

    klass.define_instance_method('insert_at_index') do |method|
      method.define_argument('index')
      method.define_argument('value')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('join') do |method|
      method.define_argument('sep')
      method.define_optional_argument('meth')
    end

    klass.define_instance_method('join_upto') do |method|
      method.define_argument('sep')
      method.define_argument('count')
      method.define_optional_argument('meth')
    end

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('put') do |method|
      method.define_argument('idx')
      method.define_argument('val')
    end

    klass.define_instance_method('reverse!') do |method|
      method.define_argument('start')
      method.define_argument('total')
    end

    klass.define_instance_method('shift')

    klass.define_instance_method('size')

    klass.define_instance_method('swap') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('ActiveSupport::InheritableOptions::Enumerator') do |klass|
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

  defs.define_constant('ActiveSupport::InheritableOptions::Iterator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next') do |method|
      method.define_argument('item')
    end
  end

  defs.define_constant('ActiveSupport::InheritableOptions::MAX_ENTRIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::InheritableOptions::MIN_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::InheritableOptions::SortedElement') do |klass|
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

  defs.define_constant('ActiveSupport::InheritableOptions::State') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from') do |method|
      method.define_argument('state')
    end

    klass.define_instance_method('compare_by_identity')

    klass.define_instance_method('compare_by_identity?')

    klass.define_instance_method('head')

    klass.define_instance_method('head=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('match?') do |method|
      method.define_argument('this_key')
      method.define_argument('this_hash')
      method.define_argument('other_key')
      method.define_argument('other_hash')
    end

    klass.define_instance_method('tail')

    klass.define_instance_method('tail=')
  end

  defs.define_constant('ActiveSupport::JSON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('backend')

    klass.define_method('backend=') do |method|
      method.define_argument('name')
    end

    klass.define_method('decode') do |method|
      method.define_argument('json')
      method.define_optional_argument('options')
    end

    klass.define_method('encode') do |method|
      method.define_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_method('engine')

    klass.define_method('engine=') do |method|
      method.define_argument('name')
    end

    klass.define_method('parse_error')

    klass.define_method('with_backend') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('ActiveSupport::JSON::DATE_REGEX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::JSON::Encoding') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('encode_big_decimal_as_string')

    klass.define_method('encode_big_decimal_as_string=')

    klass.define_method('escape') do |method|
      method.define_argument('string')
    end

    klass.define_method('escape_html_entities_in_json')

    klass.define_method('escape_html_entities_in_json=') do |method|
      method.define_argument('value')
    end

    klass.define_method('escape_regex')

    klass.define_method('escape_regex=')

    klass.define_method('use_standard_json_time_format')

    klass.define_method('use_standard_json_time_format=')
  end

  defs.define_constant('ActiveSupport::JSON::Encoding::CircularReferenceError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::JSON::Encoding::ESCAPED_CHARS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::JSON::Encoding::Encoder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_json') do |method|
      method.define_argument('value')
      method.define_optional_argument('use_options')
    end

    klass.define_instance_method('encode') do |method|
      method.define_argument('value')
      method.define_optional_argument('use_options')
    end

    klass.define_instance_method('escape') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options_for') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveSupport::JSON::Variable') do |klass|
    klass.inherits(defs.constant_proxy('String', RubyLint.registry))

    klass.define_instance_method('as_json') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('encode_json') do |method|
      method.define_argument('encoder')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::JSON::Variable::Complexifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::JSON::Variable::ControlCharacters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::JSON::Variable::ControlPrintValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::JSON::Variable::Extend') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create')
  end

  defs.define_constant('ActiveSupport::JSON::Variable::Rationalizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::KeyGenerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('generate_key') do |method|
      method.define_argument('salt')
      method.define_optional_argument('key_size')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('secret')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::LegacyKeyGenerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('generate_key') do |method|
      method.define_argument('salt')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('secret')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::LegacyKeyGenerator::SECRET_MIN_LENGTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::LogSubscriber') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Subscriber', RubyLint.registry))

    klass.define_method('colorize_logging')

    klass.define_method('colorize_logging=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('flush_all!')

    klass.define_method('log_subscribers')

    klass.define_method('logger')

    klass.define_method('logger=')

    klass.define_instance_method('color') do |method|
      method.define_argument('text')
      method.define_argument('color')
      method.define_optional_argument('bold')
    end

    klass.define_instance_method('colorize_logging')

    klass.define_instance_method('colorize_logging=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('debug') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('error') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('fatal') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('finish') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end

    klass.define_instance_method('info') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('start') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end

    klass.define_instance_method('unknown') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('warn') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::LogSubscriber::BLACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::LogSubscriber::BLUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::LogSubscriber::BOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::LogSubscriber::CLEAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::LogSubscriber::CYAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::LogSubscriber::GREEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::LogSubscriber::MAGENTA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::LogSubscriber::RED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::LogSubscriber::WHITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::LogSubscriber::YELLOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger') do |klass|
    klass.inherits(defs.constant_proxy('Logger', RubyLint.registry))
    klass.inherits(defs.constant_proxy('LoggerSilence', RubyLint.registry))

    klass.define_method('broadcast') do |method|
      method.define_argument('logger')
    end

    klass.define_method('silencer')

    klass.define_method('silencer=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('silencer')

    klass.define_instance_method('silencer=') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('ActiveSupport::Logger::Application') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Logger::Severity', RubyLint.registry))

    klass.define_instance_method('appname')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('appname')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('level=') do |method|
      method.define_argument('level')
    end

    klass.define_instance_method('log') do |method|
      method.define_argument('severity')
      method.define_optional_argument('message')
      method.define_block_argument('block')
    end

    klass.define_instance_method('log=') do |method|
      method.define_argument('logdev')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('logger=') do |method|
      method.define_argument('logger')
    end

    klass.define_instance_method('set_log') do |method|
      method.define_argument('logdev')
      method.define_optional_argument('shift_age')
      method.define_optional_argument('shift_size')
    end

    klass.define_instance_method('start')
  end

  defs.define_constant('ActiveSupport::Logger::DEBUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::Error') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::FATAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::Formatter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('severity')
      method.define_argument('time')
      method.define_argument('progname')
      method.define_argument('msg')
    end

    klass.define_instance_method('datetime_format')

    klass.define_instance_method('datetime_format=')

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActiveSupport::Logger::INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::LogDevice') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('close')

    klass.define_instance_method('dev')

    klass.define_instance_method('filename')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('log')
      method.define_optional_argument('opt')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('write') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('ActiveSupport::Logger::ProgName') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::SEV_LABEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::Severity') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::ShiftingError') do |klass|
    klass.inherits(defs.constant_proxy('Logger::Error', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::SimpleFormatter') do |klass|
    klass.inherits(defs.constant_proxy('Logger::Formatter', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('severity')
      method.define_argument('timestamp')
      method.define_argument('progname')
      method.define_argument('msg')
    end
  end

  defs.define_constant('ActiveSupport::Logger::SimpleFormatter::Format') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Logger::WARN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::MessageEncryptor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('decrypt_and_verify') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('encrypt_and_sign') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('secret')
      method.define_rest_argument('signature_key_or_options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::MessageEncryptor::InvalidMessage') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::MessageEncryptor::NullSerializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('dump') do |method|
      method.define_argument('value')
    end

    klass.define_method('load') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveSupport::MessageEncryptor::OpenSSLCipherError') do |klass|
    klass.inherits(defs.constant_proxy('OpenSSL::OpenSSLError', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::MessageVerifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('generate') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('secret')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('verify') do |method|
      method.define_argument('signed_message')
    end
  end

  defs.define_constant('ActiveSupport::MessageVerifier::InvalidSignature') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Multibyte') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('clean') do |method|
      method.define_argument('string')
    end

    klass.define_method('proxy_class')

    klass.define_method('proxy_class=') do |method|
      method.define_argument('klass')
    end

    klass.define_method('valid_character')

    klass.define_method('verify') do |method|
      method.define_argument('string')
    end

    klass.define_method('verify!') do |method|
      method.define_argument('string')
    end
  end

  defs.define_constant('ActiveSupport::Notifications') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('instrument') do |method|
      method.define_argument('name')
      method.define_optional_argument('payload')
    end

    klass.define_method('instrumenter')

    klass.define_method('notifier')

    klass.define_method('notifier=')

    klass.define_method('publish') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end

    klass.define_method('subscribe') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('subscribed') do |method|
      method.define_argument('callback')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('unsubscribe') do |method|
      method.define_argument('args')
    end
  end

  defs.define_constant('ActiveSupport::Notifications::Event') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('event')
    end

    klass.define_instance_method('children')

    klass.define_instance_method('duration')

    klass.define_instance_method('end')

    klass.define_instance_method('end=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('start')
      method.define_argument('ending')
      method.define_argument('transaction_id')
      method.define_argument('payload')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('parent_of?') do |method|
      method.define_argument('event')
    end

    klass.define_instance_method('payload')

    klass.define_instance_method('time')

    klass.define_instance_method('transaction_id')
  end

  defs.define_constant('ActiveSupport::Notifications::Fanout') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mutex_m', RubyLint.registry))

    klass.define_instance_method('finish') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('listeners_for') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('listening?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('lock')

    klass.define_instance_method('locked?')

    klass.define_instance_method('publish') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('start') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end

    klass.define_instance_method('subscribe') do |method|
      method.define_optional_argument('pattern')
      method.define_optional_argument('block')
    end

    klass.define_instance_method('synchronize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('try_lock')

    klass.define_instance_method('unlock')

    klass.define_instance_method('unsubscribe') do |method|
      method.define_argument('subscriber')
    end

    klass.define_instance_method('wait')
  end

  defs.define_constant('ActiveSupport::Notifications::Fanout::Subscribers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_argument('pattern')
      method.define_argument('listener')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::Notifications::Fanout::Subscribers::AllMessages') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('finish') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('delegate')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('matches?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('publish') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('start') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end

    klass.define_instance_method('subscribed_to?') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('ActiveSupport::Notifications::Fanout::Subscribers::Evented') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('finish') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('pattern')
      method.define_argument('delegate')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('matches?') do |method|
      method.define_argument('subscriber_or_name')
    end

    klass.define_instance_method('publish') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('start') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end

    klass.define_instance_method('subscribed_to?') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('ActiveSupport::Notifications::Fanout::Subscribers::Timed') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::Notifications::Fanout::Subscribers::Evented', RubyLint.registry))

    klass.define_instance_method('finish') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('pattern')
      method.define_argument('delegate')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('publish') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('start') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end
  end

  defs.define_constant('ActiveSupport::Notifications::InstrumentationRegistry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('instrumenter_for') do |method|
      method.define_argument('notifier')
    end
  end

  defs.define_constant('ActiveSupport::Notifications::Instrumenter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('finish') do |method|
      method.define_argument('name')
      method.define_argument('payload')
    end

    klass.define_instance_method('id')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('notifier')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('instrument') do |method|
      method.define_argument('name')
      method.define_optional_argument('payload')
    end

    klass.define_instance_method('start') do |method|
      method.define_argument('name')
      method.define_argument('payload')
    end
  end

  defs.define_constant('ActiveSupport::NumberHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('number_to_currency') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_delimited') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_human') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_human_size') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_percentage') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_phone') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_rounded') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActiveSupport::NumberHelper::DECIMAL_UNITS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::NumberHelper::DEFAULTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::NumberHelper::STORAGE_UNITS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::OptionMerger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('context')
      method.define_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::OrderedHash') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('extractable_options?')

    klass.define_instance_method('nested_under_indifferent_access')

    klass.define_instance_method('to_yaml_type')
  end

  defs.define_constant('ActiveSupport::OrderedHash::Bucket') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('delete') do |method|
      method.define_argument('key')
      method.define_argument('key_hash')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('key')
      method.define_argument('key_hash')
      method.define_argument('value')
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key')

    klass.define_instance_method('key=')

    klass.define_instance_method('key_hash')

    klass.define_instance_method('key_hash=')

    klass.define_instance_method('link')

    klass.define_instance_method('link=')

    klass.define_instance_method('next')

    klass.define_instance_method('next=')

    klass.define_instance_method('previous')

    klass.define_instance_method('previous=')

    klass.define_instance_method('remove')

    klass.define_instance_method('state')

    klass.define_instance_method('state=')

    klass.define_instance_method('value')

    klass.define_instance_method('value=')
  end

  defs.define_constant('ActiveSupport::OrderedHash::Entries') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_method('allocate')

    klass.define_method('new') do |method|
      method.define_argument('cnt')

      method.returns { |object| object.instance }
    end

    klass.define_method('pattern') do |method|
      method.define_argument('size')
      method.define_argument('obj')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('tup')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('idx')
      method.define_argument('val')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_argument('depth')
    end

    klass.define_instance_method('at') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('copy_from') do |method|
      method.define_argument('other')
      method.define_argument('start')
      method.define_argument('length')
      method.define_argument('dest')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('start')
      method.define_argument('length')
      method.define_argument('object')
    end

    klass.define_instance_method('delete_at_index') do |method|
      method.define_argument('index')
    end

    klass.define_instance_method('dup')

    klass.define_instance_method('each')

    klass.define_instance_method('empty?')

    klass.define_instance_method('fields')

    klass.define_instance_method('first')

    klass.define_instance_method('insert_at_index') do |method|
      method.define_argument('index')
      method.define_argument('value')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('join') do |method|
      method.define_argument('sep')
      method.define_optional_argument('meth')
    end

    klass.define_instance_method('join_upto') do |method|
      method.define_argument('sep')
      method.define_argument('count')
      method.define_optional_argument('meth')
    end

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('put') do |method|
      method.define_argument('idx')
      method.define_argument('val')
    end

    klass.define_instance_method('reverse!') do |method|
      method.define_argument('start')
      method.define_argument('total')
    end

    klass.define_instance_method('shift')

    klass.define_instance_method('size')

    klass.define_instance_method('swap') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('ActiveSupport::OrderedHash::Enumerator') do |klass|
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

  defs.define_constant('ActiveSupport::OrderedHash::Iterator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next') do |method|
      method.define_argument('item')
    end
  end

  defs.define_constant('ActiveSupport::OrderedHash::MAX_ENTRIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::OrderedHash::MIN_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::OrderedHash::SortedElement') do |klass|
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

  defs.define_constant('ActiveSupport::OrderedHash::State') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from') do |method|
      method.define_argument('state')
    end

    klass.define_instance_method('compare_by_identity')

    klass.define_instance_method('compare_by_identity?')

    klass.define_instance_method('head')

    klass.define_instance_method('head=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('match?') do |method|
      method.define_argument('this_key')
      method.define_argument('this_hash')
      method.define_argument('other_key')
      method.define_argument('other_hash')
    end

    klass.define_instance_method('tail')

    klass.define_instance_method('tail=')
  end

  defs.define_constant('ActiveSupport::OrderedOptions') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('_get') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveSupport::OrderedOptions::Bucket') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('delete') do |method|
      method.define_argument('key')
      method.define_argument('key_hash')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('key')
      method.define_argument('key_hash')
      method.define_argument('value')
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key')

    klass.define_instance_method('key=')

    klass.define_instance_method('key_hash')

    klass.define_instance_method('key_hash=')

    klass.define_instance_method('link')

    klass.define_instance_method('link=')

    klass.define_instance_method('next')

    klass.define_instance_method('next=')

    klass.define_instance_method('previous')

    klass.define_instance_method('previous=')

    klass.define_instance_method('remove')

    klass.define_instance_method('state')

    klass.define_instance_method('state=')

    klass.define_instance_method('value')

    klass.define_instance_method('value=')
  end

  defs.define_constant('ActiveSupport::OrderedOptions::Entries') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_method('allocate')

    klass.define_method('new') do |method|
      method.define_argument('cnt')

      method.returns { |object| object.instance }
    end

    klass.define_method('pattern') do |method|
      method.define_argument('size')
      method.define_argument('obj')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('tup')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('idx')
      method.define_argument('val')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_argument('depth')
    end

    klass.define_instance_method('at') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('copy_from') do |method|
      method.define_argument('other')
      method.define_argument('start')
      method.define_argument('length')
      method.define_argument('dest')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('start')
      method.define_argument('length')
      method.define_argument('object')
    end

    klass.define_instance_method('delete_at_index') do |method|
      method.define_argument('index')
    end

    klass.define_instance_method('dup')

    klass.define_instance_method('each')

    klass.define_instance_method('empty?')

    klass.define_instance_method('fields')

    klass.define_instance_method('first')

    klass.define_instance_method('insert_at_index') do |method|
      method.define_argument('index')
      method.define_argument('value')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('join') do |method|
      method.define_argument('sep')
      method.define_optional_argument('meth')
    end

    klass.define_instance_method('join_upto') do |method|
      method.define_argument('sep')
      method.define_argument('count')
      method.define_optional_argument('meth')
    end

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('put') do |method|
      method.define_argument('idx')
      method.define_argument('val')
    end

    klass.define_instance_method('reverse!') do |method|
      method.define_argument('start')
      method.define_argument('total')
    end

    klass.define_instance_method('shift')

    klass.define_instance_method('size')

    klass.define_instance_method('swap') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('ActiveSupport::OrderedOptions::Enumerator') do |klass|
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

  defs.define_constant('ActiveSupport::OrderedOptions::Iterator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next') do |method|
      method.define_argument('item')
    end
  end

  defs.define_constant('ActiveSupport::OrderedOptions::MAX_ENTRIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::OrderedOptions::MIN_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::OrderedOptions::SortedElement') do |klass|
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

  defs.define_constant('ActiveSupport::OrderedOptions::State') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from') do |method|
      method.define_argument('state')
    end

    klass.define_instance_method('compare_by_identity')

    klass.define_instance_method('compare_by_identity?')

    klass.define_instance_method('head')

    klass.define_instance_method('head=')

    klass.define_instance_method('initialize')

    klass.define_instance_method('match?') do |method|
      method.define_argument('this_key')
      method.define_argument('this_hash')
      method.define_argument('other_key')
      method.define_argument('other_hash')
    end

    klass.define_instance_method('tail')

    klass.define_instance_method('tail=')
  end

  defs.define_constant('ActiveSupport::PerThreadRegistry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::ProxyObject') do |klass|
    klass.inherits(defs.constant_proxy('BasicObject', RubyLint.registry))

    klass.define_instance_method('raise') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveSupport::Railtie') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configurable', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Railtie::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Railtie::ClassMethods') do |klass|
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

  defs.define_constant('ActiveSupport::Railtie::Collection') do |klass|
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

  defs.define_constant('ActiveSupport::Railtie::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Railtie::Configuration') do |klass|
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

  defs.define_constant('ActiveSupport::Railtie::Initializer') do |klass|
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

  defs.define_constant('ActiveSupport::Rescuable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('handler_for_rescue') do |method|
      method.define_argument('exception')
    end

    klass.define_instance_method('rescue_with_handler') do |method|
      method.define_argument('exception')
    end
  end

  defs.define_constant('ActiveSupport::Rescuable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('rescue_from') do |method|
      method.define_rest_argument('klasses')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::SafeBuffer') do |klass|
    klass.inherits(defs.constant_proxy('String', RubyLint.registry))

    klass.define_instance_method('%') do |method|
      method.define_argument('args')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('capitalize') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('capitalize!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('chomp') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('chomp!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('chop') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('chop!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('clone_empty')

    klass.define_instance_method('concat') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('downcase') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('downcase!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('gsub') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('gsub!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('html_safe?')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lstrip') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('lstrip!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('next') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('next!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('prepend!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('reverse') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('reverse!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('rstrip') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rstrip!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('safe_concat') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('slice') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('slice!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('squeeze') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('squeeze!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('strip') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('strip!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('sub') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sub!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('succ') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('succ!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('swapcase') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('swapcase!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('to_param')

    klass.define_instance_method('to_s')

    klass.define_instance_method('tr') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tr!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('tr_s') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tr_s!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('upcase') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('upcase!') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveSupport::SafeBuffer::Complexifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::SafeBuffer::ControlCharacters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::SafeBuffer::ControlPrintValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::SafeBuffer::Extend') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create')
  end

  defs.define_constant('ActiveSupport::SafeBuffer::Rationalizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::SafeBuffer::SafeConcatError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActiveSupport::SafeBuffer::UNSAFE_STRING_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::StringInquirer') do |klass|
    klass.inherits(defs.constant_proxy('String', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::StringInquirer::Complexifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::StringInquirer::ControlCharacters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::StringInquirer::ControlPrintValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::StringInquirer::Extend') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create')
  end

  defs.define_constant('ActiveSupport::StringInquirer::Rationalizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::Subscriber') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('attach_to') do |method|
      method.define_argument('namespace')
      method.define_optional_argument('subscriber')
      method.define_optional_argument('notifier')
    end

    klass.define_method('subscribers')

    klass.define_instance_method('finish') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('start') do |method|
      method.define_argument('name')
      method.define_argument('id')
      method.define_argument('payload')
    end
  end

  defs.define_constant('ActiveSupport::SubscriberQueueRegistry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('get_queue') do |method|
      method.define_argument('queue_key')
    end

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActiveSupport::TaggedLogging') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_argument('logger')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('clear_tags!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('flush')

    klass.define_instance_method('pop_tags') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('push_tags') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tagged') do |method|
      method.define_rest_argument('tags')
    end
  end

  defs.define_constant('ActiveSupport::TaggedLogging::Formatter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('severity')
      method.define_argument('timestamp')
      method.define_argument('progname')
      method.define_argument('msg')
    end

    klass.define_instance_method('clear_tags!')

    klass.define_instance_method('current_tags')

    klass.define_instance_method('pop_tags') do |method|
      method.define_optional_argument('size')
    end

    klass.define_instance_method('push_tags') do |method|
      method.define_rest_argument('tags')
    end

    klass.define_instance_method('tagged') do |method|
      method.define_rest_argument('tags')
    end
  end

  defs.define_constant('ActiveSupport::TestCase') do |klass|
    klass.inherits(defs.constant_proxy('MiniTest::Unit::TestCase', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Testing::Pending', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Testing::Deprecation', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Testing::Assertions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Callbacks', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Testing::SetupAndTeardown', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Testing::TaggedLogging', RubyLint.registry))

    klass.define_method('_setup_callbacks')

    klass.define_method('_setup_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_setup_callbacks?')

    klass.define_method('_teardown_callbacks')

    klass.define_method('_teardown_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_teardown_callbacks?')

    klass.define_method('describe') do |method|
      method.define_argument('text')
    end

    klass.define_method('for_tag') do |method|
      method.define_argument('tag')
    end

    klass.define_method('test_order')

    klass.define_instance_method('_setup_callbacks')

    klass.define_instance_method('_setup_callbacks=')

    klass.define_instance_method('_setup_callbacks?')

    klass.define_instance_method('_teardown_callbacks')

    klass.define_instance_method('_teardown_callbacks=')

    klass.define_instance_method('_teardown_callbacks?')

    klass.define_instance_method('assert_no_match') do |method|
      method.define_argument('matcher')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_empty') do |method|
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_equal') do |method|
      method.define_argument('exp')
      method.define_argument('act')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_in_delta') do |method|
      method.define_argument('exp')
      method.define_argument('act')
      method.define_optional_argument('delta')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_in_epsilon') do |method|
      method.define_argument('a')
      method.define_argument('b')
      method.define_optional_argument('epsilon')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_includes') do |method|
      method.define_argument('collection')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_instance_of') do |method|
      method.define_argument('cls')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_kind_of') do |method|
      method.define_argument('cls')
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_nil') do |method|
      method.define_argument('obj')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_operator') do |method|
      method.define_argument('o1')
      method.define_argument('op')
      method.define_optional_argument('o2')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_predicate') do |method|
      method.define_argument('o1')
      method.define_argument('op')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_respond_to') do |method|
      method.define_argument('obj')
      method.define_argument('meth')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_not_same') do |method|
      method.define_argument('exp')
      method.define_argument('act')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_nothing_raised') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('assert_raise') do |method|
      method.define_rest_argument('exp')
    end

    klass.define_instance_method('method_name')
  end

  defs.define_constant('ActiveSupport::TestCase::Assertion') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::TestCase::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::TestCase::Callback') do |klass|
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

  defs.define_constant('ActiveSupport::TestCase::CallbackChain') do |klass|
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

  defs.define_constant('ActiveSupport::TestCase::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__callback_runner_name_cache')

    klass.define_instance_method('__define_callbacks') do |method|
      method.define_argument('kind')
      method.define_argument('object')
    end

    klass.define_instance_method('__generate_callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__reset_runner') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('__update_callbacks') do |method|
      method.define_argument('name')
      method.define_optional_argument('filters')
      method.define_optional_argument('block')
    end

    klass.define_instance_method('define_callbacks') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('reset_callbacks') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('set_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end

    klass.define_instance_method('skip_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::TestCase::PASSTHROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::TestCase::UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('inspect')
  end

  defs.define_constant('ActiveSupport::Testing') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Testing::Assertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_blank') do |method|
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_difference') do |method|
      method.define_argument('expression')
      method.define_optional_argument('difference')
      method.define_optional_argument('message')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_no_difference') do |method|
      method.define_argument('expression')
      method.define_optional_argument('message')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_not') do |method|
      method.define_argument('object')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_present') do |method|
      method.define_argument('object')
      method.define_optional_argument('message')
    end
  end

  defs.define_constant('ActiveSupport::Testing::ConstantLookup') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Testing::ConstantLookup::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('determine_constant_from_test_name') do |method|
      method.define_argument('test_name')
    end
  end

  defs.define_constant('ActiveSupport::Testing::Declarative') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('extended') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('test') do |method|
      method.define_argument('name')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::Testing::Deprecation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_deprecated') do |method|
      method.define_optional_argument('match')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_not_deprecated') do |method|
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::Testing::Isolation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('forking_env?')

    klass.define_method('included') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('_run_class_setup')

    klass.define_instance_method('run') do |method|
      method.define_argument('runner')
    end
  end

  defs.define_constant('ActiveSupport::Testing::Isolation::Forking') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('run_in_isolation') do |method|
      method.define_block_argument('blk')
    end
  end

  defs.define_constant('ActiveSupport::Testing::Isolation::Subprocess') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('run_in_isolation') do |method|
      method.define_block_argument('blk')
    end
  end

  defs.define_constant('ActiveSupport::Testing::Isolation::Subprocess::ORIG_ARGV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::Testing::Pending') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('pending') do |method|
      method.define_optional_argument('description')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::Testing::ProxyTestResult') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__replay__') do |method|
      method.define_argument('result')
    end

    klass.define_instance_method('add_error') do |method|
      method.define_argument('e')
    end

    klass.define_instance_method('info_signal')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('calls')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('calls')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveSupport::Testing::RemoteError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('backtrace')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('exception')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('message')
  end

  defs.define_constant('ActiveSupport::Testing::SetupAndTeardown') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after_teardown')

    klass.define_instance_method('before_setup')
  end

  defs.define_constant('ActiveSupport::Testing::SetupAndTeardown::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('setup') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('teardown') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveSupport::Testing::TaggedLogging') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('before_setup')

    klass.define_instance_method('tagged_logger=')
  end

  defs.define_constant('ActiveSupport::TimeWithZone') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('name')

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('acts_like_time?')

    klass.define_instance_method('advance') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('ago') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('as_json') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('between?') do |method|
      method.define_argument('min')
      method.define_argument('max')
    end

    klass.define_instance_method('comparable_time')

    klass.define_instance_method('day')

    klass.define_instance_method('dst?')

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('formatted_offset') do |method|
      method.define_optional_argument('colon')
      method.define_optional_argument('alternate_utc_string')
    end

    klass.define_instance_method('freeze')

    klass.define_instance_method('future?')

    klass.define_instance_method('getgm')

    klass.define_instance_method('getlocal')

    klass.define_instance_method('getutc')

    klass.define_instance_method('gmt?')

    klass.define_instance_method('gmt_offset')

    klass.define_instance_method('gmtime')

    klass.define_instance_method('gmtoff')

    klass.define_instance_method('hash')

    klass.define_instance_method('hour')

    klass.define_instance_method('httpdate')

    klass.define_instance_method('in_time_zone') do |method|
      method.define_optional_argument('new_zone')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('utc_time')
      method.define_argument('time_zone')
      method.define_optional_argument('local_time')
      method.define_optional_argument('period')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('is_a?') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('isdst')

    klass.define_instance_method('iso8601') do |method|
      method.define_optional_argument('fraction_digits')
    end

    klass.define_instance_method('kind_of?') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('localtime')

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('variables')
    end

    klass.define_instance_method('mday')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('sym')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('min')

    klass.define_instance_method('mon')

    klass.define_instance_method('month')

    klass.define_instance_method('nsec')

    klass.define_instance_method('past?')

    klass.define_instance_method('period')

    klass.define_instance_method('rfc2822')

    klass.define_instance_method('rfc822')

    klass.define_instance_method('sec')

    klass.define_instance_method('since') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('strftime') do |method|
      method.define_argument('format')
    end

    klass.define_instance_method('time')

    klass.define_instance_method('time_zone')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_date')

    klass.define_instance_method('to_datetime')

    klass.define_instance_method('to_f')

    klass.define_instance_method('to_formatted_s') do |method|
      method.define_optional_argument('format')
    end

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_r')

    klass.define_instance_method('to_s') do |method|
      method.define_optional_argument('format')
    end

    klass.define_instance_method('to_time')

    klass.define_instance_method('today?')

    klass.define_instance_method('tv_sec')

    klass.define_instance_method('usec')

    klass.define_instance_method('utc')

    klass.define_instance_method('utc?')

    klass.define_instance_method('utc_offset')

    klass.define_instance_method('wday')

    klass.define_instance_method('xmlschema') do |method|
      method.define_optional_argument('fraction_digits')
    end

    klass.define_instance_method('yday')

    klass.define_instance_method('year')

    klass.define_instance_method('zone')
  end

  defs.define_constant('ActiveSupport::TimeZone') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_argument('arg')
    end

    klass.define_method('all')

    klass.define_method('create') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('find_tzinfo') do |method|
      method.define_argument('name')
    end

    klass.define_method('new') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_method('require_tzinfo')

    klass.define_method('seconds_to_utc_offset') do |method|
      method.define_argument('seconds')
      method.define_optional_argument('colon')
    end

    klass.define_method('us_zones')

    klass.define_method('zones_map')

    klass.define_instance_method('<=>') do |method|
      method.define_argument('zone')
    end

    klass.define_instance_method('=~') do |method|
      method.define_argument('re')
    end

    klass.define_instance_method('at') do |method|
      method.define_argument('secs')
    end

    klass.define_instance_method('formatted_offset') do |method|
      method.define_optional_argument('colon')
      method.define_optional_argument('alternate_utc_string')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_optional_argument('utc_offset')
      method.define_optional_argument('tzinfo')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('local') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('local_to_utc') do |method|
      method.define_argument('time')
      method.define_optional_argument('dst')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('now')

    klass.define_instance_method('parse') do |method|
      method.define_argument('str')
      method.define_optional_argument('now')
    end

    klass.define_instance_method('period_for_local') do |method|
      method.define_argument('time')
      method.define_optional_argument('dst')
    end

    klass.define_instance_method('period_for_utc') do |method|
      method.define_argument('time')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('today')

    klass.define_instance_method('tzinfo')

    klass.define_instance_method('utc_offset')

    klass.define_instance_method('utc_to_local') do |method|
      method.define_argument('time')
    end
  end

  defs.define_constant('ActiveSupport::TimeZone::MAPPING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::TimeZone::UTC_OFFSET_WITHOUT_COLON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::TimeZone::UTC_OFFSET_WITH_COLON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::VERSION::MAJOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::VERSION::MINOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::VERSION::PRE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::VERSION::STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::VERSION::TINY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::XMLConverter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('xml')
      method.define_optional_argument('disallowed_types')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_h')
  end

  defs.define_constant('ActiveSupport::XMLConverter::DISALLOWED_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::XMLConverter::DisallowedType') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('type')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveSupport::XmlMini') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_dasherize') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('_parse_binary') do |method|
      method.define_argument('bin')
      method.define_argument('entity')
    end

    klass.define_instance_method('_parse_file') do |method|
      method.define_argument('file')
      method.define_argument('entity')
    end

    klass.define_instance_method('backend')

    klass.define_instance_method('backend=') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('parse') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rename_key') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('to_tag') do |method|
      method.define_argument('key')
      method.define_argument('value')
      method.define_argument('options')
    end

    klass.define_instance_method('with_backend') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('ActiveSupport::XmlMini::DEFAULT_ENCODINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::XmlMini::FORMATTING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::XmlMini::FileLike') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('content_type')

    klass.define_instance_method('content_type=')

    klass.define_instance_method('original_filename')

    klass.define_instance_method('original_filename=')
  end

  defs.define_constant('ActiveSupport::XmlMini::PARSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::XmlMini::TYPE_NAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveSupport::XmlMini_REXML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('parse') do |method|
      method.define_argument('data')
    end
  end

  defs.define_constant('ActiveSupport::XmlMini_REXML::CONTENT_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
