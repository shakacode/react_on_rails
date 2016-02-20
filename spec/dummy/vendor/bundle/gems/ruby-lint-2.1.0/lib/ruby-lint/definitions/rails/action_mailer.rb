# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('ActionMailer') do |defs|
  defs.define_constant('ActionMailer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('version')
  end

  defs.define_constant('ActionMailer::Base') do |klass|
    klass.inherits(defs.constant_proxy('AbstractController::Base', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::Callbacks', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Callbacks', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::AssetPaths', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::Translation', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::Helpers', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::Layouts', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::Rendering', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::ViewPaths', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Benchmarkable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::Logger', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionMailer::DeliveryMethods', RubyLint.registry))

    klass.define_method('_helper_methods')

    klass.define_method('_helper_methods=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_helper_methods?')

    klass.define_method('_helpers')

    klass.define_method('_helpers=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_helpers?')

    klass.define_method('_layout')

    klass.define_method('_layout=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_layout?')

    klass.define_method('_layout_conditions')

    klass.define_method('_layout_conditions=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_layout_conditions?')

    klass.define_method('_process_action_callbacks')

    klass.define_method('_process_action_callbacks=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_process_action_callbacks?')

    klass.define_method('_view_paths')

    klass.define_method('_view_paths=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_view_paths?')

    klass.define_method('asset_host')

    klass.define_method('asset_host=') do |method|
      method.define_argument('value')
    end

    klass.define_method('assets_dir')

    klass.define_method('assets_dir=') do |method|
      method.define_argument('value')
    end

    klass.define_method('controller_path')

    klass.define_method('default') do |method|
      method.define_optional_argument('value')
    end

    klass.define_method('default_asset_host_protocol')

    klass.define_method('default_asset_host_protocol=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_options=') do |method|
      method.define_optional_argument('value')
    end

    klass.define_method('default_params')

    klass.define_method('default_params=') do |method|
      method.define_argument('val')
    end

    klass.define_method('default_params?')

    klass.define_method('deliver_mail') do |method|
      method.define_argument('mail')
    end

    klass.define_method('delivery_method')

    klass.define_method('delivery_method=') do |method|
      method.define_argument('val')
    end

    klass.define_method('delivery_method?')

    klass.define_method('delivery_methods')

    klass.define_method('delivery_methods=') do |method|
      method.define_argument('val')
    end

    klass.define_method('delivery_methods?')

    klass.define_method('file_settings')

    klass.define_method('file_settings=') do |method|
      method.define_argument('val')
    end

    klass.define_method('file_settings?')

    klass.define_method('javascripts_dir')

    klass.define_method('javascripts_dir=') do |method|
      method.define_argument('value')
    end

    klass.define_method('logger')

    klass.define_method('logger=') do |method|
      method.define_argument('value')
    end

    klass.define_method('mailer_name')

    klass.define_method('mailer_name=')

    klass.define_method('method_missing') do |method|
      method.define_argument('method_name')
      method.define_rest_argument('args')
    end

    klass.define_method('perform_deliveries')

    klass.define_method('perform_deliveries=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('protected_instance_variables')

    klass.define_method('protected_instance_variables=') do |method|
      method.define_argument('val')
    end

    klass.define_method('protected_instance_variables?')

    klass.define_method('raise_delivery_errors')

    klass.define_method('raise_delivery_errors=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('receive') do |method|
      method.define_argument('raw_mail')
    end

    klass.define_method('register_interceptor') do |method|
      method.define_argument('interceptor')
    end

    klass.define_method('register_interceptors') do |method|
      method.define_rest_argument('interceptors')
    end

    klass.define_method('register_observer') do |method|
      method.define_argument('observer')
    end

    klass.define_method('register_observers') do |method|
      method.define_rest_argument('observers')
    end

    klass.define_method('relative_url_root')

    klass.define_method('relative_url_root=') do |method|
      method.define_argument('value')
    end

    klass.define_method('respond_to?') do |method|
      method.define_argument('method')
      method.define_optional_argument('include_private')
    end

    klass.define_method('sendmail_settings')

    klass.define_method('sendmail_settings=') do |method|
      method.define_argument('val')
    end

    klass.define_method('sendmail_settings?')

    klass.define_method('set_payload_for_mail') do |method|
      method.define_argument('payload')
      method.define_argument('mail')
    end

    klass.define_method('smtp_settings')

    klass.define_method('smtp_settings=') do |method|
      method.define_argument('val')
    end

    klass.define_method('smtp_settings?')

    klass.define_method('stylesheets_dir')

    klass.define_method('stylesheets_dir=') do |method|
      method.define_argument('value')
    end

    klass.define_method('test_settings')

    klass.define_method('test_settings=') do |method|
      method.define_argument('val')
    end

    klass.define_method('test_settings?')

    klass.define_instance_method('_helper_methods')

    klass.define_instance_method('_helper_methods=')

    klass.define_instance_method('_helper_methods?')

    klass.define_instance_method('_helpers')

    klass.define_instance_method('_helpers=')

    klass.define_instance_method('_helpers?')

    klass.define_instance_method('_process_action_callbacks')

    klass.define_instance_method('_process_action_callbacks=')

    klass.define_instance_method('_process_action_callbacks?')

    klass.define_instance_method('_view_paths')

    klass.define_instance_method('_view_paths=')

    klass.define_instance_method('_view_paths?')

    klass.define_instance_method('asset_host')

    klass.define_instance_method('asset_host=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('assets_dir')

    klass.define_instance_method('assets_dir=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('attachments')

    klass.define_instance_method('collect_responses') do |method|
      method.define_argument('headers')
    end

    klass.define_instance_method('create_parts_from_responses') do |method|
      method.define_argument('m')
      method.define_argument('responses')
    end

    klass.define_instance_method('default_asset_host_protocol')

    klass.define_instance_method('default_asset_host_protocol=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('default_i18n_subject') do |method|
      method.define_optional_argument('interpolations')
    end

    klass.define_instance_method('default_params')

    klass.define_instance_method('default_params=')

    klass.define_instance_method('default_params?')

    klass.define_instance_method('delivery_method')

    klass.define_instance_method('delivery_method=')

    klass.define_instance_method('delivery_method?')

    klass.define_instance_method('delivery_methods')

    klass.define_instance_method('delivery_methods=')

    klass.define_instance_method('delivery_methods?')

    klass.define_instance_method('each_template') do |method|
      method.define_argument('paths')
      method.define_argument('name')
      method.define_block_argument('block')
    end

    klass.define_instance_method('file_settings')

    klass.define_instance_method('file_settings=')

    klass.define_instance_method('file_settings?')

    klass.define_instance_method('headers') do |method|
      method.define_optional_argument('args')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('method_name')
      method.define_rest_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert_part') do |method|
      method.define_argument('container')
      method.define_argument('response')
      method.define_argument('charset')
    end

    klass.define_instance_method('javascripts_dir')

    klass.define_instance_method('javascripts_dir=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('logger=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('mail') do |method|
      method.define_optional_argument('headers')
      method.define_block_argument('block')
    end

    klass.define_instance_method('mailer_name')

    klass.define_instance_method('message')

    klass.define_instance_method('message=')

    klass.define_instance_method('perform_deliveries')

    klass.define_instance_method('perform_deliveries=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('process') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('protected_instance_variables')

    klass.define_instance_method('protected_instance_variables=')

    klass.define_instance_method('protected_instance_variables?')

    klass.define_instance_method('raise_delivery_errors')

    klass.define_instance_method('raise_delivery_errors=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('relative_url_root')

    klass.define_instance_method('relative_url_root=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('sendmail_settings')

    klass.define_instance_method('sendmail_settings=')

    klass.define_instance_method('sendmail_settings?')

    klass.define_instance_method('set_content_type') do |method|
      method.define_argument('m')
      method.define_argument('user_content_type')
      method.define_argument('class_default')
    end

    klass.define_instance_method('smtp_settings')

    klass.define_instance_method('smtp_settings=')

    klass.define_instance_method('smtp_settings?')

    klass.define_instance_method('stylesheets_dir')

    klass.define_instance_method('stylesheets_dir=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('test_settings')

    klass.define_instance_method('test_settings=')

    klass.define_instance_method('test_settings?')
  end

  defs.define_constant('ActionMailer::Base::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::Base::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_update_filter') do |method|
      method.define_argument('filter_options')
      method.define_argument('new_options')
    end

    klass.define_instance_method('apply') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('chain=')

    klass.define_instance_method('clone') do |method|
      method.define_argument('chain')
      method.define_argument('klass')
    end

    klass.define_instance_method('deprecate_per_key_option') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('duplicates?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('chain')
      method.define_argument('filter')
      method.define_argument('kind')
      method.define_argument('options')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('kind=')

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('_kind')
      method.define_argument('_filter')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_id')

    klass.define_instance_method('normalize_options!') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('raw_filter')

    klass.define_instance_method('raw_filter=')

    klass.define_instance_method('recompile!') do |method|
      method.define_argument('_options')
    end
  end

  defs.define_constant('ActionMailer::Base::CallbackChain') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('compile')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('ActionMailer::Base::ClassMethods') do |klass|
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

  defs.define_constant('ActionMailer::Base::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::InheritableOptions', RubyLint.registry))

    klass.define_method('compile_methods!') do |method|
      method.define_argument('keys')
    end

    klass.define_instance_method('compile_methods!')
  end

  defs.define_constant('ActionMailer::Base::DEFAULT_PROTECTED_INSTANCE_VARIABLES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::Base::NullMail') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('body')

    klass.define_instance_method('method_missing') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActionMailer::Collector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::Collector', RubyLint.registry))

    klass.define_instance_method('all') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('any') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('custom') do |method|
      method.define_argument('mime')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('context')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('responses')
  end

  defs.define_constant('ActionMailer::DeliveryMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('wrap_delivery_behavior!') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActionMailer::DeliveryMethods::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_delivery_method') do |method|
      method.define_argument('symbol')
      method.define_argument('klass')
      method.define_optional_argument('default_options')
    end

    klass.define_instance_method('deliveries') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('deliveries=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('wrap_delivery_behavior') do |method|
      method.define_argument('mail')
      method.define_optional_argument('method')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionMailer::MailHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('attachments')

    klass.define_instance_method('block_format') do |method|
      method.define_argument('text')
    end

    klass.define_instance_method('format_paragraph') do |method|
      method.define_argument('text')
      method.define_optional_argument('len')
      method.define_optional_argument('indent')
    end

    klass.define_instance_method('mailer')

    klass.define_instance_method('message')
  end

  defs.define_constant('ActionMailer::Railtie') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configurable', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::Railtie::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::Railtie::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('config') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('configure') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('inherited') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('instance')

    klass.define_instance_method('method_missing') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('respond_to?') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActionMailer::Railtie::Collection') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))
    klass.inherits(defs.constant_proxy('TSort', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('tsort_each_child') do |method|
      method.define_argument('initializer')
      method.define_block_argument('block')
    end

    klass.define_instance_method('tsort_each_node')
  end

  defs.define_constant('ActionMailer::Railtie::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::Railtie::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('eager_load_namespaces')

    klass.define_instance_method('after_initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('app_generators')

    klass.define_instance_method('app_middleware')

    klass.define_instance_method('before_configuration') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_eager_load') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('before_initialize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('eager_load_namespaces')

    klass.define_instance_method('initialize')

    klass.define_instance_method('respond_to?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('to_prepare') do |method|
      method.define_block_argument('blk')
    end

    klass.define_instance_method('to_prepare_blocks')

    klass.define_instance_method('watchable_dirs')

    klass.define_instance_method('watchable_files')
  end

  defs.define_constant('ActionMailer::Railtie::Initializer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('after')

    klass.define_instance_method('before')

    klass.define_instance_method('belongs_to?') do |method|
      method.define_argument('group')
    end

    klass.define_instance_method('bind') do |method|
      method.define_argument('context')
    end

    klass.define_instance_method('block')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActionMailer::TestCase') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::TestCase', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionMailer::TestCase::Behavior', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionMailer::TestHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Testing::ConstantLookup', RubyLint.registry))

    klass.define_method('_mailer_class')

    klass.define_method('_mailer_class=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_mailer_class?')

    klass.define_method('_setup_callbacks')

    klass.define_instance_method('_mailer_class')

    klass.define_instance_method('_mailer_class=')

    klass.define_instance_method('_mailer_class?')
  end

  defs.define_constant('ActionMailer::TestCase::Assertion') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::TestCase::Behavior') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize_test_deliveries')

    klass.define_instance_method('set_expected_mail')
  end

  defs.define_constant('ActionMailer::TestCase::Behavior::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('determine_default_mailer') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('mailer_class')

    klass.define_instance_method('tests') do |method|
      method.define_argument('mailer')
    end
  end

  defs.define_constant('ActionMailer::TestCase::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::TestCase::Callback') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_update_filter') do |method|
      method.define_argument('filter_options')
      method.define_argument('new_options')
    end

    klass.define_instance_method('apply') do |method|
      method.define_argument('code')
    end

    klass.define_instance_method('chain')

    klass.define_instance_method('chain=')

    klass.define_instance_method('clone') do |method|
      method.define_argument('chain')
      method.define_argument('klass')
    end

    klass.define_instance_method('deprecate_per_key_option') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('duplicates?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('chain')
      method.define_argument('filter')
      method.define_argument('kind')
      method.define_argument('options')
      method.define_argument('klass')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('kind')

    klass.define_instance_method('kind=')

    klass.define_instance_method('klass')

    klass.define_instance_method('klass=')

    klass.define_instance_method('matches?') do |method|
      method.define_argument('_kind')
      method.define_argument('_filter')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('next_id')

    klass.define_instance_method('normalize_options!') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('raw_filter')

    klass.define_instance_method('raw_filter=')

    klass.define_instance_method('recompile!') do |method|
      method.define_argument('_options')
    end
  end

  defs.define_constant('ActionMailer::TestCase::CallbackChain') do |klass|
    klass.inherits(defs.constant_proxy('Array', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('callbacks')
    end

    klass.define_instance_method('compile')

    klass.define_instance_method('config')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('config')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('callbacks')
    end
  end

  defs.define_constant('ActionMailer::TestCase::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('determine_default_mailer') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('mailer_class')

    klass.define_instance_method('tests') do |method|
      method.define_argument('mailer')
    end
  end

  defs.define_constant('ActionMailer::TestCase::PASSTHROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::TestCase::UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('inspect')
  end

  defs.define_constant('ActionMailer::TestHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_emails') do |method|
      method.define_argument('number')
    end

    klass.define_instance_method('assert_no_emails') do |method|
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionMailer::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::VERSION::MAJOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::VERSION::MINOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::VERSION::PRE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::VERSION::STRING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionMailer::VERSION::TINY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
