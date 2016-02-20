# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Process') do |defs|
  defs.define_constant('Process') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('abort') do |method|
      method.define_optional_argument('msg')
    end

    klass.define_method('cpu_times')

    klass.define_method('daemon') do |method|
      method.define_optional_argument('stay_in_dir')
      method.define_optional_argument('keep_stdio_open')
    end

    klass.define_method('detach') do |method|
      method.define_argument('pid')
    end

    klass.define_method('egid')

    klass.define_method('egid=') do |method|
      method.define_argument('gid')
    end

    klass.define_method('euid')

    klass.define_method('euid=') do |method|
      method.define_argument('uid')
    end

    klass.define_method('exec') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('exit') do |method|
      method.define_optional_argument('code')
    end

    klass.define_method('exit!') do |method|
      method.define_optional_argument('code')
    end

    klass.define_method('fork')

    klass.define_method('getpgid') do |method|
      method.define_argument('pid')
    end

    klass.define_method('getpgrp')

    klass.define_method('getpriority') do |method|
      method.define_argument('kind')
      method.define_argument('id')
    end

    klass.define_method('getrlimit') do |method|
      method.define_argument('resource')
    end

    klass.define_method('gid')

    klass.define_method('gid=') do |method|
      method.define_argument('gid')
    end

    klass.define_method('groups')

    klass.define_method('groups=') do |method|
      method.define_argument('g')
    end

    klass.define_method('initgroups') do |method|
      method.define_argument('username')
      method.define_argument('gid')
    end

    klass.define_method('kill') do |method|
      method.define_argument('signal')
      method.define_rest_argument('pids')
    end

    klass.define_method('maxgroups')

    klass.define_method('maxgroups=') do |method|
      method.define_argument('m')
    end

    klass.define_method('perform_exec') do |method|
      method.define_argument('file')
      method.define_argument('args')
    end

    klass.define_method('perform_fork')

    klass.define_method('pid')

    klass.define_method('ppid')

    klass.define_method('replace') do |method|
      method.define_argument('str')
    end

    klass.define_method('set_status_global') do |method|
      method.define_argument('status')
    end

    klass.define_method('setpgid') do |method|
      method.define_argument('pid')
      method.define_argument('int')
    end

    klass.define_method('setpgrp')

    klass.define_method('setpriority') do |method|
      method.define_argument('kind')
      method.define_argument('id')
      method.define_argument('priority')
    end

    klass.define_method('setproctitle') do |method|
      method.define_argument('title')
    end

    klass.define_method('setrlimit') do |method|
      method.define_argument('resource')
      method.define_argument('cur_limit')
      method.define_optional_argument('max_limit')
    end

    klass.define_method('setsid')

    klass.define_method('spawn') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('time')

    klass.define_method('times')

    klass.define_method('uid')

    klass.define_method('uid=') do |method|
      method.define_argument('uid')
    end

    klass.define_method('wait') do |method|
      method.define_optional_argument('pid')
      method.define_optional_argument('flags')
    end

    klass.define_method('wait2') do |method|
      method.define_optional_argument('input_pid')
      method.define_optional_argument('flags')
    end

    klass.define_method('wait_pid_prim') do |method|
      method.define_argument('pid')
      method.define_argument('no_hang')
    end

    klass.define_method('waitall')

    klass.define_method('waitpid') do |method|
      method.define_optional_argument('pid')
      method.define_optional_argument('flags')
    end

    klass.define_method('waitpid2') do |method|
      method.define_optional_argument('input_pid')
      method.define_optional_argument('flags')
    end
  end

  defs.define_constant('Process::Constants') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::EXIT_FAILURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::EXIT_SUCCESS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::PRIO_PGRP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::PRIO_PROCESS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::PRIO_USER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_AS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_CORE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_CPU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_DATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_FSIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_MEMLOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_MSGQUEUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_NICE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_NOFILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_NPROC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_RSS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_RTPRIO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_RTTIME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_SBSIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_SIGPENDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIMIT_STACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIM_INFINITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIM_SAVED_CUR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::RLIM_SAVED_MAX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::WNOHANG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Constants::WUNTRACED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::EXIT_FAILURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::EXIT_SUCCESS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::FFI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_typedef') do |method|
      method.define_argument('current')
      method.define_argument('add')
    end

    klass.define_method('config') do |method|
      method.define_argument('name')
    end

    klass.define_method('config_hash') do |method|
      method.define_argument('name')
    end

    klass.define_method('errno')

    klass.define_method('find_type') do |method|
      method.define_argument('name')
    end

    klass.define_method('generate_function') do |method|
      method.define_argument('ptr')
      method.define_argument('name')
      method.define_argument('args')
      method.define_argument('ret')
    end

    klass.define_method('generate_trampoline') do |method|
      method.define_argument('obj')
      method.define_argument('name')
      method.define_argument('args')
      method.define_argument('ret')
    end

    klass.define_method('size_to_type') do |method|
      method.define_argument('size')
    end

    klass.define_method('type_size') do |method|
      method.define_argument('type')
    end
  end

  defs.define_constant('Process::GID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('change_privilege') do |method|
      method.define_argument('gid')
    end

    klass.define_method('eid')

    klass.define_method('eid=') do |method|
      method.define_argument('gid')
    end

    klass.define_method('grant_privilege') do |method|
      method.define_argument('gid')
    end

    klass.define_method('re_exchange')

    klass.define_method('re_exchangeable?')

    klass.define_method('rid')

    klass.define_method('sid_available?')

    klass.define_method('switch')
  end

  defs.define_constant('Process::PRIO_PGRP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::PRIO_PROCESS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::PRIO_USER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_AS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_CORE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_CPU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_DATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_FSIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_MEMLOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_MSGQUEUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_NICE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_NOFILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_NPROC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_RSS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_RTPRIO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_RTTIME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_SBSIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_SIGPENDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIMIT_STACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIM_INFINITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIM_SAVED_CUR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::RLIM_SAVED_MAX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::Rlimit') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

  end

  defs.define_constant('Process::Rlimit::InlineArray') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('idx')
      method.define_argument('val')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('type')
      method.define_argument('ptr')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('size')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_ptr')
  end

  defs.define_constant('Process::Rlimit::InlineCharArray') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct::InlineArray', RubyLint.registry))

    klass.define_instance_method('inspect')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_str')
  end

  defs.define_constant('Process::Status') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('&') do |method|
      method.define_argument('num')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>>') do |method|
      method.define_argument('num')
    end

    klass.define_instance_method('coredump?')

    klass.define_instance_method('exited?')

    klass.define_instance_method('exitstatus')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('pid')
      method.define_argument('exitstatus')
      method.define_optional_argument('termsig')
      method.define_optional_argument('stopsig')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('pid')

    klass.define_instance_method('signaled?')

    klass.define_instance_method('stopped?')

    klass.define_instance_method('stopsig')

    klass.define_instance_method('success?')

    klass.define_instance_method('termsig')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Process::Sys') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('getegid')

    klass.define_method('geteuid')

    klass.define_method('getgid')

    klass.define_method('getuid')

    klass.define_method('issetugid')

    klass.define_method('setegid') do |method|
      method.define_argument('egid')
    end

    klass.define_method('seteuid') do |method|
      method.define_argument('euid')
    end

    klass.define_method('setgid') do |method|
      method.define_argument('gid')
    end

    klass.define_method('setregid') do |method|
      method.define_argument('rid')
      method.define_argument('eid')
    end

    klass.define_method('setresgid') do |method|
      method.define_argument('rid')
      method.define_argument('eid')
      method.define_argument('sid')
    end

    klass.define_method('setresuid') do |method|
      method.define_argument('rid')
      method.define_argument('eid')
      method.define_argument('sid')
    end

    klass.define_method('setreuid') do |method|
      method.define_argument('rid')
      method.define_argument('eid')
    end

    klass.define_method('setrgid') do |method|
      method.define_argument('rgid')
    end

    klass.define_method('setruid') do |method|
      method.define_argument('ruid')
    end

    klass.define_method('setuid') do |method|
      method.define_argument('uid')
    end
  end

  defs.define_constant('Process::UID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('change_privilege') do |method|
      method.define_argument('uid')
    end

    klass.define_method('eid')

    klass.define_method('eid=') do |method|
      method.define_argument('uid')
    end

    klass.define_method('grant_privilege') do |method|
      method.define_argument('uid')
    end

    klass.define_method('re_exchange')

    klass.define_method('re_exchangeable?')

    klass.define_method('rid')

    klass.define_method('sid_available?')

    klass.define_method('switch')
  end

  defs.define_constant('Process::WNOHANG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Process::WUNTRACED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
