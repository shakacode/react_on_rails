# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: ruby 1.9.3

RubyLint.registry.register('LibXML') do |defs|
  defs.define_constant('LibXML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('catalog_dump')

    klass.define_method('catalog_remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('check_lib_versions')

    klass.define_method('debug_entities')

    klass.define_method('debug_entities=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('default_compression')

    klass.define_method('default_compression=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('default_keep_blanks')

    klass.define_method('default_keep_blanks=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('default_line_numbers')

    klass.define_method('default_line_numbers=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('default_load_external_dtd')

    klass.define_method('default_load_external_dtd=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('default_options')

    klass.define_method('default_pedantic_parser')

    klass.define_method('default_pedantic_parser=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('default_substitute_entities')

    klass.define_method('default_substitute_entities=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('default_tree_indent_string')

    klass.define_method('default_tree_indent_string=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('default_validity_checking')

    klass.define_method('default_validity_checking=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('default_warnings')

    klass.define_method('default_warnings=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('enabled_automata?')

    klass.define_method('enabled_c14n?')

    klass.define_method('enabled_catalog?')

    klass.define_method('enabled_debug?')

    klass.define_method('enabled_docbook?')

    klass.define_method('enabled_ftp?')

    klass.define_method('enabled_html?')

    klass.define_method('enabled_http?')

    klass.define_method('enabled_iconv?')

    klass.define_method('enabled_memory_debug?')

    klass.define_method('enabled_regexp?')

    klass.define_method('enabled_schemas?')

    klass.define_method('enabled_thread?')

    klass.define_method('enabled_unicode?')

    klass.define_method('enabled_xinclude?')

    klass.define_method('enabled_xpath?')

    klass.define_method('enabled_xpointer?')

    klass.define_method('enabled_zlib?')

    klass.define_method('features')

    klass.define_method('indent_tree_output')

    klass.define_method('indent_tree_output=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('memory_dump')

    klass.define_method('memory_used')
  end

  defs.define_constant('LibXML::XML::Attr') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('child')

    klass.define_instance_method('child?')

    klass.define_instance_method('doc')

    klass.define_instance_method('doc?')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('each_attr') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('each_sibling') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('last')

    klass.define_instance_method('last?')

    klass.define_instance_method('name')

    klass.define_instance_method('namespaces')

    klass.define_instance_method('next')

    klass.define_instance_method('next?')

    klass.define_instance_method('node_type')

    klass.define_instance_method('node_type_name')

    klass.define_instance_method('ns')

    klass.define_instance_method('ns?')

    klass.define_instance_method('parent')

    klass.define_instance_method('parent?')

    klass.define_instance_method('prev')

    klass.define_instance_method('prev?')

    klass.define_instance_method('remove!')

    klass.define_instance_method('siblings') do |method|
      method.define_argument('node')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_h')

    klass.define_instance_method('to_s')

    klass.define_instance_method('value')

    klass.define_instance_method('value=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('LibXML::XML::AttrDecl') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('child')

    klass.define_instance_method('child?')

    klass.define_instance_method('doc')

    klass.define_instance_method('doc?')

    klass.define_instance_method('name')

    klass.define_instance_method('next')

    klass.define_instance_method('next?')

    klass.define_instance_method('node_type')

    klass.define_instance_method('node_type_name')

    klass.define_instance_method('parent')

    klass.define_instance_method('parent?')

    klass.define_instance_method('prev')

    klass.define_instance_method('prev?')

    klass.define_instance_method('to_s')

    klass.define_instance_method('value')
  end

  defs.define_constant('LibXML::XML::Attributes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('first')

    klass.define_instance_method('get_attribute') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_attribute_ns') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('length')

    klass.define_instance_method('node')

    klass.define_instance_method('to_h')
  end

  defs.define_constant('LibXML::XML::Document') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('document') do |method|
      method.define_argument('value')
    end

    klass.define_method('file') do |method|
      method.define_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_method('io') do |method|
      method.define_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_method('string') do |method|
      method.define_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('canonicalize') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('child')

    klass.define_instance_method('child?')

    klass.define_instance_method('compression')

    klass.define_instance_method('compression=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('compression?')

    klass.define_instance_method('context') do |method|
      method.define_optional_argument('nslist')
    end

    klass.define_instance_method('debug')

    klass.define_instance_method('debug_dump')

    klass.define_instance_method('debug_dump_head')

    klass.define_instance_method('debug_format_dump')

    klass.define_instance_method('docbook_doc?')

    klass.define_instance_method('document?')

    klass.define_instance_method('dump')

    klass.define_instance_method('encoding')

    klass.define_instance_method('encoding=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('find') do |method|
      method.define_argument('xpath')
      method.define_optional_argument('nslist')
    end

    klass.define_instance_method('find_first') do |method|
      method.define_argument('xpath')
      method.define_optional_argument('nslist')
    end

    klass.define_instance_method('format_dump')

    klass.define_instance_method('html_doc?')

    klass.define_instance_method('import') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('last')

    klass.define_instance_method('last?')

    klass.define_instance_method('next')

    klass.define_instance_method('next?')

    klass.define_instance_method('node_type')

    klass.define_instance_method('node_type_name')

    klass.define_instance_method('order_elements!')

    klass.define_instance_method('parent')

    klass.define_instance_method('parent?')

    klass.define_instance_method('prev')

    klass.define_instance_method('prev?')

    klass.define_instance_method('rb_encoding')

    klass.define_instance_method('reader')

    klass.define_instance_method('root')

    klass.define_instance_method('root=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('save') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('standalone?')

    klass.define_instance_method('to_s') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('url')

    klass.define_instance_method('validate') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('validate_relaxng') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('validate_schema') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('version')

    klass.define_instance_method('xhtml?')

    klass.define_instance_method('xinclude')
  end

  defs.define_constant('LibXML::XML::Document::XML_C14N_1_0') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Document::XML_C14N_1_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Document::XML_C14N_EXCLUSIVE_1_0') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Dtd') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('external_id')

    klass.define_instance_method('name')

    klass.define_instance_method('node_type')

    klass.define_instance_method('system_id')

    klass.define_instance_method('uri')
  end

  defs.define_constant('LibXML::XML::Encoding') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from_s') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('to_s') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('LibXML::XML::Encoding::ASCII') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::EBCDIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::EUC_JP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ISO_2022_JP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ISO_8859_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ISO_8859_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ISO_8859_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ISO_8859_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ISO_8859_5') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ISO_8859_6') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ISO_8859_7') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ISO_8859_8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::ISO_8859_9') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::SHIFT_JIS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::UCS_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::UCS_4BE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::UCS_4LE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::UCS_4_2143') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::UCS_4_3412') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::UTF_16BE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::UTF_16LE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Encoding::UTF_8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_method('get_handler')

    klass.define_method('reset_handler')

    klass.define_method('set_handler')

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('code')

    klass.define_instance_method('code_to_s')

    klass.define_instance_method('ctxt')

    klass.define_instance_method('domain')

    klass.define_instance_method('domain_to_s')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('file')

    klass.define_instance_method('int1')

    klass.define_instance_method('int2')

    klass.define_instance_method('level')

    klass.define_instance_method('level_to_s')

    klass.define_instance_method('line')

    klass.define_instance_method('node')

    klass.define_instance_method('str1')

    klass.define_instance_method('str2')

    klass.define_instance_method('str3')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('LibXML::XML::Error::ATTLIST_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ATTLIST_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ATTRIBUTE_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ATTRIBUTE_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ATTRIBUTE_REDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ATTRIBUTE_WITHOUT_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::C14N') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::C14N_CREATE_CTXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::C14N_CREATE_STACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::C14N_INVALID_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::C14N_RELATIVE_NAMESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::C14N_REQUIRES_UTF8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::C14N_UNKNOW_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CATALOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CATALOG_ENTRY_BROKEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CATALOG_MISSING_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CATALOG_NOT_CATALOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CATALOG_PREFER_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CATALOG_RECURSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CDATA_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHARREF_AT_EOF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHARREF_IN_DTD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHARREF_IN_EPILOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHARREF_IN_PROLOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_ENTITY_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_CDATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_COMMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_DOCTYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_ELEMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_ENTITYREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_FRAGMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_NOTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_PI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_FOUND_TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NAME_NOT_NULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NOT_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NOT_ATTR_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NOT_DTD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NOT_ELEM_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NOT_ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NOT_NCNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NOT_NS_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NOT_UTF8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NO_DICT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NO_DOC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NO_ELEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NO_HREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NO_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NO_NEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NO_PARENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NO_PREV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NS_ANCESTOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_NS_SCOPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_OUTSIDE_DICT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_UNKNOWN_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_WRONG_DOC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_WRONG_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_WRONG_NEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_WRONG_PARENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CHECK_WRONG_PREV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::COMMENT_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CONDSEC_INVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CONDSEC_INVALID_KEYWORD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CONDSEC_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::CONDSEC_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DATATYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DOCTYPE_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DOCUMENT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DOCUMENT_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DOCUMENT_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DOMAIN_CODE_MAP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ATTRIBUTE_DEFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ATTRIBUTE_REDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ATTRIBUTE_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_CONTENT_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_CONTENT_MODEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_CONTENT_NOT_DETERMINIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_DIFFERENT_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ELEM_DEFAULT_NAMESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ELEM_NAMESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ELEM_REDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_EMPTY_NOTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ENTITY_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ID_FIXED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ID_REDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ID_SUBSET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_INVALID_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_INVALID_DEFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_LOAD_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_MISSING_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_MIXED_CORRUPT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_MULTIPLE_ID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_NOTATION_REDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_NOTATION_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_NOT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_NOT_PCDATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_NOT_STANDALONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_NO_DOC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_NO_DTD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_NO_ELEM_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_NO_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_NO_ROOT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_ROOT_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_STANDALONE_DEFAULTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_STANDALONE_WHITE_SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_UNKNOWN_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_UNKNOWN_ELEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_UNKNOWN_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_UNKNOWN_ID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_UNKNOWN_NOTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_XMLID_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::DTD_XMLID_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ELEMCONTENT_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ELEMCONTENT_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENCODING_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITYREF_AT_EOF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITYREF_IN_DTD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITYREF_IN_EPILOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITYREF_IN_PROLOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITYREF_NO_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITYREF_SEMICOL_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITY_BOUNDARY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITY_CHAR_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITY_IS_EXTERNAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITY_IS_PARAMETER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITY_LOOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITY_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITY_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITY_PE_INTERNAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ENTITY_PROCESSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::EQUAL_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::ERROR_CODE_MAP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::EXTRA_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::EXT_ENTITY_STANDALONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::EXT_SUBSET_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::FATAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::FTP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::FTP_ACCNT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::FTP_EPSV_ANSWER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::FTP_PASV_ANSWER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::FTP_URL_SYNTAX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::GT_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::HTML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::HTML_STRUCURE_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::HTML_UNKNOWN_TAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::HTTP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::HTTP_UNKNOWN_HOST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::HTTP_URL_SYNTAX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::HTTP_USE_IP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::HYPHEN_IN_COMMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::I18N') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::I18N_CONV_FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::I18N_EXCESS_HANDLER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::I18N_NO_HANDLER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::I18N_NO_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::I18N_NO_OUTPUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::INTERNAL_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::INVALID_CHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::INVALID_CHARREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::INVALID_DEC_CHARREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::INVALID_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::INVALID_HEX_CHARREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::INVALID_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_BUFFER_FULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EACCES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EADDRINUSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EAFNOSUPPORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EAGAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EALREADY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EBADF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EBADMSG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EBUSY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ECANCELED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ECHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ECONNREFUSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EDEADLK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EDOM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EEXIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EFBIG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EINPROGRESS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EINTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EINVAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EIO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EISCONN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EISDIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EMFILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EMLINK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EMSGSIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENAMETOOLONG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENCODER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENETUNREACH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENFILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENODEV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOEXEC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOLCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOMEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOSPC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOSYS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOTDIR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOTEMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOTSOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOTSUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENOTTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ENXIO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EPERM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EPIPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ERANGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EROFS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ESPIPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ESRCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_ETIMEDOUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_EXDEV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_FLUSH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_LOAD_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_NETWORK_ATTEMPT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_NO_INPUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::IO_WRITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::LITERAL_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::LITERAL_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::LTSLASH_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::LT_IN_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::LT_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::MEMORY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::MISPLACED_CDATA_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::MISSING_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::MIXED_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::MIXED_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::MODULE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::MODULE_CLOSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::MODULE_OPEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NAMESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NAME_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NMTOKEN_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NOTATION_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NOTATION_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NOTATION_PROCESSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NOT_STANDALONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NOT_WELL_BALANCED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NO_DTD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NO_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NO_MEMORY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NS_DECL_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NS_ERR_ATTRIBUTE_REDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NS_ERR_COLON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NS_ERR_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NS_ERR_QNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NS_ERR_UNDEFINED_NAMESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::NS_ERR_XML_NAMESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::OUTPUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PARSER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PCDATA_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PEREF_AT_EOF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PEREF_IN_EPILOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PEREF_IN_INT_SUBSET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PEREF_IN_PROLOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PEREF_NO_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PEREF_SEMICOL_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PI_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PI_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::PUBID_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::QUIET_HANDLER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::REGEXP_COMPILE_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RELAXNGP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RELAXNGV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RESERVED_XML_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ANYNAME_ATTR_ANCESTOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ATTRIBUTE_CHILDREN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ATTRIBUTE_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ATTRIBUTE_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ATTRIBUTE_NOOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ATTR_CONFLICT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_CHOICE_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_CHOICE_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_CREATE_FAILURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_DATA_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_DEFINE_CREATE_FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_DEFINE_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_DEFINE_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_DEFINE_NAME_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_DEF_CHOICE_AND_INTERLEAVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ELEMENT_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ELEMENT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ELEMENT_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ELEMENT_NO_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ELEM_CONTENT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ELEM_CONTENT_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ELEM_TEXT_CONFLICT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EMPTY_CONSTRUCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EMPTY_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EMPTY_NOT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_ERROR_TYPE_LIB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EXCEPT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EXCEPT_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EXCEPT_MULTIPLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EXCEPT_NO_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EXTERNALREF_EMTPY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EXTERNALREF_RECURSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_EXTERNAL_REF_FAILURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_FORBIDDEN_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_FOREIGN_ELEMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_GRAMMAR_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_GRAMMAR_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_GRAMMAR_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_GRAMMAR_NO_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_GROUP_ATTR_CONFLICT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_HREF_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_INCLUDE_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_INCLUDE_FAILURE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_INCLUDE_RECURSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_INTERLEAVE_ADD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_INTERLEAVE_CREATE_FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_INTERLEAVE_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_INTERLEAVE_NO_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_INVALID_DEFINE_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_INVALID_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_INVALID_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_MISSING_HREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_NAME_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_NEED_COMBINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_NOTALLOWED_NOT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_NSNAME_ATTR_ANCESTOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_NSNAME_NO_NS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PARAM_FORBIDDEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PARAM_NAME_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PARENTREF_CREATE_FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PARENTREF_NAME_INVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PARENTREF_NOT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PARENTREF_NO_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PARENTREF_NO_PARENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PARSE_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_ANYNAME_EXCEPT_ANYNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_ATTR_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_ATTR_ELEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_DATA_EXCEPT_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_DATA_EXCEPT_ELEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_DATA_EXCEPT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_DATA_EXCEPT_GROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_DATA_EXCEPT_INTERLEAVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_DATA_EXCEPT_LIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_DATA_EXCEPT_ONEMORE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_DATA_EXCEPT_REF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_DATA_EXCEPT_TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_LIST_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_LIST_ELEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_LIST_INTERLEAVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_LIST_LIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_LIST_REF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_LIST_TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_NSNAME_EXCEPT_ANYNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_NSNAME_EXCEPT_NSNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_ONEMORE_GROUP_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_ONEMORE_INTERLEAVE_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_START_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_START_DATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_START_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_START_GROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_START_INTERLEAVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_START_LIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_START_ONEMORE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_START_TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PAT_START_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_PREFIX_UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_REF_CREATE_FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_REF_CYCLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_REF_NAME_INVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_REF_NOT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_REF_NO_DEF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_REF_NO_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_START_CHOICE_AND_INTERLEAVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_START_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_START_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_START_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_TEXT_EXPECTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_TEXT_HAS_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_TYPE_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_TYPE_NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_TYPE_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_UNKNOWN_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_UNKNOWN_COMBINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_UNKNOWN_CONSTRUCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_UNKNOWN_TYPE_LIB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_URI_FRAGMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_URI_NOT_ABSOLUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_VALUE_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_VALUE_NO_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_XMLNS_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::RNGP_XML_NS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SAVE_CHAR_INVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SAVE_NOT_UTF8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SAVE_NO_DOCTYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SAVE_UNKNOWN_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_AG_PROPS_CORRECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_ATTRFORMDEFAULT_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_ATTRGRP_NONAME_NOREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_ATTR_NONAME_NOREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_AU_PROPS_CORRECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_AU_PROPS_CORRECT_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_A_PROPS_CORRECT_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_A_PROPS_CORRECT_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COMPLEXTYPE_NONAME_NOREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ALL_LIMITED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_CT_EXTENDS_1_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_CT_EXTENDS_1_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_CT_EXTENDS_1_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_DERIVED_OK_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_DERIVED_OK_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_1_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_1_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_1_3_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_1_3_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_2_3_1_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_2_3_1_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_2_3_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_2_3_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_2_3_2_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_2_3_2_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_2_3_2_5') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_3_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_3_3_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_3_3_1_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_3_3_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_3_3_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_3_3_2_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_3_3_2_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_ST_RESTRICTS_3_3_2_5') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_VALID_DEFAULT_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_VALID_DEFAULT_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_VALID_DEFAULT_2_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_COS_VALID_DEFAULT_2_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_CT_PROPS_CORRECT_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_CT_PROPS_CORRECT_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_CT_PROPS_CORRECT_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_CT_PROPS_CORRECT_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_CT_PROPS_CORRECT_5') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_CVC_SIMPLE_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_C_PROPS_CORRECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_DEF_AND_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_DERIVATION_OK_RESTRICTION_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_DERIVATION_OK_RESTRICTION_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_DERIVATION_OK_RESTRICTION_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_DERIVATION_OK_RESTRICTION_4_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_DERIVATION_OK_RESTRICTION_4_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_DERIVATION_OK_RESTRICTION_4_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_ELEMFORMDEFAULT_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_ELEM_DEFAULT_FIXED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_ELEM_NONAME_NOREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_EXTENSION_NO_BASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_E_PROPS_CORRECT_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_E_PROPS_CORRECT_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_E_PROPS_CORRECT_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_E_PROPS_CORRECT_5') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_E_PROPS_CORRECT_6') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_FACET_NO_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_FAILED_BUILD_IMPORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_FAILED_LOAD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_FAILED_PARSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_GROUP_NONAME_NOREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_IMPORT_NAMESPACE_NOT_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_IMPORT_REDEFINE_NSNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_IMPORT_SCHEMA_NOT_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INCLUDE_SCHEMA_NOT_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INCLUDE_SCHEMA_NO_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INTERNAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INTERSECTION_NOT_EXPRESSIBLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_ATTR_COMBINATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_ATTR_INLINE_COMBINATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_ATTR_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_ATTR_USE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_BOOLEAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_ENUM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_FACET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_FACET_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_MAXOCCURS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_MINOCCURS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_REF_AND_SUBTYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_INVALID_WHITE_SPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_MG_PROPS_CORRECT_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_MG_PROPS_CORRECT_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_MISSING_SIMPLETYPE_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_NOATTR_NOREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_NOROOT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_NOTATION_NO_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_NOTHING_TO_PARSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_NOTYPE_NOREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_NOT_DETERMINISTIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_NOT_SCHEMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_NO_XMLNS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_NO_XSI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_PREFIX_UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_P_PROPS_CORRECT_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_P_PROPS_CORRECT_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_P_PROPS_CORRECT_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_RECURSIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_REDEFINED_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_REDEFINED_ATTRGROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_REDEFINED_ELEMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_REDEFINED_GROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_REDEFINED_NOTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_REDEFINED_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_REF_AND_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_REF_AND_SUBTYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_REGEXP_INVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_RESTRICTION_NONAME_NOREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_S4S_ATTR_INVALID_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_S4S_ATTR_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_S4S_ATTR_NOT_ALLOWED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_S4S_ELEM_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_S4S_ELEM_NOT_ALLOWED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SIMPLETYPE_NONAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ATTRIBUTE_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ATTRIBUTE_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ATTRIBUTE_3_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ATTRIBUTE_3_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ATTRIBUTE_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ATTRIBUTE_GROUP_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ATTRIBUTE_GROUP_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ATTRIBUTE_GROUP_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_CT_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ELEMENT_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ELEMENT_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ELEMENT_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_ELEMENT_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_IMPORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_IMPORT_1_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_IMPORT_1_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_IMPORT_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_IMPORT_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_IMPORT_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_IMPORT_3_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_IMPORT_3_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_INCLUDE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_LIST_ITEMTYPE_OR_SIMPLETYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_REDEFINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_RESOLVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_RESTRICTION_BASE_OR_SIMPLETYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_SIMPLE_TYPE_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_SIMPLE_TYPE_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_SIMPLE_TYPE_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_SIMPLE_TYPE_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SRC_UNION_MEMBERTYPES_OR_SIMPLETYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_ST_PROPS_CORRECT_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_ST_PROPS_CORRECT_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_ST_PROPS_CORRECT_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_SUPERNUMEROUS_LIST_ITEM_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_TYPE_AND_SUBTYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNION_NOT_EXPRESSIBLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_ALL_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_ANYATTRIBUTE_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_ATTRGRP_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_ATTRIBUTE_GROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_ATTR_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_BASE_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_CHOICE_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_COMPLEXCONTENT_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_COMPLEXTYPE_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_ELEM_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_EXTENSION_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_FACET_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_FACET_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_GROUP_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_IMPORT_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_INCLUDE_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_LIST_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_MEMBER_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_NOTATION_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_PREFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_PROCESSCONTENT_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_REF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_RESTRICTION_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_SCHEMAS_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_SEQUENCE_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_SIMPLECONTENT_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_SIMPLETYPE_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_UNKNOWN_UNION_CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_WARN_ATTR_POINTLESS_PROH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_WARN_ATTR_REDECL_PROH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_WARN_SKIP_SCHEMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_WARN_UNLOCATED_SCHEMA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAP_WILDCARD_INVALID_NS_MEMBER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMASP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMASV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMATRONV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMATRONV_ASSERT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMATRONV_REPORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_ATTRINVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_ATTRUNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CONSTRUCT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ATTRIBUTE_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ATTRIBUTE_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ATTRIBUTE_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ATTRIBUTE_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_AU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_2_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_2_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_3_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_3_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_3_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_5_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_COMPLEX_TYPE_5_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_DATATYPE_VALID_1_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_DATATYPE_VALID_1_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_DATATYPE_VALID_1_2_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_3_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_3_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_3_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_4_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_4_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_4_3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_5_1_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_5_1_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_5_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_5_2_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_5_2_2_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_5_2_2_2_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_6') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ELT_7') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_ENUMERATION_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_FACET_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_FRACTIONDIGITS_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_IDC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_LENGTH_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_MAXEXCLUSIVE_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_MAXINCLUSIVE_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_MAXLENGTH_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_MINEXCLUSIVE_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_MININCLUSIVE_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_MINLENGTH_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_PATTERN_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_TOTALDIGITS_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_TYPE_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_TYPE_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_TYPE_3_1_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_TYPE_3_1_2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_CVC_WILDCARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_DOCUMENT_ELEMENT_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_ELEMCONT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_ELEMENT_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_EXTRACONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_FACET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_HAVEDEFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_INTERNAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_INVALIDATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_INVALIDELEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_ISABSTRACT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_MISC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_NOROLLBACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_NOROOT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_NOTDETERMINIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_NOTEMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_NOTNILLABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_NOTSIMPLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_NOTTOPLEVEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_NOTYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_UNDECLAREDELEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SCHEMAV_WRONGELEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SEPARATOR_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::SPACE_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::STANDALONE_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::STRING_NOT_CLOSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::STRING_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::TAG_NAME_MISMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::TAG_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::TREE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::TREE_INVALID_DEC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::TREE_INVALID_HEX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::TREE_NOT_UTF8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::TREE_UNTERMINATED_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::UNDECLARED_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::UNKNOWN_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::UNPARSED_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::UNSUPPORTED_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::URI_FRAGMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::URI_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::VALUE_REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::VERBOSE_HANDLER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::VERSION_MISSING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::WARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::WAR_ENTITY_REDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::WAR_NS_COLUMN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::WRITER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_BUILD_FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_DEPRECATED_NS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_ENTITY_DEF_MISMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_FALLBACKS_IN_INCLUDE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_FALLBACK_NOT_IN_INCLUDE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_FRAGMENT_ID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_HREF_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_INCLUDE_IN_INCLUDE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_INVALID_CHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_MULTIPLE_ROOT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_NO_FALLBACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_NO_HREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_PARSE_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_RECURSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_TEXT_DOCUMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_TEXT_FRAGMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_UNKNOWN_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_XPTR_FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XINCLUDE_XPTR_RESULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XMLDECL_NOT_FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XMLDECL_NOT_STARTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XML_WAR_CATALOG_PI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XML_WAR_LANG_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XML_WAR_NS_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XML_WAR_NS_URI_RELATIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XML_WAR_SPACE_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XML_WAR_UNDECLARED_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XML_WAR_UNKNOWN_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_ENCODING_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_EXPRESSION_OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_EXPR_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_INVALID_ARITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_INVALID_CHAR_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_INVALID_CTXT_POSITION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_INVALID_CTXT_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_INVALID_OPERAND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_INVALID_PREDICATE_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_INVALID_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_MEMORY_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_NUMBER_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_START_LITERAL_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_UNCLOSED_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_UNDEF_PREFIX_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_UNDEF_VARIABLE_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_UNFINISHED_LITERAL_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_UNKNOWN_FUNC_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPATH_VARIABLE_REF_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPOINTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPTR_CHILDSEQ_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPTR_EVAL_FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPTR_EXTRA_OBJECTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPTR_RESOURCE_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPTR_SUB_RESOURCE_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPTR_SYNTAX_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XPTR_UNKNOWN_SCHEME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Error::XSLT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::HTMLParser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('file') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_method('io') do |method|
      method.define_argument('io')
      method.define_optional_argument('options')
    end

    klass.define_method('string') do |method|
      method.define_argument('string')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('file=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('input')

    klass.define_instance_method('io=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('parse')

    klass.define_instance_method('string=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('LibXML::XML::HTMLParser::Context') do |klass|
    klass.inherits(defs.constant_proxy('LibXML::XML::Parser::Context', RubyLint.registry))

    klass.define_method('file') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('io') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('string') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('disable_cdata=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('options=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('LibXML::XML::HTMLParser::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::HTMLParser::Options::COMPACT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::HTMLParser::Options::NOBLANKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::HTMLParser::Options::NODEFDTD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::HTMLParser::Options::NOERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::HTMLParser::Options::NOIMPLIED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::HTMLParser::Options::NONET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::HTMLParser::Options::NOWARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::HTMLParser::Options::PEDANTIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::HTMLParser::Options::RECOVER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::InputCallbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_scheme') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('register')

    klass.define_method('remove_scheme') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('LibXML::XML::LIBXML_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::NS') do |klass|
    klass.inherits(defs.constant_proxy('LibXML::XML::Namespace', RubyLint.registry))

    klass.define_instance_method('href?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('node')
      method.define_argument('prefix')
      method.define_argument('href')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('prefix?')
  end

  defs.define_constant('LibXML::XML::Namespace') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('href')

    klass.define_instance_method('next')

    klass.define_instance_method('node_type')

    klass.define_instance_method('prefix')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('LibXML::XML::Namespaces') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('default')

    klass.define_instance_method('default_prefix=') do |method|
      method.define_argument('prefix')
    end

    klass.define_instance_method('definitions')

    klass.define_instance_method('each')

    klass.define_instance_method('find_by_href') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('find_by_prefix') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('namespace')

    klass.define_instance_method('namespace=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('node')
  end

  defs.define_constant('LibXML::XML::Node') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('new_cdata') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('new_comment') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('new_pi') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('new_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('attribute?')

    klass.define_instance_method('attribute_decl?')

    klass.define_instance_method('attributes')

    klass.define_instance_method('attributes?')

    klass.define_instance_method('base')

    klass.define_instance_method('base=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('base_uri')

    klass.define_instance_method('base_uri=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('blank?')

    klass.define_instance_method('cdata?')

    klass.define_instance_method('child')

    klass.define_instance_method('child=') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('child?')

    klass.define_instance_method('child_add') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('children')

    klass.define_instance_method('children?')

    klass.define_instance_method('clone')

    klass.define_instance_method('comment?')

    klass.define_instance_method('content')

    klass.define_instance_method('content=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('content_stripped')

    klass.define_instance_method('context') do |method|
      method.define_optional_argument('nslist')
    end

    klass.define_instance_method('copy') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('debug')

    klass.define_instance_method('doc')

    klass.define_instance_method('docbook_doc?')

    klass.define_instance_method('doctype?')

    klass.define_instance_method('document?')

    klass.define_instance_method('dtd?')

    klass.define_instance_method('dump')

    klass.define_instance_method('dup')

    klass.define_instance_method('each')

    klass.define_instance_method('each_attr')

    klass.define_instance_method('each_child')

    klass.define_instance_method('each_element')

    klass.define_instance_method('element?')

    klass.define_instance_method('element_decl?')

    klass.define_instance_method('empty?')

    klass.define_instance_method('entity?')

    klass.define_instance_method('entity_ref?')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('find') do |method|
      method.define_argument('xpath')
      method.define_optional_argument('nslist')
    end

    klass.define_instance_method('find_first') do |method|
      method.define_argument('xpath')
      method.define_optional_argument('nslist')
    end

    klass.define_instance_method('first')

    klass.define_instance_method('first?')

    klass.define_instance_method('fragment?')

    klass.define_instance_method('html_doc?')

    klass.define_instance_method('inner_xml') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('lang')

    klass.define_instance_method('lang=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('last')

    klass.define_instance_method('last?')

    klass.define_instance_method('line_num')

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('namespace')

    klass.define_instance_method('namespace=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('namespace?')

    klass.define_instance_method('namespace_node')

    klass.define_instance_method('namespaces')

    klass.define_instance_method('next')

    klass.define_instance_method('next=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('next?')

    klass.define_instance_method('node_type')

    klass.define_instance_method('node_type_name')

    klass.define_instance_method('notation?')

    klass.define_instance_method('ns')

    klass.define_instance_method('ns?')

    klass.define_instance_method('ns_def')

    klass.define_instance_method('ns_def?')

    klass.define_instance_method('output_escaping=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('output_escaping?')

    klass.define_instance_method('parent')

    klass.define_instance_method('parent?')

    klass.define_instance_method('path')

    klass.define_instance_method('pi?')

    klass.define_instance_method('pointer') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('prev')

    klass.define_instance_method('prev=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('prev?')

    klass.define_instance_method('properties')

    klass.define_instance_method('properties?')

    klass.define_instance_method('property') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('remove!')

    klass.define_instance_method('search_href') do |method|
      method.define_argument('href')
    end

    klass.define_instance_method('search_ns') do |method|
      method.define_argument('prefix')
    end

    klass.define_instance_method('sibling=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('space_preserve')

    klass.define_instance_method('space_preserve=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('text?')

    klass.define_instance_method('to_s') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('xinclude_end?')

    klass.define_instance_method('xinclude_start?')

    klass.define_instance_method('xlink?')

    klass.define_instance_method('xlink_type')

    klass.define_instance_method('xlink_type_name')
  end

  defs.define_constant('LibXML::XML::Node::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::SPACE_DEFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::SPACE_NOT_INHERIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::SPACE_PRESERVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_ACTUATE_AUTO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_ACTUATE_NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_ACTUATE_ONREQUEST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_SHOW_EMBED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_SHOW_NEW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_SHOW_NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_SHOW_REPLACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_TYPE_EXTENDED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_TYPE_EXTENDED_SET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_TYPE_NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Node::XLINK_TYPE_SIMPLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('catalog_dump')

    klass.define_method('catalog_remove')

    klass.define_method('check_lib_versions')

    klass.define_method('debug_entities')

    klass.define_method('debug_entities=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_compression')

    klass.define_method('default_compression=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_keep_blanks')

    klass.define_method('default_keep_blanks=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_line_numbers')

    klass.define_method('default_line_numbers=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_load_external_dtd')

    klass.define_method('default_load_external_dtd=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_pedantic_parser')

    klass.define_method('default_pedantic_parser=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_substitute_entities')

    klass.define_method('default_substitute_entities=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_tree_indent_string')

    klass.define_method('default_tree_indent_string=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_validity_checking')

    klass.define_method('default_validity_checking=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_warnings')

    klass.define_method('default_warnings=') do |method|
      method.define_argument('value')
    end

    klass.define_method('document') do |method|
      method.define_argument('doc')
    end

    klass.define_method('enabled_automata?')

    klass.define_method('enabled_c14n?')

    klass.define_method('enabled_catalog?')

    klass.define_method('enabled_debug?')

    klass.define_method('enabled_docbook?')

    klass.define_method('enabled_ftp?')

    klass.define_method('enabled_html?')

    klass.define_method('enabled_http?')

    klass.define_method('enabled_iconv?')

    klass.define_method('enabled_memory_debug?')

    klass.define_method('enabled_regexp?')

    klass.define_method('enabled_schemas?')

    klass.define_method('enabled_thread?')

    klass.define_method('enabled_unicode?')

    klass.define_method('enabled_xinclude?')

    klass.define_method('enabled_xpath?')

    klass.define_method('enabled_xpointer?')

    klass.define_method('enabled_zlib?')

    klass.define_method('features')

    klass.define_method('file') do |method|
      method.define_argument('path')
      method.define_optional_argument('options')
    end

    klass.define_method('filename') do |method|
      method.define_argument('value')
    end

    klass.define_method('indent_tree_output')

    klass.define_method('indent_tree_output=') do |method|
      method.define_argument('value')
    end

    klass.define_method('io') do |method|
      method.define_argument('io')
      method.define_optional_argument('options')
    end

    klass.define_method('memory_dump')

    klass.define_method('memory_used')

    klass.define_method('register_error_handler') do |method|
      method.define_argument('proc')
    end

    klass.define_method('string') do |method|
      method.define_argument('string')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('context')

    klass.define_instance_method('document=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('file=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('filename=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('input')

    klass.define_instance_method('io=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('parse')

    klass.define_instance_method('string=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('LibXML::XML::Parser::Context') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('document') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('file') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('io') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('string') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('base_uri')

    klass.define_instance_method('base_uri=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('data_directory')

    klass.define_instance_method('depth')

    klass.define_instance_method('disable_cdata=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('disable_cdata?')

    klass.define_instance_method('disable_sax?')

    klass.define_instance_method('docbook?')

    klass.define_instance_method('encoding')

    klass.define_instance_method('encoding=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('errno')

    klass.define_instance_method('html?')

    klass.define_instance_method('io_max_num_streams')

    klass.define_instance_method('io_num_streams')

    klass.define_instance_method('keep_blanks?')

    klass.define_instance_method('name_depth')

    klass.define_instance_method('name_depth_max')

    klass.define_instance_method('name_node')

    klass.define_instance_method('name_tab')

    klass.define_instance_method('node')

    klass.define_instance_method('node_depth')

    klass.define_instance_method('node_depth_max')

    klass.define_instance_method('num_chars')

    klass.define_instance_method('options')

    klass.define_instance_method('options=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('recovery=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('recovery?')

    klass.define_instance_method('replace_entities=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('replace_entities?')

    klass.define_instance_method('space_depth')

    klass.define_instance_method('space_depth_max')

    klass.define_instance_method('standalone?')

    klass.define_instance_method('stats?')

    klass.define_instance_method('subset_external?')

    klass.define_instance_method('subset_external_system_id')

    klass.define_instance_method('subset_external_uri')

    klass.define_instance_method('subset_internal?')

    klass.define_instance_method('subset_internal_name')

    klass.define_instance_method('valid')

    klass.define_instance_method('validate?')

    klass.define_instance_method('version')

    klass.define_instance_method('well_formed?')
  end

  defs.define_constant('LibXML::XML::Parser::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::COMPACT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::DTDATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::DTDLOAD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::DTDVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::HUGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::NOBASEFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::NOBLANKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::NOCDATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::NODICT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::NOENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::NOERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::NONET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::NOWARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::NOXINCNODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::NSCLEAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::PARSE_OLD10') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::PEDANTIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::RECOVER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::SAX1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::Options::XINCLUDE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::VERNUM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Parser::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('data') do |method|
      method.define_argument('string')
      method.define_optional_argument('options')
    end

    klass.define_method('document') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('io') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('string') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('walker') do |method|
      method.define_argument('doc')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('attribute_count')

    klass.define_instance_method('base_uri')

    klass.define_instance_method('byte_consumed')

    klass.define_instance_method('close')

    klass.define_instance_method('column_number')

    klass.define_instance_method('default?')

    klass.define_instance_method('depth')

    klass.define_instance_method('empty_element?')

    klass.define_instance_method('encoding')

    klass.define_instance_method('expand')

    klass.define_instance_method('get_attribute') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_attribute_no') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_attribute_ns') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('has_attributes?')

    klass.define_instance_method('has_value?')

    klass.define_instance_method('line_number')

    klass.define_instance_method('local_name')

    klass.define_instance_method('lookup_namespace') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('move_to_attribute') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('move_to_attribute_no') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('move_to_attribute_ns') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('move_to_element')

    klass.define_instance_method('move_to_first_attribute')

    klass.define_instance_method('move_to_next_attribute')

    klass.define_instance_method('name')

    klass.define_instance_method('namespace_declaration?')

    klass.define_instance_method('namespace_uri')

    klass.define_instance_method('next')

    klass.define_instance_method('next_sibling')

    klass.define_instance_method('node')

    klass.define_instance_method('node_type')

    klass.define_instance_method('normalization')

    klass.define_instance_method('prefix')

    klass.define_instance_method('quote_char')

    klass.define_instance_method('read')

    klass.define_instance_method('read_attribute_value')

    klass.define_instance_method('read_inner_xml')

    klass.define_instance_method('read_outer_xml')

    klass.define_instance_method('read_state')

    klass.define_instance_method('read_string')

    klass.define_instance_method('relax_ng_validate') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('reset_error_handler')

    klass.define_instance_method('schema_validate') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_error_handler') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('standalone')

    klass.define_instance_method('valid?')

    klass.define_instance_method('value')

    klass.define_instance_method('xml_lang')

    klass.define_instance_method('xml_version')
  end

  defs.define_constant('LibXML::XML::Reader::DEFAULTATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::LOADDTD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::MODE_CLOSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::MODE_EOF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::MODE_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::MODE_INITIAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::MODE_INTERACTIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::MODE_READING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::SEVERITY_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::SEVERITY_VALIDITY_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::SEVERITY_VALIDITY_WARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::SEVERITY_WARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::SUBST_ENTITIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_CDATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_COMMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_DOCUMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_DOCUMENT_FRAGMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_DOCUMENT_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_ELEMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_END_ELEMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_END_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_ENTITY_REFERENCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_NOTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_PROCESSING_INSTRUCTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_SIGNIFICANT_WHITESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_WHITESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::TYPE_XML_DECLARATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Reader::VALIDATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::RelaxNG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('document') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('from_string') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('new') do |method|
      method.define_argument('arg1')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('LibXML::XML::SaxParser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('file') do |method|
      method.define_argument('path')
    end

    klass.define_method('io') do |method|
      method.define_argument('io')
      method.define_optional_argument('options')
    end

    klass.define_method('string') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('callbacks')

    klass.define_instance_method('callbacks=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('file=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('io=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('parse')

    klass.define_instance_method('string=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('LibXML::XML::SaxParser::Callbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('on_cdata_block') do |method|
      method.define_argument('cdata')
    end

    klass.define_instance_method('on_characters') do |method|
      method.define_argument('chars')
    end

    klass.define_instance_method('on_comment') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('on_end_document')

    klass.define_instance_method('on_end_element_ns') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('uri')
    end

    klass.define_instance_method('on_error') do |method|
      method.define_argument('msg')
    end

    klass.define_instance_method('on_external_subset') do |method|
      method.define_argument('name')
      method.define_argument('external_id')
      method.define_argument('system_id')
    end

    klass.define_instance_method('on_has_external_subset')

    klass.define_instance_method('on_has_internal_subset')

    klass.define_instance_method('on_internal_subset') do |method|
      method.define_argument('name')
      method.define_argument('external_id')
      method.define_argument('system_id')
    end

    klass.define_instance_method('on_is_standalone')

    klass.define_instance_method('on_processing_instruction') do |method|
      method.define_argument('target')
      method.define_argument('data')
    end

    klass.define_instance_method('on_reference') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('on_start_document')

    klass.define_instance_method('on_start_element_ns') do |method|
      method.define_argument('name')
      method.define_argument('attributes')
      method.define_argument('prefix')
      method.define_argument('uri')
      method.define_argument('namespaces')
    end
  end

  defs.define_constant('LibXML::XML::SaxParser::VerboseCallbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('on_cdata_block') do |method|
      method.define_argument('cdata')
    end

    klass.define_instance_method('on_characters') do |method|
      method.define_argument('chars')
    end

    klass.define_instance_method('on_comment') do |method|
      method.define_argument('comment')
    end

    klass.define_instance_method('on_end_document')

    klass.define_instance_method('on_end_element_ns') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('uri')
    end

    klass.define_instance_method('on_error') do |method|
      method.define_argument('error')
    end

    klass.define_instance_method('on_external_subset') do |method|
      method.define_argument('name')
      method.define_argument('external_id')
      method.define_argument('system_id')
    end

    klass.define_instance_method('on_has_external_subset')

    klass.define_instance_method('on_has_internal_subset')

    klass.define_instance_method('on_internal_subset') do |method|
      method.define_argument('name')
      method.define_argument('external_id')
      method.define_argument('system_id')
    end

    klass.define_instance_method('on_is_standalone')

    klass.define_instance_method('on_processing_instruction') do |method|
      method.define_argument('target')
      method.define_argument('data')
    end

    klass.define_instance_method('on_reference') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('on_start_document')

    klass.define_instance_method('on_start_element_ns') do |method|
      method.define_argument('name')
      method.define_argument('attributes')
      method.define_argument('prefix')
      method.define_argument('uri')
      method.define_argument('namespaces')
    end
  end

  defs.define_constant('LibXML::XML::Schema') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cached') do |method|
      method.define_argument('location')
    end

    klass.define_method('document') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('from_string') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('new') do |method|
      method.define_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('_collect_types')

    klass.define_instance_method('_namespaces')

    klass.define_instance_method('document')

    klass.define_instance_method('elements')

    klass.define_instance_method('id')

    klass.define_instance_method('name')

    klass.define_instance_method('namespaces')

    klass.define_instance_method('target_namespace')

    klass.define_instance_method('types')

    klass.define_instance_method('version')
  end

  defs.define_constant('LibXML::XML::Schema::Attribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('default')

    klass.define_instance_method('name')

    klass.define_instance_method('namespace')

    klass.define_instance_method('node')

    klass.define_instance_method('occurs')

    klass.define_instance_method('required?')

    klass.define_instance_method('type')

    klass.define_instance_method('value')
  end

  defs.define_constant('LibXML::XML::Schema::Attribute::OPTIONAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Attribute::REQUIRED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Element') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('annotation')

    klass.define_instance_method('array?')

    klass.define_instance_method('elements')

    klass.define_instance_method('max_occurs')

    klass.define_instance_method('min_occurs')

    klass.define_instance_method('name')

    klass.define_instance_method('namespace')

    klass.define_instance_method('node')

    klass.define_instance_method('required?')

    klass.define_instance_method('type')

    klass.define_instance_method('value')
  end

  defs.define_constant('LibXML::XML::Schema::Facet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('kind')

    klass.define_instance_method('node')

    klass.define_instance_method('value')
  end

  defs.define_constant('LibXML::XML::Schema::Namespaces') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('find_by_href') do |method|
      method.define_argument('href')
    end

    klass.define_instance_method('find_by_prefix') do |method|
      method.define_argument('prefix')
    end
  end

  defs.define_constant('LibXML::XML::Schema::Type') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('annonymus_subtypes')

    klass.define_instance_method('annonymus_subtypes_recursively') do |method|
      method.define_optional_argument('parent')
    end

    klass.define_instance_method('annotation')

    klass.define_instance_method('attributes')

    klass.define_instance_method('base')

    klass.define_instance_method('elements')

    klass.define_instance_method('facets')

    klass.define_instance_method('kind')

    klass.define_instance_method('kind_name')

    klass.define_instance_method('name')

    klass.define_instance_method('namespace')

    klass.define_instance_method('node')
  end

  defs.define_constant('LibXML::XML::Schema::Types') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_EXTRA_ATTR_USE_PROHIB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_EXTRA_QNAMEREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_ENUMERATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_FRACTIONDIGITS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_LENGTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_MAXEXCLUSIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_MAXINCLUSIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_MAXLENGTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_MINEXCLUSIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_MININCLUSIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_MINLENGTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_TOTALDIGITS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_FACET_WHITESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_ANY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_ANY_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_ATTRIBUTEGROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_ATTRIBUTE_USE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_BASIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_CHOICE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_COMPLEX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_COMPLEX_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_ELEMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_EXTENSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_FACET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_GROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_IDC_KEY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_IDC_KEYREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_IDC_UNIQUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_LIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_NOTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_PARTICLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_RESTRICTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_SEQUENCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_SIMPLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_SIMPLE_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_UNION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Schema::Types::XML_SCHEMA_TYPE_UR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Tree::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::VERNUM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::Writer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('document')

    klass.define_method('file') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('io') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('string')

    klass.define_instance_method('end_attribute')

    klass.define_instance_method('end_cdata')

    klass.define_instance_method('end_comment')

    klass.define_instance_method('end_document')

    klass.define_instance_method('end_dtd')

    klass.define_instance_method('end_dtd_attlist')

    klass.define_instance_method('end_dtd_element')

    klass.define_instance_method('end_dtd_entity')

    klass.define_instance_method('end_element')

    klass.define_instance_method('end_pi')

    klass.define_instance_method('flush') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('full_end_element')

    klass.define_instance_method('result')

    klass.define_instance_method('set_indent') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_indent_string') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('start_attribute') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('start_attribute_ns') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('start_cdata')

    klass.define_instance_method('start_comment')

    klass.define_instance_method('start_document') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('start_dtd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('start_dtd_attlist') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('start_dtd_element') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('start_dtd_entity') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('start_element') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('start_element_ns') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('start_pi') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('write_attribute') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('write_attribute_ns') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('write_cdata') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('write_comment') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('write_dtd') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('write_dtd_attlist') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('write_dtd_element') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('write_dtd_entity') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
      method.define_argument('arg6')
    end

    klass.define_instance_method('write_dtd_external_entity') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('write_dtd_external_entity_contents') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('write_dtd_internal_entity') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('write_dtd_notation') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('write_element') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('write_element_ns') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('write_pi') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('write_raw') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('write_string') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('LibXML::XML::XInclude') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XML_NAMESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath::BOOLEAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath::Context') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('disable_cache')

    klass.define_instance_method('doc')

    klass.define_instance_method('enable_cache') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('find') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('node=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('register_namespace') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('register_namespaces') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('register_namespaces_from_node') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('LibXML::XML::XPath::Expression') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('compile') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('LibXML::XML::XPath::LOCATIONSET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath::NODESET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath::NUMBER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath::Object') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('context')

    klass.define_instance_method('debug')

    klass.define_instance_method('each')

    klass.define_instance_method('empty?')

    klass.define_instance_method('first')

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('set')

    klass.define_instance_method('size')

    klass.define_instance_method('string')

    klass.define_instance_method('to_a')

    klass.define_instance_method('xpath_type')
  end

  defs.define_constant('LibXML::XML::XPath::POINT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath::RANGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath::STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath::UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath::USERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPath::XSLT_TREE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('LibXML::XML::XPointer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('range') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end
end
