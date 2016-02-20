# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('IRB') do |defs|
  defs.define_constant('IRB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('CurrentContext')

    klass.define_method('Inspector') do |method|
      method.define_argument('inspect')
      method.define_optional_argument('init')
    end

    klass.define_method('conf')

    klass.define_method('delete_caller')

    klass.define_method('init_config') do |method|
      method.define_argument('ap_path')
    end

    klass.define_method('init_error')

    klass.define_method('irb_abort') do |method|
      method.define_argument('irb')
      method.define_optional_argument('exception')
    end

    klass.define_method('irb_at_exit')

    klass.define_method('irb_exit') do |method|
      method.define_argument('irb')
      method.define_argument('ret')
    end

    klass.define_method('load_modules')

    klass.define_method('parse_opts')

    klass.define_method('rc_file') do |method|
      method.define_optional_argument('ext')
    end

    klass.define_method('rc_file_generators')

    klass.define_method('run_config')

    klass.define_method('setup') do |method|
      method.define_argument('ap_path')
    end

    klass.define_method('start') do |method|
      method.define_optional_argument('ap_path')
    end

    klass.define_method('version')
  end

  defs.define_constant('IRB::Abort') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

  end

  defs.define_constant('IRB::Context') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__inspect__')

    klass.define_instance_method('__to_s__')

    klass.define_instance_method('ap_name')

    klass.define_instance_method('ap_name=')

    klass.define_instance_method('auto_indent_mode')

    klass.define_instance_method('auto_indent_mode=')

    klass.define_instance_method('back_trace_limit')

    klass.define_instance_method('back_trace_limit=')

    klass.define_instance_method('debug?')

    klass.define_instance_method('debug_level')

    klass.define_instance_method('debug_level=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('echo')

    klass.define_instance_method('echo=')

    klass.define_instance_method('echo?')

    klass.define_instance_method('eval_history=') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('line')
      method.define_argument('line_no')
    end

    klass.define_instance_method('exit') do |method|
      method.define_optional_argument('ret')
    end

    klass.define_instance_method('file_input?')

    klass.define_instance_method('ignore_eof')

    klass.define_instance_method('ignore_eof=')

    klass.define_instance_method('ignore_eof?')

    klass.define_instance_method('ignore_sigint')

    klass.define_instance_method('ignore_sigint=')

    klass.define_instance_method('ignore_sigint?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('irb')
      method.define_optional_argument('workspace')
      method.define_optional_argument('input_method')
      method.define_optional_argument('output_method')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('inspect?')

    klass.define_instance_method('inspect_last_value')

    klass.define_instance_method('inspect_mode')

    klass.define_instance_method('inspect_mode=') do |method|
      method.define_argument('opt')
    end

    klass.define_instance_method('io')

    klass.define_instance_method('io=')

    klass.define_instance_method('irb')

    klass.define_instance_method('irb=')

    klass.define_instance_method('irb_name')

    klass.define_instance_method('irb_name=')

    klass.define_instance_method('irb_path')

    klass.define_instance_method('irb_path=')

    klass.define_instance_method('last_value')

    klass.define_instance_method('load_modules')

    klass.define_instance_method('load_modules=')

    klass.define_instance_method('main')

    klass.define_instance_method('math_mode=') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('prompt_c')

    klass.define_instance_method('prompt_c=')

    klass.define_instance_method('prompt_i')

    klass.define_instance_method('prompt_i=')

    klass.define_instance_method('prompt_mode')

    klass.define_instance_method('prompt_mode=') do |method|
      method.define_argument('mode')
    end

    klass.define_instance_method('prompt_n')

    klass.define_instance_method('prompt_n=')

    klass.define_instance_method('prompt_s')

    klass.define_instance_method('prompt_s=')

    klass.define_instance_method('prompting?')

    klass.define_instance_method('rc')

    klass.define_instance_method('rc=')

    klass.define_instance_method('rc?')

    klass.define_instance_method('return_format')

    klass.define_instance_method('return_format=')

    klass.define_instance_method('save_history=') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('set_last_value') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('thread')

    klass.define_instance_method('to_s')

    klass.define_instance_method('use_loader=') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('use_readline')

    klass.define_instance_method('use_readline=') do |method|
      method.define_argument('opt')
    end

    klass.define_instance_method('use_readline?')

    klass.define_instance_method('use_tracer=') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('verbose')

    klass.define_instance_method('verbose=')

    klass.define_instance_method('verbose?')

    klass.define_instance_method('workspace')

    klass.define_instance_method('workspace=')

    klass.define_instance_method('workspace_home')
  end

  defs.define_constant('IRB::Context::IDNAME_IVARS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::Context::NOPRINTING_IVARS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::Context::NO_INSPECTING_IVARS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::ContextExtender') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('def_extend_command') do |method|
      method.define_argument('cmd_name')
      method.define_argument('load_file')
      method.define_rest_argument('aliases')
    end

    klass.define_method('install_extend_commands')
  end

  defs.define_constant('IRB::DefaultEncodings') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('external')

    klass.define_instance_method('external=')

    klass.define_instance_method('internal')

    klass.define_instance_method('internal=')
  end

  defs.define_constant('IRB::DefaultEncodings::Enumerator') do |klass|
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

  defs.define_constant('IRB::DefaultEncodings::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('IRB::DefaultEncodings::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('IRB::DefaultEncodings::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::DefaultEncodings::SortedElement') do |klass|
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

  defs.define_constant('IRB::DefaultEncodings::Tms') do |klass|
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

  defs.define_constant('IRB::ExtendCommandBundle') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('def_extend_command') do |method|
      method.define_argument('cmd_name')
      method.define_argument('cmd_class')
      method.define_optional_argument('load_file')
      method.define_rest_argument('aliases')
    end

    klass.define_method('extend_object') do |method|
      method.define_argument('obj')
    end

    klass.define_method('install_extend_commands')

    klass.define_method('irb_original_method_name') do |method|
      method.define_argument('method_name')
    end

    klass.define_instance_method('install_alias_method') do |method|
      method.define_argument('to')
      method.define_argument('from')
      method.define_optional_argument('override')
    end

    klass.define_instance_method('irb') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_change_workspace') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_context')

    klass.define_instance_method('irb_current_working_workspace') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_exit') do |method|
      method.define_optional_argument('ret')
    end

    klass.define_instance_method('irb_fg') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_help') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_jobs') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_kill') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_load') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_pop_workspace') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_push_workspace') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_require') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_source') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('irb_workspaces') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end
  end

  defs.define_constant('IRB::ExtendCommandBundle::NO_OVERRIDE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::ExtendCommandBundle::OVERRIDE_ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::ExtendCommandBundle::OVERRIDE_PRIVATE_ONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::FEATURE_IOPT_CHANGE_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::FileInputMethod') do |klass|
    klass.inherits(defs.constant_proxy('IRB::InputMethod', RubyLint.registry))

    klass.define_instance_method('encoding')

    klass.define_instance_method('eof?')

    klass.define_instance_method('file_name')

    klass.define_instance_method('gets')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('file')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('IRB::IRBRC_EXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::InputMethod') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('file_name')

    klass.define_instance_method('gets')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('file')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('prompt')

    klass.define_instance_method('prompt=')

    klass.define_instance_method('readable_after_eof?')
  end

  defs.define_constant('IRB::Inspector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('def_inspector') do |method|
      method.define_argument('key')
      method.define_optional_argument('arg')
      method.define_block_argument('block')
    end

    klass.define_method('keys_with_inspector') do |method|
      method.define_argument('inspector')
    end

    klass.define_instance_method('init')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('inspect_proc')
      method.define_optional_argument('init_proc')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect_value') do |method|
      method.define_argument('v')
    end
  end

  defs.define_constant('IRB::Inspector::INSPECTORS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::Irb') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('context')

    klass.define_instance_method('eval_input')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('workspace')
      method.define_optional_argument('input_method')
      method.define_optional_argument('output_method')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('output_value')

    klass.define_instance_method('prompt') do |method|
      method.define_argument('prompt')
      method.define_argument('ltype')
      method.define_argument('indent')
      method.define_argument('line_no')
    end

    klass.define_instance_method('scanner')

    klass.define_instance_method('scanner=')

    klass.define_instance_method('signal_handle')

    klass.define_instance_method('signal_status') do |method|
      method.define_argument('status')
    end

    klass.define_instance_method('suspend_context') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('suspend_input_method') do |method|
      method.define_argument('input_method')
    end

    klass.define_instance_method('suspend_name') do |method|
      method.define_optional_argument('path')
      method.define_optional_argument('name')
    end

    klass.define_instance_method('suspend_workspace') do |method|
      method.define_argument('workspace')
    end
  end

  defs.define_constant('IRB::Locale') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('String') do |method|
      method.define_argument('mes')
    end

    klass.define_instance_method('encoding')

    klass.define_instance_method('find') do |method|
      method.define_argument('file')
      method.define_optional_argument('paths')
    end

    klass.define_instance_method('format') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('gets') do |method|
      method.define_rest_argument('rs')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('locale')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lang')

    klass.define_instance_method('load') do |method|
      method.define_argument('file')
      method.define_optional_argument('priv')
    end

    klass.define_instance_method('modifieer')

    klass.define_instance_method('print') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('printf') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('puts') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('readline') do |method|
      method.define_rest_argument('rs')
    end

    klass.define_instance_method('require') do |method|
      method.define_argument('file')
      method.define_optional_argument('priv')
    end

    klass.define_instance_method('territory')
  end

  defs.define_constant('IRB::Locale::LOCALE_DIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::Locale::LOCALE_NAME_RE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::MagicFile') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('open') do |method|
      method.define_argument('path')
    end
  end

  defs.define_constant('IRB::MethodExtender') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('def_post_proc') do |method|
      method.define_argument('base_method')
      method.define_argument('extend_method')
    end

    klass.define_instance_method('def_pre_proc') do |method|
      method.define_argument('base_method')
      method.define_argument('extend_method')
    end

    klass.define_instance_method('new_alias_name') do |method|
      method.define_argument('name')
      method.define_optional_argument('prefix')
      method.define_optional_argument('postfix')
    end
  end

  defs.define_constant('IRB::Notifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('def_notifier') do |method|
      method.define_optional_argument('prefix')
      method.define_optional_argument('output_method')
    end

    klass.define_method('included') do |method|
      method.define_argument('mod')
    end

    klass.define_instance_method('Fail') do |method|
      method.define_optional_argument('err')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('Raise') do |method|
      method.define_optional_argument('err')
      method.define_rest_argument('rest')
    end
  end

  defs.define_constant('IRB::Notifier::AbstractNotifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('exec_if')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('prefix')
      method.define_argument('base_notifier')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('notify?')

    klass.define_instance_method('pp') do |method|
      method.define_rest_argument('objs')
    end

    klass.define_instance_method('ppx') do |method|
      method.define_argument('prefix')
      method.define_rest_argument('objs')
    end

    klass.define_instance_method('prefix')

    klass.define_instance_method('print') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('printf') do |method|
      method.define_argument('format')
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('printn') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('puts') do |method|
      method.define_rest_argument('objs')
    end
  end

  defs.define_constant('IRB::Notifier::CompositeNotifier') do |klass|
    klass.inherits(defs.constant_proxy('IRB::Notifier::AbstractNotifier', RubyLint.registry))

    klass.define_instance_method('def_notifier') do |method|
      method.define_argument('level')
      method.define_optional_argument('prefix')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('prefix')
      method.define_argument('base_notifier')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('level')

    klass.define_instance_method('level=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('level_notifier')

    klass.define_instance_method('level_notifier=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('notifiers')
  end

  defs.define_constant('IRB::Notifier::D_NOMSG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::Notifier::ErrUndefinedNotifier') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('IRB::Notifier::ErrUnrecognizedLevel') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('IRB::Notifier::LeveledNotifier') do |klass|
    klass.inherits(defs.constant_proxy('IRB::Notifier::AbstractNotifier', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('level')
      method.define_argument('prefix')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('level')

    klass.define_instance_method('notify?')
  end

  defs.define_constant('IRB::Notifier::NoMsgNotifier') do |klass|
    klass.inherits(defs.constant_proxy('IRB::Notifier::LeveledNotifier', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('notify?')
  end

  defs.define_constant('IRB::OutputMethod') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('mod')
    end

    klass.define_instance_method('Fail') do |method|
      method.define_optional_argument('err')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('Raise') do |method|
      method.define_optional_argument('err')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('parse_printf_format') do |method|
      method.define_argument('format')
      method.define_argument('opts')
    end

    klass.define_instance_method('pp') do |method|
      method.define_rest_argument('objs')
    end

    klass.define_instance_method('ppx') do |method|
      method.define_argument('prefix')
      method.define_rest_argument('objs')
    end

    klass.define_instance_method('print') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('printf') do |method|
      method.define_argument('format')
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('printn') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('puts') do |method|
      method.define_rest_argument('objs')
    end
  end

  defs.define_constant('IRB::OutputMethod::NotImplementedError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('IRB::ReadlineInputMethod') do |klass|
    klass.inherits(defs.constant_proxy('IRB::InputMethod', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Readline', RubyLint.registry))

    klass.define_instance_method('encoding')

    klass.define_instance_method('eof?')

    klass.define_instance_method('gets')

    klass.define_instance_method('initialize')

    klass.define_instance_method('line') do |method|
      method.define_argument('line_no')
    end

    klass.define_instance_method('readable_after_eof?')
  end

  defs.define_constant('IRB::ReadlineInputMethod::FILENAME_COMPLETION_PROC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('call')
  end

  defs.define_constant('IRB::ReadlineInputMethod::HISTORY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('<<')

    klass.define_method('[]')

    klass.define_method('[]=')

    klass.define_method('clear')

    klass.define_method('delete_at')

    klass.define_method('each')

    klass.define_method('empty?')

    klass.define_method('length')

    klass.define_method('pop')

    klass.define_method('push')

    klass.define_method('shift')

    klass.define_method('size')

    klass.define_method('to_s')
  end

  defs.define_constant('IRB::ReadlineInputMethod::USERNAME_COMPLETION_PROC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('call')
  end

  defs.define_constant('IRB::ReadlineInputMethod::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::SLex') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('mod')
    end

    klass.define_instance_method('Fail') do |method|
      method.define_optional_argument('err')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('Raise') do |method|
      method.define_optional_argument('err')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('create') do |method|
      method.define_argument('token')
      method.define_optional_argument('preproc')
      method.define_optional_argument('postproc')
    end

    klass.define_instance_method('def_rule') do |method|
      method.define_argument('token')
      method.define_optional_argument('preproc')
      method.define_optional_argument('postproc')
      method.define_block_argument('block')
    end

    klass.define_instance_method('def_rules') do |method|
      method.define_rest_argument('tokens')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')

    klass.define_instance_method('match') do |method|
      method.define_argument('token')
    end

    klass.define_instance_method('postproc') do |method|
      method.define_argument('token')
    end

    klass.define_instance_method('preproc') do |method|
      method.define_argument('token')
      method.define_argument('proc')
    end

    klass.define_instance_method('search') do |method|
      method.define_argument('token')
    end
  end

  defs.define_constant('IRB::SLex::DOUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::SLex::D_DEBUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::SLex::D_DETAIL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::SLex::D_WARN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::SLex::ErrNodeAlreadyExists') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('IRB::SLex::ErrNodeNothing') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('IRB::SLex::Node') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('create_subnode') do |method|
      method.define_argument('chrs')
      method.define_optional_argument('preproc')
      method.define_optional_argument('postproc')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('preproc')
      method.define_optional_argument('postproc')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('match') do |method|
      method.define_argument('chrs')
      method.define_optional_argument('op')
    end

    klass.define_instance_method('match_io') do |method|
      method.define_argument('io')
      method.define_optional_argument('op')
    end

    klass.define_instance_method('postproc')

    klass.define_instance_method('postproc=')

    klass.define_instance_method('preproc')

    klass.define_instance_method('preproc=')

    klass.define_instance_method('search') do |method|
      method.define_argument('chrs')
      method.define_optional_argument('opt')
    end
  end

  defs.define_constant('IRB::STDIN_FILE_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IRB::StdioInputMethod') do |klass|
    klass.inherits(defs.constant_proxy('IRB::InputMethod', RubyLint.registry))

    klass.define_instance_method('encoding')

    klass.define_instance_method('eof?')

    klass.define_instance_method('gets')

    klass.define_instance_method('initialize')

    klass.define_instance_method('line') do |method|
      method.define_argument('line_no')
    end

    klass.define_instance_method('readable_after_eof?')
  end

  defs.define_constant('IRB::StdioOutputMethod') do |klass|
    klass.inherits(defs.constant_proxy('IRB::OutputMethod', RubyLint.registry))

    klass.define_instance_method('print') do |method|
      method.define_rest_argument('opts')
    end
  end

  defs.define_constant('IRB::StdioOutputMethod::NotImplementedError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('IRB::WorkSpace') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('binding')

    klass.define_instance_method('evaluate') do |method|
      method.define_argument('context')
      method.define_argument('statements')
      method.define_optional_argument('file')
      method.define_optional_argument('line')
    end

    klass.define_instance_method('filter_backtrace') do |method|
      method.define_argument('bt')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('main')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('main')
  end
end
