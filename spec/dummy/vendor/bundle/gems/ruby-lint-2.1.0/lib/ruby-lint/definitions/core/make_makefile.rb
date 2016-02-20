# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('MakeMakefile') do |defs|
  defs.define_constant('MakeMakefile') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('config_string') do |method|
      method.define_argument('key')
      method.define_optional_argument('config')
    end

    klass.define_method('dir_re') do |method|
      method.define_argument('dir')
    end

    klass.define_method('rm_f') do |method|
      method.define_rest_argument('files')
    end

    klass.define_method('rm_rf') do |method|
      method.define_rest_argument('files')
    end

    klass.define_instance_method('MAIN_DOES_NOTHING') do |method|
      method.define_rest_argument('refs')
    end

    klass.define_instance_method('append_library') do |method|
      method.define_argument('libs')
      method.define_argument('lib')
    end

    klass.define_instance_method('arg_config') do |method|
      method.define_argument('config')
      method.define_optional_argument('default')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cc_command') do |method|
      method.define_optional_argument('opt')
    end

    klass.define_instance_method('check_signedness') do |method|
      method.define_argument('type')
      method.define_optional_argument('headers')
      method.define_optional_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('check_sizeof') do |method|
      method.define_argument('type')
      method.define_optional_argument('headers')
      method.define_optional_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('checking_for') do |method|
      method.define_argument('m')
      method.define_optional_argument('fmt')
    end

    klass.define_instance_method('checking_message') do |method|
      method.define_argument('target')
      method.define_optional_argument('place')
      method.define_optional_argument('opt')
    end

    klass.define_instance_method('configuration') do |method|
      method.define_argument('srcdir')
    end

    klass.define_instance_method('convertible_int') do |method|
      method.define_argument('type')
      method.define_optional_argument('headers')
      method.define_optional_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('cpp_command') do |method|
      method.define_argument('outfile')
      method.define_optional_argument('opt')
    end

    klass.define_instance_method('cpp_include') do |method|
      method.define_argument('header')
    end

    klass.define_instance_method('create_header') do |method|
      method.define_optional_argument('header')
    end

    klass.define_instance_method('create_makefile') do |method|
      method.define_argument('target')
      method.define_optional_argument('srcprefix')
    end

    klass.define_instance_method('create_tmpsrc') do |method|
      method.define_argument('src')
    end

    klass.define_instance_method('depend_rules') do |method|
      method.define_argument('depend')
    end

    klass.define_instance_method('dir_config') do |method|
      method.define_argument('target')
      method.define_optional_argument('idefault')
      method.define_optional_argument('ldefault')
    end

    klass.define_instance_method('dummy_makefile') do |method|
      method.define_argument('srcdir')
    end

    klass.define_instance_method('each_compile_rules')

    klass.define_instance_method('egrep_cpp') do |method|
      method.define_argument('pat')
      method.define_argument('src')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('enable_config') do |method|
      method.define_argument('config')
      method.define_optional_argument('default')
    end

    klass.define_instance_method('find_executable') do |method|
      method.define_argument('bin')
      method.define_optional_argument('path')
    end

    klass.define_instance_method('find_executable0') do |method|
      method.define_argument('bin')
      method.define_optional_argument('path')
    end

    klass.define_instance_method('find_header') do |method|
      method.define_argument('header')
      method.define_rest_argument('paths')
    end

    klass.define_instance_method('find_library') do |method|
      method.define_argument('lib')
      method.define_argument('func')
      method.define_rest_argument('paths')
      method.define_block_argument('b')
    end

    klass.define_instance_method('find_type') do |method|
      method.define_argument('type')
      method.define_argument('opt')
      method.define_rest_argument('headers')
      method.define_block_argument('b')
    end

    klass.define_instance_method('have_const') do |method|
      method.define_argument('const')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('have_devel?')

    klass.define_instance_method('have_framework') do |method|
      method.define_argument('fw')
      method.define_block_argument('b')
    end

    klass.define_instance_method('have_func') do |method|
      method.define_argument('func')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('have_header') do |method|
      method.define_argument('header')
      method.define_optional_argument('preheaders')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('have_library') do |method|
      method.define_argument('lib')
      method.define_optional_argument('func')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('have_macro') do |method|
      method.define_argument('macro')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('have_struct_member') do |method|
      method.define_argument('type')
      method.define_argument('member')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('have_type') do |method|
      method.define_argument('type')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('have_typeof?')

    klass.define_instance_method('have_var') do |method|
      method.define_argument('var')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('init_mkmf') do |method|
      method.define_optional_argument('config')
      method.define_optional_argument('rbconfig')
    end

    klass.define_instance_method('install_dirs') do |method|
      method.define_optional_argument('target_prefix')
    end

    klass.define_instance_method('install_files') do |method|
      method.define_argument('mfile')
      method.define_argument('ifiles')
      method.define_optional_argument('map')
      method.define_optional_argument('srcprefix')
    end

    klass.define_instance_method('install_rb') do |method|
      method.define_argument('mfile')
      method.define_argument('dest')
      method.define_optional_argument('srcdir')
    end

    klass.define_instance_method('libpathflag') do |method|
      method.define_optional_argument('libpath')
    end

    klass.define_instance_method('link_command') do |method|
      method.define_argument('ldflags')
      method.define_optional_argument('opt')
      method.define_optional_argument('libpath')
    end

    klass.define_instance_method('log_src') do |method|
      method.define_argument('src')
      method.define_optional_argument('heading')
    end

    klass.define_instance_method('macro_defined?') do |method|
      method.define_argument('macro')
      method.define_argument('src')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('map_dir') do |method|
      method.define_argument('dir')
      method.define_optional_argument('map')
    end

    klass.define_instance_method('merge_libs') do |method|
      method.define_rest_argument('libs')
    end

    klass.define_instance_method('message') do |method|
      method.define_rest_argument('s')
    end

    klass.define_instance_method('mkintpath') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('mkmf_failed') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('modified?') do |method|
      method.define_argument('target')
      method.define_argument('times')
    end

    klass.define_instance_method('pkg_config') do |method|
      method.define_argument('pkg')
    end

    klass.define_instance_method('relative_from') do |method|
      method.define_argument('path')
      method.define_argument('base')
    end

    klass.define_instance_method('scalar_ptr_type?') do |method|
      method.define_argument('type')
      method.define_optional_argument('member')
      method.define_optional_argument('headers')
      method.define_block_argument('b')
    end

    klass.define_instance_method('scalar_type?') do |method|
      method.define_argument('type')
      method.define_optional_argument('member')
      method.define_optional_argument('headers')
      method.define_block_argument('b')
    end

    klass.define_instance_method('split_libs') do |method|
      method.define_rest_argument('strs')
    end

    klass.define_instance_method('timestamp_file') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('try_cflags') do |method|
      method.define_argument('flags')
    end

    klass.define_instance_method('try_compile') do |method|
      method.define_argument('src')
      method.define_optional_argument('opt')
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_const') do |method|
      method.define_argument('const')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_constant') do |method|
      method.define_argument('const')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_cpp') do |method|
      method.define_argument('src')
      method.define_optional_argument('opt')
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_cppflags') do |method|
      method.define_argument('flags')
    end

    klass.define_instance_method('try_do') do |method|
      method.define_argument('src')
      method.define_argument('command')
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_func') do |method|
      method.define_argument('func')
      method.define_argument('libs')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_header') do |method|
      method.define_argument('src')
      method.define_optional_argument('opt')
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_ldflags') do |method|
      method.define_argument('flags')
    end

    klass.define_instance_method('try_link') do |method|
      method.define_argument('src')
      method.define_optional_argument('opt')
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_link0') do |method|
      method.define_argument('src')
      method.define_optional_argument('opt')
      method.define_rest_argument('opts')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_run') do |method|
      method.define_argument('src')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_signedness') do |method|
      method.define_argument('type')
      method.define_argument('member')
      method.define_optional_argument('headers')
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('try_static_assert') do |method|
      method.define_argument('expr')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_type') do |method|
      method.define_argument('type')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('try_var') do |method|
      method.define_argument('var')
      method.define_optional_argument('headers')
      method.define_optional_argument('opt')
      method.define_block_argument('b')
    end

    klass.define_instance_method('typedef_expr') do |method|
      method.define_argument('type')
      method.define_argument('headers')
    end

    klass.define_instance_method('what_type?') do |method|
      method.define_argument('type')
      method.define_optional_argument('member')
      method.define_optional_argument('headers')
      method.define_block_argument('b')
    end

    klass.define_instance_method('winsep') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('with_cflags') do |method|
      method.define_argument('flags')
    end

    klass.define_instance_method('with_config') do |method|
      method.define_argument('config')
      method.define_optional_argument('default')
    end

    klass.define_instance_method('with_cppflags') do |method|
      method.define_argument('flags')
    end

    klass.define_instance_method('with_destdir') do |method|
      method.define_argument('dir')
    end

    klass.define_instance_method('with_ldflags') do |method|
      method.define_argument('flags')
    end

    klass.define_instance_method('with_werror') do |method|
      method.define_argument('opt')
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('xpopen') do |method|
      method.define_argument('command')
      method.define_rest_argument('mode')
      method.define_block_argument('block')
    end

    klass.define_instance_method('xsystem') do |method|
      method.define_argument('command')
      method.define_optional_argument('opts')
    end
  end

  defs.define_constant('MakeMakefile::CLEANINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::COMMON_HEADERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::COMMON_LIBS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::COMPILE_C') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::COMPILE_CXX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::COMPILE_RULES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::CONFIG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::CONFTEST_C') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::COUTFLAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::CPPOUTFILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::CXX_EXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::C_EXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::EXPORT_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::FailedMessage') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::HDR_EXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::INSTALL_DIRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::LIBARG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::LIBPATHFLAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::LINK_SO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::Logging') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('log_close')

    klass.define_method('log_open')

    klass.define_method('logfile') do |method|
      method.define_argument('file')
    end

    klass.define_method('message') do |method|
      method.define_rest_argument('s')
    end

    klass.define_method('open')

    klass.define_method('postpone')

    klass.define_method('quiet')

    klass.define_method('quiet=')
  end

  defs.define_constant('MakeMakefile::MAIN_DOES_NOTHING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::ORIG_LIBPATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::OUTFLAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::RPATHFLAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::RULE_SUBST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::SRC_EXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::STRING_OR_FAILED_FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('%') do |method|
      method.define_argument('x')
    end
  end

  defs.define_constant('MakeMakefile::TRY_LINK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('MakeMakefile::UNIVERSAL_INTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
