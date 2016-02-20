# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('FileUtils') do |defs|
  defs.define_constant('FileUtils') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cd') do |method|
      method.define_argument('dir')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('chdir') do |method|
      method.define_argument('dir')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('chmod') do |method|
      method.define_argument('mode')
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('chmod_R') do |method|
      method.define_argument('mode')
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('chown') do |method|
      method.define_argument('user')
      method.define_argument('group')
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('chown_R') do |method|
      method.define_argument('user')
      method.define_argument('group')
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('cmp') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_method('collect_method') do |method|
      method.define_argument('opt')
    end

    klass.define_method('commands')

    klass.define_method('compare_file') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_method('compare_stream') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_method('copy') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('copy_entry') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('preserve')
      method.define_optional_argument('dereference_root')
      method.define_optional_argument('remove_destination')
    end

    klass.define_method('copy_file') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('preserve')
      method.define_optional_argument('dereference')
    end

    klass.define_method('copy_stream') do |method|
      method.define_argument('src')
      method.define_argument('dest')
    end

    klass.define_method('cp') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('cp_r') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('getwd')

    klass.define_method('have_option?') do |method|
      method.define_argument('mid')
      method.define_argument('opt')
    end

    klass.define_method('identical?') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_method('install') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('link') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('ln') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('ln_s') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('ln_sf') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('makedirs') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('mkdir') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('mkdir_p') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('mkpath') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('move') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('mv') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('options')

    klass.define_method('options_of') do |method|
      method.define_argument('mid')
    end

    klass.define_method('private_module_function') do |method|
      method.define_argument('name')
    end

    klass.define_method('pwd')

    klass.define_method('remove') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('remove_dir') do |method|
      method.define_argument('path')
      method.define_optional_argument('force')
    end

    klass.define_method('remove_entry') do |method|
      method.define_argument('path')
      method.define_optional_argument('force')
    end

    klass.define_method('remove_entry_secure') do |method|
      method.define_argument('path')
      method.define_optional_argument('force')
    end

    klass.define_method('remove_file') do |method|
      method.define_argument('path')
      method.define_optional_argument('force')
    end

    klass.define_method('rm') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('rm_f') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('rm_r') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('rm_rf') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('rmdir') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('rmtree') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('safe_unlink') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('symlink') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('options')
    end

    klass.define_method('touch') do |method|
      method.define_argument('list')
      method.define_optional_argument('options')
    end

    klass.define_method('uptodate?') do |method|
      method.define_argument('new')
      method.define_argument('old_list')
    end

    klass.define_instance_method('ruby') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('safe_ln') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('sh') do |method|
      method.define_rest_argument('cmd')
      method.define_block_argument('block')
    end

    klass.define_instance_method('split_all') do |method|
      method.define_argument('path')
    end
  end

  defs.define_constant('FileUtils::DryRun') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('chdir') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('chmod') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chmod_R') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chown') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chown_R') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('cmp') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('compare_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('compare_stream') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('copy_entry') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy_stream') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('cp') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('cp_r') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('getwd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('identical?') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('install') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('link') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln_s') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln_sf') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('makedirs') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkdir_p') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkpath') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('move') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mv') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('pwd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('remove_dir') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_entry') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_entry_secure') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('rm') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_f') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_r') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_rf') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rmdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rmtree') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('safe_unlink') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('symlink') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('touch') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('uptodate?') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('FileUtils::Entry_') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('FileUtils::StreamUtils_', RubyLint.registry))

    klass.define_instance_method('blockdev?')

    klass.define_instance_method('chardev?')

    klass.define_instance_method('chmod') do |method|
      method.define_argument('mode')
    end

    klass.define_instance_method('chown') do |method|
      method.define_argument('uid')
      method.define_argument('gid')
    end

    klass.define_instance_method('copy') do |method|
      method.define_argument('dest')
    end

    klass.define_instance_method('copy_file') do |method|
      method.define_argument('dest')
    end

    klass.define_instance_method('copy_metadata') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('dereference?')

    klass.define_instance_method('directory?')

    klass.define_instance_method('door?')

    klass.define_instance_method('entries')

    klass.define_instance_method('exist?')

    klass.define_instance_method('file?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('a')
      method.define_optional_argument('b')
      method.define_optional_argument('deref')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('lstat')

    klass.define_instance_method('lstat!')

    klass.define_instance_method('path')

    klass.define_instance_method('pipe?')

    klass.define_instance_method('platform_support')

    klass.define_instance_method('postorder_traverse')

    klass.define_instance_method('prefix')

    klass.define_instance_method('preorder_traverse')

    klass.define_instance_method('rel')

    klass.define_instance_method('remove')

    klass.define_instance_method('remove_dir1')

    klass.define_instance_method('remove_file')

    klass.define_instance_method('socket?')

    klass.define_instance_method('stat')

    klass.define_instance_method('stat!')

    klass.define_instance_method('symlink?')

    klass.define_instance_method('traverse')

    klass.define_instance_method('wrap_traverse') do |method|
      method.define_argument('pre')
      method.define_argument('post')
    end
  end

  defs.define_constant('FileUtils::Entry_::DIRECTORY_TERM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::Entry_::SYSCASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::Entry_::S_IF_DOOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::LN_SUPPORTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::LOW_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::LowMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::NoWrite') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('chdir') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('chmod') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chmod_R') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chown') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chown_R') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('cmp') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('compare_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('compare_stream') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('copy_entry') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy_stream') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('cp') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('cp_r') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('getwd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('identical?') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('install') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('link') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln_s') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln_sf') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('makedirs') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkdir_p') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkpath') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('move') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mv') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('pwd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('remove_dir') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_entry') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_entry_secure') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('rm') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_f') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_r') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_rf') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rmdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rmtree') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('safe_unlink') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('symlink') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('touch') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('uptodate?') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('FileUtils::OPT_TABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::RUBY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::StreamUtils_') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::Verbose') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cd') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chmod') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chmod_R') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chown') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chown_R') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('cmp') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_method('compare_file') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_method('compare_stream') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_method('copy') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('copy_entry') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('preserve')
      method.define_optional_argument('dereference_root')
      method.define_optional_argument('remove_destination')
    end

    klass.define_method('copy_file') do |method|
      method.define_argument('src')
      method.define_argument('dest')
      method.define_optional_argument('preserve')
      method.define_optional_argument('dereference')
    end

    klass.define_method('copy_stream') do |method|
      method.define_argument('src')
      method.define_argument('dest')
    end

    klass.define_method('cp') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('cp_r') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('getwd')

    klass.define_method('identical?') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_method('install') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('link') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln_s') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln_sf') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('makedirs') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkdir_p') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkpath') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('move') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mv') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('pwd')

    klass.define_method('remove') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('remove_dir') do |method|
      method.define_argument('path')
      method.define_optional_argument('force')
    end

    klass.define_method('remove_entry') do |method|
      method.define_argument('path')
      method.define_optional_argument('force')
    end

    klass.define_method('remove_entry_secure') do |method|
      method.define_argument('path')
      method.define_optional_argument('force')
    end

    klass.define_method('remove_file') do |method|
      method.define_argument('path')
      method.define_optional_argument('force')
    end

    klass.define_method('rm') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_f') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_r') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_rf') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rmdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rmtree') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('safe_unlink') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('symlink') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('touch') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('uptodate?') do |method|
      method.define_argument('new')
      method.define_argument('old_list')
    end
  end

  defs.define_constant('FileUtils::Verbose::DryRun') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('chdir') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('chmod') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chmod_R') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chown') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chown_R') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('cmp') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('compare_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('compare_stream') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('copy_entry') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy_stream') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('cp') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('cp_r') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('getwd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('identical?') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('install') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('link') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln_s') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln_sf') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('makedirs') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkdir_p') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkpath') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('move') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mv') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('pwd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('remove_dir') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_entry') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_entry_secure') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('rm') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_f') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_r') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_rf') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rmdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rmtree') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('safe_unlink') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('symlink') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('touch') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('uptodate?') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('FileUtils::Verbose::Entry_') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('FileUtils::StreamUtils_', RubyLint.registry))

    klass.define_instance_method('blockdev?')

    klass.define_instance_method('chardev?')

    klass.define_instance_method('chmod') do |method|
      method.define_argument('mode')
    end

    klass.define_instance_method('chown') do |method|
      method.define_argument('uid')
      method.define_argument('gid')
    end

    klass.define_instance_method('copy') do |method|
      method.define_argument('dest')
    end

    klass.define_instance_method('copy_file') do |method|
      method.define_argument('dest')
    end

    klass.define_instance_method('copy_metadata') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('dereference?')

    klass.define_instance_method('directory?')

    klass.define_instance_method('door?')

    klass.define_instance_method('entries')

    klass.define_instance_method('exist?')

    klass.define_instance_method('file?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('a')
      method.define_optional_argument('b')
      method.define_optional_argument('deref')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('lstat')

    klass.define_instance_method('lstat!')

    klass.define_instance_method('path')

    klass.define_instance_method('pipe?')

    klass.define_instance_method('platform_support')

    klass.define_instance_method('postorder_traverse')

    klass.define_instance_method('prefix')

    klass.define_instance_method('preorder_traverse')

    klass.define_instance_method('rel')

    klass.define_instance_method('remove')

    klass.define_instance_method('remove_dir1')

    klass.define_instance_method('remove_file')

    klass.define_instance_method('socket?')

    klass.define_instance_method('stat')

    klass.define_instance_method('stat!')

    klass.define_instance_method('symlink?')

    klass.define_instance_method('traverse')

    klass.define_instance_method('wrap_traverse') do |method|
      method.define_argument('pre')
      method.define_argument('post')
    end
  end

  defs.define_constant('FileUtils::Verbose::LN_SUPPORTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::Verbose::LOW_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::Verbose::LowMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::Verbose::METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::Verbose::NoWrite') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('chdir') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('chmod') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chmod_R') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chown') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('chown_R') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('cmp') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('compare_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('compare_stream') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('copy_entry') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('copy_stream') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('cp') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('cp_r') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('getwd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('identical?') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('install') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('link') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln_s') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('ln_sf') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('makedirs') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkdir_p') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mkpath') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('move') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mv') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('pwd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('remove_dir') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_entry') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_entry_secure') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('remove_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('rm') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_f') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_r') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rm_rf') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rmdir') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('rmtree') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('safe_unlink') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('symlink') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('touch') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('uptodate?') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('FileUtils::Verbose::OPT_TABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::Verbose::RUBY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('FileUtils::Verbose::StreamUtils_') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
