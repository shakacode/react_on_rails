# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Time') do |defs|
  defs.define_constant('Time') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_method('__construct__') do |method|
      method.define_argument('ms')
      method.define_argument('data')
      method.define_argument('ivar_index')
      method.define_argument('has_ivar')
    end

    klass.define_method('at') do |method|
      method.define_argument('sec')
      method.define_optional_argument('usec')
    end

    klass.define_method('compose') do |method|
      method.define_argument('offset')
      method.define_argument('p1')
      method.define_optional_argument('p2')
      method.define_optional_argument('p3')
      method.define_optional_argument('p4')
      method.define_optional_argument('p5')
      method.define_optional_argument('p6')
      method.define_optional_argument('p7')
      method.define_optional_argument('yday')
      method.define_optional_argument('is_dst')
      method.define_optional_argument('tz')
    end

    klass.define_method('duplicate') do |method|
      method.define_argument('other')
    end

    klass.define_method('from_array') do |method|
      method.define_argument('sec')
      method.define_argument('min')
      method.define_argument('hour')
      method.define_argument('mday')
      method.define_argument('month')
      method.define_argument('year')
      method.define_argument('nsec')
      method.define_argument('is_dst')
      method.define_argument('from_gmt')
      method.define_argument('utc_offset')
    end

    klass.define_method('gm') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('httpdate') do |method|
      method.define_argument('date')
    end

    klass.define_method('iso8601') do |method|
      method.define_argument('date')
    end

    klass.define_method('local') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('mktime') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('new') do |method|
      method.define_optional_argument('year')
      method.define_optional_argument('month')
      method.define_optional_argument('day')
      method.define_optional_argument('hour')
      method.define_optional_argument('minute')
      method.define_optional_argument('second')
      method.define_optional_argument('utc_offset')

      method.returns { |object| object.instance }
    end

    klass.define_method('now')

    klass.define_method('parse') do |method|
      method.define_argument('date')
      method.define_optional_argument('now')
    end

    klass.define_method('rfc2822') do |method|
      method.define_argument('date')
    end

    klass.define_method('rfc822') do |method|
      method.define_argument('date')
    end

    klass.define_method('specific') do |method|
      method.define_argument('sec')
      method.define_argument('nsec')
      method.define_argument('from_gmt')
      method.define_argument('offset')
    end

    klass.define_method('strptime') do |method|
      method.define_argument('date')
      method.define_argument('format')
      method.define_optional_argument('now')
    end

    klass.define_method('utc') do |method|
      method.define_rest_argument('args')
    end

    klass.define_method('xmlschema') do |method|
      method.define_argument('date')
    end

    klass.define_method('yaml_new') do |method|
      method.define_argument('klass')
      method.define_argument('tag')
      method.define_argument('val')
    end

    klass.define_method('yaml_tag_subclasses?')

    klass.define_method('zone_offset') do |method|
      method.define_argument('zone')
      method.define_optional_argument('year')
    end

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('-') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('__custom_marshal__') do |method|
      method.define_argument('ms')
    end

    klass.define_instance_method('asctime')

    klass.define_instance_method('ctime')

    klass.define_instance_method('day')

    klass.define_instance_method('dst?')

    klass.define_instance_method('dup')

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('friday?')

    klass.define_instance_method('getgm')

    klass.define_instance_method('getlocal') do |method|
      method.define_optional_argument('offset')
    end

    klass.define_instance_method('getutc')

    klass.define_instance_method('gmt?')

    klass.define_instance_method('gmt_offset')

    klass.define_instance_method('gmtime')

    klass.define_instance_method('gmtoff')

    klass.define_instance_method('hash')

    klass.define_instance_method('hour')

    klass.define_instance_method('httpdate')

    klass.define_instance_method('inspect')

    klass.define_instance_method('isdst')

    klass.define_instance_method('iso8601') do |method|
      method.define_optional_argument('fraction_digits')
    end

    klass.define_instance_method('localtime') do |method|
      method.define_optional_argument('offset')
    end

    klass.define_instance_method('mday')

    klass.define_instance_method('min')

    klass.define_instance_method('mon')

    klass.define_instance_method('monday?')

    klass.define_instance_method('month')

    klass.define_instance_method('nsec')

    klass.define_instance_method('rake_original_time_compare') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('rfc2822')

    klass.define_instance_method('rfc822')

    klass.define_instance_method('round') do |method|
      method.define_optional_argument('places')
    end

    klass.define_instance_method('saturday?')

    klass.define_instance_method('sec')

    klass.define_instance_method('seconds')

    klass.define_instance_method('strftime') do |method|
      method.define_argument('format')
    end

    klass.define_instance_method('subsec')

    klass.define_instance_method('succ')

    klass.define_instance_method('sunday?')

    klass.define_instance_method('taguri')

    klass.define_instance_method('taguri=')

    klass.define_instance_method('thursday?')

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_date')

    klass.define_instance_method('to_datetime')

    klass.define_instance_method('to_f')

    klass.define_instance_method('to_i')

    klass.define_instance_method('to_r')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_time')

    klass.define_instance_method('to_yaml') do |method|
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('tuesday?')

    klass.define_instance_method('tv_nsec')

    klass.define_instance_method('tv_sec')

    klass.define_instance_method('tv_usec')

    klass.define_instance_method('usec')

    klass.define_instance_method('utc')

    klass.define_instance_method('utc?')

    klass.define_instance_method('utc_offset')

    klass.define_instance_method('wday')

    klass.define_instance_method('wednesday?')

    klass.define_instance_method('xmlschema') do |method|
      method.define_optional_argument('fraction_digits')
    end

    klass.define_instance_method('yday')

    klass.define_instance_method('year')

    klass.define_instance_method('zone')
  end

  defs.define_constant('Time::MonthValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Time::RFC2822_DAY_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Time::RFC2822_MONTH_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
