# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Regexp') do |defs|
  defs.define_constant('Regexp') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_method('compatible?') do |method|
      method.define_rest_argument('patterns')
    end

    klass.define_method('compile') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('convert') do |method|
      method.define_argument('pattern')
    end

    klass.define_method('escape') do |method|
      method.define_argument('str')
    end

    klass.define_method('last_match') do |method|
      method.define_optional_argument('field')
    end

    klass.define_method('last_match=') do |method|
      method.define_argument('match')
    end

    klass.define_method('propagate_last_match')

    klass.define_method('quote') do |method|
      method.define_argument('str')
    end

    klass.define_method('set_block_last_match')

    klass.define_method('try_convert') do |method|
      method.define_argument('obj')
    end

    klass.define_method('union') do |method|
      method.define_rest_argument('patterns')
    end

    klass.define_method('yaml_new') do |method|
      method.define_argument('klass')
      method.define_argument('tag')
      method.define_argument('val')
    end

    klass.define_method('yaml_tag_subclasses?')

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('=~') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
    end

    klass.define_instance_method('casefold?')

    klass.define_instance_method('encoding')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('fixed_encoding?')

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('opts')
      method.define_optional_argument('lang')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('initialize_copy') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('match') do |method|
      method.define_argument('str')
      method.define_optional_argument('pos')
    end

    klass.define_instance_method('match_all') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('match_from') do |method|
      method.define_argument('str')
      method.define_argument('count')
    end

    klass.define_instance_method('match_start') do |method|
      method.define_argument('str')
      method.define_argument('offset')
    end

    klass.define_instance_method('name_table')

    klass.define_instance_method('named_captures')

    klass.define_instance_method('names')

    klass.define_instance_method('option_to_string') do |method|
      method.define_argument('option')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('search_from') do |method|
      method.define_argument('str')
      method.define_argument('offset')
    end

    klass.define_instance_method('search_region') do |method|
      method.define_argument('str')
      method.define_argument('start')
      method.define_argument('finish')
      method.define_argument('forward')
    end

    klass.define_instance_method('source')

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('~')
  end

  defs.define_constant('Regexp::CAPTURE_GROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::DONT_CAPTURE_GROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::ESCAPE_TABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::EXTENDED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::FIXEDENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::IGNORECASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::KCODE_EUC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::KCODE_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::KCODE_NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::KCODE_SJIS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::KCODE_UTF8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::MULTILINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::NOENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::OPTION_MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::SourceParser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_part!')

    klass.define_instance_method('create_parts')

    klass.define_instance_method('group_part_class')

    klass.define_instance_method('in_group_with_options?')

    klass.define_instance_method('in_lookahead_group?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options_string')

    klass.define_instance_method('parts')

    klass.define_instance_method('parts_string')

    klass.define_instance_method('process_group')

    klass.define_instance_method('process_group_options')

    klass.define_instance_method('process_look_ahead')

    klass.define_instance_method('process_until_group_finished')

    klass.define_instance_method('push_current_character!')

    klass.define_instance_method('push_option!')

    klass.define_instance_method('string')
  end

  defs.define_constant('Regexp::SourceParser::LookAheadGroupPart') do |klass|
    klass.inherits(defs.constant_proxy('Regexp::SourceParser::Part', RubyLint.registry))

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Regexp::SourceParser::LookAheadGroupPart::OPTIONS_MAP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::SourceParser::OptionsGroupPart') do |klass|
    klass.inherits(defs.constant_proxy('Regexp::SourceParser::Part', RubyLint.registry))

    klass.define_instance_method('flatten')

    klass.define_instance_method('push_negated_option!') do |method|
      method.define_argument('identifier')
    end

    klass.define_instance_method('push_option!') do |method|
      method.define_argument('identifier')
    end

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Regexp::SourceParser::OptionsGroupPart::OPTIONS_MAP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::SourceParser::Part') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('flatten')

    klass.define_instance_method('has_options!')

    klass.define_instance_method('has_options?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('source')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('source')

    klass.define_instance_method('source=')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Regexp::SourceParser::Part::OPTIONS_MAP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Regexp::SourceParser::PossibleOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
