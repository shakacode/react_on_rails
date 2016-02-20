# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: ruby 1.9.3

RubyLint.registry.register('WIN32OLE') do |defs|
  defs.define_constant('WIN32OLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('codepage')

    klass.define_method('codepage=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('connect') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('const_load') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('create_guid')

    klass.define_method('locale')

    klass.define_method('locale=') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('ole_free') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('ole_initialize')

    klass.define_method('ole_reference_count') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('ole_show_help') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('ole_uninitialize')

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('_getproperty') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('_invoke') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('_setproperty') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('invoke') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('ole_activex_initialize')

    klass.define_instance_method('ole_free')

    klass.define_instance_method('ole_func_methods')

    klass.define_instance_method('ole_get_methods')

    klass.define_instance_method('ole_method') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('ole_method_help') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('ole_methods')

    klass.define_instance_method('ole_obj_help')

    klass.define_instance_method('ole_put_methods')

    klass.define_instance_method('ole_query_interface') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('ole_respond_to?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('ole_type')

    klass.define_instance_method('ole_typelib')

    klass.define_instance_method('setproperty') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('WIN32OLE::ARGV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::CP_ACP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::CP_MACCP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::CP_OEMCP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::CP_SYMBOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::CP_THREAD_ACP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::CP_UTF7') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::CP_UTF8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::LOCALE_SYSTEM_DEFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::LOCALE_USER_DEFAULT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_ARRAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_BOOL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_BSTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_BYREF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_CY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_DATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_DISPATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_I1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_I2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_I4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_I8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_INT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_NULL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_PTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_R4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_R8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_UI1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_UI2') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_UI4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_UI8') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_UINT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_USERDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VARIANT::VT_VARIANT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('WIN32OLE::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
