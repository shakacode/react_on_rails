# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Open3') do |defs|
  defs.define_constant('Open3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('capture2') do |method|
      method.define_rest_argument('cmd')
      method.define_block_argument('block')
    end

    klass.define_method('capture2e') do |method|
      method.define_rest_argument('cmd')
      method.define_block_argument('block')
    end

    klass.define_method('capture3') do |method|
      method.define_rest_argument('cmd')
      method.define_block_argument('block')
    end

    klass.define_method('pipeline') do |method|
      method.define_rest_argument('cmds')
    end

    klass.define_method('pipeline_r') do |method|
      method.define_rest_argument('cmds')
      method.define_block_argument('block')
    end

    klass.define_method('pipeline_rw') do |method|
      method.define_rest_argument('cmds')
      method.define_block_argument('block')
    end

    klass.define_method('pipeline_start') do |method|
      method.define_rest_argument('cmds')
      method.define_block_argument('block')
    end

    klass.define_method('pipeline_w') do |method|
      method.define_rest_argument('cmds')
      method.define_block_argument('block')
    end

    klass.define_method('popen2') do |method|
      method.define_rest_argument('cmd')
      method.define_block_argument('block')
    end

    klass.define_method('popen2e') do |method|
      method.define_rest_argument('cmd')
      method.define_block_argument('block')
    end

    klass.define_method('popen3') do |method|
      method.define_rest_argument('cmd')
      method.define_block_argument('block')
    end
  end
end
