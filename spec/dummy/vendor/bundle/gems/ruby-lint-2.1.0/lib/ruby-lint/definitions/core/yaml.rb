# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('YAML') do |defs|
  defs.define_constant('YAML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_builtin_type') do |method|
      method.define_argument('type_tag')
      method.define_block_argument('transfer_proc')
    end

    klass.define_method('add_domain_type') do |method|
      method.define_argument('domain')
      method.define_argument('type_tag')
      method.define_block_argument('transfer_proc')
    end

    klass.define_method('add_private_type') do |method|
      method.define_argument('type_re')
      method.define_block_argument('transfer_proc')
    end

    klass.define_method('add_ruby_type') do |method|
      method.define_argument('type_tag')
      method.define_block_argument('transfer_proc')
    end

    klass.define_method('compile')

    klass.define_method('detect_implicit') do |method|
      method.define_argument('val')
    end

    klass.define_method('dump') do |method|
      method.define_argument('obj')
      method.define_optional_argument('io')
    end

    klass.define_method('dump_stream') do |method|
      method.define_rest_argument('objs')
    end

    klass.define_method('each_document') do |method|
      method.define_argument('io')
      method.define_block_argument('block')
    end

    klass.define_method('each_node') do |method|
      method.define_argument('io')
      method.define_block_argument('doc_proc')
    end

    klass.define_method('emitter')

    klass.define_method('generic_parser')

    klass.define_method('load') do |method|
      method.define_argument('io')
    end

    klass.define_method('load_documents') do |method|
      method.define_argument('io')
      method.define_block_argument('doc_proc')
    end

    klass.define_method('load_file') do |method|
      method.define_argument('filepath')
    end

    klass.define_method('load_stream') do |method|
      method.define_argument('io')
    end

    klass.define_method('merge_i') do |method|
      method.define_argument('ary')
      method.define_argument('hsh')
    end

    klass.define_method('mktime') do |method|
      method.define_argument('str')
    end

    klass.define_method('object_maker') do |method|
      method.define_argument('obj_class')
      method.define_argument('val')
    end

    klass.define_method('parse') do |method|
      method.define_argument('io')
    end

    klass.define_method('parse_documents') do |method|
      method.define_argument('io')
      method.define_block_argument('doc_proc')
    end

    klass.define_method('parse_file') do |method|
      method.define_argument('filepath')
    end

    klass.define_method('parser')

    klass.define_method('quick_emit') do |method|
      method.define_argument('oid')
      method.define_optional_argument('opts')
      method.define_block_argument('e')
    end

    klass.define_method('read_type_class') do |method|
      method.define_argument('type')
      method.define_argument('obj_class')
    end

    klass.define_method('require_date')

    klass.define_method('resolver')

    klass.define_method('set_ivars') do |method|
      method.define_argument('hsh')
      method.define_argument('obj')
    end

    klass.define_method('tag_class') do |method|
      method.define_argument('tag')
      method.define_argument('cls')
    end

    klass.define_method('tagged_classes')

    klass.define_method('tagurize') do |method|
      method.define_argument('val')
    end

    klass.define_method('transfer') do |method|
      method.define_argument('type_id')
      method.define_argument('obj')
    end

    klass.define_method('try_implicit') do |method|
      method.define_argument('obj')
    end
  end
end
