# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: ruby 1.9.3

RubyLint.registry.register('Tree') do |defs|
  defs.define_constant('Tree') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Tree::TreeNode') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Tree::Utils::TreeMergeHandler', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Tree::Utils::JSONConverter', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Tree::Utils::CamelCaseMethodHandler', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Tree::Utils::TreeMetricsHandler', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('child')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('name_or_index')
      method.define_optional_argument('num_as_name')
    end

    klass.define_instance_method('add') do |method|
      method.define_argument('child')
      method.define_optional_argument('at_index')
    end

    klass.define_instance_method('breadth_each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('children')

    klass.define_instance_method('content')

    klass.define_instance_method('content=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('create_dump_rep')

    klass.define_instance_method('detached_copy')

    klass.define_instance_method('detached_subtree_copy')

    klass.define_instance_method('dup')

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('each_leaf') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('first_child')

    klass.define_instance_method('first_sibling')

    klass.define_instance_method('freeze_tree!')

    klass.define_instance_method('has_children?')

    klass.define_instance_method('has_content?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_optional_argument('content')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('is_first_sibling?')

    klass.define_instance_method('is_last_sibling?')

    klass.define_instance_method('is_leaf?')

    klass.define_instance_method('is_only_child?')

    klass.define_instance_method('is_root?')

    klass.define_instance_method('last_child')

    klass.define_instance_method('last_sibling')

    klass.define_instance_method('marshal_dump')

    klass.define_instance_method('marshal_load') do |method|
      method.define_argument('dumped_tree_array')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_sibling')

    klass.define_instance_method('parent')

    klass.define_instance_method('parent=') do |method|
      method.define_argument('parent')
    end

    klass.define_instance_method('parentage')

    klass.define_instance_method('postordered_each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('preordered_each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('previous_sibling')

    klass.define_instance_method('print_tree') do |method|
      method.define_optional_argument('level')
    end

    klass.define_instance_method('remove!') do |method|
      method.define_argument('child')
    end

    klass.define_instance_method('remove_all!')

    klass.define_instance_method('remove_from_parent!')

    klass.define_instance_method('root')

    klass.define_instance_method('set_as_root!')

    klass.define_instance_method('siblings')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Tree::TreeNode::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create') do |method|
      method.define_argument('json_hash')
    end
  end

  defs.define_constant('Tree::Utils') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Tree::Utils::CamelCaseMethodHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('meth')
      method.define_rest_argument('args')
      method.define_block_argument('blk')
    end
  end

  defs.define_constant('Tree::Utils::JSONConverter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('as_json') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('to_json') do |method|
      method.define_rest_argument('a')
    end
  end

  defs.define_constant('Tree::Utils::JSONConverter::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create') do |method|
      method.define_argument('json_hash')
    end
  end

  defs.define_constant('Tree::Utils::TreeMergeHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('merge') do |method|
      method.define_argument('other_tree')
    end

    klass.define_instance_method('merge!') do |method|
      method.define_argument('other_tree')
    end
  end

  defs.define_constant('Tree::Utils::TreeMetricsHandler') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('breadth')

    klass.define_instance_method('depth')

    klass.define_instance_method('in_degree')

    klass.define_instance_method('length')

    klass.define_instance_method('level')

    klass.define_instance_method('node_depth')

    klass.define_instance_method('node_height')

    klass.define_instance_method('out_degree')

    klass.define_instance_method('size')
  end

  defs.define_constant('Tree::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
