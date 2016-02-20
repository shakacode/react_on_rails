# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('OptionParser') do |defs|
  defs.define_constant('OptionParser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('accept') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('blk')
    end

    klass.define_method('getopts') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('inc') do |method|
      method.define_argument('arg')
      method.define_optional_argument('default')
    end

    klass.define_method('reject') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('blk')
    end

    klass.define_method('terminate') do |method|
      method.define_optional_argument('arg')
    end

    klass.define_method('top')

    klass.define_method('with') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('abort') do |method|
      method.define_optional_argument('mesg')
    end

    klass.define_instance_method('accept') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('add_officious')

    klass.define_instance_method('banner')

    klass.define_instance_method('banner=')

    klass.define_instance_method('base')

    klass.define_instance_method('candidate') do |method|
      method.define_argument('word')
    end

    klass.define_instance_method('compsys') do |method|
      method.define_argument('to')
      method.define_optional_argument('name')
    end

    klass.define_instance_method('def_head_option') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('block')
    end

    klass.define_instance_method('def_option') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('block')
    end

    klass.define_instance_method('def_tail_option') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('block')
    end

    klass.define_instance_method('default_argv')

    klass.define_instance_method('default_argv=')

    klass.define_instance_method('define') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('block')
    end

    klass.define_instance_method('define_head') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('block')
    end

    klass.define_instance_method('define_tail') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('block')
    end

    klass.define_instance_method('environment') do |method|
      method.define_optional_argument('env')
    end

    klass.define_instance_method('getopts') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('help')

    klass.define_instance_method('inc') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('banner')
      method.define_optional_argument('width')
      method.define_optional_argument('indent')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load') do |method|
      method.define_optional_argument('filename')
    end

    klass.define_instance_method('make_switch') do |method|
      method.define_argument('opts')
      method.define_optional_argument('block')
    end

    klass.define_instance_method('new')

    klass.define_instance_method('on') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('block')
    end

    klass.define_instance_method('on_head') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('block')
    end

    klass.define_instance_method('on_tail') do |method|
      method.define_rest_argument('opts')
      method.define_block_argument('block')
    end

    klass.define_instance_method('order') do |method|
      method.define_rest_argument('argv')
      method.define_block_argument('block')
    end

    klass.define_instance_method('order!') do |method|
      method.define_optional_argument('argv')
      method.define_block_argument('nonopt')
    end

    klass.define_instance_method('parse') do |method|
      method.define_rest_argument('argv')
    end

    klass.define_instance_method('parse!') do |method|
      method.define_optional_argument('argv')
    end

    klass.define_instance_method('permute') do |method|
      method.define_rest_argument('argv')
    end

    klass.define_instance_method('permute!') do |method|
      method.define_optional_argument('argv')
    end

    klass.define_instance_method('program_name')

    klass.define_instance_method('program_name=')

    klass.define_instance_method('reject') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('release')

    klass.define_instance_method('release=')

    klass.define_instance_method('remove')

    klass.define_instance_method('separator') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('set_banner')

    klass.define_instance_method('set_program_name')

    klass.define_instance_method('set_summary_indent')

    klass.define_instance_method('set_summary_width')

    klass.define_instance_method('summarize') do |method|
      method.define_optional_argument('to')
      method.define_optional_argument('width')
      method.define_optional_argument('max')
      method.define_optional_argument('indent')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('summary_indent')

    klass.define_instance_method('summary_indent=')

    klass.define_instance_method('summary_width')

    klass.define_instance_method('summary_width=')

    klass.define_instance_method('terminate') do |method|
      method.define_optional_argument('arg')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')

    klass.define_instance_method('top')

    klass.define_instance_method('ver')

    klass.define_instance_method('version')

    klass.define_instance_method('version=')

    klass.define_instance_method('warn') do |method|
      method.define_optional_argument('mesg')
    end
  end

  defs.define_constant('OptionParser::Acceptables') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::Acceptables::DecimalInteger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::Acceptables::DecimalNumeric') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::Acceptables::OctalInteger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::AmbiguousArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::InvalidArgument', RubyLint.registry))

  end

  defs.define_constant('OptionParser::AmbiguousArgument::Reason') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::AmbiguousOption') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::ParseError', RubyLint.registry))

  end

  defs.define_constant('OptionParser::AmbiguousOption::Reason') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::Arguable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('extend_object') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('getopts') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=') do |method|
      method.define_argument('opt')
    end

    klass.define_instance_method('order!') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('parse!')

    klass.define_instance_method('permute!')
  end

  defs.define_constant('OptionParser::ArgumentStyle') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::COMPSYS_HEADER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::CompletingHash') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))
    klass.inherits(defs.constant_proxy('OptionParser::Completion', RubyLint.registry))

    klass.define_instance_method('match') do |method|
      method.define_argument('key')
    end
  end

  defs.define_constant('OptionParser::CompletingHash::Bucket') do |klass|
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

  defs.define_constant('OptionParser::CompletingHash::Entries') do |klass|
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

  defs.define_constant('OptionParser::CompletingHash::Enumerator') do |klass|
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

  defs.define_constant('OptionParser::CompletingHash::Iterator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next') do |method|
      method.define_argument('item')
    end
  end

  defs.define_constant('OptionParser::CompletingHash::MAX_ENTRIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::CompletingHash::MIN_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::CompletingHash::SortedElement') do |klass|
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

  defs.define_constant('OptionParser::CompletingHash::State') do |klass|
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

  defs.define_constant('OptionParser::Completion') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('candidate') do |method|
      method.define_argument('key')
      method.define_optional_argument('icase')
      method.define_optional_argument('pat')
      method.define_block_argument('block')
    end

    klass.define_method('regexp') do |method|
      method.define_argument('key')
      method.define_argument('icase')
    end

    klass.define_instance_method('candidate') do |method|
      method.define_argument('key')
      method.define_optional_argument('icase')
      method.define_optional_argument('pat')
    end

    klass.define_instance_method('complete') do |method|
      method.define_argument('key')
      method.define_optional_argument('icase')
      method.define_optional_argument('pat')
    end

    klass.define_instance_method('convert') do |method|
      method.define_optional_argument('opt')
      method.define_optional_argument('val')
      method.define_rest_argument('arg3')
    end
  end

  defs.define_constant('OptionParser::DecimalInteger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::DecimalNumeric') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::DefaultList') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::InvalidArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::ParseError', RubyLint.registry))

  end

  defs.define_constant('OptionParser::InvalidArgument::Reason') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::InvalidOption') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::ParseError', RubyLint.registry))

  end

  defs.define_constant('OptionParser::InvalidOption::Reason') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::LastModified') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::List') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accept') do |method|
      method.define_argument('t')
      method.define_optional_argument('pat')
      method.define_block_argument('block')
    end

    klass.define_instance_method('add_banner') do |method|
      method.define_argument('to')
    end

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('atype')

    klass.define_instance_method('complete') do |method|
      method.define_argument('id')
      method.define_argument('opt')
      method.define_optional_argument('icase')
      method.define_rest_argument('pat')
      method.define_block_argument('block')
    end

    klass.define_instance_method('compsys') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('each_option') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('list')

    klass.define_instance_method('long')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('reject') do |method|
      method.define_argument('t')
    end

    klass.define_instance_method('search') do |method|
      method.define_argument('id')
      method.define_argument('key')
    end

    klass.define_instance_method('short')

    klass.define_instance_method('summarize') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('OptionParser::MissingArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::ParseError', RubyLint.registry))

  end

  defs.define_constant('OptionParser::MissingArgument::Reason') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::NO_ARGUMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::NeedlessArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::ParseError', RubyLint.registry))

  end

  defs.define_constant('OptionParser::NeedlessArgument::Reason') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::NoArgument') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::OPTIONAL_ARGUMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::OctalInteger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::Officious') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::OptionMap') do |klass|
    klass.inherits(defs.constant_proxy('Hash', RubyLint.registry))
    klass.inherits(defs.constant_proxy('OptionParser::Completion', RubyLint.registry))

  end

  defs.define_constant('OptionParser::OptionMap::Bucket') do |klass|
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

  defs.define_constant('OptionParser::OptionMap::Entries') do |klass|
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

  defs.define_constant('OptionParser::OptionMap::Enumerator') do |klass|
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

  defs.define_constant('OptionParser::OptionMap::Iterator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('state')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next') do |method|
      method.define_argument('item')
    end
  end

  defs.define_constant('OptionParser::OptionMap::MAX_ENTRIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::OptionMap::MIN_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::OptionMap::SortedElement') do |klass|
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

  defs.define_constant('OptionParser::OptionMap::State') do |klass|
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

  defs.define_constant('OptionParser::OptionalArgument') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::ParseError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

    klass.define_method('filter_backtrace') do |method|
      method.define_argument('array')
    end

    klass.define_instance_method('args')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('message')

    klass.define_instance_method('reason')

    klass.define_instance_method('reason=')

    klass.define_instance_method('recover') do |method|
      method.define_argument('argv')
    end

    klass.define_instance_method('set_backtrace') do |method|
      method.define_argument('array')
    end

    klass.define_instance_method('set_option') do |method|
      method.define_argument('opt')
      method.define_argument('eq')
    end

    klass.define_instance_method('to_s')
  end

  defs.define_constant('OptionParser::ParseError::Reason') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::RCSID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::REQUIRED_ARGUMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::Release') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::RequiredArgument') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::SPLAT_PROC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OptionParser::Switch') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('guess') do |method|
      method.define_argument('arg')
    end

    klass.define_method('incompatible_argument_styles') do |method|
      method.define_argument('arg')
      method.define_argument('t')
    end

    klass.define_method('pattern')

    klass.define_instance_method('add_banner') do |method|
      method.define_argument('to')
    end

    klass.define_instance_method('arg')

    klass.define_instance_method('block')

    klass.define_instance_method('compsys') do |method|
      method.define_argument('sdone')
      method.define_argument('ldone')
    end

    klass.define_instance_method('conv')

    klass.define_instance_method('desc')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('pattern')
      method.define_optional_argument('conv')
      method.define_optional_argument('short')
      method.define_optional_argument('long')
      method.define_optional_argument('arg')
      method.define_optional_argument('desc')
      method.define_optional_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('long')

    klass.define_instance_method('match_nonswitch?') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('pattern')

    klass.define_instance_method('short')

    klass.define_instance_method('summarize') do |method|
      method.define_optional_argument('sdone')
      method.define_optional_argument('ldone')
      method.define_optional_argument('width')
      method.define_optional_argument('max')
      method.define_optional_argument('indent')
    end

    klass.define_instance_method('switch_name')
  end

  defs.define_constant('OptionParser::Switch::NoArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::Switch', RubyLint.registry))

    klass.define_method('incompatible_argument_styles') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('pattern')

    klass.define_instance_method('parse') do |method|
      method.define_argument('arg')
      method.define_argument('argv')
    end
  end

  defs.define_constant('OptionParser::Switch::OptionalArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::Switch', RubyLint.registry))

    klass.define_instance_method('parse') do |method|
      method.define_argument('arg')
      method.define_argument('argv')
      method.define_block_argument('error')
    end
  end

  defs.define_constant('OptionParser::Switch::OptionalArgument::NoArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::Switch', RubyLint.registry))

    klass.define_method('incompatible_argument_styles') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('pattern')

    klass.define_instance_method('parse') do |method|
      method.define_argument('arg')
      method.define_argument('argv')
    end
  end

  defs.define_constant('OptionParser::Switch::OptionalArgument::PlacedArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::Switch', RubyLint.registry))

    klass.define_instance_method('parse') do |method|
      method.define_argument('arg')
      method.define_argument('argv')
      method.define_block_argument('error')
    end
  end

  defs.define_constant('OptionParser::Switch::OptionalArgument::RequiredArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::Switch', RubyLint.registry))

    klass.define_instance_method('parse') do |method|
      method.define_argument('arg')
      method.define_argument('argv')
    end
  end

  defs.define_constant('OptionParser::Switch::PlacedArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::Switch', RubyLint.registry))

    klass.define_instance_method('parse') do |method|
      method.define_argument('arg')
      method.define_argument('argv')
      method.define_block_argument('error')
    end
  end

  defs.define_constant('OptionParser::Switch::RequiredArgument') do |klass|
    klass.inherits(defs.constant_proxy('OptionParser::Switch', RubyLint.registry))

    klass.define_instance_method('parse') do |method|
      method.define_argument('arg')
      method.define_argument('argv')
    end
  end

  defs.define_constant('OptionParser::Version') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
