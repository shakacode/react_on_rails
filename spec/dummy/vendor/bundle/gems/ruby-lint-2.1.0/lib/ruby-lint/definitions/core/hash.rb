# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Hash') do |defs|
  defs.define_constant('Hash') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('JSON::Ext::Generator::GeneratorMethods::Hash', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('allocate')

    klass.define_method('new_from_literal') do |method|
      method.define_argument('size')
    end

    klass.define_method('try_convert') do |method|
      method.define_argument('obj')
    end

    klass.define_method('yaml_tag_subclasses?')

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

    klass.define_instance_method('__entries__')

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
    end

    klass.define_instance_method('__store__') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('assoc') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('capacity')

    klass.define_instance_method('clear')

    klass.define_instance_method('compare_by_identity')

    klass.define_instance_method('compare_by_identity?')

    klass.define_instance_method('default') do |method|
      method.define_optional_argument('key')
    end

    klass.define_instance_method('default=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('default_proc')

    klass.define_instance_method('default_proc=') do |method|
      method.define_argument('prc')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('delete_if')

    klass.define_instance_method('each')

    klass.define_instance_method('each_item')

    klass.define_instance_method('each_key')

    klass.define_instance_method('each_pair')

    klass.define_instance_method('each_value')

    klass.define_instance_method('empty?')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('fetch') do |method|
      method.define_argument('key')
      method.define_optional_argument('default')
    end

    klass.define_instance_method('find_item') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('flatten') do |method|
      method.define_optional_argument('level')
    end

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('has_value?') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('include?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('index') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('indexes') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('indices') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('default')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('invert')

    klass.define_instance_method('keep_if')

    klass.define_instance_method('key') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('key?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('keys')

    klass.define_instance_method('length')

    klass.define_instance_method('max_entries')

    klass.define_instance_method('member?') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('merge!') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('pretty_print_cycle') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('rassoc') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('redistribute') do |method|
      method.define_argument('entries')
    end

    klass.define_instance_method('rehash')

    klass.define_instance_method('reject')

    klass.define_instance_method('reject!')

    klass.define_instance_method('replace') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('select')

    klass.define_instance_method('select!')

    klass.define_instance_method('shift')

    klass.define_instance_method('size')

    klass.define_instance_method('sort')

    klass.define_instance_method('store') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_h')

    klass.define_instance_method('to_hash')

    klass.define_instance_method('to_iter')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('update') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('value?') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('values')

    klass.define_instance_method('values_at') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('yaml_initialize') do |method|
      method.define_argument('tag')
      method.define_argument('val')
    end
  end

  defs.define_constant('Hash::Bucket') do |klass|
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

  defs.define_constant('Hash::Entries') do |klass|
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

  defs.define_constant('Hash::Enumerator') do |klass|
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

  defs.define_constant('Hash::Iterator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next') do |method|
      method.define_argument('item')
    end
  end

  defs.define_constant('Hash::MAX_ENTRIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Hash::MIN_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Hash::SortedElement') do |klass|
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

  defs.define_constant('Hash::State') do |klass|
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
end
