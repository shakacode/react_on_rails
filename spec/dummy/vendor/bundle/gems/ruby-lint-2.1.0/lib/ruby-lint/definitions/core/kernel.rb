##
# Constant: Kernel
# Created:  2013-04-01 18:33:54 +0200
# Platform: rbx 2.0.0.rc1
#
RubyLint.registry.register('Kernel') do |defs|
  defs.define_constant('Kernel') do |klass|
    klass.define_method('Array') do |method|
      method.define_argument('obj')
    end

    klass.define_method('Complex') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('Float') do |method|
      method.define_argument('obj')
    end

    klass.define_method('Integer') do |method|
      method.define_argument('obj')
      method.define_optional_argument('base')
    end

    klass.define_method('Rational') do |method|
      method.define_argument('a')
      method.define_optional_argument('b')
    end

    klass.define_method('String') do |method|
      method.define_argument('obj')
    end

    klass.define_method('StringValue') do |method|
      method.define_argument('obj')
    end

    klass.define_method('URI') do |method|
      method.define_argument('uri')
    end

    klass.define_method('__callee__')

    klass.define_method('__method__')

    klass.define_method('__module_init__')

    klass.define_method('`') do |method|
      method.define_argument('str')
    end

    klass.define_method('abort') do |method|
      method.define_optional_argument('msg')
    end

    klass.define_method('at_exit') do |method|
      method.define_optional_argument('prc')
      method.define_block_argument('block')
    end

    # ---

    # These methods aren't actually defined in Kernel (but in Module, at least
    # on MRI) but since they are available as both class and instance methods
    # they have been added to this module (since it's available in both
    # contexts).
    ['alias', 'alias_method'].each do |name|
      klass.define_method(name) do |method|
        method.define_argument('name')
        method.define_argument('original')
      end
    end

    klass.define_method('class_variable_defined?') do |method|
      method.define_argument('sym')
    end

    klass.define_method('class_variable_get') do |method|
      method.define_argument('sym')
    end

    klass.define_method('class_variable_set') do |method|
      method.define_argument('sym')
      method.define_argument('val')
    end

    klass.define_method('const_defined?') do |method|
      method.define_argument('name')
      method.define_optional_argument('search_parents')
    end

    klass.define_method('const_set') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    # ---

    klass.define_method('binding')

    klass.define_method('block_given?')

    klass.define_method('callcc')

    klass.define_method('caller') do |method|
      method.define_optional_argument('start')
      method.define_optional_argument('exclude_kernel')
    end

    klass.define_method('catch') do |method|
      method.define_optional_argument('obj')
      method.define_block_argument('block')
    end

    klass.define_method('chomp') do |method|
      method.define_optional_argument('string')
    end

    klass.define_method('chomp!') do |method|
      method.define_optional_argument('string')
    end

    klass.define_method('chop')

    klass.define_method('chop!')

    klass.define_method('eval') do |method|
      method.define_argument('string')
      method.define_optional_argument('binding')
      method.define_optional_argument('filename')
      method.define_optional_argument('lineno')
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

    klass.define_method('fail') do |method|
      method.define_optional_argument('exc')
      method.define_optional_argument('msg')
      method.define_optional_argument('ctx')
    end

    klass.define_method('fork') do |method|
      method.define_block_argument('block')
    end

    klass.define_method('format') do |method|
      method.define_argument('str')
      method.define_rest_argument('args')
    end

    klass.define_method('getc')

    klass.define_method('gets') do |method|
      method.define_optional_argument('sep')
    end

    klass.define_method('global_variables')

    klass.define_method('gsub') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('rep')
      method.define_block_argument('block')
    end

    klass.define_method('gsub!') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('rep')
      method.define_block_argument('block')
    end

    klass.define_method('iterator?')

    klass.define_method('lambda')

    klass.define_method('load') do |method|
      method.define_argument('name')
      method.define_optional_argument('wrap')
    end

    klass.define_method('local_variables')

    klass.define_method('loop')

    klass.define_method('open') do |method|
      method.define_argument('obj')
      method.define_rest_argument('rest')
      method.define_block_argument('block')
    end

    klass.define_method('p') do |method|
      method.define_rest_argument('a')
    end

    klass.define_method('print') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('printf') do |method|
      method.define_argument('target')
      method.define_rest_argument('args')
    end

    klass.define_method('proc') do |method|
      method.define_block_argument('prc')
    end

    klass.define_method('putc') do |method|
      method.define_argument('int')
    end

    klass.define_method('puts') do |method|
      method.define_rest_argument('a')
    end

    klass.define_method('raise') do |method|
      method.define_optional_argument('exc')
      method.define_optional_argument('msg')
      method.define_optional_argument('ctx')
    end

    klass.define_method('rand') do |method|
      method.define_optional_argument('limit')
    end

    klass.define_method('readline') do |method|
      method.define_optional_argument('sep')
    end

    klass.define_method('readlines') do |method|
      method.define_optional_argument('sep')
    end

    klass.define_method('require') do |method|
      method.define_argument('name')
    end

    klass.define_method('require_relative') do |method|
      method.define_argument('name')
    end

    klass.define_method('scan') do |method|
      method.define_argument('pattern')
      method.define_block_argument('block')
    end

    klass.define_method('select') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('set_trace_func') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('sleep') do |method|
      method.define_optional_argument('duration')
    end

    klass.define_method('spawn') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('split') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('sprintf') do |method|
      method.define_argument('str')
      method.define_rest_argument('args')
    end

    klass.define_method('srand') do |method|
      method.define_optional_argument('seed')
    end

    klass.define_method('sub') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('rep')
      method.define_block_argument('block')
    end

    klass.define_method('sub!') do |method|
      method.define_argument('pattern')
      method.define_optional_argument('rep')
      method.define_block_argument('block')
    end

    klass.define_method('syscall') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('system') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('test') do |method|
      method.define_argument('cmd')
      method.define_argument('file1')
      method.define_optional_argument('file2')
    end

    klass.define_method('throw') do |method|
      method.define_argument('obj')
      method.define_optional_argument('value')
    end

    klass.define_method('trace_var') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('trap') do |method|
      method.define_argument('sig')
      method.define_optional_argument('prc')
      method.define_block_argument('block')
    end

    klass.define_method('untrace_var') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('warn') do |method|
      method.define_argument('warning')
    end

    klass.define_method('warning') do |method|
      method.define_argument('message')
    end

    klass.define_method('!~') do |method|
      method.define_argument('other')
    end

    klass.define_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_method('=~') do |method|
      method.define_argument('other')
    end

    klass.define_method('__class__')

    klass.define_method('__extend__') do |method|
      method.define_rest_argument('modules')
    end

    klass.define_method('__instance_variable_defined_p__') do |method|
      method.define_argument('name')
    end

    klass.define_method('__instance_variable_get__') do |method|
      method.define_argument('sym')
    end

    klass.define_method('__instance_variable_set__') do |method|
      method.define_argument('sym')
      method.define_argument('value')
    end

    klass.define_method('__instance_variables__')

    klass.define_method('__respond_to_p__') do |method|
      method.define_argument('meth')
      method.define_optional_argument('include_private')
    end

    klass.define_method('class')

    klass.define_method('clone')

    klass.define_method('define_singleton_method') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('display') do |method|
      method.define_optional_argument('port')
    end

    klass.define_method('dup')

    klass.define_method('enum_for') do |method|
      method.define_optional_argument('method')
      method.define_rest_argument('args')
    end

    klass.define_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_method('equal?') do |method|
      method.define_argument('other')
    end

    klass.define_method('extend') do |method|
      method.define_rest_argument('modules')
    end

    klass.define_method('freeze')

    klass.define_method('frozen?')

    klass.define_method('hash')

    klass.define_method('include') do |method|
      method.define_rest_argument('mods')
    end

    klass.define_method('initialize_clone') do |method|
      method.define_argument('other')
    end

    klass.define_method('initialize_dup') do |method|
      method.define_argument('other')
    end

    klass.define_method('inspect')

    klass.define_method('instance_of?') do |method|
      method.define_argument('cls')
    end

    klass.define_method('instance_variable_defined?') do |method|
      method.define_argument('name')
    end

    klass.define_method('instance_variable_get') do |method|
      method.define_argument('sym')
    end

    klass.define_method('instance_variable_set') do |method|
      method.define_argument('sym')
      method.define_argument('value')
    end

    klass.define_method('instance_variables')

    klass.define_method('is_a?') do |method|
      method.define_argument('cls')
    end

    klass.define_method('kind_of?') do |method|
      method.define_argument('cls')
    end

    klass.define_method('method') do |method|
      method.define_argument('name')
    end

    klass.define_method('methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_method('nil?')

    klass.define_method('object_id')

    klass.define_method('private') do |method|
      method.define_rest_argument('methods')
    end

    klass.define_method('public') do |method|
      method.define_rest_argument('methods')
    end

    klass.define_method('protected') do |method|
      method.define_rest_argument('methods')
    end

    klass.define_method('private_methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_method('protected_methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_method('public_method') do |method|
      method.define_argument('name')
    end

    klass.define_method('public_methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_method('public_send') do |method|
      method.define_argument('message')
      method.define_rest_argument('args')
    end

    klass.define_method('respond_to?') do |method|
      method.define_argument('meth')
      method.define_optional_argument('include_private')
    end

    klass.define_method('respond_to_missing?') do |method|
      method.define_argument('meth')
      method.define_argument('include')
    end

    klass.define_method('send') do |method|
      method.define_argument('message')
      method.define_rest_argument('args')
    end

    klass.define_method('singleton_class')

    klass.define_method('singleton_methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_method('taint')

    klass.define_method('tainted?')

    klass.define_method('tap')

    klass.define_method('to_enum') do |method|
      method.define_optional_argument('method')
      method.define_rest_argument('args')
    end

    klass.define_method('to_s')

    klass.define_method('trust')

    klass.define_method('untaint')

    klass.define_method('untrust')

    klass.define_method('untrusted?')

    # Methods defined in Kernel (both class and instance methods) are globally
    # available regardless of whether the code is evaluated in a class or
    # instance context.
    klass.copy(klass, :method, :instance_method)
  end
end
