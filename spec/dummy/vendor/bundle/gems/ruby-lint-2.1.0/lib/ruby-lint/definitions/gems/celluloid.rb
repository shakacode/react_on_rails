# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: ruby 2.1.2

RubyLint.registry.register('Celluloid') do |defs|
  defs.define_constant('Celluloid') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('actor?')

    klass.define_method('boot')

    klass.define_method('cores')

    klass.define_method('cpus')

    klass.define_method('detect_recursion')

    klass.define_method('dump') do |method|
      method.define_optional_argument('output')
    end

    klass.define_method('exception_handler') do |method|
      method.define_block_argument('block')
    end

    klass.define_method('included') do |method|
      method.define_argument('klass')
    end

    klass.define_method('init')

    klass.define_method('internal_pool')

    klass.define_method('internal_pool=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('logger')

    klass.define_method('logger=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('mailbox')

    klass.define_method('ncpus')

    klass.define_method('register_shutdown')

    klass.define_method('running?')

    klass.define_method('shutdown')

    klass.define_method('shutdown_timeout')

    klass.define_method('shutdown_timeout=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('stack_dump') do |method|
      method.define_optional_argument('output')
    end

    klass.define_method('start')

    klass.define_method('suspend') do |method|
      method.define_argument('status')
      method.define_argument('waiter')
    end

    klass.define_method('task_class')

    klass.define_method('task_class=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('uuid')

    klass.define_method('version')

    klass.define_instance_method('abort') do |method|
      method.define_argument('cause')
    end

    klass.define_instance_method('after') do |method|
      method.define_argument('interval')
      method.define_block_argument('block')
    end

    klass.define_instance_method('async') do |method|
      method.define_optional_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('call_chain_id')

    klass.define_instance_method('current_actor')

    klass.define_instance_method('defer') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('every') do |method|
      method.define_argument('interval')
      method.define_block_argument('block')
    end

    klass.define_instance_method('exclusive') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('exclusive?')

    klass.define_instance_method('future') do |method|
      method.define_optional_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('link') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('linked_to?') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('links')

    klass.define_instance_method('monitor') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('monitoring?') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('receive') do |method|
      method.define_optional_argument('timeout')
      method.define_block_argument('block')
    end

    klass.define_instance_method('signal') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
    end

    klass.define_instance_method('sleep') do |method|
      method.define_argument('interval')
    end

    klass.define_instance_method('tasks')

    klass.define_instance_method('terminate')

    klass.define_instance_method('timeout') do |method|
      method.define_argument('duration')
    end

    klass.define_instance_method('unlink') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('unmonitor') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('wait') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('Celluloid::AbortError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

    klass.define_instance_method('cause')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('cause')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Celluloid::AbstractProxy') do |klass|
    klass.inherits(defs.constant_proxy('BasicObject', RubyLint.registry))

    klass.define_instance_method('__class__')
  end

  defs.define_constant('Celluloid::AbstractProxy::BasicObject') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('!')

    klass.define_instance_method('!=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('__id__')

    klass.define_instance_method('__send__') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('equal?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('instance_eval') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('instance_exec') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::AbstractProxy::RUBYGEMS_ACTIVATION_MONITOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Actor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('[]=') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('all')

    klass.define_method('async') do |method|
      method.define_argument('mailbox')
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('call') do |method|
      method.define_argument('mailbox')
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('clear_registry')

    klass.define_method('current')

    klass.define_method('future') do |method|
      method.define_argument('mailbox')
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('join') do |method|
      method.define_argument('actor')
      method.define_optional_argument('timeout')
    end

    klass.define_method('kill') do |method|
      method.define_argument('actor')
    end

    klass.define_method('link') do |method|
      method.define_argument('actor')
    end

    klass.define_method('linked_to?') do |method|
      method.define_argument('actor')
    end

    klass.define_method('monitor') do |method|
      method.define_argument('actor')
    end

    klass.define_method('monitoring?') do |method|
      method.define_argument('actor')
    end

    klass.define_method('name')

    klass.define_method('registered')

    klass.define_method('unlink') do |method|
      method.define_argument('actor')
    end

    klass.define_method('unmonitor') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('after') do |method|
      method.define_argument('interval')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cleanup') do |method|
      method.define_argument('exit_event')
    end

    klass.define_instance_method('every') do |method|
      method.define_argument('interval')
      method.define_block_argument('block')
    end

    klass.define_instance_method('handle_crash') do |method|
      method.define_argument('exception')
    end

    klass.define_instance_method('handle_exit_event') do |method|
      method.define_argument('event')
    end

    klass.define_instance_method('handle_message') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('handle_system_event') do |method|
      method.define_argument('event')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('subject')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('linking_request') do |method|
      method.define_argument('receiver')
      method.define_argument('type')
    end

    klass.define_instance_method('links')

    klass.define_instance_method('mailbox')

    klass.define_instance_method('name')

    klass.define_instance_method('proxy')

    klass.define_instance_method('receive') do |method|
      method.define_optional_argument('timeout')
      method.define_block_argument('block')
    end

    klass.define_instance_method('run')

    klass.define_instance_method('run_finalizer')

    klass.define_instance_method('setup_thread')

    klass.define_instance_method('shutdown') do |method|
      method.define_optional_argument('exit_event')
    end

    klass.define_instance_method('signal') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
    end

    klass.define_instance_method('sleep') do |method|
      method.define_argument('interval')
    end

    klass.define_instance_method('subject')

    klass.define_instance_method('task') do |method|
      method.define_argument('task_type')
      method.define_optional_argument('meta')
    end

    klass.define_instance_method('tasks')

    klass.define_instance_method('terminate')

    klass.define_instance_method('thread')

    klass.define_instance_method('timeout') do |method|
      method.define_argument('duration')
    end

    klass.define_instance_method('timeout_interval')

    klass.define_instance_method('wait') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('Celluloid::Actor::Sleeper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('before_suspend') do |method|
      method.define_argument('task')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('timers')
      method.define_argument('interval')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('wait')
  end

  defs.define_constant('Celluloid::ActorProxy') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SyncProxy', RubyLint.registry))

    klass.define_instance_method('__class__')

    klass.define_instance_method('_send_') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('alive?')

    klass.define_instance_method('async') do |method|
      method.define_optional_argument('method_name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('future') do |method|
      method.define_optional_argument('method_name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('actor')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('method') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('sync') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('terminate')

    klass.define_instance_method('terminate!')

    klass.define_instance_method('thread')
  end

  defs.define_constant('Celluloid::ActorProxy::BasicObject') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('!')

    klass.define_instance_method('!=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('__id__')

    klass.define_instance_method('__send__') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('equal?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('instance_eval') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('instance_exec') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::ActorProxy::RUBYGEMS_ACTIVATION_MONITOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::AsyncCall') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Call', RubyLint.registry))

    klass.define_instance_method('dispatch') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('Celluloid::AsyncProxy') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::AbstractProxy', RubyLint.registry))

    klass.define_instance_method('__class__')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mailbox')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('mailbox')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Celluloid::AsyncProxy::BasicObject') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('!')

    klass.define_instance_method('!=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('__id__')

    klass.define_instance_method('__send__') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('equal?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('instance_eval') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('instance_exec') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::AsyncProxy::RUBYGEMS_ACTIVATION_MONITOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::BARE_OBJECT_WARNING_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::BlockCall') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call')

    klass.define_instance_method('dispatch')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('block_proxy')
      method.define_argument('sender')
      method.define_argument('arguments')
      method.define_optional_argument('task')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('task')
  end

  defs.define_constant('Celluloid::BlockProxy') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('block')

    klass.define_instance_method('call')

    klass.define_instance_method('execution=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('call')
      method.define_argument('mailbox')
      method.define_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_proc')
  end

  defs.define_constant('Celluloid::BlockResponse') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('dispatch')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('call')
      method.define_argument('result')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Celluloid::CPUCounter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cores')
  end

  defs.define_constant('Celluloid::Call') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('arguments')

    klass.define_instance_method('block')

    klass.define_instance_method('dispatch') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('execute_block_on_receiver')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('method')
      method.define_optional_argument('arguments')
      method.define_optional_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method')
  end

  defs.define_constant('Celluloid::CallChain') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('current_id')

    klass.define_method('current_id=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Celluloid::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('actor_options')

    klass.define_instance_method('exclusive') do |method|
      method.define_rest_argument('methods')
    end

    klass.define_instance_method('new') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('new_link') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pool') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('pool_link') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('spawn') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('spawn_link') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('supervise') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('supervise_as') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Celluloid::Condition') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')

    klass.define_instance_method('signal') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('wait')
  end

  defs.define_constant('Celluloid::Condition::Waiter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('condition')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('condition')
      method.define_argument('task')
      method.define_argument('mailbox')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('task')

    klass.define_instance_method('wait')
  end

  defs.define_constant('Celluloid::ConditionError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::DeadActorError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::DeadTaskError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Celluloid::ErrorResponse') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Response', RubyLint.registry))

    klass.define_instance_method('value')
  end

  defs.define_constant('Celluloid::EventedMailbox') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Mailbox', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('reactor_class')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next_message') do |method|
      method.define_argument('block')
    end

    klass.define_instance_method('reactor')

    klass.define_instance_method('receive') do |method|
      method.define_optional_argument('timeout')
      method.define_block_argument('block')
    end

    klass.define_instance_method('shutdown')
  end

  defs.define_constant('Celluloid::ExitEvent') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SystemEvent', RubyLint.registry))

    klass.define_instance_method('actor')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('actor')
      method.define_optional_argument('reason')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('reason')
  end

  defs.define_constant('Celluloid::FSM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('actor')

    klass.define_instance_method('actor=') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('attach') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('current_state')

    klass.define_instance_method('current_state_name')

    klass.define_instance_method('default_state')

    klass.define_instance_method('handle_delayed_transitions') do |method|
      method.define_argument('new_state')
      method.define_argument('delay')
    end

    klass.define_instance_method('state')

    klass.define_instance_method('states')

    klass.define_instance_method('transition') do |method|
      method.define_argument('state_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('transition!') do |method|
      method.define_argument('state_name')
    end

    klass.define_instance_method('transition_with_callbacks!') do |method|
      method.define_argument('state_name')
    end

    klass.define_instance_method('validate_and_sanitize_new_state') do |method|
      method.define_argument('state_name')
    end
  end

  defs.define_constant('Celluloid::FSM::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('default_state') do |method|
      method.define_optional_argument('new_default')
    end

    klass.define_instance_method('state') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('states')
  end

  defs.define_constant('Celluloid::FSM::DEFAULT_STATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::FSM::State') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_optional_argument('transitions')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('transitions')

    klass.define_instance_method('valid_transition?') do |method|
      method.define_argument('new_state')
    end
  end

  defs.define_constant('Celluloid::FSM::UnattachedError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::FiberStackError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Future') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('address')

    klass.define_instance_method('call') do |method|
      method.define_optional_argument('timeout')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')

    klass.define_instance_method('ready?')

    klass.define_instance_method('signal') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('value') do |method|
      method.define_optional_argument('timeout')
    end
  end

  defs.define_constant('Celluloid::Future::Result') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('future')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('result')
      method.define_argument('future')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('value')
  end

  defs.define_constant('Celluloid::FutureProxy') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::AbstractProxy', RubyLint.registry))

    klass.define_instance_method('__class__')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mailbox')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('mailbox')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Celluloid::FutureProxy::BasicObject') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('!')

    klass.define_instance_method('!=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('__id__')

    klass.define_instance_method('__send__') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('equal?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('instance_eval') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('instance_exec') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::FutureProxy::RUBYGEMS_ACTIVATION_MONITOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Incident') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('events')

    klass.define_instance_method('events=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('events')
      method.define_optional_argument('triggering_event')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('merge') do |method|
      method.define_rest_argument('other_incidents')
    end

    klass.define_instance_method('pid')

    klass.define_instance_method('pid=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('triggering_event')

    klass.define_instance_method('triggering_event=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::IncidentLogger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid::IncidentLogger::Severity', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Logger::Severity', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('severity')
      method.define_optional_argument('message')
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('buffers')

    klass.define_instance_method('buffers=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('create_incident') do |method|
      method.define_optional_argument('event')
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

    klass.define_instance_method('flush')

    klass.define_instance_method('incident_topic')

    klass.define_instance_method('info') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('progname')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('level')

    klass.define_instance_method('level=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('log') do |method|
      method.define_argument('severity')
      method.define_optional_argument('message')
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('progname')

    klass.define_instance_method('progname=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('sizelimit')

    klass.define_instance_method('sizelimit=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('threshold')

    klass.define_instance_method('threshold=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('trace') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
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

  defs.define_constant('Celluloid::IncidentReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid::Notifications', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid::InstanceMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid', RubyLint.registry))

    klass.define_method('execute_block_on_receiver') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('exit_handler') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('finalizer') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('mailbox_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('mailbox_size') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('proxy_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('task_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('trap_exit') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('report') do |method|
      method.define_argument('topic')
      method.define_argument('incident')
    end

    klass.define_instance_method('silence')

    klass.define_instance_method('silenced?')

    klass.define_instance_method('unsilence')
  end

  defs.define_constant('Celluloid::InstanceMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('bare_object')

    klass.define_instance_method('inspect')

    klass.define_instance_method('leaked?')

    klass.define_instance_method('name')

    klass.define_instance_method('tap')

    klass.define_instance_method('wrapped_object')
  end

  defs.define_constant('Celluloid::InternalPool') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('active?')

    klass.define_instance_method('assert_inactive')

    klass.define_instance_method('assert_running')

    klass.define_instance_method('busy_size')

    klass.define_instance_method('clean_thread_locals') do |method|
      method.define_argument('thread')
    end

    klass.define_instance_method('create')

    klass.define_instance_method('each')

    klass.define_instance_method('get') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('idle_size')

    klass.define_instance_method('initialize')

    klass.define_instance_method('kill')

    klass.define_instance_method('max_idle')

    klass.define_instance_method('max_idle=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('put') do |method|
      method.define_argument('thread')
    end

    klass.define_instance_method('running?')

    klass.define_instance_method('shutdown')

    klass.define_instance_method('to_a')
  end

  defs.define_constant('Celluloid::LINKING_TIMEOUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::LinkingRequest') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SystemEvent', RubyLint.registry))

    klass.define_instance_method('actor')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('actor')
      method.define_argument('type')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('process') do |method|
      method.define_argument('links')
    end

    klass.define_instance_method('type')
  end

  defs.define_constant('Celluloid::LinkingResponse') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('actor')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('actor')
      method.define_argument('type')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('type')
  end

  defs.define_constant('Celluloid::Links') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('include?') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Celluloid::LogEvent') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('id')

    klass.define_instance_method('id=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('severity')
      method.define_argument('message')
      method.define_argument('progname')
      method.define_optional_argument('time')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('message')

    klass.define_instance_method('message=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('progname')

    klass.define_instance_method('progname=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('severity')

    klass.define_instance_method('severity=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('time')

    klass.define_instance_method('time=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::Logger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('crash') do |method|
      method.define_argument('string')
      method.define_argument('exception')
    end

    klass.define_method('debug') do |method|
      method.define_argument('string')
    end

    klass.define_method('deprecate') do |method|
      method.define_argument('message')
    end

    klass.define_method('error') do |method|
      method.define_argument('string')
    end

    klass.define_method('exception_handler') do |method|
      method.define_block_argument('block')
    end

    klass.define_method('format_exception') do |method|
      method.define_argument('exception')
    end

    klass.define_method('info') do |method|
      method.define_argument('string')
    end

    klass.define_method('warn') do |method|
      method.define_argument('string')
    end
  end

  defs.define_constant('Celluloid::Mailbox') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('address')

    klass.define_instance_method('alive?')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')

    klass.define_instance_method('max_size')

    klass.define_instance_method('max_size=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('next_message')

    klass.define_instance_method('receive') do |method|
      method.define_optional_argument('timeout')
      method.define_block_argument('block')
    end

    klass.define_instance_method('shutdown')

    klass.define_instance_method('size')

    klass.define_instance_method('to_a')
  end

  defs.define_constant('Celluloid::MailboxDead') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::MailboxShutdown') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Method') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('arity')

    klass.define_instance_method('call') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('proxy')
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Celluloid::NamingRequest') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SystemEvent', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')
  end

  defs.define_constant('Celluloid::NotActorError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::NotTaskError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Notifications') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('notifier')

    klass.define_instance_method('publish') do |method|
      method.define_argument('pattern')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('subscribe') do |method|
      method.define_argument('pattern')
      method.define_argument('method')
    end

    klass.define_instance_method('unsubscribe') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Celluloid::OWNER_IVAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid::InstanceMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid', RubyLint.registry))

    klass.define_method('execute_block_on_receiver') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('exit_handler') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('finalizer') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('mailbox_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('mailbox_size') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('proxy_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('task_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('trap_exit') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('__crash_handler__') do |method|
      method.define_argument('actor')
      method.define_argument('reason')
    end

    klass.define_instance_method('__provision_worker__')

    klass.define_instance_method('__shutdown__')

    klass.define_instance_method('_send_') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('busy_size')

    klass.define_instance_method('idle_size')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('worker_class')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('is_a?') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('kind_of?') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('methods') do |method|
      method.define_optional_argument('include_ancestors')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('method')
      method.define_optional_argument('include_private')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Celluloid::PoolManager::AbortError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

    klass.define_instance_method('cause')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('cause')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Celluloid::PoolManager::AbstractProxy') do |klass|
    klass.inherits(defs.constant_proxy('BasicObject', RubyLint.registry))

    klass.define_instance_method('__class__')
  end

  defs.define_constant('Celluloid::PoolManager::Actor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('[]=') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('all')

    klass.define_method('async') do |method|
      method.define_argument('mailbox')
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('call') do |method|
      method.define_argument('mailbox')
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('clear_registry')

    klass.define_method('current')

    klass.define_method('future') do |method|
      method.define_argument('mailbox')
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('join') do |method|
      method.define_argument('actor')
      method.define_optional_argument('timeout')
    end

    klass.define_method('kill') do |method|
      method.define_argument('actor')
    end

    klass.define_method('link') do |method|
      method.define_argument('actor')
    end

    klass.define_method('linked_to?') do |method|
      method.define_argument('actor')
    end

    klass.define_method('monitor') do |method|
      method.define_argument('actor')
    end

    klass.define_method('monitoring?') do |method|
      method.define_argument('actor')
    end

    klass.define_method('name')

    klass.define_method('registered')

    klass.define_method('unlink') do |method|
      method.define_argument('actor')
    end

    klass.define_method('unmonitor') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('after') do |method|
      method.define_argument('interval')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cleanup') do |method|
      method.define_argument('exit_event')
    end

    klass.define_instance_method('every') do |method|
      method.define_argument('interval')
      method.define_block_argument('block')
    end

    klass.define_instance_method('handle_crash') do |method|
      method.define_argument('exception')
    end

    klass.define_instance_method('handle_exit_event') do |method|
      method.define_argument('event')
    end

    klass.define_instance_method('handle_message') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('handle_system_event') do |method|
      method.define_argument('event')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('subject')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('linking_request') do |method|
      method.define_argument('receiver')
      method.define_argument('type')
    end

    klass.define_instance_method('links')

    klass.define_instance_method('mailbox')

    klass.define_instance_method('name')

    klass.define_instance_method('proxy')

    klass.define_instance_method('receive') do |method|
      method.define_optional_argument('timeout')
      method.define_block_argument('block')
    end

    klass.define_instance_method('run')

    klass.define_instance_method('run_finalizer')

    klass.define_instance_method('setup_thread')

    klass.define_instance_method('shutdown') do |method|
      method.define_optional_argument('exit_event')
    end

    klass.define_instance_method('signal') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
    end

    klass.define_instance_method('sleep') do |method|
      method.define_argument('interval')
    end

    klass.define_instance_method('subject')

    klass.define_instance_method('task') do |method|
      method.define_argument('task_type')
      method.define_optional_argument('meta')
    end

    klass.define_instance_method('tasks')

    klass.define_instance_method('terminate')

    klass.define_instance_method('thread')

    klass.define_instance_method('timeout') do |method|
      method.define_argument('duration')
    end

    klass.define_instance_method('timeout_interval')

    klass.define_instance_method('wait') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('Celluloid::PoolManager::ActorProxy') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SyncProxy', RubyLint.registry))

    klass.define_instance_method('__class__')

    klass.define_instance_method('_send_') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('alive?')

    klass.define_instance_method('async') do |method|
      method.define_optional_argument('method_name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('future') do |method|
      method.define_optional_argument('method_name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('actor')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('method') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('sync') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('terminate')

    klass.define_instance_method('terminate!')

    klass.define_instance_method('thread')
  end

  defs.define_constant('Celluloid::PoolManager::AsyncCall') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Call', RubyLint.registry))

    klass.define_instance_method('dispatch') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('Celluloid::PoolManager::AsyncProxy') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::AbstractProxy', RubyLint.registry))

    klass.define_instance_method('__class__')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mailbox')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('mailbox')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Celluloid::PoolManager::BARE_OBJECT_WARNING_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::BlockCall') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call')

    klass.define_instance_method('dispatch')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('block_proxy')
      method.define_argument('sender')
      method.define_argument('arguments')
      method.define_optional_argument('task')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('task')
  end

  defs.define_constant('Celluloid::PoolManager::BlockProxy') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('block')

    klass.define_instance_method('call')

    klass.define_instance_method('execution=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('call')
      method.define_argument('mailbox')
      method.define_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_proc')
  end

  defs.define_constant('Celluloid::PoolManager::BlockResponse') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('dispatch')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('call')
      method.define_argument('result')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Celluloid::PoolManager::CPUCounter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cores')
  end

  defs.define_constant('Celluloid::PoolManager::Call') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('arguments')

    klass.define_instance_method('block')

    klass.define_instance_method('dispatch') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('execute_block_on_receiver')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('method')
      method.define_optional_argument('arguments')
      method.define_optional_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method')
  end

  defs.define_constant('Celluloid::PoolManager::CallChain') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('current_id')

    klass.define_method('current_id=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Celluloid::PoolManager::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('actor_options')

    klass.define_instance_method('exclusive') do |method|
      method.define_rest_argument('methods')
    end

    klass.define_instance_method('new') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('new_link') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pool') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('pool_link') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('spawn') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('spawn_link') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('supervise') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('supervise_as') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Celluloid::PoolManager::Condition') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')

    klass.define_instance_method('signal') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('wait')
  end

  defs.define_constant('Celluloid::PoolManager::ConditionError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::DeadActorError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::DeadTaskError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::ErrorResponse') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Response', RubyLint.registry))

    klass.define_instance_method('value')
  end

  defs.define_constant('Celluloid::PoolManager::EventedMailbox') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Mailbox', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('reactor_class')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next_message') do |method|
      method.define_argument('block')
    end

    klass.define_instance_method('reactor')

    klass.define_instance_method('receive') do |method|
      method.define_optional_argument('timeout')
      method.define_block_argument('block')
    end

    klass.define_instance_method('shutdown')
  end

  defs.define_constant('Celluloid::PoolManager::ExitEvent') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SystemEvent', RubyLint.registry))

    klass.define_instance_method('actor')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('actor')
      method.define_optional_argument('reason')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('reason')
  end

  defs.define_constant('Celluloid::PoolManager::FSM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('actor')

    klass.define_instance_method('actor=') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('attach') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('current_state')

    klass.define_instance_method('current_state_name')

    klass.define_instance_method('default_state')

    klass.define_instance_method('handle_delayed_transitions') do |method|
      method.define_argument('new_state')
      method.define_argument('delay')
    end

    klass.define_instance_method('state')

    klass.define_instance_method('states')

    klass.define_instance_method('transition') do |method|
      method.define_argument('state_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('transition!') do |method|
      method.define_argument('state_name')
    end

    klass.define_instance_method('transition_with_callbacks!') do |method|
      method.define_argument('state_name')
    end

    klass.define_instance_method('validate_and_sanitize_new_state') do |method|
      method.define_argument('state_name')
    end
  end

  defs.define_constant('Celluloid::PoolManager::FiberStackError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::Future') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('address')

    klass.define_instance_method('call') do |method|
      method.define_optional_argument('timeout')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')

    klass.define_instance_method('ready?')

    klass.define_instance_method('signal') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('value') do |method|
      method.define_optional_argument('timeout')
    end
  end

  defs.define_constant('Celluloid::PoolManager::FutureProxy') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::AbstractProxy', RubyLint.registry))

    klass.define_instance_method('__class__')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mailbox')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('mailbox')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Celluloid::PoolManager::Incident') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('events')

    klass.define_instance_method('events=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('events')
      method.define_optional_argument('triggering_event')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('merge') do |method|
      method.define_rest_argument('other_incidents')
    end

    klass.define_instance_method('pid')

    klass.define_instance_method('pid=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('triggering_event')

    klass.define_instance_method('triggering_event=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::PoolManager::IncidentLogger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid::IncidentLogger::Severity', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Logger::Severity', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('severity')
      method.define_optional_argument('message')
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('buffers')

    klass.define_instance_method('buffers=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('create_incident') do |method|
      method.define_optional_argument('event')
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

    klass.define_instance_method('flush')

    klass.define_instance_method('incident_topic')

    klass.define_instance_method('info') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('progname')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('level')

    klass.define_instance_method('level=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('log') do |method|
      method.define_argument('severity')
      method.define_optional_argument('message')
      method.define_optional_argument('progname')
      method.define_block_argument('block')
    end

    klass.define_instance_method('progname')

    klass.define_instance_method('progname=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('sizelimit')

    klass.define_instance_method('sizelimit=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('threshold')

    klass.define_instance_method('threshold=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('trace') do |method|
      method.define_optional_argument('progname')
      method.define_block_argument('block')
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

  defs.define_constant('Celluloid::PoolManager::IncidentReporter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid::Notifications', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid::InstanceMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid', RubyLint.registry))

    klass.define_method('execute_block_on_receiver') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('exit_handler') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('finalizer') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('mailbox_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('mailbox_size') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('proxy_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('task_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('trap_exit') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('report') do |method|
      method.define_argument('topic')
      method.define_argument('incident')
    end

    klass.define_instance_method('silence')

    klass.define_instance_method('silenced?')

    klass.define_instance_method('unsilence')
  end

  defs.define_constant('Celluloid::PoolManager::InstanceMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('bare_object')

    klass.define_instance_method('inspect')

    klass.define_instance_method('leaked?')

    klass.define_instance_method('name')

    klass.define_instance_method('tap')

    klass.define_instance_method('wrapped_object')
  end

  defs.define_constant('Celluloid::PoolManager::InternalPool') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('active?')

    klass.define_instance_method('assert_inactive')

    klass.define_instance_method('assert_running')

    klass.define_instance_method('busy_size')

    klass.define_instance_method('clean_thread_locals') do |method|
      method.define_argument('thread')
    end

    klass.define_instance_method('create')

    klass.define_instance_method('each')

    klass.define_instance_method('get') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('idle_size')

    klass.define_instance_method('initialize')

    klass.define_instance_method('kill')

    klass.define_instance_method('max_idle')

    klass.define_instance_method('max_idle=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('put') do |method|
      method.define_argument('thread')
    end

    klass.define_instance_method('running?')

    klass.define_instance_method('shutdown')

    klass.define_instance_method('to_a')
  end

  defs.define_constant('Celluloid::PoolManager::LINKING_TIMEOUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::LinkingRequest') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SystemEvent', RubyLint.registry))

    klass.define_instance_method('actor')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('actor')
      method.define_argument('type')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('process') do |method|
      method.define_argument('links')
    end

    klass.define_instance_method('type')
  end

  defs.define_constant('Celluloid::PoolManager::LinkingResponse') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('actor')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('actor')
      method.define_argument('type')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('type')
  end

  defs.define_constant('Celluloid::PoolManager::Links') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('include?') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Celluloid::PoolManager::LogEvent') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('id')

    klass.define_instance_method('id=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('severity')
      method.define_argument('message')
      method.define_argument('progname')
      method.define_optional_argument('time')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('message')

    klass.define_instance_method('message=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('progname')

    klass.define_instance_method('progname=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('severity')

    klass.define_instance_method('severity=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('time')

    klass.define_instance_method('time=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::PoolManager::Logger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('crash') do |method|
      method.define_argument('string')
      method.define_argument('exception')
    end

    klass.define_method('debug') do |method|
      method.define_argument('string')
    end

    klass.define_method('deprecate') do |method|
      method.define_argument('message')
    end

    klass.define_method('error') do |method|
      method.define_argument('string')
    end

    klass.define_method('exception_handler') do |method|
      method.define_block_argument('block')
    end

    klass.define_method('format_exception') do |method|
      method.define_argument('exception')
    end

    klass.define_method('info') do |method|
      method.define_argument('string')
    end

    klass.define_method('warn') do |method|
      method.define_argument('string')
    end
  end

  defs.define_constant('Celluloid::PoolManager::Mailbox') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('address')

    klass.define_instance_method('alive?')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('inspect')

    klass.define_instance_method('max_size')

    klass.define_instance_method('max_size=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('next_message')

    klass.define_instance_method('receive') do |method|
      method.define_optional_argument('timeout')
      method.define_block_argument('block')
    end

    klass.define_instance_method('shutdown')

    klass.define_instance_method('size')

    klass.define_instance_method('to_a')
  end

  defs.define_constant('Celluloid::PoolManager::MailboxDead') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::MailboxShutdown') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::Method') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('arity')

    klass.define_instance_method('call') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('proxy')
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Celluloid::PoolManager::NamingRequest') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SystemEvent', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')
  end

  defs.define_constant('Celluloid::PoolManager::NotActorError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::NotTaskError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::Notifications') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('notifier')

    klass.define_instance_method('publish') do |method|
      method.define_argument('pattern')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('subscribe') do |method|
      method.define_argument('pattern')
      method.define_argument('method')
    end

    klass.define_instance_method('unsubscribe') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Celluloid::PoolManager::OWNER_IVAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::Properties') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('property') do |method|
      method.define_argument('name')
      method.define_optional_argument('opts')
    end
  end

  defs.define_constant('Celluloid::PoolManager::Receiver') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('match') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('resume') do |method|
      method.define_optional_argument('message')
    end

    klass.define_instance_method('timer')

    klass.define_instance_method('timer=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::PoolManager::Receivers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('fire_timers')

    klass.define_instance_method('handle_message') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('receive') do |method|
      method.define_optional_argument('timeout')
      method.define_block_argument('block')
    end

    klass.define_instance_method('wait_interval')
  end

  defs.define_constant('Celluloid::PoolManager::Registry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('root')

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('actor')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('delete') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('get') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('names')

    klass.define_instance_method('set') do |method|
      method.define_argument('name')
      method.define_argument('actor')
    end
  end

  defs.define_constant('Celluloid::PoolManager::Response') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call')

    klass.define_instance_method('dispatch')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('call')
      method.define_argument('value')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('value')
  end

  defs.define_constant('Celluloid::PoolManager::ResumableError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::RingBuffer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('empty?')

    klass.define_instance_method('flush')

    klass.define_instance_method('full?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('size')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('shift')
  end

  defs.define_constant('Celluloid::PoolManager::SignalConditionRequest') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SystemEvent', RubyLint.registry))

    klass.define_instance_method('call')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('task')
      method.define_argument('value')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('task')

    klass.define_instance_method('value')
  end

  defs.define_constant('Celluloid::PoolManager::Signals') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('wait') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('Celluloid::PoolManager::StackDump') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('actors')

    klass.define_instance_method('actors=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('dump') do |method|
      method.define_optional_argument('output')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('snapshot')

    klass.define_instance_method('snapshot_actor') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('snapshot_thread') do |method|
      method.define_argument('thread')
    end

    klass.define_instance_method('threads')

    klass.define_instance_method('threads=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::PoolManager::SuccessResponse') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Response', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::SupervisionGroup') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid::InstanceMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid', RubyLint.registry))

    klass.define_method('blocks')

    klass.define_method('execute_block_on_receiver') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('exit_handler') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('finalizer') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('mailbox_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('mailbox_size') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('pool') do |method|
      method.define_argument('klass')
      method.define_optional_argument('options')
    end

    klass.define_method('proxy_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('run') do |method|
      method.define_optional_argument('registry')
    end

    klass.define_method('run!') do |method|
      method.define_optional_argument('registry')
    end

    klass.define_method('supervise') do |method|
      method.define_argument('klass')
      method.define_optional_argument('options')
    end

    klass.define_method('task_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('trap_exit') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('actors')

    klass.define_instance_method('add') do |method|
      method.define_argument('klass')
      method.define_argument('options')
    end

    klass.define_instance_method('finalize')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('registry')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('pool') do |method|
      method.define_argument('klass')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('restart_actor') do |method|
      method.define_argument('actor')
      method.define_argument('reason')
    end

    klass.define_instance_method('supervise') do |method|
      method.define_argument('klass')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('supervise_as') do |method|
      method.define_argument('name')
      method.define_argument('klass')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Celluloid::PoolManager::Supervisor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('root')

    klass.define_method('root=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('supervise') do |method|
      method.define_argument('klass')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('supervise_as') do |method|
      method.define_argument('name')
      method.define_argument('klass')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Celluloid::PoolManager::SyncCall') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Call', RubyLint.registry))

    klass.define_instance_method('chain_id')

    klass.define_instance_method('cleanup')

    klass.define_instance_method('dispatch') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('sender')
      method.define_argument('method')
      method.define_optional_argument('arguments')
      method.define_optional_argument('block')
      method.define_optional_argument('task')
      method.define_optional_argument('chain_id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('respond') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('sender')

    klass.define_instance_method('task')

    klass.define_instance_method('value')

    klass.define_instance_method('wait')
  end

  defs.define_constant('Celluloid::PoolManager::SyncProxy') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::AbstractProxy', RubyLint.registry))

    klass.define_instance_method('__class__')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mailbox')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('mailbox')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('meth')
      method.define_optional_argument('include_private')
    end
  end

  defs.define_constant('Celluloid::PoolManager::SystemEvent') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::Task') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('current')

    klass.define_method('suspend') do |method|
      method.define_argument('status')
    end

    klass.define_instance_method('backtrace')

    klass.define_instance_method('chain_id')

    klass.define_instance_method('chain_id=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('create') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('exclusive')

    klass.define_instance_method('exclusive?')

    klass.define_instance_method('guard') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('guard_warnings')

    klass.define_instance_method('guard_warnings=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('type')
      method.define_argument('meta')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('meta')

    klass.define_instance_method('resume') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('running?')

    klass.define_instance_method('status')

    klass.define_instance_method('suspend') do |method|
      method.define_argument('status')
    end

    klass.define_instance_method('terminate')

    klass.define_instance_method('type')
  end

  defs.define_constant('Celluloid::PoolManager::TaskFiber') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Task', RubyLint.registry))

    klass.define_instance_method('create')

    klass.define_instance_method('deliver') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('signal')

    klass.define_instance_method('terminate')
  end

  defs.define_constant('Celluloid::PoolManager::TaskSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('ary')
    end

    klass.define_instance_method('&') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('<') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('<=') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('>=') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('^') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('add') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('add?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('classify')

    klass.define_instance_method('clear')

    klass.define_instance_method('collect!')

    klass.define_instance_method('delete') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('delete?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('delete_if')

    klass.define_instance_method('difference') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('disjoint?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('divide') do |method|
      method.define_block_argument('func')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('flatten')

    klass.define_instance_method('flatten!')

    klass.define_instance_method('flatten_merge') do |method|
      method.define_argument('set')
      method.define_optional_argument('seen')
    end

    klass.define_instance_method('freeze')

    klass.define_instance_method('hash')

    klass.define_instance_method('include?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('enum')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('intersect?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('intersection') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('keep_if')

    klass.define_instance_method('length')

    klass.define_instance_method('map!')

    klass.define_instance_method('member?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('pp')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('pp')
    end

    klass.define_instance_method('proper_subset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('proper_superset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('reject!') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('replace') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('select!') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('subset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('subtract') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('superset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('taint')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_set') do |method|
      method.define_optional_argument('klass')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('union') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('untaint')

    klass.define_instance_method('|') do |method|
      method.define_argument('enum')
    end
  end

  defs.define_constant('Celluloid::PoolManager::TaskThread') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Task', RubyLint.registry))

    klass.define_instance_method('backtrace')

    klass.define_instance_method('create')

    klass.define_instance_method('deliver') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('type')
      method.define_argument('meta')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('signal')
  end

  defs.define_constant('Celluloid::PoolManager::TerminationRequest') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SystemEvent', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::Thread') do |klass|
    klass.inherits(defs.constant_proxy('Thread', RubyLint.registry))

    klass.define_instance_method('actor')

    klass.define_instance_method('busy')

    klass.define_instance_method('busy=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('call_chain_id')

    klass.define_instance_method('celluloid?')

    klass.define_instance_method('mailbox')

    klass.define_instance_method('role')

    klass.define_instance_method('role=') do |method|
      method.define_argument('role')
    end

    klass.define_instance_method('task')
  end

  defs.define_constant('Celluloid::PoolManager::ThreadHandle') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('alive?')

    klass.define_instance_method('backtrace')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('role')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('join') do |method|
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('kill')
  end

  defs.define_constant('Celluloid::PoolManager::TimeoutError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::PoolManager::UUID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('generate')
  end

  defs.define_constant('Celluloid::PoolManager::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Properties') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('property') do |method|
      method.define_argument('name')
      method.define_optional_argument('opts')
    end
  end

  defs.define_constant('Celluloid::Receiver') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('match') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('resume') do |method|
      method.define_optional_argument('message')
    end

    klass.define_instance_method('timer')

    klass.define_instance_method('timer=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::Receivers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('fire_timers')

    klass.define_instance_method('handle_message') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('receive') do |method|
      method.define_optional_argument('timeout')
      method.define_block_argument('block')
    end

    klass.define_instance_method('wait_interval')
  end

  defs.define_constant('Celluloid::Registry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('root')

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('actor')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('delete') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('get') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('names')

    klass.define_instance_method('set') do |method|
      method.define_argument('name')
      method.define_argument('actor')
    end
  end

  defs.define_constant('Celluloid::Response') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call')

    klass.define_instance_method('dispatch')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('call')
      method.define_argument('value')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('value')
  end

  defs.define_constant('Celluloid::ResumableError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::RingBuffer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('empty?')

    klass.define_instance_method('flush')

    klass.define_instance_method('full?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('size')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('shift')
  end

  defs.define_constant('Celluloid::SignalConditionRequest') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SystemEvent', RubyLint.registry))

    klass.define_instance_method('call')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('task')
      method.define_argument('value')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('task')

    klass.define_instance_method('value')
  end

  defs.define_constant('Celluloid::Signals') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('wait') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('Celluloid::StackDump') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('actors')

    klass.define_instance_method('actors=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('dump') do |method|
      method.define_optional_argument('output')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('snapshot')

    klass.define_instance_method('snapshot_actor') do |method|
      method.define_argument('actor')
    end

    klass.define_instance_method('snapshot_thread') do |method|
      method.define_argument('thread')
    end

    klass.define_instance_method('threads')

    klass.define_instance_method('threads=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::StackDump::ActorState') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid::StackDump::DisplayBacktrace', RubyLint.registry))

    klass.define_instance_method('backtrace')

    klass.define_instance_method('backtrace=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('dump')

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('status')

    klass.define_instance_method('status=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('subject_class')

    klass.define_instance_method('subject_class=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('subject_id')

    klass.define_instance_method('subject_id=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('tasks')

    klass.define_instance_method('tasks=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::StackDump::DisplayBacktrace') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('display_backtrace') do |method|
      method.define_argument('backtrace')
      method.define_argument('output')
      method.define_optional_argument('indent')
    end
  end

  defs.define_constant('Celluloid::StackDump::TaskState') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::StackDump::TaskState::Group') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('each')

    klass.define_method('members')

    klass.define_method('new') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('gid')

    klass.define_instance_method('gid=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('mem')

    klass.define_instance_method('mem=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('passwd')

    klass.define_instance_method('passwd=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::StackDump::TaskState::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('each')

    klass.define_method('members')

    klass.define_method('new') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('dir')

    klass.define_instance_method('dir=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('gecos')

    klass.define_instance_method('gecos=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('gid')

    klass.define_instance_method('gid=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('passwd')

    klass.define_instance_method('passwd=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('shell')

    klass.define_instance_method('shell=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('uid')

    klass.define_instance_method('uid=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::StackDump::TaskState::Tms') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('members')

    klass.define_method('new') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('cstime')

    klass.define_instance_method('cstime=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('cutime')

    klass.define_instance_method('cutime=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('stime')

    klass.define_instance_method('stime=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('utime')

    klass.define_instance_method('utime=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::StackDump::ThreadState') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('dump')
  end

  defs.define_constant('Celluloid::StackDump::ThreadState::Group') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('each')

    klass.define_method('members')

    klass.define_method('new') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('gid')

    klass.define_instance_method('gid=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('mem')

    klass.define_instance_method('mem=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('passwd')

    klass.define_instance_method('passwd=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::StackDump::ThreadState::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('each')

    klass.define_method('members')

    klass.define_method('new') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('dir')

    klass.define_instance_method('dir=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('gecos')

    klass.define_instance_method('gecos=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('gid')

    klass.define_instance_method('gid=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('passwd')

    klass.define_instance_method('passwd=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('shell')

    klass.define_instance_method('shell=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('uid')

    klass.define_instance_method('uid=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::StackDump::ThreadState::Tms') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('members')

    klass.define_method('new') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('cstime')

    klass.define_instance_method('cstime=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('cutime')

    klass.define_instance_method('cutime=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('stime')

    klass.define_instance_method('stime=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('utime')

    klass.define_instance_method('utime=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::SuccessResponse') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Response', RubyLint.registry))

  end

  defs.define_constant('Celluloid::SupervisionGroup') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid::InstanceMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Celluloid', RubyLint.registry))

    klass.define_method('blocks')

    klass.define_method('execute_block_on_receiver') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('exit_handler') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('finalizer') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('mailbox_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('mailbox_size') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('pool') do |method|
      method.define_argument('klass')
      method.define_optional_argument('options')
    end

    klass.define_method('proxy_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('run') do |method|
      method.define_optional_argument('registry')
    end

    klass.define_method('run!') do |method|
      method.define_optional_argument('registry')
    end

    klass.define_method('supervise') do |method|
      method.define_argument('klass')
      method.define_optional_argument('options')
    end

    klass.define_method('task_class') do |method|
      method.define_optional_argument('value')
      method.define_rest_argument('extra')
    end

    klass.define_method('trap_exit') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('actors')

    klass.define_instance_method('add') do |method|
      method.define_argument('klass')
      method.define_argument('options')
    end

    klass.define_instance_method('finalize')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('registry')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('pool') do |method|
      method.define_argument('klass')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('restart_actor') do |method|
      method.define_argument('actor')
      method.define_argument('reason')
    end

    klass.define_instance_method('supervise') do |method|
      method.define_argument('klass')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('supervise_as') do |method|
      method.define_argument('name')
      method.define_argument('klass')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Celluloid::Supervisor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('root')

    klass.define_method('root=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('supervise') do |method|
      method.define_argument('klass')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('supervise_as') do |method|
      method.define_argument('name')
      method.define_argument('klass')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Celluloid::SyncCall') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Call', RubyLint.registry))

    klass.define_instance_method('chain_id')

    klass.define_instance_method('cleanup')

    klass.define_instance_method('dispatch') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('sender')
      method.define_argument('method')
      method.define_optional_argument('arguments')
      method.define_optional_argument('block')
      method.define_optional_argument('task')
      method.define_optional_argument('chain_id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('respond') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('sender')

    klass.define_instance_method('task')

    klass.define_instance_method('value')

    klass.define_instance_method('wait')
  end

  defs.define_constant('Celluloid::SyncProxy') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::AbstractProxy', RubyLint.registry))

    klass.define_instance_method('__class__')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mailbox')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('mailbox')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('meth')
      method.define_optional_argument('include_private')
    end
  end

  defs.define_constant('Celluloid::SyncProxy::BasicObject') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('!')

    klass.define_instance_method('!=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('__id__')

    klass.define_instance_method('__send__') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('equal?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('instance_eval') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('instance_exec') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::SyncProxy::RUBYGEMS_ACTIVATION_MONITOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::SystemEvent') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Task') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('current')

    klass.define_method('suspend') do |method|
      method.define_argument('status')
    end

    klass.define_instance_method('backtrace')

    klass.define_instance_method('chain_id')

    klass.define_instance_method('chain_id=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('create') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('exclusive')

    klass.define_instance_method('exclusive?')

    klass.define_instance_method('guard') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('guard_warnings')

    klass.define_instance_method('guard_warnings=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('type')
      method.define_argument('meta')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('meta')

    klass.define_instance_method('resume') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('running?')

    klass.define_instance_method('status')

    klass.define_instance_method('suspend') do |method|
      method.define_argument('status')
    end

    klass.define_instance_method('terminate')

    klass.define_instance_method('type')
  end

  defs.define_constant('Celluloid::Task::TerminatedError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::ResumableError', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Task::TimeoutError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::ResumableError', RubyLint.registry))

  end

  defs.define_constant('Celluloid::TaskFiber') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Task', RubyLint.registry))

    klass.define_instance_method('create')

    klass.define_instance_method('deliver') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('signal')

    klass.define_instance_method('terminate')
  end

  defs.define_constant('Celluloid::TaskFiber::TerminatedError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::ResumableError', RubyLint.registry))

  end

  defs.define_constant('Celluloid::TaskFiber::TimeoutError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::ResumableError', RubyLint.registry))

  end

  defs.define_constant('Celluloid::TaskSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('ary')
    end

    klass.define_instance_method('&') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('<') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('<=') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('>=') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('^') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('add') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('add?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('classify')

    klass.define_instance_method('clear')

    klass.define_instance_method('collect!')

    klass.define_instance_method('delete') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('delete?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('delete_if')

    klass.define_instance_method('difference') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('disjoint?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('divide') do |method|
      method.define_block_argument('func')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('flatten')

    klass.define_instance_method('flatten!')

    klass.define_instance_method('flatten_merge') do |method|
      method.define_argument('set')
      method.define_optional_argument('seen')
    end

    klass.define_instance_method('freeze')

    klass.define_instance_method('hash')

    klass.define_instance_method('include?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('enum')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('intersect?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('intersection') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('keep_if')

    klass.define_instance_method('length')

    klass.define_instance_method('map!')

    klass.define_instance_method('member?') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('pp')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('pp')
    end

    klass.define_instance_method('proper_subset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('proper_superset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('reject!') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('replace') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('select!') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('subset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('subtract') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('superset?') do |method|
      method.define_argument('set')
    end

    klass.define_instance_method('taint')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_set') do |method|
      method.define_optional_argument('klass')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('union') do |method|
      method.define_argument('enum')
    end

    klass.define_instance_method('untaint')

    klass.define_instance_method('|') do |method|
      method.define_argument('enum')
    end
  end

  defs.define_constant('Celluloid::TaskThread') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Task', RubyLint.registry))

    klass.define_instance_method('backtrace')

    klass.define_instance_method('create')

    klass.define_instance_method('deliver') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('type')
      method.define_argument('meta')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('signal')
  end

  defs.define_constant('Celluloid::TaskThread::TerminatedError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::ResumableError', RubyLint.registry))

  end

  defs.define_constant('Celluloid::TaskThread::TimeoutError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::ResumableError', RubyLint.registry))

  end

  defs.define_constant('Celluloid::TerminationRequest') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::SystemEvent', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Thread') do |klass|
    klass.inherits(defs.constant_proxy('Thread', RubyLint.registry))

    klass.define_instance_method('actor')

    klass.define_instance_method('busy')

    klass.define_instance_method('busy=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('call_chain_id')

    klass.define_instance_method('celluloid?')

    klass.define_instance_method('mailbox')

    klass.define_instance_method('role')

    klass.define_instance_method('role=') do |method|
      method.define_argument('role')
    end

    klass.define_instance_method('task')
  end

  defs.define_constant('Celluloid::Thread::Backtrace') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Thread::ConditionVariable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast')

    klass.define_instance_method('signal')

    klass.define_instance_method('wait') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::Thread::MUTEX_FOR_THREAD_EXCLUSIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::Thread::Queue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('deq') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('enq') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('length')

    klass.define_instance_method('num_waiting')

    klass.define_instance_method('pop') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('shift') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('size')
  end

  defs.define_constant('Celluloid::Thread::SizedQueue') do |klass|
    klass.inherits(defs.constant_proxy('Thread::Queue', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('deq') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('enq') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('max')

    klass.define_instance_method('max=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('num_waiting')

    klass.define_instance_method('pop') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('shift') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('Celluloid::ThreadHandle') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('alive?')

    klass.define_instance_method('backtrace')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('role')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('join') do |method|
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('kill')
  end

  defs.define_constant('Celluloid::TimeoutError') do |klass|
    klass.inherits(defs.constant_proxy('Celluloid::Error', RubyLint.registry))

  end

  defs.define_constant('Celluloid::UUID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('generate')
  end

  defs.define_constant('Celluloid::UUID::BLOCK_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::UUID::PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Celluloid::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
