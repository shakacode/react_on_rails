# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: ruby 1.9.3

RubyLint.registry.register('GLib') do |defs|
  defs.define_constant('GLib') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('__add_one_arg_setter') do |method|
      method.define_argument('klass')
    end

    klass.define_method('application_name')

    klass.define_method('application_name=') do |method|
      method.define_argument('val')
    end

    klass.define_method('bit_nth_lsf') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('bit_nth_msf') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('bit_storage') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('charset')

    klass.define_method('check_binding_version?') do |method|
      method.define_argument('major')
      method.define_argument('minor')
      method.define_argument('micro')
    end

    klass.define_method('check_version?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('convert') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('current_dir')

    klass.define_method('exit_application') do |method|
      method.define_argument('exception')
      method.define_argument('status')
    end

    klass.define_method('filename_from_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('filename_from_utf8') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('filename_to_uri') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('filename_to_utf8') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('find_program_in_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('format_size_for_display') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('get_user_special_dir') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('getenv') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('home_dir')

    klass.define_method('host_name')

    klass.define_method('language_names')

    klass.define_method('listenv')

    klass.define_method('locale_from_utf8') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('locale_to_utf8') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('os_beos?')

    klass.define_method('os_unix?')

    klass.define_method('os_win32?')

    klass.define_method('parse_debug_string') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('path_get_basename') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('path_get_dirname') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('path_is_absolute?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('path_skip_root') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('prepend_dll_path') do |method|
      method.define_argument('path')
    end

    klass.define_method('prepend_path_to_environment_variable') do |method|
      method.define_argument('path')
      method.define_argument('environment_name')
    end

    klass.define_method('prgname')

    klass.define_method('prgname=') do |method|
      method.define_argument('val')
    end

    klass.define_method('real_name')

    klass.define_method('ruby_thread_priority=') do |method|
      method.define_argument('val')
    end

    klass.define_method('set_application_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('set_prgname') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('set_ruby_thread_priority') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('setenv') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('spaced_primes_closest') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('system_config_dirs')

    klass.define_method('system_data_dirs')

    klass.define_method('tmp_dir')

    klass.define_method('unsetenv') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('user_cache_dir')

    klass.define_method('user_config_dir')

    klass.define_method('user_data_dir')

    klass.define_method('user_name')

    klass.define_method('utf8_validate') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('win32_locale')

    klass.define_method('win32_locale_filename_from_utf8') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::BINARY_AGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BINDING_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BUILD_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFile') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('add_application') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('add_group') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_added') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_app_info') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_applications') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_description') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_groups') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_icon') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_mime_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_modified') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_title') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_visited') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_application?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('has_group?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('has_item?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('load_from_data') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('load_from_data_dirs') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('load_from_file') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('move_item') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('private?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_application') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('remove_group') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('remove_item') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_added') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_app_info') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('set_description') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_groups') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_icon') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_mime_type') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_modified') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_private') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_title') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_visited') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('to_data')

    klass.define_instance_method('to_file') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('uris')
  end

  defs.define_constant('GLib::BookmarkFileError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::APP_NOT_REGISTERED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::AppNotRegistered') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::FILE_NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::FileNotFound') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::INVALID_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::INVALID_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::APP_NOT_REGISTERED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::AppNotRegistered') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::FILE_NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::FileNotFound') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::INVALID_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::INVALID_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::InvalidValue') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::READ') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::Read') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::UNKNOWN_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::URI_NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::UnknownEncoding') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::UriNotFound') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::WRITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidUri::Write') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::InvalidValue') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::READ') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::Read') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::UNKNOWN_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::URI_NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::UnknownEncoding') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::UriNotFound') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::WRITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::BookmarkFileError::Write') do |klass|
    klass.inherits(defs.constant_proxy('GLib::BookmarkFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::Boxed') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('gtype')

    klass.define_instance_method('copy')

    klass.define_instance_method('gtype')

    klass.define_instance_method('inspect')
  end

  defs.define_constant('GLib::CallbackNotInitializedError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

  end

  defs.define_constant('GLib::ChildWatch') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('source_new') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::Closure') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('in_marshal?')

    klass.define_instance_method('invalid?')

    klass.define_instance_method('invalidate')
  end

  defs.define_constant('GLib::ConnectFlags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('after?')

    klass.define_instance_method('swapped?')
  end

  defs.define_constant('GLib::ConnectFlags::AFTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::ConnectFlags::SWAPPED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::ConvertError') do |klass|
    klass.inherits(defs.constant_proxy('IOError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('GLib::ConvertError::BAD_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::ConvertError::FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::ConvertError::ILLEGAL_SEQUENCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::ConvertError::NOT_ABSOLUTE_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::ConvertError::NO_CONVERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::ConvertError::PARTIAL_INPUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::DIR_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Deprecatable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('extended') do |method|
      method.define_argument('class_or_module')
    end

    klass.define_instance_method('define_deprecated_const') do |method|
      method.define_argument('deprecated_const')
      method.define_optional_argument('new_const')
    end

    klass.define_instance_method('define_deprecated_enums') do |method|
      method.define_argument('enums')
      method.define_optional_argument('prefix')
    end

    klass.define_instance_method('define_deprecated_flags') do |method|
      method.define_argument('enums')
      method.define_optional_argument('prefix')
    end

    klass.define_instance_method('define_deprecated_method') do |method|
      method.define_argument('deprecated_method')
      method.define_optional_argument('new_method')
      method.define_block_argument('block')
    end

    klass.define_instance_method('define_deprecated_method_by_hash_args') do |method|
      method.define_argument('deprecated_method')
      method.define_argument('old_args')
      method.define_argument('new_args')
      method.define_optional_argument('req_argc')
      method.define_block_argument('block')
    end

    klass.define_instance_method('define_deprecated_signal') do |method|
      method.define_argument('deprecated_signal')
      method.define_optional_argument('new_signal')
    end

    klass.define_instance_method('define_deprecated_singleton_method') do |method|
      method.define_argument('deprecated_method')
      method.define_optional_argument('new_method')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('GLib::DeprecatedError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

  end

  defs.define_constant('GLib::E') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Enum') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('_load') do |method|
      method.define_argument('obj')
    end

    klass.define_method('gtype')

    klass.define_method('range')

    klass.define_method('values')

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_argument('limit')
    end

    klass.define_instance_method('coerce') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('gtype')

    klass.define_instance_method('hash')

    klass.define_instance_method('inspect')

    klass.define_instance_method('name')

    klass.define_instance_method('nick')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_int')
  end

  defs.define_constant('GLib::Error') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('GLib::ErrorInfo') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('code')

    klass.define_instance_method('domain')
  end

  defs.define_constant('GLib::FileError') do |klass|
    klass.inherits(defs.constant_proxy('IOError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::ACCES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::AGAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::BADF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::EXIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::FAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::INTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::INVAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::IO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::ISDIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::LOOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::MFILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::NAMETOOLONG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::NFILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::NODEV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::NOENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::NOMEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::NOSPC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::NOTDIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::NXIO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::PERM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::PIPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::ROFS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::FileError::TXTBSY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Flags') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('_load') do |method|
      method.define_argument('obj')
    end

    klass.define_method('gtype')

    klass.define_method('mask')

    klass.define_method('values')

    klass.define_instance_method('&') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('<') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('<=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('>') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('>=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('^') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('_dump') do |method|
      method.define_argument('limit')
    end

    klass.define_instance_method('coerce') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('gtype')

    klass.define_instance_method('hash')

    klass.define_instance_method('inspect')

    klass.define_instance_method('name')

    klass.define_instance_method('nick')

    klass.define_instance_method('nonzero?')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_int')

    klass.define_instance_method('zero?')

    klass.define_instance_method('|') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('~')
  end

  defs.define_constant('GLib::GetText') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('bindtextdomain') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('GLib::INTERFACE_AGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('open') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('add_watch') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('buffer_condition')

    klass.define_instance_method('buffer_size')

    klass.define_instance_method('buffer_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('buffered')

    klass.define_instance_method('buffered=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('close') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('create_watch') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('each_char')

    klass.define_instance_method('each_line') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('encoding')

    klass.define_instance_method('encoding=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('fileno')

    klass.define_instance_method('flags')

    klass.define_instance_method('flags=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('flush')

    klass.define_instance_method('getc')

    klass.define_instance_method('gets') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('pos=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('print') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('printf') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('putc') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('puts') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('read') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('readchar')

    klass.define_instance_method('readline') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('seek') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_buffer_size') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_buffered') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_encoding') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_flags') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_pos') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('to_i')

    klass.define_instance_method('write') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::IOChannel::ERR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::FLAG_APPEND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::FLAG_GET_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::FLAG_IS_SEEKABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::FLAG_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::FLAG_NONBLOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::FLAG_READABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::FLAG_SET_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::FLAG_WRITEABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::HUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::IN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::NVAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::OUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::PRI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::SEEK_CUR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::SEEK_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::SEEK_SET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::STATUS_AGAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::STATUS_EOF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::STATUS_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannel::STATUS_NORMAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelError') do |klass|
    klass.inherits(defs.constant_proxy('IOError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

    klass.define_method('from_errno') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::IOChannelError::FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelError::FBIG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelError::INVAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelError::IO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelError::ISDIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelError::NOSPC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelError::NXIO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelError::OVERFLOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelError::PIPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket') do |klass|
    klass.inherits(defs.constant_proxy('GLib::IOChannel', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::ERR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::FLAG_APPEND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::FLAG_GET_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::FLAG_IS_SEEKABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::FLAG_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::FLAG_NONBLOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::FLAG_READABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::FLAG_SET_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::FLAG_WRITEABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::HUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::IN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::NVAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::OUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::PRI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::SEEK_CUR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::SEEK_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::SEEK_SET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::STATUS_AGAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::STATUS_EOF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::STATUS_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOChannelWin32Socket::STATUS_NORMAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOCondition') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('err?')

    klass.define_instance_method('hup?')

    klass.define_instance_method('in?')

    klass.define_instance_method('nval?')

    klass.define_instance_method('out?')

    klass.define_instance_method('pri?')
  end

  defs.define_constant('GLib::IOCondition::ERR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOCondition::HUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOCondition::IN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOCondition::NVAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOCondition::OUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::IOCondition::PRI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Idle') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('source_new')
  end

  defs.define_constant('GLib::InitiallyUnowned') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

  end

  defs.define_constant('GLib::InitiallyUnowned::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Instantiatable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('method_added') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('clone')

    klass.define_instance_method('gtype')

    klass.define_instance_method('signal_connect') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('signal_connect_after') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('signal_emit') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('signal_emit_stop') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('signal_handler_block') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('signal_handler_disconnect') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('signal_handler_is_connected?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('signal_handler_unblock') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('signal_has_handler_pending?') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('GLib::Interface') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('get_boolean') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_boolean_list') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_comment') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_double') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_double_list') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_integer') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_integer_list') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_keys') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_locale_string') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('get_locale_string_list') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('get_string') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_string_list') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_value') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('groups')

    klass.define_instance_method('has_group?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('list_separator=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('load_from_data') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('load_from_data_dirs') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('load_from_dirs') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('load_from_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('remove_comment') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('remove_group') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_key') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_boolean') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_boolean_list') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_comment') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_double') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_double_list') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_integer') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_integer_list') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_list_separator') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_locale_string') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('set_locale_string_list') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('set_string') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_string_list') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_value') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('start_group')

    klass.define_instance_method('to_data')
  end

  defs.define_constant('GLib::KeyFile::DESKTOP_GROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_CATEGORIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_COMMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_EXEC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_GENERIC_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_HIDDEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_ICON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_MIME_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_NOT_SHOW_IN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_NO_DISPLAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_ONLY_SHOW_IN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_STARTUP_NOTIFY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_STARTUP_WM_CLASS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_TERMINAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_TRY_EXEC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_URL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_KEY_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_TYPE_APPLICATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_TYPE_DIRECTORY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::DESKTOP_TYPE_LINK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('keep_comments?')

    klass.define_instance_method('keep_translations?')

    klass.define_instance_method('none?')
  end

  defs.define_constant('GLib::KeyFile::Flags::KEEP_COMMENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::Flags::KEEP_TRANSLATIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::Flags::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::KEEP_COMMENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::KEEP_TRANSLATIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFile::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::GROUP_NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::GroupNotFound') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::INVALID_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::InvalidValue') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::KEY_NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::KeyNotFound') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::NotFound') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::PARSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::Parse') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UNKNOWN_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::GROUP_NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::GroupNotFound') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::INVALID_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::InvalidValue') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::KEY_NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::KeyNotFound') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::NotFound') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::PARSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::Parse') do |klass|
    klass.inherits(defs.constant_proxy('GLib::KeyFileError', RubyLint.registry))

  end

  defs.define_constant('GLib::KeyFileError::UnknownEncoding::UNKNOWN_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::LN10') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::LN2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::LOG_2_BASE_10') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('always_fatal=') do |method|
      method.define_argument('val')
    end

    klass.define_method('cancel_handler')

    klass.define_method('critical') do |method|
      method.define_argument('str')
    end

    klass.define_method('error') do |method|
      method.define_argument('str')
    end

    klass.define_method('log') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('message') do |method|
      method.define_argument('str')
    end

    klass.define_method('remove_handler') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('set_always_fatal') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('set_fatal_mask') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('set_handler') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('set_log_domain') do |method|
      method.define_argument('domain')
    end

    klass.define_method('warning') do |method|
      method.define_argument('str')
    end
  end

  defs.define_constant('GLib::Log::DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::FATAL_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::FLAG_FATAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::FLAG_RECURSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::LEVELS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::LEVEL_CRITICAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::LEVEL_DEBUG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::LEVEL_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::LEVEL_INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::LEVEL_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::LEVEL_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::LEVEL_USER_SHIFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Log::LEVEL_WARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAJOR_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXDOUBLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXFLOAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXINT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXINT16') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXINT32') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXINT64') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXINT8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXLONG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXSHORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXSIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXUINT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXUINT16') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXUINT32') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXUINT64') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXUINT8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXULONG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MAXUSHORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MICRO_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MINDOUBLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MINFLOAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MININT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MININT16') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MININT32') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MININT64') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MININT8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MINLONG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MINOR_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MINSHORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::MainContext') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_method('default')

    klass.define_method('depth')

    klass.define_instance_method('acquire')

    klass.define_instance_method('add_poll') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('dispatch')

    klass.define_instance_method('find_source') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iteration') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('owner?')

    klass.define_instance_method('pending?')

    klass.define_instance_method('prepare')

    klass.define_instance_method('query') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('release')

    klass.define_instance_method('remove_poll') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('wakeup')
  end

  defs.define_constant('GLib::MainLoop') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('context')

    klass.define_instance_method('quit')

    klass.define_instance_method('run')

    klass.define_instance_method('running?')
  end

  defs.define_constant('GLib::MetaInterface') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('append_features') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('gtype')

    klass.define_instance_method('install_property') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('properties') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('property') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('signal') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('signal_new') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('signals') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('GLib::Module') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Module::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::NoPropertyError') do |klass|
    klass.inherits(defs.constant_proxy('NameError', RubyLint.registry))

  end

  defs.define_constant('GLib::NoSignalError') do |klass|
    klass.inherits(defs.constant_proxy('NameError', RubyLint.registry))

  end

  defs.define_constant('GLib::NormalizeMode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('GLib::NormalizeMode::ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::NormalizeMode::ALL_COMPOSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::NormalizeMode::DEFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::NormalizeMode::DEFAULT_COMPOSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::NormalizeMode::NFC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::NormalizeMode::NFD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::NormalizeMode::NFKC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::NormalizeMode::NFKD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Object') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Instantiatable', RubyLint.registry))

    klass.define_method('install_property') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('new!') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('properties') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('property') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('type_register') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('destroyed?')

    klass.define_instance_method('freeze_notify')

    klass.define_instance_method('get_property') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('notify') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('ref_count')

    klass.define_instance_method('set_property') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('thaw_notify')

    klass.define_instance_method('type_name')
  end

  defs.define_constant('GLib::Object::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::PI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::PI_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::PI_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::PRIORITY_DEFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::PRIORITY_DEFAULT_IDLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::PRIORITY_HIGH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::PRIORITY_HIGH_IDLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::PRIORITY_LOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Instantiatable', RubyLint.registry))

    klass.define_instance_method('blurb')

    klass.define_instance_method('construct?')

    klass.define_instance_method('construct_only?')

    klass.define_instance_method('default')

    klass.define_instance_method('flags')

    klass.define_instance_method('inspect')

    klass.define_instance_method('lax_validation?')

    klass.define_instance_method('name')

    klass.define_instance_method('nick')

    klass.define_instance_method('owner')

    klass.define_instance_method('owner_type')

    klass.define_instance_method('private?')

    klass.define_instance_method('readable?')

    klass.define_instance_method('readwrite?')

    klass.define_instance_method('ref_count')

    klass.define_instance_method('value_compare') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('value_convert') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('value_default')

    klass.define_instance_method('value_type')

    klass.define_instance_method('value_validate') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('writable?')
  end

  defs.define_constant('GLib::Param::Boolean') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Boxed') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::CONSTRUCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::CONSTRUCT_ONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Char::Boolean') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::Boxed') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::CONSTRUCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::CONSTRUCT_ONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::Double') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('epsilon')

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Char::Enum') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::Float') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('epsilon')

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Char::Int') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Char::Int64') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Char::LAX_VALIDATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::Long') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Char::MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::Object') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::PRIVATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::Param') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::Pointer') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::READABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::READWRITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::String') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::UChar') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Char::UInt') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Char::UInt64') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Char::ULong') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Char::USER_SHIFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::UniChar') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::ValueArray') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Char::WRITABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Double') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('epsilon')

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Enum') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Float') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('epsilon')

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Int') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::Int64') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::LAX_VALIDATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Long') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Object') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::PRIVATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Param') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::Pointer') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::READABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::READWRITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::String') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::UChar') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::UInt') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::UInt64') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::ULong') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

    klass.define_instance_method('maximum')

    klass.define_instance_method('minimum')

    klass.define_instance_method('range')
  end

  defs.define_constant('GLib::Param::USER_SHIFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::UniChar') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::ValueArray') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Param', RubyLint.registry))

  end

  defs.define_constant('GLib::Param::WRITABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Pointer') do |klass|
    klass.inherits(defs.constant_proxy('Data', RubyLint.registry))

    klass.define_method('gtype') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('gtype') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::PollFD') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('events')

    klass.define_instance_method('events=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('fd')

    klass.define_instance_method('fd=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('revents')

    klass.define_instance_method('revents=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_events') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_fd') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_revents') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::SEARCHPATH_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SQRT2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Shell') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('parse') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('quote') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('unquote') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::ShellError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('GLib::ShellError::BAD_QUOTING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::ShellError::EMPTY_STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::ShellError::FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal') do |klass|
    klass.inherits(defs.constant_proxy('Data', RubyLint.registry))

    klass.define_instance_method('action?')

    klass.define_instance_method('add_emission_hook') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('detailed?')

    klass.define_instance_method('flags')

    klass.define_instance_method('id')

    klass.define_instance_method('inspect')

    klass.define_instance_method('itype')

    klass.define_instance_method('name')

    klass.define_instance_method('no_hooks?')

    klass.define_instance_method('no_recurse?')

    klass.define_instance_method('owner')

    klass.define_instance_method('param_types')

    klass.define_instance_method('remove_emission_hook') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('return_type')

    klass.define_instance_method('run_cleanup?')

    klass.define_instance_method('run_first?')

    klass.define_instance_method('run_last?')
  end

  defs.define_constant('GLib::Signal::ACTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::CONNECT_AFTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::CONNECT_SWAPPED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::DEPRECATED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::DETAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::FLAGS_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::MATCH_CLOSURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::MATCH_DATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::MATCH_DETAIL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::MATCH_FUNC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::MATCH_ID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::MATCH_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::MATCH_UNBLOCKED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::MUST_COLLECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::NO_HOOKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::NO_RECURSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::RUN_CLEANUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::RUN_FIRST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::RUN_LAST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Signal::TYPE_STATIC_SCOPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalFlags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('action?')

    klass.define_instance_method('deprecated?')

    klass.define_instance_method('detailed?')

    klass.define_instance_method('must_collect?')

    klass.define_instance_method('no_hooks?')

    klass.define_instance_method('no_recurse?')

    klass.define_instance_method('run_cleanup?')

    klass.define_instance_method('run_first?')

    klass.define_instance_method('run_last?')
  end

  defs.define_constant('GLib::SignalFlags::ACTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalFlags::DEPRECATED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalFlags::DETAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalFlags::MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalFlags::MUST_COLLECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalFlags::NO_HOOKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalFlags::NO_RECURSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalFlags::RUN_CLEANUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalFlags::RUN_FIRST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalFlags::RUN_LAST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalMatchType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('closure?')

    klass.define_instance_method('data?')

    klass.define_instance_method('detail?')

    klass.define_instance_method('func?')

    klass.define_instance_method('id?')

    klass.define_instance_method('unblocked?')
  end

  defs.define_constant('GLib::SignalMatchType::CLOSURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalMatchType::DATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalMatchType::DETAIL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalMatchType::FUNC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalMatchType::ID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalMatchType::MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SignalMatchType::UNBLOCKED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Source') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_method('current')

    klass.define_method('remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_poll') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('attach') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('can_recurse=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('can_recurse?')

    klass.define_instance_method('context')

    klass.define_instance_method('destroyed?')

    klass.define_instance_method('id')

    klass.define_instance_method('priority')

    klass.define_instance_method('priority=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('remove_poll') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_callback')

    klass.define_instance_method('set_can_recurse') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_priority') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('time')
  end

  defs.define_constant('GLib::Source::CONTINUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Source::REMOVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Spawn') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('async') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_method('async_with_pipes') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_method('close_pid') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('command_line_async') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('command_line_sync') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('sync') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end
  end

  defs.define_constant('GLib::Spawn::CHILD_INHERITS_STDIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Spawn::DO_NOT_REAP_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Spawn::FILE_AND_ARGV_ZERO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Spawn::LEAVE_DESCRIPTORS_OPEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Spawn::SEARCH_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Spawn::STDERR_TO_DEV_NULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Spawn::STDOUT_TO_DEV_NULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError') do |klass|
    klass.inherits(defs.constant_proxy('IOError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::CHDIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::E2BIG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::EACCES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::EINVAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::EIO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::EISDIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::ELIBBAD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::ELOOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::EMFILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::ENAMETOOLONG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::ENFILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::ENOENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::ENOEXEC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::ENOMEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::ENOTDIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::EPERM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::ETXTBUSY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::FORK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::SpawnError::READ') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Thread') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('init')

    klass.define_method('supported?')
  end

  defs.define_constant('GLib::Thread::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Timeout') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('add_seconds') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('source_new') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('source_new_seconds') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::Timer') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('continue')

    klass.define_instance_method('elapsed')

    klass.define_instance_method('reset')

    klass.define_instance_method('start')

    klass.define_instance_method('stop')
  end

  defs.define_constant('GLib::Type') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('<') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('<=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('>') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('>=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('abstract?')

    klass.define_instance_method('ancestors')

    klass.define_instance_method('children')

    klass.define_instance_method('class_size')

    klass.define_instance_method('classed?')

    klass.define_instance_method('decendants')

    klass.define_instance_method('deep_derivable?')

    klass.define_instance_method('depth')

    klass.define_instance_method('derivable?')

    klass.define_instance_method('derived?')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('fundamental')

    klass.define_instance_method('fundamental?')

    klass.define_instance_method('has_value_table')

    klass.define_instance_method('hash')

    klass.define_instance_method('inspect')

    klass.define_instance_method('instance_size')

    klass.define_instance_method('instantiatable?')

    klass.define_instance_method('interface?')

    klass.define_instance_method('interfaces')

    klass.define_instance_method('name')

    klass.define_instance_method('next_base') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('parent')

    klass.define_instance_method('to_class')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_int')

    klass.define_instance_method('to_s')

    klass.define_instance_method('type_is_a?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('value_abstract?')

    klass.define_instance_method('value_type?')
  end

  defs.define_constant('GLib::Type::BOOLEAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::BOXED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::CHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::DOUBLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::ENUM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::FLAGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::FLOAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::FUNDAMENTAL_MAX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::FUNDAMENTAL_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::INT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::INT64') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::INTERFACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::LONG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::OBJECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::PARAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::POINTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::UCHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::UINT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::UINT64') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Type::ULONG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::TypeModule') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::TypePlugin', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('unuse')

    klass.define_instance_method('use')
  end

  defs.define_constant('GLib::TypeModule::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::TypePlugin') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('unuse')

    klass.define_instance_method('use')
  end

  defs.define_constant('GLib::UCS4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('to_utf16') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('to_utf8') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::USER_DIRECTORY_DESKTOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::USER_DIRECTORY_DOCUMENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::USER_DIRECTORY_DOWNLOAD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::USER_DIRECTORY_MUSIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::USER_DIRECTORY_PICTURES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::USER_DIRECTORY_PUBLIC_SHARE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::USER_DIRECTORY_TEMPLATES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::USER_DIRECTORY_VIDEOS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::USER_N_DIRECTORIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UTF16') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('to_ucs4') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('to_utf8') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::UTF8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('casefold') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('collate') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('collate_key') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('downcase') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('get_char') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('normalize') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('reverse') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('size') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('to_ucs4') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('to_utf16') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('upcase') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('validate') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::UniChar') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('alnum?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('alpha?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('break_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('cntrl?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('combining_class') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('defined?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('digit?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('digit_value') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('get_mirror_char') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('get_script') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('graph?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('lower?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('mark?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('print?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('punct?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('space?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('title?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('to_lower') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('to_title') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('to_upper') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('to_utf8') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('type') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('upper?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('wide?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('wide_cjk?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('xdigit?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('xdigit_value') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('zero_width?') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::Unicode') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('canonical_decomposition') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('canonical_ordering') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('GLib::Unicode::BREAK_AFTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_ALPHABETIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_AMBIGUOUS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_BEFORE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_BEFORE_AND_AFTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_CARRIAGE_RETURN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_CLOSE_PARANTHESIS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_CLOSE_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_COMBINING_MARK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_COMPLEX_CONTEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_CONDITIONAL_JAPANESE_STARTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_CONTINGENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_EXCLAMATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_HANGUL_LVT_SYLLABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_HANGUL_LV_SYLLABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_HANGUL_L_JAMO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_HANGUL_T_JAMO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_HANGUL_V_JAMO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_HEBREW_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_HYPHEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_IDEOGRAPHIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_INFIX_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_INSEPARABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_LINE_FEED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_MANDATORY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_NEXT_LINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_NON_BREAKING_GLUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_NON_STARTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_NUMERIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_OPEN_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_POSTFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_QUOTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_REGIONAL_INDICATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_SURROGATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_WORD_JOINER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BREAK_ZERO_WIDTH_SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::AFTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::ALPHABETIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::AMBIGUOUS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::BEFORE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::BEFORE_AND_AFTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::CARRIAGE_RETURN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::CLOSE_PARANTHESIS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::CLOSE_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::COMBINING_MARK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::COMPLEX_CONTEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::CONDITIONAL_JAPANESE_STARTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::CONTINGENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::EXCLAMATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::HANGUL_LVT_SYLLABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::HANGUL_LV_SYLLABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::HANGUL_L_JAMO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::HANGUL_T_JAMO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::HANGUL_V_JAMO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::HEBREW_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::HYPHEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::IDEOGRAPHIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::INFIX_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::INSEPARABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::LINE_FEED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::MANDATORY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::NEXT_LINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::NON_BREAKING_GLUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::NON_STARTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::NUMERIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::OPEN_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::POSTFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::QUOTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::REGIONAL_INDICATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::SURROGATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::WORD_JOINER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::BreakType::ZERO_WIDTH_SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::CLOSE_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::CONNECT_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::CONTROL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::CURRENCY_SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::DASH_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::DECIMAL_NUMBER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::ENCLOSING_MARK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::FINAL_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::INITIAL_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::LETTER_NUMBER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::LINE_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::LOWERCASE_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::MATH_SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::MODIFIER_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::MODIFIER_SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::NON_SPACING_MARK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::OPEN_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::OTHER_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::OTHER_NUMBER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::OTHER_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::OTHER_SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::PARAGRAPH_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::PRIVATE_USE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_ARABIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_ARMENIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_AVESTAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_BALINESE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_BAMUM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_BATAK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_BENGALI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_BOPOMOFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_BRAHMI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_BRAILLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_BUGINESE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_BUHID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_CANADIAN_ABORIGINAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_CARIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_CHAKMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_CHAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_CHEROKEE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_COMMON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_COPTIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_CUNEIFORM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_CYPRIOT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_CYRILLIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_DESERET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_DEVANAGARI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_EGYPTIAN_HIEROGLYPHS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_ETHIOPIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_GEORGIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_GLAGOLITIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_GOTHIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_GREEK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_GUJARATI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_GURMUKHI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_HAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_HANGUL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_HANUNOO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_HEBREW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_HIRAGANA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_IMPERIAL_ARAMAIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_INHERITED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_INSCRIPTIONAL_PAHLAVI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_INSCRIPTIONAL_PARTHIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_INVALID_CODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_JAVANESE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_KAITHI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_KANNADA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_KATAKANA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_KAYAH_LI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_KHAROSHTHI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_KHMER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_LAO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_LATIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_LEPCHA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_LIMBU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_LINEAR_B') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_LISU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_LYCIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_LYDIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_MALAYALAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_MANDAIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_MEETEI_MAYEK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_MEROITIC_CURSIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_MEROITIC_HIEROGLYPHS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_MIAO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_MONGOLIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_MYANMAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_NEW_TAI_LUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_NKO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_OGHAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_OLD_ITALIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_OLD_PERSIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_OLD_SOUTH_ARABIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_OLD_TURKIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_OL_CHIKI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_ORIYA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_OSMANYA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_PHAGS_PA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_PHOENICIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_REJANG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_RUNIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_SAMARITAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_SAURASHTRA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_SHARADA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_SHAVIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_SINHALA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_SORA_SOMPENG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_SUNDANESE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_SYLOTI_NAGRI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_SYRIAC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_TAGALOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_TAGBANWA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_TAI_LE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_TAI_THAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_TAI_VIET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_TAKRI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_TAMIL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_TELUGU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_THAANA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_THAI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_TIBETAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_TIFINAGH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_UGARITIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_VAI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SCRIPT_YI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SPACE_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SPACING_MARK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::SURROGATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::ARABIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::ARMENIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::AVESTAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::BALINESE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::BAMUM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::BATAK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::BENGALI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::BOPOMOFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::BRAHMI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::BRAILLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::BUGINESE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::BUHID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::CANADIAN_ABORIGINAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::CARIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::CHAKMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::CHAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::CHEROKEE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::COMMON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::COPTIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::CUNEIFORM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::CYPRIOT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::CYRILLIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::DESERET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::DEVANAGARI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::EGYPTIAN_HIEROGLYPHS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::ETHIOPIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::GEORGIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::GLAGOLITIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::GOTHIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::GREEK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::GUJARATI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::GURMUKHI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::HAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::HANGUL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::HANUNOO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::HEBREW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::HIRAGANA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::IMPERIAL_ARAMAIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::INHERITED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::INSCRIPTIONAL_PAHLAVI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::INSCRIPTIONAL_PARTHIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::INVALID_CODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::JAVANESE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::KAITHI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::KANNADA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::KATAKANA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::KAYAH_LI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::KHAROSHTHI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::KHMER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::LAO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::LATIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::LEPCHA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::LIMBU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::LINEAR_B') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::LISU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::LYCIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::LYDIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::MALAYALAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::MANDAIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::MEETEI_MAYEK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::MEROITIC_CURSIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::MEROITIC_HIEROGLYPHS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::MIAO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::MONGOLIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::MYANMAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::NEW_TAI_LUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::NKO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::OGHAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::OLD_ITALIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::OLD_PERSIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::OLD_SOUTH_ARABIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::OLD_TURKIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::OL_CHIKI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::ORIYA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::OSMANYA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::PHAGS_PA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::PHOENICIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::REJANG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::RUNIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::SAMARITAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::SAURASHTRA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::SHARADA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::SHAVIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::SINHALA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::SORA_SOMPENG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::SUNDANESE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::SYLOTI_NAGRI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::SYRIAC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::TAGALOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::TAGBANWA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::TAI_LE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::TAI_THAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::TAI_VIET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::TAKRI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::TAMIL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::TELUGU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::THAANA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::THAI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::TIBETAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::TIFINAGH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::UGARITIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::VAI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Script::YI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::TITLECASE_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::CLOSE_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::CONNECT_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::CONTROL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::CURRENCY_SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::DASH_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::DECIMAL_NUMBER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::ENCLOSING_MARK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::FINAL_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::INITIAL_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::LETTER_NUMBER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::LINE_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::LOWERCASE_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::MATH_SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::MODIFIER_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::MODIFIER_SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::NON_SPACING_MARK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::OPEN_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::OTHER_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::OTHER_NUMBER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::OTHER_PUNCTUATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::OTHER_SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::PARAGRAPH_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::PRIVATE_USE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::SPACE_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::SPACING_MARK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::SURROGATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::TITLECASE_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::UNASSIGNED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::Type::UPPERCASE_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::UNASSIGNED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Unicode::UPPERCASE_LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DESKTOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DIRECTORY_DESKTOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DIRECTORY_DOCUMENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DIRECTORY_DOWNLOAD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DIRECTORY_MUSIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DIRECTORY_PICTURES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DIRECTORY_PUBLIC_SHARE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DIRECTORY_TEMPLATES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DIRECTORY_VIDEOS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DOCUMENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::DOWNLOAD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::MUSIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::N_DIRECTORIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::PICTURES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::PUBLIC_SHARE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::TEMPLATES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::UserDirectory::VIDEOS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('GLib::Value') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('to_s')

    klass.define_instance_method('type')

    klass.define_instance_method('value')
  end

  defs.define_constant('GLib::Win32') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('error_message') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('get_package_installation_directory_of_module') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('locale')

    klass.define_method('locale_filename_from_utf8') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('version')
  end
end
