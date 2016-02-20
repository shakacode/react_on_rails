# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('IPAddr') do |defs|
  defs.define_constant('IPAddr') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('new_ntoh') do |method|
      method.define_argument('addr')
    end

    klass.define_method('ntop') do |method|
      method.define_argument('addr')
    end

    klass.define_instance_method('&') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<<') do |method|
      method.define_argument('num')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('===') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('>>') do |method|
      method.define_argument('num')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('family')

    klass.define_instance_method('hash')

    klass.define_instance_method('hton')

    klass.define_instance_method('include?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('addr')
      method.define_optional_argument('family')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('ip6_arpa')

    klass.define_instance_method('ip6_int')

    klass.define_instance_method('ipv4?')

    klass.define_instance_method('ipv4_compat')

    klass.define_instance_method('ipv4_compat?')

    klass.define_instance_method('ipv4_mapped')

    klass.define_instance_method('ipv4_mapped?')

    klass.define_instance_method('ipv6?')

    klass.define_instance_method('mask') do |method|
      method.define_argument('prefixlen')
    end

    klass.define_instance_method('mask!') do |method|
      method.define_argument('mask')
    end

    klass.define_instance_method('native')

    klass.define_instance_method('reverse')

    klass.define_instance_method('set') do |method|
      method.define_argument('addr')
      method.define_rest_argument('family')
    end

    klass.define_instance_method('succ')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_range')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_string')

    klass.define_instance_method('|') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('~')
  end

  defs.define_constant('IPAddr::AddressFamilyError') do |klass|
    klass.inherits(defs.constant_proxy('IPAddr::Error', RubyLint.registry))

  end

  defs.define_constant('IPAddr::Error') do |klass|
    klass.inherits(defs.constant_proxy('ArgumentError', RubyLint.registry))

  end

  defs.define_constant('IPAddr::IN4MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IPAddr::IN6FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IPAddr::IN6MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IPAddr::InvalidAddressError') do |klass|
    klass.inherits(defs.constant_proxy('IPAddr::Error', RubyLint.registry))

  end

  defs.define_constant('IPAddr::InvalidPrefixError') do |klass|
    klass.inherits(defs.constant_proxy('IPAddr::InvalidAddressError', RubyLint.registry))

  end

  defs.define_constant('IPAddr::RE_IPV4ADDRLIKE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IPAddr::RE_IPV6ADDRLIKE_COMPRESSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('IPAddr::RE_IPV6ADDRLIKE_FULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
