##
# Constant: Module
# Created:  2013-04-01 18:33:54 +0200
# Platform: rbx 2.0.0.rc1
#
RubyLint.registry.register('Module') do |defs|
  defs.define_constant('Module') do |klass|
    klass.inherits(defs.constant_proxy('Kernel', RubyLint.registry))

    klass.define_method('allocate')
    klass.define_method('nesting')

    # Define the various attr_* methods. These methods are defined as private
    # instance methods in Module and thus aren't available to
    # RubyLint::Inspector.
    klass.define_method('attr') do |method|
      method.define_optional_argument('attribute')
      method.define_optional_argument('writer')
    end

    ['attr_reader', 'attr_writer', 'attr_accessor'].each do |name|
      klass.define_method(name) do |method|
        method.define_rest_argument('attributes')
      end
    end

    klass.define_method('define_method') do |method|
      method.define_argument('name')
      method.define_optional_argument('method')

      method.define_block_argument('block')
    end

    klass.define_instance_method('<') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<=') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('inst')
    end

    klass.define_instance_method('>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>=') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('!')

    klass.define_instance_method('!=') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('__class_variables__')

    klass.define_instance_method('__marshal__') do |method|
      method.define_argument('ms')
    end

    klass.define_instance_method('add_ivars') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('ancestors')

    klass.define_instance_method('attr_reader_specific') do |method|
      method.define_argument('name')
      method.define_argument('method_name')
    end

    klass.define_instance_method('autoload') do |method|
      method.define_argument('name')
      method.define_argument('path')
    end

    klass.define_instance_method('autoload?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('class_eval') do |method|
      method.define_optional_argument('string')
      method.define_optional_argument('filename')
      method.define_optional_argument('line')
      method.define_block_argument('prc')
    end

    klass.define_instance_method('class_exec') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('prc')
    end

    klass.define_instance_method('class_variable_defined?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('class_variable_get') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('class_variable_set') do |method|
      method.define_argument('name')
      method.define_argument('val')
    end

    klass.define_instance_method('class_variables')

    klass.define_instance_method('const_defined?') do |method|
      method.define_argument('name')
      method.define_optional_argument('search_parents')
    end

    klass.define_instance_method('const_get') do |method|
      method.define_argument('name')
      method.define_optional_argument('inherit')
    end

    klass.define_instance_method('const_missing') do |method|
      method.define_argument('const_name')
    end

    klass.define_instance_method('const_set') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('constant_table')

    klass.define_instance_method('constants') do |method|
      method.define_optional_argument('all')
    end

    klass.define_instance_method('direct_superclass')

    klass.define_instance_method('dynamic_method') do |method|
      method.define_argument('name')
      method.define_optional_argument('file')
      method.define_optional_argument('line')
    end

    klass.define_instance_method('freeze')

    klass.define_instance_method('include?') do |method|
      method.define_argument('mod')
    end

    klass.define_instance_method('include_into') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('included_modules')

    klass.define_instance_method('initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('instance_method') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('instance_methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_instance_method('lookup_method') do |method|
      method.define_argument('sym')
      method.define_optional_argument('check_object_too')
      method.define_optional_argument('trim_im')
    end

    klass.define_instance_method('method_defined?') do |method|
      method.define_argument('sym')
    end

    klass.define_instance_method('method_table')

    klass.define_instance_method('method_table=')

    klass.define_instance_method('module_eval') do |method|
      method.define_optional_argument('string')
      method.define_optional_argument('filename')
      method.define_optional_argument('line')
      method.define_block_argument('prc')
    end

    klass.define_instance_method('module_exec') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('prc')
    end

    klass.define_instance_method('module_function') do |method|
      method.define_rest_argument('syms')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('private_class_method') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('private_constant') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('private_instance_methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_instance_method('private_method_defined?') do |method|
      method.define_argument('sym')
    end

    klass.define_instance_method('protected_instance_methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_instance_method('protected_method_defined?') do |method|
      method.define_argument('sym')
    end

    klass.define_instance_method('psych_yaml_as') do |method|
      method.define_argument('url')
    end

    klass.define_instance_method('public_class_method') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('public_constant') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('public_instance_methods') do |method|
      method.define_optional_argument('all')
    end

    klass.define_instance_method('public_method_defined?') do |method|
      method.define_argument('sym')
    end

    klass.define_instance_method('rake_extension') do |method|
      method.define_argument('method')
    end

    klass.define_instance_method('rake_original_const_missing') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('remove_class_variable') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('set_class_visibility') do |method|
      method.define_argument('meth')
      method.define_argument('vis')
    end

    klass.define_instance_method('set_visibility') do |method|
      method.define_argument('meth')
      method.define_argument('vis')
      method.define_optional_argument('where')
    end

    klass.define_instance_method('superclass=') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('thunk_method') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('undef_method!') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('yaml_as') do |method|
      method.define_argument('url')
    end

    klass.copy(klass, :instance_method, :method)
  end
end
