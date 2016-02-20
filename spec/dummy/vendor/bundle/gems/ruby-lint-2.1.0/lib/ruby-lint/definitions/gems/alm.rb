# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: ruby 1.9.3

RubyLint.registry.register('ALM') do |defs|
  defs.define_constant('ALM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('attachWithMultipart') do |method|
      method.define_argument('defectId')
      method.define_argument('filePath')
    end

    klass.define_method('createDefect') do |method|
      method.define_argument('defect')
    end

    klass.define_method('deleteDefect') do |method|
      method.define_argument('defectId')
    end

    klass.define_method('getDefectFields') do |method|
      method.define_optional_argument('required')
    end

    klass.define_method('getValueLists') do |method|
      method.define_optional_argument('defectFields')
    end

    klass.define_method('isAuthenticated')

    klass.define_method('isLoggedIn') do |method|
      method.define_argument('username')
      method.define_argument('password')
    end

    klass.define_method('login') do |method|
      method.define_argument('loginUrl')
      method.define_argument('username')
      method.define_argument('password')
    end

    klass.define_method('logout')
  end

  defs.define_constant('ALM::Constants') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ALM::Constants::DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ALM::Constants::HOST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ALM::Constants::PASSWORD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ALM::Constants::PORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ALM::Constants::PROJECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ALM::Constants::USERNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ALM::Constants::VERSIONED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ALM::Response') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('failure')

    klass.define_instance_method('failure=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('responseData')

    klass.define_instance_method('responseData=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('responseHeaders')

    klass.define_instance_method('responseHeaders=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('statusCode')

    klass.define_instance_method('statusCode=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('toString')
  end

  defs.define_constant('ALM::RestConnector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Singleton', RubyLint.registry))

    klass.define_method('instance')

    klass.define_instance_method('buildDefectUrl') do |method|
      method.define_argument('defectId')
    end

    klass.define_instance_method('buildEntityCollectionUrl') do |method|
      method.define_argument('entityType')
    end

    klass.define_instance_method('buildUrl') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('cookies')

    klass.define_instance_method('cookies=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('domain')

    klass.define_instance_method('domain=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('getCookieString')

    klass.define_instance_method('host')

    klass.define_instance_method('host=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('httpBasicAuth') do |method|
      method.define_argument('url')
      method.define_argument('username')
      method.define_argument('password')
    end

    klass.define_instance_method('httpDelete') do |method|
      method.define_argument('url')
      method.define_argument('headers')
    end

    klass.define_instance_method('httpGet') do |method|
      method.define_argument('url')
      method.define_argument('queryString')
      method.define_argument('headers')
    end

    klass.define_instance_method('httpPost') do |method|
      method.define_argument('url')
      method.define_argument('data')
      method.define_argument('headers')
    end

    klass.define_instance_method('httpPut') do |method|
      method.define_argument('url')
      method.define_argument('data')
      method.define_argument('headers')
    end

    klass.define_instance_method('init') do |method|
      method.define_argument('cookies')
      method.define_argument('host')
      method.define_argument('port')
      method.define_argument('domain')
      method.define_argument('project')
    end

    klass.define_instance_method('port')

    klass.define_instance_method('port=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('project')

    klass.define_instance_method('project=') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('ALM::RestConnector::SingletonClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_load') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('clone')
  end
end
