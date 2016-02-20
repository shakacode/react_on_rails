# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('DateTime') do |defs|
  defs.define_constant('DateTime') do |klass|
    klass.inherits(defs.constant_proxy('Date', RubyLint.registry))

    klass.define_method('_strptime') do |method|
      method.define_argument('str')
      method.define_optional_argument('fmt')
    end

    klass.define_method('civil') do |method|
      method.define_optional_argument('y')
      method.define_optional_argument('m')
      method.define_optional_argument('d')
      method.define_optional_argument('h')
      method.define_optional_argument('min')
      method.define_optional_argument('s')
      method.define_optional_argument('of')
      method.define_optional_argument('sg')
    end

    klass.define_method('commercial') do |method|
      method.define_optional_argument('y')
      method.define_optional_argument('w')
      method.define_optional_argument('d')
      method.define_optional_argument('h')
      method.define_optional_argument('min')
      method.define_optional_argument('s')
      method.define_optional_argument('of')
      method.define_optional_argument('sg')
    end

    klass.define_method('httpdate') do |method|
      method.define_optional_argument('str')
      method.define_optional_argument('sg')
    end

    klass.define_method('iso8601') do |method|
      method.define_optional_argument('str')
      method.define_optional_argument('sg')
    end

    klass.define_method('jd') do |method|
      method.define_optional_argument('jd')
      method.define_optional_argument('h')
      method.define_optional_argument('min')
      method.define_optional_argument('s')
      method.define_optional_argument('of')
      method.define_optional_argument('sg')
    end

    klass.define_method('jisx0301') do |method|
      method.define_optional_argument('str')
      method.define_optional_argument('sg')
    end

    klass.define_method('new') do |method|
      method.define_optional_argument('y')
      method.define_optional_argument('m')
      method.define_optional_argument('d')
      method.define_optional_argument('h')
      method.define_optional_argument('min')
      method.define_optional_argument('s')
      method.define_optional_argument('of')
      method.define_optional_argument('sg')

      method.returns { |object| object.instance }
    end

    klass.define_method('now') do |method|
      method.define_optional_argument('sg')
    end

    klass.define_method('ordinal') do |method|
      method.define_optional_argument('y')
      method.define_optional_argument('d')
      method.define_optional_argument('h')
      method.define_optional_argument('min')
      method.define_optional_argument('s')
      method.define_optional_argument('of')
      method.define_optional_argument('sg')
    end

    klass.define_method('parse') do |method|
      method.define_optional_argument('str')
      method.define_optional_argument('comp')
      method.define_optional_argument('sg')
    end

    klass.define_method('rfc2822') do |method|
      method.define_optional_argument('str')
      method.define_optional_argument('sg')
    end

    klass.define_method('rfc3339') do |method|
      method.define_optional_argument('str')
      method.define_optional_argument('sg')
    end

    klass.define_method('rfc822') do |method|
      method.define_optional_argument('str')
      method.define_optional_argument('sg')
    end

    klass.define_method('strptime') do |method|
      method.define_optional_argument('str')
      method.define_optional_argument('fmt')
      method.define_optional_argument('sg')
    end

    klass.define_method('xmlschema') do |method|
      method.define_optional_argument('str')
      method.define_optional_argument('sg')
    end

    klass.define_instance_method('hour')

    klass.define_instance_method('iso8601') do |method|
      method.define_optional_argument('n')
    end

    klass.define_instance_method('jisx0301') do |method|
      method.define_optional_argument('n')
    end

    klass.define_instance_method('min')

    klass.define_instance_method('minute')

    klass.define_instance_method('new_offset') do |method|
      method.define_optional_argument('of')
    end

    klass.define_instance_method('offset')

    klass.define_instance_method('rfc3339') do |method|
      method.define_optional_argument('n')
    end

    klass.define_instance_method('sec')

    klass.define_instance_method('sec_fraction')

    klass.define_instance_method('second')

    klass.define_instance_method('second_fraction')

    klass.define_instance_method('strftime') do |method|
      method.define_optional_argument('fmt')
    end

    klass.define_instance_method('to_date')

    klass.define_instance_method('to_datetime')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_time')

    klass.define_instance_method('xmlschema') do |method|
      method.define_optional_argument('n')
    end

    klass.define_instance_method('zone')
  end

  defs.define_constant('DateTime::ABBR_DAYNAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::ABBR_MONTHNAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::DAYNAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::ENGLAND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::Format') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::GREGORIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::HALF_DAYS_IN_DAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::HOURS_IN_DAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::ITALY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::Infinity') do |klass|
    klass.inherits(defs.constant_proxy('Numeric', RubyLint.registry))

    klass.define_instance_method('+@')

    klass.define_instance_method('-@')

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('abs')

    klass.define_instance_method('coerce') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('d')

    klass.define_instance_method('finite?')

    klass.define_instance_method('infinite?')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('d')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('nan?')

    klass.define_instance_method('zero?')
  end

  defs.define_constant('DateTime::JULIAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::LD_EPOCH_IN_CJD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::MILLISECONDS_IN_DAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::MILLISECONDS_IN_SECOND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::MINUTES_IN_DAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::MJD_EPOCH_IN_AJD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::MJD_EPOCH_IN_CJD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::MONTHNAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::NANOSECONDS_IN_DAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::NANOSECONDS_IN_SECOND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::SECONDS_IN_DAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::UNIX_EPOCH_IN_AJD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('DateTime::UNIX_EPOCH_IN_CJD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
