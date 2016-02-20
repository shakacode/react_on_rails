# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('OpenURI') do |defs|
  defs.define_constant('OpenURI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('check_options') do |method|
      method.define_argument('options')
    end

    klass.define_method('open_http') do |method|
      method.define_argument('buf')
      method.define_argument('target')
      method.define_argument('proxy')
      method.define_argument('options')
    end

    klass.define_method('open_loop') do |method|
      method.define_argument('uri')
      method.define_argument('options')
    end

    klass.define_method('open_uri') do |method|
      method.define_argument('name')
      method.define_rest_argument('rest')
    end

    klass.define_method('redirectable?') do |method|
      method.define_argument('uri1')
      method.define_argument('uri2')
    end

    klass.define_method('scan_open_optional_arguments') do |method|
      method.define_rest_argument('rest')
    end
  end

  defs.define_constant('OpenURI::Buffer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('str')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('io')

    klass.define_instance_method('size')
  end

  defs.define_constant('OpenURI::Buffer::StringMax') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenURI::HTTPError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('message')
      method.define_argument('io')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('io')
  end

  defs.define_constant('OpenURI::HTTPRedirect') do |klass|
    klass.inherits(defs.constant_proxy('OpenURI::HTTPError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('message')
      method.define_argument('io')
      method.define_argument('uri')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('uri')
  end

  defs.define_constant('OpenURI::Meta') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('init') do |method|
      method.define_argument('obj')
      method.define_optional_argument('src')
    end

    klass.define_instance_method('base_uri')

    klass.define_instance_method('base_uri=')

    klass.define_instance_method('charset')

    klass.define_instance_method('content_encoding')

    klass.define_instance_method('content_type')

    klass.define_instance_method('content_type_parse')

    klass.define_instance_method('last_modified')

    klass.define_instance_method('meta')

    klass.define_instance_method('meta_add_field') do |method|
      method.define_argument('name')
      method.define_argument('value')
    end

    klass.define_instance_method('meta_setup_encoding')

    klass.define_instance_method('status')

    klass.define_instance_method('status=')
  end

  defs.define_constant('OpenURI::Meta::RE_LWS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenURI::Meta::RE_PARAMETERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenURI::Meta::RE_QUOTED_STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenURI::Meta::RE_TOKEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('OpenURI::OpenRead') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('open') do |method|
      method.define_rest_argument('rest')
      method.define_block_argument('block')
    end

    klass.define_instance_method('read') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('OpenURI::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
