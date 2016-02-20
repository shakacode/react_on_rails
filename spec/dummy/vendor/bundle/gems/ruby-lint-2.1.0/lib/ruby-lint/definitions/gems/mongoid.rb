# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.10.n211

RubyLint.registry.register('Mongoid') do |defs|
  defs.define_constant('Mongoid') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('configure')

    klass.define_instance_method('configured?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('connect_to') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('default_session')

    klass.define_instance_method('destructive_fields') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('disconnect_sessions')

    klass.define_instance_method('duplicate_fields_exception') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('duplicate_fields_exception=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('duplicate_fields_exception?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('include_root_in_json') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('include_root_in_json=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('include_root_in_json?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('include_type_for_serialization') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('include_type_for_serialization=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('include_type_for_serialization?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('load!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('load_configuration') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('models') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('options=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('override_database') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('override_session') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('preload_models') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('preload_models=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('preload_models?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('purge!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('raise_not_found_error') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('raise_not_found_error=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('raise_not_found_error?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('register_model') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('running_with_passenger?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('scope_overwrite_exception') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('scope_overwrite_exception=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('scope_overwrite_exception?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('session') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('sessions') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sessions=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('time_zone') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('truncate!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('use_activesupport_time_zone') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('use_activesupport_time_zone=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('use_activesupport_time_zone?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('use_utc') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('use_utc=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('use_utc?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Mongoid::Atomic') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_updates') do |method|
      method.define_optional_argument('use_indexes')
    end

    klass.define_instance_method('add_atomic_pull') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('add_atomic_unset') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('atomic_array_add_to_sets')

    klass.define_instance_method('atomic_array_pulls')

    klass.define_instance_method('atomic_array_pushes')

    klass.define_instance_method('atomic_attribute_name') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('atomic_delete_modifier')

    klass.define_instance_method('atomic_insert_modifier')

    klass.define_instance_method('atomic_path')

    klass.define_instance_method('atomic_paths')

    klass.define_instance_method('atomic_position')

    klass.define_instance_method('atomic_pulls')

    klass.define_instance_method('atomic_pushes')

    klass.define_instance_method('atomic_sets')

    klass.define_instance_method('atomic_unsets')

    klass.define_instance_method('atomic_updates') do |method|
      method.define_optional_argument('use_indexes')
    end

    klass.define_instance_method('delayed_atomic_pulls')

    klass.define_instance_method('delayed_atomic_sets')

    klass.define_instance_method('delayed_atomic_unsets')

    klass.define_instance_method('flag_as_destroyed')

    klass.define_instance_method('flagged_destroys')

    klass.define_instance_method('process_flagged_destroys')
  end

  defs.define_constant('Mongoid::Atomic::Modifiers') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))

    klass.define_instance_method('add_to_set') do |method|
      method.define_argument('modifications')
    end

    klass.define_instance_method('pull') do |method|
      method.define_argument('modifications')
    end

    klass.define_instance_method('pull_all') do |method|
      method.define_argument('modifications')
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('modifications')
    end

    klass.define_instance_method('set') do |method|
      method.define_argument('modifications')
    end

    klass.define_instance_method('unset') do |method|
      method.define_argument('modifications')
    end
  end

  defs.define_constant('Mongoid::Atomic::Modifiers::BSON_ADJUST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Atomic::Modifiers::BSON_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Atomic::Modifiers::Bucket') do |klass|
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

  defs.define_constant('Mongoid::Atomic::Modifiers::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('resizable?')
  end

  defs.define_constant('Mongoid::Atomic::Modifiers::Entries') do |klass|
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

    klass.define_instance_method('to_ary')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Mongoid::Atomic::Modifiers::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::Atomic::Modifiers::Iterator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next') do |method|
      method.define_argument('item')
    end
  end

  defs.define_constant('Mongoid::Atomic::Modifiers::MAX_ENTRIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Atomic::Modifiers::MIN_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Atomic::Modifiers::PLACEHOLDER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Atomic::Modifiers::STRING_ADJUST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Atomic::Modifiers::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::Atomic::Modifiers::State') do |klass|
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

  defs.define_constant('Mongoid::Atomic::Paths') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Atomic::Paths::Embedded') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('delete_modifier')

    klass.define_instance_method('document')

    klass.define_instance_method('insert_modifier')

    klass.define_instance_method('parent')

    klass.define_instance_method('path')
  end

  defs.define_constant('Mongoid::Atomic::Paths::Embedded::Many') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Atomic::Paths::Embedded', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('position')
  end

  defs.define_constant('Mongoid::Atomic::Paths::Embedded::One') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Atomic::Paths::Embedded', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('position')
  end

  defs.define_constant('Mongoid::Atomic::Paths::Embedded::One::Many') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Atomic::Paths::Embedded', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('position')
  end

  defs.define_constant('Mongoid::Atomic::Paths::Root') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('document')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert_modifier')

    klass.define_instance_method('path')

    klass.define_instance_method('position')
  end

  defs.define_constant('Mongoid::Atomic::UPDATES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Attributes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('assign_attributes') do |method|
      method.define_optional_argument('attrs')
    end

    klass.define_instance_method('attribute_missing?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('attribute_present?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('attributes')

    klass.define_instance_method('attributes=') do |method|
      method.define_optional_argument('attrs')
    end

    klass.define_instance_method('attributes_before_type_cast')

    klass.define_instance_method('has_attribute?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('has_attribute_before_type_cast?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('raw_attributes')

    klass.define_instance_method('read_attribute') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('read_attribute_before_type_cast') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('remove_attribute') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('write_attribute') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('write_attributes') do |method|
      method.define_optional_argument('attrs')
    end
  end

  defs.define_constant('Mongoid::Attributes::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('alias_attribute') do |method|
      method.define_argument('name')
      method.define_argument('original')
    end
  end

  defs.define_constant('Mongoid::Attributes::Dynamic') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('define_dynamic_before_type_cast_reader') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('define_dynamic_reader') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('define_dynamic_writer') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('inspect_dynamic_fields')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('process_attribute') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
      method.define_optional_argument('include_private')
    end
  end

  defs.define_constant('Mongoid::Attributes::Nested') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Attributes::Nested::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accepts_nested_attributes_for') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Mongoid::Attributes::Nested::ClassMethods::REJECT_ALL_BLANK_PROC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Attributes::Processing') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('process_attributes') do |method|
      method.define_optional_argument('attrs')
    end
  end

  defs.define_constant('Mongoid::Attributes::Readonly') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attribute_writable?') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('Mongoid::Attributes::Readonly::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attr_readonly') do |method|
      method.define_rest_argument('names')
    end
  end

  defs.define_constant('Mongoid::Boolean') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('evolve') do |method|
      method.define_argument('object')
    end

    klass.define_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Changeable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('changed')

    klass.define_instance_method('changed?')

    klass.define_instance_method('changed_attributes')

    klass.define_instance_method('changes')

    klass.define_instance_method('children_changed?')

    klass.define_instance_method('move_changes')

    klass.define_instance_method('post_persist')

    klass.define_instance_method('previous_changes')

    klass.define_instance_method('remove_change') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('setters')
  end

  defs.define_constant('Mongoid::Changeable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Composable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('prohibited_methods')
  end

  defs.define_constant('Mongoid::Composable::MODULES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Config') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('configured?')

    klass.define_instance_method('connect_to') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('destructive_fields')

    klass.define_instance_method('duplicate_fields_exception')

    klass.define_instance_method('duplicate_fields_exception=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('duplicate_fields_exception?')

    klass.define_instance_method('include_root_in_json')

    klass.define_instance_method('include_root_in_json=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('include_root_in_json?')

    klass.define_instance_method('include_type_for_serialization')

    klass.define_instance_method('include_type_for_serialization=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('include_type_for_serialization?')

    klass.define_instance_method('load!') do |method|
      method.define_argument('path')
      method.define_optional_argument('environment')
    end

    klass.define_instance_method('load_configuration') do |method|
      method.define_argument('settings')
    end

    klass.define_instance_method('logger') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('logger=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('models')

    klass.define_instance_method('options=') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('override_database') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('override_session') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('preload_models')

    klass.define_instance_method('preload_models=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('preload_models?')

    klass.define_instance_method('purge!')

    klass.define_instance_method('raise_not_found_error')

    klass.define_instance_method('raise_not_found_error=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('raise_not_found_error?')

    klass.define_instance_method('register_model') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('running_with_passenger?')

    klass.define_instance_method('scope_overwrite_exception')

    klass.define_instance_method('scope_overwrite_exception=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('scope_overwrite_exception?')

    klass.define_instance_method('sessions')

    klass.define_instance_method('sessions=') do |method|
      method.define_argument('sessions')
    end

    klass.define_instance_method('time_zone')

    klass.define_instance_method('truncate!')

    klass.define_instance_method('use_activesupport_time_zone')

    klass.define_instance_method('use_activesupport_time_zone=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('use_activesupport_time_zone?')

    klass.define_instance_method('use_utc')

    klass.define_instance_method('use_utc=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('use_utc?')
  end

  defs.define_constant('Mongoid::Config::Environment') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('env_name')

    klass.define_instance_method('load_yaml') do |method|
      method.define_argument('path')
      method.define_optional_argument('environment')
    end
  end

  defs.define_constant('Mongoid::Config::LOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Config::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('defaults')

    klass.define_instance_method('option') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('settings')
  end

  defs.define_constant('Mongoid::Config::Validators') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Config::Validators::Option') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validate') do |method|
      method.define_argument('option')
    end
  end

  defs.define_constant('Mongoid::Config::Validators::Session') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validate') do |method|
      method.define_argument('sessions')
    end
  end

  defs.define_constant('Mongoid::Config::Validators::Session::STANDARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Contextual') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_to_set') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('aggregates') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('avg') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('bit') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('blank?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cached?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('context')

    klass.define_instance_method('count') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('criteria') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('database_field_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete_all') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('destroy') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('destroy_all') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('distinct') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('empty?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('exists?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('explain') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_and_modify') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('geo_near') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('inc') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('klass') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('last') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('length') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('map') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('map_reduce') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('max') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('min') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('one') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pop') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pull') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pull_all') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('push') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('push_all') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('query') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rename') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('set') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('size') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sort') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('text_search') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('unset') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('update') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('update_all') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Mongoid::Contextual::Aggregable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Contextual::Aggregable::Memory') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('avg') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('max') do |method|
      method.define_optional_argument('field')
    end

    klass.define_instance_method('min') do |method|
      method.define_optional_argument('field')
    end

    klass.define_instance_method('sum') do |method|
      method.define_optional_argument('field')
    end
  end

  defs.define_constant('Mongoid::Contextual::Aggregable::Mongo') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('aggregates') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('avg') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('max') do |method|
      method.define_optional_argument('field')
    end

    klass.define_instance_method('min') do |method|
      method.define_optional_argument('field')
    end

    klass.define_instance_method('sum') do |method|
      method.define_optional_argument('field')
    end
  end

  defs.define_constant('Mongoid::Contextual::Atomic') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_to_set') do |method|
      method.define_argument('adds')
    end

    klass.define_instance_method('bit') do |method|
      method.define_argument('bits')
    end

    klass.define_instance_method('inc') do |method|
      method.define_argument('incs')
    end

    klass.define_instance_method('pop') do |method|
      method.define_argument('pops')
    end

    klass.define_instance_method('pull') do |method|
      method.define_argument('pulls')
    end

    klass.define_instance_method('pull_all') do |method|
      method.define_argument('pulls')
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('pushes')
    end

    klass.define_instance_method('push_all') do |method|
      method.define_argument('pushes')
    end

    klass.define_instance_method('rename') do |method|
      method.define_argument('renames')
    end

    klass.define_instance_method('set') do |method|
      method.define_argument('sets')
    end

    klass.define_instance_method('unset') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Mongoid::Contextual::Command') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collection')

    klass.define_instance_method('command')

    klass.define_instance_method('criteria')

    klass.define_instance_method('session')
  end

  defs.define_constant('Mongoid::Contextual::FindAndModify') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Command', RubyLint.registry))

    klass.define_instance_method('criteria')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('collection')
      method.define_argument('criteria')
      method.define_argument('update')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')

    klass.define_instance_method('query')

    klass.define_instance_method('result')

    klass.define_instance_method('update')
  end

  defs.define_constant('Mongoid::Contextual::GeoNear') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Command', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('average_distance')

    klass.define_instance_method('distance_multiplier') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('empty?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('collection')
      method.define_argument('criteria')
      method.define_argument('near')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('max_distance') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('spherical')

    klass.define_instance_method('stats')

    klass.define_instance_method('time')

    klass.define_instance_method('unique') do |method|
      method.define_optional_argument('value')
    end
  end

  defs.define_constant('Mongoid::Contextual::GeoNear::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::Contextual::GeoNear::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::Contextual::MapReduce') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Command', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('counts')

    klass.define_instance_method('each')

    klass.define_instance_method('emitted')

    klass.define_instance_method('empty?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute')

    klass.define_instance_method('finalize') do |method|
      method.define_argument('function')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('collection')
      method.define_argument('criteria')
      method.define_argument('map')
      method.define_argument('reduce')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('input')

    klass.define_instance_method('inspect')

    klass.define_instance_method('js_mode')

    klass.define_instance_method('out') do |method|
      method.define_argument('location')
    end

    klass.define_instance_method('output')

    klass.define_instance_method('raw')

    klass.define_instance_method('reduced')

    klass.define_instance_method('scope') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('time')
  end

  defs.define_constant('Mongoid::Contextual::MapReduce::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::Contextual::MapReduce::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::Contextual::Memory') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Positional', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Queryable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Aggregable::Memory', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('delete')

    klass.define_instance_method('delete_all')

    klass.define_instance_method('destroy')

    klass.define_instance_method('destroy_all')

    klass.define_instance_method('distinct') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('documents')

    klass.define_instance_method('each')

    klass.define_instance_method('exists?')

    klass.define_instance_method('first')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('criteria')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('limit') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('one')

    klass.define_instance_method('path')

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('fields')
    end

    klass.define_instance_method('root')

    klass.define_instance_method('selector')

    klass.define_instance_method('size')

    klass.define_instance_method('skip') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('sort') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('update') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('update_all') do |method|
      method.define_optional_argument('attributes')
    end
  end

  defs.define_constant('Mongoid::Contextual::Memory::Base') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each_loaded_document')

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('grouped_docs')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('associations')
      method.define_argument('docs')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('keys_from_docs')

    klass.define_instance_method('preload')

    klass.define_instance_method('run')

    klass.define_instance_method('set_on_parent') do |method|
      method.define_argument('id')
      method.define_argument('element')
    end

    klass.define_instance_method('set_relation') do |method|
      method.define_argument('doc')
      method.define_argument('element')
    end

    klass.define_instance_method('shift_metadata')
  end

  defs.define_constant('Mongoid::Contextual::Memory::BelongsTo') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('preload')
  end

  defs.define_constant('Mongoid::Contextual::Memory::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::Contextual::Memory::HasAndBelongsToMany') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('keys_from_docs')

    klass.define_instance_method('preload')

    klass.define_instance_method('set_relation') do |method|
      method.define_argument('doc')
      method.define_argument('element')
    end
  end

  defs.define_constant('Mongoid::Contextual::Memory::HasMany') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('preload')

    klass.define_instance_method('set_relation') do |method|
      method.define_argument('doc')
      method.define_argument('element')
    end
  end

  defs.define_constant('Mongoid::Contextual::Memory::HasOne') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('preload')
  end

  defs.define_constant('Mongoid::Contextual::Memory::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::Contextual::Mongo') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Queryable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Atomic', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Aggregable::Mongo', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('cached?')

    klass.define_instance_method('count') do |method|
      method.define_optional_argument('document')
      method.define_block_argument('block')
    end

    klass.define_instance_method('database_field_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete')

    klass.define_instance_method('delete_all')

    klass.define_instance_method('destroy')

    klass.define_instance_method('destroy_all')

    klass.define_instance_method('distinct') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('exists?')

    klass.define_instance_method('explain')

    klass.define_instance_method('find_and_modify') do |method|
      method.define_argument('update')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('first')

    klass.define_instance_method('geo_near') do |method|
      method.define_argument('coordinates')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('criteria')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('limit') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('map') do |method|
      method.define_optional_argument('field')
      method.define_block_argument('block')
    end

    klass.define_instance_method('map_reduce') do |method|
      method.define_argument('map')
      method.define_argument('reduce')
    end

    klass.define_instance_method('one')

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('fields')
    end

    klass.define_instance_method('query')

    klass.define_instance_method('size')

    klass.define_instance_method('skip') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('sort') do |method|
      method.define_optional_argument('values')
      method.define_block_argument('block')
    end

    klass.define_instance_method('text_search') do |method|
      method.define_argument('query')
    end

    klass.define_instance_method('update') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('update_all') do |method|
      method.define_optional_argument('attributes')
    end
  end

  defs.define_constant('Mongoid::Contextual::Mongo::Base') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each_loaded_document')

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('grouped_docs')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('associations')
      method.define_argument('docs')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('keys_from_docs')

    klass.define_instance_method('preload')

    klass.define_instance_method('run')

    klass.define_instance_method('set_on_parent') do |method|
      method.define_argument('id')
      method.define_argument('element')
    end

    klass.define_instance_method('set_relation') do |method|
      method.define_argument('doc')
      method.define_argument('element')
    end

    klass.define_instance_method('shift_metadata')
  end

  defs.define_constant('Mongoid::Contextual::Mongo::BelongsTo') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('preload')
  end

  defs.define_constant('Mongoid::Contextual::Mongo::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::Contextual::Mongo::HasAndBelongsToMany') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('keys_from_docs')

    klass.define_instance_method('preload')

    klass.define_instance_method('set_relation') do |method|
      method.define_argument('doc')
      method.define_argument('element')
    end
  end

  defs.define_constant('Mongoid::Contextual::Mongo::HasMany') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('preload')

    klass.define_instance_method('set_relation') do |method|
      method.define_argument('doc')
      method.define_argument('element')
    end
  end

  defs.define_constant('Mongoid::Contextual::Mongo::HasOne') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('preload')
  end

  defs.define_constant('Mongoid::Contextual::Mongo::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::Contextual::None') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Queryable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('criteria')

    klass.define_instance_method('each')

    klass.define_instance_method('exists?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('criteria')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('size')
  end

  defs.define_constant('Mongoid::Contextual::None::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::Contextual::None::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::Contextual::Queryable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('blank?')

    klass.define_instance_method('collection')

    klass.define_instance_method('criteria')

    klass.define_instance_method('empty?')

    klass.define_instance_method('klass')
  end

  defs.define_constant('Mongoid::Contextual::TextSearch') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Command', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('empty?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('collection')
      method.define_argument('criteria')
      method.define_argument('search_string')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('language') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('project') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('stats')
  end

  defs.define_constant('Mongoid::Contextual::TextSearch::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::Contextual::TextSearch::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::Copyable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('clone')

    klass.define_instance_method('dup')
  end

  defs.define_constant('Mongoid::Criteria') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Sessions::Options', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Criteria::Scopable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Criteria::Modifiable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Criteria::Marshalable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Criteria::Inspectable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Criteria::Findable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Origin::Queryable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Origin::Optional', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Origin::Selectable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Origin::Aggregable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Origin::Mergeable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('as_json') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('cache')

    klass.define_instance_method('cached?')

    klass.define_instance_method('documents')

    klass.define_instance_method('documents=') do |method|
      method.define_argument('docs')
    end

    klass.define_instance_method('embedded')

    klass.define_instance_method('embedded=')

    klass.define_instance_method('embedded?')

    klass.define_instance_method('empty_and_chainable?')

    klass.define_instance_method('extract_id')

    klass.define_instance_method('extras') do |method|
      method.define_argument('extras')
    end

    klass.define_instance_method('field_list')

    klass.define_instance_method('for_js') do |method|
      method.define_argument('javascript')
      method.define_optional_argument('scope')
    end

    klass.define_instance_method('freeze')

    klass.define_instance_method('includes') do |method|
      method.define_rest_argument('relations')
    end

    klass.define_instance_method('inclusions')

    klass.define_instance_method('inclusions=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('merge') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('merge!') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('metadata')

    klass.define_instance_method('metadata=')

    klass.define_instance_method('none')

    klass.define_instance_method('only') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('parent_document')

    klass.define_instance_method('parent_document=')

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
      method.define_optional_argument('include_private')
    end

    klass.define_instance_method('to_ary') do |method|
      method.define_rest_argument('arg')
    end

    klass.define_instance_method('to_criteria')

    klass.define_instance_method('to_proc')

    klass.define_instance_method('type') do |method|
      method.define_argument('types')
    end

    klass.define_instance_method('where') do |method|
      method.define_argument('expression')
    end

    klass.define_instance_method('without_options')
  end

  defs.define_constant('Mongoid::Criteria::Aggregable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Criteria::Atomic') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_to_set') do |method|
      method.define_argument('adds')
    end

    klass.define_instance_method('bit') do |method|
      method.define_argument('bits')
    end

    klass.define_instance_method('inc') do |method|
      method.define_argument('incs')
    end

    klass.define_instance_method('pop') do |method|
      method.define_argument('pops')
    end

    klass.define_instance_method('pull') do |method|
      method.define_argument('pulls')
    end

    klass.define_instance_method('pull_all') do |method|
      method.define_argument('pulls')
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('pushes')
    end

    klass.define_instance_method('push_all') do |method|
      method.define_argument('pushes')
    end

    klass.define_instance_method('rename') do |method|
      method.define_argument('renames')
    end

    klass.define_instance_method('set') do |method|
      method.define_argument('sets')
    end

    klass.define_instance_method('unset') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Mongoid::Criteria::CHECK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Criteria::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collection_name')

    klass.define_instance_method('database_name')

    klass.define_instance_method('session_name')

    klass.define_instance_method('with') do |method|
      method.define_argument('options')
    end
  end

  defs.define_constant('Mongoid::Criteria::Command') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collection')

    klass.define_instance_method('command')

    klass.define_instance_method('criteria')

    klass.define_instance_method('session')
  end

  defs.define_constant('Mongoid::Criteria::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::Criteria::FindAndModify') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Command', RubyLint.registry))

    klass.define_instance_method('criteria')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('collection')
      method.define_argument('criteria')
      method.define_argument('update')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')

    klass.define_instance_method('query')

    klass.define_instance_method('result')

    klass.define_instance_method('update')
  end

  defs.define_constant('Mongoid::Criteria::Findable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('execute_or_raise') do |method|
      method.define_argument('ids')
      method.define_argument('multi')
    end

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('for_ids') do |method|
      method.define_argument('ids')
    end

    klass.define_instance_method('multiple_from_db') do |method|
      method.define_argument('ids')
    end
  end

  defs.define_constant('Mongoid::Criteria::GeoNear') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Command', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('average_distance')

    klass.define_instance_method('distance_multiplier') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('empty?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('collection')
      method.define_argument('criteria')
      method.define_argument('near')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('max_distance') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('spherical')

    klass.define_instance_method('stats')

    klass.define_instance_method('time')

    klass.define_instance_method('unique') do |method|
      method.define_optional_argument('value')
    end
  end

  defs.define_constant('Mongoid::Criteria::Inspectable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Mongoid::Criteria::LINE_STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Criteria::MapReduce') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Command', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('counts')

    klass.define_instance_method('each')

    klass.define_instance_method('emitted')

    klass.define_instance_method('empty?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute')

    klass.define_instance_method('finalize') do |method|
      method.define_argument('function')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('collection')
      method.define_argument('criteria')
      method.define_argument('map')
      method.define_argument('reduce')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('input')

    klass.define_instance_method('inspect')

    klass.define_instance_method('js_mode')

    klass.define_instance_method('out') do |method|
      method.define_argument('location')
    end

    klass.define_instance_method('output')

    klass.define_instance_method('raw')

    klass.define_instance_method('reduced')

    klass.define_instance_method('scope') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('time')
  end

  defs.define_constant('Mongoid::Criteria::Marshalable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('data')
    end
  end

  defs.define_constant('Mongoid::Criteria::Memory') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Positional', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Queryable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Aggregable::Memory', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('delete')

    klass.define_instance_method('delete_all')

    klass.define_instance_method('destroy')

    klass.define_instance_method('destroy_all')

    klass.define_instance_method('distinct') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('documents')

    klass.define_instance_method('each')

    klass.define_instance_method('exists?')

    klass.define_instance_method('first')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('criteria')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('limit') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('one')

    klass.define_instance_method('path')

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('fields')
    end

    klass.define_instance_method('root')

    klass.define_instance_method('selector')

    klass.define_instance_method('size')

    klass.define_instance_method('skip') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('sort') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('update') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('update_all') do |method|
      method.define_optional_argument('attributes')
    end
  end

  defs.define_constant('Mongoid::Criteria::Modifiable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attrs')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attrs')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attrs')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_or_create_by') do |method|
      method.define_optional_argument('attrs')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_or_create_by!') do |method|
      method.define_optional_argument('attrs')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_or_initialize_by') do |method|
      method.define_optional_argument('attrs')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first_or_create') do |method|
      method.define_optional_argument('attrs')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first_or_create!') do |method|
      method.define_optional_argument('attrs')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first_or_initialize') do |method|
      method.define_optional_argument('attrs')
      method.define_block_argument('block')
    end

    klass.define_instance_method('new') do |method|
      method.define_optional_argument('attrs')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Mongoid::Criteria::Mongo') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Queryable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Atomic', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Aggregable::Mongo', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('cached?')

    klass.define_instance_method('count') do |method|
      method.define_optional_argument('document')
      method.define_block_argument('block')
    end

    klass.define_instance_method('database_field_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete')

    klass.define_instance_method('delete_all')

    klass.define_instance_method('destroy')

    klass.define_instance_method('destroy_all')

    klass.define_instance_method('distinct') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('exists?')

    klass.define_instance_method('explain')

    klass.define_instance_method('find_and_modify') do |method|
      method.define_argument('update')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('first')

    klass.define_instance_method('geo_near') do |method|
      method.define_argument('coordinates')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('criteria')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('limit') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('map') do |method|
      method.define_optional_argument('field')
      method.define_block_argument('block')
    end

    klass.define_instance_method('map_reduce') do |method|
      method.define_argument('map')
      method.define_argument('reduce')
    end

    klass.define_instance_method('one')

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('fields')
    end

    klass.define_instance_method('query')

    klass.define_instance_method('size')

    klass.define_instance_method('skip') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('sort') do |method|
      method.define_optional_argument('values')
      method.define_block_argument('block')
    end

    klass.define_instance_method('text_search') do |method|
      method.define_argument('query')
    end

    klass.define_instance_method('update') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('update_all') do |method|
      method.define_optional_argument('attributes')
    end
  end

  defs.define_constant('Mongoid::Criteria::None') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Queryable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('criteria')

    klass.define_instance_method('each')

    klass.define_instance_method('exists?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('criteria')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('size')
  end

  defs.define_constant('Mongoid::Criteria::POINT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Criteria::POLYGON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Criteria::Proxy') do |klass|
    klass.inherits(defs.constant_proxy('BasicObject', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Sessions::Options::Threaded', RubyLint.registry))

    klass.define_method('const_missing') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('target')
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('persistence_options')

    klass.define_instance_method('respond_to?') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('send') do |method|
      method.define_argument('symbol')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Mongoid::Criteria::Queryable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('blank?')

    klass.define_instance_method('collection')

    klass.define_instance_method('criteria')

    klass.define_instance_method('empty?')

    klass.define_instance_method('klass')
  end

  defs.define_constant('Mongoid::Criteria::Scopable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('apply_default_scope')

    klass.define_instance_method('remove_scoping') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('scoped') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('scoped?')

    klass.define_instance_method('scoping_options')

    klass.define_instance_method('scoping_options=') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('unscoped')

    klass.define_instance_method('unscoped?')

    klass.define_instance_method('with_default_scope')
  end

  defs.define_constant('Mongoid::Criteria::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::Criteria::TextSearch') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Contextual::Command', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('empty?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('collection')
      method.define_argument('criteria')
      method.define_argument('search_string')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('language') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('project') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('stats')
  end

  defs.define_constant('Mongoid::Criteria::Threaded') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('persistence_options') do |method|
      method.define_optional_argument('klass')
    end
  end

  defs.define_constant('Mongoid::Document') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__selected_fields')

    klass.define_instance_method('__selected_fields=')

    klass.define_instance_method('as_document')

    klass.define_instance_method('becomes') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('cache_key')

    klass.define_instance_method('freeze')

    klass.define_instance_method('frozen?')

    klass.define_instance_method('hash')

    klass.define_instance_method('identity')

    klass.define_instance_method('model_name')

    klass.define_instance_method('new_record')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_key')
  end

  defs.define_constant('Mongoid::Document::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('_types')

    klass.define_instance_method('i18n_scope')

    klass.define_instance_method('instantiate') do |method|
      method.define_optional_argument('attrs')
      method.define_optional_argument('selected_fields')
    end

    klass.define_instance_method('logger')
  end

  defs.define_constant('Mongoid::Equality') do |klass|
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

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end
  end

  defs.define_constant('Mongoid::Errors') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::AmbiguousRelationship') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('inverse')
      method.define_argument('name')
      method.define_argument('candidates')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::AmbiguousRelationship::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('method')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::Callback::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::DeleteRestriction') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')
      method.define_argument('relation')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::DeleteRestriction::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::DocumentNotDestroyed') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('id')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::DocumentNotDestroyed::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::DocumentNotFound') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('params')
      method.define_optional_argument('unmatched')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('params')
  end

  defs.define_constant('Mongoid::Errors::DocumentNotFound::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::EagerLoad') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::EagerLoad::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidCollection') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidCollection::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidConfigOption') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidConfigOption::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidField') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidField::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidFieldOption') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('name')
      method.define_argument('option')
      method.define_argument('valid')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidFieldOption::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidFind') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Mongoid::Errors::InvalidFind::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidIncludes') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('args')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidIncludes::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidIndex') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('spec')
      method.define_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidIndex::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidOptions') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('invalid')
      method.define_argument('valid')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidOptions::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidPath') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidPath::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidScope') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidScope::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidSetPolymorphicRelation') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('klass')
      method.define_argument('other_klass')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidSetPolymorphicRelation::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidStorageOptions') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidStorageOptions::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidStorageParent') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidStorageParent::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidTime') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidTime::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InvalidValue') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('field_class')
      method.define_argument('value_class')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InvalidValue::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::InverseNotFound') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('name')
      method.define_argument('klass')
      method.define_argument('inverse')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::InverseNotFound::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::MixedRelations') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('root_klass')
      method.define_argument('embedded_klass')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::MixedRelations::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::MixedSessionConfiguration') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::MixedSessionConfiguration::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::MongoidError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('compose_message') do |method|
      method.define_argument('key')
      method.define_argument('attributes')
    end
  end

  defs.define_constant('Mongoid::Errors::MongoidError::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::NestedAttributesMetadataNotFound') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::NestedAttributesMetadataNotFound::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::NoDefaultSession') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('keys')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::NoDefaultSession::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::NoEnvironment') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Mongoid::Errors::NoEnvironment::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::NoMapReduceOutput') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('command')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::NoMapReduceOutput::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::NoMetadata') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::NoMetadata::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::NoParent') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::NoParent::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::NoSessionConfig') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::NoSessionConfig::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::NoSessionDatabase') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::NoSessionDatabase::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::NoSessionHosts') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::NoSessionHosts::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::NoSessionsConfig') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Mongoid::Errors::NoSessionsConfig::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::ReadonlyAttribute') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::ReadonlyAttribute::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::ReadonlyDocument') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::ReadonlyDocument::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::ScopeOverwrite') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('model_name')
      method.define_argument('scope_name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::ScopeOverwrite::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::TooManyNestedAttributeRecords') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('association')
      method.define_argument('limit')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::TooManyNestedAttributeRecords::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::UnknownAttribute') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::UnknownAttribute::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::UnsavedDocument') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('document')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::UnsavedDocument::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::UnsupportedJavascript') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('javascript')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Errors::UnsupportedJavascript::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Errors::Validations') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Errors::MongoidError', RubyLint.registry))

    klass.define_instance_method('document')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('record')
  end

  defs.define_constant('Mongoid::Errors::Validations::BASE_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Evolvable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__evolve_object_id__')
  end

  defs.define_constant('Mongoid::Extensions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Extensions::Array') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__evolve_object_id__')

    klass.define_instance_method('__find_args__')

    klass.define_instance_method('__mongoize_object_id__')

    klass.define_instance_method('__mongoize_time__')

    klass.define_instance_method('blank_criteria?')

    klass.define_instance_method('delete_one') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize')

    klass.define_instance_method('multi_arged?')

    klass.define_instance_method('resizable?')
  end

  defs.define_constant('Mongoid::Extensions::Array::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__mongoize_fk__') do |method|
      method.define_argument('constraint')
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('resizable?')
  end

  defs.define_constant('Mongoid::Extensions::BigDecimal') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__to_inc__')

    klass.define_instance_method('mongoize')
  end

  defs.define_constant('Mongoid::Extensions::BigDecimal::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::Date') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__mongoize_time__')

    klass.define_instance_method('mongoize')
  end

  defs.define_constant('Mongoid::Extensions::Date::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::Date::EPOCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Extensions::DateTime') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__mongoize_time__')

    klass.define_instance_method('mongoize')
  end

  defs.define_constant('Mongoid::Extensions::DateTime::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::FalseClass') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__sortable__')

    klass.define_instance_method('is_a?') do |method|
      method.define_argument('other')
    end
  end

  defs.define_constant('Mongoid::Extensions::Float') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__mongoize_time__')

    klass.define_instance_method('numeric?')
  end

  defs.define_constant('Mongoid::Extensions::Float::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::Hash') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__consolidate__') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('__evolve_object_id__')

    klass.define_instance_method('__mongoize_object_id__')

    klass.define_instance_method('__nested__') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('blank_criteria?')

    klass.define_instance_method('delete_id')

    klass.define_instance_method('extract_id')

    klass.define_instance_method('mongoize')

    klass.define_instance_method('resizable?')

    klass.define_instance_method('to_criteria')
  end

  defs.define_constant('Mongoid::Extensions::Hash::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('resizable?')
  end

  defs.define_constant('Mongoid::Extensions::Integer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__mongoize_time__')

    klass.define_instance_method('numeric?')

    klass.define_instance_method('unconvertable_to_bson?')
  end

  defs.define_constant('Mongoid::Extensions::Integer::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::Module') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('re_define_method') do |method|
      method.define_argument('name')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Mongoid::Extensions::NilClass') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__setter__')

    klass.define_instance_method('collectionize')
  end

  defs.define_constant('Mongoid::Extensions::Object') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__evolve_object_id__')

    klass.define_instance_method('__find_args__')

    klass.define_instance_method('__mongoize_object_id__')

    klass.define_instance_method('__mongoize_time__')

    klass.define_instance_method('__setter__')

    klass.define_instance_method('__sortable__')

    klass.define_instance_method('__to_inc__')

    klass.define_instance_method('blank_criteria?')

    klass.define_instance_method('do_or_do_not') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('ivar') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('mongoize')

    klass.define_instance_method('multi_arged?')

    klass.define_instance_method('numeric?')

    klass.define_instance_method('remove_ivar') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('resizable?')

    klass.define_instance_method('substitutable')

    klass.define_instance_method('you_must') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Mongoid::Extensions::Object::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__mongoize_fk__') do |method|
      method.define_argument('constraint')
      method.define_argument('object')
    end

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::ObjectId') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__evolve_object_id__')

    klass.define_instance_method('__mongoize_object_id__')
  end

  defs.define_constant('Mongoid::Extensions::ObjectId::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('evolve') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::Range') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__find_args__')

    klass.define_instance_method('mongoize')

    klass.define_instance_method('resizable?')
  end

  defs.define_constant('Mongoid::Extensions::Range::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::Regexp') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Extensions::Regexp::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::Set') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('mongoize')
  end

  defs.define_constant('Mongoid::Extensions::Set::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::String') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__evolve_object_id__')

    klass.define_instance_method('__mongoize_object_id__')

    klass.define_instance_method('__mongoize_time__')

    klass.define_instance_method('before_type_cast?')

    klass.define_instance_method('collectionize')

    klass.define_instance_method('mongoid_id?')

    klass.define_instance_method('numeric?')

    klass.define_instance_method('reader')

    klass.define_instance_method('unconvertable_to_bson')

    klass.define_instance_method('unconvertable_to_bson=')

    klass.define_instance_method('unconvertable_to_bson?')

    klass.define_instance_method('valid_method_name?')

    klass.define_instance_method('writer?')
  end

  defs.define_constant('Mongoid::Extensions::String::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::Symbol') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('mongoid_id?')
  end

  defs.define_constant('Mongoid::Extensions::Symbol::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::Time') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('mongoize')
  end

  defs.define_constant('Mongoid::Extensions::Time::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('configured')

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::Time::EPOCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Extensions::TimeWithZone') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('mongoize')
  end

  defs.define_constant('Mongoid::Extensions::TimeWithZone::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Extensions::TrueClass') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__sortable__')

    klass.define_instance_method('is_a?') do |method|
      method.define_argument('other')
    end
  end

  defs.define_constant('Mongoid::Factory') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_argument('klass')
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('from_db') do |method|
      method.define_argument('klass')
      method.define_optional_argument('attributes')
      method.define_optional_argument('selected_fields')
    end
  end

  defs.define_constant('Mongoid::Fields') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('option') do |method|
      method.define_argument('option_name')
      method.define_block_argument('block')
    end

    klass.define_method('options')

    klass.define_instance_method('apply_default') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('apply_defaults')

    klass.define_instance_method('apply_post_processed_defaults')

    klass.define_instance_method('apply_pre_processed_defaults')

    klass.define_instance_method('attribute_names')

    klass.define_instance_method('database_field_name') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('lazy_settable?') do |method|
      method.define_argument('field')
      method.define_argument('value')
    end

    klass.define_instance_method('using_object_ids?')
  end

  defs.define_constant('Mongoid::Fields::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_defaults') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('add_field') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('attribute_names')

    klass.define_instance_method('create_accessors') do |method|
      method.define_argument('name')
      method.define_argument('meth')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('create_field_check') do |method|
      method.define_argument('name')
      method.define_argument('meth')
    end

    klass.define_instance_method('create_field_getter') do |method|
      method.define_argument('name')
      method.define_argument('meth')
      method.define_argument('field')
    end

    klass.define_instance_method('create_field_getter_before_type_cast') do |method|
      method.define_argument('name')
      method.define_argument('meth')
    end

    klass.define_instance_method('create_field_setter') do |method|
      method.define_argument('name')
      method.define_argument('meth')
      method.define_argument('field')
    end

    klass.define_instance_method('create_translations_getter') do |method|
      method.define_argument('name')
      method.define_argument('meth')
    end

    klass.define_instance_method('create_translations_setter') do |method|
      method.define_argument('name')
      method.define_argument('meth')
      method.define_argument('field')
    end

    klass.define_instance_method('database_field_name') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('field') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('field_for') do |method|
      method.define_argument('name')
      method.define_argument('options')
    end

    klass.define_instance_method('generated_methods')

    klass.define_instance_method('process_options') do |method|
      method.define_argument('field')
    end

    klass.define_instance_method('remove_defaults') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('replace_field') do |method|
      method.define_argument('name')
      method.define_argument('type')
    end

    klass.define_instance_method('unmapped_type') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('using_object_ids?')
  end

  defs.define_constant('Mongoid::Fields::ForeignKey') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Fields::Standard', RubyLint.registry))

    klass.define_instance_method('add_atomic_changes') do |method|
      method.define_argument('document')
      method.define_argument('name')
      method.define_argument('key')
      method.define_argument('mods')
      method.define_argument('new_elements')
      method.define_argument('old_elements')
    end

    klass.define_instance_method('evolve') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('foreign_key?')

    klass.define_instance_method('lazy?')

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('object_id_field?')

    klass.define_instance_method('resizable?')
  end

  defs.define_constant('Mongoid::Fields::Localized') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Fields::Standard', RubyLint.registry))

    klass.define_instance_method('demongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('localized?')

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('Mongoid::Fields::Standard') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_atomic_changes') do |method|
      method.define_argument('document')
      method.define_argument('name')
      method.define_argument('key')
      method.define_argument('mods')
      method.define_argument('new')
      method.define_argument('old')
    end

    klass.define_instance_method('constraint')

    klass.define_instance_method('default_val')

    klass.define_instance_method('default_val=')

    klass.define_instance_method('demongoize') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('eval_default') do |method|
      method.define_argument('doc')
    end

    klass.define_instance_method('evolve') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('foreign_key?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label')

    klass.define_instance_method('label=')

    klass.define_instance_method('lazy?')

    klass.define_instance_method('localized?')

    klass.define_instance_method('metadata')

    klass.define_instance_method('mongoize') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('object_id_field?')

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('pre_processed?')

    klass.define_instance_method('type')
  end

  defs.define_constant('Mongoid::Fields::TYPE_MAPPINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Fields::Validators') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Fields::Validators::Macro') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validate') do |method|
      method.define_argument('klass')
      method.define_argument('name')
      method.define_argument('options')
    end
  end

  defs.define_constant('Mongoid::Fields::Validators::Macro::OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Findable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('aggregates') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('all') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('all_in') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('all_of') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('and') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('any_in') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('any_of') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('asc') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('ascending') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('avg') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('batch_size') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('between') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('count')

    klass.define_instance_method('desc') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('descending') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('distinct') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('each_with_index') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('elem_match') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('excludes') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('exists') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('exists?')

    klass.define_instance_method('extras') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('find_and_modify') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_by') do |method|
      method.define_optional_argument('attrs')
    end

    klass.define_instance_method('find_or_create_by') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_or_create_by!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_or_initialize_by') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first')

    klass.define_instance_method('first_or_create') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first_or_create!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first_or_initialize') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('for_js') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('geo_near') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('geo_spacial') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('gt') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('gte') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('hint') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('in') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('includes') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('last')

    klass.define_instance_method('limit') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('lt') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('lte') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('map_reduce') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('max') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('max_distance') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('max_scan') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('min') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('mod') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('ne') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('near') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('near_sphere') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('nin') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('no_timeout') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('none') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('nor') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('not') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('not_in') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('offset') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('one')

    klass.define_instance_method('only') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('or') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('order') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('order_by') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('reorder') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('skip') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('slice') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('snapshot') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('text_search') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('update') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('update_all') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('where') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with_size') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with_type') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('without') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Mongoid::Indexable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Indexable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_indexes')

    klass.define_instance_method('create_indexes')

    klass.define_instance_method('index') do |method|
      method.define_argument('spec')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('index_specification') do |method|
      method.define_argument('index_hash')
    end

    klass.define_instance_method('remove_indexes')
  end

  defs.define_constant('Mongoid::Indexable::Specification') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('fields')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('key')
      method.define_optional_argument('opts')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('key')

    klass.define_instance_method('klass')

    klass.define_instance_method('options')
  end

  defs.define_constant('Mongoid::Indexable::Specification::MAPPINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Indexable::Validators') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Indexable::Validators::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validate') do |method|
      method.define_argument('klass')
      method.define_argument('spec')
      method.define_argument('options')
    end
  end

  defs.define_constant('Mongoid::Indexable::Validators::Options::VALID_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Indexable::Validators::Options::VALID_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Inspectable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Mongoid::Interceptable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('callback_executable?') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('in_callback_state?') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('run_after_callbacks') do |method|
      method.define_rest_argument('kinds')
    end

    klass.define_instance_method('run_before_callbacks') do |method|
      method.define_rest_argument('kinds')
    end

    klass.define_instance_method('run_callbacks') do |method|
      method.define_argument('kind')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Mongoid::Interceptable::CALLBACKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::LogSubscriber') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::LogSubscriber', RubyLint.registry))

    klass.define_instance_method('debug') do |method|
      method.define_argument('prefix')
      method.define_argument('operations')
      method.define_argument('runtime')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('query') do |method|
      method.define_argument('event')
    end

    klass.define_instance_method('query_cache') do |method|
      method.define_argument('event')
    end
  end

  defs.define_constant('Mongoid::LogSubscriber::BLACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::LogSubscriber::BLUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::LogSubscriber::BOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::LogSubscriber::CLEAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::LogSubscriber::CYAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::LogSubscriber::GREEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::LogSubscriber::MAGENTA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::LogSubscriber::RED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::LogSubscriber::WHITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::LogSubscriber::YELLOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Loggable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('logger')

    klass.define_instance_method('logger=') do |method|
      method.define_argument('logger')
    end
  end

  defs.define_constant('Mongoid::MONGODB_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Matchable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('matcher') do |method|
      method.define_argument('document')
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('matches?') do |method|
      method.define_argument('selector')
    end
  end

  defs.define_constant('Mongoid::Matchable::All') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Matchable::And') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('conditions')
    end
  end

  defs.define_constant('Mongoid::Matchable::Default') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attribute')

    klass.define_instance_method('attribute=')

    klass.define_instance_method('determine') do |method|
      method.define_argument('value')
      method.define_argument('operator')
    end

    klass.define_instance_method('document')

    klass.define_instance_method('document=')

    klass.define_instance_method('first') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('attribute')
      method.define_optional_argument('document')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Matchable::Exists') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Matchable::Gt') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Matchable::Gte') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Matchable::In') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Matchable::Lt') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Matchable::Lte') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Matchable::MATCHERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Matchable::Ne') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Matchable::Nin') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Matchable::Or') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('conditions')
    end
  end

  defs.define_constant('Mongoid::Matchable::Size') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Matchable::Default', RubyLint.registry))

    klass.define_instance_method('matches?') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Persistable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('atomically')

    klass.define_instance_method('fail_due_to_callback!') do |method|
      method.define_argument('method')
    end

    klass.define_instance_method('fail_due_to_validation!')
  end

  defs.define_constant('Mongoid::Persistable::Creatable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('insert') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Mongoid::Persistable::Creatable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Mongoid::Persistable::Deletable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('delete') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('remove') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Mongoid::Persistable::Deletable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('delete_all') do |method|
      method.define_optional_argument('conditions')
    end
  end

  defs.define_constant('Mongoid::Persistable::Destroyable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('destroy') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('destroy!') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Mongoid::Persistable::Destroyable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('destroy_all') do |method|
      method.define_optional_argument('conditions')
    end
  end

  defs.define_constant('Mongoid::Persistable::Incrementable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('inc') do |method|
      method.define_argument('increments')
    end
  end

  defs.define_constant('Mongoid::Persistable::LIST_OPERATIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Persistable::Logical') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('bit') do |method|
      method.define_argument('operations')
    end
  end

  defs.define_constant('Mongoid::Persistable::Poppable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('pop') do |method|
      method.define_argument('pops')
    end
  end

  defs.define_constant('Mongoid::Persistable::Pullable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('pull') do |method|
      method.define_argument('pulls')
    end

    klass.define_instance_method('pull_all') do |method|
      method.define_argument('pulls')
    end
  end

  defs.define_constant('Mongoid::Persistable::Pushable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_to_set') do |method|
      method.define_argument('adds')
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('pushes')
    end
  end

  defs.define_constant('Mongoid::Persistable::Renamable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('rename') do |method|
      method.define_argument('renames')
    end
  end

  defs.define_constant('Mongoid::Persistable::Savable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('save') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('save!') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Mongoid::Persistable::Settable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('set') do |method|
      method.define_argument('setters')
    end
  end

  defs.define_constant('Mongoid::Persistable::Unsettable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('unset') do |method|
      method.define_rest_argument('fields')
    end
  end

  defs.define_constant('Mongoid::Persistable::Updatable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('update') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('update!') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('update_attribute') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('update_attributes') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('update_attributes!') do |method|
      method.define_optional_argument('attributes')
    end
  end

  defs.define_constant('Mongoid::Persistable::Upsertable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('upsert') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Mongoid::Positional') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('positionally') do |method|
      method.define_argument('selector')
      method.define_argument('operations')
      method.define_optional_argument('processed')
    end
  end

  defs.define_constant('Mongoid::QueryCache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cache')

    klass.define_method('cache_table')

    klass.define_method('clear_cache')

    klass.define_method('enabled=') do |method|
      method.define_argument('value')
    end

    klass.define_method('enabled?')
  end

  defs.define_constant('Mongoid::QueryCache::Base') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('alias_query_cache_clear') do |method|
      method.define_rest_argument('method_names')
    end
  end

  defs.define_constant('Mongoid::QueryCache::Cacheable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::QueryCache::CachedCursor') do |klass|
    klass.inherits(defs.constant_proxy('Moped::Cursor', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::QueryCache::Cacheable', RubyLint.registry))

    klass.define_instance_method('load_docs')
  end

  defs.define_constant('Mongoid::QueryCache::CachedCursor::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::QueryCache::CachedCursor::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::QueryCache::Collection') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::QueryCache::Middleware') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::QueryCache::Query') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cursor_with_cache')

    klass.define_instance_method('first_with_cache')
  end

  defs.define_constant('Mongoid::Relations') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__metadata')

    klass.define_instance_method('__metadata=')

    klass.define_instance_method('embedded?')

    klass.define_instance_method('embedded_many?')

    klass.define_instance_method('embedded_one?')

    klass.define_instance_method('metadata_name')

    klass.define_instance_method('referenced_many?')

    klass.define_instance_method('referenced_one?')

    klass.define_instance_method('relation_metadata')

    klass.define_instance_method('reload_relations')
  end

  defs.define_constant('Mongoid::Relations::Accessors') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__build__') do |method|
      method.define_argument('name')
      method.define_argument('object')
      method.define_argument('metadata')
    end

    klass.define_instance_method('create_relation') do |method|
      method.define_argument('object')
      method.define_argument('metadata')
    end

    klass.define_instance_method('reset_relation_criteria') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('set_relation') do |method|
      method.define_argument('name')
      method.define_argument('relation')
    end
  end

  defs.define_constant('Mongoid::Relations::Accessors::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('existence_check') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('getter') do |method|
      method.define_argument('name')
      method.define_argument('metadata')
    end

    klass.define_instance_method('ids_getter') do |method|
      method.define_argument('name')
      method.define_argument('metadata')
    end

    klass.define_instance_method('ids_setter') do |method|
      method.define_argument('name')
      method.define_argument('metadata')
    end

    klass.define_instance_method('setter') do |method|
      method.define_argument('name')
      method.define_argument('metadata')
    end
  end

  defs.define_constant('Mongoid::Relations::AutoSave') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__autosaving__')

    klass.define_instance_method('autosaved?')

    klass.define_instance_method('changed_for_autosave?') do |method|
      method.define_argument('doc')
    end
  end

  defs.define_constant('Mongoid::Relations::AutoSave::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('autosave') do |method|
      method.define_argument('metadata')
    end
  end

  defs.define_constant('Mongoid::Relations::Binding') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Threaded::Lifecycle', RubyLint.registry))

    klass.define_instance_method('base')

    klass.define_instance_method('binding')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('target')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('metadata')

    klass.define_instance_method('target')
  end

  defs.define_constant('Mongoid::Relations::Binding::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Bindings') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Bindings::Embedded') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Bindings::Embedded::In') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Binding', RubyLint.registry))

    klass.define_instance_method('bind_one')

    klass.define_instance_method('unbind_one')
  end

  defs.define_constant('Mongoid::Relations::Bindings::Embedded::In::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Bindings::Embedded::Many') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Binding', RubyLint.registry))

    klass.define_instance_method('bind_one') do |method|
      method.define_argument('doc')
    end

    klass.define_instance_method('unbind_one') do |method|
      method.define_argument('doc')
    end
  end

  defs.define_constant('Mongoid::Relations::Bindings::Embedded::Many::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Bindings::Embedded::One') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Binding', RubyLint.registry))

    klass.define_instance_method('bind_one')

    klass.define_instance_method('unbind_one')
  end

  defs.define_constant('Mongoid::Relations::Bindings::Embedded::One::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Bindings::Referenced') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Bindings::Referenced::In') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Binding', RubyLint.registry))

    klass.define_instance_method('bind_one')

    klass.define_instance_method('unbind_one')
  end

  defs.define_constant('Mongoid::Relations::Bindings::Referenced::In::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Bindings::Referenced::Many') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Binding', RubyLint.registry))

    klass.define_instance_method('bind_one') do |method|
      method.define_argument('doc')
    end

    klass.define_instance_method('unbind_one') do |method|
      method.define_argument('doc')
    end
  end

  defs.define_constant('Mongoid::Relations::Bindings::Referenced::Many::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Bindings::Referenced::ManyToMany') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Binding', RubyLint.registry))

    klass.define_instance_method('bind_one') do |method|
      method.define_argument('doc')
    end

    klass.define_instance_method('determine_inverse_metadata') do |method|
      method.define_argument('doc')
    end

    klass.define_instance_method('inverse_record_id') do |method|
      method.define_argument('doc')
    end

    klass.define_instance_method('unbind_one') do |method|
      method.define_argument('doc')
    end
  end

  defs.define_constant('Mongoid::Relations::Bindings::Referenced::ManyToMany::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Bindings::Referenced::One') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Binding', RubyLint.registry))

    klass.define_instance_method('bind_one')

    klass.define_instance_method('unbind_one')
  end

  defs.define_constant('Mongoid::Relations::Bindings::Referenced::One::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Builder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Threaded::Lifecycle', RubyLint.registry))

    klass.define_instance_method('base')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('metadata')
      method.define_argument('object')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('metadata')

    klass.define_instance_method('object')

    klass.define_instance_method('query?')
  end

  defs.define_constant('Mongoid::Relations::Builder::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Builders') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Builders::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('builder') do |method|
      method.define_argument('name')
      method.define_argument('metadata')
    end

    klass.define_instance_method('creator') do |method|
      method.define_argument('name')
      method.define_argument('metadata')
    end
  end

  defs.define_constant('Mongoid::Relations::Builders::Embedded') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Builders::Embedded::In') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Builder', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('type')
    end
  end

  defs.define_constant('Mongoid::Relations::Builders::Embedded::In::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Builders::Embedded::Many') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Builder', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('type')
    end
  end

  defs.define_constant('Mongoid::Relations::Builders::Embedded::Many::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Builders::Embedded::One') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Builder', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('type')
    end
  end

  defs.define_constant('Mongoid::Relations::Builders::Embedded::One::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Builders::NestedAttributes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Builders::NestedAttributes::Many') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::NestedBuilder', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_argument('parent')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('metadata')
      method.define_argument('attributes')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Relations::Builders::NestedAttributes::One') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::NestedBuilder', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_argument('parent')
    end

    klass.define_instance_method('destroy')

    klass.define_instance_method('destroy=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('metadata')
      method.define_argument('attributes')
      method.define_argument('options')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Mongoid::Relations::Builders::Referenced') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Builders::Referenced::In') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Builder', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('type')
    end
  end

  defs.define_constant('Mongoid::Relations::Builders::Referenced::In::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Builders::Referenced::Many') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Builder', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('type')
    end
  end

  defs.define_constant('Mongoid::Relations::Builders::Referenced::Many::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Builders::Referenced::ManyToMany') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Builder', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('type')
    end

    klass.define_instance_method('query?')
  end

  defs.define_constant('Mongoid::Relations::Builders::Referenced::ManyToMany::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Builders::Referenced::One') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Builder', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('type')
    end
  end

  defs.define_constant('Mongoid::Relations::Builders::Referenced::One::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Cascading') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cascade!')
  end

  defs.define_constant('Mongoid::Relations::Cascading::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cascade') do |method|
      method.define_argument('metadata')
    end
  end

  defs.define_constant('Mongoid::Relations::Cascading::Delete') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cascade')

    klass.define_instance_method('document')

    klass.define_instance_method('document=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('metadata')

    klass.define_instance_method('metadata=')

    klass.define_instance_method('relation')

    klass.define_instance_method('relation=')
  end

  defs.define_constant('Mongoid::Relations::Cascading::Destroy') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cascade')

    klass.define_instance_method('document')

    klass.define_instance_method('document=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('metadata')

    klass.define_instance_method('metadata=')

    klass.define_instance_method('relation')

    klass.define_instance_method('relation=')
  end

  defs.define_constant('Mongoid::Relations::Cascading::Nullify') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cascade')

    klass.define_instance_method('document')

    klass.define_instance_method('document=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('metadata')

    klass.define_instance_method('metadata=')

    klass.define_instance_method('relation')

    klass.define_instance_method('relation=')
  end

  defs.define_constant('Mongoid::Relations::Cascading::Restrict') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cascade')

    klass.define_instance_method('document')

    klass.define_instance_method('document=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('metadata')

    klass.define_instance_method('metadata=')

    klass.define_instance_method('relation')

    klass.define_instance_method('relation=')
  end

  defs.define_constant('Mongoid::Relations::Constraint') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('metadata')
  end

  defs.define_constant('Mongoid::Relations::Conversions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('flag') do |method|
      method.define_argument('object')
      method.define_argument('metadata')
    end
  end

  defs.define_constant('Mongoid::Relations::CounterCache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('reset_counters') do |method|
      method.define_rest_argument('counters')
    end
  end

  defs.define_constant('Mongoid::Relations::CounterCache::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('decrement_counter') do |method|
      method.define_argument('counter_name')
      method.define_argument('id')
    end

    klass.define_instance_method('increment_counter') do |method|
      method.define_argument('counter_name')
      method.define_argument('id')
    end

    klass.define_instance_method('reset_counters') do |method|
      method.define_argument('id')
      method.define_rest_argument('counters')
    end

    klass.define_instance_method('update_counters') do |method|
      method.define_argument('id')
      method.define_argument('counters')
    end
  end

  defs.define_constant('Mongoid::Relations::Cyclic') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Cyclic::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('recursively_embeds_many') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('recursively_embeds_one') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Mongoid::Relations::Eager') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('eager_load') do |method|
      method.define_argument('docs')
    end

    klass.define_instance_method('eager_load_one') do |method|
      method.define_argument('doc')
    end

    klass.define_instance_method('eager_loadable?') do |method|
      method.define_optional_argument('document')
    end

    klass.define_instance_method('eager_loaded')

    klass.define_instance_method('eager_loaded=')

    klass.define_instance_method('preload') do |method|
      method.define_argument('relations')
      method.define_argument('docs')
    end

    klass.define_instance_method('with_eager_loading') do |method|
      method.define_argument('document')
    end
  end

  defs.define_constant('Mongoid::Relations::Eager::Base') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each_loaded_document')

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('grouped_docs')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('associations')
      method.define_argument('docs')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('keys_from_docs')

    klass.define_instance_method('preload')

    klass.define_instance_method('run')

    klass.define_instance_method('set_on_parent') do |method|
      method.define_argument('id')
      method.define_argument('element')
    end

    klass.define_instance_method('set_relation') do |method|
      method.define_argument('doc')
      method.define_argument('element')
    end

    klass.define_instance_method('shift_metadata')
  end

  defs.define_constant('Mongoid::Relations::Eager::BelongsTo') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('preload')
  end

  defs.define_constant('Mongoid::Relations::Eager::HasAndBelongsToMany') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('keys_from_docs')

    klass.define_instance_method('preload')

    klass.define_instance_method('set_relation') do |method|
      method.define_argument('doc')
      method.define_argument('element')
    end
  end

  defs.define_constant('Mongoid::Relations::Eager::HasMany') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('preload')

    klass.define_instance_method('set_relation') do |method|
      method.define_argument('doc')
      method.define_argument('element')
    end
  end

  defs.define_constant('Mongoid::Relations::Eager::HasOne') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Eager::Base', RubyLint.registry))

    klass.define_instance_method('group_by_key')

    klass.define_instance_method('key')

    klass.define_instance_method('preload')
  end

  defs.define_constant('Mongoid::Relations::Embedded') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Embedded::Batchable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('batch_clear') do |method|
      method.define_argument('docs')
    end

    klass.define_instance_method('batch_insert') do |method|
      method.define_argument('docs')
    end

    klass.define_instance_method('batch_remove') do |method|
      method.define_argument('docs')
      method.define_optional_argument('method')
    end

    klass.define_instance_method('batch_replace') do |method|
      method.define_argument('docs')
    end
  end

  defs.define_constant('Mongoid::Relations::Embedded::In') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::One', RubyLint.registry))

    klass.define_method('builder') do |method|
      method.define_argument('base')
      method.define_argument('meta')
      method.define_argument('object')
    end

    klass.define_method('embedded?')

    klass.define_method('foreign_key_suffix')

    klass.define_method('macro')

    klass.define_method('nested_builder') do |method|
      method.define_argument('metadata')
      method.define_argument('attributes')
      method.define_argument('options')
    end

    klass.define_method('path') do |method|
      method.define_argument('document')
    end

    klass.define_method('stores_foreign_key?')

    klass.define_method('valid_options')

    klass.define_method('validation_default')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('target')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('substitute') do |method|
      method.define_argument('replacement')
    end
  end

  defs.define_constant('Mongoid::Relations::Embedded::In::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Embedded::Many') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Many', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Embedded::Batchable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Positional', RubyLint.registry))

    klass.define_method('builder') do |method|
      method.define_argument('base')
      method.define_argument('meta')
      method.define_argument('object')
    end

    klass.define_method('embedded?')

    klass.define_method('foreign_key_suffix')

    klass.define_method('macro')

    klass.define_method('nested_builder') do |method|
      method.define_argument('metadata')
      method.define_argument('attributes')
      method.define_argument('options')
    end

    klass.define_method('path') do |method|
      method.define_argument('document')
    end

    klass.define_method('stores_foreign_key?')

    klass.define_method('valid_options')

    klass.define_method('validation_default')

    klass.define_instance_method('<<') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('as_document')

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
      method.define_optional_argument('type')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('concat') do |method|
      method.define_argument('docs')
    end

    klass.define_instance_method('count')

    klass.define_instance_method('delete') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('delete_all') do |method|
      method.define_optional_argument('conditions')
    end

    klass.define_instance_method('delete_if')

    klass.define_instance_method('destroy_all') do |method|
      method.define_optional_argument('conditions')
    end

    klass.define_instance_method('exists?')

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('in_memory')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('target')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('new') do |method|
      method.define_optional_argument('attributes')
      method.define_optional_argument('type')
    end

    klass.define_instance_method('pop') do |method|
      method.define_optional_argument('count')
    end

    klass.define_instance_method('push') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('substitute') do |method|
      method.define_argument('docs')
    end

    klass.define_instance_method('unscoped')
  end

  defs.define_constant('Mongoid::Relations::Embedded::Many::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Embedded::One') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::One', RubyLint.registry))

    klass.define_method('builder') do |method|
      method.define_argument('base')
      method.define_argument('meta')
      method.define_argument('object')
    end

    klass.define_method('embedded?')

    klass.define_method('foreign_key_suffix')

    klass.define_method('macro')

    klass.define_method('nested_builder') do |method|
      method.define_argument('metadata')
      method.define_argument('attributes')
      method.define_argument('options')
    end

    klass.define_method('path') do |method|
      method.define_argument('document')
    end

    klass.define_method('stores_foreign_key?')

    klass.define_method('valid_options')

    klass.define_method('validation_default')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('target')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('substitute') do |method|
      method.define_argument('replacement')
    end
  end

  defs.define_constant('Mongoid::Relations::Embedded::One::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Macros') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('associations')
  end

  defs.define_constant('Mongoid::Relations::Macros::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('belongs_to') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('embedded_in') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('embeds_many') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('embeds_one') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('has_and_belongs_to_many') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('has_many') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('has_one') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Mongoid::Relations::Many') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Proxy', RubyLint.registry))

    klass.define_instance_method('avg') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('blank?')

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_optional_argument('type')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_optional_argument('type')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_or_create_by') do |method|
      method.define_optional_argument('attrs')
      method.define_optional_argument('type')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_or_initialize_by') do |method|
      method.define_optional_argument('attrs')
      method.define_optional_argument('type')
      method.define_block_argument('block')
    end

    klass.define_instance_method('length') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('max') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('min') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('nil?')

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
      method.define_optional_argument('include_private')
    end

    klass.define_instance_method('scoped')

    klass.define_instance_method('serializable_hash') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('size') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('unscoped')
  end

  defs.define_constant('Mongoid::Relations::Many::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Marshalable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('data')
    end
  end

  defs.define_constant('Mongoid::Relations::Metadata') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))

    klass.define_instance_method('as')

    klass.define_instance_method('as?')

    klass.define_instance_method('autobuilding?')

    klass.define_instance_method('autosave')

    klass.define_instance_method('autosave?')

    klass.define_instance_method('builder') do |method|
      method.define_argument('base')
      method.define_argument('object')
    end

    klass.define_instance_method('cascade_strategy')

    klass.define_instance_method('cascading_callbacks?')

    klass.define_instance_method('class_name')

    klass.define_instance_method('constraint')

    klass.define_instance_method('counter_cache_column_name')

    klass.define_instance_method('counter_cached?')

    klass.define_instance_method('criteria') do |method|
      method.define_argument('object')
      method.define_argument('type')
    end

    klass.define_instance_method('cyclic')

    klass.define_instance_method('cyclic?')

    klass.define_instance_method('dependent')

    klass.define_instance_method('dependent?')

    klass.define_instance_method('destructive?')

    klass.define_instance_method('embedded?')

    klass.define_instance_method('extension')

    klass.define_instance_method('extension?')

    klass.define_instance_method('forced_nil_inverse?')

    klass.define_instance_method('foreign_key')

    klass.define_instance_method('foreign_key_check')

    klass.define_instance_method('foreign_key_default') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('foreign_key_setter')

    klass.define_instance_method('index')

    klass.define_instance_method('indexed?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('properties')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('inverse') do |method|
      method.define_optional_argument('other')
    end

    klass.define_instance_method('inverse_class_name')

    klass.define_instance_method('inverse_class_name?')

    klass.define_instance_method('inverse_foreign_key')

    klass.define_instance_method('inverse_klass')

    klass.define_instance_method('inverse_metadata') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('inverse_of')

    klass.define_instance_method('inverse_of?')

    klass.define_instance_method('inverse_setter') do |method|
      method.define_optional_argument('other')
    end

    klass.define_instance_method('inverse_type')

    klass.define_instance_method('inverse_type_setter')

    klass.define_instance_method('inverses') do |method|
      method.define_optional_argument('other')
    end

    klass.define_instance_method('key')

    klass.define_instance_method('klass')

    klass.define_instance_method('macro')

    klass.define_instance_method('many?')

    klass.define_instance_method('name')

    klass.define_instance_method('name?')

    klass.define_instance_method('nested_builder') do |method|
      method.define_argument('attributes')
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('order')

    klass.define_instance_method('order?')

    klass.define_instance_method('path') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('polymorphic?')

    klass.define_instance_method('primary_key')

    klass.define_instance_method('relation')

    klass.define_instance_method('setter')

    klass.define_instance_method('store_as')

    klass.define_instance_method('stores_foreign_key?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('touchable?')

    klass.define_instance_method('type')

    klass.define_instance_method('type_relation')

    klass.define_instance_method('type_setter')

    klass.define_instance_method('validate?')
  end

  defs.define_constant('Mongoid::Relations::Metadata::BSON_ADJUST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Metadata::BSON_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Metadata::Bucket') do |klass|
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

  defs.define_constant('Mongoid::Relations::Metadata::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('mongoize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('resizable?')
  end

  defs.define_constant('Mongoid::Relations::Metadata::Entries') do |klass|
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

    klass.define_instance_method('to_ary')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Mongoid::Relations::Metadata::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::Relations::Metadata::Iterator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next') do |method|
      method.define_argument('item')
    end
  end

  defs.define_constant('Mongoid::Relations::Metadata::MAX_ENTRIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Metadata::MIN_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Metadata::PLACEHOLDER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Metadata::STRING_ADJUST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Metadata::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::Relations::Metadata::State') do |klass|
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

  defs.define_constant('Mongoid::Relations::NestedBuilder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('allow_destroy?')

    klass.define_instance_method('attributes')

    klass.define_instance_method('attributes=')

    klass.define_instance_method('convert_id') do |method|
      method.define_argument('klass')
      method.define_argument('id')
    end

    klass.define_instance_method('existing')

    klass.define_instance_method('existing=')

    klass.define_instance_method('metadata')

    klass.define_instance_method('metadata=')

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('reject?') do |method|
      method.define_argument('document')
      method.define_argument('attrs')
    end

    klass.define_instance_method('update_only?')
  end

  defs.define_constant('Mongoid::Relations::One') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Proxy', RubyLint.registry))

    klass.define_instance_method('__evolve_object_id__')

    klass.define_instance_method('clear')

    klass.define_instance_method('in_memory')

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
      method.define_optional_argument('include_private')
    end
  end

  defs.define_constant('Mongoid::Relations::One::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validate!') do |method|
      method.define_argument('options')
    end
  end

  defs.define_constant('Mongoid::Relations::Options::COMMON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Polymorphic') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Polymorphic::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('polymorph') do |method|
      method.define_argument('metadata')
    end
  end

  defs.define_constant('Mongoid::Relations::Proxy') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Marshalable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Threaded::Lifecycle', RubyLint.registry))

    klass.define_method('apply_ordering') do |method|
      method.define_argument('criteria')
      method.define_argument('metadata')
    end

    klass.define_instance_method('__metadata')

    klass.define_instance_method('__metadata=')

    klass.define_instance_method('base')

    klass.define_instance_method('base=')

    klass.define_instance_method('bind_one') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('callback_method') do |method|
      method.define_argument('callback_name')
    end

    klass.define_instance_method('characterize_one') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('collection')

    klass.define_instance_method('collection_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute_callback') do |method|
      method.define_argument('callback')
      method.define_argument('doc')
    end

    klass.define_instance_method('extend_proxies') do |method|
      method.define_rest_argument('extension')
    end

    klass.define_instance_method('extend_proxy') do |method|
      method.define_rest_argument('modules')
    end

    klass.define_instance_method('foreign_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('init') do |method|
      method.define_argument('base')
      method.define_argument('target')
      method.define_argument('metadata')
    end

    klass.define_instance_method('inverse_foreign_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('raise_mixed')

    klass.define_instance_method('raise_unsaved') do |method|
      method.define_argument('doc')
    end

    klass.define_instance_method('relation_metadata')

    klass.define_instance_method('reset_unloaded')

    klass.define_instance_method('substitutable')

    klass.define_instance_method('target')

    klass.define_instance_method('target=')

    klass.define_instance_method('unbind_one') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with') do |method|
      method.define_argument('options')
    end
  end

  defs.define_constant('Mongoid::Relations::Proxy::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Referenced') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Referenced::In') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::One', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Evolvable', RubyLint.registry))

    klass.define_method('builder') do |method|
      method.define_argument('base')
      method.define_argument('meta')
      method.define_argument('object')
    end

    klass.define_method('criteria') do |method|
      method.define_argument('metadata')
      method.define_argument('object')
      method.define_optional_argument('type')
    end

    klass.define_method('eager_load_klass')

    klass.define_method('embedded?')

    klass.define_method('foreign_key') do |method|
      method.define_argument('name')
    end

    klass.define_method('foreign_key_default')

    klass.define_method('foreign_key_suffix')

    klass.define_method('macro')

    klass.define_method('nested_builder') do |method|
      method.define_argument('metadata')
      method.define_argument('attributes')
      method.define_argument('options')
    end

    klass.define_method('path') do |method|
      method.define_argument('document')
    end

    klass.define_method('stores_foreign_key?')

    klass.define_method('valid_options')

    klass.define_method('validation_default')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('target')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('nullify')

    klass.define_instance_method('substitute') do |method|
      method.define_argument('replacement')
    end
  end

  defs.define_constant('Mongoid::Relations::Referenced::In::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Referenced::Many') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Many', RubyLint.registry))

    klass.define_method('builder') do |method|
      method.define_argument('base')
      method.define_argument('meta')
      method.define_argument('object')
    end

    klass.define_method('criteria') do |method|
      method.define_argument('metadata')
      method.define_argument('object')
      method.define_optional_argument('type')
    end

    klass.define_method('eager_load_klass')

    klass.define_method('embedded?')

    klass.define_method('foreign_key') do |method|
      method.define_argument('name')
    end

    klass.define_method('foreign_key_default')

    klass.define_method('foreign_key_suffix')

    klass.define_method('macro')

    klass.define_method('nested_builder') do |method|
      method.define_argument('metadata')
      method.define_argument('attributes')
      method.define_argument('options')
    end

    klass.define_method('path') do |method|
      method.define_argument('document')
    end

    klass.define_method('stores_foreign_key?')

    klass.define_method('valid_options')

    klass.define_method('validation_default')

    klass.define_instance_method('<<') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
      method.define_optional_argument('type')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('concat') do |method|
      method.define_argument('documents')
    end

    klass.define_instance_method('count') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('delete_all') do |method|
      method.define_optional_argument('conditions')
    end

    klass.define_instance_method('destroy_all') do |method|
      method.define_optional_argument('conditions')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('exists?')

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('first') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('in_memory') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('target')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('last') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('new') do |method|
      method.define_optional_argument('attributes')
      method.define_optional_argument('type')
    end

    klass.define_instance_method('nullify')

    klass.define_instance_method('nullify_all')

    klass.define_instance_method('purge')

    klass.define_instance_method('push') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('reset') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('substitute') do |method|
      method.define_argument('replacement')
    end

    klass.define_instance_method('uniq') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('unscoped')
  end

  defs.define_constant('Mongoid::Relations::Referenced::Many::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Referenced::ManyToMany') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::Referenced::Many', RubyLint.registry))

    klass.define_method('builder') do |method|
      method.define_argument('base')
      method.define_argument('meta')
      method.define_argument('object')
    end

    klass.define_method('criteria') do |method|
      method.define_argument('metadata')
      method.define_argument('object')
      method.define_optional_argument('type')
    end

    klass.define_method('eager_load_klass')

    klass.define_method('embedded?')

    klass.define_method('foreign_key') do |method|
      method.define_argument('name')
    end

    klass.define_method('foreign_key_default')

    klass.define_method('foreign_key_suffix')

    klass.define_method('macro')

    klass.define_method('nested_builder') do |method|
      method.define_argument('metadata')
      method.define_argument('attributes')
      method.define_argument('options')
    end

    klass.define_method('path') do |method|
      method.define_argument('document')
    end

    klass.define_method('stores_foreign_key?')

    klass.define_method('valid_options')

    klass.define_method('validation_default')

    klass.define_instance_method('<<') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
      method.define_optional_argument('type')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('concat') do |method|
      method.define_argument('documents')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('new') do |method|
      method.define_optional_argument('attributes')
      method.define_optional_argument('type')
    end

    klass.define_instance_method('nullify')

    klass.define_instance_method('nullify_all')

    klass.define_instance_method('purge')

    klass.define_instance_method('push') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('substitute') do |method|
      method.define_argument('replacement')
    end

    klass.define_instance_method('unscoped')
  end

  defs.define_constant('Mongoid::Relations::Referenced::ManyToMany::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Referenced::One') do |klass|
    klass.inherits(defs.constant_proxy('Mongoid::Relations::One', RubyLint.registry))

    klass.define_method('builder') do |method|
      method.define_argument('base')
      method.define_argument('meta')
      method.define_argument('object')
    end

    klass.define_method('criteria') do |method|
      method.define_argument('metadata')
      method.define_argument('object')
      method.define_optional_argument('type')
    end

    klass.define_method('eager_load_klass')

    klass.define_method('embedded?')

    klass.define_method('foreign_key') do |method|
      method.define_argument('name')
    end

    klass.define_method('foreign_key_default')

    klass.define_method('foreign_key_suffix')

    klass.define_method('macro')

    klass.define_method('nested_builder') do |method|
      method.define_argument('metadata')
      method.define_argument('attributes')
      method.define_argument('options')
    end

    klass.define_method('path') do |method|
      method.define_argument('document')
    end

    klass.define_method('stores_foreign_key?')

    klass.define_method('valid_options')

    klass.define_method('validation_default')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('target')
      method.define_argument('metadata')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('nullify')

    klass.define_instance_method('substitute') do |method|
      method.define_argument('replacement')
    end
  end

  defs.define_constant('Mongoid::Relations::Referenced::One::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Relations::Reflections') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('reflect_on_all_associations') do |method|
      method.define_rest_argument('macros')
    end

    klass.define_instance_method('reflect_on_association') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('Mongoid::Relations::Reflections::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('reflect_on_all_associations') do |method|
      method.define_rest_argument('macros')
    end

    klass.define_instance_method('reflect_on_association') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('Mongoid::Relations::Synchronization') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('remove_inverse_keys') do |method|
      method.define_argument('meta')
    end

    klass.define_instance_method('syncable?') do |method|
      method.define_argument('metadata')
    end

    klass.define_instance_method('synced')

    klass.define_instance_method('synced?') do |method|
      method.define_argument('foreign_key')
    end

    klass.define_instance_method('update_inverse_keys') do |method|
      method.define_argument('meta')
    end
  end

  defs.define_constant('Mongoid::Relations::Synchronization::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('synced') do |method|
      method.define_argument('metadata')
    end
  end

  defs.define_constant('Mongoid::Relations::Targets') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Relations::Targets::Enumerable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('_added')

    klass.define_instance_method('_added=')

    klass.define_instance_method('_loaded')

    klass.define_instance_method('_loaded=')

    klass.define_instance_method('_loaded?')

    klass.define_instance_method('_unloaded')

    klass.define_instance_method('_unloaded=')

    klass.define_instance_method('as_json') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('clone')

    klass.define_instance_method('delete') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('delete_if') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('empty?')

    klass.define_instance_method('first')

    klass.define_instance_method('in_memory')

    klass.define_instance_method('include?') do |method|
      method.define_argument('doc')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('target')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('is_a?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('kind_of?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('load_all!') do |method|
      method.define_rest_argument('arg')
    end

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('reset_unloaded') do |method|
      method.define_argument('criteria')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
      method.define_optional_argument('include_private')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('to_json') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('uniq')
  end

  defs.define_constant('Mongoid::Relations::Targets::Enumerable::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('feed') do |method|
      method.define_argument('val')
    end

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

  defs.define_constant('Mongoid::Relations::Targets::Enumerable::SortedElement') do |klass|
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

  defs.define_constant('Mongoid::Relations::Touchable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('touch') do |method|
      method.define_optional_argument('field')
    end
  end

  defs.define_constant('Mongoid::Relations::Touchable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('touchable') do |method|
      method.define_argument('metadata')
    end
  end

  defs.define_constant('Mongoid::Reloadable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('reload')
  end

  defs.define_constant('Mongoid::Scopable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Scopable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('criteria')

    klass.define_instance_method('default_scopable?')

    klass.define_instance_method('default_scope') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('queryable')

    klass.define_instance_method('scope') do |method|
      method.define_argument('name')
      method.define_argument('value')
      method.define_block_argument('block')
    end

    klass.define_instance_method('scope_stack')

    klass.define_instance_method('scoped') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('scopes')

    klass.define_instance_method('unscoped')

    klass.define_instance_method('with_default_scope')

    klass.define_instance_method('with_scope') do |method|
      method.define_argument('criteria')
    end

    klass.define_instance_method('without_default_scope')
  end

  defs.define_constant('Mongoid::Selectable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('atomic_selector')
  end

  defs.define_constant('Mongoid::Serializable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('serializable_hash') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Mongoid::Sessions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('clear')

    klass.define_method('default')

    klass.define_method('disconnect')

    klass.define_method('with_name') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('collection')

    klass.define_instance_method('collection_name')

    klass.define_instance_method('mongo_session')
  end

  defs.define_constant('Mongoid::Sessions::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collection')

    klass.define_instance_method('mongo_session')
  end

  defs.define_constant('Mongoid::Sessions::Factory') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('name')
    end

    klass.define_instance_method('default')
  end

  defs.define_constant('Mongoid::Sessions::MongoUri') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('database')

    klass.define_instance_method('hosts')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('string')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('match')

    klass.define_instance_method('password')

    klass.define_instance_method('to_hash')

    klass.define_instance_method('username')
  end

  defs.define_constant('Mongoid::Sessions::MongoUri::DATABASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Sessions::MongoUri::NODES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Sessions::MongoUri::PASS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Sessions::MongoUri::SCHEME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Sessions::MongoUri::URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Sessions::MongoUri::USER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Sessions::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collection_name')

    klass.define_instance_method('mongo_session')

    klass.define_instance_method('persistence_options')

    klass.define_instance_method('with') do |method|
      method.define_argument('options')
    end
  end

  defs.define_constant('Mongoid::Sessions::Options::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collection_name')

    klass.define_instance_method('database_name')

    klass.define_instance_method('session_name')

    klass.define_instance_method('with') do |method|
      method.define_argument('options')
    end
  end

  defs.define_constant('Mongoid::Sessions::Options::Proxy') do |klass|
    klass.inherits(defs.constant_proxy('BasicObject', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Sessions::Options::Threaded', RubyLint.registry))

    klass.define_method('const_missing') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('target')
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('persistence_options')

    klass.define_instance_method('respond_to?') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('send') do |method|
      method.define_argument('symbol')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Mongoid::Sessions::Options::Proxy::BasicObject') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('!')

    klass.define_instance_method('!=') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('__id__')

    klass.define_instance_method('__instance_variables__')

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
      method.define_optional_argument('strip_ivars')
    end

    klass.define_instance_method('__send__') do |method|
      method.define_argument('message')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('equal?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('instance_eval') do |method|
      method.define_optional_argument('string')
      method.define_optional_argument('filename')
      method.define_optional_argument('line')
    end

    klass.define_instance_method('instance_exec') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Mongoid::Sessions::Options::Threaded') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('persistence_options') do |method|
      method.define_optional_argument('klass')
    end
  end

  defs.define_constant('Mongoid::Sessions::StorageOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Sessions::StorageOptions::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collection_name')

    klass.define_instance_method('database_name')

    klass.define_instance_method('reset_storage_options!')

    klass.define_instance_method('session_name')

    klass.define_instance_method('storage_options_defaults')

    klass.define_instance_method('store_in') do |method|
      method.define_argument('options')
    end
  end

  defs.define_constant('Mongoid::Sessions::ThreadOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Sessions::ThreadOptions::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('database_name')

    klass.define_instance_method('session_name')
  end

  defs.define_constant('Mongoid::Sessions::Validators') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Sessions::Validators::Storage') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validate') do |method|
      method.define_argument('klass')
      method.define_argument('options')
    end
  end

  defs.define_constant('Mongoid::Sessions::Validators::Storage::VALID_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Shardable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('shard_key_fields')

    klass.define_instance_method('shard_key_selector')
  end

  defs.define_constant('Mongoid::Shardable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('shard_key') do |method|
      method.define_rest_argument('names')
    end
  end

  defs.define_constant('Mongoid::Stateful') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('deleted?')

    klass.define_instance_method('destroyed=')

    klass.define_instance_method('destroyed?')

    klass.define_instance_method('flagged_for_destroy=')

    klass.define_instance_method('flagged_for_destroy?')

    klass.define_instance_method('marked_for_destruction?')

    klass.define_instance_method('new_record=')

    klass.define_instance_method('new_record?')

    klass.define_instance_method('persisted?')

    klass.define_instance_method('pushable?')

    klass.define_instance_method('readonly?')

    klass.define_instance_method('settable?')

    klass.define_instance_method('updateable?')
  end

  defs.define_constant('Mongoid::Tasks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Tasks::Database') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('create_indexes') do |method|
      method.define_optional_argument('models')
    end

    klass.define_instance_method('remove_indexes') do |method|
      method.define_optional_argument('models')
    end

    klass.define_instance_method('remove_undefined_indexes') do |method|
      method.define_optional_argument('models')
    end

    klass.define_instance_method('undefined_indexes') do |method|
      method.define_optional_argument('models')
    end
  end

  defs.define_constant('Mongoid::Threaded') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('autosaved?') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('autosaves')

    klass.define_instance_method('autosaves_for') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('begin_autosave') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('begin_execution') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('begin_validate') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('database_override')

    klass.define_instance_method('database_override=') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('executing?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('exit_autosave') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('exit_execution') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('exit_validate') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('scope_stack')

    klass.define_instance_method('session_override')

    klass.define_instance_method('session_override=') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('sessions')

    klass.define_instance_method('stack') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('validated?') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('validations')

    klass.define_instance_method('validations_for') do |method|
      method.define_argument('klass')
    end
  end

  defs.define_constant('Mongoid::Threaded::Lifecycle') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Threaded::Lifecycle::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_creating')
  end

  defs.define_constant('Mongoid::Timestamps') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Timestamps::Created') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('set_created_at')
  end

  defs.define_constant('Mongoid::Timestamps::Created::Short') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Timestamps::Short') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Timestamps::Timeless') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('[]=') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('timeless_table')

    klass.define_instance_method('clear_timeless_option')

    klass.define_instance_method('timeless')

    klass.define_instance_method('timeless?')
  end

  defs.define_constant('Mongoid::Timestamps::Timeless::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('clear_timeless_option')

    klass.define_instance_method('timeless')

    klass.define_instance_method('timeless?')
  end

  defs.define_constant('Mongoid::Timestamps::Updated') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('able_to_set_updated_at?')

    klass.define_instance_method('set_updated_at')
  end

  defs.define_constant('Mongoid::Timestamps::Updated::Short') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Traversable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_children')

    klass.define_instance_method('_root')

    klass.define_instance_method('_root?')

    klass.define_instance_method('collect_children')

    klass.define_instance_method('flag_children_persisted')

    klass.define_instance_method('hereditary?')

    klass.define_instance_method('parentize') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('remove_child') do |method|
      method.define_argument('child')
    end

    klass.define_instance_method('reset_persisted_children')
  end

  defs.define_constant('Mongoid::Traversable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('hereditary?')

    klass.define_instance_method('inherited') do |method|
      method.define_argument('subclass')
    end
  end

  defs.define_constant('Mongoid::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Validatable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('begin_validate')

    klass.define_instance_method('exit_validate')

    klass.define_instance_method('performing_validations?') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('read_attribute_for_validation') do |method|
      method.define_argument('attr')
    end

    klass.define_instance_method('valid?') do |method|
      method.define_optional_argument('context')
    end

    klass.define_instance_method('validated?')

    klass.define_instance_method('validating_with_query?')
  end

  defs.define_constant('Mongoid::Validatable::AssociatedValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('document')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Validatable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validates_relation') do |method|
      method.define_argument('metadata')
    end

    klass.define_instance_method('validates_with') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('validating_with_query?')
  end

  defs.define_constant('Mongoid::Validatable::FormatValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::FormatValidator', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Validatable::Localizable', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Validatable::LengthValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::LengthValidator', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Validatable::Localizable', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Validatable::LengthValidator::CHECKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Validatable::LengthValidator::MESSAGES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Validatable::LengthValidator::RESERVED_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Mongoid::Validatable::Localizable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('document')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Validatable::Macros') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validates_associated') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('validates_format_of') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('validates_length_of') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('validates_presence_of') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('validates_uniqueness_of') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Mongoid::Validatable::PresenceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('document')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('Mongoid::Validatable::Queryable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('with_query') do |method|
      method.define_argument('document')
    end
  end

  defs.define_constant('Mongoid::Validatable::UniquenessValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Mongoid::Validatable::Queryable', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('document')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end
end
