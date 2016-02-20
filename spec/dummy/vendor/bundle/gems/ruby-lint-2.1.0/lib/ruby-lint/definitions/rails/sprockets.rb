# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('Sprockets') do |defs|
  defs.define_constant('Sprockets') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::ArgumentError') do |klass|
    klass.inherits(defs.constant_proxy('Sprockets::Error', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Asset') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from_hash') do |method|
      method.define_argument('environment')
      method.define_argument('hash')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('body')

    klass.define_instance_method('bytesize')

    klass.define_instance_method('content_type')

    klass.define_instance_method('dependencies')

    klass.define_instance_method('dependency_fresh?') do |method|
      method.define_argument('environment')
      method.define_argument('dep')
    end

    klass.define_instance_method('dependency_paths')

    klass.define_instance_method('digest')

    klass.define_instance_method('digest_path')

    klass.define_instance_method('each')

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('expand_root_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('fresh?') do |method|
      method.define_argument('environment')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('init_with') do |method|
      method.define_argument('environment')
      method.define_argument('coder')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('environment')
      method.define_argument('logical_path')
      method.define_argument('pathname')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('length')

    klass.define_instance_method('logical_path')

    klass.define_instance_method('mtime')

    klass.define_instance_method('pathname')

    klass.define_instance_method('relative_pathname')

    klass.define_instance_method('relativize_root_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('required_assets')

    klass.define_instance_method('stale?') do |method|
      method.define_argument('environment')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')

    klass.define_instance_method('write_to') do |method|
      method.define_argument('filename')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Sprockets::AssetAttributes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('content_type')

    klass.define_instance_method('engine_extensions')

    klass.define_instance_method('engines')

    klass.define_instance_method('environment')

    klass.define_instance_method('extensions')

    klass.define_instance_method('format_extension')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('environment')
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('logical_path')

    klass.define_instance_method('pathname')

    klass.define_instance_method('processors')

    klass.define_instance_method('search_paths')
  end

  defs.define_constant('Sprockets::Base') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Sprockets::Caching', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Sprockets::Paths', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Sprockets::Mime', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Sprockets::Processing', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Sprockets::Compressing', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Sprockets::Engines', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Sprockets::Server', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('append_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('attributes_for') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('build_asset') do |method|
      method.define_argument('logical_path')
      method.define_argument('pathname')
      method.define_argument('options')
    end

    klass.define_instance_method('cache')

    klass.define_instance_method('cache=') do |method|
      method.define_argument('cache')
    end

    klass.define_instance_method('cache_key_for') do |method|
      method.define_argument('path')
      method.define_argument('options')
    end

    klass.define_instance_method('circular_call_protection') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('clear_paths')

    klass.define_instance_method('content_type_of') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('context_class')

    klass.define_instance_method('default_external_encoding')

    klass.define_instance_method('default_external_encoding=')

    klass.define_instance_method('digest')

    klass.define_instance_method('digest_class')

    klass.define_instance_method('digest_class=') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('each_entry') do |method|
      method.define_argument('root')
      method.define_block_argument('block')
    end

    klass.define_instance_method('each_file')

    klass.define_instance_method('each_logical_path') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('entries') do |method|
      method.define_argument('pathname')
    end

    klass.define_instance_method('expire_index!')

    klass.define_instance_method('file_digest') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('find_asset') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('index')

    klass.define_instance_method('inspect')

    klass.define_instance_method('json_decode') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('logger=')

    klass.define_instance_method('logical_path_for_filename') do |method|
      method.define_argument('filename')
      method.define_argument('filters')
    end

    klass.define_instance_method('matches_filter') do |method|
      method.define_argument('filters')
      method.define_argument('logical_path')
      method.define_argument('filename')
    end

    klass.define_instance_method('prepend_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('register_bundle_processor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
      method.define_block_argument('block')
    end

    klass.define_instance_method('register_engine') do |method|
      method.define_argument('ext')
      method.define_argument('klass')
    end

    klass.define_instance_method('register_mime_type') do |method|
      method.define_argument('mime_type')
      method.define_argument('ext')
    end

    klass.define_instance_method('register_postprocessor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
      method.define_block_argument('block')
    end

    klass.define_instance_method('register_preprocessor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
      method.define_block_argument('block')
    end

    klass.define_instance_method('resolve') do |method|
      method.define_argument('logical_path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('stat') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('unregister_bundle_processor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
    end

    klass.define_instance_method('unregister_postprocessor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
    end

    klass.define_instance_method('unregister_preprocessor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
    end

    klass.define_instance_method('version')

    klass.define_instance_method('version=') do |method|
      method.define_argument('version')
    end
  end

  defs.define_constant('Sprockets::BundledAsset') do |klass|
    klass.inherits(defs.constant_proxy('Sprockets::Asset', RubyLint.registry))

    klass.define_instance_method('body')

    klass.define_instance_method('dependencies')

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('fresh?') do |method|
      method.define_argument('environment')
    end

    klass.define_instance_method('init_with') do |method|
      method.define_argument('environment')
      method.define_argument('coder')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('environment')
      method.define_argument('logical_path')
      method.define_argument('pathname')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('source')

    klass.define_instance_method('to_a')
  end

  defs.define_constant('Sprockets::Cache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Cache::FileStore') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('root')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Sprockets::CharsetNormalizer') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('context')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('prepare')
  end

  defs.define_constant('Sprockets::CircularDependencyError') do |klass|
    klass.inherits(defs.constant_proxy('Sprockets::Error', RubyLint.registry))

  end

  defs.define_constant('Sprockets::ClosureCompressor') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_method('engine_initialized?')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('context')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize_engine')

    klass.define_instance_method('prepare')
  end

  defs.define_constant('Sprockets::Compressing') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('compressors')

    klass.define_instance_method('css_compressor')

    klass.define_instance_method('css_compressor=') do |method|
      method.define_argument('compressor')
    end

    klass.define_instance_method('js_compressor')

    klass.define_instance_method('js_compressor=') do |method|
      method.define_argument('compressor')
    end

    klass.define_instance_method('register_compressor') do |method|
      method.define_argument('mime_type')
      method.define_argument('sym')
      method.define_argument('klass')
    end
  end

  defs.define_constant('Sprockets::ContentTypeMismatch') do |klass|
    klass.inherits(defs.constant_proxy('Sprockets::Error', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Context') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__LINE__=')

    klass.define_instance_method('_dependency_assets')

    klass.define_instance_method('_dependency_paths')

    klass.define_instance_method('_required_paths')

    klass.define_instance_method('_stubbed_assets')

    klass.define_instance_method('asset_data_uri') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('asset_path') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('asset_requirable?') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('audio_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('content_type')

    klass.define_instance_method('depend_on') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('depend_on_asset') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('environment')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('font_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('image_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('environment')
      method.define_argument('logical_path')
      method.define_argument('pathname')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('javascript_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('logical_path')

    klass.define_instance_method('pathname')

    klass.define_instance_method('require_asset') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('resolve') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('root_path')

    klass.define_instance_method('stub_asset') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('stylesheet_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('video_path') do |method|
      method.define_argument('path')
    end
  end

  defs.define_constant('Sprockets::DirectiveProcessor') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_instance_method('body')

    klass.define_instance_method('compat?')

    klass.define_instance_method('constants')

    klass.define_instance_method('context')

    klass.define_instance_method('directives')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('context')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('header')

    klass.define_instance_method('included_pathnames')

    klass.define_instance_method('pathname')

    klass.define_instance_method('prepare')

    klass.define_instance_method('process_compat_directive')

    klass.define_instance_method('process_depend_on_asset_directive') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('process_depend_on_directive') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('process_directives')

    klass.define_instance_method('process_include_directive') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('process_provide_directive') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('process_require_directive') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('process_require_directory_directive') do |method|
      method.define_optional_argument('path')
    end

    klass.define_instance_method('process_require_self_directive')

    klass.define_instance_method('process_require_tree_directive') do |method|
      method.define_optional_argument('path')
    end

    klass.define_instance_method('process_source')

    klass.define_instance_method('process_stub_directive') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('processed_header')

    klass.define_instance_method('processed_source')
  end

  defs.define_constant('Sprockets::DirectiveProcessor::DIRECTIVE_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::DirectiveProcessor::HEADER_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::EcoTemplate') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_method('engine_initialized?')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('scope')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize_engine')

    klass.define_instance_method('prepare')
  end

  defs.define_constant('Sprockets::EjsTemplate') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_method('engine_initialized?')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('scope')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize_engine')

    klass.define_instance_method('prepare')
  end

  defs.define_constant('Sprockets::EngineError') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('message')

    klass.define_instance_method('sprockets_annotation')

    klass.define_instance_method('sprockets_annotation=')
  end

  defs.define_constant('Sprockets::Engines') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('engine_extensions')

    klass.define_instance_method('engines') do |method|
      method.define_optional_argument('ext')
    end

    klass.define_instance_method('register_engine') do |method|
      method.define_argument('ext')
      method.define_argument('klass')
    end
  end

  defs.define_constant('Sprockets::Environment') do |klass|
    klass.inherits(defs.constant_proxy('Sprockets::Base', RubyLint.registry))

    klass.define_instance_method('expire_index!')

    klass.define_instance_method('find_asset') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('index')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('root')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Sprockets::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Sprockets::FileNotFound') do |klass|
    klass.inherits(defs.constant_proxy('Sprockets::Error', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Index') do |klass|
    klass.inherits(defs.constant_proxy('Sprockets::Base', RubyLint.registry))

    klass.define_instance_method('build_asset') do |method|
      method.define_argument('path')
      method.define_argument('pathname')
      method.define_argument('options')
    end

    klass.define_instance_method('expire_index!')

    klass.define_instance_method('file_digest') do |method|
      method.define_argument('pathname')
    end

    klass.define_instance_method('find_asset') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('index')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('environment')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Sprockets::JstProcessor') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_method('default_namespace')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('scope')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('namespace')

    klass.define_instance_method('prepare')
  end

  defs.define_constant('Sprockets::Manifest') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assets')

    klass.define_instance_method('backups_for') do |method|
      method.define_argument('logical_path')
    end

    klass.define_instance_method('clean') do |method|
      method.define_optional_argument('keep')
    end

    klass.define_instance_method('clobber')

    klass.define_instance_method('compile') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('dir')

    klass.define_instance_method('environment')

    klass.define_instance_method('files')

    klass.define_instance_method('find_asset') do |method|
      method.define_argument('logical_path')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('path')

    klass.define_instance_method('remove') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('save')
  end

  defs.define_constant('Sprockets::Mime') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('encoding_for_mime_type') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('extension_for_mime_type') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('mime_types') do |method|
      method.define_optional_argument('ext')
    end

    klass.define_instance_method('register_mime_type') do |method|
      method.define_argument('mime_type')
      method.define_argument('ext')
    end

    klass.define_instance_method('registered_mime_types')
  end

  defs.define_constant('Sprockets::Paths') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('append_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('clear_paths')

    klass.define_instance_method('extensions')

    klass.define_instance_method('paths')

    klass.define_instance_method('prepend_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('root')

    klass.define_instance_method('trail')
  end

  defs.define_constant('Sprockets::ProcessedAsset') do |klass|
    klass.inherits(defs.constant_proxy('Sprockets::Asset', RubyLint.registry))

    klass.define_instance_method('dependency_digest')

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('fresh?') do |method|
      method.define_argument('environment')
    end

    klass.define_instance_method('init_with') do |method|
      method.define_argument('environment')
      method.define_argument('coder')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('environment')
      method.define_argument('logical_path')
      method.define_argument('pathname')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('source')
  end

  defs.define_constant('Sprockets::ProcessedAsset::DependencyFile') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('pathname')
      method.define_argument('mtime')
      method.define_argument('digest')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Sprockets::ProcessedAsset::DependencyFile::Enumerator') do |klass|
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

  defs.define_constant('Sprockets::ProcessedAsset::DependencyFile::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Sprockets::ProcessedAsset::DependencyFile::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Sprockets::ProcessedAsset::DependencyFile::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::ProcessedAsset::DependencyFile::SortedElement') do |klass|
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

  defs.define_constant('Sprockets::ProcessedAsset::DependencyFile::Tms') do |klass|
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

  defs.define_constant('Sprockets::Processing') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('bundle_processors') do |method|
      method.define_optional_argument('mime_type')
    end

    klass.define_instance_method('format_extensions')

    klass.define_instance_method('postprocessors') do |method|
      method.define_optional_argument('mime_type')
    end

    klass.define_instance_method('preprocessors') do |method|
      method.define_optional_argument('mime_type')
    end

    klass.define_instance_method('processors') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('register_bundle_processor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
      method.define_block_argument('block')
    end

    klass.define_instance_method('register_postprocessor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
      method.define_block_argument('block')
    end

    klass.define_instance_method('register_preprocessor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
      method.define_block_argument('block')
    end

    klass.define_instance_method('register_processor') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('unregister_bundle_processor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
    end

    klass.define_instance_method('unregister_postprocessor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
    end

    klass.define_instance_method('unregister_preprocessor') do |method|
      method.define_argument('mime_type')
      method.define_argument('klass')
    end

    klass.define_instance_method('unregister_processor') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Sprockets::Processor') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_method('name')

    klass.define_method('processor')

    klass.define_method('to_s')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('context')
      method.define_argument('locals')
    end

    klass.define_instance_method('prepare')
  end

  defs.define_constant('Sprockets::Rails') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Rails::Helper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('extended') do |method|
      method.define_argument('obj')
    end

    klass.define_method('included') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('asset_digest') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('asset_digest_path') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('compute_asset_path') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('javascript_include_tag') do |method|
      method.define_rest_argument('sources')
    end

    klass.define_instance_method('lookup_asset_for_path') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('request_debug_assets?')

    klass.define_instance_method('stylesheet_link_tag') do |method|
      method.define_rest_argument('sources')
    end
  end

  defs.define_constant('Sprockets::Rails::Helper::ASSET_EXTENSIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Rails::Helper::ASSET_PUBLIC_DIRECTORIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Rails::Helper::BOOLEAN_ATTRIBUTES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Rails::Helper::PRE_CONTENT_STRINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Rails::Helper::URI_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Rails::Helper::VIEW_ACCESSORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Railtie') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configurable', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Railtie::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Railtie::ClassMethods') do |klass|
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

  defs.define_constant('Sprockets::Railtie::Collection') do |klass|
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

  defs.define_constant('Sprockets::Railtie::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Railtie::Configuration') do |klass|
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

  defs.define_constant('Sprockets::Railtie::Initializer') do |klass|
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

  defs.define_constant('Sprockets::Railtie::LOOSE_APP_ASSETS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Railtie::OrderedOptions') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::OrderedOptions', RubyLint.registry))

    klass.define_instance_method('configure') do |method|
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Sprockets::Railtie::OrderedOptions::Bucket') do |klass|
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

  defs.define_constant('Sprockets::Railtie::OrderedOptions::Entries') do |klass|
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

  defs.define_constant('Sprockets::Railtie::OrderedOptions::Enumerator') do |klass|
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

  defs.define_constant('Sprockets::Railtie::OrderedOptions::Iterator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next') do |method|
      method.define_argument('item')
    end
  end

  defs.define_constant('Sprockets::Railtie::OrderedOptions::MAX_ENTRIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Railtie::OrderedOptions::MIN_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::Railtie::OrderedOptions::SortedElement') do |klass|
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

  defs.define_constant('Sprockets::Railtie::OrderedOptions::State') do |klass|
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

  defs.define_constant('Sprockets::SafetyColons') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('context')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('prepare')
  end

  defs.define_constant('Sprockets::SassCompressor') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_method('engine_initialized?')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('context')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize_engine')

    klass.define_instance_method('prepare')
  end

  defs.define_constant('Sprockets::SassTemplate') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_method('engine_initialized?')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('context')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize_engine')

    klass.define_instance_method('prepare')

    klass.define_instance_method('syntax')
  end

  defs.define_constant('Sprockets::ScssTemplate') do |klass|
    klass.inherits(defs.constant_proxy('Sprockets::SassTemplate', RubyLint.registry))

    klass.define_instance_method('syntax')
  end

  defs.define_constant('Sprockets::StaticAsset') do |klass|
    klass.inherits(defs.constant_proxy('Sprockets::Asset', RubyLint.registry))

    klass.define_instance_method('source')

    klass.define_instance_method('to_path')

    klass.define_instance_method('write_to') do |method|
      method.define_argument('filename')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Sprockets::UglifierCompressor') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_method('engine_initialized?')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('context')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize_engine')

    klass.define_instance_method('prepare')
  end

  defs.define_constant('Sprockets::Utils') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('normalize_extension') do |method|
      method.define_argument('extension')
    end

    klass.define_method('read_unicode') do |method|
      method.define_argument('pathname')
      method.define_optional_argument('external_encoding')
    end
  end

  defs.define_constant('Sprockets::Utils::UTF8_BOM_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Sprockets::YUICompressor') do |klass|
    klass.inherits(defs.constant_proxy('Tilt::Template', RubyLint.registry))

    klass.define_method('engine_initialized?')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('context')
      method.define_argument('locals')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize_engine')

    klass.define_instance_method('prepare')
  end
end
