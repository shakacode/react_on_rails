# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Kconv') do |defs|
  defs.define_constant('Kconv') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('guess') do |method|
      method.define_argument('str')
    end

    klass.define_method('iseuc') do |method|
      method.define_argument('str')
    end

    klass.define_method('isjis') do |method|
      method.define_argument('str')
    end

    klass.define_method('issjis') do |method|
      method.define_argument('str')
    end

    klass.define_method('isutf8') do |method|
      method.define_argument('str')
    end

    klass.define_method('kconv') do |method|
      method.define_argument('str')
      method.define_argument('to_enc')
      method.define_optional_argument('from_enc')
    end

    klass.define_method('toeuc') do |method|
      method.define_argument('str')
    end

    klass.define_method('tojis') do |method|
      method.define_argument('str')
    end

    klass.define_method('tolocale') do |method|
      method.define_argument('str')
    end

    klass.define_method('tosjis') do |method|
      method.define_argument('str')
    end

    klass.define_method('toutf16') do |method|
      method.define_argument('str')
    end

    klass.define_method('toutf32') do |method|
      method.define_argument('str')
    end

    klass.define_method('toutf8') do |method|
      method.define_argument('str')
    end
  end

  defs.define_constant('Kconv::ASCII') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Kconv::AUTO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Kconv::BINARY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Kconv::EUC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Kconv::JIS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Kconv::NOCONV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Kconv::SJIS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Kconv::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Kconv::UTF16') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Kconv::UTF32') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Kconv::UTF8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
