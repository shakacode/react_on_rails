# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('Nokogiri') do |defs|
  defs.define_constant('Nokogiri') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('HTML') do |method|
      method.define_argument('thing')
      method.define_optional_argument('url')
      method.define_optional_argument('encoding')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('Slop') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('XML') do |method|
      method.define_argument('thing')
      method.define_optional_argument('url')
      method.define_optional_argument('encoding')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('XSLT') do |method|
      method.define_argument('stylesheet')
      method.define_optional_argument('modules')
    end

    klass.define_method('jruby?')

    klass.define_method('make') do |method|
      method.define_optional_argument('input')
      method.define_optional_argument('opts')
      method.define_block_argument('blk')
    end

    klass.define_method('parse') do |method|
      method.define_argument('string')
      method.define_optional_argument('url')
      method.define_optional_argument('encoding')
      method.define_optional_argument('options')
    end

    klass.define_method('uses_libxml?')
  end

  defs.define_constant('Nokogiri::CSS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('parse') do |method|
      method.define_argument('selector')
    end

    klass.define_method('xpath_for') do |method|
      method.define_argument('selector')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Nokogiri::CSS::Node') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accept') do |method|
      method.define_argument('visitor')
    end

    klass.define_instance_method('find_by_type') do |method|
      method.define_argument('types')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('type')
      method.define_argument('value')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('preprocess!')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_type')

    klass.define_instance_method('to_xpath') do |method|
      method.define_optional_argument('prefix')
      method.define_optional_argument('visitor')
    end

    klass.define_instance_method('type')

    klass.define_instance_method('type=')

    klass.define_instance_method('value')

    klass.define_instance_method('value=')
  end

  defs.define_constant('Nokogiri::CSS::Node::ALLOW_COMBINATOR_ON_SELF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser') do |klass|
    klass.inherits(defs.constant_proxy('Racc::Parser', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_argument('string')
    end

    klass.define_method('[]=') do |method|
      method.define_argument('string')
      method.define_argument('value')
    end

    klass.define_method('cache_on')

    klass.define_method('cache_on=')

    klass.define_method('cache_on?')

    klass.define_method('clear_cache')

    klass.define_method('parse') do |method|
      method.define_argument('selector')
    end

    klass.define_method('set_cache')

    klass.define_method('without_cache') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('_reduce_1') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_10') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_11') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_12') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_14') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_15') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_16') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_17') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_18') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_19') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_2') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_21') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_23') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_24') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_25') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_26') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_28') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_29') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_3') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_30') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_31') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_32') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_33') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_34') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_35') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_36') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_37') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_38') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_39') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_4') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_40') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_43') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_44') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_45') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_46') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_47') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_48') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_5') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_51') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_52') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_53') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_54') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_59') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_6') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_60') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_61') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_63') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_64') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_65') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_66') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_67') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_68') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_69') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_7') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_70') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_8') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_9') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('_reduce_none') do |method|
      method.define_argument('val')
      method.define_argument('_values')
      method.define_argument('result')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('namespaces')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next_token')

    klass.define_instance_method('on_error') do |method|
      method.define_argument('error_token_id')
      method.define_argument('error_value')
      method.define_argument('value_stack')
    end

    klass.define_instance_method('parse') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('xpath_for') do |method|
      method.define_argument('string')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Main_Parsing_Routine') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Runtime_Core_Id_C') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Runtime_Core_Revision') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Runtime_Core_Revision_C') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Runtime_Core_Revision_R') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Runtime_Core_Version') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Runtime_Core_Version_C') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Runtime_Core_Version_R') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Runtime_Revision') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Runtime_Type') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_Runtime_Version') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_YY_Parse_Method') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_arg') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_debug_parser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Parser::Racc_token_to_s_table') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::SyntaxError') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::SyntaxError', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::Tokenizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_next_token')

    klass.define_instance_method('action')

    klass.define_instance_method('filename')

    klass.define_instance_method('lineno')

    klass.define_instance_method('load_file') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('next_token')

    klass.define_instance_method('scan') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('scan_file') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('scan_setup') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('scan_str') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('state')

    klass.define_instance_method('state=')
  end

  defs.define_constant('Nokogiri::CSS::Tokenizer::ScanError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::CSS::XPathVisitor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accept') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_attribute_condition') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_child_selector') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_class_condition') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_combinator') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_conditional_selector') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_descendant_selector') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_direct_adjacent_selector') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_element_name') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_following_selector') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_function') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_id') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_not') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('visit_pseudo_class') do |method|
      method.define_argument('node')
    end
  end

  defs.define_constant('Nokogiri::Decorators') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::Decorators::Slop') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Nokogiri::EncodingHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('[]')

    klass.define_method('alias')

    klass.define_method('clear_aliases!')

    klass.define_method('delete')

    klass.define_instance_method('name')
  end

  defs.define_constant('Nokogiri::HTML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('fragment') do |method|
      method.define_argument('string')
      method.define_optional_argument('encoding')
    end

    klass.define_method('parse') do |method|
      method.define_argument('thing')
      method.define_optional_argument('url')
      method.define_optional_argument('encoding')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Nokogiri::HTML::Builder') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Builder', RubyLint.registry))

    klass.define_instance_method('to_html')
  end

  defs.define_constant('Nokogiri::HTML::Builder::NodeBuilder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('k')
      method.define_argument('v')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('node')
      method.define_argument('doc_builder')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Nokogiri::HTML::Document') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Document', RubyLint.registry))

    klass.define_method('new')

    klass.define_method('parse') do |method|
      method.define_argument('string_or_io')
      method.define_optional_argument('url')
      method.define_optional_argument('encoding')
      method.define_optional_argument('options')
    end

    klass.define_method('read_io')

    klass.define_method('read_memory')

    klass.define_instance_method('fragment') do |method|
      method.define_optional_argument('tags')
    end

    klass.define_instance_method('meta_encoding')

    klass.define_instance_method('meta_encoding=') do |method|
      method.define_argument('encoding')
    end

    klass.define_instance_method('serialize') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('title')

    klass.define_instance_method('title=') do |method|
      method.define_argument('text')
    end

    klass.define_instance_method('type')
  end

  defs.define_constant('Nokogiri::HTML::Document::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::EncodingFound') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('found_encoding')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('encoding')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Nokogiri::HTML::Document::EncodingReader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('detect_encoding') do |method|
      method.define_argument('chunk')
    end

    klass.define_method('detect_encoding_for_jruby_without_fix') do |method|
      method.define_argument('chunk')
    end

    klass.define_method('is_jruby_without_fix?')

    klass.define_instance_method('encoding_found')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('io')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('read') do |method|
      method.define_argument('len')
    end
  end

  defs.define_constant('Nokogiri::HTML::Document::EncodingReader::JumpSAXHandler') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::HTML::Document::EncodingReader::SAXHandler', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('jumptag')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('start_element') do |method|
      method.define_argument('name')
      method.define_optional_argument('attrs')
    end
  end

  defs.define_constant('Nokogiri::HTML::Document::EncodingReader::SAXHandler') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::SAX::Document', RubyLint.registry))

    klass.define_instance_method('encoding')

    klass.define_instance_method('initialize')

    klass.define_instance_method('start_element') do |method|
      method.define_argument('name')
      method.define_optional_argument('attrs')
    end
  end

  defs.define_constant('Nokogiri::HTML::Document::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::HTML::Document::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::NCNAME_CHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::NCNAME_RE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::NCNAME_START_CHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::HTML::Document::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::HTML::Document::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::Document::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::DocumentFragment', RubyLint.registry))

    klass.define_method('parse') do |method|
      method.define_argument('tags')
      method.define_optional_argument('encoding')
    end

    klass.define_instance_method('errors')

    klass.define_instance_method('errors=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')
      method.define_optional_argument('tags')
      method.define_optional_argument('ctx')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::HTML::DocumentFragment::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::HTML::DocumentFragment::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::DocumentFragment::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('[]')

    klass.define_instance_method('block?')

    klass.define_instance_method('default_sub_element')

    klass.define_instance_method('deprecated?')

    klass.define_instance_method('deprecated_attributes')

    klass.define_instance_method('description')

    klass.define_instance_method('empty?')

    klass.define_instance_method('implied_end_tag?')

    klass.define_instance_method('implied_start_tag?')

    klass.define_instance_method('inline?')

    klass.define_instance_method('inspect')

    klass.define_instance_method('name')

    klass.define_instance_method('optional_attributes')

    klass.define_instance_method('required_attributes')

    klass.define_instance_method('save_end_tag?')

    klass.define_instance_method('sub_elements')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::ACTION_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::ALIGN_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::ALT_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::APPLET_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::AREA_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::A_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::BASEFONT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::BGCOLOR_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::BLOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::BLOCKLI_ELT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::BODY_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::BODY_CONTENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::BODY_DEPR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::BUTTON_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::CELLHALIGN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::CELLVALIGN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::CLEAR_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::COL_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::COL_ELT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::COMPACT_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::COMPACT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::CONTENT_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::COREATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::CORE_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::CORE_I18N_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::DIR_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::DL_CONTENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::DefaultDescriptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::Desc') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('attrs_depr')

    klass.define_instance_method('attrs_depr=')

    klass.define_instance_method('attrs_opt')

    klass.define_instance_method('attrs_opt=')

    klass.define_instance_method('attrs_req')

    klass.define_instance_method('attrs_req=')

    klass.define_instance_method('defaultsubelt')

    klass.define_instance_method('defaultsubelt=')

    klass.define_instance_method('depr')

    klass.define_instance_method('depr=')

    klass.define_instance_method('desc')

    klass.define_instance_method('desc=')

    klass.define_instance_method('dtd')

    klass.define_instance_method('dtd=')

    klass.define_instance_method('empty')

    klass.define_instance_method('empty=')

    klass.define_instance_method('endTag')

    klass.define_instance_method('endTag=')

    klass.define_instance_method('isinline')

    klass.define_instance_method('isinline=')

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('saveEndTag')

    klass.define_instance_method('saveEndTag=')

    klass.define_instance_method('startTag')

    klass.define_instance_method('startTag=')

    klass.define_instance_method('subelts')

    klass.define_instance_method('subelts=')
  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::EDIT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::EMBED_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::EVENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FIELDSET_CONTENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FLOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FLOW_PARAM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FONTSTYLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FONT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FORMCTRL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FORM_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FORM_CONTENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FRAMESET_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FRAMESET_CONTENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::FRAME_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HEADING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HEAD_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HEAD_CONTENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HREF_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HR_DEPR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HTML_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HTML_CDATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HTML_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HTML_FLOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HTML_INLINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::HTML_PCDATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::I18N') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::I18N_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::IFRAME_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::IMG_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::INLINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::INLINE_P') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::INPUT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::LABEL_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::LABEL_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::LANGUAGE_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::LEGEND_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::LINK_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::LIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::LI_ELT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::MAP_CONTENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::META_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::MODIFIER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::NAME_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::NOFRAMES_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::OBJECT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::OBJECT_CONTENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::OBJECT_DEPR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::OL_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::OPTGROUP_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::OPTION_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::OPTION_ELT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::PARAM_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::PCDATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::PHRASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::PRE_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::PROMPT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::QUOTE_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::ROWS_COLS_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::SCRIPT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::SELECT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::SELECT_CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::SPECIAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::SRC_ALT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::STYLE_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TABLE_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TABLE_CONTENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TABLE_DEPR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TALIGN_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TARGET_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TEXTAREA_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TH_TD_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TH_TD_DEPR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TR_CONTENTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TR_ELT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::TYPE_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::UL_DEPR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::VERSION_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::ElementDescription::WIDTH_ATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::EntityDescription') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::EntityDescription::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::HTML::EntityDescription::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Nokogiri::HTML::EntityDescription::HTMLElementDescription') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('attrs_depr')

    klass.define_instance_method('attrs_depr=')

    klass.define_instance_method('attrs_opt')

    klass.define_instance_method('attrs_opt=')

    klass.define_instance_method('attrs_req')

    klass.define_instance_method('attrs_req=')

    klass.define_instance_method('defaultsubelt')

    klass.define_instance_method('defaultsubelt=')

    klass.define_instance_method('depr')

    klass.define_instance_method('depr=')

    klass.define_instance_method('desc')

    klass.define_instance_method('desc=')

    klass.define_instance_method('dtd')

    klass.define_instance_method('dtd=')

    klass.define_instance_method('empty')

    klass.define_instance_method('empty=')

    klass.define_instance_method('endTag')

    klass.define_instance_method('endTag=')

    klass.define_instance_method('isinline')

    klass.define_instance_method('isinline=')

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('saveEndTag')

    klass.define_instance_method('saveEndTag=')

    klass.define_instance_method('startTag')

    klass.define_instance_method('startTag=')

    klass.define_instance_method('subelts')

    klass.define_instance_method('subelts=')
  end

  defs.define_constant('Nokogiri::HTML::EntityDescription::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Nokogiri::HTML::EntityDescription::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::EntityDescription::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::HTML::EntityDescription::Tms') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('cstime')

    klass.define_instance_method('cstime=')

    klass.define_instance_method('cutime')

    klass.define_instance_method('cutime=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('utime')
      method.define_optional_argument('stime')
      method.define_optional_argument('cutime')
      method.define_optional_argument('cstime')
      method.define_optional_argument('tutime')
      method.define_optional_argument('tstime')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('stime')

    klass.define_instance_method('stime=')

    klass.define_instance_method('tstime')

    klass.define_instance_method('tstime=')

    klass.define_instance_method('tutime')

    klass.define_instance_method('tutime=')

    klass.define_instance_method('utime')

    klass.define_instance_method('utime=')
  end

  defs.define_constant('Nokogiri::HTML::EntityLookup') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('get')
  end

  defs.define_constant('Nokogiri::HTML::NamedCharacters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::SAX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::SAX::Parser') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::SAX::Parser', RubyLint.registry))

    klass.define_instance_method('parse_file') do |method|
      method.define_argument('filename')
      method.define_optional_argument('encoding')
    end

    klass.define_instance_method('parse_memory') do |method|
      method.define_argument('data')
      method.define_optional_argument('encoding')
    end
  end

  defs.define_constant('Nokogiri::HTML::SAX::Parser::Attribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::SAX::Parser::ENCODINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::HTML::SAX::ParserContext') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::SAX::ParserContext', RubyLint.registry))

    klass.define_method('file')

    klass.define_method('memory')

    klass.define_method('new') do |method|
      method.define_argument('thing')
      method.define_optional_argument('encoding')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('parse_with')
  end

  defs.define_constant('Nokogiri::HTML::SAX::PushParser') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::SAX::PushParser', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('doc')
      method.define_optional_argument('file_name')
      method.define_optional_argument('encoding')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Nokogiri::LIBXML_ICONV_ENABLED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::LIBXML_PARSER_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::LIBXML_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::NOKOGIRI_LIBXML2_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::NOKOGIRI_LIBXSLT_PATH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::NOKOGIRI_USE_PACKAGED_LIBRARIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::SyntaxError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::VERSION_INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::VersionInfo') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('instance')

    klass.define_instance_method('compiled_parser_version')

    klass.define_instance_method('engine')

    klass.define_instance_method('jruby?')

    klass.define_instance_method('libxml2?')

    klass.define_instance_method('libxml2_using_packaged?')

    klass.define_instance_method('libxml2_using_system?')

    klass.define_instance_method('loaded_parser_version')

    klass.define_instance_method('to_hash')

    klass.define_instance_method('to_markdown')

    klass.define_instance_method('warnings')
  end

  defs.define_constant('Nokogiri::XML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('Reader') do |method|
      method.define_argument('string_or_io')
      method.define_optional_argument('url')
      method.define_optional_argument('encoding')
      method.define_optional_argument('options')
    end

    klass.define_method('RelaxNG') do |method|
      method.define_argument('string_or_io')
    end

    klass.define_method('Schema') do |method|
      method.define_argument('string_or_io')
    end

    klass.define_method('fragment') do |method|
      method.define_argument('string')
    end

    klass.define_method('parse') do |method|
      method.define_argument('thing')
      method.define_optional_argument('url')
      method.define_optional_argument('encoding')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Nokogiri::XML::Attr') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))

    klass.define_method('new')

    klass.define_instance_method('content=')

    klass.define_instance_method('to_s')

    klass.define_instance_method('value')

    klass.define_instance_method('value=')
  end

  defs.define_constant('Nokogiri::XML::Attr::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::Attr::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::Attr::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::Attr::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Attr::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))

    klass.define_instance_method('attribute_type')

    klass.define_instance_method('default')

    klass.define_instance_method('enumeration')

    klass.define_instance_method('inspect')
  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::AttributeDecl::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::AttributeDecl::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::AttributeDecl::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Builder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('with') do |method|
      method.define_argument('root')
      method.define_block_argument('block')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('ns')
    end

    klass.define_instance_method('arity')

    klass.define_instance_method('arity=')

    klass.define_instance_method('cdata') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('comment') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('context')

    klass.define_instance_method('context=')

    klass.define_instance_method('doc')

    klass.define_instance_method('doc=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')
      method.define_optional_argument('root')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('parent')

    klass.define_instance_method('parent=')

    klass.define_instance_method('text') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('to_xml') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Nokogiri::XML::Builder::NodeBuilder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('k')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('k')
      method.define_argument('v')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('node')
      method.define_argument('doc_builder')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Nokogiri::XML::CDATA') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Text', RubyLint.registry))

    klass.define_method('new')

    klass.define_instance_method('name')
  end

  defs.define_constant('Nokogiri::XML::CDATA::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::CDATA::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::CDATA::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::CDATA::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CDATA::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Nokogiri::XML::PP::CharacterData', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::CharacterData::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::CharacterData::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::CharacterData::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::CharacterData::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::CharacterData', RubyLint.registry))

    klass.define_method('new')
  end

  defs.define_constant('Nokogiri::XML::Comment::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::Comment::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::Comment::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::Comment::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Comment::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))

    klass.define_instance_method('attributes')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('elements')

    klass.define_instance_method('entities')

    klass.define_instance_method('external_id')

    klass.define_instance_method('keys')

    klass.define_instance_method('notations')

    klass.define_instance_method('system_id')

    klass.define_instance_method('validate')
  end

  defs.define_constant('Nokogiri::XML::DTD::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::DTD::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::DTD::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::DTD::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DTD::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))

    klass.define_method('empty_doc?') do |method|
      method.define_argument('string_or_io')
    end

    klass.define_method('new')

    klass.define_method('parse') do |method|
      method.define_argument('string_or_io')
      method.define_optional_argument('url')
      method.define_optional_argument('encoding')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('read_io')

    klass.define_method('read_memory')

    klass.define_method('wrap') do |method|
      method.define_argument('document')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('add_child') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('canonicalize')

    klass.define_instance_method('clone')

    klass.define_instance_method('collect_namespaces')

    klass.define_instance_method('create_cdata') do |method|
      method.define_argument('string')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create_comment') do |method|
      method.define_argument('string')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create_element') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create_entity')

    klass.define_instance_method('create_text_node') do |method|
      method.define_argument('string')
      method.define_block_argument('block')
    end

    klass.define_instance_method('decorate') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('decorators') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('document')

    klass.define_instance_method('dup')

    klass.define_instance_method('encoding')

    klass.define_instance_method('encoding=')

    klass.define_instance_method('errors')

    klass.define_instance_method('errors=')

    klass.define_instance_method('fragment') do |method|
      method.define_optional_argument('tags')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('namespaces')

    klass.define_instance_method('remove_namespaces!')

    klass.define_instance_method('root')

    klass.define_instance_method('root=')

    klass.define_instance_method('slop!')

    klass.define_instance_method('to_java')

    klass.define_instance_method('to_xml') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('url')

    klass.define_instance_method('validate')

    klass.define_instance_method('version')
  end

  defs.define_constant('Nokogiri::XML::Document::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::Document::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::NCNAME_CHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::NCNAME_RE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::NCNAME_START_CHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::Document::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::Document::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Document::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))

    klass.define_method('new')

    klass.define_method('parse') do |method|
      method.define_argument('tags')
    end

    klass.define_instance_method('css') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')
      method.define_optional_argument('tags')
      method.define_optional_argument('ctx')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('serialize')

    klass.define_instance_method('to_html') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_xhtml') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('to_xml') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::DocumentFragment::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::DocumentFragment::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::DocumentFragment::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::Element::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::Element::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::Element::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Element::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementContent') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('children')

    klass.define_instance_method('document')

    klass.define_instance_method('name')

    klass.define_instance_method('occur')

    klass.define_instance_method('prefix')

    klass.define_instance_method('type')
  end

  defs.define_constant('Nokogiri::XML::ElementContent::ELEMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementContent::MULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementContent::ONCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementContent::OPT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementContent::OR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementContent::PCDATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementContent::PLUS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementContent::SEQ') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))

    klass.define_instance_method('content')

    klass.define_instance_method('element_type')

    klass.define_instance_method('inspect')

    klass.define_instance_method('prefix')
  end

  defs.define_constant('Nokogiri::XML::ElementDecl::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::ElementDecl::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::ElementDecl::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::ElementDecl::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ElementDecl::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_argument('name')
      method.define_argument('doc')
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('content')

    klass.define_instance_method('entity_type')

    klass.define_instance_method('external_id')

    klass.define_instance_method('inspect')

    klass.define_instance_method('original_content')

    klass.define_instance_method('system_id')
  end

  defs.define_constant('Nokogiri::XML::EntityDecl::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::EXTERNAL_GENERAL_PARSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::EXTERNAL_GENERAL_UNPARSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::EXTERNAL_PARAMETER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::EntityDecl::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::INTERNAL_GENERAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::INTERNAL_PARAMETER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::INTERNAL_PREDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::EntityDecl::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::EntityDecl::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityDecl::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))

    klass.define_method('new')
  end

  defs.define_constant('Nokogiri::XML::EntityReference::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::EntityReference::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::EntityReference::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::EntityReference::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::EntityReference::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Namespace') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Nokogiri::XML::PP::Node', RubyLint.registry))

    klass.define_instance_method('document')

    klass.define_instance_method('href')

    klass.define_instance_method('prefix')
  end

  defs.define_constant('Nokogiri::XML::Node') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Nokogiri::XML::PP::Node', RubyLint.registry))

    klass.define_method('new')

    klass.define_instance_method('%') do |method|
      method.define_argument('path')
      method.define_optional_argument('ns')
    end

    klass.define_instance_method('/') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>') do |method|
      method.define_argument('selector')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('accept') do |method|
      method.define_argument('visitor')
    end

    klass.define_instance_method('add_child') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('add_namespace')

    klass.define_instance_method('add_namespace_definition')

    klass.define_instance_method('add_next_sibling') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('add_previous_sibling') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('after') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('ancestors') do |method|
      method.define_optional_argument('selector')
    end

    klass.define_instance_method('at') do |method|
      method.define_argument('path')
      method.define_optional_argument('ns')
    end

    klass.define_instance_method('at_css') do |method|
      method.define_rest_argument('rules')
    end

    klass.define_instance_method('at_xpath') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_instance_method('attr') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('attribute')

    klass.define_instance_method('attribute_nodes')

    klass.define_instance_method('attribute_with_ns')

    klass.define_instance_method('attributes')

    klass.define_instance_method('before') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('blank?')

    klass.define_instance_method('canonicalize') do |method|
      method.define_optional_argument('mode')
      method.define_optional_argument('inclusive_namespaces')
      method.define_optional_argument('with_comments')
    end

    klass.define_instance_method('cdata?')

    klass.define_instance_method('child')

    klass.define_instance_method('children')

    klass.define_instance_method('children=') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('clone')

    klass.define_instance_method('comment?')

    klass.define_instance_method('content')

    klass.define_instance_method('content=') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('create_external_subset')

    klass.define_instance_method('create_internal_subset')

    klass.define_instance_method('css') do |method|
      method.define_rest_argument('rules')
    end

    klass.define_instance_method('css_path')

    klass.define_instance_method('decorate!')

    klass.define_instance_method('default_namespace=') do |method|
      method.define_argument('url')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('description')

    klass.define_instance_method('do_xinclude') do |method|
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('document')

    klass.define_instance_method('dup')

    klass.define_instance_method('each')

    klass.define_instance_method('elem?')

    klass.define_instance_method('element?')

    klass.define_instance_method('element_children')

    klass.define_instance_method('elements')

    klass.define_instance_method('encode_special_chars')

    klass.define_instance_method('external_subset')

    klass.define_instance_method('first_element_child')

    klass.define_instance_method('fragment') do |method|
      method.define_argument('tags')
    end

    klass.define_instance_method('fragment?')

    klass.define_instance_method('get_attribute') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('has_attribute?')

    klass.define_instance_method('html?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('document')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inner_html') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('inner_html=') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('inner_text')

    klass.define_instance_method('internal_subset')

    klass.define_instance_method('key?')

    klass.define_instance_method('keys')

    klass.define_instance_method('last_element_child')

    klass.define_instance_method('line')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('selector')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('namespace')

    klass.define_instance_method('namespace=') do |method|
      method.define_argument('ns')
    end

    klass.define_instance_method('namespace_definitions')

    klass.define_instance_method('namespace_scopes')

    klass.define_instance_method('namespaced_key?')

    klass.define_instance_method('namespaces')

    klass.define_instance_method('native_content=')

    klass.define_instance_method('next')

    klass.define_instance_method('next=') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('next_element')

    klass.define_instance_method('next_sibling')

    klass.define_instance_method('node_name')

    klass.define_instance_method('node_name=')

    klass.define_instance_method('node_type')

    klass.define_instance_method('parent')

    klass.define_instance_method('parent=') do |method|
      method.define_argument('parent_node')
    end

    klass.define_instance_method('parse') do |method|
      method.define_argument('string_or_io')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path')

    klass.define_instance_method('pointer_id')

    klass.define_instance_method('previous')

    klass.define_instance_method('previous=') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('previous_element')

    klass.define_instance_method('previous_sibling')

    klass.define_instance_method('read_only?')

    klass.define_instance_method('remove')

    klass.define_instance_method('remove_attribute') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('replace') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('search') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_instance_method('serialize') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('set_attribute') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('swap') do |method|
      method.define_argument('node_or_tags')
    end

    klass.define_instance_method('text')

    klass.define_instance_method('text?')

    klass.define_instance_method('to_html') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_str')

    klass.define_instance_method('to_xhtml') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('to_xml') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('traverse') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('type')

    klass.define_instance_method('unlink')

    klass.define_instance_method('values')

    klass.define_instance_method('write_html_to') do |method|
      method.define_argument('io')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('write_to') do |method|
      method.define_argument('io')
      method.define_rest_argument('options')
    end

    klass.define_instance_method('write_xhtml_to') do |method|
      method.define_argument('io')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('write_xml_to') do |method|
      method.define_argument('io')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('xml?')

    klass.define_instance_method('xpath') do |method|
      method.define_rest_argument('paths')
    end
  end

  defs.define_constant('Nokogiri::XML::Node::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::Node::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::Node::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Node::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::NodeSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('%') do |method|
      method.define_argument('path')
      method.define_optional_argument('ns')
    end

    klass.define_instance_method('&')

    klass.define_instance_method('+')

    klass.define_instance_method('-')

    klass.define_instance_method('/') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_instance_method('<<')

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>') do |method|
      method.define_argument('selector')
    end

    klass.define_instance_method('[]')

    klass.define_instance_method('add_class') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('after') do |method|
      method.define_argument('datum')
    end

    klass.define_instance_method('at') do |method|
      method.define_argument('path')
      method.define_optional_argument('ns')
    end

    klass.define_instance_method('at_css') do |method|
      method.define_rest_argument('rules')
    end

    klass.define_instance_method('at_xpath') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_instance_method('attr') do |method|
      method.define_argument('key')
      method.define_optional_argument('value')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('attribute') do |method|
      method.define_argument('key')
      method.define_optional_argument('value')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('before') do |method|
      method.define_argument('datum')
    end

    klass.define_instance_method('children')

    klass.define_instance_method('css') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_instance_method('delete')

    klass.define_instance_method('document')

    klass.define_instance_method('document=')

    klass.define_instance_method('dup')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('filter') do |method|
      method.define_argument('expr')
    end

    klass.define_instance_method('first') do |method|
      method.define_optional_argument('n')
    end

    klass.define_instance_method('include?')

    klass.define_instance_method('index') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')
      method.define_optional_argument('list')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inner_html') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('inner_text')

    klass.define_instance_method('inspect')

    klass.define_instance_method('last')

    klass.define_instance_method('length')

    klass.define_instance_method('pop')

    klass.define_instance_method('push')

    klass.define_instance_method('remove')

    klass.define_instance_method('remove_attr') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('remove_class') do |method|
      method.define_optional_argument('name')
    end

    klass.define_instance_method('reverse')

    klass.define_instance_method('search') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_instance_method('set') do |method|
      method.define_argument('key')
      method.define_optional_argument('value')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('shift')

    klass.define_instance_method('size')

    klass.define_instance_method('slice')

    klass.define_instance_method('text')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_ary')

    klass.define_instance_method('to_html') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_xhtml') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('to_xml') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('unlink')

    klass.define_instance_method('wrap') do |method|
      method.define_argument('html')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('xpath') do |method|
      method.define_rest_argument('paths')
    end

    klass.define_instance_method('|')
  end

  defs.define_constant('Nokogiri::XML::NodeSet::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::NodeSet::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::Notation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Notation::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::Notation::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('Nokogiri::XML::Notation::HTMLElementDescription') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('attrs_depr')

    klass.define_instance_method('attrs_depr=')

    klass.define_instance_method('attrs_opt')

    klass.define_instance_method('attrs_opt=')

    klass.define_instance_method('attrs_req')

    klass.define_instance_method('attrs_req=')

    klass.define_instance_method('defaultsubelt')

    klass.define_instance_method('defaultsubelt=')

    klass.define_instance_method('depr')

    klass.define_instance_method('depr=')

    klass.define_instance_method('desc')

    klass.define_instance_method('desc=')

    klass.define_instance_method('dtd')

    klass.define_instance_method('dtd=')

    klass.define_instance_method('empty')

    klass.define_instance_method('empty=')

    klass.define_instance_method('endTag')

    klass.define_instance_method('endTag=')

    klass.define_instance_method('isinline')

    klass.define_instance_method('isinline=')

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('saveEndTag')

    klass.define_instance_method('saveEndTag=')

    klass.define_instance_method('startTag')

    klass.define_instance_method('startTag=')

    klass.define_instance_method('subelts')

    klass.define_instance_method('subelts=')
  end

  defs.define_constant('Nokogiri::XML::Notation::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('Nokogiri::XML::Notation::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Notation::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::Notation::Tms') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('cstime')

    klass.define_instance_method('cstime=')

    klass.define_instance_method('cutime')

    klass.define_instance_method('cutime=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('utime')
      method.define_optional_argument('stime')
      method.define_optional_argument('cutime')
      method.define_optional_argument('cstime')
      method.define_optional_argument('tutime')
      method.define_optional_argument('tstime')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('stime')

    klass.define_instance_method('stime=')

    klass.define_instance_method('tstime')

    klass.define_instance_method('tstime=')

    klass.define_instance_method('tutime')

    klass.define_instance_method('tutime=')

    klass.define_instance_method('utime')

    klass.define_instance_method('utime=')
  end

  defs.define_constant('Nokogiri::XML::PP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::PP::CharacterData') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('inspect')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('pp')
    end
  end

  defs.define_constant('Nokogiri::XML::PP::Node') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('inspect')

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('pp')
    end
  end

  defs.define_constant('Nokogiri::XML::ParseOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('compact')

    klass.define_instance_method('compact?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('dtdattr')

    klass.define_instance_method('dtdattr?')

    klass.define_instance_method('dtdload')

    klass.define_instance_method('dtdload?')

    klass.define_instance_method('dtdvalid')

    klass.define_instance_method('dtdvalid?')

    klass.define_instance_method('huge')

    klass.define_instance_method('huge?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('nobasefix')

    klass.define_instance_method('nobasefix?')

    klass.define_instance_method('noblanks')

    klass.define_instance_method('noblanks?')

    klass.define_instance_method('nocdata')

    klass.define_instance_method('nocdata?')

    klass.define_instance_method('nocompact')

    klass.define_instance_method('nodefault_html')

    klass.define_instance_method('nodefault_xml')

    klass.define_instance_method('nodict')

    klass.define_instance_method('nodict?')

    klass.define_instance_method('nodtdattr')

    klass.define_instance_method('nodtdload')

    klass.define_instance_method('nodtdvalid')

    klass.define_instance_method('noent')

    klass.define_instance_method('noent?')

    klass.define_instance_method('noerror')

    klass.define_instance_method('noerror?')

    klass.define_instance_method('nohuge')

    klass.define_instance_method('nonet')

    klass.define_instance_method('nonet?')

    klass.define_instance_method('nonobasefix')

    klass.define_instance_method('nonoblanks')

    klass.define_instance_method('nonocdata')

    klass.define_instance_method('nonodict')

    klass.define_instance_method('nonoent')

    klass.define_instance_method('nonoerror')

    klass.define_instance_method('nononet')

    klass.define_instance_method('nonowarning')

    klass.define_instance_method('nonoxincnode')

    klass.define_instance_method('nonsclean')

    klass.define_instance_method('noold10')

    klass.define_instance_method('nopedantic')

    klass.define_instance_method('norecover')

    klass.define_instance_method('nosax1')

    klass.define_instance_method('nowarning')

    klass.define_instance_method('nowarning?')

    klass.define_instance_method('noxinclude')

    klass.define_instance_method('noxincnode')

    klass.define_instance_method('noxincnode?')

    klass.define_instance_method('nsclean')

    klass.define_instance_method('nsclean?')

    klass.define_instance_method('old10')

    klass.define_instance_method('old10?')

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('pedantic')

    klass.define_instance_method('pedantic?')

    klass.define_instance_method('recover')

    klass.define_instance_method('recover?')

    klass.define_instance_method('sax1')

    klass.define_instance_method('sax1?')

    klass.define_instance_method('strict')

    klass.define_instance_method('strict?')

    klass.define_instance_method('to_i')

    klass.define_instance_method('xinclude')

    klass.define_instance_method('xinclude?')
  end

  defs.define_constant('Nokogiri::XML::ParseOptions::COMPACT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::DEFAULT_HTML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::DEFAULT_XML') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::DTDATTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::DTDLOAD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::DTDVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::HUGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::NOBASEFIX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::NOBLANKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::NOCDATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::NODICT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::NOENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::NOERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::NONET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::NOWARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::NOXINCNODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::NSCLEAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::OLD10') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::PEDANTIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::RECOVER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::SAX1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::STRICT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ParseOptions::XINCLUDE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Node', RubyLint.registry))

    klass.define_method('new')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('document')
      method.define_argument('name')
      method.define_argument('content')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::ProcessingInstruction::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('from_io')

    klass.define_method('from_memory')

    klass.define_instance_method('attribute')

    klass.define_instance_method('attribute_at')

    klass.define_instance_method('attribute_count')

    klass.define_instance_method('attribute_nodes')

    klass.define_instance_method('attributes')

    klass.define_instance_method('attributes?')

    klass.define_instance_method('base_uri')

    klass.define_instance_method('default?')

    klass.define_instance_method('depth')

    klass.define_instance_method('each')

    klass.define_instance_method('empty_element?')

    klass.define_instance_method('encoding')

    klass.define_instance_method('errors')

    klass.define_instance_method('errors=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('source')
      method.define_optional_argument('url')
      method.define_optional_argument('encoding')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inner_xml')

    klass.define_instance_method('lang')

    klass.define_instance_method('local_name')

    klass.define_instance_method('name')

    klass.define_instance_method('namespace_uri')

    klass.define_instance_method('namespaces')

    klass.define_instance_method('node_type')

    klass.define_instance_method('outer_xml')

    klass.define_instance_method('prefix')

    klass.define_instance_method('read')

    klass.define_instance_method('self_closing?')

    klass.define_instance_method('source')

    klass.define_instance_method('state')

    klass.define_instance_method('value')

    klass.define_instance_method('value?')

    klass.define_instance_method('xml_version')
  end

  defs.define_constant('Nokogiri::XML::Reader::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::Reader::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::Reader::TYPE_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_CDATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_COMMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_DOCUMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_DOCUMENT_FRAGMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_DOCUMENT_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_ELEMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_END_ELEMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_END_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_ENTITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_ENTITY_REFERENCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_NOTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_PROCESSING_INSTRUCTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_SIGNIFICANT_WHITESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_WHITESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Reader::TYPE_XML_DECLARATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::RelaxNG') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::Schema', RubyLint.registry))

    klass.define_method('from_document')

    klass.define_method('read_memory')
  end

  defs.define_constant('Nokogiri::XML::SAX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::SAX::Document') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cdata_block') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('characters') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('comment') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('end_document')

    klass.define_instance_method('end_element') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('end_element_namespace') do |method|
      method.define_argument('name')
      method.define_optional_argument('prefix')
      method.define_optional_argument('uri')
    end

    klass.define_instance_method('error') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('processing_instruction') do |method|
      method.define_argument('name')
      method.define_argument('content')
    end

    klass.define_instance_method('start_document')

    klass.define_instance_method('start_element') do |method|
      method.define_argument('name')
      method.define_optional_argument('attrs')
    end

    klass.define_instance_method('start_element_namespace') do |method|
      method.define_argument('name')
      method.define_optional_argument('attrs')
      method.define_optional_argument('prefix')
      method.define_optional_argument('uri')
      method.define_optional_argument('ns')
    end

    klass.define_instance_method('warning') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('xmldecl') do |method|
      method.define_argument('version')
      method.define_argument('encoding')
      method.define_argument('standalone')
    end
  end

  defs.define_constant('Nokogiri::XML::SAX::Parser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('document')

    klass.define_instance_method('document=')

    klass.define_instance_method('encoding')

    klass.define_instance_method('encoding=')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('doc')
      method.define_optional_argument('encoding')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('parse') do |method|
      method.define_argument('thing')
      method.define_block_argument('block')
    end

    klass.define_instance_method('parse_file') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('parse_io') do |method|
      method.define_argument('io')
      method.define_optional_argument('encoding')
    end

    klass.define_instance_method('parse_memory') do |method|
      method.define_argument('data')
    end
  end

  defs.define_constant('Nokogiri::XML::SAX::Parser::ENCODINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::SAX::ParserContext') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('file')

    klass.define_method('io')

    klass.define_method('memory')

    klass.define_method('new') do |method|
      method.define_argument('thing')
      method.define_optional_argument('encoding')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('column')

    klass.define_instance_method('line')

    klass.define_instance_method('parse_with')

    klass.define_instance_method('replace_entities')

    klass.define_instance_method('replace_entities=')
  end

  defs.define_constant('Nokogiri::XML::SAX::PushParser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('allocate')

    klass.define_instance_method('<<') do |method|
      method.define_argument('chunk')
      method.define_optional_argument('last_chunk')
    end

    klass.define_instance_method('document')

    klass.define_instance_method('document=')

    klass.define_instance_method('finish')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('doc')
      method.define_optional_argument('file_name')
      method.define_optional_argument('encoding')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('write') do |method|
      method.define_argument('chunk')
      method.define_optional_argument('last_chunk')
    end
  end

  defs.define_constant('Nokogiri::XML::Schema') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from_document')

    klass.define_method('new') do |method|
      method.define_argument('string_or_io')

      method.returns { |object| object.instance }
    end

    klass.define_method('read_memory')

    klass.define_instance_method('errors')

    klass.define_instance_method('errors=')

    klass.define_instance_method('valid?') do |method|
      method.define_argument('thing')
    end

    klass.define_instance_method('validate') do |method|
      method.define_argument('thing')
    end
  end

  defs.define_constant('Nokogiri::XML::SyntaxError') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::SyntaxError', RubyLint.registry))

    klass.define_instance_method('code')

    klass.define_instance_method('column')

    klass.define_instance_method('domain')

    klass.define_instance_method('error?')

    klass.define_instance_method('fatal?')

    klass.define_instance_method('file')

    klass.define_instance_method('int1')

    klass.define_instance_method('level')

    klass.define_instance_method('line')

    klass.define_instance_method('none?')

    klass.define_instance_method('str1')

    klass.define_instance_method('str2')

    klass.define_instance_method('str3')

    klass.define_instance_method('to_s')

    klass.define_instance_method('warning?')
  end

  defs.define_constant('Nokogiri::XML::Text') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::CharacterData', RubyLint.registry))

    klass.define_method('new')

    klass.define_instance_method('content=') do |method|
      method.define_argument('string')
    end
  end

  defs.define_constant('Nokogiri::XML::Text::ATTRIBUTE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::ATTRIBUTE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::CDATA_SECTION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::COMMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::DOCB_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::DOCUMENT_FRAG_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::DOCUMENT_TYPE_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::DTD_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::ELEMENT_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::ELEMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::ENTITY_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::ENTITY_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::ENTITY_REF_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::Enumerator') do |klass|
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

  defs.define_constant('Nokogiri::XML::Text::HTML_DOCUMENT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::NAMESPACE_DECL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::NOTATION_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::PI_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::SaveOptions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('as_html')

    klass.define_instance_method('as_html?')

    klass.define_instance_method('as_xhtml')

    klass.define_instance_method('as_xhtml?')

    klass.define_instance_method('as_xml')

    klass.define_instance_method('as_xml?')

    klass.define_instance_method('default_html')

    klass.define_instance_method('default_html?')

    klass.define_instance_method('default_xhtml')

    klass.define_instance_method('default_xhtml?')

    klass.define_instance_method('default_xml')

    klass.define_instance_method('default_xml?')

    klass.define_instance_method('format')

    klass.define_instance_method('format?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('no_declaration')

    klass.define_instance_method('no_declaration?')

    klass.define_instance_method('no_empty_tags')

    klass.define_instance_method('no_empty_tags?')

    klass.define_instance_method('no_xhtml')

    klass.define_instance_method('no_xhtml?')

    klass.define_instance_method('options')

    klass.define_instance_method('to_i')
  end

  defs.define_constant('Nokogiri::XML::Text::SortedElement') do |klass|
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

  defs.define_constant('Nokogiri::XML::Text::TEXT_NODE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::XINCLUDE_END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::Text::XINCLUDE_START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::XML_C14N_1_0') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::XML_C14N_1_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Nokogiri::XML::XPath') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('document')

    klass.define_instance_method('document=')
  end

  defs.define_constant('Nokogiri::XML::XPath::SyntaxError') do |klass|
    klass.inherits(defs.constant_proxy('Nokogiri::XML::SyntaxError', RubyLint.registry))

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Nokogiri::XML::XPathContext') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new')

    klass.define_instance_method('evaluate')

    klass.define_instance_method('register_namespaces') do |method|
      method.define_argument('namespaces')
    end

    klass.define_instance_method('register_ns')

    klass.define_instance_method('register_variable')
  end

  defs.define_constant('Nokogiri::XSLT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('parse') do |method|
      method.define_argument('string')
      method.define_optional_argument('modules')
    end

    klass.define_method('quote_params') do |method|
      method.define_argument('params')
    end

    klass.define_method('register')
  end

  defs.define_constant('Nokogiri::XSLT::Stylesheet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('parse_stylesheet_doc')

    klass.define_instance_method('apply_to') do |method|
      method.define_argument('document')
      method.define_optional_argument('params')
    end

    klass.define_instance_method('serialize')

    klass.define_instance_method('transform')
  end
end
