# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('ActiveRecord') do |defs|
  defs.define_constant('ActiveRecord') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('eager_load!')

    klass.define_method('version')
  end

  defs.define_constant('ActiveRecord::ActiveRecordError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::AdapterNotFound') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::AdapterNotSpecified') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Aggregations') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('clear_aggregation_cache')
  end

  defs.define_constant('ActiveRecord::Aggregations::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('composed_of') do |method|
      method.define_argument('part_id')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActiveRecord::AssociationRelation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Relation', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('table')
      method.define_argument('association')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('proxy_association')
  end

  defs.define_constant('ActiveRecord::AssociationRelation::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('const_missing') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('new') do |method|
      method.define_argument('klass')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveRecord::AssociationRelation::ClassSpecificRelation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::AssociationRelation::DeprecatedMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('all') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('apply_finder_options') do |method|
      method.define_argument('options')
      method.define_optional_argument('silence_deprecation')
    end

    klass.define_instance_method('calculate') do |method|
      method.define_argument('operation')
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('find_in_batches') do |method|
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('last') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('update_all_with_deprecated_options') do |method|
      method.define_argument('updates')
      method.define_optional_argument('conditions')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActiveRecord::AssociationRelation::HashMerger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('relation')
      method.define_argument('hash')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('merge')

    klass.define_instance_method('other')

    klass.define_instance_method('relation')
  end

  defs.define_constant('ActiveRecord::AssociationRelation::JoinOperation') do |klass|
    klass.inherits(defs.constant_proxy('Struct', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('join_class')

    klass.define_instance_method('join_class=')

    klass.define_instance_method('on')

    klass.define_instance_method('on=')

    klass.define_instance_method('relation')

    klass.define_instance_method('relation=')
  end

  defs.define_constant('ActiveRecord::AssociationRelation::MULTI_VALUE_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::AssociationRelation::Merger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('relation')
      method.define_argument('other')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('merge')

    klass.define_instance_method('normal_values')

    klass.define_instance_method('other')

    klass.define_instance_method('relation')

    klass.define_instance_method('values')
  end

  defs.define_constant('ActiveRecord::AssociationRelation::SINGLE_VALUE_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::AssociationRelation::VALID_FIND_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::AssociationRelation::VALID_UNSCOPING_VALUES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::AssociationRelation::VALUE_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::AssociationRelation::WhereChain') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('scope')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('not') do |method|
      method.define_argument('opts')
      method.define_rest_argument('rest')
    end
  end

  defs.define_constant('ActiveRecord::AssociationTypeMismatch') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Associations') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('association') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('association_cache')

    klass.define_instance_method('clear_association_cache')
  end

  defs.define_constant('ActiveRecord::Associations::AliasTracker') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('aliased_name_for') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('aliased_name')
    end

    klass.define_instance_method('aliased_table_for') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('aliased_name')
    end

    klass.define_instance_method('aliases')

    klass.define_instance_method('connection')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('connection')
      method.define_optional_argument('table_joins')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('table_joins')
  end

  defs.define_constant('ActiveRecord::Associations::Association') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('aliased_table_name')

    klass.define_instance_method('association_scope')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('initialize_attributes') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('interpolate') do |method|
      method.define_argument('sql')
      method.define_optional_argument('record')
    end

    klass.define_instance_method('inversed')

    klass.define_instance_method('inversed=')

    klass.define_instance_method('klass')

    klass.define_instance_method('load_target')

    klass.define_instance_method('loaded!')

    klass.define_instance_method('loaded?')

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('options') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('owner')

    klass.define_instance_method('reflection')

    klass.define_instance_method('reload')

    klass.define_instance_method('reset')

    klass.define_instance_method('reset_scope')

    klass.define_instance_method('scope')

    klass.define_instance_method('scoped')

    klass.define_instance_method('set_inverse_instance') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('stale_target?')

    klass.define_instance_method('target')

    klass.define_instance_method('target=') do |method|
      method.define_argument('target')
    end

    klass.define_instance_method('target_scope')
  end

  defs.define_constant('ActiveRecord::Associations::AssociationScope') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::JoinHelper', RubyLint.registry))

    klass.define_instance_method('active_record') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('alias_tracker')

    klass.define_instance_method('association')

    klass.define_instance_method('chain') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('association')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('interpolate') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('klass') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('options') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('owner') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('reflection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('scope')

    klass.define_instance_method('scope_chain') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('source_options') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Associations::BelongsToAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::SingularAssociation', RubyLint.registry))

    klass.define_instance_method('handle_dependency')

    klass.define_instance_method('replace') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('updated?')
  end

  defs.define_constant('ActiveRecord::Associations::BelongsToPolymorphicAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::BelongsToAssociation', RubyLint.registry))

    klass.define_instance_method('klass')
  end

  defs.define_constant('ActiveRecord::Associations::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('belongs_to') do |method|
      method.define_argument('name')
      method.define_optional_argument('scope')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('has_and_belongs_to_many') do |method|
      method.define_argument('name')
      method.define_optional_argument('scope')
      method.define_optional_argument('options')
      method.define_block_argument('extension')
    end

    klass.define_instance_method('has_many') do |method|
      method.define_argument('name')
      method.define_optional_argument('scope')
      method.define_optional_argument('options')
      method.define_block_argument('extension')
    end

    klass.define_instance_method('has_one') do |method|
      method.define_argument('name')
      method.define_optional_argument('scope')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActiveRecord::Associations::CollectionAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::Association', RubyLint.registry))

    klass.define_instance_method('add_to_target') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('any?')

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('concat') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('count') do |method|
      method.define_optional_argument('column_name')
      method.define_optional_argument('count_options')
    end

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('delete_all')

    klass.define_instance_method('destroy') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('destroy_all')

    klass.define_instance_method('distinct')

    klass.define_instance_method('empty?')

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('first') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('ids_reader')

    klass.define_instance_method('ids_writer') do |method|
      method.define_argument('ids')
    end

    klass.define_instance_method('include?') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('last') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('length')

    klass.define_instance_method('load_target')

    klass.define_instance_method('many?')

    klass.define_instance_method('null_scope?')

    klass.define_instance_method('reader') do |method|
      method.define_optional_argument('force_reload')
    end

    klass.define_instance_method('replace') do |method|
      method.define_argument('other_array')
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('scope') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('select') do |method|
      method.define_optional_argument('select')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('transaction') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('uniq')

    klass.define_instance_method('writer') do |method|
      method.define_argument('records')
    end
  end

  defs.define_constant('ActiveRecord::Associations::HasAndBelongsToManyAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::CollectionAssociation', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert_record') do |method|
      method.define_argument('record')
      method.define_optional_argument('validate')
      method.define_optional_argument('raise')
    end

    klass.define_instance_method('join_table')
  end

  defs.define_constant('ActiveRecord::Associations::HasManyAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::CollectionAssociation', RubyLint.registry))

    klass.define_instance_method('handle_dependency')

    klass.define_instance_method('insert_record') do |method|
      method.define_argument('record')
      method.define_optional_argument('validate')
      method.define_optional_argument('raise')
    end
  end

  defs.define_constant('ActiveRecord::Associations::HasManyThroughAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::HasManyAssociation', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::ThroughAssociation', RubyLint.registry))

    klass.define_instance_method('concat') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('concat_records') do |method|
      method.define_argument('records')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert_record') do |method|
      method.define_argument('record')
      method.define_optional_argument('validate')
      method.define_optional_argument('raise')
    end

    klass.define_instance_method('size')
  end

  defs.define_constant('ActiveRecord::Associations::HasOneAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::SingularAssociation', RubyLint.registry))

    klass.define_instance_method('delete') do |method|
      method.define_optional_argument('method')
    end

    klass.define_instance_method('handle_dependency')

    klass.define_instance_method('replace') do |method|
      method.define_argument('record')
      method.define_optional_argument('save')
    end
  end

  defs.define_constant('ActiveRecord::Associations::HasOneThroughAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::HasOneAssociation', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::ThroughAssociation', RubyLint.registry))

    klass.define_instance_method('replace') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::Associations::JoinHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('join_type')
  end

  defs.define_constant('ActiveRecord::Associations::SingularAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::Association', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('reader') do |method|
      method.define_optional_argument('force_reload')
    end

    klass.define_instance_method('writer') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::Associations::ThroughAssociation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('chain') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('source_reflection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('target_scope')

    klass.define_instance_method('through_reflection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::AttributeAssignment') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assign_attributes') do |method|
      method.define_argument('new_attributes')
    end

    klass.define_instance_method('attributes=') do |method|
      method.define_argument('new_attributes')
    end
  end

  defs.define_constant('ActiveRecord::AttributeAssignment::MultiparameterAttribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('column')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('object')
      method.define_argument('name')
      method.define_argument('values')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('object')

    klass.define_instance_method('read_value')

    klass.define_instance_method('values')
  end

  defs.define_constant('ActiveRecord::AttributeAssignmentError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('attribute')

    klass.define_instance_method('exception')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('message')
      method.define_argument('exception')
      method.define_argument('attribute')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::AttributeMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('attr_name')
      method.define_argument('value')
    end

    klass.define_instance_method('arel_attributes_with_values_for_create') do |method|
      method.define_argument('attribute_names')
    end

    klass.define_instance_method('arel_attributes_with_values_for_update') do |method|
      method.define_argument('attribute_names')
    end

    klass.define_instance_method('attribute_for_inspect') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('attribute_method?') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('attribute_missing') do |method|
      method.define_argument('match')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('attribute_names')

    klass.define_instance_method('attribute_present?') do |method|
      method.define_argument('attribute')
    end

    klass.define_instance_method('attributes')

    klass.define_instance_method('clone_attribute_value') do |method|
      method.define_argument('reader_method')
      method.define_argument('attribute_name')
    end

    klass.define_instance_method('clone_attributes') do |method|
      method.define_optional_argument('reader_method')
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('column_for_attribute') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('has_attribute?') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
      method.define_optional_argument('include_private')
    end
  end

  defs.define_constant('ActiveRecord::AttributeMethods::BeforeTypeCast') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attributes_before_type_cast')

    klass.define_instance_method('read_attribute_before_type_cast') do |method|
      method.define_argument('attr_name')
    end
  end

  defs.define_constant('ActiveRecord::AttributeMethods::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attribute_method?') do |method|
      method.define_argument('attribute')
    end

    klass.define_instance_method('attribute_methods_generated?')

    klass.define_instance_method('attribute_names')

    klass.define_instance_method('dangerous_attribute_method?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('define_attribute_methods')

    klass.define_instance_method('inherited') do |method|
      method.define_argument('child_class')
    end

    klass.define_instance_method('initialize_generated_modules')

    klass.define_instance_method('instance_method_already_implemented?') do |method|
      method.define_argument('method_name')
    end

    klass.define_instance_method('method_defined_within?') do |method|
      method.define_argument('name')
      method.define_argument('klass')
      method.define_optional_argument('sup')
    end

    klass.define_instance_method('undefine_attribute_methods')
  end

  defs.define_constant('ActiveRecord::AttributeMethods::Dirty') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('reload') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('save') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('save!') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('ActiveRecord::AttributeMethods::Query') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('query_attribute') do |method|
      method.define_argument('attr_name')
    end
  end

  defs.define_constant('ActiveRecord::AutosaveAssociation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('changed_for_autosave?')

    klass.define_instance_method('destroyed_by_association')

    klass.define_instance_method('destroyed_by_association=') do |method|
      method.define_argument('reflection')
    end

    klass.define_instance_method('mark_for_destruction')

    klass.define_instance_method('marked_for_destruction?')

    klass.define_instance_method('reload') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActiveRecord::AutosaveAssociation::AssociationBuilderExtension') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('build')
  end

  defs.define_constant('ActiveRecord::AutosaveAssociation::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Core', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Store', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Serialization', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Serializers::Xml', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Serializers::JSON', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Serialization', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Reflection', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Transactions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Aggregations', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::NestedAttributes', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AutosaveAssociation', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::SecurePassword', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Timestamp', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::Callbacks', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Callbacks', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AttributeMethods::Serialization', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AttributeMethods::Dirty', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Dirty', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AttributeMethods::TimeZoneConversion', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AttributeMethods::PrimaryKey', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AttributeMethods::Query', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AttributeMethods::BeforeTypeCast', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AttributeMethods::Write', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AttributeMethods::Read', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AttributeMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::AttributeMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Locking::Pessimistic', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Locking::Optimistic', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::CounterCache', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Validations', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::HelperMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Callbacks', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Validations', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Integration', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Conversion', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::AttributeAssignment', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::ForbiddenAttributesProtection', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::DeprecatedMassAssignmentSecurity', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Sanitization', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Scoping::Named', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Scoping::Default', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Scoping', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Inheritance', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::ModelSchema', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::ReadonlyAttributes', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Persistence', RubyLint.registry))

    klass.define_method('_attr_readonly')

    klass.define_method('_attr_readonly=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_attr_readonly?')

    klass.define_method('_commit_callbacks')

    klass.define_method('_commit_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_commit_callbacks?')

    klass.define_method('_create_callbacks')

    klass.define_method('_create_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_create_callbacks?')

    klass.define_method('_destroy_callbacks')

    klass.define_method('_destroy_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_destroy_callbacks?')

    klass.define_method('_find_callbacks')

    klass.define_method('_find_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_find_callbacks?')

    klass.define_method('_initialize_callbacks')

    klass.define_method('_initialize_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_initialize_callbacks?')

    klass.define_method('_rollback_callbacks')

    klass.define_method('_rollback_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_rollback_callbacks?')

    klass.define_method('_save_callbacks')

    klass.define_method('_save_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_save_callbacks?')

    klass.define_method('_touch_callbacks')

    klass.define_method('_touch_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_touch_callbacks?')

    klass.define_method('_update_callbacks')

    klass.define_method('_update_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_update_callbacks?')

    klass.define_method('_validate_callbacks')

    klass.define_method('_validate_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_validate_callbacks?')

    klass.define_method('_validation_callbacks')

    klass.define_method('_validation_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_validation_callbacks?')

    klass.define_method('_validators')

    klass.define_method('_validators=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_validators?')

    klass.define_method('after_create') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('after_destroy') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('after_find') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('after_initialize') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('after_save') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('after_touch') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('after_update') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('around_create') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('around_destroy') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('around_save') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('around_update') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('attribute_aliases')

    klass.define_method('attribute_aliases=') do |method|
      method.define_argument('val')
    end

    klass.define_method('attribute_aliases?')

    klass.define_method('attribute_method_matchers')

    klass.define_method('attribute_method_matchers=') do |method|
      method.define_argument('val')
    end

    klass.define_method('attribute_method_matchers?')

    klass.define_method('attribute_types_cached_by_default')

    klass.define_method('attribute_types_cached_by_default=') do |method|
      method.define_argument('val')
    end

    klass.define_method('attribute_types_cached_by_default?')

    klass.define_method('before_create') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('before_destroy') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('before_save') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('before_update') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('cache_timestamp_format')

    klass.define_method('cache_timestamp_format=') do |method|
      method.define_argument('val')
    end

    klass.define_method('cache_timestamp_format?')

    klass.define_method('configurations')

    klass.define_method('configurations=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('connection_handler')

    klass.define_method('connection_handler=') do |method|
      method.define_argument('handler')
    end

    klass.define_method('default_connection_handler')

    klass.define_method('default_connection_handler=') do |method|
      method.define_argument('val')
    end

    klass.define_method('default_connection_handler?')

    klass.define_method('default_scopes')

    klass.define_method('default_scopes=') do |method|
      method.define_argument('val')
    end

    klass.define_method('default_scopes?')

    klass.define_method('default_timezone')

    klass.define_method('default_timezone=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('disable_implicit_join_references')

    klass.define_method('disable_implicit_join_references=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('include_root_in_json')

    klass.define_method('include_root_in_json=') do |method|
      method.define_argument('val')
    end

    klass.define_method('include_root_in_json?')

    klass.define_method('lock_optimistically')

    klass.define_method('lock_optimistically=') do |method|
      method.define_argument('val')
    end

    klass.define_method('lock_optimistically?')

    klass.define_method('logger')

    klass.define_method('logger=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('nested_attributes_options')

    klass.define_method('nested_attributes_options=') do |method|
      method.define_argument('val')
    end

    klass.define_method('nested_attributes_options?')

    klass.define_method('partial_updates') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('partial_updates=') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('partial_updates?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('partial_updates_with_deprecation') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('partial_updates_with_deprecation=') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('partial_updates_with_deprecation?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('partial_updates_without_deprecation')

    klass.define_method('partial_updates_without_deprecation=') do |method|
      method.define_argument('v')
    end

    klass.define_method('partial_updates_without_deprecation?')

    klass.define_method('partial_writes')

    klass.define_method('partial_writes=') do |method|
      method.define_argument('val')
    end

    klass.define_method('partial_writes?')

    klass.define_method('pluralize_table_names')

    klass.define_method('pluralize_table_names=') do |method|
      method.define_argument('val')
    end

    klass.define_method('pluralize_table_names?')

    klass.define_method('primary_key_prefix_type')

    klass.define_method('primary_key_prefix_type=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('record_timestamps')

    klass.define_method('record_timestamps=') do |method|
      method.define_argument('val')
    end

    klass.define_method('record_timestamps?')

    klass.define_method('reflections')

    klass.define_method('reflections=') do |method|
      method.define_argument('val')
    end

    klass.define_method('reflections?')

    klass.define_method('schema_format')

    klass.define_method('schema_format=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('serialized_attributes')

    klass.define_method('serialized_attributes=') do |method|
      method.define_argument('val')
    end

    klass.define_method('serialized_attributes?')

    klass.define_method('skip_time_zone_conversion_for_attributes')

    klass.define_method('skip_time_zone_conversion_for_attributes=') do |method|
      method.define_argument('val')
    end

    klass.define_method('skip_time_zone_conversion_for_attributes?')

    klass.define_method('store_full_sti_class')

    klass.define_method('store_full_sti_class=') do |method|
      method.define_argument('val')
    end

    klass.define_method('store_full_sti_class?')

    klass.define_method('stored_attributes')

    klass.define_method('stored_attributes=') do |method|
      method.define_argument('val')
    end

    klass.define_method('stored_attributes?')

    klass.define_method('table_name_prefix')

    klass.define_method('table_name_prefix=') do |method|
      method.define_argument('val')
    end

    klass.define_method('table_name_prefix?')

    klass.define_method('table_name_suffix')

    klass.define_method('table_name_suffix=') do |method|
      method.define_argument('val')
    end

    klass.define_method('table_name_suffix?')

    klass.define_method('time_zone_aware_attributes')

    klass.define_method('time_zone_aware_attributes=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('timestamped_migrations')

    klass.define_method('timestamped_migrations=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('_commit_callbacks')

    klass.define_instance_method('_commit_callbacks=')

    klass.define_instance_method('_commit_callbacks?')

    klass.define_instance_method('_create_callbacks')

    klass.define_instance_method('_create_callbacks=')

    klass.define_instance_method('_create_callbacks?')

    klass.define_instance_method('_destroy_callbacks')

    klass.define_instance_method('_destroy_callbacks=')

    klass.define_instance_method('_destroy_callbacks?')

    klass.define_instance_method('_find_callbacks')

    klass.define_instance_method('_find_callbacks=')

    klass.define_instance_method('_find_callbacks?')

    klass.define_instance_method('_initialize_callbacks')

    klass.define_instance_method('_initialize_callbacks=')

    klass.define_instance_method('_initialize_callbacks?')

    klass.define_instance_method('_rollback_callbacks')

    klass.define_instance_method('_rollback_callbacks=')

    klass.define_instance_method('_rollback_callbacks?')

    klass.define_instance_method('_save_callbacks')

    klass.define_instance_method('_save_callbacks=')

    klass.define_instance_method('_save_callbacks?')

    klass.define_instance_method('_touch_callbacks')

    klass.define_instance_method('_touch_callbacks=')

    klass.define_instance_method('_touch_callbacks?')

    klass.define_instance_method('_update_callbacks')

    klass.define_instance_method('_update_callbacks=')

    klass.define_instance_method('_update_callbacks?')

    klass.define_instance_method('_validate_callbacks')

    klass.define_instance_method('_validate_callbacks=')

    klass.define_instance_method('_validate_callbacks?')

    klass.define_instance_method('_validation_callbacks')

    klass.define_instance_method('_validation_callbacks=')

    klass.define_instance_method('_validation_callbacks?')

    klass.define_instance_method('_validators')

    klass.define_instance_method('_validators=')

    klass.define_instance_method('_validators?')

    klass.define_instance_method('attribute_aliases')

    klass.define_instance_method('attribute_aliases?')

    klass.define_instance_method('attribute_method_matchers')

    klass.define_instance_method('attribute_method_matchers?')

    klass.define_instance_method('attribute_types_cached_by_default')

    klass.define_instance_method('attribute_types_cached_by_default?')

    klass.define_instance_method('cache_timestamp_format')

    klass.define_instance_method('cache_timestamp_format?')

    klass.define_instance_method('configurations')

    klass.define_instance_method('default_connection_handler')

    klass.define_instance_method('default_connection_handler?')

    klass.define_instance_method('default_scopes')

    klass.define_instance_method('default_timezone')

    klass.define_instance_method('disable_implicit_join_references')

    klass.define_instance_method('include_root_in_json')

    klass.define_instance_method('include_root_in_json=')

    klass.define_instance_method('include_root_in_json?')

    klass.define_instance_method('lock_optimistically')

    klass.define_instance_method('lock_optimistically?')

    klass.define_instance_method('logger')

    klass.define_instance_method('nested_attributes_options')

    klass.define_instance_method('nested_attributes_options?')

    klass.define_instance_method('partial_writes')

    klass.define_instance_method('partial_writes?')

    klass.define_instance_method('pluralize_table_names')

    klass.define_instance_method('pluralize_table_names?')

    klass.define_instance_method('primary_key_prefix_type')

    klass.define_instance_method('record_timestamps')

    klass.define_instance_method('record_timestamps=')

    klass.define_instance_method('record_timestamps?')

    klass.define_instance_method('reflections')

    klass.define_instance_method('reflections=')

    klass.define_instance_method('reflections?')

    klass.define_instance_method('schema_format')

    klass.define_instance_method('skip_time_zone_conversion_for_attributes')

    klass.define_instance_method('skip_time_zone_conversion_for_attributes?')

    klass.define_instance_method('store_full_sti_class')

    klass.define_instance_method('store_full_sti_class?')

    klass.define_instance_method('table_name_prefix')

    klass.define_instance_method('table_name_prefix?')

    klass.define_instance_method('table_name_suffix')

    klass.define_instance_method('table_name_suffix?')

    klass.define_instance_method('time_zone_aware_attributes')

    klass.define_instance_method('timestamped_migrations')

    klass.define_instance_method('validation_context')

    klass.define_instance_method('validation_context=')
  end

  defs.define_constant('ActiveRecord::Base::ACTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::ATTRIBUTE_TYPES_CACHED_BY_DEFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::AbsenceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attr_name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::AcceptanceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('setup') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::AggregateReflection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Reflection::MacroReflection', RubyLint.registry))

    klass.define_instance_method('mapping')
  end

  defs.define_constant('ActiveRecord::Base::AliasTracker') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('aliased_name_for') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('aliased_name')
    end

    klass.define_instance_method('aliased_table_for') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('aliased_name')
    end

    klass.define_instance_method('aliases')

    klass.define_instance_method('connection')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('connection')
      method.define_optional_argument('table_joins')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('table_joins')
  end

  defs.define_constant('ActiveRecord::Base::AssociatedValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::Association') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('aliased_table_name')

    klass.define_instance_method('association_scope')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('initialize_attributes') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('interpolate') do |method|
      method.define_argument('sql')
      method.define_optional_argument('record')
    end

    klass.define_instance_method('inversed')

    klass.define_instance_method('inversed=')

    klass.define_instance_method('klass')

    klass.define_instance_method('load_target')

    klass.define_instance_method('loaded!')

    klass.define_instance_method('loaded?')

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('options') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('owner')

    klass.define_instance_method('reflection')

    klass.define_instance_method('reload')

    klass.define_instance_method('reset')

    klass.define_instance_method('reset_scope')

    klass.define_instance_method('scope')

    klass.define_instance_method('scoped')

    klass.define_instance_method('set_inverse_instance') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('stale_target?')

    klass.define_instance_method('target')

    klass.define_instance_method('target=') do |method|
      method.define_argument('target')
    end

    klass.define_instance_method('target_scope')
  end

  defs.define_constant('ActiveRecord::Base::AssociationBuilderExtension') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('build')
  end

  defs.define_constant('ActiveRecord::Base::AssociationReflection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Reflection::MacroReflection', RubyLint.registry))

    klass.define_instance_method('active_record_primary_key')

    klass.define_instance_method('association_class')

    klass.define_instance_method('association_foreign_key')

    klass.define_instance_method('association_primary_key') do |method|
      method.define_optional_argument('klass')
    end

    klass.define_instance_method('belongs_to?')

    klass.define_instance_method('build_association') do |method|
      method.define_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('check_validity_of_inverse!')

    klass.define_instance_method('collection?')

    klass.define_instance_method('columns') do |method|
      method.define_argument('tbl_name')
    end

    klass.define_instance_method('counter_cache_column')

    klass.define_instance_method('foreign_key')

    klass.define_instance_method('foreign_type')

    klass.define_instance_method('has_and_belongs_to_many?')

    klass.define_instance_method('has_inverse?')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inverse_of')

    klass.define_instance_method('join_table')

    klass.define_instance_method('klass')

    klass.define_instance_method('nested?')

    klass.define_instance_method('polymorphic?')

    klass.define_instance_method('polymorphic_inverse_of') do |method|
      method.define_argument('associated_class')
    end

    klass.define_instance_method('primary_key_column')

    klass.define_instance_method('quoted_table_name')

    klass.define_instance_method('reset_column_information')

    klass.define_instance_method('scope_chain')

    klass.define_instance_method('source_macro')

    klass.define_instance_method('source_reflection')

    klass.define_instance_method('table_name')

    klass.define_instance_method('through_reflection')

    klass.define_instance_method('type')

    klass.define_instance_method('validate?')
  end

  defs.define_constant('ActiveRecord::Base::AssociationScope') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::JoinHelper', RubyLint.registry))

    klass.define_instance_method('active_record') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('alias_tracker')

    klass.define_instance_method('association')

    klass.define_instance_method('chain') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('association')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('interpolate') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('klass') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('options') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('owner') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('reflection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('scope')

    klass.define_instance_method('scope_chain') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('source_options') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Base::AttrNames') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('set_name_cache') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::Attribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('serialize')

    klass.define_instance_method('serialized_value')

    klass.define_instance_method('unserialize') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('unserialized_value') do |method|
      method.define_optional_argument('v')
    end
  end

  defs.define_constant('ActiveRecord::Base::BeforeTypeCast') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attributes_before_type_cast')

    klass.define_instance_method('read_attribute_before_type_cast') do |method|
      method.define_argument('attr_name')
    end
  end

  defs.define_constant('ActiveRecord::Base::Behavior') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_field_changed?') do |method|
      method.define_argument('attr')
      method.define_argument('old')
      method.define_argument('value')
    end

    klass.define_instance_method('attributes_before_type_cast')

    klass.define_instance_method('read_attribute_before_type_cast') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('type_cast_attribute_for_write') do |method|
      method.define_argument('column')
      method.define_argument('value')
    end

    klass.define_instance_method('typecasted_attribute_value') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('ActiveRecord::Base::BelongsToAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::SingularAssociation', RubyLint.registry))

    klass.define_instance_method('handle_dependency')

    klass.define_instance_method('replace') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('updated?')
  end

  defs.define_constant('ActiveRecord::Base::BelongsToPolymorphicAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::BelongsToAssociation', RubyLint.registry))

    klass.define_instance_method('klass')
  end

  defs.define_constant('ActiveRecord::Base::Builder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::CALLBACKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::CALL_COMPILABLE_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_update_filter') do |method|
      method.define_argument('filter_options')
      method.define_argument('new_options')
    end

    klass.define_instance_method('apply') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('chain=')

    klass.define_instance_method('clone') do |method|
      method.define_argument('chain')
      method.define_argument('klass')
    end

    klass.define_instance_method('deprecate_per_key_option') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('duplicates?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('chain')
      method.define_argument('filter')
      method.define_argument('kind')
      method.define_argument('options')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('kind=')

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('_kind')
      method.define_argument('_filter')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_id')

    klass.define_instance_method('normalize_options!') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('raw_filter')

    klass.define_instance_method('raw_filter=')

    klass.define_instance_method('recompile!') do |method|
      method.define_argument('_options')
    end
  end

  defs.define_constant('ActiveRecord::Base::CallbackChain') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('compile')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('ActiveRecord::Base::Callbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('run_validations!')
  end

  defs.define_constant('ActiveRecord::Base::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('===') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('arel_engine')

    klass.define_instance_method('arel_table')

    klass.define_instance_method('generated_feature_methods')

    klass.define_instance_method('initialize_generated_modules')

    klass.define_instance_method('inspect')
  end

  defs.define_constant('ActiveRecord::Base::Clusivity') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('check_validity!')
  end

  defs.define_constant('ActiveRecord::Base::CollectionAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::Association', RubyLint.registry))

    klass.define_instance_method('add_to_target') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('any?')

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('concat') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('count') do |method|
      method.define_optional_argument('column_name')
      method.define_optional_argument('count_options')
    end

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('delete_all')

    klass.define_instance_method('destroy') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('destroy_all')

    klass.define_instance_method('distinct')

    klass.define_instance_method('empty?')

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('first') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('ids_reader')

    klass.define_instance_method('ids_writer') do |method|
      method.define_argument('ids')
    end

    klass.define_instance_method('include?') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('last') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('length')

    klass.define_instance_method('load_target')

    klass.define_instance_method('many?')

    klass.define_instance_method('null_scope?')

    klass.define_instance_method('reader') do |method|
      method.define_optional_argument('force_reload')
    end

    klass.define_instance_method('replace') do |method|
      method.define_argument('other_array')
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('scope') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('select') do |method|
      method.define_optional_argument('select')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('transaction') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('uniq')

    klass.define_instance_method('writer') do |method|
      method.define_argument('records')
    end
  end

  defs.define_constant('ActiveRecord::Base::CollectionProxy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Relation', RubyLint.registry))

    klass.define_method('inherited') do |method|
      method.define_argument('subclass')
    end

    klass.define_instance_method('<<') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('any?') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('average') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('calculate') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('concat') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('count') do |method|
      method.define_optional_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('delete_all')

    klass.define_instance_method('destroy') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('destroy_all')

    klass.define_instance_method('distinct')

    klass.define_instance_method('empty?')

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('ids') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('include?') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('association')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('last') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('length')

    klass.define_instance_method('load_target')

    klass.define_instance_method('loaded?')

    klass.define_instance_method('many?') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('maximum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('minimum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('new') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('proxy_association')

    klass.define_instance_method('push') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('reload')

    klass.define_instance_method('replace') do |method|
      method.define_argument('other_array')
    end

    klass.define_instance_method('scope')

    klass.define_instance_method('scoping')

    klass.define_instance_method('select') do |method|
      method.define_optional_argument('select')
      method.define_block_argument('block')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('spawn')

    klass.define_instance_method('sum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('target')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_ary')

    klass.define_instance_method('uniq')
  end

  defs.define_constant('ActiveRecord::Base::ConfirmationValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('setup') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::Default') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::Dirty') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('reload') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('save') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('save!') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('ActiveRecord::Base::ExclusionValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::Clusivity', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::FormatValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::HasAndBelongsToManyAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::CollectionAssociation', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert_record') do |method|
      method.define_argument('record')
      method.define_optional_argument('validate')
      method.define_optional_argument('raise')
    end

    klass.define_instance_method('join_table')
  end

  defs.define_constant('ActiveRecord::Base::HasManyAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::CollectionAssociation', RubyLint.registry))

    klass.define_instance_method('handle_dependency')

    klass.define_instance_method('insert_record') do |method|
      method.define_argument('record')
      method.define_optional_argument('validate')
      method.define_optional_argument('raise')
    end
  end

  defs.define_constant('ActiveRecord::Base::HasManyThroughAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::HasManyAssociation', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::ThroughAssociation', RubyLint.registry))

    klass.define_instance_method('concat') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('concat_records') do |method|
      method.define_argument('records')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert_record') do |method|
      method.define_argument('record')
      method.define_optional_argument('validate')
      method.define_optional_argument('raise')
    end

    klass.define_instance_method('size')
  end

  defs.define_constant('ActiveRecord::Base::HasOneAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::SingularAssociation', RubyLint.registry))

    klass.define_instance_method('delete') do |method|
      method.define_optional_argument('method')
    end

    klass.define_instance_method('handle_dependency')

    klass.define_instance_method('replace') do |method|
      method.define_argument('record')
      method.define_optional_argument('save')
    end
  end

  defs.define_constant('ActiveRecord::Base::HasOneThroughAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::HasOneAssociation', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::ThroughAssociation', RubyLint.registry))

    klass.define_instance_method('replace') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::Base::HelperMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validates_absence_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_acceptance_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_confirmation_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_exclusion_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_format_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_inclusion_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_length_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_numericality_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_presence_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_size_of') do |method|
      method.define_rest_argument('attr_names')
    end
  end

  defs.define_constant('ActiveRecord::Base::InclusionValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::Clusivity', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::IndifferentCoder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('as_indifferent_hash') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('dump') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('coder_or_class_name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load') do |method|
      method.define_argument('yaml')
    end
  end

  defs.define_constant('ActiveRecord::Base::InstanceMethodsOnActivation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('authenticate') do |method|
      method.define_argument('unencrypted_password')
    end

    klass.define_instance_method('password=') do |method|
      method.define_argument('unencrypted_password')
    end

    klass.define_instance_method('password_confirmation=') do |method|
      method.define_argument('unencrypted_password')
    end
  end

  defs.define_constant('ActiveRecord::Base::JoinDependency') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('alias_tracker')

    klass.define_instance_method('base_klass')

    klass.define_instance_method('build') do |method|
      method.define_argument('associations')
      method.define_optional_argument('parent')
      method.define_optional_argument('join_type')
    end

    klass.define_instance_method('build_join_association') do |method|
      method.define_argument('reflection')
      method.define_argument('parent')
    end

    klass.define_instance_method('cache_joined_association') do |method|
      method.define_argument('association')
    end

    klass.define_instance_method('columns')

    klass.define_instance_method('construct') do |method|
      method.define_argument('parent')
      method.define_argument('associations')
      method.define_argument('join_parts')
      method.define_argument('row')
    end

    klass.define_instance_method('construct_association') do |method|
      method.define_argument('record')
      method.define_argument('join_part')
      method.define_argument('row')
    end

    klass.define_instance_method('find_join_association') do |method|
      method.define_argument('name_or_reflection')
      method.define_argument('parent')
    end

    klass.define_instance_method('graft') do |method|
      method.define_rest_argument('associations')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('associations')
      method.define_argument('joins')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('instantiate') do |method|
      method.define_argument('rows')
    end

    klass.define_instance_method('join_associations')

    klass.define_instance_method('join_base')

    klass.define_instance_method('join_parts')

    klass.define_instance_method('reflections')

    klass.define_instance_method('remove_duplicate_results!') do |method|
      method.define_argument('base')
      method.define_argument('records')
      method.define_argument('associations')
    end

    klass.define_instance_method('remove_uniq_by_reflection') do |method|
      method.define_argument('reflection')
      method.define_argument('records')
    end

    klass.define_instance_method('set_target_and_inverse') do |method|
      method.define_argument('join_part')
      method.define_argument('association')
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::Base::JoinHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('join_type')
  end

  defs.define_constant('ActiveRecord::Base::LengthValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::MacroReflection') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other_aggregation')
    end

    klass.define_instance_method('active_record')

    klass.define_instance_method('class_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('macro')
      method.define_argument('name')
      method.define_argument('scope')
      method.define_argument('options')
      method.define_argument('active_record')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('macro')

    klass.define_instance_method('name')

    klass.define_instance_method('options')

    klass.define_instance_method('plural_name')

    klass.define_instance_method('scope')
  end

  defs.define_constant('ActiveRecord::Base::MultiparameterAttribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('column')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('object')
      method.define_argument('name')
      method.define_argument('values')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('object')

    klass.define_instance_method('read_value')

    klass.define_instance_method('values')
  end

  defs.define_constant('ActiveRecord::Base::NAME_COMPILABLE_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::Named') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::NumericalityValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('filtered_options') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('parse_raw_value_as_a_number') do |method|
      method.define_argument('raw_value')
    end

    klass.define_instance_method('parse_raw_value_as_an_integer') do |method|
      method.define_argument('raw_value')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attr_name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::Preloader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('associations')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('records')
      method.define_argument('associations')
      method.define_optional_argument('preload_scope')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('model')

    klass.define_instance_method('preload_scope')

    klass.define_instance_method('records')

    klass.define_instance_method('run')
  end

  defs.define_constant('ActiveRecord::Base::PresenceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::PresenceValidator', RubyLint.registry))

    klass.define_instance_method('validate') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::Base::PrimaryKey') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attribute_method?') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('id')

    klass.define_instance_method('id=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('id?')

    klass.define_instance_method('id_before_type_cast')

    klass.define_instance_method('to_key')
  end

  defs.define_constant('ActiveRecord::Base::Query') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('query_attribute') do |method|
      method.define_argument('attr_name')
    end
  end

  defs.define_constant('ActiveRecord::Base::Read') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('read_attribute') do |method|
      method.define_argument('attr_name')
    end
  end

  defs.define_constant('ActiveRecord::Base::ScopeRegistry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('set_value_for') do |method|
      method.define_argument('scope_type')
      method.define_argument('variable_name')
      method.define_argument('value')
    end

    klass.define_instance_method('value_for') do |method|
      method.define_argument('scope_type')
      method.define_argument('variable_name')
    end
  end

  defs.define_constant('ActiveRecord::Base::Serialization') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('serialized_attributes')
  end

  defs.define_constant('ActiveRecord::Base::Serializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('serializable')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')

    klass.define_instance_method('serializable_collection')

    klass.define_instance_method('serializable_hash')

    klass.define_instance_method('serialize')
  end

  defs.define_constant('ActiveRecord::Base::SingularAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::Association', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('reader') do |method|
      method.define_optional_argument('force_reload')
    end

    klass.define_instance_method('writer') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::Base::ThroughAssociation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('chain') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('source_reflection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('target_scope')

    klass.define_instance_method('through_reflection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Base::ThroughReflection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Reflection::AssociationReflection', RubyLint.registry))

    klass.define_instance_method('active_record_primary_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('association_foreign_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('association_primary_key') do |method|
      method.define_optional_argument('klass')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('foreign_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('foreign_type') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('nested?')

    klass.define_instance_method('scope_chain')

    klass.define_instance_method('source_macro')

    klass.define_instance_method('source_options')

    klass.define_instance_method('source_reflection')

    klass.define_instance_method('source_reflection_names')

    klass.define_instance_method('through_options')

    klass.define_instance_method('through_reflection')

    klass.define_instance_method('type') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Base::TimeZoneConversion') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::TooManyRecords') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::TransactionError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::Type') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('column')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('type')

    klass.define_instance_method('type_cast') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::UNASSIGNABLE_KEYS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Base::UniquenessValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('build_relation') do |method|
      method.define_argument('klass')
      method.define_argument('table')
      method.define_argument('attribute')
      method.define_argument('value')
    end

    klass.define_instance_method('deserialize_attribute') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end

    klass.define_instance_method('find_finder_class_for') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('scope_relation') do |method|
      method.define_argument('record')
      method.define_argument('table')
      method.define_argument('relation')
    end

    klass.define_instance_method('setup') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Base::WithValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attr')
      method.define_argument('val')
    end
  end

  defs.define_constant('ActiveRecord::Base::Write') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('raw_write_attribute') do |method|
      method.define_argument('attr_name')
      method.define_argument('value')
    end

    klass.define_instance_method('write_attribute') do |method|
      method.define_argument('attr_name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Batches') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('find_each') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('find_in_batches') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActiveRecord::Calculations') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('average') do |method|
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('calculate') do |method|
      method.define_argument('operation')
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('count') do |method|
      method.define_optional_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('ids')

    klass.define_instance_method('maximum') do |method|
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('minimum') do |method|
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('column_names')
    end

    klass.define_instance_method('sum') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveRecord::Callbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('destroy')

    klass.define_instance_method('touch') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('ActiveRecord::Callbacks::CALLBACKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Callbacks::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Coders') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Coders::YAMLColumn') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('dump') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('object_class')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load') do |method|
      method.define_argument('yaml')
    end

    klass.define_instance_method('object_class')

    klass.define_instance_method('object_class=')
  end

  defs.define_constant('ActiveRecord::ConfigurationError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::AbstractAdapter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::ConnectionAdapters::ColumnDumper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('MonitorMixin', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Callbacks', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::ConnectionAdapters::QueryCache', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::ConnectionAdapters::DatabaseLimits', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::ConnectionAdapters::Quoting', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::ConnectionAdapters::DatabaseStatements', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::ConnectionAdapters::SchemaStatements', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Migration::JoinTable', RubyLint.registry))

    klass.define_method('_checkin_callbacks')

    klass.define_method('_checkin_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_checkin_callbacks?')

    klass.define_method('_checkout_callbacks')

    klass.define_method('_checkout_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_checkout_callbacks?')

    klass.define_method('type_cast_config_to_boolean') do |method|
      method.define_argument('config')
    end

    klass.define_method('type_cast_config_to_integer') do |method|
      method.define_argument('config')
    end

    klass.define_instance_method('_checkin_callbacks')

    klass.define_instance_method('_checkin_callbacks=')

    klass.define_instance_method('_checkin_callbacks?')

    klass.define_instance_method('_checkout_callbacks')

    klass.define_instance_method('_checkout_callbacks=')

    klass.define_instance_method('_checkout_callbacks?')

    klass.define_instance_method('active?')

    klass.define_instance_method('adapter_name')

    klass.define_instance_method('case_insensitive_comparison') do |method|
      method.define_argument('table')
      method.define_argument('attribute')
      method.define_argument('column')
      method.define_argument('value')
    end

    klass.define_instance_method('case_sensitive_modifier') do |method|
      method.define_argument('node')
    end

    klass.define_instance_method('clear_cache!')

    klass.define_instance_method('close')

    klass.define_instance_method('create_savepoint')

    klass.define_instance_method('current_savepoint_name')

    klass.define_instance_method('decrement_open_transactions')

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('disable_extension') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('disable_referential_integrity')

    klass.define_instance_method('disconnect!')

    klass.define_instance_method('enable_extension') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('expire')

    klass.define_instance_method('extensions')

    klass.define_instance_method('in_use')

    klass.define_instance_method('in_use?')

    klass.define_instance_method('increment_open_transactions')

    klass.define_instance_method('index_algorithms')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('connection')
      method.define_optional_argument('logger')
      method.define_optional_argument('pool')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('last_use')

    klass.define_instance_method('lease')

    klass.define_instance_method('log') do |method|
      method.define_argument('sql')
      method.define_optional_argument('name')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('open_transactions')

    klass.define_instance_method('pool')

    klass.define_instance_method('pool=')

    klass.define_instance_method('prefetch_primary_key?') do |method|
      method.define_optional_argument('table_name')
    end

    klass.define_instance_method('raw_connection')

    klass.define_instance_method('reconnect!')

    klass.define_instance_method('release_savepoint')

    klass.define_instance_method('requires_reloading?')

    klass.define_instance_method('reset!')

    klass.define_instance_method('rollback_to_savepoint')

    klass.define_instance_method('schema_cache')

    klass.define_instance_method('schema_cache=') do |method|
      method.define_argument('cache')
    end

    klass.define_instance_method('schema_creation')

    klass.define_instance_method('substitute_at') do |method|
      method.define_argument('column')
      method.define_argument('index')
    end

    klass.define_instance_method('supports_bulk_alter?')

    klass.define_instance_method('supports_count_distinct?')

    klass.define_instance_method('supports_ddl_transactions?')

    klass.define_instance_method('supports_explain?')

    klass.define_instance_method('supports_extensions?')

    klass.define_instance_method('supports_index_sort_order?')

    klass.define_instance_method('supports_migrations?')

    klass.define_instance_method('supports_partial_index?')

    klass.define_instance_method('supports_primary_key?')

    klass.define_instance_method('supports_savepoints?')

    klass.define_instance_method('supports_transaction_isolation?')

    klass.define_instance_method('transaction_joinable=') do |method|
      method.define_argument('joinable')
    end

    klass.define_instance_method('translate_exception') do |method|
      method.define_argument('exception')
      method.define_argument('message')
    end

    klass.define_instance_method('unprepared_statement')

    klass.define_instance_method('unprepared_visitor')

    klass.define_instance_method('update') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('valid_type?') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('verify!') do |method|
      method.define_rest_argument('ignored')
    end

    klass.define_instance_method('visitor')

    klass.define_instance_method('visitor=')

    klass.define_instance_method('without_prepared_statement?') do |method|
      method.define_argument('binds')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::AbstractAdapter::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::AbstractAdapter::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_update_filter') do |method|
      method.define_argument('filter_options')
      method.define_argument('new_options')
    end

    klass.define_instance_method('apply') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('chain=')

    klass.define_instance_method('clone') do |method|
      method.define_argument('chain')
      method.define_argument('klass')
    end

    klass.define_instance_method('deprecate_per_key_option') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('duplicates?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('chain')
      method.define_argument('filter')
      method.define_argument('kind')
      method.define_argument('options')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('kind=')

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('_kind')
      method.define_argument('_filter')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_id')

    klass.define_instance_method('normalize_options!') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('raw_filter')

    klass.define_instance_method('raw_filter=')

    klass.define_instance_method('recompile!') do |method|
      method.define_argument('_options')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::AbstractAdapter::CallbackChain') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('compile')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::AbstractAdapter::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__callback_runner_name_cache')

    klass.define_instance_method('__define_callbacks') do |method|
      method.define_argument('kind')
      method.define_argument('object')
    end

    klass.define_instance_method('__generate_callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__reset_runner') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('__update_callbacks') do |method|
      method.define_argument('name')
      method.define_optional_argument('filters')
      method.define_optional_argument('block')
    end

    klass.define_instance_method('define_callbacks') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('reset_callbacks') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('set_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end

    klass.define_instance_method('skip_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::AbstractAdapter::ConditionVariable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('monitor')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('signal')

    klass.define_instance_method('wait') do |method|
      method.define_optional_argument('timeout')
    end

    klass.define_instance_method('wait_until')

    klass.define_instance_method('wait_while')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::AbstractAdapter::SIMPLE_INT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::AbstractAdapter::SchemaCreation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accept') do |method|
      method.define_argument('o')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('conn')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::AlterTable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_column') do |method|
      method.define_argument('name')
      method.define_argument('type')
      method.define_argument('options')
    end

    klass.define_instance_method('adds')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('td')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ClosedTransaction') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ConnectionAdapters::Transaction', RubyLint.registry))

    klass.define_instance_method('add_record') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('begin') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('closed?')

    klass.define_instance_method('joinable?')

    klass.define_instance_method('number')

    klass.define_instance_method('open?')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::Column') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('binary_to_string') do |method|
      method.define_argument('value')
    end

    klass.define_method('fallback_string_to_date') do |method|
      method.define_argument('string')
    end

    klass.define_method('fallback_string_to_time') do |method|
      method.define_argument('string')
    end

    klass.define_method('fast_string_to_date') do |method|
      method.define_argument('string')
    end

    klass.define_method('fast_string_to_time') do |method|
      method.define_argument('string')
    end

    klass.define_method('microseconds') do |method|
      method.define_argument('time')
    end

    klass.define_method('new_date') do |method|
      method.define_argument('year')
      method.define_argument('mon')
      method.define_argument('mday')
    end

    klass.define_method('new_time') do |method|
      method.define_argument('year')
      method.define_argument('mon')
      method.define_argument('mday')
      method.define_argument('hour')
      method.define_argument('min')
      method.define_argument('sec')
      method.define_argument('microsec')
    end

    klass.define_method('string_to_binary') do |method|
      method.define_argument('value')
    end

    klass.define_method('string_to_dummy_time') do |method|
      method.define_argument('string')
    end

    klass.define_method('string_to_time') do |method|
      method.define_argument('string')
    end

    klass.define_method('value_to_boolean') do |method|
      method.define_argument('value')
    end

    klass.define_method('value_to_date') do |method|
      method.define_argument('value')
    end

    klass.define_method('value_to_decimal') do |method|
      method.define_argument('value')
    end

    klass.define_method('value_to_integer') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('binary?')

    klass.define_instance_method('coder')

    klass.define_instance_method('coder=')

    klass.define_instance_method('default')

    klass.define_instance_method('default_function')

    klass.define_instance_method('encoded?')

    klass.define_instance_method('extract_default') do |method|
      method.define_argument('default')
    end

    klass.define_instance_method('has_default?')

    klass.define_instance_method('human_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('default')
      method.define_optional_argument('sql_type')
      method.define_optional_argument('null')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('limit')

    klass.define_instance_method('name')

    klass.define_instance_method('null')

    klass.define_instance_method('number?')

    klass.define_instance_method('precision')

    klass.define_instance_method('primary')

    klass.define_instance_method('primary=')

    klass.define_instance_method('scale')

    klass.define_instance_method('sql_type')

    klass.define_instance_method('string_to_binary') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('text?')

    klass.define_instance_method('type')

    klass.define_instance_method('type_cast') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('type_cast_code') do |method|
      method.define_argument('var_name')
    end

    klass.define_instance_method('type_cast_for_write') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::Column::Format') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::Column::Format::ISO_DATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::Column::Format::ISO_DATETIME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ColumnDefinition') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('primary_key?')

    klass.define_instance_method('string_to_binary') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ColumnDefinition::Enumerator') do |klass|
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

  defs.define_constant('ActiveRecord::ConnectionAdapters::ColumnDefinition::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ColumnDefinition::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ColumnDefinition::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ColumnDefinition::SortedElement') do |klass|
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

  defs.define_constant('ActiveRecord::ConnectionAdapters::ColumnDefinition::Tms') do |klass|
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

  defs.define_constant('ActiveRecord::ConnectionAdapters::ColumnDumper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('column_spec') do |method|
      method.define_argument('column')
      method.define_argument('types')
    end

    klass.define_instance_method('migration_keys')

    klass.define_instance_method('prepare_column_options') do |method|
      method.define_argument('column')
      method.define_argument('types')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ConnectionHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('active_connections?')

    klass.define_instance_method('clear_active_connections!')

    klass.define_instance_method('clear_all_connections!')

    klass.define_instance_method('clear_reloadable_connections!')

    klass.define_instance_method('connected?') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('connection_pool_list')

    klass.define_instance_method('connection_pools')

    klass.define_instance_method('establish_connection') do |method|
      method.define_argument('owner')
      method.define_argument('spec')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('remove_connection') do |method|
      method.define_argument('owner')
    end

    klass.define_instance_method('retrieve_connection') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('retrieve_connection_pool') do |method|
      method.define_argument('klass')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ConnectionManagement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ConnectionPool') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('MonitorMixin', RubyLint.registry))

    klass.define_instance_method('active_connection?')

    klass.define_instance_method('automatic_reconnect')

    klass.define_instance_method('automatic_reconnect=')

    klass.define_instance_method('checkin') do |method|
      method.define_argument('conn')
    end

    klass.define_instance_method('checkout')

    klass.define_instance_method('checkout_timeout')

    klass.define_instance_method('checkout_timeout=')

    klass.define_instance_method('clear_reloadable_connections!')

    klass.define_instance_method('clear_stale_cached_connections!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('clear_stale_cached_connections_with_deprecation!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('clear_stale_cached_connections_without_deprecation!')

    klass.define_instance_method('connected?')

    klass.define_instance_method('connection')

    klass.define_instance_method('connections')

    klass.define_instance_method('dead_connection_timeout')

    klass.define_instance_method('dead_connection_timeout=')

    klass.define_instance_method('disconnect!')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('spec')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('reap')

    klass.define_instance_method('reaper')

    klass.define_instance_method('release_connection') do |method|
      method.define_optional_argument('with_id')
    end

    klass.define_instance_method('remove') do |method|
      method.define_argument('conn')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('spec')

    klass.define_instance_method('with_connection')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ConnectionPool::ConditionVariable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('broadcast')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('monitor')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('signal')

    klass.define_instance_method('wait') do |method|
      method.define_optional_argument('timeout')
    end

    klass.define_instance_method('wait_until')

    klass.define_instance_method('wait_while')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ConnectionPool::Queue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('element')
    end

    klass.define_instance_method('any_waiting?')

    klass.define_instance_method('clear')

    klass.define_instance_method('delete') do |method|
      method.define_argument('element')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('lock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('num_waiting')

    klass.define_instance_method('poll') do |method|
      method.define_optional_argument('timeout')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ConnectionPool::Reaper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('frequency')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('pool')
      method.define_argument('frequency')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('pool')

    klass.define_instance_method('run')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ConnectionSpecification') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('adapter_method')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('config')
      method.define_argument('adapter_method')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('config')

    klass.define_instance_method('configurations')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('config')
      method.define_argument('configurations')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('spec')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::DatabaseLimits') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('allowed_index_name_length')

    klass.define_instance_method('column_name_length')

    klass.define_instance_method('columns_per_multicolumn_index')

    klass.define_instance_method('columns_per_table')

    klass.define_instance_method('in_clause_length')

    klass.define_instance_method('index_name_length')

    klass.define_instance_method('indexes_per_table')

    klass.define_instance_method('joins_per_query')

    klass.define_instance_method('sql_query_length')

    klass.define_instance_method('table_alias_length')

    klass.define_instance_method('table_name_length')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::DatabaseStatements') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_transaction_record') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('begin_db_transaction')

    klass.define_instance_method('begin_isolated_db_transaction') do |method|
      method.define_argument('isolation')
    end

    klass.define_instance_method('begin_transaction') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('case_sensitive_equality_operator')

    klass.define_instance_method('commit_db_transaction')

    klass.define_instance_method('commit_transaction')

    klass.define_instance_method('current_transaction')

    klass.define_instance_method('default_sequence_name') do |method|
      method.define_argument('table')
      method.define_argument('column')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('arel')
      method.define_optional_argument('name')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('delete_sql') do |method|
      method.define_argument('sql')
      method.define_optional_argument('name')
    end

    klass.define_instance_method('empty_insert_statement_value')

    klass.define_instance_method('exec_delete') do |method|
      method.define_argument('sql')
      method.define_argument('name')
      method.define_argument('binds')
    end

    klass.define_instance_method('exec_insert') do |method|
      method.define_argument('sql')
      method.define_argument('name')
      method.define_argument('binds')
      method.define_optional_argument('pk')
      method.define_optional_argument('sequence_name')
    end

    klass.define_instance_method('exec_query') do |method|
      method.define_argument('sql')
      method.define_optional_argument('name')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('exec_update') do |method|
      method.define_argument('sql')
      method.define_argument('name')
      method.define_argument('binds')
    end

    klass.define_instance_method('insert') do |method|
      method.define_argument('arel')
      method.define_optional_argument('name')
      method.define_optional_argument('pk')
      method.define_optional_argument('id_value')
      method.define_optional_argument('sequence_name')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('insert_fixture') do |method|
      method.define_argument('fixture')
      method.define_argument('table_name')
    end

    klass.define_instance_method('insert_sql') do |method|
      method.define_argument('sql')
      method.define_optional_argument('name')
      method.define_optional_argument('pk')
      method.define_optional_argument('id_value')
      method.define_optional_argument('sequence_name')
    end

    klass.define_instance_method('join_to_delete') do |method|
      method.define_argument('delete')
      method.define_argument('select')
      method.define_argument('key')
    end

    klass.define_instance_method('join_to_update') do |method|
      method.define_argument('update')
      method.define_argument('select')
    end

    klass.define_instance_method('last_inserted_id') do |method|
      method.define_argument('result')
    end

    klass.define_instance_method('limited_update_conditions') do |method|
      method.define_argument('where_sql')
      method.define_argument('quoted_table_name')
      method.define_argument('quoted_primary_key')
    end

    klass.define_instance_method('reset_sequence!') do |method|
      method.define_argument('table')
      method.define_argument('column')
      method.define_optional_argument('sequence')
    end

    klass.define_instance_method('reset_transaction')

    klass.define_instance_method('rollback_db_transaction')

    klass.define_instance_method('rollback_transaction')

    klass.define_instance_method('sanitize_limit') do |method|
      method.define_argument('limit')
    end

    klass.define_instance_method('select_all') do |method|
      method.define_argument('arel')
      method.define_optional_argument('name')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('select_one') do |method|
      method.define_argument('arel')
      method.define_optional_argument('name')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('select_value') do |method|
      method.define_argument('arel')
      method.define_optional_argument('name')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('select_values') do |method|
      method.define_argument('arel')
      method.define_optional_argument('name')
    end

    klass.define_instance_method('sql_for_insert') do |method|
      method.define_argument('sql')
      method.define_argument('pk')
      method.define_argument('id_value')
      method.define_argument('sequence_name')
      method.define_argument('binds')
    end

    klass.define_instance_method('subquery_for') do |method|
      method.define_argument('key')
      method.define_argument('select')
    end

    klass.define_instance_method('supports_statement_cache?')

    klass.define_instance_method('to_sql') do |method|
      method.define_argument('arel')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('transaction') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('transaction_isolation_levels')

    klass.define_instance_method('transaction_open?')

    klass.define_instance_method('update') do |method|
      method.define_argument('arel')
      method.define_optional_argument('name')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('update_sql') do |method|
      method.define_argument('sql')
      method.define_optional_argument('name')
    end

    klass.define_instance_method('within_new_transaction') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::IndexDefinition') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::IndexDefinition::Enumerator') do |klass|
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

  defs.define_constant('ActiveRecord::ConnectionAdapters::IndexDefinition::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::IndexDefinition::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::IndexDefinition::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::IndexDefinition::SortedElement') do |klass|
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

  defs.define_constant('ActiveRecord::ConnectionAdapters::IndexDefinition::Tms') do |klass|
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

  defs.define_constant('ActiveRecord::ConnectionAdapters::QueryCache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('dirties_query_cache') do |method|
      method.define_argument('base')
      method.define_rest_argument('method_names')
    end

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('cache')

    klass.define_instance_method('clear_query_cache')

    klass.define_instance_method('disable_query_cache!')

    klass.define_instance_method('enable_query_cache!')

    klass.define_instance_method('query_cache')

    klass.define_instance_method('query_cache_enabled')

    klass.define_instance_method('select_all') do |method|
      method.define_argument('arel')
      method.define_optional_argument('name')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('uncached')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::Quoting') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('quote') do |method|
      method.define_argument('value')
      method.define_optional_argument('column')
    end

    klass.define_instance_method('quote_column_name') do |method|
      method.define_argument('column_name')
    end

    klass.define_instance_method('quote_string') do |method|
      method.define_argument('s')
    end

    klass.define_instance_method('quote_table_name') do |method|
      method.define_argument('table_name')
    end

    klass.define_instance_method('quote_table_name_for_assignment') do |method|
      method.define_argument('table')
      method.define_argument('attr')
    end

    klass.define_instance_method('quoted_date') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('quoted_false')

    klass.define_instance_method('quoted_true')

    klass.define_instance_method('type_cast') do |method|
      method.define_argument('value')
      method.define_argument('column')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::RealTransaction') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ConnectionAdapters::OpenTransaction', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('connection')
      method.define_argument('parent')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('perform_commit')

    klass.define_instance_method('perform_rollback')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::SavepointTransaction') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ConnectionAdapters::OpenTransaction', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('connection')
      method.define_argument('parent')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('perform_commit')

    klass.define_instance_method('perform_rollback')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::SchemaCache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('table_name')
    end

    klass.define_instance_method('clear!')

    klass.define_instance_method('clear_table_cache!') do |method|
      method.define_argument('table_name')
    end

    klass.define_instance_method('columns') do |method|
      method.define_optional_argument('table')
    end

    klass.define_instance_method('columns_hash') do |method|
      method.define_optional_argument('table')
    end

    klass.define_instance_method('connection')

    klass.define_instance_method('connection=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('conn')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('array')
    end

    klass.define_instance_method('primary_keys') do |method|
      method.define_optional_argument('table_name')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('table_exists?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('tables') do |method|
      method.define_optional_argument('name')
    end

    klass.define_instance_method('version')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::SchemaStatements') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_belongs_to') do |method|
      method.define_argument('table_name')
      method.define_argument('ref_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('add_column') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_argument('type')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('add_column_options!') do |method|
      method.define_argument('sql')
      method.define_argument('options')
    end

    klass.define_instance_method('add_index') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('add_index_options') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('add_index_sort_order') do |method|
      method.define_argument('option_strings')
      method.define_argument('column_names')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('add_reference') do |method|
      method.define_argument('table_name')
      method.define_argument('ref_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('add_timestamps') do |method|
      method.define_argument('table_name')
    end

    klass.define_instance_method('assume_migrated_upto_version') do |method|
      method.define_argument('version')
      method.define_optional_argument('migrations_paths')
    end

    klass.define_instance_method('change_column') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_argument('type')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('change_column_default') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_argument('default')
    end

    klass.define_instance_method('change_column_null') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_argument('null')
      method.define_optional_argument('default')
    end

    klass.define_instance_method('change_table') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('column_exists?') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_optional_argument('type')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('columns') do |method|
      method.define_argument('table_name')
    end

    klass.define_instance_method('columns_for_distinct') do |method|
      method.define_argument('columns')
      method.define_argument('orders')
    end

    klass.define_instance_method('columns_for_remove') do |method|
      method.define_argument('table_name')
      method.define_rest_argument('column_names')
    end

    klass.define_instance_method('create_join_table') do |method|
      method.define_argument('table_1')
      method.define_argument('table_2')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('create_table') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('distinct') do |method|
      method.define_argument('columns')
      method.define_argument('order_by')
    end

    klass.define_instance_method('drop_join_table') do |method|
      method.define_argument('table_1')
      method.define_argument('table_2')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('drop_table') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('dump_schema_information')

    klass.define_instance_method('index_exists?') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('index_name') do |method|
      method.define_argument('table_name')
      method.define_argument('options')
    end

    klass.define_instance_method('index_name_exists?') do |method|
      method.define_argument('table_name')
      method.define_argument('index_name')
      method.define_argument('default')
    end

    klass.define_instance_method('index_name_for_remove') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize_schema_migrations_table')

    klass.define_instance_method('native_database_types')

    klass.define_instance_method('options_include_default?') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('quoted_columns_for_index') do |method|
      method.define_argument('column_names')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('remove_belongs_to') do |method|
      method.define_argument('table_name')
      method.define_argument('ref_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('remove_column') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_optional_argument('type')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('remove_columns') do |method|
      method.define_argument('table_name')
      method.define_rest_argument('column_names')
    end

    klass.define_instance_method('remove_index') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('remove_index!') do |method|
      method.define_argument('table_name')
      method.define_argument('index_name')
    end

    klass.define_instance_method('remove_reference') do |method|
      method.define_argument('table_name')
      method.define_argument('ref_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('remove_timestamps') do |method|
      method.define_argument('table_name')
    end

    klass.define_instance_method('rename_column') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_argument('new_column_name')
    end

    klass.define_instance_method('rename_column_indexes') do |method|
      method.define_argument('table_name')
      method.define_argument('column_name')
      method.define_argument('new_column_name')
    end

    klass.define_instance_method('rename_index') do |method|
      method.define_argument('table_name')
      method.define_argument('old_name')
      method.define_argument('new_name')
    end

    klass.define_instance_method('rename_table') do |method|
      method.define_argument('table_name')
      method.define_argument('new_name')
    end

    klass.define_instance_method('rename_table_indexes') do |method|
      method.define_argument('table_name')
      method.define_argument('new_name')
    end

    klass.define_instance_method('table_alias_for') do |method|
      method.define_argument('table_name')
    end

    klass.define_instance_method('table_exists?') do |method|
      method.define_argument('table_name')
    end

    klass.define_instance_method('type_to_sql') do |method|
      method.define_argument('type')
      method.define_optional_argument('limit')
      method.define_optional_argument('precision')
      method.define_optional_argument('scale')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::Table') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('belongs_to') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('binary') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('boolean') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('change') do |method|
      method.define_argument('column_name')
      method.define_argument('type')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('change_default') do |method|
      method.define_argument('column_name')
      method.define_argument('default')
    end

    klass.define_instance_method('column') do |method|
      method.define_argument('column_name')
      method.define_argument('type')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('column_exists?') do |method|
      method.define_argument('column_name')
      method.define_optional_argument('type')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('datetime') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('decimal') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('float') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('index') do |method|
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('index_exists?') do |method|
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('table_name')
      method.define_argument('base')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('integer') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('references') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('remove') do |method|
      method.define_rest_argument('column_names')
    end

    klass.define_instance_method('remove_belongs_to') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('remove_index') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('remove_references') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('remove_timestamps')

    klass.define_instance_method('rename') do |method|
      method.define_argument('column_name')
      method.define_argument('new_column_name')
    end

    klass.define_instance_method('rename_index') do |method|
      method.define_argument('index_name')
      method.define_argument('new_index_name')
    end

    klass.define_instance_method('string') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('text') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('time') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('timestamp') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('timestamps')
  end

  defs.define_constant('ActiveRecord::ConnectionAdapters::TableDefinition') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('belongs_to') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('binary') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('boolean') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('column') do |method|
      method.define_argument('name')
      method.define_argument('type')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('columns')

    klass.define_instance_method('date') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('datetime') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('decimal') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('float') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('index') do |method|
      method.define_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('indexes')

    klass.define_instance_method('indexes=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('types')
      method.define_argument('name')
      method.define_argument('temporary')
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('integer') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('new_column_definition') do |method|
      method.define_argument('name')
      method.define_argument('type')
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('primary_key') do |method|
      method.define_argument('name')
      method.define_optional_argument('type')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('references') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('remove_column') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('string') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('temporary')

    klass.define_instance_method('text') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('time') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('timestamp') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('timestamps') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveRecord::ConnectionHandling') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('clear_active_connections!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('clear_all_connections!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('clear_cache!')

    klass.define_instance_method('clear_reloadable_connections!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('connected?')

    klass.define_instance_method('connection')

    klass.define_instance_method('connection_config')

    klass.define_instance_method('connection_id')

    klass.define_instance_method('connection_id=') do |method|
      method.define_argument('connection_id')
    end

    klass.define_instance_method('connection_pool')

    klass.define_instance_method('establish_connection') do |method|
      method.define_optional_argument('spec')
    end

    klass.define_instance_method('remove_connection') do |method|
      method.define_optional_argument('klass')
    end

    klass.define_instance_method('retrieve_connection')
  end

  defs.define_constant('ActiveRecord::ConnectionNotEstablished') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ConnectionTimeoutError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ConnectionNotEstablished', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Core') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other_object')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('comparison_object')
    end

    klass.define_instance_method('connection')

    klass.define_instance_method('connection_handler')

    klass.define_instance_method('encode_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('comparison_object')
    end

    klass.define_instance_method('freeze')

    klass.define_instance_method('frozen?')

    klass.define_instance_method('has_transactional_callbacks?')

    klass.define_instance_method('hash')

    klass.define_instance_method('init_with') do |method|
      method.define_argument('coder')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('readonly!')

    klass.define_instance_method('readonly?')

    klass.define_instance_method('set_transaction_state') do |method|
      method.define_argument('state')
    end

    klass.define_instance_method('slice') do |method|
      method.define_rest_argument('methods')
    end
  end

  defs.define_constant('ActiveRecord::Core::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('===') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('arel_engine')

    klass.define_instance_method('arel_table')

    klass.define_instance_method('generated_feature_methods')

    klass.define_instance_method('initialize_generated_modules')

    klass.define_instance_method('inspect')
  end

  defs.define_constant('ActiveRecord::CounterCache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::CounterCache::ClassMethods') do |klass|
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

  defs.define_constant('ActiveRecord::DangerousAttributeError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Delegation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('all?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collect') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('columns_hash') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('include?') do |method|
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

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('primary_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('quoted_primary_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('quoted_table_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('method')
      method.define_optional_argument('include_private')
    end

    klass.define_instance_method('table_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('to_ary') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('to_xml') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('to_yaml') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Delegation::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('const_missing') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('new') do |method|
      method.define_argument('klass')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveRecord::DeleteRestrictionError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::DeprecatedFinders') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('all') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('default_scope') do |method|
      method.define_optional_argument('scope')
      method.define_block_argument('block')
    end

    klass.define_instance_method('scope') do |method|
      method.define_argument('name')
      method.define_optional_argument('body')
      method.define_block_argument('block')
    end

    klass.define_instance_method('scoped') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('with_exclusive_scope') do |method|
      method.define_optional_argument('method_scoping')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with_scope') do |method|
      method.define_optional_argument('scope')
      method.define_optional_argument('action')
    end
  end

  defs.define_constant('ActiveRecord::DeprecatedFinders::ScopeWrapper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('wrap') do |method|
      method.define_argument('klass')
      method.define_argument('scope')
    end

    klass.define_instance_method('call') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('scope')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::DeprecatedFinders::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::DuplicateMigrationNameError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::DuplicateMigrationVersionError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('version')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::DynamicMatchers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
      method.define_optional_argument('include_private')
    end
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::DeprecatedFinder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('body')

    klass.define_instance_method('result')

    klass.define_instance_method('signature')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::DeprecationWarning') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('body')

    klass.define_instance_method('deprecation_warning')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::FindAllBy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Method', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::DeprecationWarning', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::DeprecatedFinder', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Finder', RubyLint.registry))

    klass.define_method('prefix')

    klass.define_instance_method('deprecation_alternative')

    klass.define_instance_method('finder')

    klass.define_instance_method('result')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::FindBy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Method', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::FindByDeprecationWarning', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::DeprecatedFinder', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Finder', RubyLint.registry))

    klass.define_method('prefix')

    klass.define_instance_method('finder')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::FindByBang') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Method', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::FindByDeprecationWarning', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::DeprecatedFinder', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Finder', RubyLint.registry))

    klass.define_method('prefix')

    klass.define_method('suffix')

    klass.define_instance_method('finder')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::FindByDeprecationWarning') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('body')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::FindLastBy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Method', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::DeprecationWarning', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::DeprecatedFinder', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Finder', RubyLint.registry))

    klass.define_method('prefix')

    klass.define_instance_method('deprecation_alternative')

    klass.define_instance_method('finder')

    klass.define_instance_method('result')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::FindOrCreateBy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Instantiator', RubyLint.registry))

    klass.define_method('prefix')

    klass.define_instance_method('instantiator')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::FindOrCreateByBang') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Instantiator', RubyLint.registry))

    klass.define_method('prefix')

    klass.define_method('suffix')

    klass.define_instance_method('instantiator')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::FindOrInitializeBy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Instantiator', RubyLint.registry))

    klass.define_method('prefix')

    klass.define_instance_method('instantiator')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::Finder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attributes_hash')

    klass.define_instance_method('body')

    klass.define_instance_method('finder')

    klass.define_instance_method('result')

    klass.define_instance_method('signature')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::Instantiator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Method', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::DeprecationWarning', RubyLint.registry))

    klass.define_method('dispatch') do |method|
      method.define_argument('klass')
      method.define_argument('attribute_names')
      method.define_argument('instantiator')
      method.define_argument('args')
      method.define_argument('block')
    end

    klass.define_instance_method('body')

    klass.define_instance_method('deprecation_alternative')

    klass.define_instance_method('instantiator')

    klass.define_instance_method('signature')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::Method') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('match') do |method|
      method.define_argument('model')
      method.define_argument('name')
    end

    klass.define_method('matchers')

    klass.define_method('pattern')

    klass.define_method('prefix')

    klass.define_method('suffix')

    klass.define_instance_method('attribute_names')

    klass.define_instance_method('body')

    klass.define_instance_method('define')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('model')
      method.define_argument('name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('model')

    klass.define_instance_method('name')

    klass.define_instance_method('valid?')
  end

  defs.define_constant('ActiveRecord::DynamicMatchers::ScopedBy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Method', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::DeprecationWarning', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::DynamicMatchers::Finder', RubyLint.registry))

    klass.define_method('prefix')

    klass.define_instance_method('body')

    klass.define_instance_method('deprecation_alternative')
  end

  defs.define_constant('ActiveRecord::EagerLoadPolymorphicError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::Explain') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collecting_queries_for_explain')

    klass.define_instance_method('exec_explain') do |method|
      method.define_argument('queries')
    end
  end

  defs.define_constant('ActiveRecord::ExplainRegistry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collect')

    klass.define_instance_method('collect=')

    klass.define_instance_method('collect?')

    klass.define_instance_method('initialize')

    klass.define_instance_method('queries')

    klass.define_instance_method('queries=')

    klass.define_instance_method('reset')
  end

  defs.define_constant('ActiveRecord::FinderMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('apply_join_dependency') do |method|
      method.define_argument('relation')
      method.define_argument('join_dependency')
    end

    klass.define_instance_method('construct_join_dependency_for_association_find')

    klass.define_instance_method('construct_limited_ids_condition') do |method|
      method.define_argument('relation')
    end

    klass.define_instance_method('construct_relation_for_association_calculations')

    klass.define_instance_method('construct_relation_for_association_find') do |method|
      method.define_argument('join_dependency')
    end

    klass.define_instance_method('exists?') do |method|
      method.define_optional_argument('conditions')
    end

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('find_by') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('find_by!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('find_first')

    klass.define_instance_method('find_last')

    klass.define_instance_method('find_one') do |method|
      method.define_argument('id')
    end

    klass.define_instance_method('find_some') do |method|
      method.define_argument('ids')
    end

    klass.define_instance_method('find_take')

    klass.define_instance_method('find_with_associations')

    klass.define_instance_method('find_with_ids') do |method|
      method.define_rest_argument('ids')
    end

    klass.define_instance_method('first') do |method|
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('first!')

    klass.define_instance_method('last') do |method|
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('last!')

    klass.define_instance_method('raise_record_not_found_exception!') do |method|
      method.define_argument('ids')
      method.define_argument('result_size')
      method.define_argument('expected_size')
    end

    klass.define_instance_method('take') do |method|
      method.define_optional_argument('limit')
    end

    klass.define_instance_method('take!')

    klass.define_instance_method('using_limitable_reflections?') do |method|
      method.define_argument('reflections')
    end
  end

  defs.define_constant('ActiveRecord::HasAndBelongsToManyAssociationForeignKeyNeeded') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::HasManyThroughAssociationNotFoundError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner_class_name')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::HasManyThroughAssociationPointlessSourceTypeError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner_class_name')
      method.define_argument('reflection')
      method.define_argument('source_reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::HasManyThroughAssociationPolymorphicSourceError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner_class_name')
      method.define_argument('reflection')
      method.define_argument('source_reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::HasManyThroughAssociationPolymorphicThroughError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner_class_name')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::HasManyThroughCantAssociateNewRecords') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::HasManyThroughCantAssociateThroughHasOneOrManyReflection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::HasManyThroughCantDissociateNewRecords') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::HasManyThroughNestedAssociationsAreReadonly') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::HasManyThroughSourceAssociationNotFoundError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::HasOneThroughCantAssociateThroughCollection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner_class_name')
      method.define_argument('reflection')
      method.define_argument('through_reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::IllegalMigrationNameError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::ImmutableRelation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Inheritance') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Inheritance::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('abstract_class')

    klass.define_instance_method('abstract_class=')

    klass.define_instance_method('abstract_class?')

    klass.define_instance_method('base_class')

    klass.define_instance_method('compute_type') do |method|
      method.define_argument('type_name')
    end

    klass.define_instance_method('descends_from_active_record?')

    klass.define_instance_method('finder_needs_type_condition?')

    klass.define_instance_method('new') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sti_name')

    klass.define_instance_method('symbolized_base_class')

    klass.define_instance_method('symbolized_sti_name')
  end

  defs.define_constant('ActiveRecord::Integration') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache_key')

    klass.define_instance_method('to_param')
  end

  defs.define_constant('ActiveRecord::InvalidForeignKey') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::WrappedDatabaseException', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::InverseOfAssociationNotFoundError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('reflection')
      method.define_optional_argument('associated_class')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::IrreversibleMigration') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Locking') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Locking::Optimistic') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('locking_enabled?')
  end

  defs.define_constant('ActiveRecord::Locking::Optimistic::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('column_defaults')

    klass.define_instance_method('locking_column')

    klass.define_instance_method('locking_column=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('locking_enabled?')

    klass.define_instance_method('quoted_locking_column')

    klass.define_instance_method('reset_locking_column')

    klass.define_instance_method('update_counters') do |method|
      method.define_argument('id')
      method.define_argument('counters')
    end
  end

  defs.define_constant('ActiveRecord::Locking::Optimistic::ClassMethods::DEFAULT_LOCKING_COLUMN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Locking::Pessimistic') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('lock!') do |method|
      method.define_optional_argument('lock')
    end

    klass.define_instance_method('with_lock') do |method|
      method.define_optional_argument('lock')
    end
  end

  defs.define_constant('ActiveRecord::Migration') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('check_pending!')

    klass.define_method('delegate')

    klass.define_method('delegate=')

    klass.define_method('disable_ddl_transaction')

    klass.define_method('disable_ddl_transaction!')

    klass.define_method('disable_ddl_transaction=')

    klass.define_method('method_missing') do |method|
      method.define_argument('name')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_method('migrate') do |method|
      method.define_argument('direction')
    end

    klass.define_method('verbose')

    klass.define_method('verbose=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('announce') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('connection')

    klass.define_instance_method('copy') do |method|
      method.define_argument('destination')
      method.define_argument('sources')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('disable_ddl_transaction')

    klass.define_instance_method('down')

    klass.define_instance_method('exec_migration') do |method|
      method.define_argument('conn')
      method.define_argument('direction')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('version')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('arguments')
      method.define_block_argument('block')
    end

    klass.define_instance_method('migrate') do |method|
      method.define_argument('direction')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=')

    klass.define_instance_method('next_migration_number') do |method|
      method.define_argument('number')
    end

    klass.define_instance_method('reversible')

    klass.define_instance_method('revert') do |method|
      method.define_rest_argument('migration_classes')
    end

    klass.define_instance_method('reverting?')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('migration_classes')
    end

    klass.define_instance_method('say') do |method|
      method.define_argument('message')
      method.define_optional_argument('subitem')
    end

    klass.define_instance_method('say_with_time') do |method|
      method.define_argument('message')
    end

    klass.define_instance_method('suppress_messages')

    klass.define_instance_method('up')

    klass.define_instance_method('verbose')

    klass.define_instance_method('verbose=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('version')

    klass.define_instance_method('version=')

    klass.define_instance_method('write') do |method|
      method.define_optional_argument('text')
    end
  end

  defs.define_constant('ActiveRecord::Migration::CheckPending') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::Migration::CommandRecorder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Migration::CommandRecorder::StraightReversions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Migration::JoinTable', RubyLint.registry))

    klass.define_instance_method('add_belongs_to') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('add_column') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('add_index') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('add_reference') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('add_timestamps') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('change_column') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('change_column_default') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('change_table') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('commands')

    klass.define_instance_method('commands=')

    klass.define_instance_method('create_join_table') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create_table') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delegate')

    klass.define_instance_method('delegate=')

    klass.define_instance_method('drop_join_table') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('drop_table') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute_block') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('delegate')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inverse_of') do |method|
      method.define_argument('command')
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_add_belongs_to') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_remove_belongs_to') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('record') do |method|
      method.define_rest_argument('command')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_belongs_to') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_column') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_columns') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_index') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_reference') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_timestamps') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rename_column') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rename_index') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rename_table') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('revert')

    klass.define_instance_method('reverting')

    klass.define_instance_method('reverting=')

    klass.define_instance_method('transaction') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Migration::CommandRecorder::StraightReversions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('invert_add_column') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_add_reference') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_add_timestamps') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_create_join_table') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_create_table') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_drop_join_table') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_drop_table') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_execute_block') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_remove_column') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_remove_reference') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_remove_timestamps') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_transaction') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Migration::JoinTable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Migration::ReversibleBlockHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('down')

    klass.define_instance_method('up')
  end

  defs.define_constant('ActiveRecord::Migration::ReversibleBlockHelper::Enumerator') do |klass|
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

  defs.define_constant('ActiveRecord::Migration::ReversibleBlockHelper::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('ActiveRecord::Migration::ReversibleBlockHelper::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('ActiveRecord::Migration::ReversibleBlockHelper::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Migration::ReversibleBlockHelper::SortedElement') do |klass|
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

  defs.define_constant('ActiveRecord::Migration::ReversibleBlockHelper::Tms') do |klass|
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

  defs.define_constant('ActiveRecord::MigrationProxy') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('announce') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('basename')

    klass.define_instance_method('disable_ddl_transaction') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('version')
      method.define_argument('filename')
      method.define_argument('scope')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('migrate') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('mtime')

    klass.define_instance_method('write') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::MigrationProxy::Enumerator') do |klass|
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

  defs.define_constant('ActiveRecord::MigrationProxy::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('ActiveRecord::MigrationProxy::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('ActiveRecord::MigrationProxy::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::MigrationProxy::SortedElement') do |klass|
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

  defs.define_constant('ActiveRecord::MigrationProxy::Tms') do |klass|
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

  defs.define_constant('ActiveRecord::Migrator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('current_version')

    klass.define_method('down') do |method|
      method.define_argument('migrations_paths')
      method.define_optional_argument('target_version')
      method.define_block_argument('block')
    end

    klass.define_method('forward') do |method|
      method.define_argument('migrations_paths')
      method.define_optional_argument('steps')
    end

    klass.define_method('get_all_versions')

    klass.define_method('last_migration')

    klass.define_method('last_version')

    klass.define_method('migrate') do |method|
      method.define_argument('migrations_paths')
      method.define_optional_argument('target_version')
      method.define_block_argument('block')
    end

    klass.define_method('migrations') do |method|
      method.define_argument('paths')
    end

    klass.define_method('migrations_path')

    klass.define_method('migrations_path=')

    klass.define_method('migrations_paths')

    klass.define_method('migrations_paths=')

    klass.define_method('needs_migration?')

    klass.define_method('open') do |method|
      method.define_argument('migrations_paths')
    end

    klass.define_method('proper_table_name') do |method|
      method.define_argument('name')
    end

    klass.define_method('rollback') do |method|
      method.define_argument('migrations_paths')
      method.define_optional_argument('steps')
    end

    klass.define_method('run') do |method|
      method.define_argument('direction')
      method.define_argument('migrations_paths')
      method.define_argument('target_version')
    end

    klass.define_method('schema_migrations_table_name')

    klass.define_method('up') do |method|
      method.define_argument('migrations_paths')
      method.define_optional_argument('target_version')
    end

    klass.define_instance_method('current')

    klass.define_instance_method('current_migration')

    klass.define_instance_method('current_version')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('direction')
      method.define_argument('migrations')
      method.define_optional_argument('target_version')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('migrate')

    klass.define_instance_method('migrated')

    klass.define_instance_method('migrations')

    klass.define_instance_method('pending_migrations')

    klass.define_instance_method('run')

    klass.define_instance_method('runnable')
  end

  defs.define_constant('ActiveRecord::ModelSchema') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ModelSchema::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('column_defaults')

    klass.define_instance_method('column_methods_hash')

    klass.define_instance_method('column_names')

    klass.define_instance_method('column_types')

    klass.define_instance_method('columns')

    klass.define_instance_method('columns_hash')

    klass.define_instance_method('content_columns')

    klass.define_instance_method('decorate_columns') do |method|
      method.define_argument('columns_hash')
    end

    klass.define_instance_method('full_table_name_prefix')

    klass.define_instance_method('inheritance_column')

    klass.define_instance_method('inheritance_column=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('initialize_attributes') do |method|
      method.define_argument('attributes')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('quoted_table_name')

    klass.define_instance_method('reset_column_information')

    klass.define_instance_method('reset_sequence_name')

    klass.define_instance_method('reset_table_name')

    klass.define_instance_method('sequence_name')

    klass.define_instance_method('sequence_name=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('table_exists?')

    klass.define_instance_method('table_name')

    klass.define_instance_method('table_name=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::MultiparameterAssignmentErrors') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('errors')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('errors')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::NestedAttributes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_destroy')
  end

  defs.define_constant('ActiveRecord::NestedAttributes::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('accepts_nested_attributes_for') do |method|
      method.define_rest_argument('attr_names')
    end
  end

  defs.define_constant('ActiveRecord::NestedAttributes::ClassMethods::REJECT_ALL_BLANK_PROC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::NestedAttributes::TooManyRecords') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::NestedAttributes::UNASSIGNABLE_KEYS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::NullMigration') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::MigrationProxy', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('mtime')
  end

  defs.define_constant('ActiveRecord::NullMigration::Enumerator') do |klass|
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

  defs.define_constant('ActiveRecord::NullMigration::Group') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('gid')

    klass.define_instance_method('mem')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')
  end

  defs.define_constant('ActiveRecord::NullMigration::Passwd') do |klass|
    klass.inherits(defs.constant_proxy('Rubinius::FFI::Struct', RubyLint.registry))

    klass.define_instance_method('dir')

    klass.define_instance_method('gecos')

    klass.define_instance_method('gid')

    klass.define_instance_method('name')

    klass.define_instance_method('passwd')

    klass.define_instance_method('shell')

    klass.define_instance_method('uid')
  end

  defs.define_constant('ActiveRecord::NullMigration::STRUCT_ATTRS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::NullMigration::SortedElement') do |klass|
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

  defs.define_constant('ActiveRecord::NullMigration::Tms') do |klass|
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

  defs.define_constant('ActiveRecord::NullRelation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('any?')

    klass.define_instance_method('calculate') do |method|
      method.define_argument('_operation')
      method.define_argument('_column_name')
      method.define_optional_argument('_options')
    end

    klass.define_instance_method('count') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('delete') do |method|
      method.define_argument('_id_or_array')
    end

    klass.define_instance_method('delete_all') do |method|
      method.define_optional_argument('_conditions')
    end

    klass.define_instance_method('empty?')

    klass.define_instance_method('exec_queries')

    klass.define_instance_method('exists?') do |method|
      method.define_optional_argument('_id')
    end

    klass.define_instance_method('many?')

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('column_names')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('sum') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('to_sql')

    klass.define_instance_method('update_all') do |method|
      method.define_argument('_updates')
      method.define_optional_argument('_conditions')
      method.define_optional_argument('_options')
    end
  end

  defs.define_constant('ActiveRecord::PendingMigrationError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActiveRecord::Persistence') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('becomes') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('becomes!') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('decrement') do |method|
      method.define_argument('attribute')
      method.define_optional_argument('by')
    end

    klass.define_instance_method('decrement!') do |method|
      method.define_argument('attribute')
      method.define_optional_argument('by')
    end

    klass.define_instance_method('delete')

    klass.define_instance_method('destroy')

    klass.define_instance_method('destroy!')

    klass.define_instance_method('destroyed?')

    klass.define_instance_method('increment') do |method|
      method.define_argument('attribute')
      method.define_optional_argument('by')
    end

    klass.define_instance_method('increment!') do |method|
      method.define_argument('attribute')
      method.define_optional_argument('by')
    end

    klass.define_instance_method('new_record?')

    klass.define_instance_method('persisted?')

    klass.define_instance_method('reload') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('save') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('save!') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('toggle') do |method|
      method.define_argument('attribute')
    end

    klass.define_instance_method('toggle!') do |method|
      method.define_argument('attribute')
    end

    klass.define_instance_method('touch') do |method|
      method.define_optional_argument('name')
    end

    klass.define_instance_method('update') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('update!') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('update_attribute') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('update_attributes') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('update_attributes!') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('update_column') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('update_columns') do |method|
      method.define_argument('attributes')
    end
  end

  defs.define_constant('ActiveRecord::Persistence::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('instantiate') do |method|
      method.define_argument('record')
      method.define_optional_argument('column_types')
    end
  end

  defs.define_constant('ActiveRecord::PredicateBuilder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('attribute')
      method.define_argument('value')
    end

    klass.define_method('build_from_hash') do |method|
      method.define_argument('klass')
      method.define_argument('attributes')
      method.define_argument('default_table')
    end

    klass.define_method('expand') do |method|
      method.define_argument('klass')
      method.define_argument('table')
      method.define_argument('column')
      method.define_argument('value')
    end

    klass.define_method('references') do |method|
      method.define_argument('attributes')
    end
  end

  defs.define_constant('ActiveRecord::PreparedStatementInvalid') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::QueryCache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::QueryCache::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('uncached') do |method|
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::QueryMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('arel')

    klass.define_instance_method('bind') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('bind!') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('bind_values')

    klass.define_instance_method('bind_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('build_arel')

    klass.define_instance_method('create_with') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('create_with!') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('create_with_value')

    klass.define_instance_method('create_with_value=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('distinct') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('distinct!') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('distinct_value')

    klass.define_instance_method('distinct_value=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('eager_load') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('eager_load!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('eager_load_values')

    klass.define_instance_method('eager_load_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('extending') do |method|
      method.define_rest_argument('modules')
      method.define_block_argument('block')
    end

    klass.define_instance_method('extending!') do |method|
      method.define_rest_argument('modules')
      method.define_block_argument('block')
    end

    klass.define_instance_method('extending_values')

    klass.define_instance_method('extending_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('extensions')

    klass.define_instance_method('from') do |method|
      method.define_argument('value')
      method.define_optional_argument('subquery_name')
    end

    klass.define_instance_method('from!') do |method|
      method.define_argument('value')
      method.define_optional_argument('subquery_name')
    end

    klass.define_instance_method('from_value')

    klass.define_instance_method('from_value=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('group') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('group!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('group_values')

    klass.define_instance_method('group_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('having') do |method|
      method.define_argument('opts')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('having!') do |method|
      method.define_argument('opts')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('having_values')

    klass.define_instance_method('having_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('includes') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('includes!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('includes_values')

    klass.define_instance_method('includes_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('joins') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('joins!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('joins_values')

    klass.define_instance_method('joins_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('limit') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('limit!') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('limit_value')

    klass.define_instance_method('limit_value=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('lock') do |method|
      method.define_optional_argument('locks')
    end

    klass.define_instance_method('lock!') do |method|
      method.define_optional_argument('locks')
    end

    klass.define_instance_method('lock_value')

    klass.define_instance_method('lock_value=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('none')

    klass.define_instance_method('none!')

    klass.define_instance_method('offset') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('offset!') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('offset_value')

    klass.define_instance_method('offset_value=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('order') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('order!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('order_values')

    klass.define_instance_method('order_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('preload') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('preload!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('preload_values')

    klass.define_instance_method('preload_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('readonly') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('readonly!') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('readonly_value')

    klass.define_instance_method('readonly_value=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('references') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('references!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('references_values')

    klass.define_instance_method('references_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('reorder') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('reorder!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('reordering_value')

    klass.define_instance_method('reordering_value=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('reverse_order')

    klass.define_instance_method('reverse_order!')

    klass.define_instance_method('reverse_order_value')

    klass.define_instance_method('reverse_order_value=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('select') do |method|
      method.define_rest_argument('fields')
    end

    klass.define_instance_method('select!') do |method|
      method.define_rest_argument('fields')
    end

    klass.define_instance_method('select_values')

    klass.define_instance_method('select_values=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('uniq') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('uniq!') do |method|
      method.define_optional_argument('value')
    end

    klass.define_instance_method('uniq_value')

    klass.define_instance_method('uniq_value=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('unscope') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('unscope!') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('where') do |method|
      method.define_optional_argument('opts')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('where!') do |method|
      method.define_optional_argument('opts')
      method.define_rest_argument('rest')
    end

    klass.define_instance_method('where_values')

    klass.define_instance_method('where_values=') do |method|
      method.define_argument('values')
    end
  end

  defs.define_constant('ActiveRecord::QueryMethods::VALID_UNSCOPING_VALUES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::QueryMethods::WhereChain') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('scope')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('not') do |method|
      method.define_argument('opts')
      method.define_rest_argument('rest')
    end
  end

  defs.define_constant('ActiveRecord::Querying') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('any?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('average') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('calculate') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('count') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('count_by_sql') do |method|
      method.define_argument('sql')
    end

    klass.define_instance_method('create_with') do |method|
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

    klass.define_instance_method('eager_load') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('except') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('exists?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_by') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_by!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_by_sql') do |method|
      method.define_argument('sql')
      method.define_optional_argument('binds')
    end

    klass.define_instance_method('find_each') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_in_batches') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
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

    klass.define_instance_method('first') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

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

    klass.define_instance_method('from') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('group') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('having') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('ids') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('includes') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('joins') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('last') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('last!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('limit') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('lock') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('many?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('maximum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('minimum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('none') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('offset') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('order') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('preload') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('readonly') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('references') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('reorder') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('select') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('sum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('take') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('take!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('uniq') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('unscope') do |method|
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
  end

  defs.define_constant('ActiveRecord::Railtie') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configurable', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Railtie::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Railtie::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('config') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('configure') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('inherited') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('instance')

    klass.define_instance_method('method_missing') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveRecord::Railtie::Collection') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('initializer')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tsort_each_node')
  end

  defs.define_constant('ActiveRecord::Railtie::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Railtie::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('eager_load_namespaces')

    klass.define_instance_method('after_initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('app_generators')

    klass.define_instance_method('app_middleware')

    klass.define_instance_method('before_configuration') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_eager_load') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('eager_load_namespaces')

    klass.define_instance_method('initialize')

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('to_prepare') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('to_prepare_blocks')

    klass.define_instance_method('watchable_dirs')

    klass.define_instance_method('watchable_files')
  end

  defs.define_constant('ActiveRecord::Railtie::Initializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after')

    klass.define_instance_method('before')

    klass.define_instance_method('belongs_to?') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('bind') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveRecord::ReadOnlyAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::ReadOnlyRecord') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::ReadonlyAttributes') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_attr_readonly')
  end

  defs.define_constant('ActiveRecord::ReadonlyAttributes::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attr_readonly') do |method|
      method.define_rest_argument('attributes')
    end

    klass.define_instance_method('readonly_attributes')
  end

  defs.define_constant('ActiveRecord::RecordNotDestroyed') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::RecordNotFound') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::RecordNotSaved') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::RecordNotUnique') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::WrappedDatabaseException', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Reflection') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Reflection::AggregateReflection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Reflection::MacroReflection', RubyLint.registry))

    klass.define_instance_method('mapping')
  end

  defs.define_constant('ActiveRecord::Reflection::AssociationReflection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Reflection::MacroReflection', RubyLint.registry))

    klass.define_instance_method('active_record_primary_key')

    klass.define_instance_method('association_class')

    klass.define_instance_method('association_foreign_key')

    klass.define_instance_method('association_primary_key') do |method|
      method.define_optional_argument('klass')
    end

    klass.define_instance_method('belongs_to?')

    klass.define_instance_method('build_association') do |method|
      method.define_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('check_validity_of_inverse!')

    klass.define_instance_method('collection?')

    klass.define_instance_method('columns') do |method|
      method.define_argument('tbl_name')
    end

    klass.define_instance_method('counter_cache_column')

    klass.define_instance_method('foreign_key')

    klass.define_instance_method('foreign_type')

    klass.define_instance_method('has_and_belongs_to_many?')

    klass.define_instance_method('has_inverse?')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inverse_of')

    klass.define_instance_method('join_table')

    klass.define_instance_method('klass')

    klass.define_instance_method('nested?')

    klass.define_instance_method('polymorphic?')

    klass.define_instance_method('polymorphic_inverse_of') do |method|
      method.define_argument('associated_class')
    end

    klass.define_instance_method('primary_key_column')

    klass.define_instance_method('quoted_table_name')

    klass.define_instance_method('reset_column_information')

    klass.define_instance_method('scope_chain')

    klass.define_instance_method('source_macro')

    klass.define_instance_method('source_reflection')

    klass.define_instance_method('table_name')

    klass.define_instance_method('through_reflection')

    klass.define_instance_method('type')

    klass.define_instance_method('validate?')
  end

  defs.define_constant('ActiveRecord::Reflection::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('create_reflection') do |method|
      method.define_argument('macro')
      method.define_argument('name')
      method.define_argument('scope')
      method.define_argument('options')
      method.define_argument('active_record')
    end

    klass.define_instance_method('reflect_on_aggregation') do |method|
      method.define_argument('aggregation')
    end

    klass.define_instance_method('reflect_on_all_aggregations')

    klass.define_instance_method('reflect_on_all_associations') do |method|
      method.define_optional_argument('macro')
    end

    klass.define_instance_method('reflect_on_all_autosave_associations')

    klass.define_instance_method('reflect_on_association') do |method|
      method.define_argument('association')
    end
  end

  defs.define_constant('ActiveRecord::Reflection::MacroReflection') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other_aggregation')
    end

    klass.define_instance_method('active_record')

    klass.define_instance_method('class_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('macro')
      method.define_argument('name')
      method.define_argument('scope')
      method.define_argument('options')
      method.define_argument('active_record')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('macro')

    klass.define_instance_method('name')

    klass.define_instance_method('options')

    klass.define_instance_method('plural_name')

    klass.define_instance_method('scope')
  end

  defs.define_constant('ActiveRecord::Reflection::ThroughReflection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Reflection::AssociationReflection', RubyLint.registry))

    klass.define_instance_method('active_record_primary_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('association_foreign_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('association_primary_key') do |method|
      method.define_optional_argument('klass')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('foreign_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('foreign_type') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('nested?')

    klass.define_instance_method('scope_chain')

    klass.define_instance_method('source_macro')

    klass.define_instance_method('source_options')

    klass.define_instance_method('source_reflection')

    klass.define_instance_method('source_reflection_names')

    klass.define_instance_method('through_options')

    klass.define_instance_method('through_reflection')

    klass.define_instance_method('type') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Relation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Relation::DeprecatedMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::FinderMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Calculations', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::SpawnMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::QueryMethods', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Batches', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Explain', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Delegation', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('any?')

    klass.define_instance_method('as_json') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('blank?')

    klass.define_instance_method('build') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('default_scoped')

    klass.define_instance_method('default_scoped=')

    klass.define_instance_method('default_scoped?')

    klass.define_instance_method('delete') do |method|
      method.define_argument('id_or_array')
    end

    klass.define_instance_method('delete_all') do |method|
      method.define_optional_argument('conditions')
    end

    klass.define_instance_method('destroy') do |method|
      method.define_argument('id')
    end

    klass.define_instance_method('destroy_all') do |method|
      method.define_optional_argument('conditions')
    end

    klass.define_instance_method('eager_loading?')

    klass.define_instance_method('empty?')

    klass.define_instance_method('explain')

    klass.define_instance_method('find_or_create_by') do |method|
      method.define_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_or_create_by!') do |method|
      method.define_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('find_or_initialize_by') do |method|
      method.define_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first_or_create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first_or_create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first_or_initialize') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('table')
      method.define_optional_argument('values')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('joined_includes_values')

    klass.define_instance_method('klass')

    klass.define_instance_method('load')

    klass.define_instance_method('loaded')

    klass.define_instance_method('loaded?')

    klass.define_instance_method('many?')

    klass.define_instance_method('model')

    klass.define_instance_method('new') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('reload')

    klass.define_instance_method('reset')

    klass.define_instance_method('scope_for_create')

    klass.define_instance_method('scoping')

    klass.define_instance_method('size')

    klass.define_instance_method('table')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_sql')

    klass.define_instance_method('uniq_value')

    klass.define_instance_method('update') do |method|
      method.define_argument('id')
      method.define_argument('attributes')
    end

    klass.define_instance_method('update_all') do |method|
      method.define_argument('updates')
      method.define_optional_argument('conditions')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('update_all_without_deprecated_options') do |method|
      method.define_argument('updates')
    end

    klass.define_instance_method('values')

    klass.define_instance_method('where_values_hash')

    klass.define_instance_method('with_default_scope')
  end

  defs.define_constant('ActiveRecord::Relation::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('const_missing') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('new') do |method|
      method.define_argument('klass')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActiveRecord::Relation::ClassSpecificRelation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('method')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Relation::HashMerger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('relation')
      method.define_argument('hash')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('merge')

    klass.define_instance_method('other')

    klass.define_instance_method('relation')
  end

  defs.define_constant('ActiveRecord::Relation::MULTI_VALUE_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Relation::SINGLE_VALUE_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Relation::VALID_FIND_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Relation::VALID_UNSCOPING_VALUES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Relation::VALUE_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Relation::WhereChain') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('scope')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('not') do |method|
      method.define_argument('opts')
      method.define_rest_argument('rest')
    end
  end

  defs.define_constant('ActiveRecord::Result') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('collect!')

    klass.define_instance_method('column_types')

    klass.define_instance_method('columns')

    klass.define_instance_method('each')

    klass.define_instance_method('empty?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('columns')
      method.define_argument('rows')
      method.define_optional_argument('column_types')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('last')

    klass.define_instance_method('map!')

    klass.define_instance_method('rows')

    klass.define_instance_method('to_ary')

    klass.define_instance_method('to_hash')
  end

  defs.define_constant('ActiveRecord::Result::Enumerator') do |klass|
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

  defs.define_constant('ActiveRecord::Result::SortedElement') do |klass|
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

  defs.define_constant('ActiveRecord::Rollback') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::RuntimeRegistry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('connection_handler') do |method|
      method.define_rest_argument('a')
      method.define_block_argument('b')
    end

    klass.define_instance_method('connection_handler')

    klass.define_instance_method('connection_handler=')

    klass.define_instance_method('connection_id')

    klass.define_instance_method('connection_id=')

    klass.define_instance_method('sql_runtime')

    klass.define_instance_method('sql_runtime=')
  end

  defs.define_constant('ActiveRecord::Sanitization') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('quoted_id')
  end

  defs.define_constant('ActiveRecord::Sanitization::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('expand_hash_conditions_for_aggregates') do |method|
      method.define_argument('attrs')
    end

    klass.define_instance_method('quote_bound_value') do |method|
      method.define_argument('value')
      method.define_optional_argument('c')
    end

    klass.define_instance_method('quote_value') do |method|
      method.define_argument('value')
      method.define_optional_argument('column')
    end

    klass.define_instance_method('raise_if_bind_arity_mismatch') do |method|
      method.define_argument('statement')
      method.define_argument('expected')
      method.define_argument('provided')
    end

    klass.define_instance_method('replace_bind_variable') do |method|
      method.define_argument('value')
      method.define_optional_argument('c')
    end

    klass.define_instance_method('replace_bind_variables') do |method|
      method.define_argument('statement')
      method.define_argument('values')
    end

    klass.define_instance_method('replace_named_bind_variables') do |method|
      method.define_argument('statement')
      method.define_argument('bind_vars')
    end

    klass.define_instance_method('sanitize') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('sanitize_conditions') do |method|
      method.define_argument('condition')
      method.define_optional_argument('table_name')
    end

    klass.define_instance_method('sanitize_sql') do |method|
      method.define_argument('condition')
      method.define_optional_argument('table_name')
    end

    klass.define_instance_method('sanitize_sql_array') do |method|
      method.define_argument('ary')
    end

    klass.define_instance_method('sanitize_sql_for_assignment') do |method|
      method.define_argument('assignments')
      method.define_optional_argument('default_table_name')
    end

    klass.define_instance_method('sanitize_sql_for_conditions') do |method|
      method.define_argument('condition')
      method.define_optional_argument('table_name')
    end

    klass.define_instance_method('sanitize_sql_hash') do |method|
      method.define_argument('attrs')
      method.define_optional_argument('default_table_name')
    end

    klass.define_instance_method('sanitize_sql_hash_for_assignment') do |method|
      method.define_argument('attrs')
      method.define_argument('table')
    end

    klass.define_instance_method('sanitize_sql_hash_for_conditions') do |method|
      method.define_argument('attrs')
      method.define_optional_argument('default_table_name')
    end
  end

  defs.define_constant('ActiveRecord::Schema') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Migration', RubyLint.registry))

    klass.define_method('define') do |method|
      method.define_optional_argument('info')
      method.define_block_argument('block')
    end

    klass.define_instance_method('define') do |method|
      method.define_argument('info')
      method.define_block_argument('block')
    end

    klass.define_instance_method('migrations_paths')
  end

  defs.define_constant('ActiveRecord::Schema::CheckPending') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('app')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::Schema::CommandRecorder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Migration::CommandRecorder::StraightReversions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Migration::JoinTable', RubyLint.registry))

    klass.define_instance_method('add_belongs_to') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('add_column') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('add_index') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('add_reference') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('add_timestamps') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('change_column') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('change_column_default') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('change_table') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('commands')

    klass.define_instance_method('commands=')

    klass.define_instance_method('create_join_table') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create_table') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delegate')

    klass.define_instance_method('delegate=')

    klass.define_instance_method('drop_join_table') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('drop_table') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('execute_block') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('delegate')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inverse_of') do |method|
      method.define_argument('command')
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_add_belongs_to') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('invert_remove_belongs_to') do |method|
      method.define_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('record') do |method|
      method.define_rest_argument('command')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_belongs_to') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_column') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_columns') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_index') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_reference') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('remove_timestamps') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rename_column') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rename_index') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rename_table') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('revert')

    klass.define_instance_method('reverting')

    klass.define_instance_method('reverting=')

    klass.define_instance_method('transaction') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Schema::JoinTable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Schema::ReversibleBlockHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('down')

    klass.define_instance_method('up')
  end

  defs.define_constant('ActiveRecord::SchemaDumper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('dump') do |method|
      method.define_optional_argument('connection')
      method.define_optional_argument('stream')
    end

    klass.define_method('ignore_tables')

    klass.define_method('ignore_tables=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('dump') do |method|
      method.define_argument('stream')
    end

    klass.define_instance_method('ignore_tables')

    klass.define_instance_method('ignore_tables=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('connection')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Base', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::SchemaMigration::GeneratedFeatureMethods', RubyLint.registry))

    klass.define_method('_validators')

    klass.define_method('create_table') do |method|
      method.define_optional_argument('limit')
    end

    klass.define_method('drop_table')

    klass.define_method('index_name')

    klass.define_method('table_name')

    klass.define_instance_method('version')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::ACTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::ATTRIBUTE_TYPES_CACHED_BY_DEFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::AbsenceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attr_name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::AcceptanceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('setup') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::AggregateReflection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Reflection::MacroReflection', RubyLint.registry))

    klass.define_instance_method('mapping')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::AliasTracker') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('aliased_name_for') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('aliased_name')
    end

    klass.define_instance_method('aliased_table_for') do |method|
      method.define_argument('table_name')
      method.define_optional_argument('aliased_name')
    end

    klass.define_instance_method('aliases')

    klass.define_instance_method('connection')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('connection')
      method.define_optional_argument('table_joins')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('table_joins')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::AssociatedValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Association') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('aliased_table_name')

    klass.define_instance_method('association_scope')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('initialize_attributes') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('interpolate') do |method|
      method.define_argument('sql')
      method.define_optional_argument('record')
    end

    klass.define_instance_method('inversed')

    klass.define_instance_method('inversed=')

    klass.define_instance_method('klass')

    klass.define_instance_method('load_target')

    klass.define_instance_method('loaded!')

    klass.define_instance_method('loaded?')

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('data')
    end

    klass.define_instance_method('options') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('owner')

    klass.define_instance_method('reflection')

    klass.define_instance_method('reload')

    klass.define_instance_method('reset')

    klass.define_instance_method('reset_scope')

    klass.define_instance_method('scope')

    klass.define_instance_method('scoped')

    klass.define_instance_method('set_inverse_instance') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('stale_target?')

    klass.define_instance_method('target')

    klass.define_instance_method('target=') do |method|
      method.define_argument('target')
    end

    klass.define_instance_method('target_scope')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::AssociationBuilderExtension') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('build')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::AssociationReflection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Reflection::MacroReflection', RubyLint.registry))

    klass.define_instance_method('active_record_primary_key')

    klass.define_instance_method('association_class')

    klass.define_instance_method('association_foreign_key')

    klass.define_instance_method('association_primary_key') do |method|
      method.define_optional_argument('klass')
    end

    klass.define_instance_method('belongs_to?')

    klass.define_instance_method('build_association') do |method|
      method.define_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('check_validity_of_inverse!')

    klass.define_instance_method('collection?')

    klass.define_instance_method('columns') do |method|
      method.define_argument('tbl_name')
    end

    klass.define_instance_method('counter_cache_column')

    klass.define_instance_method('foreign_key')

    klass.define_instance_method('foreign_type')

    klass.define_instance_method('has_and_belongs_to_many?')

    klass.define_instance_method('has_inverse?')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inverse_of')

    klass.define_instance_method('join_table')

    klass.define_instance_method('klass')

    klass.define_instance_method('nested?')

    klass.define_instance_method('polymorphic?')

    klass.define_instance_method('polymorphic_inverse_of') do |method|
      method.define_argument('associated_class')
    end

    klass.define_instance_method('primary_key_column')

    klass.define_instance_method('quoted_table_name')

    klass.define_instance_method('reset_column_information')

    klass.define_instance_method('scope_chain')

    klass.define_instance_method('source_macro')

    klass.define_instance_method('source_reflection')

    klass.define_instance_method('table_name')

    klass.define_instance_method('through_reflection')

    klass.define_instance_method('type')

    klass.define_instance_method('validate?')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::AssociationScope') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::JoinHelper', RubyLint.registry))

    klass.define_instance_method('active_record') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('alias_tracker')

    klass.define_instance_method('association')

    klass.define_instance_method('chain') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('association')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('interpolate') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('klass') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('options') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('owner') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('reflection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('scope')

    klass.define_instance_method('scope_chain') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('source_options') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::AttrNames') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('set_name_cache') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Attribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('serialize')

    klass.define_instance_method('serialized_value')

    klass.define_instance_method('unserialize') do |method|
      method.define_argument('v')
    end

    klass.define_instance_method('unserialized_value') do |method|
      method.define_optional_argument('v')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::BeforeTypeCast') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attributes_before_type_cast')

    klass.define_instance_method('read_attribute_before_type_cast') do |method|
      method.define_argument('attr_name')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Behavior') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_field_changed?') do |method|
      method.define_argument('attr')
      method.define_argument('old')
      method.define_argument('value')
    end

    klass.define_instance_method('attributes_before_type_cast')

    klass.define_instance_method('read_attribute_before_type_cast') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('type_cast_attribute_for_write') do |method|
      method.define_argument('column')
      method.define_argument('value')
    end

    klass.define_instance_method('typecasted_attribute_value') do |method|
      method.define_argument('name')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::BelongsToAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::SingularAssociation', RubyLint.registry))

    klass.define_instance_method('handle_dependency')

    klass.define_instance_method('replace') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('updated?')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::BelongsToPolymorphicAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::BelongsToAssociation', RubyLint.registry))

    klass.define_instance_method('klass')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Builder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::CALLBACKS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::CALL_COMPILABLE_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_update_filter') do |method|
      method.define_argument('filter_options')
      method.define_argument('new_options')
    end

    klass.define_instance_method('apply') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('chain=')

    klass.define_instance_method('clone') do |method|
      method.define_argument('chain')
      method.define_argument('klass')
    end

    klass.define_instance_method('deprecate_per_key_option') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('duplicates?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('chain')
      method.define_argument('filter')
      method.define_argument('kind')
      method.define_argument('options')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('kind=')

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('_kind')
      method.define_argument('_filter')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_id')

    klass.define_instance_method('normalize_options!') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('raw_filter')

    klass.define_instance_method('raw_filter=')

    klass.define_instance_method('recompile!') do |method|
      method.define_argument('_options')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::CallbackChain') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('compile')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Callbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('run_validations!')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('===') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('arel_engine')

    klass.define_instance_method('arel_table')

    klass.define_instance_method('generated_feature_methods')

    klass.define_instance_method('initialize_generated_modules')

    klass.define_instance_method('inspect')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Clusivity') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('check_validity!')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::CollectionAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::Association', RubyLint.registry))

    klass.define_instance_method('add_to_target') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('any?')

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('concat') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('count') do |method|
      method.define_optional_argument('column_name')
      method.define_optional_argument('count_options')
    end

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('delete_all')

    klass.define_instance_method('destroy') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('destroy_all')

    klass.define_instance_method('distinct')

    klass.define_instance_method('empty?')

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('first') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('ids_reader')

    klass.define_instance_method('ids_writer') do |method|
      method.define_argument('ids')
    end

    klass.define_instance_method('include?') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('last') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('length')

    klass.define_instance_method('load_target')

    klass.define_instance_method('many?')

    klass.define_instance_method('null_scope?')

    klass.define_instance_method('reader') do |method|
      method.define_optional_argument('force_reload')
    end

    klass.define_instance_method('replace') do |method|
      method.define_argument('other_array')
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('scope') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('select') do |method|
      method.define_optional_argument('select')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('transaction') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('uniq')

    klass.define_instance_method('writer') do |method|
      method.define_argument('records')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::CollectionProxy') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Relation', RubyLint.registry))

    klass.define_method('inherited') do |method|
      method.define_argument('subclass')
    end

    klass.define_instance_method('<<') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('any?') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('average') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('calculate') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('concat') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('count') do |method|
      method.define_optional_argument('column_name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('delete_all')

    klass.define_instance_method('destroy') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('destroy_all')

    klass.define_instance_method('distinct')

    klass.define_instance_method('empty?')

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('first') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('ids') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('include?') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('klass')
      method.define_argument('association')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('last') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('length')

    klass.define_instance_method('load_target')

    klass.define_instance_method('loaded?')

    klass.define_instance_method('many?') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('maximum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('minimum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('new') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pluck') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('proxy_association')

    klass.define_instance_method('push') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('reload')

    klass.define_instance_method('replace') do |method|
      method.define_argument('other_array')
    end

    klass.define_instance_method('scope')

    klass.define_instance_method('scoping')

    klass.define_instance_method('select') do |method|
      method.define_optional_argument('select')
      method.define_block_argument('block')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('spawn')

    klass.define_instance_method('sum') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('target')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_ary')

    klass.define_instance_method('uniq')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::ConfirmationValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('setup') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Default') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::Dirty') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('reload') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('save') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('save!') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::ExclusionValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::Clusivity', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::FormatValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::GeneratedFeatureMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::HasAndBelongsToManyAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::CollectionAssociation', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert_record') do |method|
      method.define_argument('record')
      method.define_optional_argument('validate')
      method.define_optional_argument('raise')
    end

    klass.define_instance_method('join_table')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::HasManyAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::CollectionAssociation', RubyLint.registry))

    klass.define_instance_method('handle_dependency')

    klass.define_instance_method('insert_record') do |method|
      method.define_argument('record')
      method.define_optional_argument('validate')
      method.define_optional_argument('raise')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::HasManyThroughAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::HasManyAssociation', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::ThroughAssociation', RubyLint.registry))

    klass.define_instance_method('concat') do |method|
      method.define_rest_argument('records')
    end

    klass.define_instance_method('concat_records') do |method|
      method.define_argument('records')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('owner')
      method.define_argument('reflection')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert_record') do |method|
      method.define_argument('record')
      method.define_optional_argument('validate')
      method.define_optional_argument('raise')
    end

    klass.define_instance_method('size')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::HasOneAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::SingularAssociation', RubyLint.registry))

    klass.define_instance_method('delete') do |method|
      method.define_optional_argument('method')
    end

    klass.define_instance_method('handle_dependency')

    klass.define_instance_method('replace') do |method|
      method.define_argument('record')
      method.define_optional_argument('save')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::HasOneThroughAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::HasOneAssociation', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::ThroughAssociation', RubyLint.registry))

    klass.define_instance_method('replace') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::HelperMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('validates_absence_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_acceptance_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_confirmation_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_exclusion_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_format_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_inclusion_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_length_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_numericality_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_presence_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_size_of') do |method|
      method.define_rest_argument('attr_names')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::InclusionValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::Clusivity', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::IndifferentCoder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('as_indifferent_hash') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('dump') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('coder_or_class_name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load') do |method|
      method.define_argument('yaml')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::InstanceMethodsOnActivation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('authenticate') do |method|
      method.define_argument('unencrypted_password')
    end

    klass.define_instance_method('password=') do |method|
      method.define_argument('unencrypted_password')
    end

    klass.define_instance_method('password_confirmation=') do |method|
      method.define_argument('unencrypted_password')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::JoinDependency') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('alias_tracker')

    klass.define_instance_method('base_klass')

    klass.define_instance_method('build') do |method|
      method.define_argument('associations')
      method.define_optional_argument('parent')
      method.define_optional_argument('join_type')
    end

    klass.define_instance_method('build_join_association') do |method|
      method.define_argument('reflection')
      method.define_argument('parent')
    end

    klass.define_instance_method('cache_joined_association') do |method|
      method.define_argument('association')
    end

    klass.define_instance_method('columns')

    klass.define_instance_method('construct') do |method|
      method.define_argument('parent')
      method.define_argument('associations')
      method.define_argument('join_parts')
      method.define_argument('row')
    end

    klass.define_instance_method('construct_association') do |method|
      method.define_argument('record')
      method.define_argument('join_part')
      method.define_argument('row')
    end

    klass.define_instance_method('find_join_association') do |method|
      method.define_argument('name_or_reflection')
      method.define_argument('parent')
    end

    klass.define_instance_method('graft') do |method|
      method.define_rest_argument('associations')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('base')
      method.define_argument('associations')
      method.define_argument('joins')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('instantiate') do |method|
      method.define_argument('rows')
    end

    klass.define_instance_method('join_associations')

    klass.define_instance_method('join_base')

    klass.define_instance_method('join_parts')

    klass.define_instance_method('reflections')

    klass.define_instance_method('remove_duplicate_results!') do |method|
      method.define_argument('base')
      method.define_argument('records')
      method.define_argument('associations')
    end

    klass.define_instance_method('remove_uniq_by_reflection') do |method|
      method.define_argument('reflection')
      method.define_argument('records')
    end

    klass.define_instance_method('set_target_and_inverse') do |method|
      method.define_argument('join_part')
      method.define_argument('association')
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::JoinHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('join_type')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::LengthValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::MacroReflection') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other_aggregation')
    end

    klass.define_instance_method('active_record')

    klass.define_instance_method('class_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('macro')
      method.define_argument('name')
      method.define_argument('scope')
      method.define_argument('options')
      method.define_argument('active_record')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('klass')

    klass.define_instance_method('macro')

    klass.define_instance_method('name')

    klass.define_instance_method('options')

    klass.define_instance_method('plural_name')

    klass.define_instance_method('scope')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::MultiparameterAttribute') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('column')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('object')
      method.define_argument('name')
      method.define_argument('values')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('object')

    klass.define_instance_method('read_value')

    klass.define_instance_method('values')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::NAME_COMPILABLE_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::Named') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::NumericalityValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('filtered_options') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('parse_raw_value_as_a_number') do |method|
      method.define_argument('raw_value')
    end

    klass.define_instance_method('parse_raw_value_as_an_integer') do |method|
      method.define_argument('raw_value')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attr_name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Preloader') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('associations')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('records')
      method.define_argument('associations')
      method.define_optional_argument('preload_scope')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('model')

    klass.define_instance_method('preload_scope')

    klass.define_instance_method('records')

    klass.define_instance_method('run')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::PresenceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::PresenceValidator', RubyLint.registry))

    klass.define_instance_method('validate') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::PrimaryKey') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attribute_method?') do |method|
      method.define_argument('attr_name')
    end

    klass.define_instance_method('id')

    klass.define_instance_method('id=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('id?')

    klass.define_instance_method('id_before_type_cast')

    klass.define_instance_method('to_key')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Query') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('query_attribute') do |method|
      method.define_argument('attr_name')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Read') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('read_attribute') do |method|
      method.define_argument('attr_name')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::ScopeRegistry') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize')

    klass.define_instance_method('set_value_for') do |method|
      method.define_argument('scope_type')
      method.define_argument('variable_name')
      method.define_argument('value')
    end

    klass.define_instance_method('value_for') do |method|
      method.define_argument('scope_type')
      method.define_argument('variable_name')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Serialization') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('serialized_attributes')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Serializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('serializable')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')

    klass.define_instance_method('serializable_collection')

    klass.define_instance_method('serializable_hash')

    klass.define_instance_method('serialize')
  end

  defs.define_constant('ActiveRecord::SchemaMigration::SingularAssociation') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Associations::Association', RubyLint.registry))

    klass.define_instance_method('build') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('reader') do |method|
      method.define_optional_argument('force_reload')
    end

    klass.define_instance_method('writer') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::ThroughAssociation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('chain') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('source_reflection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('target_scope')

    klass.define_instance_method('through_reflection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::ThroughReflection') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::Reflection::AssociationReflection', RubyLint.registry))

    klass.define_instance_method('active_record_primary_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('association_foreign_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('association_primary_key') do |method|
      method.define_optional_argument('klass')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('check_validity!')

    klass.define_instance_method('foreign_key') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('foreign_type') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('nested?')

    klass.define_instance_method('scope_chain')

    klass.define_instance_method('source_macro')

    klass.define_instance_method('source_options')

    klass.define_instance_method('source_reflection')

    klass.define_instance_method('source_reflection_names')

    klass.define_instance_method('through_options')

    klass.define_instance_method('through_reflection')

    klass.define_instance_method('type') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::TimeZoneConversion') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::TooManyRecords') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::TransactionError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::Type') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('column')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('type')

    klass.define_instance_method('type_cast') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::UNASSIGNABLE_KEYS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SchemaMigration::UniquenessValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('build_relation') do |method|
      method.define_argument('klass')
      method.define_argument('table')
      method.define_argument('attribute')
      method.define_argument('value')
    end

    klass.define_instance_method('deserialize_attribute') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end

    klass.define_instance_method('find_finder_class_for') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('scope_relation') do |method|
      method.define_argument('record')
      method.define_argument('table')
      method.define_argument('relation')
    end

    klass.define_instance_method('setup') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::WithValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attr')
      method.define_argument('val')
    end
  end

  defs.define_constant('ActiveRecord::SchemaMigration::Write') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('raw_write_attribute') do |method|
      method.define_argument('attr_name')
      method.define_argument('value')
    end

    klass.define_instance_method('write_attribute') do |method|
      method.define_argument('attr_name')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Scoping') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('populate_with_current_scope_attributes')
  end

  defs.define_constant('ActiveRecord::Scoping::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('current_scope')

    klass.define_instance_method('current_scope=') do |method|
      method.define_argument('scope')
    end
  end

  defs.define_constant('ActiveRecord::Serialization') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('serializable_hash') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('to_xml') do |method|
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::SerializationTypeMismatch') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::SpawnMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('except') do |method|
      method.define_rest_argument('skips')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('merge!') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('only') do |method|
      method.define_rest_argument('onlies')
    end

    klass.define_instance_method('spawn')
  end

  defs.define_constant('ActiveRecord::StaleObjectError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('attempted_action')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('record')
      method.define_argument('attempted_action')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('record')
  end

  defs.define_constant('ActiveRecord::StatementCache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('execute')

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActiveRecord::StatementInvalid') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('message')
      method.define_optional_argument('original_exception')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('original_exception')
  end

  defs.define_constant('ActiveRecord::Store') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('read_store_attribute') do |method|
      method.define_argument('store_attribute')
      method.define_argument('key')
    end

    klass.define_instance_method('write_store_attribute') do |method|
      method.define_argument('store_attribute')
      method.define_argument('key')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Store::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_store_accessors_module')

    klass.define_instance_method('store') do |method|
      method.define_argument('store_attribute')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('store_accessor') do |method|
      method.define_argument('store_attribute')
      method.define_rest_argument('keys')
    end
  end

  defs.define_constant('ActiveRecord::Store::IndifferentCoder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('as_indifferent_hash') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('dump') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('coder_or_class_name')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('load') do |method|
      method.define_argument('yaml')
    end
  end

  defs.define_constant('ActiveRecord::SubclassNotFound') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Tasks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Tasks::DatabaseTasks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('charset') do |method|
      method.define_rest_argument('arguments')
    end

    klass.define_instance_method('charset_current') do |method|
      method.define_optional_argument('environment')
    end

    klass.define_instance_method('collation') do |method|
      method.define_rest_argument('arguments')
    end

    klass.define_instance_method('collation_current') do |method|
      method.define_optional_argument('environment')
    end

    klass.define_instance_method('create') do |method|
      method.define_rest_argument('arguments')
    end

    klass.define_instance_method('create_all')

    klass.define_instance_method('create_current') do |method|
      method.define_optional_argument('environment')
    end

    klass.define_instance_method('create_database_url')

    klass.define_instance_method('current_config') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('current_config=')

    klass.define_instance_method('database_configuration')

    klass.define_instance_method('database_configuration=')

    klass.define_instance_method('db_dir')

    klass.define_instance_method('db_dir=')

    klass.define_instance_method('drop') do |method|
      method.define_rest_argument('arguments')
    end

    klass.define_instance_method('drop_all')

    klass.define_instance_method('drop_current') do |method|
      method.define_optional_argument('environment')
    end

    klass.define_instance_method('drop_database_url')

    klass.define_instance_method('env')

    klass.define_instance_method('env=')

    klass.define_instance_method('fixtures_path')

    klass.define_instance_method('fixtures_path=')

    klass.define_instance_method('load_seed')

    klass.define_instance_method('migrations_paths')

    klass.define_instance_method('migrations_paths=')

    klass.define_instance_method('purge') do |method|
      method.define_argument('configuration')
    end

    klass.define_instance_method('register_task') do |method|
      method.define_argument('pattern')
      method.define_argument('task')
    end

    klass.define_instance_method('root')

    klass.define_instance_method('root=')

    klass.define_instance_method('seed_loader')

    klass.define_instance_method('seed_loader=')

    klass.define_instance_method('structure_dump') do |method|
      method.define_rest_argument('arguments')
    end

    klass.define_instance_method('structure_load') do |method|
      method.define_rest_argument('arguments')
    end
  end

  defs.define_constant('ActiveRecord::Tasks::DatabaseTasks::LOCAL_HOSTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Tasks::FirebirdDatabaseTasks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('charset')

    klass.define_instance_method('connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create')

    klass.define_instance_method('drop')

    klass.define_instance_method('establish_connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('configuration')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('purge')

    klass.define_instance_method('structure_dump') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('structure_load') do |method|
      method.define_argument('filename')
    end
  end

  defs.define_constant('ActiveRecord::Tasks::MySQLDatabaseTasks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('charset')

    klass.define_instance_method('collation')

    klass.define_instance_method('connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create')

    klass.define_instance_method('drop')

    klass.define_instance_method('establish_connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('configuration')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('purge')

    klass.define_instance_method('structure_dump') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('structure_load') do |method|
      method.define_argument('filename')
    end
  end

  defs.define_constant('ActiveRecord::Tasks::MySQLDatabaseTasks::ACCESS_DENIED_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Tasks::MySQLDatabaseTasks::DEFAULT_CHARSET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Tasks::MySQLDatabaseTasks::DEFAULT_COLLATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Tasks::OracleDatabaseTasks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('charset')

    klass.define_instance_method('connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create')

    klass.define_instance_method('drop')

    klass.define_instance_method('establish_connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('configuration')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('purge')

    klass.define_instance_method('structure_dump') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('structure_load') do |method|
      method.define_argument('filename')
    end
  end

  defs.define_constant('ActiveRecord::Tasks::PostgreSQLDatabaseTasks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('charset')

    klass.define_instance_method('clear_active_connections!') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collation')

    klass.define_instance_method('connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create') do |method|
      method.define_optional_argument('master_established')
    end

    klass.define_instance_method('drop')

    klass.define_instance_method('establish_connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('configuration')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('purge')

    klass.define_instance_method('structure_dump') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('structure_load') do |method|
      method.define_argument('filename')
    end
  end

  defs.define_constant('ActiveRecord::Tasks::PostgreSQLDatabaseTasks::DEFAULT_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Tasks::SQLiteDatabaseTasks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('charset')

    klass.define_instance_method('connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create')

    klass.define_instance_method('drop')

    klass.define_instance_method('establish_connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('configuration')
      method.define_optional_argument('root')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('purge')

    klass.define_instance_method('structure_dump') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('structure_load') do |method|
      method.define_argument('filename')
    end
  end

  defs.define_constant('ActiveRecord::Tasks::SqlserverDatabaseTasks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('charset')

    klass.define_instance_method('connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('create')

    klass.define_instance_method('drop')

    klass.define_instance_method('establish_connection') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('configuration')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('purge')

    klass.define_instance_method('structure_dump') do |method|
      method.define_argument('filename')
    end

    klass.define_instance_method('structure_load') do |method|
      method.define_argument('filename')
    end
  end

  defs.define_constant('ActiveRecord::TestCase') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::TestCase', RubyLint.registry))

    klass.define_instance_method('assert_date_from_db') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_no_queries') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_queries') do |method|
      method.define_optional_argument('num')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('assert_sql') do |method|
      method.define_rest_argument('patterns_to_match')
    end

    klass.define_instance_method('teardown')
  end

  defs.define_constant('ActiveRecord::TestCase::Assertion') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::TestCase::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::TestCase::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_update_filter') do |method|
      method.define_argument('filter_options')
      method.define_argument('new_options')
    end

    klass.define_instance_method('apply') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('chain=')

    klass.define_instance_method('clone') do |method|
      method.define_argument('chain')
      method.define_argument('klass')
    end

    klass.define_instance_method('deprecate_per_key_option') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('duplicates?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('chain')
      method.define_argument('filter')
      method.define_argument('kind')
      method.define_argument('options')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('kind=')

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('_kind')
      method.define_argument('_filter')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_id')

    klass.define_instance_method('normalize_options!') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('raw_filter')

    klass.define_instance_method('raw_filter=')

    klass.define_instance_method('recompile!') do |method|
      method.define_argument('_options')
    end
  end

  defs.define_constant('ActiveRecord::TestCase::CallbackChain') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('compile')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('ActiveRecord::TestCase::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('__callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__callback_runner_name_cache')

    klass.define_instance_method('__define_callbacks') do |method|
      method.define_argument('kind')
      method.define_argument('object')
    end

    klass.define_instance_method('__generate_callback_runner_name') do |method|
      method.define_argument('kind')
    end

    klass.define_instance_method('__reset_runner') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('__update_callbacks') do |method|
      method.define_argument('name')
      method.define_optional_argument('filters')
      method.define_optional_argument('block')
    end

    klass.define_instance_method('define_callbacks') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('reset_callbacks') do |method|
      method.define_argument('symbol')
    end

    klass.define_instance_method('set_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end

    klass.define_instance_method('skip_callback') do |method|
      method.define_argument('name')
      method.define_rest_argument('filter_list')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::TestCase::PASSTHROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::TestCase::UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('inspect')
  end

  defs.define_constant('ActiveRecord::TestFixtures') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after_teardown')

    klass.define_instance_method('before_setup')

    klass.define_instance_method('enlist_fixture_connections')

    klass.define_instance_method('run_in_transaction?')

    klass.define_instance_method('setup_fixtures')

    klass.define_instance_method('teardown_fixtures')
  end

  defs.define_constant('ActiveRecord::TestFixtures::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('fixtures') do |method|
      method.define_rest_argument('fixture_set_names')
    end

    klass.define_instance_method('require_fixture_classes') do |method|
      method.define_optional_argument('fixture_set_names')
    end

    klass.define_instance_method('set_fixture_class') do |method|
      method.define_optional_argument('class_names')
    end

    klass.define_instance_method('setup_fixture_accessors') do |method|
      method.define_optional_argument('fixture_set_names')
    end

    klass.define_instance_method('try_to_load_dependency') do |method|
      method.define_argument('file_name')
    end

    klass.define_instance_method('uses_transaction') do |method|
      method.define_rest_argument('methods')
    end

    klass.define_instance_method('uses_transaction?') do |method|
      method.define_argument('method')
    end
  end

  defs.define_constant('ActiveRecord::ThrowResult') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Timestamp') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::TransactionIsolationError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Transactions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_to_transaction')

    klass.define_instance_method('clear_transaction_record_state')

    klass.define_instance_method('committed!')

    klass.define_instance_method('destroy')

    klass.define_instance_method('remember_transaction_record_state')

    klass.define_instance_method('restore_transaction_record_state') do |method|
      method.define_optional_argument('force')
    end

    klass.define_instance_method('rollback_active_record_state!')

    klass.define_instance_method('rolledback!') do |method|
      method.define_optional_argument('force_restore_state')
    end

    klass.define_instance_method('save') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('save!') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('transaction') do |method|
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('transaction_include_any_action?') do |method|
      method.define_argument('actions')
    end

    klass.define_instance_method('transaction_record_state') do |method|
      method.define_argument('state')
    end

    klass.define_instance_method('with_transaction_returning_status')
  end

  defs.define_constant('ActiveRecord::Transactions::ACTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Transactions::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after_commit') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('after_rollback') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('transaction') do |method|
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActiveRecord::Transactions::TransactionError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Translation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('i18n_scope')

    klass.define_instance_method('lookup_ancestors')
  end

  defs.define_constant('ActiveRecord::UnknownAttributeError') do |klass|
    klass.inherits(defs.constant_proxy('NoMethodError', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::UnknownMigrationVersionError') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('version')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActiveRecord::UnknownPrimaryKey') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::ActiveRecordError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('model')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('model')
  end

  defs.define_constant('ActiveRecord::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::VERSION::MAJOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::VERSION::MINOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::VERSION::PRE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::VERSION::STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::VERSION::TINY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActiveRecord::Validations') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('perform_validations') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('save') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('save!') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('valid?') do |method|
      method.define_optional_argument('context')
    end
  end

  defs.define_constant('ActiveRecord::Validations::AssociatedValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::Validations::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('create!') do |method|
      method.define_optional_argument('attributes')
      method.define_block_argument('block')
    end

    klass.define_instance_method('validates_associated') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_presence_of') do |method|
      method.define_rest_argument('attr_names')
    end

    klass.define_instance_method('validates_uniqueness_of') do |method|
      method.define_rest_argument('attr_names')
    end
  end

  defs.define_constant('ActiveRecord::Validations::PresenceValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::Validations::PresenceValidator', RubyLint.registry))

    klass.define_instance_method('validate') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('ActiveRecord::Validations::UniquenessValidator') do |klass|
    klass.inherits(defs.constant_proxy('ActiveModel::EachValidator', RubyLint.registry))

    klass.define_instance_method('build_relation') do |method|
      method.define_argument('klass')
      method.define_argument('table')
      method.define_argument('attribute')
      method.define_argument('value')
    end

    klass.define_instance_method('deserialize_attribute') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end

    klass.define_instance_method('find_finder_class_for') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('scope_relation') do |method|
      method.define_argument('record')
      method.define_argument('table')
      method.define_argument('relation')
    end

    klass.define_instance_method('setup') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('validate_each') do |method|
      method.define_argument('record')
      method.define_argument('attribute')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActiveRecord::WrappedDatabaseException') do |klass|
    klass.inherits(defs.constant_proxy('ActiveRecord::StatementInvalid', RubyLint.registry))

  end
end
