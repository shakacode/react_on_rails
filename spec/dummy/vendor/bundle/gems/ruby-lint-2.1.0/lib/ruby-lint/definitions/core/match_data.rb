# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('MatchData') do |defs|
  defs.define_constant('MatchData') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Unmarshalable', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('idx')
      method.define_optional_argument('len')
    end

    klass.define_instance_method('begin') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('captures')

    klass.define_instance_method('collapsing?')

    klass.define_instance_method('end') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('full')

    klass.define_instance_method('inspect')

    klass.define_instance_method('length')

    klass.define_instance_method('names')

    klass.define_instance_method('offset') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('post_match')

    klass.define_instance_method('pre_match')

    klass.define_instance_method('pre_match_from') do |method|
      method.define_argument('idx')
    end

    klass.define_instance_method('pretty_print') do |method|
      method.define_argument('q')
    end

    klass.define_instance_method('regexp')

    klass.define_instance_method('select')

    klass.define_instance_method('size')

    klass.define_instance_method('source')

    klass.define_instance_method('string')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_s')

    klass.define_instance_method('values_at') do |method|
      method.define_rest_argument('indexes')
    end
  end
end
