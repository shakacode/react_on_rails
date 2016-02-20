# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Benchmark') do |defs|
  defs.define_constant('Benchmark') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('benchmark') do |method|
      method.define_optional_argument('caption')
      method.define_optional_argument('label_width')
      method.define_optional_argument('format')
      method.define_rest_argument('labels')
    end

    klass.define_method('bm') do |method|
      method.define_optional_argument('label_width')
      method.define_rest_argument('labels')
      method.define_block_argument('blk')
    end

    klass.define_method('bmbm') do |method|
      method.define_optional_argument('width')
    end

    klass.define_method('measure') do |method|
      method.define_optional_argument('label')
    end

    klass.define_method('realtime')
  end

  defs.define_constant('Benchmark::BENCHMARK_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Benchmark::CAPTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Benchmark::FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Benchmark::Job') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('width')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('item') do |method|
      method.define_optional_argument('label')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('list')

    klass.define_instance_method('report') do |method|
      method.define_optional_argument('label')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('width')
  end

  defs.define_constant('Benchmark::Report') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('width')
      method.define_optional_argument('format')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('item') do |method|
      method.define_optional_argument('label')
      method.define_rest_argument('format')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('list')

    klass.define_instance_method('report') do |method|
      method.define_optional_argument('label')
      method.define_rest_argument('format')
      method.define_block_argument('blk')
    end
  end

  defs.define_constant('Benchmark::Tms') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('*') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('/') do |method|
      method.define_argument('x')
    end

    klass.define_instance_method('add') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('add!') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('cstime')

    klass.define_instance_method('cutime')

    klass.define_instance_method('format') do |method|
      method.define_optional_argument('format')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('utime')
      method.define_optional_argument('stime')
      method.define_optional_argument('cutime')
      method.define_optional_argument('cstime')
      method.define_optional_argument('real')
      method.define_optional_argument('label')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label')

    klass.define_instance_method('memberwise') do |method|
      method.define_argument('op')
      method.define_argument('x')
    end

    klass.define_instance_method('real')

    klass.define_instance_method('stime')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')

    klass.define_instance_method('total')

    klass.define_instance_method('utime')
  end

  defs.define_constant('Benchmark::Tms::CAPTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Benchmark::Tms::FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
