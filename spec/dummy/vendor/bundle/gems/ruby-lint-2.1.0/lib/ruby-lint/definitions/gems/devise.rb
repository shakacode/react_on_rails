# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('Devise') do |defs|
  defs.define_constant('Devise') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_mapping') do |method|
      method.define_argument('resource')
      method.define_argument('options')
    end

    klass.define_method('add_module') do |method|
      method.define_argument('module_name')
      method.define_optional_argument('options')
    end

    klass.define_method('allow_insecure_sign_in_after_confirmation')

    klass.define_method('allow_insecure_sign_in_after_confirmation=') do |method|
      method.define_argument('val')
    end

    klass.define_method('allow_insecure_token_lookup')

    klass.define_method('allow_insecure_token_lookup=') do |method|
      method.define_argument('val')
    end

    klass.define_method('allow_unconfirmed_access_for')

    klass.define_method('allow_unconfirmed_access_for=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('authentication_keys')

    klass.define_method('authentication_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('available_router_name')

    klass.define_method('bcrypt') do |method|
      method.define_argument('klass')
      method.define_argument('password')
    end

    klass.define_method('case_insensitive_keys')

    klass.define_method('case_insensitive_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('clean_up_csrf_token_on_authentication')

    klass.define_method('clean_up_csrf_token_on_authentication=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('configure_warden!')

    klass.define_method('confirm_within')

    klass.define_method('confirm_within=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('confirmation_keys')

    klass.define_method('confirmation_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('default_scope')

    klass.define_method('default_scope=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('email_regexp')

    klass.define_method('email_regexp=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('expire_auth_token_on_timeout')

    klass.define_method('expire_auth_token_on_timeout=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('extend_remember_period')

    klass.define_method('extend_remember_period=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('friendly_token')

    klass.define_method('helpers')

    klass.define_method('http_authenticatable')

    klass.define_method('http_authenticatable=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('http_authenticatable_on_xhr')

    klass.define_method('http_authenticatable_on_xhr=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('http_authentication_key')

    klass.define_method('http_authentication_key=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('http_authentication_realm')

    klass.define_method('http_authentication_realm=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('include_helpers') do |method|
      method.define_argument('scope')
    end

    klass.define_method('last_attempt_warning')

    klass.define_method('last_attempt_warning=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('lock_strategy')

    klass.define_method('lock_strategy=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('mailer')

    klass.define_method('mailer=') do |method|
      method.define_argument('class_name')
    end

    klass.define_method('mailer_sender')

    klass.define_method('mailer_sender=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('mappings')

    klass.define_method('maximum_attempts')

    klass.define_method('maximum_attempts=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('navigational_formats')

    klass.define_method('navigational_formats=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('omniauth') do |method|
      method.define_argument('provider')
      method.define_rest_argument('args')
    end

    klass.define_method('omniauth_configs')

    klass.define_method('omniauth_path_prefix')

    klass.define_method('omniauth_path_prefix=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('omniauth_providers')

    klass.define_method('params_authenticatable')

    klass.define_method('params_authenticatable=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('paranoid')

    klass.define_method('paranoid=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('parent_controller')

    klass.define_method('parent_controller=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('parent_mailer')

    klass.define_method('parent_mailer=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('password_length')

    klass.define_method('password_length=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('pepper')

    klass.define_method('pepper=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('reconfirmable')

    klass.define_method('reconfirmable=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('ref') do |method|
      method.define_argument('arg')
    end

    klass.define_method('regenerate_helpers!')

    klass.define_method('remember_for')

    klass.define_method('remember_for=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('rememberable_options')

    klass.define_method('rememberable_options=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('request_keys')

    klass.define_method('request_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('reset_password_keys')

    klass.define_method('reset_password_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('reset_password_within')

    klass.define_method('reset_password_within=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('router_name')

    klass.define_method('router_name=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('scoped_views')

    klass.define_method('scoped_views=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('secret_key')

    klass.define_method('secret_key=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('secure_compare') do |method|
      method.define_argument('a')
      method.define_argument('b')
    end

    klass.define_method('setup')

    klass.define_method('sign_out_all_scopes')

    klass.define_method('sign_out_all_scopes=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('sign_out_via')

    klass.define_method('sign_out_via=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('skip_session_storage')

    klass.define_method('skip_session_storage=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('stretches')

    klass.define_method('stretches=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('strip_whitespace_keys')

    klass.define_method('strip_whitespace_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('timeout_in')

    klass.define_method('timeout_in=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('token_authentication_key')

    klass.define_method('token_authentication_key=') do |method|
      method.define_argument('val')
    end

    klass.define_method('token_generator')

    klass.define_method('token_generator=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('unlock_in')

    klass.define_method('unlock_in=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('unlock_keys')

    klass.define_method('unlock_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('unlock_strategy')

    klass.define_method('unlock_strategy=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('warden') do |method|
      method.define_block_argument('block')
    end

    klass.define_method('warden_config')

    klass.define_method('warden_config=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('allow_unconfirmed_access_for')

    klass.define_instance_method('allow_unconfirmed_access_for=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('authentication_keys')

    klass.define_instance_method('authentication_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('case_insensitive_keys')

    klass.define_instance_method('case_insensitive_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('clean_up_csrf_token_on_authentication')

    klass.define_instance_method('clean_up_csrf_token_on_authentication=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('confirm_within')

    klass.define_instance_method('confirm_within=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('confirmation_keys')

    klass.define_instance_method('confirmation_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('default_scope')

    klass.define_instance_method('default_scope=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('email_regexp')

    klass.define_instance_method('email_regexp=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('expire_auth_token_on_timeout')

    klass.define_instance_method('expire_auth_token_on_timeout=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('extend_remember_period')

    klass.define_instance_method('extend_remember_period=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('helpers')

    klass.define_instance_method('http_authenticatable')

    klass.define_instance_method('http_authenticatable=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('http_authenticatable_on_xhr')

    klass.define_instance_method('http_authenticatable_on_xhr=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('http_authentication_key')

    klass.define_instance_method('http_authentication_key=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('http_authentication_realm')

    klass.define_instance_method('http_authentication_realm=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('last_attempt_warning')

    klass.define_instance_method('last_attempt_warning=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('lock_strategy')

    klass.define_instance_method('lock_strategy=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('mailer_sender')

    klass.define_instance_method('mailer_sender=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('mappings')

    klass.define_instance_method('maximum_attempts')

    klass.define_instance_method('maximum_attempts=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('navigational_formats')

    klass.define_instance_method('navigational_formats=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('omniauth_configs')

    klass.define_instance_method('omniauth_path_prefix')

    klass.define_instance_method('omniauth_path_prefix=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('params_authenticatable')

    klass.define_instance_method('params_authenticatable=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('paranoid')

    klass.define_instance_method('paranoid=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('parent_controller')

    klass.define_instance_method('parent_controller=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('parent_mailer')

    klass.define_instance_method('parent_mailer=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('password_length')

    klass.define_instance_method('password_length=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('pepper')

    klass.define_instance_method('pepper=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('reconfirmable')

    klass.define_instance_method('reconfirmable=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('remember_for')

    klass.define_instance_method('remember_for=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('rememberable_options')

    klass.define_instance_method('rememberable_options=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('request_keys')

    klass.define_instance_method('request_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('reset_password_keys')

    klass.define_instance_method('reset_password_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('reset_password_within')

    klass.define_instance_method('reset_password_within=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('router_name')

    klass.define_instance_method('router_name=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('scoped_views')

    klass.define_instance_method('scoped_views=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('secret_key')

    klass.define_instance_method('secret_key=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('sign_out_all_scopes')

    klass.define_instance_method('sign_out_all_scopes=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('sign_out_via')

    klass.define_instance_method('sign_out_via=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('skip_session_storage')

    klass.define_instance_method('skip_session_storage=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('stretches')

    klass.define_instance_method('stretches=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('strip_whitespace_keys')

    klass.define_instance_method('strip_whitespace_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('timeout_in')

    klass.define_instance_method('timeout_in=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('token_generator')

    klass.define_instance_method('token_generator=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('unlock_in')

    klass.define_instance_method('unlock_in=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('unlock_keys')

    klass.define_instance_method('unlock_keys=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('unlock_strategy')

    klass.define_instance_method('unlock_strategy=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('warden_config')

    klass.define_instance_method('warden_config=') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('Devise::ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::BaseSanitizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('for') do |method|
      method.define_argument('kind')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('resource_class')
      method.define_argument('resource_name')
      method.define_argument('params')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('params')

    klass.define_instance_method('resource_class')

    klass.define_instance_method('resource_name')

    klass.define_instance_method('sanitize') do |method|
      method.define_argument('kind')
    end
  end

  defs.define_constant('Devise::CONTROLLERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::Controllers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::Controllers::Helpers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('define_helpers') do |method|
      method.define_argument('mapping')
    end

    klass.define_instance_method('after_sign_in_path_for') do |method|
      method.define_argument('resource_or_scope')
    end

    klass.define_instance_method('after_sign_out_path_for') do |method|
      method.define_argument('resource_or_scope')
    end

    klass.define_instance_method('allow_params_authentication!')

    klass.define_instance_method('devise_controller?')

    klass.define_instance_method('devise_parameter_sanitizer')

    klass.define_instance_method('handle_unverified_request')

    klass.define_instance_method('is_flashing_format?')

    klass.define_instance_method('is_navigational_format?')

    klass.define_instance_method('request_format')

    klass.define_instance_method('sign_in_and_redirect') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('sign_out_and_redirect') do |method|
      method.define_argument('resource_or_scope')
    end

    klass.define_instance_method('signed_in_root_path') do |method|
      method.define_argument('resource_or_scope')
    end

    klass.define_instance_method('warden')
  end

  defs.define_constant('Devise::Controllers::Helpers::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('log_process_action') do |method|
      method.define_argument('payload')
    end
  end

  defs.define_constant('Devise::Controllers::Rememberable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cookie_values')

    klass.define_instance_method('forget_cookie_values') do |method|
      method.define_argument('resource')
    end

    klass.define_instance_method('forget_me') do |method|
      method.define_argument('resource')
    end

    klass.define_instance_method('remember_cookie_values') do |method|
      method.define_argument('resource')
    end

    klass.define_instance_method('remember_key') do |method|
      method.define_argument('resource')
      method.define_argument('scope')
    end

    klass.define_instance_method('remember_me') do |method|
      method.define_argument('resource')
    end
  end

  defs.define_constant('Devise::Controllers::ScopedViews') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::Controllers::ScopedViews::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('scoped_views=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('scoped_views?')
  end

  defs.define_constant('Devise::Controllers::SignInOut') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('sign_in') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('sign_out') do |method|
      method.define_optional_argument('resource_or_scope')
    end

    klass.define_instance_method('sign_out_all_scopes') do |method|
      method.define_optional_argument('lock')
    end

    klass.define_instance_method('signed_in?') do |method|
      method.define_optional_argument('scope')
    end
  end

  defs.define_constant('Devise::Controllers::StoreLocation') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('store_location_for') do |method|
      method.define_argument('resource_or_scope')
      method.define_argument('location')
    end

    klass.define_instance_method('stored_location_for') do |method|
      method.define_argument('resource_or_scope')
    end
  end

  defs.define_constant('Devise::Controllers::UrlHelpers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('generate_helpers!') do |method|
      method.define_optional_argument('routes')
    end

    klass.define_method('remove_helpers!')

    klass.define_instance_method('cancel_registration_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('cancel_registration_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('confirmation_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('confirmation_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('destroy_session_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('destroy_session_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('edit_password_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('edit_password_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('edit_registration_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('edit_registration_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('new_confirmation_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('new_confirmation_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('new_password_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('new_password_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('new_registration_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('new_registration_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('new_session_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('new_session_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('new_unlock_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('new_unlock_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('password_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('password_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('registration_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('registration_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('session_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('session_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('unlock_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('unlock_url') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Devise::Delegator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('env')
    end

    klass.define_instance_method('failure_app') do |method|
      method.define_argument('env')
    end
  end

  defs.define_constant('Devise::Engine') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Engine', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configurable', RubyLint.registry))

  end

  defs.define_constant('Devise::Engine::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::Engine::ClassMethods') do |klass|
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

  defs.define_constant('Devise::Engine::Collection') do |klass|
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

  defs.define_constant('Devise::Engine::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::Engine::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configuration', RubyLint.registry))

    klass.define_instance_method('autoload_once_paths')

    klass.define_instance_method('autoload_once_paths=')

    klass.define_instance_method('autoload_paths')

    klass.define_instance_method('autoload_paths=')

    klass.define_instance_method('eager_load_paths')

    klass.define_instance_method('eager_load_paths=')

    klass.define_instance_method('generators')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('root')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('middleware')

    klass.define_instance_method('middleware=')

    klass.define_instance_method('paths')

    klass.define_instance_method('root')

    klass.define_instance_method('root=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Devise::Engine::Initializer') do |klass|
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

  defs.define_constant('Devise::Engine::Railties') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_method('engines')

    klass.define_instance_method('-') do |method|
      method.define_argument('others')
    end

    klass.define_instance_method('_all')

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('engines') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('engines_with_deprecation') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('engines_without_deprecation') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize')
  end

  defs.define_constant('Devise::Getter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('get')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Devise::Hooks') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::Hooks::Proxy') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Devise::Controllers::SignInOut', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Devise::Controllers::Rememberable', RubyLint.registry))

    klass.define_instance_method('cookies') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('env') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('warden')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('session')

    klass.define_instance_method('warden')
  end

  defs.define_constant('Devise::Mailers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::Mailers::Helpers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('devise_mail') do |method|
      method.define_argument('record')
      method.define_argument('action')
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('devise_mapping')

    klass.define_instance_method('headers_for') do |method|
      method.define_argument('action')
      method.define_argument('opts')
    end

    klass.define_instance_method('initialize_from_record') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('mailer_from') do |method|
      method.define_argument('mapping')
    end

    klass.define_instance_method('mailer_reply_to') do |method|
      method.define_argument('mapping')
    end

    klass.define_instance_method('mailer_sender') do |method|
      method.define_argument('mapping')
      method.define_optional_argument('sender')
    end

    klass.define_instance_method('subject_for') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('template_paths')
  end

  defs.define_constant('Devise::Mapping') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_module') do |method|
      method.define_argument('m')
    end

    klass.define_method('find_by_path!') do |method|
      method.define_argument('path')
      method.define_optional_argument('path_type')
    end

    klass.define_method('find_scope!') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('authenticatable?')

    klass.define_instance_method('class_name')

    klass.define_instance_method('confirmable?')

    klass.define_instance_method('controllers')

    klass.define_instance_method('database_authenticatable?')

    klass.define_instance_method('failure_app')

    klass.define_instance_method('format')

    klass.define_instance_method('fullpath')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lockable?')

    klass.define_instance_method('modules')

    klass.define_instance_method('name')

    klass.define_instance_method('no_input_strategies')

    klass.define_instance_method('omniauthable?')

    klass.define_instance_method('path')

    klass.define_instance_method('path_names')

    klass.define_instance_method('recoverable?')

    klass.define_instance_method('registerable?')

    klass.define_instance_method('rememberable?')

    klass.define_instance_method('routes')

    klass.define_instance_method('scoped_path')

    klass.define_instance_method('sign_out_via')

    klass.define_instance_method('singular')

    klass.define_instance_method('strategies')

    klass.define_instance_method('timeoutable?')

    klass.define_instance_method('to')

    klass.define_instance_method('trackable?')

    klass.define_instance_method('used_helpers')

    klass.define_instance_method('used_routes')

    klass.define_instance_method('validatable?')
  end

  defs.define_constant('Devise::Models') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('check_fields!') do |method|
      method.define_argument('klass')
    end

    klass.define_method('config') do |method|
      method.define_argument('mod')
      method.define_rest_argument('accessors')
    end

    klass.define_instance_method('devise') do |method|
      method.define_rest_argument('modules')
    end

    klass.define_instance_method('devise_modules_hook!')
  end

  defs.define_constant('Devise::Models::Authenticatable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('active_for_authentication?')

    klass.define_instance_method('apply_to_attribute_or_variable') do |method|
      method.define_argument('attr')
      method.define_argument('method')
    end

    klass.define_instance_method('authenticatable_salt')

    klass.define_instance_method('devise_mailer')

    klass.define_instance_method('downcase_keys')

    klass.define_instance_method('inactive_message')

    klass.define_instance_method('send_devise_notification') do |method|
      method.define_argument('notification')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('serializable_hash') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('strip_whitespace')

    klass.define_instance_method('unauthenticated_message')

    klass.define_instance_method('valid_for_authentication?')
  end

  defs.define_constant('Devise::Models::Authenticatable::BLACKLIST_FOR_SERIALIZATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::Models::Authenticatable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_configs')

    klass.define_method('available_configs=')

    klass.define_instance_method('authentication_keys')

    klass.define_instance_method('authentication_keys=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('case_insensitive_keys')

    klass.define_instance_method('case_insensitive_keys=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('devise_parameter_filter')

    klass.define_instance_method('find_first_by_auth_conditions') do |method|
      method.define_argument('tainted_conditions')
      method.define_optional_argument('opts')
    end

    klass.define_instance_method('find_for_authentication') do |method|
      method.define_argument('tainted_conditions')
    end

    klass.define_instance_method('find_or_initialize_with_error_by') do |method|
      method.define_argument('attribute')
      method.define_argument('value')
      method.define_optional_argument('error')
    end

    klass.define_instance_method('find_or_initialize_with_errors') do |method|
      method.define_argument('required_attributes')
      method.define_argument('attributes')
      method.define_optional_argument('error')
    end

    klass.define_instance_method('http_authenticatable')

    klass.define_instance_method('http_authenticatable=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('http_authenticatable?') do |method|
      method.define_argument('strategy')
    end

    klass.define_instance_method('http_authentication_key')

    klass.define_instance_method('http_authentication_key=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('params_authenticatable')

    klass.define_instance_method('params_authenticatable=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('params_authenticatable?') do |method|
      method.define_argument('strategy')
    end

    klass.define_instance_method('request_keys')

    klass.define_instance_method('request_keys=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('serialize_from_session') do |method|
      method.define_argument('key')
      method.define_argument('salt')
    end

    klass.define_instance_method('serialize_into_session') do |method|
      method.define_argument('record')
    end

    klass.define_instance_method('skip_session_storage')

    klass.define_instance_method('skip_session_storage=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('strip_whitespace_keys')

    klass.define_instance_method('strip_whitespace_keys=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Devise::Models::Confirmable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('active_for_authentication?')

    klass.define_instance_method('after_confirmation')

    klass.define_instance_method('confirm!')

    klass.define_instance_method('confirmation_period_expired?')

    klass.define_instance_method('confirmation_period_valid?')

    klass.define_instance_method('confirmation_required?')

    klass.define_instance_method('confirmed?')

    klass.define_instance_method('generate_confirmation_token')

    klass.define_instance_method('generate_confirmation_token!')

    klass.define_instance_method('inactive_message')

    klass.define_instance_method('pending_any_confirmation')

    klass.define_instance_method('pending_reconfirmation?')

    klass.define_instance_method('postpone_email_change?')

    klass.define_instance_method('postpone_email_change_until_confirmation_and_regenerate_confirmation_token')

    klass.define_instance_method('reconfirmation_required?')

    klass.define_instance_method('resend_confirmation_instructions')

    klass.define_instance_method('send_confirmation_instructions')

    klass.define_instance_method('send_confirmation_notification?')

    klass.define_instance_method('send_on_create_confirmation_instructions')

    klass.define_instance_method('send_reconfirmation_instructions')

    klass.define_instance_method('skip_confirmation!')

    klass.define_instance_method('skip_confirmation_notification!')

    klass.define_instance_method('skip_reconfirmation!')
  end

  defs.define_constant('Devise::Models::Confirmable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_configs')

    klass.define_method('available_configs=')

    klass.define_instance_method('allow_unconfirmed_access_for')

    klass.define_instance_method('allow_unconfirmed_access_for=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('confirm_by_token') do |method|
      method.define_argument('confirmation_token')
    end

    klass.define_instance_method('confirm_within')

    klass.define_instance_method('confirm_within=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('confirmation_keys')

    klass.define_instance_method('confirmation_keys=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('find_by_unconfirmed_email_with_errors') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('reconfirmable')

    klass.define_instance_method('reconfirmable=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('send_confirmation_instructions') do |method|
      method.define_optional_argument('attributes')
    end
  end

  defs.define_constant('Devise::Models::DatabaseAuthenticatable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('after_database_authentication')

    klass.define_instance_method('authenticatable_salt')

    klass.define_instance_method('clean_up_passwords')

    klass.define_instance_method('destroy_with_password') do |method|
      method.define_argument('current_password')
    end

    klass.define_instance_method('password=') do |method|
      method.define_argument('new_password')
    end

    klass.define_instance_method('password_digest') do |method|
      method.define_argument('password')
    end

    klass.define_instance_method('update_with_password') do |method|
      method.define_argument('params')
      method.define_rest_argument('options')
    end

    klass.define_instance_method('update_without_password') do |method|
      method.define_argument('params')
      method.define_rest_argument('options')
    end

    klass.define_instance_method('valid_password?') do |method|
      method.define_argument('password')
    end
  end

  defs.define_constant('Devise::Models::DatabaseAuthenticatable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_configs')

    klass.define_method('available_configs=')

    klass.define_instance_method('find_for_database_authentication') do |method|
      method.define_argument('conditions')
    end

    klass.define_instance_method('pepper')

    klass.define_instance_method('pepper=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('stretches')

    klass.define_instance_method('stretches=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Devise::Models::Lockable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('access_locked?')

    klass.define_instance_method('active_for_authentication?')

    klass.define_instance_method('attempts_exceeded?')

    klass.define_instance_method('if_access_locked')

    klass.define_instance_method('inactive_message')

    klass.define_instance_method('last_attempt?')

    klass.define_instance_method('lock_access!')

    klass.define_instance_method('lock_expired?')

    klass.define_instance_method('lock_strategy_enabled?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('resend_unlock_instructions')

    klass.define_instance_method('send_unlock_instructions')

    klass.define_instance_method('unauthenticated_message')

    klass.define_instance_method('unlock_access!')

    klass.define_instance_method('unlock_strategy_enabled?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('valid_for_authentication?')
  end

  defs.define_constant('Devise::Models::Lockable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_configs')

    klass.define_method('available_configs=')

    klass.define_instance_method('lock_strategy')

    klass.define_instance_method('lock_strategy=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('lock_strategy_enabled?') do |method|
      method.define_argument('strategy')
    end

    klass.define_instance_method('maximum_attempts')

    klass.define_instance_method('maximum_attempts=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('send_unlock_instructions') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('unlock_access_by_token') do |method|
      method.define_argument('unlock_token')
    end

    klass.define_instance_method('unlock_in')

    klass.define_instance_method('unlock_in=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('unlock_keys')

    klass.define_instance_method('unlock_keys=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('unlock_strategy')

    klass.define_instance_method('unlock_strategy=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('unlock_strategy_enabled?') do |method|
      method.define_argument('strategy')
    end
  end

  defs.define_constant('Devise::Models::MissingAttribute') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('attributes')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('message')
  end

  defs.define_constant('Devise::Models::Omniauthable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end
  end

  defs.define_constant('Devise::Models::Omniauthable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_configs')

    klass.define_method('available_configs=')

    klass.define_instance_method('omniauth_providers')

    klass.define_instance_method('omniauth_providers=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Devise::Models::Recoverable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('after_password_reset')

    klass.define_instance_method('clear_reset_password_token')

    klass.define_instance_method('reset_password!') do |method|
      method.define_argument('new_password')
      method.define_argument('new_password_confirmation')
    end

    klass.define_instance_method('reset_password_period_valid?')

    klass.define_instance_method('send_reset_password_instructions')
  end

  defs.define_constant('Devise::Models::Recoverable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_configs')

    klass.define_method('available_configs=')

    klass.define_instance_method('reset_password_by_token') do |method|
      method.define_optional_argument('attributes')
    end

    klass.define_instance_method('reset_password_keys')

    klass.define_instance_method('reset_password_keys=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('reset_password_within')

    klass.define_instance_method('reset_password_within=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('send_reset_password_instructions') do |method|
      method.define_optional_argument('attributes')
    end
  end

  defs.define_constant('Devise::Models::Registerable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end
  end

  defs.define_constant('Devise::Models::Registerable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('new_with_session') do |method|
      method.define_argument('params')
      method.define_argument('session')
    end
  end

  defs.define_constant('Devise::Models::Rememberable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('extend_remember_period')

    klass.define_instance_method('extend_remember_period=')

    klass.define_instance_method('forget_me!')

    klass.define_instance_method('generate_remember_timestamp?') do |method|
      method.define_argument('extend_period')
    end

    klass.define_instance_method('generate_remember_token?')

    klass.define_instance_method('remember_expired?')

    klass.define_instance_method('remember_expires_at')

    klass.define_instance_method('remember_me')

    klass.define_instance_method('remember_me!') do |method|
      method.define_optional_argument('extend_period')
    end

    klass.define_instance_method('remember_me=')

    klass.define_instance_method('rememberable_options')

    klass.define_instance_method('rememberable_value')
  end

  defs.define_constant('Devise::Models::Rememberable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_configs')

    klass.define_method('available_configs=')

    klass.define_instance_method('extend_remember_period')

    klass.define_instance_method('extend_remember_period=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('remember_for')

    klass.define_instance_method('remember_for=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('remember_token')

    klass.define_instance_method('rememberable_options')

    klass.define_instance_method('rememberable_options=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('serialize_from_cookie') do |method|
      method.define_argument('id')
      method.define_argument('remember_token')
    end

    klass.define_instance_method('serialize_into_cookie') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('Devise::Models::Timeoutable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('timedout?') do |method|
      method.define_argument('last_access')
    end

    klass.define_instance_method('timeout_in')
  end

  defs.define_constant('Devise::Models::Timeoutable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_configs')

    klass.define_method('available_configs=')

    klass.define_instance_method('timeout_in')

    klass.define_instance_method('timeout_in=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Devise::Models::Trackable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('update_tracked_fields!') do |method|
      method.define_argument('request')
    end
  end

  defs.define_constant('Devise::Models::Validatable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('assert_validations_api!') do |method|
      method.define_argument('base')
    end

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_method('required_fields') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('email_required?')

    klass.define_instance_method('password_required?')
  end

  defs.define_constant('Devise::Models::Validatable::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('available_configs')

    klass.define_method('available_configs=')

    klass.define_instance_method('email_regexp')

    klass.define_instance_method('email_regexp=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('password_length')

    klass.define_instance_method('password_length=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('Devise::Models::Validatable::VALIDATIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::NO_INPUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::OmniAuth') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::OmniAuth::Config') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('args')

    klass.define_instance_method('autoload_strategy')

    klass.define_instance_method('find_strategy')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('provider')
      method.define_argument('args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('options')

    klass.define_instance_method('provider')

    klass.define_instance_method('strategy')

    klass.define_instance_method('strategy=')

    klass.define_instance_method('strategy_class')

    klass.define_instance_method('strategy_name')
  end

  defs.define_constant('Devise::OmniAuth::UrlHelpers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('define_helpers') do |method|
      method.define_argument('mapping')
    end

    klass.define_instance_method('omniauth_authorize_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('omniauth_callback_path') do |method|
      method.define_argument('resource_or_scope')
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('Devise::ParameterFilter') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('filter') do |method|
      method.define_argument('conditions')
    end

    klass.define_instance_method('filtered_hash_by_method_for_given_keys') do |method|
      method.define_argument('conditions')
      method.define_argument('method')
      method.define_argument('condition_keys')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('case_insensitive_keys')
      method.define_argument('strip_whitespace_keys')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('stringify_params') do |method|
      method.define_argument('conditions')
    end
  end

  defs.define_constant('Devise::ParameterSanitizer') do |klass|
    klass.inherits(defs.constant_proxy('Devise::BaseSanitizer', RubyLint.registry))

    klass.define_instance_method('account_update')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('sign_in')

    klass.define_instance_method('sign_up')
  end

  defs.define_constant('Devise::ROUTES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::STRATEGIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::Strategies') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::Strategies::Authenticatable') do |klass|
    klass.inherits(defs.constant_proxy('Devise::Strategies::Base', RubyLint.registry))

    klass.define_instance_method('authentication_hash')

    klass.define_instance_method('authentication_hash=')

    klass.define_instance_method('authentication_type')

    klass.define_instance_method('authentication_type=')

    klass.define_instance_method('password')

    klass.define_instance_method('password=')

    klass.define_instance_method('store?')

    klass.define_instance_method('valid?')
  end

  defs.define_constant('Devise::Strategies::Authenticatable::NULL_STORE') do |klass|
    klass.inherits(defs.constant_proxy('Rack::Session::Abstract::SessionHash', RubyLint.registry))

    klass.define_instance_method('exists?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('env')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Devise::Strategies::Base') do |klass|
    klass.inherits(defs.constant_proxy('Warden::Strategies::Base', RubyLint.registry))

    klass.define_instance_method('mapping')

    klass.define_instance_method('store?')
  end

  defs.define_constant('Devise::Strategies::Base::NULL_STORE') do |klass|
    klass.inherits(defs.constant_proxy('Rack::Session::Abstract::SessionHash', RubyLint.registry))

    klass.define_instance_method('exists?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('env')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Devise::Strategies::DatabaseAuthenticatable') do |klass|
    klass.inherits(defs.constant_proxy('Devise::Strategies::Authenticatable', RubyLint.registry))

    klass.define_instance_method('authenticate!')
  end

  defs.define_constant('Devise::Strategies::DatabaseAuthenticatable::NULL_STORE') do |klass|
    klass.inherits(defs.constant_proxy('Rack::Session::Abstract::SessionHash', RubyLint.registry))

    klass.define_instance_method('exists?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('env')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Devise::Strategies::Rememberable') do |klass|
    klass.inherits(defs.constant_proxy('Devise::Strategies::Authenticatable', RubyLint.registry))

    klass.define_instance_method('authenticate!')

    klass.define_instance_method('valid?')
  end

  defs.define_constant('Devise::Strategies::Rememberable::NULL_STORE') do |klass|
    klass.inherits(defs.constant_proxy('Rack::Session::Abstract::SessionHash', RubyLint.registry))

    klass.define_instance_method('exists?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('env')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Devise::TRUE_VALUES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Devise::TestHelpers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('included') do |method|
      method.define_argument('base')
    end

    klass.define_instance_method('_catch_warden') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('_process_unauthenticated') do |method|
      method.define_argument('env')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('process') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('setup_controller_for_warden')

    klass.define_instance_method('sign_in') do |method|
      method.define_argument('resource_or_scope')
      method.define_optional_argument('resource')
    end

    klass.define_instance_method('sign_out') do |method|
      method.define_argument('resource_or_scope')
    end

    klass.define_instance_method('warden')
  end

  defs.define_constant('Devise::TimeInflector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::DateHelper', RubyLint.registry))

    klass.define_method('instance')

    klass.define_method('time_ago_in_words') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('Devise::TokenGenerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('digest') do |method|
      method.define_argument('klass')
      method.define_argument('column')
      method.define_argument('value')
    end

    klass.define_instance_method('generate') do |method|
      method.define_argument('klass')
      method.define_argument('column')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('key_generator')
      method.define_optional_argument('digest')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Devise::URL_HELPERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
