# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('AbstractController') do |defs|
  defs.define_constant('AbstractController') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('AbstractController::ActionNotFound') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('AbstractController::AssetPaths') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('AbstractController::Base') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Configurable', RubyLint.registry))

    klass.define_method('abstract')

    klass.define_method('abstract!')

    klass.define_method('abstract?')

    klass.define_method('action_methods')

    klass.define_method('clear_action_methods!')

    klass.define_method('controller_path')

    klass.define_method('hidden_actions')

    klass.define_method('inherited') do |method|
      method.define_argument('klass')
    end

    klass.define_method('internal_methods')

    klass.define_method('method_added') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('action_methods')

    klass.define_instance_method('action_name')

    klass.define_instance_method('action_name=')

    klass.define_instance_method('available_action?') do |method|
      method.define_argument('action_name')
    end

    klass.define_instance_method('controller_path')

    klass.define_instance_method('formats')

    klass.define_instance_method('formats=')

    klass.define_instance_method('process') do |method|
      method.define_argument('action')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('response_body')

    klass.define_instance_method('response_body=')

    klass.define_instance_method('send_action') do |method|
      method.define_argument('message')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('AbstractController::Base::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('config')

    klass.define_instance_method('config_accessor') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('configure')
  end

  defs.define_constant('AbstractController::Base::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::InheritableOptions', RubyLint.registry))

    klass.define_method('compile_methods!') do |method|
      method.define_argument('keys')
    end

    klass.define_instance_method('compile_methods!')
  end

  defs.define_constant('AbstractController::Callbacks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('process_action') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('AbstractController::Callbacks::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_insert_callbacks') do |method|
      method.define_argument('callbacks')
      method.define_optional_argument('block')
    end

    klass.define_instance_method('_normalize_callback_option') do |method|
      method.define_argument('options')
      method.define_argument('from')
      method.define_argument('to')
    end

    klass.define_instance_method('_normalize_callback_options') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('after_action') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('after_filter') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('append_after_action') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('append_after_filter') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('append_around_action') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('append_around_filter') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('append_before_action') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('append_before_filter') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('around_action') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('around_filter') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('before_action') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('before_filter') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('prepend_after_action') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('prepend_after_filter') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('prepend_around_action') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('prepend_around_filter') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('prepend_before_action') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('prepend_before_filter') do |method|
      method.define_rest_argument('names')
      method.define_block_argument('blk')
    end

    klass.define_instance_method('skip_action_callback') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('skip_after_action') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('skip_after_filter') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('skip_around_action') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('skip_around_filter') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('skip_before_action') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('skip_before_filter') do |method|
      method.define_rest_argument('names')
    end

    klass.define_instance_method('skip_filter') do |method|
      method.define_rest_argument('names')
    end
  end

  defs.define_constant('AbstractController::Collector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('generate_method_for_mime') do |method|
      method.define_argument('mime')
    end

    klass.define_instance_method('atom') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('bmp') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('css') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('csv') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('gif') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('html') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('ics') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('jpeg') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('js') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('json') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('symbol')
      method.define_block_argument('block')
    end

    klass.define_instance_method('mpeg') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('multipart_form') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('pdf') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('png') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rss') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('text') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tiff') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('url_encoded_form') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('xml') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('yaml') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('zip') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('AbstractController::DoubleRenderError') do |klass|
    klass.inherits(defs.constant_proxy('AbstractController::Error', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('message')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('AbstractController::DoubleRenderError::DEFAULT_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('AbstractController::Error') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('AbstractController::Helpers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('AbstractController::Helpers::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('clear_helpers')

    klass.define_instance_method('helper') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('helper_method') do |method|
      method.define_rest_argument('meths')
    end

    klass.define_instance_method('inherited') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('modules_for_helpers') do |method|
      method.define_argument('args')
    end
  end

  defs.define_constant('AbstractController::Helpers::ClassMethods::MissingHelperError') do |klass|
    klass.inherits(defs.constant_proxy('LoadError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('error')
      method.define_argument('path')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('AbstractController::Helpers::ClassMethods::MissingHelperError::InvalidExtensionError') do |klass|
    klass.inherits(defs.constant_proxy('LoadError', RubyLint.registry))

  end

  defs.define_constant('AbstractController::Helpers::ClassMethods::MissingHelperError::MRIExtensionError') do |klass|
    klass.inherits(defs.constant_proxy('LoadError::InvalidExtensionError', RubyLint.registry))

  end

  defs.define_constant('AbstractController::Helpers::ClassMethods::MissingHelperError::REGEXPS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('AbstractController::I18nProxy') do |klass|
    klass.inherits(defs.constant_proxy('I18n::Config', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('original_config')
      method.define_argument('lookup_context')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('locale')

    klass.define_instance_method('locale=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('lookup_context')

    klass.define_instance_method('original_config')
  end

  defs.define_constant('AbstractController::Layouts') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_layout_conditions') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('_normalize_options') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('action_has_layout=')

    klass.define_instance_method('action_has_layout?')
  end

  defs.define_constant('AbstractController::Layouts::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_implied_layout_name')

    klass.define_instance_method('_write_layout_method')

    klass.define_instance_method('inherited') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('layout') do |method|
      method.define_argument('layout')
      method.define_optional_argument('conditions')
    end
  end

  defs.define_constant('AbstractController::Layouts::ClassMethods::LayoutConditions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('AbstractController::Logger') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('AbstractController::Railties') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('AbstractController::Railties::RoutesHelpers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('with') do |method|
      method.define_argument('routes')
    end
  end

  defs.define_constant('AbstractController::Rendering') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_render_template') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('process') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('render') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('render_to_body') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('render_to_string') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('view_assigns')

    klass.define_instance_method('view_context')

    klass.define_instance_method('view_context_class')

    klass.define_instance_method('view_context_class=')

    klass.define_instance_method('view_renderer')
  end

  defs.define_constant('AbstractController::Rendering::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('view_context_class')
  end

  defs.define_constant('AbstractController::Rendering::DEFAULT_PROTECTED_INSTANCE_VARIABLES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('AbstractController::Translation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('l') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('localize') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('t') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('translate') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('AbstractController::UrlFor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_routes')
  end

  defs.define_constant('AbstractController::UrlFor::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_routes')

    klass.define_instance_method('action_methods')
  end

  defs.define_constant('AbstractController::ViewPaths') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_prefixes')

    klass.define_instance_method('append_view_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('details_for_lookup')

    klass.define_instance_method('formats') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('formats=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('locale') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('locale=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('lookup_context')

    klass.define_instance_method('prepend_view_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('template_exists?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('view_paths') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('AbstractController::ViewPaths::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('append_view_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('parent_prefixes')

    klass.define_instance_method('prepend_view_path') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('view_paths')

    klass.define_instance_method('view_paths=') do |method|
      method.define_argument('paths')
    end
  end
end
