# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Gem') do |defs|
  defs.define_constant('Gem') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('bin_path') do |method|
      method.define_argument('name')
      method.define_optional_argument('exec_name')
      method.define_rest_argument('requirements')
    end

    klass.define_method('binary_mode')

    klass.define_method('bindir') do |method|
      method.define_optional_argument('install_dir')
    end

    klass.define_method('clear_default_specs')

    klass.define_method('clear_paths')

    klass.define_method('config_file')

    klass.define_method('configuration')

    klass.define_method('configuration=') do |method|
      method.define_argument('config')
    end

    klass.define_method('datadir') do |method|
      method.define_argument('gem_name')
    end

    klass.define_method('default_bindir')

    klass.define_method('default_cert_path')

    klass.define_method('default_dir')

    klass.define_method('default_exec_format')

    klass.define_method('default_gems_use_full_paths?')

    klass.define_method('default_key_path')

    klass.define_method('default_path')

    klass.define_method('default_rubygems_dirs')

    klass.define_method('default_sources')

    klass.define_method('default_spec_cache_dir')

    klass.define_method('deflate') do |method|
      method.define_argument('data')
    end

    klass.define_method('detect_gemdeps')

    klass.define_method('dir')

    klass.define_method('done_installing') do |method|
      method.define_block_argument('hook')
    end

    klass.define_method('done_installing_hooks')

    klass.define_method('ensure_default_gem_subdirectories') do |method|
      method.define_optional_argument('dir')
      method.define_optional_argument('mode')
    end

    klass.define_method('ensure_gem_subdirectories') do |method|
      method.define_optional_argument('dir')
      method.define_optional_argument('mode')
    end

    klass.define_method('ensure_subdirectories') do |method|
      method.define_argument('dir')
      method.define_argument('mode')
      method.define_argument('subdirs')
    end

    klass.define_method('find_files') do |method|
      method.define_argument('glob')
      method.define_optional_argument('check_load_path')
    end

    klass.define_method('find_files_from_load_path') do |method|
      method.define_argument('glob')
    end

    klass.define_method('find_latest_files') do |method|
      method.define_argument('glob')
      method.define_optional_argument('check_load_path')
    end

    klass.define_method('find_unresolved_default_spec') do |method|
      method.define_argument('path')
    end

    klass.define_method('finish_resolve') do |method|
      method.define_optional_argument('request_set')
    end

    klass.define_method('gunzip') do |method|
      method.define_argument('data')
    end

    klass.define_method('gzip') do |method|
      method.define_argument('data')
    end

    klass.define_method('host')

    klass.define_method('host=') do |method|
      method.define_argument('host')
    end

    klass.define_method('inflate') do |method|
      method.define_argument('data')
    end

    klass.define_method('install') do |method|
      method.define_argument('name')
      method.define_optional_argument('version')
    end

    klass.define_method('latest_rubygems_version')

    klass.define_method('latest_spec_for') do |method|
      method.define_argument('name')
    end

    klass.define_method('latest_version_for') do |method|
      method.define_argument('name')
    end

    klass.define_method('load_env_plugins')

    klass.define_method('load_path_insert_index')

    klass.define_method('load_plugin_files') do |method|
      method.define_argument('plugins')
    end

    klass.define_method('load_plugins')

    klass.define_method('load_yaml')

    klass.define_method('loaded_specs')

    klass.define_method('location_of_caller')

    klass.define_method('marshal_version')

    klass.define_method('needs')

    klass.define_method('path')

    klass.define_method('path_separator')

    klass.define_method('paths')

    klass.define_method('paths=') do |method|
      method.define_argument('env')
    end

    klass.define_method('platforms')

    klass.define_method('platforms=') do |method|
      method.define_argument('platforms')
    end

    klass.define_method('post_build') do |method|
      method.define_block_argument('hook')
    end

    klass.define_method('post_build_hooks')

    klass.define_method('post_install') do |method|
      method.define_block_argument('hook')
    end

    klass.define_method('post_install_hooks')

    klass.define_method('post_reset') do |method|
      method.define_block_argument('hook')
    end

    klass.define_method('post_reset_hooks')

    klass.define_method('post_uninstall') do |method|
      method.define_block_argument('hook')
    end

    klass.define_method('post_uninstall_hooks')

    klass.define_method('pre_install') do |method|
      method.define_block_argument('hook')
    end

    klass.define_method('pre_install_hooks')

    klass.define_method('pre_reset') do |method|
      method.define_block_argument('hook')
    end

    klass.define_method('pre_reset_hooks')

    klass.define_method('pre_uninstall') do |method|
      method.define_block_argument('hook')
    end

    klass.define_method('pre_uninstall_hooks')

    klass.define_method('prefix')

    klass.define_method('read_binary') do |method|
      method.define_argument('path')
    end

    klass.define_method('refresh')

    klass.define_method('register_default_spec') do |method|
      method.define_argument('spec')
    end

    klass.define_method('remove_unresolved_default_spec') do |method|
      method.define_argument('spec')
    end

    klass.define_method('ruby')

    klass.define_method('ruby_engine')

    klass.define_method('ruby_version')

    klass.define_method('rubygems_version')

    klass.define_method('sources')

    klass.define_method('sources=') do |method|
      method.define_argument('new_sources')
    end

    klass.define_method('spec_cache_dir')

    klass.define_method('suffix_pattern')

    klass.define_method('suffixes')

    klass.define_method('time') do |method|
      method.define_argument('msg')
      method.define_optional_argument('width')
      method.define_optional_argument('display')
    end

    klass.define_method('try_activate') do |method|
      method.define_argument('path')
    end

    klass.define_method('ui')

    klass.define_method('use_paths') do |method|
      method.define_argument('home')
      method.define_rest_argument('paths')
    end

    klass.define_method('user_dir')

    klass.define_method('user_home')

    klass.define_method('win_platform?')
  end

  defs.define_constant('Gem::BasicSpecification') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('default_specifications_dir')

    klass.define_instance_method('activated?')

    klass.define_instance_method('base_dir')

    klass.define_instance_method('contains_requirable_file?') do |method|
      method.define_argument('file')
    end

    klass.define_instance_method('default_gem?')

    klass.define_instance_method('full_gem_path')

    klass.define_instance_method('full_name')

    klass.define_instance_method('gems_dir')

    klass.define_instance_method('loaded_from')

    klass.define_instance_method('loaded_from=') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('platform')

    klass.define_instance_method('require_paths')

    klass.define_instance_method('to_spec')

    klass.define_instance_method('version')
  end

  defs.define_constant('Gem::CommandLineError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::ConfigFile') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::UserInteraction', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::DefaultUserInteraction', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('api_keys')

    klass.define_instance_method('args')

    klass.define_instance_method('backtrace')

    klass.define_instance_method('backtrace=')

    klass.define_instance_method('bulk_threshold')

    klass.define_instance_method('bulk_threshold=')

    klass.define_instance_method('check_credentials_permissions')

    klass.define_instance_method('config_file_name')

    klass.define_instance_method('credentials_path')

    klass.define_instance_method('disable_default_gem_server')

    klass.define_instance_method('disable_default_gem_server=')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('handle_arguments') do |method|
      method.define_argument('arg_list')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('home')

    klass.define_instance_method('home=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load_api_keys')

    klass.define_instance_method('load_file') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('path')

    klass.define_instance_method('path=')

    klass.define_instance_method('really_verbose')

    klass.define_instance_method('rubygems_api_key')

    klass.define_instance_method('rubygems_api_key=') do |method|
      method.define_argument('api_key')
    end

    klass.define_instance_method('ssl_ca_cert')

    klass.define_instance_method('ssl_client_cert')

    klass.define_instance_method('ssl_verify_mode')

    klass.define_instance_method('to_yaml')

    klass.define_instance_method('update_sources')

    klass.define_instance_method('update_sources=')

    klass.define_instance_method('verbose')

    klass.define_instance_method('verbose=')

    klass.define_instance_method('write')
  end

  defs.define_constant('Gem::ConfigFile::DEFAULT_BACKTRACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::ConfigFile::DEFAULT_BULK_THRESHOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::ConfigFile::DEFAULT_UPDATE_SOURCES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::ConfigFile::DEFAULT_VERBOSITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::ConfigFile::OPERATING_SYSTEM_DEFAULTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::ConfigFile::PLATFORM_DEFAULTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::ConfigFile::SYSTEM_WIDE_CONFIG_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::ConfigFile::YAMLErrors') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::ConfigMap') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::ConsoleUI') do |klass|
    klass.inherits(defs.constant_proxy('Gem::StreamUI', RubyLint.registry))

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Gem::ConsoleUI::SilentDownloadReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('done')

    klass.define_instance_method('fetch') do |method|
      method.define_argument('filename')
      method.define_argument('filesize')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('update') do |method|
      method.define_argument('current')
    end
  end

  defs.define_constant('Gem::ConsoleUI::SilentProgressReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('count')

    klass.define_instance_method('done')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_argument('size')
      method.define_argument('initial_message')
      method.define_optional_argument('terminal_message')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('Gem::ConsoleUI::SimpleProgressReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::DefaultUserInteraction', RubyLint.registry))

    klass.define_instance_method('count')

    klass.define_instance_method('done')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_argument('size')
      method.define_argument('initial_message')
      method.define_optional_argument('terminal_message')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('Gem::ConsoleUI::VerboseDownloadReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('done')

    klass.define_instance_method('fetch') do |method|
      method.define_argument('file_name')
      method.define_argument('total_bytes')
    end

    klass.define_instance_method('file_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('progress')

    klass.define_instance_method('total_bytes')

    klass.define_instance_method('update') do |method|
      method.define_argument('bytes')
    end
  end

  defs.define_constant('Gem::ConsoleUI::VerboseProgressReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::DefaultUserInteraction', RubyLint.registry))

    klass.define_instance_method('count')

    klass.define_instance_method('done')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_argument('size')
      method.define_argument('initial_message')
      method.define_optional_argument('terminal_message')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('Gem::DEFAULT_HOST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::DefaultUserInteraction') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('ui')

    klass.define_method('ui=') do |method|
      method.define_argument('new_ui')
    end

    klass.define_method('use_ui') do |method|
      method.define_argument('new_ui')
    end

    klass.define_instance_method('ui')

    klass.define_instance_method('ui=') do |method|
      method.define_argument('new_ui')
    end

    klass.define_instance_method('use_ui') do |method|
      method.define_argument('new_ui')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Gem::Dependency') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('=~') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('groups')

    klass.define_instance_method('groups=')

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_rest_argument('requirements')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('latest_version?')

    klass.define_instance_method('match?') do |method|
      method.define_argument('obj')
      method.define_optional_argument('version')
    end

    klass.define_instance_method('matches_spec?') do |method|
      method.define_argument('spec')
    end

    klass.define_instance_method('matching_specs') do |method|
      method.define_optional_argument('platform_only')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('prerelease=')

    klass.define_instance_method('prerelease?')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('requirement')

    klass.define_instance_method('requirements_list')

    klass.define_instance_method('source')

    klass.define_instance_method('source=')

    klass.define_instance_method('specific?')

    klass.define_instance_method('to_lock')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_spec')

    klass.define_instance_method('to_specs')

    klass.define_instance_method('to_yaml_properties')

    klass.define_instance_method('type')
  end

  defs.define_constant('Gem::Dependency::TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::DependencyError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::DependencyList') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('from_specs')

    klass.define_instance_method('add') do |method|
      method.define_rest_argument('gemspecs')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('dependency_order')

    klass.define_instance_method('development')

    klass.define_instance_method('development=')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_name') do |method|
      method.define_argument('full_name')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('development')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('ok?')

    klass.define_instance_method('ok_to_remove?') do |method|
      method.define_argument('full_name')
      method.define_optional_argument('check_dev')
    end

    klass.define_instance_method('remove_by_name') do |method|
      method.define_argument('full_name')
    end

    klass.define_instance_method('remove_specs_unsatisfied_by') do |method|
      method.define_argument('dependencies')
    end

    klass.define_instance_method('spec_predecessors')

    klass.define_instance_method('specs')

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('tsort_each_node') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('why_not_ok?') do |method|
      method.define_optional_argument('quick')
    end
  end

  defs.define_constant('Gem::DependencyList::Cyclic') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Gem::DependencyList::Enumerator') do |klass|
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

  defs.define_constant('Gem::DependencyList::SortedElement') do |klass|
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

  defs.define_constant('Gem::DependencyRemovalException') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::DependencyResolutionError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

    klass.define_instance_method('conflict')

    klass.define_instance_method('conflicting_dependencies')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('conflict')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gem::DependencyResolver') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('compose_sets') do |method|
      method.define_rest_argument('sets')
    end

    klass.define_method('for_current_gems') do |method|
      method.define_argument('needed')
    end

    klass.define_instance_method('conflicts')

    klass.define_instance_method('development')

    klass.define_instance_method('development=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('needed')
      method.define_optional_argument('set')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('missing')

    klass.define_instance_method('requests') do |method|
      method.define_argument('s')
      method.define_argument('act')
      method.define_optional_argument('reqs')
    end

    klass.define_instance_method('resolve')

    klass.define_instance_method('resolve_for') do |method|
      method.define_argument('needed')
      method.define_argument('specs')
    end

    klass.define_instance_method('select_local_platforms') do |method|
      method.define_argument('specs')
    end

    klass.define_instance_method('soft_missing')

    klass.define_instance_method('soft_missing=')
  end

  defs.define_constant('Gem::DependencyResolver::APISet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('find_all') do |method|
      method.define_argument('req')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('prefetch') do |method|
      method.define_argument('reqs')
    end

    klass.define_instance_method('versions') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('Gem::DependencyResolver::APISpecification') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('dependencies')

    klass.define_instance_method('full_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('set')
      method.define_argument('api_data')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('platform')

    klass.define_instance_method('set')

    klass.define_instance_method('version')
  end

  defs.define_constant('Gem::DependencyResolver::ActivationRequest') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('download') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('full_name')

    klass.define_instance_method('full_spec')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('spec')
      method.define_argument('req')
      method.define_optional_argument('others_possible')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('installed?')

    klass.define_instance_method('name')

    klass.define_instance_method('others_possible?')

    klass.define_instance_method('parent')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('request')

    klass.define_instance_method('spec')

    klass.define_instance_method('version')
  end

  defs.define_constant('Gem::DependencyResolver::ComposedSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('find_all') do |method|
      method.define_argument('req')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('sets')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('prefetch') do |method|
      method.define_argument('reqs')
    end
  end

  defs.define_constant('Gem::DependencyResolver::CurrentSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('find_all') do |method|
      method.define_argument('req')
    end

    klass.define_instance_method('prefetch') do |method|
      method.define_argument('gems')
    end
  end

  defs.define_constant('Gem::DependencyResolver::DependencyConflict') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('activated')

    klass.define_instance_method('conflicting_dependencies')

    klass.define_instance_method('dependency')

    klass.define_instance_method('explanation')

    klass.define_instance_method('for_spec?') do |method|
      method.define_argument('spec')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('dependency')
      method.define_argument('activated')
      method.define_optional_argument('failed_dep')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('request_path')

    klass.define_instance_method('requester')
  end

  defs.define_constant('Gem::DependencyResolver::DependencyRequest') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('dependency')

    klass.define_instance_method('explicit?')

    klass.define_instance_method('implicit?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('dep')
      method.define_argument('act')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('matches_spec?') do |method|
      method.define_argument('spec')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('request_context')

    klass.define_instance_method('requester')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Gem::DependencyResolver::IndexSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('find_all') do |method|
      method.define_argument('req')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('load_spec') do |method|
      method.define_argument('name')
      method.define_argument('ver')
      method.define_argument('platform')
      method.define_argument('source')
    end

    klass.define_instance_method('prefetch') do |method|
      method.define_argument('gems')
    end
  end

  defs.define_constant('Gem::DependencyResolver::IndexSpecification') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('dependencies')

    klass.define_instance_method('full_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('set')
      method.define_argument('name')
      method.define_argument('version')
      method.define_argument('source')
      method.define_argument('platform')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('name')

    klass.define_instance_method('platform')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('source')

    klass.define_instance_method('spec')

    klass.define_instance_method('version')
  end

  defs.define_constant('Gem::DependencyResolver::InstalledSpecification') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('dependencies')

    klass.define_instance_method('full_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('set')
      method.define_argument('spec')
      method.define_optional_argument('source')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('installable_platform?')

    klass.define_instance_method('name')

    klass.define_instance_method('platform')

    klass.define_instance_method('source')

    klass.define_instance_method('spec')

    klass.define_instance_method('version')
  end

  defs.define_constant('Gem::DependencyResolver::InstallerSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('always_install')

    klass.define_instance_method('consider_local?')

    klass.define_instance_method('consider_remote?')

    klass.define_instance_method('find_all') do |method|
      method.define_argument('req')
    end

    klass.define_instance_method('ignore_dependencies')

    klass.define_instance_method('ignore_dependencies=')

    klass.define_instance_method('ignore_installed')

    klass.define_instance_method('ignore_installed=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('domain')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('load_remote_specs') do |method|
      method.define_argument('dep')
    end

    klass.define_instance_method('load_spec') do |method|
      method.define_argument('name')
      method.define_argument('ver')
      method.define_argument('platform')
      method.define_argument('source')
    end

    klass.define_instance_method('prefetch') do |method|
      method.define_argument('reqs')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end
  end

  defs.define_constant('Gem::Deprecate') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('deprecate') do |method|
      method.define_argument('name')
      method.define_argument('repl')
      method.define_argument('year')
      method.define_argument('month')
    end

    klass.define_method('skip')

    klass.define_method('skip=') do |method|
      method.define_argument('v')
    end

    klass.define_method('skip_during')
  end

  defs.define_constant('Gem::DocumentError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::EndOfYAMLException') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::ErrorReason') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Exception') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

    klass.define_instance_method('source_exception')

    klass.define_instance_method('source_exception=')
  end

  defs.define_constant('Gem::FilePermissionError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

    klass.define_instance_method('directory')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('directory')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gem::FormatException') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

    klass.define_instance_method('file_path')

    klass.define_instance_method('file_path=')
  end

  defs.define_constant('Gem::GEM_DEP_FILES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::GEM_PRELUDE_SUCKAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::GemNotFoundException') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::GemNotInHomeException') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

    klass.define_instance_method('spec')

    klass.define_instance_method('spec=')
  end

  defs.define_constant('Gem::ImpossibleDependenciesError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

    klass.define_instance_method('build_message')

    klass.define_instance_method('conflicts')

    klass.define_instance_method('dependency')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('request')
      method.define_argument('conflicts')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('request')
  end

  defs.define_constant('Gem::InstallError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::InvalidSpecificationException') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::LoadError') do |klass|
    klass.inherits(defs.constant_proxy('LoadError', RubyLint.registry))

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('requirement')

    klass.define_instance_method('requirement=')
  end

  defs.define_constant('Gem::LoadError::InvalidExtensionError') do |klass|
    klass.inherits(defs.constant_proxy('LoadError', RubyLint.registry))

  end

  defs.define_constant('Gem::LoadError::MRIExtensionError') do |klass|
    klass.inherits(defs.constant_proxy('LoadError::InvalidExtensionError', RubyLint.registry))

  end

  defs.define_constant('Gem::MARSHAL_SPEC_DIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::OperationNotSupportedError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::PathSupport') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('home')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('env')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('path')

    klass.define_instance_method('spec_cache_dir')
  end

  defs.define_constant('Gem::Platform') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('installable?') do |method|
      method.define_argument('spec')
    end

    klass.define_method('local')

    klass.define_method('match') do |method|
      method.define_argument('platform')
    end

    klass.define_method('new') do |method|
      method.define_argument('arch')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('=~') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('cpu')

    klass.define_instance_method('cpu=')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('arch')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('os')

    klass.define_instance_method('os=')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')

    klass.define_instance_method('version')

    klass.define_instance_method('version=')
  end

  defs.define_constant('Gem::Platform::CURRENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Platform::JAVA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Platform::MINGW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Platform::MSWIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Platform::RUBY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::PlatformMismatch') do |klass|
    klass.inherits(defs.constant_proxy('Gem::ErrorReason', RubyLint.registry))

    klass.define_instance_method('add_platform') do |method|
      method.define_argument('platform')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('version')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('platforms')

    klass.define_instance_method('version')

    klass.define_instance_method('wordy')
  end

  defs.define_constant('Gem::REPOSITORY_DEFAULT_GEM_SUBDIRECTORIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::REPOSITORY_SUBDIRECTORIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::RUBYGEMS_DIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::RbConfigPriorities') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::RemoteError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::RemoteInstallationCancelled') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::RemoteInstallationSkipped') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::RemoteSourceException') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::RequestSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))

    klass.define_instance_method('always_install')

    klass.define_instance_method('dependencies')

    klass.define_instance_method('development')

    klass.define_instance_method('development=')

    klass.define_instance_method('gem') do |method|
      method.define_argument('name')
      method.define_rest_argument('reqs')
    end

    klass.define_instance_method('import') do |method|
      method.define_argument('deps')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('deps')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('install') do |method|
      method.define_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('install_into') do |method|
      method.define_argument('dir')
      method.define_optional_argument('force')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('load_gemdeps') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('resolve') do |method|
      method.define_optional_argument('set')
    end

    klass.define_instance_method('resolve_current')

    klass.define_instance_method('soft_missing')

    klass.define_instance_method('soft_missing=')

    klass.define_instance_method('sorted_requests')

    klass.define_instance_method('specs')

    klass.define_instance_method('specs_in') do |method|
      method.define_argument('dir')
    end

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('tsort_each_node') do |method|
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Gem::RequestSet::Cyclic') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Gem::RequestSet::GemDepedencyAPI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('gem') do |method|
      method.define_argument('name')
      method.define_rest_argument('reqs')
    end

    klass.define_instance_method('group') do |method|
      method.define_rest_argument('what')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('set')
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load')

    klass.define_instance_method('platform') do |method|
      method.define_argument('what')
    end

    klass.define_instance_method('platforms') do |method|
      method.define_argument('what')
    end

    klass.define_instance_method('source') do |method|
      method.define_argument('url')
    end
  end

  defs.define_constant('Gem::Requirement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('input')
    end

    klass.define_method('default')

    klass.define_method('parse') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('version')
    end

    klass.define_instance_method('=~') do |method|
      method.define_argument('version')
    end

    klass.define_instance_method('as_list')

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('init_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('requirements')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('array')
    end

    klass.define_instance_method('none?')

    klass.define_instance_method('prerelease?')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('requirements')

    klass.define_instance_method('satisfied_by?') do |method|
      method.define_argument('version')
    end

    klass.define_instance_method('specific?')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_yaml_properties')

    klass.define_instance_method('yaml_initialize') do |method|
      method.define_argument('tag')
      method.define_argument('vals')
    end
  end

  defs.define_constant('Gem::RubyGemsPackageVersion') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::RubyGemsVersion') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::SilentUI') do |klass|
    klass.inherits(defs.constant_proxy('Gem::StreamUI', RubyLint.registry))

    klass.define_instance_method('download_reporter') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('progress_reporter') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Gem::SilentUI::SilentDownloadReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('done')

    klass.define_instance_method('fetch') do |method|
      method.define_argument('filename')
      method.define_argument('filesize')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('update') do |method|
      method.define_argument('current')
    end
  end

  defs.define_constant('Gem::SilentUI::SilentProgressReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('count')

    klass.define_instance_method('done')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_argument('size')
      method.define_argument('initial_message')
      method.define_optional_argument('terminal_message')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('Gem::SilentUI::SimpleProgressReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::DefaultUserInteraction', RubyLint.registry))

    klass.define_instance_method('count')

    klass.define_instance_method('done')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_argument('size')
      method.define_argument('initial_message')
      method.define_optional_argument('terminal_message')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('Gem::SilentUI::VerboseDownloadReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('done')

    klass.define_instance_method('fetch') do |method|
      method.define_argument('file_name')
      method.define_argument('total_bytes')
    end

    klass.define_instance_method('file_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('progress')

    klass.define_instance_method('total_bytes')

    klass.define_instance_method('update') do |method|
      method.define_argument('bytes')
    end
  end

  defs.define_constant('Gem::SilentUI::VerboseProgressReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::DefaultUserInteraction', RubyLint.registry))

    klass.define_instance_method('count')

    klass.define_instance_method('done')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_argument('size')
      method.define_argument('initial_message')
      method.define_optional_argument('terminal_message')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('Gem::Source') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('api_uri')

    klass.define_instance_method('cache_dir') do |method|
      method.define_argument('uri')
    end

    klass.define_instance_method('download') do |method|
      method.define_argument('spec')
      method.define_optional_argument('dir')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('fetch_spec') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('uri')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load_specs') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('update_cache?')

    klass.define_instance_method('uri')
  end

  defs.define_constant('Gem::Source::FILES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Source::Installed') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Source', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('download') do |method|
      method.define_argument('spec')
      method.define_argument('path')
    end

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Gem::Source::Installed::FILES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Source::Installed::Local') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Source', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('download') do |method|
      method.define_argument('spec')
      method.define_optional_argument('cache_dir')
    end

    klass.define_instance_method('fetch_spec') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('find_gem') do |method|
      method.define_argument('gem_name')
      method.define_optional_argument('version')
      method.define_optional_argument('prerelease')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')

    klass.define_instance_method('load_specs') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end
  end

  defs.define_constant('Gem::Source::Installed::SpecificFile') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Source', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('download') do |method|
      method.define_argument('spec')
      method.define_optional_argument('dir')
    end

    klass.define_instance_method('fetch_spec') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('file')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load_specs') do |method|
      method.define_rest_argument('a')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('spec')
  end

  defs.define_constant('Gem::Source::Local') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Source', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('download') do |method|
      method.define_argument('spec')
      method.define_optional_argument('cache_dir')
    end

    klass.define_instance_method('fetch_spec') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('find_gem') do |method|
      method.define_argument('gem_name')
      method.define_optional_argument('version')
      method.define_optional_argument('prerelease')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')

    klass.define_instance_method('load_specs') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end
  end

  defs.define_constant('Gem::Source::SpecificFile') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Source', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('download') do |method|
      method.define_argument('spec')
      method.define_optional_argument('dir')
    end

    klass.define_instance_method('fetch_spec') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('file')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load_specs') do |method|
      method.define_rest_argument('a')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('spec')
  end

  defs.define_constant('Gem::SourceFetchProblem') do |klass|
    klass.inherits(defs.constant_proxy('Gem::ErrorReason', RubyLint.registry))

    klass.define_instance_method('error')

    klass.define_instance_method('exception')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('source')
      method.define_argument('error')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('source')

    klass.define_instance_method('wordy')
  end

  defs.define_constant('Gem::SourceList') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from') do |method|
      method.define_argument('ary')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('uri')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('each_source') do |method|
      method.define_block_argument('b')
    end

    klass.define_instance_method('first')

    klass.define_instance_method('include?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('replace') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('sources')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_ary')
  end

  defs.define_constant('Gem::SpecFetcher') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::Text', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::UserInteraction', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::DefaultUserInteraction', RubyLint.registry))

    klass.define_method('fetcher')

    klass.define_method('fetcher=') do |method|
      method.define_argument('fetcher')
    end

    klass.define_instance_method('available_specs') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('detect') do |method|
      method.define_optional_argument('type')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('latest_specs')

    klass.define_instance_method('prerelease_specs')

    klass.define_instance_method('search_for_dependency') do |method|
      method.define_argument('dependency')
      method.define_optional_argument('matching_platform')
    end

    klass.define_instance_method('spec_for_dependency') do |method|
      method.define_argument('dependency')
      method.define_optional_argument('matching_platform')
    end

    klass.define_instance_method('specs')

    klass.define_instance_method('suggest_gems_from_name') do |method|
      method.define_argument('gem_name')
    end

    klass.define_instance_method('tuples_for') do |method|
      method.define_argument('source')
      method.define_argument('type')
      method.define_optional_argument('gracefully_ignore')
    end
  end

  defs.define_constant('Gem::SpecificGemNotFoundException') do |klass|
    klass.inherits(defs.constant_proxy('Gem::GemNotFoundException', RubyLint.registry))

    klass.define_instance_method('errors')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('version')
      method.define_optional_argument('errors')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('version')
  end

  defs.define_constant('Gem::Specification') do |klass|
    klass.inherits(defs.constant_proxy('Gem::BasicSpecification', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Bundler::MatchPlatform', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Bundler::GemHelpers', RubyLint.registry))

    klass.define_method('_all')

    klass.define_method('_clear_load_cache')

    klass.define_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_method('_resort!') do |method|
      method.define_argument('specs')
    end

    klass.define_method('add_spec') do |method|
      method.define_argument('spec')
    end

    klass.define_method('add_specs') do |method|
      method.define_rest_argument('specs')
    end

    klass.define_method('all')

    klass.define_method('all=') do |method|
      method.define_argument('specs')
    end

    klass.define_method('all_names')

    klass.define_method('array_attributes')

    klass.define_method('attribute_names')

    klass.define_method('dirs')

    klass.define_method('dirs=') do |method|
      method.define_argument('dirs')
    end

    klass.define_method('each')

    klass.define_method('each_gemspec') do |method|
      method.define_argument('dirs')
    end

    klass.define_method('each_spec') do |method|
      method.define_argument('dirs')
    end

    klass.define_method('each_stub') do |method|
      method.define_argument('dirs')
    end

    klass.define_method('find_all_by_name') do |method|
      method.define_argument('name')
      method.define_rest_argument('requirements')
    end

    klass.define_method('find_by_name') do |method|
      method.define_argument('name')
      method.define_rest_argument('requirements')
    end

    klass.define_method('find_by_path') do |method|
      method.define_argument('path')
    end

    klass.define_method('find_in_unresolved') do |method|
      method.define_argument('path')
    end

    klass.define_method('find_in_unresolved_tree') do |method|
      method.define_argument('path')
    end

    klass.define_method('find_inactive_by_path') do |method|
      method.define_argument('path')
    end

    klass.define_method('from_yaml') do |method|
      method.define_argument('input')
    end

    klass.define_method('latest_specs') do |method|
      method.define_optional_argument('prerelease')
    end

    klass.define_method('load') do |method|
      method.define_argument('file')
    end

    klass.define_method('load_defaults')

    klass.define_method('non_nil_attributes')

    klass.define_method('normalize_yaml_input') do |method|
      method.define_argument('input')
    end

    klass.define_method('outdated')

    klass.define_method('outdated_and_latest_version')

    klass.define_method('remove_spec') do |method|
      method.define_argument('spec')
    end

    klass.define_method('required_attribute?') do |method|
      method.define_argument('name')
    end

    klass.define_method('required_attributes')

    klass.define_method('reset')

    klass.define_method('stubs')

    klass.define_method('unresolved_deps')

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_argument('limit')
    end

    klass.define_instance_method('activate')

    klass.define_instance_method('activate_dependencies')

    klass.define_instance_method('activated')

    klass.define_instance_method('activated=')

    klass.define_instance_method('activated?')

    klass.define_instance_method('add_bindir') do |method|
      method.define_argument('executables')
    end

    klass.define_instance_method('add_dependency') do |method|
      method.define_argument('gem')
      method.define_rest_argument('requirements')
    end

    klass.define_instance_method('add_development_dependency') do |method|
      method.define_argument('gem')
      method.define_rest_argument('requirements')
    end

    klass.define_instance_method('add_runtime_dependency') do |method|
      method.define_argument('gem')
      method.define_rest_argument('requirements')
    end

    klass.define_instance_method('add_self_to_load_path')

    klass.define_instance_method('author')

    klass.define_instance_method('author=') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('authors')

    klass.define_instance_method('authors=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('autorequire')

    klass.define_instance_method('autorequire=')

    klass.define_instance_method('bin_dir')

    klass.define_instance_method('bin_file') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('bindir')

    klass.define_instance_method('bindir=')

    klass.define_instance_method('build_args')

    klass.define_instance_method('build_info_dir')

    klass.define_instance_method('build_info_file')

    klass.define_instance_method('cache_dir')

    klass.define_instance_method('cache_file')

    klass.define_instance_method('cert_chain')

    klass.define_instance_method('cert_chain=')

    klass.define_instance_method('conflicts')

    klass.define_instance_method('date')

    klass.define_instance_method('date=') do |method|
      method.define_argument('date')
    end

    klass.define_instance_method('default_executable')

    klass.define_instance_method('default_executable=')

    klass.define_instance_method('default_value') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('dependencies')

    klass.define_instance_method('dependent_gems')

    klass.define_instance_method('dependent_specs')

    klass.define_instance_method('description')

    klass.define_instance_method('description=') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('development_dependencies')

    klass.define_instance_method('doc_dir') do |method|
      method.define_optional_argument('type')
    end

    klass.define_instance_method('email')

    klass.define_instance_method('email=')

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('executable')

    klass.define_instance_method('executable=') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('executables')

    klass.define_instance_method('executables=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('extensions')

    klass.define_instance_method('extensions=') do |method|
      method.define_argument('extensions')
    end

    klass.define_instance_method('extra_rdoc_files')

    klass.define_instance_method('extra_rdoc_files=') do |method|
      method.define_argument('files')
    end

    klass.define_instance_method('file_name')

    klass.define_instance_method('files')

    klass.define_instance_method('files=') do |method|
      method.define_argument('files')
    end

    klass.define_instance_method('for_cache')

    klass.define_instance_method('full_gem_path')

    klass.define_instance_method('full_name')

    klass.define_instance_method('gem_dir')

    klass.define_instance_method('git_version')

    klass.define_instance_method('groups')

    klass.define_instance_method('has_rdoc')

    klass.define_instance_method('has_rdoc=') do |method|
      method.define_argument('ignored')
    end

    klass.define_instance_method('has_rdoc?')

    klass.define_instance_method('has_test_suite?')

    klass.define_instance_method('has_unit_tests?')

    klass.define_instance_method('hash')

    klass.define_instance_method('homepage')

    klass.define_instance_method('homepage=')

    klass.define_instance_method('init_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('version')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('lib_dirs_glob')

    klass.define_instance_method('lib_files')

    klass.define_instance_method('license')

    klass.define_instance_method('license=') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('licenses')

    klass.define_instance_method('licenses=') do |method|
      method.define_argument('licenses')
    end

    klass.define_instance_method('load_paths')

    klass.define_instance_method('loaded_from')

    klass.define_instance_method('loaded_from=') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('location')

    klass.define_instance_method('location=')

    klass.define_instance_method('mark_version')

    klass.define_instance_method('matches_for_glob') do |method|
      method.define_argument('glob')
    end

    klass.define_instance_method('metadata')

    klass.define_instance_method('metadata=')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('sym')
      method.define_rest_argument('a')
      method.define_block_argument('b')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('name_tuple')

    klass.define_instance_method('nondevelopment_dependencies')

    klass.define_instance_method('normalize')

    klass.define_instance_method('original_name')

    klass.define_instance_method('original_platform')

    klass.define_instance_method('original_platform=')

    klass.define_instance_method('platform')

    klass.define_instance_method('platform=') do |method|
      method.define_argument('platform')
    end

    klass.define_instance_method('post_install_message')

    klass.define_instance_method('post_install_message=')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('raise_if_conflicts')

    klass.define_instance_method('rdoc_options')

    klass.define_instance_method('rdoc_options=') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('relative_loaded_from')

    klass.define_instance_method('relative_loaded_from=')

    klass.define_instance_method('require_path')

    klass.define_instance_method('require_path=') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('require_paths')

    klass.define_instance_method('require_paths=')

    klass.define_instance_method('required_ruby_version')

    klass.define_instance_method('required_ruby_version=') do |method|
      method.define_argument('req')
    end

    klass.define_instance_method('required_rubygems_version')

    klass.define_instance_method('required_rubygems_version=') do |method|
      method.define_argument('req')
    end

    klass.define_instance_method('requirements')

    klass.define_instance_method('requirements=') do |method|
      method.define_argument('req')
    end

    klass.define_instance_method('reset_nil_attributes_to_default')

    klass.define_instance_method('rg_full_gem_path')

    klass.define_instance_method('rg_loaded_from')

    klass.define_instance_method('ri_dir')

    klass.define_instance_method('rubyforge_project')

    klass.define_instance_method('rubyforge_project=')

    klass.define_instance_method('rubygems_version')

    klass.define_instance_method('rubygems_version=')

    klass.define_instance_method('runtime_dependencies')

    klass.define_instance_method('satisfies_requirement?') do |method|
      method.define_argument('dependency')
    end

    klass.define_instance_method('signing_key')

    klass.define_instance_method('signing_key=')

    klass.define_instance_method('sort_obj')

    klass.define_instance_method('source')

    klass.define_instance_method('source=')

    klass.define_instance_method('spec_dir')

    klass.define_instance_method('spec_file')

    klass.define_instance_method('spec_name')

    klass.define_instance_method('specification_version')

    klass.define_instance_method('specification_version=')

    klass.define_instance_method('summary')

    klass.define_instance_method('summary=') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('test_file')

    klass.define_instance_method('test_file=') do |method|
      method.define_argument('file')
    end

    klass.define_instance_method('test_files')

    klass.define_instance_method('test_files=') do |method|
      method.define_argument('files')
    end

    klass.define_instance_method('to_gemfile') do |method|
      method.define_optional_argument('path')
    end

    klass.define_instance_method('to_ruby')

    klass.define_instance_method('to_ruby_for_cache')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_spec')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('traverse') do |method|
      method.define_optional_argument('trail')
      method.define_block_argument('block')
    end

    klass.define_instance_method('validate') do |method|
      method.define_optional_argument('packaging')
    end

    klass.define_instance_method('validate_permissions')

    klass.define_instance_method('version')

    klass.define_instance_method('version=') do |method|
      method.define_argument('version')
    end

    klass.define_instance_method('yaml_initialize') do |method|
      method.define_argument('tag')
      method.define_argument('vals')
    end
  end

  defs.define_constant('Gem::Specification::CURRENT_SPECIFICATION_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Specification::DateTimeFormat') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Specification::Dupable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Specification::GENERICS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Specification::GENERIC_CACHE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Specification::MARSHAL_FIELDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Specification::NONEXISTENT_SPECIFICATION_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Specification::SPECIFICATION_VERSION_HISTORY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Specification::TODAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::StreamUI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('alert') do |method|
      method.define_argument('statement')
      method.define_optional_argument('question')
    end

    klass.define_instance_method('alert_error') do |method|
      method.define_argument('statement')
      method.define_optional_argument('question')
    end

    klass.define_instance_method('alert_warning') do |method|
      method.define_argument('statement')
      method.define_optional_argument('question')
    end

    klass.define_instance_method('ask') do |method|
      method.define_argument('question')
    end

    klass.define_instance_method('ask_for_password') do |method|
      method.define_argument('question')
    end

    klass.define_instance_method('ask_yes_no') do |method|
      method.define_argument('question')
      method.define_optional_argument('default')
    end

    klass.define_instance_method('backtrace') do |method|
      method.define_argument('exception')
    end

    klass.define_instance_method('choose_from_list') do |method|
      method.define_argument('question')
      method.define_argument('list')
    end

    klass.define_instance_method('debug') do |method|
      method.define_argument('statement')
    end

    klass.define_instance_method('download_reporter') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('errs')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('in_stream')
      method.define_argument('out_stream')
      method.define_optional_argument('err_stream')
      method.define_optional_argument('usetty')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('ins')

    klass.define_instance_method('outs')

    klass.define_instance_method('progress_reporter') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('say') do |method|
      method.define_optional_argument('statement')
    end

    klass.define_instance_method('terminate_interaction') do |method|
      method.define_optional_argument('status')
    end

    klass.define_instance_method('tty?')
  end

  defs.define_constant('Gem::StreamUI::SilentDownloadReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('done')

    klass.define_instance_method('fetch') do |method|
      method.define_argument('filename')
      method.define_argument('filesize')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('update') do |method|
      method.define_argument('current')
    end
  end

  defs.define_constant('Gem::StreamUI::SilentProgressReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('count')

    klass.define_instance_method('done')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_argument('size')
      method.define_argument('initial_message')
      method.define_optional_argument('terminal_message')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('Gem::StreamUI::SimpleProgressReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::DefaultUserInteraction', RubyLint.registry))

    klass.define_instance_method('count')

    klass.define_instance_method('done')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_argument('size')
      method.define_argument('initial_message')
      method.define_optional_argument('terminal_message')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('Gem::StreamUI::VerboseDownloadReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('done')

    klass.define_instance_method('fetch') do |method|
      method.define_argument('file_name')
      method.define_argument('total_bytes')
    end

    klass.define_instance_method('file_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('progress')

    klass.define_instance_method('total_bytes')

    klass.define_instance_method('update') do |method|
      method.define_argument('bytes')
    end
  end

  defs.define_constant('Gem::StreamUI::VerboseProgressReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gem::DefaultUserInteraction', RubyLint.registry))

    klass.define_instance_method('count')

    klass.define_instance_method('done')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('out_stream')
      method.define_argument('size')
      method.define_argument('initial_message')
      method.define_optional_argument('terminal_message')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_argument('message')
    end
  end

  defs.define_constant('Gem::StubSpecification') do |klass|
    klass.inherits(defs.constant_proxy('Gem::BasicSpecification', RubyLint.registry))

    klass.define_instance_method('activated?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('filename')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('platform')

    klass.define_instance_method('require_paths')

    klass.define_instance_method('to_spec')

    klass.define_instance_method('valid?')

    klass.define_instance_method('version')
  end

  defs.define_constant('Gem::StubSpecification::OPEN_MODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::StubSpecification::PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::StubSpecification::StubLine') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('data')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('parts')

    klass.define_instance_method('platform')

    klass.define_instance_method('require_paths')

    klass.define_instance_method('version')
  end

  defs.define_constant('Gem::SystemExitException') do |klass|
    klass.inherits(defs.constant_proxy('SystemExit', RubyLint.registry))

    klass.define_instance_method('exit_code')

    klass.define_instance_method('exit_code=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('exit_code')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gem::UnsatisfiableDepedencyError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

    klass.define_instance_method('dependency')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('dep')
      method.define_optional_argument('platform_mismatch')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gem::UnsatisfiableDependencyError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

    klass.define_instance_method('dependency')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('dep')
      method.define_optional_argument('platform_mismatch')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gem::UserInteraction') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('alert') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('alert_error') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('alert_warning') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('ask') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('ask_for_password') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('ask_yes_no') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('choose_from_list') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('say') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('terminate_interaction') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Gem::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::VerificationError') do |klass|
    klass.inherits(defs.constant_proxy('Gem::Exception', RubyLint.registry))

  end

  defs.define_constant('Gem::Version') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('correct?') do |method|
      method.define_argument('version')
    end

    klass.define_method('create') do |method|
      method.define_argument('input')
    end

    klass.define_method('new') do |method|
      method.define_argument('version')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('approximate_recommendation')

    klass.define_instance_method('bump')

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('init_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('version')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('array')
    end

    klass.define_instance_method('prerelease?')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('release')

    klass.define_instance_method('segments')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_yaml_properties')

    klass.define_instance_method('version')

    klass.define_instance_method('yaml_initialize') do |method|
      method.define_argument('tag')
      method.define_argument('map')
    end
  end

  defs.define_constant('Gem::Version::ANCHORED_VERSION_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::Version::Requirement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('create') do |method|
      method.define_argument('input')
    end

    klass.define_method('default')

    klass.define_method('parse') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('version')
    end

    klass.define_instance_method('=~') do |method|
      method.define_argument('version')
    end

    klass.define_instance_method('as_list')

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('init_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('requirements')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('array')
    end

    klass.define_instance_method('none?')

    klass.define_instance_method('prerelease?')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('requirements')

    klass.define_instance_method('satisfied_by?') do |method|
      method.define_argument('version')
    end

    klass.define_instance_method('specific?')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_yaml_properties')

    klass.define_instance_method('yaml_initialize') do |method|
      method.define_argument('tag')
      method.define_argument('vals')
    end
  end

  defs.define_constant('Gem::Version::VERSION_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gem::WIN_PATTERNS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
