# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Readline') do |defs|
  defs.define_constant('Readline') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('basic_quote_characters')

    klass.define_method('basic_quote_characters=')

    klass.define_method('basic_word_break_characters')

    klass.define_method('basic_word_break_characters=')

    klass.define_method('completer_quote_characters')

    klass.define_method('completer_quote_characters=')

    klass.define_method('completer_word_break_characters')

    klass.define_method('completer_word_break_characters=')

    klass.define_method('completion_append_character')

    klass.define_method('completion_append_character=')

    klass.define_method('completion_case_fold')

    klass.define_method('completion_case_fold=')

    klass.define_method('completion_proc')

    klass.define_method('completion_proc=')

    klass.define_method('emacs_editing_mode')

    klass.define_method('emacs_editing_mode?')

    klass.define_method('filename_quote_characters')

    klass.define_method('filename_quote_characters=')

    klass.define_method('get_screen_size')

    klass.define_method('input=')

    klass.define_method('line_buffer')

    klass.define_method('output=')

    klass.define_method('perform_readline')

    klass.define_method('point')

    klass.define_method('readline') do |method|
      method.define_optional_argument('prompt')
      method.define_optional_argument('add_hist')
    end

    klass.define_method('refresh_line')

    klass.define_method('set_screen_size')

    klass.define_method('vi_editing_mode')

    klass.define_method('vi_editing_mode?')

    klass.define_instance_method('readline') do |method|
      method.define_optional_argument('prompt')
      method.define_optional_argument('add_hist')
    end
  end

  defs.define_constant('Readline::FILENAME_COMPLETION_PROC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('call')
  end

  defs.define_constant('Readline::HISTORY') do |klass|
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

  defs.define_constant('Readline::USERNAME_COMPLETION_PROC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('call')
  end

  defs.define_constant('Readline::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
