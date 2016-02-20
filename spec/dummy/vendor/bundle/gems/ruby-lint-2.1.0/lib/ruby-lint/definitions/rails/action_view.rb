# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n18

RubyLint.registry.register('ActionView') do |defs|
  defs.define_constant('ActionView') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('eager_load!')
  end

  defs.define_constant('ActionView::AbstractRenderer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('extract_details') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('find_template') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('formats') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('lookup_context')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('instrument') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('prepend_formats') do |method|
      method.define_argument('formats')
    end

    klass.define_instance_method('render')

    klass.define_instance_method('template_exists?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with_fallbacks') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with_layout_format') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::ActionViewError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::TranslationHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::RenderingHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::RecordTagHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::RecordIdentifier', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::FormHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::ModelNaming', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::OutputSafetyHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::NumberHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::JavaScriptHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::FormOptionsHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::FormTagHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::TextHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::DebugHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::SanitizeHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::CacheHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::AtomFeedHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::UrlHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::AssetTagHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::AssetUrlHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::ActiveModelHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Benchmarkable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::TagHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::DateHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::CsrfHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::ControllerHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::CaptureHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ERB::Util', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Context', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::CompiledTemplates', RubyLint.registry))

    klass.define_method('_routes')

    klass.define_method('_routes=') do |method|
      method.define_argument('val')
    end

    klass.define_method('_routes?')

    klass.define_method('cache_template_loading')

    klass.define_method('cache_template_loading=') do |method|
      method.define_argument('value')
    end

    klass.define_method('default_form_builder')

    klass.define_method('default_form_builder=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('default_formats')

    klass.define_method('default_formats=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('erb_trim_mode=') do |method|
      method.define_argument('arg')
    end

    klass.define_method('field_error_proc')

    klass.define_method('field_error_proc=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('logger')

    klass.define_method('logger=') do |method|
      method.define_argument('val')
    end

    klass.define_method('logger?')

    klass.define_method('prefix_partial_path_with_controller_namespace')

    klass.define_method('prefix_partial_path_with_controller_namespace=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('streaming_completion_on_exception')

    klass.define_method('streaming_completion_on_exception=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('xss_safe?')

    klass.define_instance_method('_routes')

    klass.define_instance_method('_routes=')

    klass.define_instance_method('_routes?')

    klass.define_instance_method('assign') do |method|
      method.define_argument('new_assigns')
    end

    klass.define_instance_method('assigns')

    klass.define_instance_method('assigns=')

    klass.define_instance_method('config')

    klass.define_instance_method('config=')

    klass.define_instance_method('default_form_builder')

    klass.define_instance_method('default_form_builder=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('default_formats')

    klass.define_instance_method('default_formats=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('field_error_proc')

    klass.define_instance_method('field_error_proc=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('formats') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('formats=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('context')
      method.define_optional_argument('assigns')
      method.define_optional_argument('controller')
      method.define_optional_argument('formats')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('locale') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('locale=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('logger=')

    klass.define_instance_method('logger?')

    klass.define_instance_method('lookup_context') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('prefix_partial_path_with_controller_namespace')

    klass.define_instance_method('prefix_partial_path_with_controller_namespace=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('streaming_completion_on_exception')

    klass.define_instance_method('streaming_completion_on_exception=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('view_paths') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('view_paths=') do |method|
      method.define_argument('arg')
    end

    klass.define_instance_method('view_renderer')

    klass.define_instance_method('view_renderer=')
  end

  defs.define_constant('ActionView::Base::ASSET_EXTENSIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::ASSET_PUBLIC_DIRECTORIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::ActiveModelHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::ActiveModelInstanceTag') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('content_tag') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('error_message')

    klass.define_instance_method('error_wrapping') do |method|
      method.define_argument('html_tag')
    end

    klass.define_instance_method('object')

    klass.define_instance_method('tag') do |method|
      method.define_argument('type')
      method.define_argument('options')
      method.define_rest_argument('arg3')
    end
  end

  defs.define_constant('ActionView::Base::AssetTagHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('audio_tag') do |method|
      method.define_rest_argument('sources')
    end

    klass.define_instance_method('auto_discovery_link_tag') do |method|
      method.define_optional_argument('type')
      method.define_optional_argument('url_options')
      method.define_optional_argument('tag_options')
    end

    klass.define_instance_method('favicon_link_tag') do |method|
      method.define_optional_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('image_alt') do |method|
      method.define_argument('src')
    end

    klass.define_instance_method('image_tag') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('javascript_include_tag') do |method|
      method.define_rest_argument('sources')
    end

    klass.define_instance_method('stylesheet_link_tag') do |method|
      method.define_rest_argument('sources')
    end

    klass.define_instance_method('video_tag') do |method|
      method.define_rest_argument('sources')
    end
  end

  defs.define_constant('ActionView::Base::AssetUrlHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('asset_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('asset_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('audio_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('audio_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('compute_asset_extname') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('compute_asset_host') do |method|
      method.define_optional_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('compute_asset_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('font_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('font_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('image_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('image_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('javascript_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('javascript_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_asset') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_audio') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_font') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_image') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_javascript') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_stylesheet') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_video') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('stylesheet_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('stylesheet_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_asset') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_audio') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_font') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_image') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_javascript') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_stylesheet') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_video') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('video_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('video_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Base::AtomBuilder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('xml')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionView::Base::AtomFeedBuilder') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::Helpers::AtomFeedHelper::AtomBuilder', RubyLint.registry))

    klass.define_instance_method('entry') do |method|
      method.define_argument('record')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('xml')
      method.define_argument('view')
      method.define_optional_argument('feed_options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_optional_argument('date_or_time')
    end
  end

  defs.define_constant('ActionView::Base::AtomFeedHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('atom_feed') do |method|
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::Base::BOOLEAN_ATTRIBUTES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::CacheHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cache_fragment_name') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('cache_if') do |method|
      method.define_argument('condition')
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cache_unless') do |method|
      method.define_argument('condition')
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::Base::CaptureHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('capture') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('content_for') do |method|
      method.define_argument('name')
      method.define_optional_argument('content')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('content_for?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('flush_output_buffer')

    klass.define_instance_method('provide') do |method|
      method.define_argument('name')
      method.define_optional_argument('content')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with_output_buffer') do |method|
      method.define_optional_argument('buf')
    end
  end

  defs.define_constant('ActionView::Base::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('full_sanitizer')

    klass.define_instance_method('full_sanitizer=')

    klass.define_instance_method('link_sanitizer')

    klass.define_instance_method('link_sanitizer=')

    klass.define_instance_method('sanitized_allowed_attributes')

    klass.define_instance_method('sanitized_allowed_attributes=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_allowed_css_keywords')

    klass.define_instance_method('sanitized_allowed_css_keywords=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_allowed_css_properties')

    klass.define_instance_method('sanitized_allowed_css_properties=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_allowed_protocols')

    klass.define_instance_method('sanitized_allowed_protocols=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_allowed_tags')

    klass.define_instance_method('sanitized_allowed_tags=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_bad_tags')

    klass.define_instance_method('sanitized_bad_tags=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_protocol_separator')

    klass.define_instance_method('sanitized_protocol_separator=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('sanitized_shorthand_css_properties')

    klass.define_instance_method('sanitized_shorthand_css_properties=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_uri_attributes')

    klass.define_instance_method('sanitized_uri_attributes=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('white_list_sanitizer')

    klass.define_instance_method('white_list_sanitizer=')
  end

  defs.define_constant('ActionView::Base::ControllerHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('action_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assign_controller') do |method|
      method.define_argument('controller')
    end

    klass.define_instance_method('controller')

    klass.define_instance_method('controller=')

    klass.define_instance_method('controller_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('controller_path') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cookies') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('flash') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('headers') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('params') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('request')

    klass.define_instance_method('request=')

    klass.define_instance_method('request_forgery_protection_token') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('response') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('session') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::Base::CsrfHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('csrf_meta_tag')

    klass.define_instance_method('csrf_meta_tags')
  end

  defs.define_constant('ActionView::Base::Cycle') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('current_value')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('first_value')
      method.define_rest_argument('values')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('to_s')

    klass.define_instance_method('values')
  end

  defs.define_constant('ActionView::Base::DateHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('date_select') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('datetime_select') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('distance_of_time_in_words') do |method|
      method.define_argument('from_time')
      method.define_optional_argument('to_time')
      method.define_optional_argument('include_seconds_or_options')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('distance_of_time_in_words_to_now') do |method|
      method.define_argument('from_time')
      method.define_optional_argument('include_seconds_or_options')
    end

    klass.define_instance_method('select_date') do |method|
      method.define_optional_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_datetime') do |method|
      method.define_optional_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_day') do |method|
      method.define_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_hour') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_minute') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_month') do |method|
      method.define_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_second') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_time') do |method|
      method.define_optional_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_year') do |method|
      method.define_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_ago_in_words') do |method|
      method.define_argument('from_time')
      method.define_optional_argument('include_seconds_or_options')
    end

    klass.define_instance_method('time_select') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_tag') do |method|
      method.define_argument('date_or_time')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::Base::DateTimeSelector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::TagHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::CaptureHelper', RubyLint.registry))

    klass.define_instance_method('day')

    klass.define_instance_method('hour')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('min')

    klass.define_instance_method('month')

    klass.define_instance_method('sec')

    klass.define_instance_method('select_date')

    klass.define_instance_method('select_datetime')

    klass.define_instance_method('select_day')

    klass.define_instance_method('select_hour')

    klass.define_instance_method('select_minute')

    klass.define_instance_method('select_month')

    klass.define_instance_method('select_second')

    klass.define_instance_method('select_time')

    klass.define_instance_method('select_year')

    klass.define_instance_method('year')
  end

  defs.define_constant('ActionView::Base::DebugHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('debug') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('ActionView::Base::FormBuilder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::ModelNaming', RubyLint.registry))

    klass.define_method('_to_partial_path')

    klass.define_method('field_helpers')

    klass.define_method('field_helpers=') do |method|
      method.define_argument('val')
    end

    klass.define_method('field_helpers?')

    klass.define_instance_method('button') do |method|
      method.define_optional_argument('value')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('check_box') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('checked_value')
      method.define_optional_argument('unchecked_value')
    end

    klass.define_instance_method('collection_check_boxes') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection_radio_buttons') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection_select') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('color_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('datetime_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_local_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('email_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('emitted_hidden_id?')

    klass.define_instance_method('field_helpers')

    klass.define_instance_method('field_helpers=')

    klass.define_instance_method('field_helpers?')

    klass.define_instance_method('fields_for') do |method|
      method.define_argument('record_name')
      method.define_optional_argument('record_object')
      method.define_optional_argument('fields_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('file_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('grouped_collection_select') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('group_method')
      method.define_argument('group_label_method')
      method.define_argument('option_key_method')
      method.define_argument('option_value_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('hidden_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('index')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('object_name')
      method.define_argument('object')
      method.define_argument('template')
      method.define_argument('options')
      method.define_optional_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label') do |method|
      method.define_argument('method')
      method.define_optional_argument('text')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('month_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('multipart')

    klass.define_instance_method('multipart=') do |method|
      method.define_argument('multipart')
    end

    klass.define_instance_method('multipart?')

    klass.define_instance_method('number_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('object')

    klass.define_instance_method('object=')

    klass.define_instance_method('object_name')

    klass.define_instance_method('object_name=')

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('password_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('phone_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('radio_button') do |method|
      method.define_argument('method')
      method.define_argument('tag_value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('range_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('search_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('select') do |method|
      method.define_argument('method')
      method.define_argument('choices')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('submit') do |method|
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('telephone_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_area') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_zone_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('priority_zones')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('to_model')

    klass.define_instance_method('to_partial_path')

    klass.define_instance_method('url_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('week_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Base::FormHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('check_box') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('checked_value')
      method.define_optional_argument('unchecked_value')
    end

    klass.define_instance_method('color_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_local_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('email_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('fields_for') do |method|
      method.define_argument('record_name')
      method.define_optional_argument('record_object')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('file_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('form_for') do |method|
      method.define_argument('record')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('hidden_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('label') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('content_or_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('month_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('password_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('phone_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('radio_button') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_argument('tag_value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('range_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('search_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('telephone_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_area') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('week_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Base::FormOptionsHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collection_check_boxes') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection_radio_buttons') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection_select') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('grouped_collection_select') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('group_method')
      method.define_argument('group_label_method')
      method.define_argument('option_key_method')
      method.define_argument('option_value_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('grouped_options_for_select') do |method|
      method.define_argument('grouped_options')
      method.define_optional_argument('selected_key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('option_groups_from_collection_for_select') do |method|
      method.define_argument('collection')
      method.define_argument('group_method')
      method.define_argument('group_label_method')
      method.define_argument('option_key_method')
      method.define_argument('option_value_method')
      method.define_optional_argument('selected_key')
    end

    klass.define_instance_method('options_for_select') do |method|
      method.define_argument('container')
      method.define_optional_argument('selected')
    end

    klass.define_instance_method('options_from_collection_for_select') do |method|
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('selected')
    end

    klass.define_instance_method('select') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_argument('choices')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_zone_options_for_select') do |method|
      method.define_optional_argument('selected')
      method.define_optional_argument('priority_zones')
      method.define_optional_argument('model')
    end

    klass.define_instance_method('time_zone_select') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_optional_argument('priority_zones')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end
  end

  defs.define_constant('ActionView::Base::FormTagHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('embed_authenticity_token_in_remote_forms')

    klass.define_method('embed_authenticity_token_in_remote_forms=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('button_tag') do |method|
      method.define_optional_argument('content_or_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('check_box_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('checked')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('color_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_local_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('email_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('embed_authenticity_token_in_remote_forms')

    klass.define_instance_method('embed_authenticity_token_in_remote_forms=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('field_set_tag') do |method|
      method.define_optional_argument('legend')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('file_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('form_tag') do |method|
      method.define_optional_argument('url_for_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('hidden_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('image_submit_tag') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('label_tag') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('content_or_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('month_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('password_field_tag') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('phone_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('radio_button_tag') do |method|
      method.define_argument('name')
      method.define_argument('value')
      method.define_optional_argument('checked')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('range_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('search_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('select_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('option_tags')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('submit_tag') do |method|
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('telephone_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_area_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('content')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('utf8_enforcer_tag')

    klass.define_instance_method('week_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Base::HTML_ESCAPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::HTML_ESCAPE_ONCE_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::InvalidNumberError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('number')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('number')

    klass.define_instance_method('number=')
  end

  defs.define_constant('ActionView::Base::JOIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::JSON_ESCAPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::JSON_ESCAPE_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::JS_ESCAPE_MAP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::JavaScriptHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('button_to_function') do |method|
      method.define_argument('name')
      method.define_optional_argument('function')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('escape_javascript') do |method|
      method.define_argument('javascript')
    end

    klass.define_instance_method('j') do |method|
      method.define_argument('javascript')
    end

    klass.define_instance_method('javascript_cdata_section') do |method|
      method.define_argument('content')
    end

    klass.define_instance_method('javascript_tag') do |method|
      method.define_optional_argument('content_or_options_with_block')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('link_to_function') do |method|
      method.define_argument('name')
      method.define_argument('function')
      method.define_optional_argument('html_options')
    end
  end

  defs.define_constant('ActionView::Base::NEW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::NumberHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('number_to_currency') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_human') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_human_size') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_percentage') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_phone') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_with_delimiter') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_with_precision') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Base::OutputSafetyHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('raw') do |method|
      method.define_argument('stringish')
    end

    klass.define_instance_method('safe_join') do |method|
      method.define_argument('array')
      method.define_optional_argument('sep')
    end
  end

  defs.define_constant('ActionView::Base::PRE_CONTENT_STRINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::RecordTagHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('content_tag_for') do |method|
      method.define_argument('tag_name')
      method.define_argument('single_or_multiple_records')
      method.define_optional_argument('prefix')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('div_for') do |method|
      method.define_argument('record')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::Base::RenderingHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_layout_for') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('render') do |method|
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::Base::SanitizeHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('sanitize') do |method|
      method.define_argument('html')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('sanitize_css') do |method|
      method.define_argument('style')
    end

    klass.define_instance_method('strip_links') do |method|
      method.define_argument('html')
    end

    klass.define_instance_method('strip_tags') do |method|
      method.define_argument('html')
    end
  end

  defs.define_constant('ActionView::Base::TagHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cdata_section') do |method|
      method.define_argument('content')
    end

    klass.define_instance_method('content_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('content_or_options_with_block')
      method.define_optional_argument('options')
      method.define_optional_argument('escape')
      method.define_block_argument('block')
    end

    klass.define_instance_method('escape_once') do |method|
      method.define_argument('html')
    end

    klass.define_instance_method('tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('open')
      method.define_optional_argument('escape')
    end
  end

  defs.define_constant('ActionView::Base::Tags') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::TextHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('concat') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('current_cycle') do |method|
      method.define_optional_argument('name')
    end

    klass.define_instance_method('cycle') do |method|
      method.define_argument('first_value')
      method.define_rest_argument('values')
    end

    klass.define_instance_method('excerpt') do |method|
      method.define_argument('text')
      method.define_argument('phrase')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('highlight') do |method|
      method.define_argument('text')
      method.define_argument('phrases')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('pluralize') do |method|
      method.define_argument('count')
      method.define_argument('singular')
      method.define_optional_argument('plural')
    end

    klass.define_instance_method('reset_cycle') do |method|
      method.define_optional_argument('name')
    end

    klass.define_instance_method('safe_concat') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('simple_format') do |method|
      method.define_argument('text')
      method.define_optional_argument('html_options')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('truncate') do |method|
      method.define_argument('text')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('word_wrap') do |method|
      method.define_argument('text')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Base::TranslationHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('l') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('localize') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('t') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('translate') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Base::URI_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Base::UrlHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_back_url')

    klass.define_instance_method('button_to') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('current_page?') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('link_to') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('link_to_if') do |method|
      method.define_argument('condition')
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('link_to_unless') do |method|
      method.define_argument('condition')
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('link_to_unless_current') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('mail_to') do |method|
      method.define_argument('email_address')
      method.define_optional_argument('name')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('url_for') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::CompiledTemplates') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Context') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_layout_for') do |method|
      method.define_optional_argument('name')
    end

    klass.define_instance_method('_prepare_context')

    klass.define_instance_method('output_buffer')

    klass.define_instance_method('output_buffer=')

    klass.define_instance_method('view_flow')

    klass.define_instance_method('view_flow=')
  end

  defs.define_constant('ActionView::DependencyTracker') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('find_dependencies') do |method|
      method.define_argument('name')
      method.define_argument('template')
    end

    klass.define_method('register_tracker') do |method|
      method.define_argument('extension')
      method.define_argument('tracker')
    end

    klass.define_method('remove_tracker') do |method|
      method.define_argument('handler')
    end
  end

  defs.define_constant('ActionView::DependencyTracker::ERBTracker') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('call') do |method|
      method.define_argument('name')
      method.define_argument('template')
    end

    klass.define_instance_method('dependencies')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('template')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionView::DependencyTracker::ERBTracker::EXPLICIT_DEPENDENCY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::DependencyTracker::ERBTracker::RENDER_DEPENDENCY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Digestor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('cache')

    klass.define_method('digest') do |method|
      method.define_argument('name')
      method.define_argument('format')
      method.define_argument('finder')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('cache')

    klass.define_instance_method('dependencies')

    klass.define_instance_method('digest')

    klass.define_instance_method('finder')

    klass.define_instance_method('format')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('format')
      method.define_argument('finder')
      method.define_optional_argument('options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('nested_dependencies')

    klass.define_instance_method('options')
  end

  defs.define_constant('ActionView::ENCODING_FLAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::EncodingError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActionView::FallbackFileSystemResolver') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::FileSystemResolver', RubyLint.registry))

    klass.define_method('instances')

    klass.define_instance_method('decorate') do |method|
      method.define_rest_argument('arg1')
    end
  end

  defs.define_constant('ActionView::FallbackFileSystemResolver::Cache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache') do |method|
      method.define_argument('key')
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
      method.define_argument('locals')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActionView::FallbackFileSystemResolver::DEFAULT_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::FallbackFileSystemResolver::EXTENSIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::FallbackFileSystemResolver::Path') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
      method.define_argument('virtual')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('partial')

    klass.define_instance_method('partial?')

    klass.define_instance_method('prefix')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_str')

    klass.define_instance_method('virtual')
  end

  defs.define_constant('ActionView::FileSystemResolver') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::PathResolver', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('resolver')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('resolver')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')
      method.define_optional_argument('pattern')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_path')

    klass.define_instance_method('to_s')
  end

  defs.define_constant('ActionView::FileSystemResolver::Cache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache') do |method|
      method.define_argument('key')
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
      method.define_argument('locals')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActionView::FileSystemResolver::DEFAULT_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::FileSystemResolver::EXTENSIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::FileSystemResolver::Path') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
      method.define_argument('virtual')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('partial')

    klass.define_instance_method('partial?')

    klass.define_instance_method('prefix')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_str')

    klass.define_instance_method('virtual')
  end

  defs.define_constant('ActionView::Helpers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Helpers::ASSET_EXTENSIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Helpers::ASSET_PUBLIC_DIRECTORIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Helpers::ActiveModelHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Helpers::ActiveModelInstanceTag') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('content_tag') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('error_message')

    klass.define_instance_method('error_wrapping') do |method|
      method.define_argument('html_tag')
    end

    klass.define_instance_method('object')

    klass.define_instance_method('tag') do |method|
      method.define_argument('type')
      method.define_argument('options')
      method.define_rest_argument('arg3')
    end
  end

  defs.define_constant('ActionView::Helpers::AtomBuilder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('xml')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionView::Helpers::AtomFeedBuilder') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::Helpers::AtomFeedHelper::AtomBuilder', RubyLint.registry))

    klass.define_instance_method('entry') do |method|
      method.define_argument('record')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('xml')
      method.define_argument('view')
      method.define_optional_argument('feed_options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_optional_argument('date_or_time')
    end
  end

  defs.define_constant('ActionView::Helpers::BOOLEAN_ATTRIBUTES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Helpers::CacheHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cache_fragment_name') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('cache_if') do |method|
      method.define_argument('condition')
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cache_unless') do |method|
      method.define_argument('condition')
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::Helpers::CaptureHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('capture') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('content_for') do |method|
      method.define_argument('name')
      method.define_optional_argument('content')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('content_for?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('flush_output_buffer')

    klass.define_instance_method('provide') do |method|
      method.define_argument('name')
      method.define_optional_argument('content')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with_output_buffer') do |method|
      method.define_optional_argument('buf')
    end
  end

  defs.define_constant('ActionView::Helpers::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('full_sanitizer')

    klass.define_instance_method('full_sanitizer=')

    klass.define_instance_method('link_sanitizer')

    klass.define_instance_method('link_sanitizer=')

    klass.define_instance_method('sanitized_allowed_attributes')

    klass.define_instance_method('sanitized_allowed_attributes=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_allowed_css_keywords')

    klass.define_instance_method('sanitized_allowed_css_keywords=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_allowed_css_properties')

    klass.define_instance_method('sanitized_allowed_css_properties=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_allowed_protocols')

    klass.define_instance_method('sanitized_allowed_protocols=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_allowed_tags')

    klass.define_instance_method('sanitized_allowed_tags=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_bad_tags')

    klass.define_instance_method('sanitized_bad_tags=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_protocol_separator')

    klass.define_instance_method('sanitized_protocol_separator=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('sanitized_shorthand_css_properties')

    klass.define_instance_method('sanitized_shorthand_css_properties=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('sanitized_uri_attributes')

    klass.define_instance_method('sanitized_uri_attributes=') do |method|
      method.define_argument('attributes')
    end

    klass.define_instance_method('white_list_sanitizer')

    klass.define_instance_method('white_list_sanitizer=')
  end

  defs.define_constant('ActionView::Helpers::ControllerHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('action_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assign_controller') do |method|
      method.define_argument('controller')
    end

    klass.define_instance_method('controller')

    klass.define_instance_method('controller=')

    klass.define_instance_method('controller_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('controller_path') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cookies') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('flash') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('headers') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('params') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('request')

    klass.define_instance_method('request=')

    klass.define_instance_method('request_forgery_protection_token') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('response') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('session') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::Helpers::CsrfHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('csrf_meta_tag')

    klass.define_instance_method('csrf_meta_tags')
  end

  defs.define_constant('ActionView::Helpers::Cycle') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('current_value')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('first_value')
      method.define_rest_argument('values')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('to_s')

    klass.define_instance_method('values')
  end

  defs.define_constant('ActionView::Helpers::DateHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('date_select') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('datetime_select') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('distance_of_time_in_words') do |method|
      method.define_argument('from_time')
      method.define_optional_argument('to_time')
      method.define_optional_argument('include_seconds_or_options')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('distance_of_time_in_words_to_now') do |method|
      method.define_argument('from_time')
      method.define_optional_argument('include_seconds_or_options')
    end

    klass.define_instance_method('select_date') do |method|
      method.define_optional_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_datetime') do |method|
      method.define_optional_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_day') do |method|
      method.define_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_hour') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_minute') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_month') do |method|
      method.define_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_second') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_time') do |method|
      method.define_optional_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_year') do |method|
      method.define_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_ago_in_words') do |method|
      method.define_argument('from_time')
      method.define_optional_argument('include_seconds_or_options')
    end

    klass.define_instance_method('time_select') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_tag') do |method|
      method.define_argument('date_or_time')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::Helpers::FormBuilder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::ModelNaming', RubyLint.registry))

    klass.define_method('_to_partial_path')

    klass.define_method('field_helpers')

    klass.define_method('field_helpers=') do |method|
      method.define_argument('val')
    end

    klass.define_method('field_helpers?')

    klass.define_instance_method('button') do |method|
      method.define_optional_argument('value')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('check_box') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('checked_value')
      method.define_optional_argument('unchecked_value')
    end

    klass.define_instance_method('collection_check_boxes') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection_radio_buttons') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection_select') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('color_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('datetime_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_local_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('email_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('emitted_hidden_id?')

    klass.define_instance_method('field_helpers')

    klass.define_instance_method('field_helpers=')

    klass.define_instance_method('field_helpers?')

    klass.define_instance_method('fields_for') do |method|
      method.define_argument('record_name')
      method.define_optional_argument('record_object')
      method.define_optional_argument('fields_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('file_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('grouped_collection_select') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('group_method')
      method.define_argument('group_label_method')
      method.define_argument('option_key_method')
      method.define_argument('option_value_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('hidden_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('index')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('object_name')
      method.define_argument('object')
      method.define_argument('template')
      method.define_argument('options')
      method.define_optional_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label') do |method|
      method.define_argument('method')
      method.define_optional_argument('text')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('month_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('multipart')

    klass.define_instance_method('multipart=') do |method|
      method.define_argument('multipart')
    end

    klass.define_instance_method('multipart?')

    klass.define_instance_method('number_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('object')

    klass.define_instance_method('object=')

    klass.define_instance_method('object_name')

    klass.define_instance_method('object_name=')

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('password_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('phone_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('radio_button') do |method|
      method.define_argument('method')
      method.define_argument('tag_value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('range_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('search_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('select') do |method|
      method.define_argument('method')
      method.define_argument('choices')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('submit') do |method|
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('telephone_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_area') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_zone_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('priority_zones')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('to_model')

    klass.define_instance_method('to_partial_path')

    klass.define_instance_method('url_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('week_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Helpers::FormHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('check_box') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('checked_value')
      method.define_optional_argument('unchecked_value')
    end

    klass.define_instance_method('color_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_local_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('email_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('fields_for') do |method|
      method.define_argument('record_name')
      method.define_optional_argument('record_object')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('file_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('form_for') do |method|
      method.define_argument('record')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('hidden_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('label') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('content_or_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('month_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('password_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('phone_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('radio_button') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_argument('tag_value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('range_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('search_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('telephone_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_area') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('week_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Helpers::FormTagHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('embed_authenticity_token_in_remote_forms')

    klass.define_method('embed_authenticity_token_in_remote_forms=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('button_tag') do |method|
      method.define_optional_argument('content_or_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('check_box_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('checked')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('color_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_local_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('email_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('embed_authenticity_token_in_remote_forms')

    klass.define_instance_method('embed_authenticity_token_in_remote_forms=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('field_set_tag') do |method|
      method.define_optional_argument('legend')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('file_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('form_tag') do |method|
      method.define_optional_argument('url_for_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('hidden_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('image_submit_tag') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('label_tag') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('content_or_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('month_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('password_field_tag') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('phone_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('radio_button_tag') do |method|
      method.define_argument('name')
      method.define_argument('value')
      method.define_optional_argument('checked')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('range_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('search_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('select_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('option_tags')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('submit_tag') do |method|
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('telephone_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_area_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('content')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('utf8_enforcer_tag')

    klass.define_instance_method('week_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Helpers::InvalidNumberError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('number')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('number')

    klass.define_instance_method('number=')
  end

  defs.define_constant('ActionView::Helpers::JOIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Helpers::JS_ESCAPE_MAP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Helpers::NEW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Helpers::OutputSafetyHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('raw') do |method|
      method.define_argument('stringish')
    end

    klass.define_instance_method('safe_join') do |method|
      method.define_argument('array')
      method.define_optional_argument('sep')
    end
  end

  defs.define_constant('ActionView::Helpers::PRE_CONTENT_STRINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Helpers::RenderingHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_layout_for') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('render') do |method|
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::Helpers::TranslationHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('l') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('localize') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('t') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('translate') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::Helpers::URI_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::LogSubscriber', RubyLint.registry))

    klass.define_instance_method('from_rails_root') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('render_collection') do |method|
      method.define_argument('event')
    end

    klass.define_instance_method('render_partial') do |method|
      method.define_argument('event')
    end

    klass.define_instance_method('render_template') do |method|
      method.define_argument('event')
    end
  end

  defs.define_constant('ActionView::LogSubscriber::BLACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber::BLUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber::BOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber::CLEAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber::CYAN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber::GREEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber::MAGENTA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber::RED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber::VIEWS_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber::WHITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LogSubscriber::YELLOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::LookupContext') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::LookupContext::ViewPaths', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::LookupContext::DetailsCache', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::LookupContext::Accessors', RubyLint.registry))

    klass.define_method('fallbacks')

    klass.define_method('fallbacks=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('register_detail') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_method('registered_details')

    klass.define_method('registered_details=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('fallbacks')

    klass.define_instance_method('fallbacks=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('formats=') do |method|
      method.define_argument('values')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('view_paths')
      method.define_optional_argument('details')
      method.define_optional_argument('prefixes')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('locale')

    klass.define_instance_method('locale=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('prefixes')

    klass.define_instance_method('prefixes=')

    klass.define_instance_method('registered_details')

    klass.define_instance_method('registered_details=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('rendered_format')

    klass.define_instance_method('rendered_format=')

    klass.define_instance_method('skip_default_locale!')

    klass.define_instance_method('with_layout_format')
  end

  defs.define_constant('ActionView::LookupContext::Accessors') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('default_formats')

    klass.define_instance_method('default_handlers')

    klass.define_instance_method('default_locale')

    klass.define_instance_method('formats')

    klass.define_instance_method('formats=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('handlers')

    klass.define_instance_method('handlers=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('initialize_details') do |method|
      method.define_argument('details')
    end

    klass.define_instance_method('locale')

    klass.define_instance_method('locale=') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('ActionView::LookupContext::DetailsCache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_set_detail') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('cache')

    klass.define_instance_method('cache=')

    klass.define_instance_method('details_key')

    klass.define_instance_method('disable_cache')
  end

  defs.define_constant('ActionView::LookupContext::DetailsKey') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('clear')

    klass.define_method('get') do |method|
      method.define_argument('details')
    end

    klass.define_instance_method('eql?') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('hash')

    klass.define_instance_method('initialize')

    klass.define_instance_method('object_hash')
  end

  defs.define_constant('ActionView::LookupContext::ViewPaths') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('args_for_lookup') do |method|
      method.define_argument('name')
      method.define_argument('prefixes')
      method.define_argument('partial')
      method.define_argument('keys')
      method.define_argument('details_options')
    end

    klass.define_instance_method('detail_args_for') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('exists?') do |method|
      method.define_argument('name')
      method.define_optional_argument('prefixes')
      method.define_optional_argument('partial')
      method.define_optional_argument('keys')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('find') do |method|
      method.define_argument('name')
      method.define_optional_argument('prefixes')
      method.define_optional_argument('partial')
      method.define_optional_argument('keys')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('find_all') do |method|
      method.define_argument('name')
      method.define_optional_argument('prefixes')
      method.define_optional_argument('partial')
      method.define_optional_argument('keys')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('find_template') do |method|
      method.define_argument('name')
      method.define_optional_argument('prefixes')
      method.define_optional_argument('partial')
      method.define_optional_argument('keys')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('html_fallback_for_js')

    klass.define_instance_method('normalize_name') do |method|
      method.define_argument('name')
      method.define_argument('prefixes')
    end

    klass.define_instance_method('template_exists?') do |method|
      method.define_argument('name')
      method.define_optional_argument('prefixes')
      method.define_optional_argument('partial')
      method.define_optional_argument('keys')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('view_paths')

    klass.define_instance_method('view_paths=') do |method|
      method.define_argument('paths')
    end

    klass.define_instance_method('with_fallbacks')
  end

  defs.define_constant('ActionView::MissingRequestError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

  end

  defs.define_constant('ActionView::MissingTemplate') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::ActionViewError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('paths')
      method.define_argument('path')
      method.define_argument('prefixes')
      method.define_argument('partial')
      method.define_argument('details')
      method.define_rest_argument('arg6')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('path')
  end

  defs.define_constant('ActionView::ModelNaming') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert_to_model') do |method|
      method.define_argument('object')
    end

    klass.define_instance_method('model_name_from_record_or_class') do |method|
      method.define_argument('record_or_class')
    end
  end

  defs.define_constant('ActionView::OptimizedFileSystemResolver') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::FileSystemResolver', RubyLint.registry))

    klass.define_instance_method('build_query') do |method|
      method.define_argument('path')
      method.define_argument('details')
    end
  end

  defs.define_constant('ActionView::OptimizedFileSystemResolver::Cache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache') do |method|
      method.define_argument('key')
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
      method.define_argument('locals')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActionView::OptimizedFileSystemResolver::DEFAULT_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::OptimizedFileSystemResolver::EXTENSIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::OptimizedFileSystemResolver::Path') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
      method.define_argument('virtual')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('partial')

    klass.define_instance_method('partial?')

    klass.define_instance_method('prefix')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_str')

    klass.define_instance_method('virtual')
  end

  defs.define_constant('ActionView::OutputBuffer') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::SafeBuffer', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('append=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('safe_append=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('safe_concat') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('ActionView::OutputBuffer::Complexifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionView::OutputBuffer::ControlCharacters') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::OutputBuffer::ControlPrintValue') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::OutputBuffer::Extend') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('json_create')
  end

  defs.define_constant('ActionView::OutputBuffer::Rationalizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('convert')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('value')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionView::OutputBuffer::SafeConcatError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActionView::OutputBuffer::UNSAFE_STRING_METHODS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::OutputFlow') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('append!') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('content')

    klass.define_instance_method('get') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('set') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end
  end

  defs.define_constant('ActionView::PartialDigestor') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::Digestor', RubyLint.registry))

    klass.define_instance_method('partial?')
  end

  defs.define_constant('ActionView::PartialRenderer') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::AbstractRenderer', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('arg1')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('render') do |method|
      method.define_argument('context')
      method.define_argument('options')
      method.define_argument('block')
    end

    klass.define_instance_method('render_collection')

    klass.define_instance_method('render_partial')
  end

  defs.define_constant('ActionView::PartialRenderer::IDENTIFIER_ERROR_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::PartialRenderer::PREFIXED_PARTIAL_NAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::PathResolver') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::Resolver', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('pattern')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionView::PathResolver::Cache') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache') do |method|
      method.define_argument('key')
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
      method.define_argument('locals')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActionView::PathResolver::DEFAULT_PATTERN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::PathResolver::EXTENSIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::PathResolver::Path') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
      method.define_argument('virtual')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('partial')

    klass.define_instance_method('partial?')

    klass.define_instance_method('prefix')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_str')

    klass.define_instance_method('virtual')
  end

  defs.define_constant('ActionView::PathSet') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('+') do |method|
      method.define_argument('array')
    end

    klass.define_instance_method('<<') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('compact')

    klass.define_instance_method('concat') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('exists?') do |method|
      method.define_argument('path')
      method.define_argument('prefixes')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('find') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('find_all') do |method|
      method.define_argument('path')
      method.define_optional_argument('prefixes')
      method.define_rest_argument('args')
    end

    klass.define_instance_method('include?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('paths')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('paths')

    klass.define_instance_method('pop') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('push') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('size') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('to_ary')

    klass.define_instance_method('unshift') do |method|
      method.define_rest_argument('args')
    end
  end

  defs.define_constant('ActionView::PathSet::Enumerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('each_with_index')

    klass.define_instance_method('initialize') do |method|
      method.define_optional_argument('receiver_or_size')
      method.define_optional_argument('method_name')
      method.define_rest_argument('method_args')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('next')

    klass.define_instance_method('next_values')

    klass.define_instance_method('peek')

    klass.define_instance_method('peek_values')

    klass.define_instance_method('rewind')

    klass.define_instance_method('size')

    klass.define_instance_method('with_index') do |method|
      method.define_optional_argument('offset')
    end
  end

  defs.define_constant('ActionView::PathSet::SortedElement') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('other')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('val')
      method.define_argument('sort_id')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('sort_id')

    klass.define_instance_method('value')
  end

  defs.define_constant('ActionView::Railtie') do |klass|
    klass.inherits(defs.constant_proxy('Rails::Railtie', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Rails::Railtie::Configurable', RubyLint.registry))

  end

  defs.define_constant('ActionView::Railtie::ABSTRACT_RAILTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Railtie::ClassMethods') do |klass|
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

  defs.define_constant('ActionView::Railtie::Collection') do |klass|
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

  defs.define_constant('ActionView::Railtie::Configurable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Railtie::Configuration') do |klass|
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

  defs.define_constant('ActionView::Railtie::Initializer') do |klass|
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

  defs.define_constant('ActionView::RecordIdentifier') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('dom_class') do |method|
      method.define_argument('record_or_class')
      method.define_optional_argument('prefix')
    end

    klass.define_instance_method('dom_id') do |method|
      method.define_argument('record')
      method.define_optional_argument('prefix')
    end

    klass.define_instance_method('record_key_for_dom_id') do |method|
      method.define_argument('record')
    end
  end

  defs.define_constant('ActionView::RecordIdentifier::JOIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::RecordIdentifier::NEW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Renderer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('lookup_context')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lookup_context')

    klass.define_instance_method('lookup_context=')

    klass.define_instance_method('render') do |method|
      method.define_argument('context')
      method.define_argument('options')
    end

    klass.define_instance_method('render_body') do |method|
      method.define_argument('context')
      method.define_argument('options')
    end

    klass.define_instance_method('render_partial') do |method|
      method.define_argument('context')
      method.define_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('render_template') do |method|
      method.define_argument('context')
      method.define_argument('options')
    end
  end

  defs.define_constant('ActionView::Resolver') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('caching')

    klass.define_method('caching=') do |method|
      method.define_argument('obj')
    end

    klass.define_method('caching?')

    klass.define_instance_method('caching')

    klass.define_instance_method('caching=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('caching?') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('clear_cache')

    klass.define_instance_method('find_all') do |method|
      method.define_argument('name')
      method.define_optional_argument('prefix')
      method.define_optional_argument('partial')
      method.define_optional_argument('details')
      method.define_optional_argument('key')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('initialize')
  end

  defs.define_constant('ActionView::Resolver::Path') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('build') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('prefix')
      method.define_argument('partial')
      method.define_argument('virtual')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('name')

    klass.define_instance_method('partial')

    klass.define_instance_method('partial?')

    klass.define_instance_method('prefix')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_str')

    klass.define_instance_method('virtual')
  end

  defs.define_constant('ActionView::RoutingUrlFor') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('default_url_options=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('_routes_context')

    klass.define_instance_method('default_url_options=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('optimize_routes_generation?')

    klass.define_instance_method('url_for') do |method|
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_options')
  end

  defs.define_constant('ActionView::StreamingBuffer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('append=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('concat') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('html_safe')

    klass.define_instance_method('html_safe?')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('safe_append=') do |method|
      method.define_argument('value')
    end

    klass.define_instance_method('safe_concat') do |method|
      method.define_argument('value')
    end
  end

  defs.define_constant('ActionView::StreamingFlow') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::OutputFlow', RubyLint.registry))

    klass.define_instance_method('append!') do |method|
      method.define_argument('key')
      method.define_argument('value')
    end

    klass.define_instance_method('get') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('view')
      method.define_argument('fiber')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionView::StreamingTemplateRenderer') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::TemplateRenderer', RubyLint.registry))

    klass.define_instance_method('render_template') do |method|
      method.define_argument('template')
      method.define_optional_argument('layout_name')
      method.define_optional_argument('locals')
    end
  end

  defs.define_constant('ActionView::StreamingTemplateRenderer::Body') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_block_argument('start')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionView::Template') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('compile') do |method|
      method.define_argument('view')
      method.define_argument('mod')
    end

    klass.define_instance_method('compile!') do |method|
      method.define_argument('view')
    end

    klass.define_instance_method('encode!')

    klass.define_instance_method('formats')

    klass.define_instance_method('formats=')

    klass.define_instance_method('handle_render_error') do |method|
      method.define_argument('view')
      method.define_argument('e')
    end

    klass.define_instance_method('handler')

    klass.define_instance_method('identifier')

    klass.define_instance_method('identifier_method_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('source')
      method.define_argument('identifier')
      method.define_argument('handler')
      method.define_argument('details')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('locals')

    klass.define_instance_method('locals=')

    klass.define_instance_method('locals_code')

    klass.define_instance_method('method_name')

    klass.define_instance_method('mime_type')

    klass.define_instance_method('original_encoding')

    klass.define_instance_method('refresh') do |method|
      method.define_argument('view')
    end

    klass.define_instance_method('render') do |method|
      method.define_argument('view')
      method.define_argument('locals')
      method.define_optional_argument('buffer')
      method.define_block_argument('block')
    end

    klass.define_instance_method('source')

    klass.define_instance_method('supports_streaming?')

    klass.define_instance_method('type')

    klass.define_instance_method('updated_at')

    klass.define_instance_method('virtual_path')

    klass.define_instance_method('virtual_path=')
  end

  defs.define_constant('ActionView::Template::Error') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::ActionViewError', RubyLint.registry))

    klass.define_instance_method('annoted_source_code')

    klass.define_instance_method('backtrace')

    klass.define_instance_method('file_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('template')
      method.define_argument('original_exception')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('line_number')

    klass.define_instance_method('original_exception')

    klass.define_instance_method('source_extract') do |method|
      method.define_optional_argument('indentation')
      method.define_optional_argument('output')
    end

    klass.define_instance_method('sub_template_message')

    klass.define_instance_method('sub_template_of') do |method|
      method.define_argument('template_path')
    end
  end

  defs.define_constant('ActionView::Template::Error::SOURCE_CODE_RADIUS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Template::Finalizer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Template::Handlers') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('extended') do |method|
      method.define_argument('base')
    end

    klass.define_method('extensions')

    klass.define_instance_method('handler_for_extension') do |method|
      method.define_argument('extension')
    end

    klass.define_instance_method('register_default_template_handler') do |method|
      method.define_argument('extension')
      method.define_argument('klass')
    end

    klass.define_instance_method('register_template_handler') do |method|
      method.define_rest_argument('extensions')
      method.define_argument('handler')
    end

    klass.define_instance_method('registered_template_handler') do |method|
      method.define_argument('extension')
    end

    klass.define_instance_method('template_handler_extensions')
  end

  defs.define_constant('ActionView::Template::Handlers::Builder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('default_format')

    klass.define_method('default_format=') do |method|
      method.define_argument('val')
    end

    klass.define_method('default_format?')

    klass.define_instance_method('call') do |method|
      method.define_argument('template')
    end

    klass.define_instance_method('default_format')

    klass.define_instance_method('default_format=')

    klass.define_instance_method('default_format?')

    klass.define_instance_method('require_engine')
  end

  defs.define_constant('ActionView::Template::Handlers::ERB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('call') do |method|
      method.define_argument('template')
    end

    klass.define_method('erb_implementation')

    klass.define_method('erb_implementation=') do |method|
      method.define_argument('val')
    end

    klass.define_method('erb_implementation?')

    klass.define_method('erb_trim_mode')

    klass.define_method('erb_trim_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_method('erb_trim_mode?')

    klass.define_method('escape_whitelist')

    klass.define_method('escape_whitelist=') do |method|
      method.define_argument('val')
    end

    klass.define_method('escape_whitelist?')

    klass.define_instance_method('call') do |method|
      method.define_argument('template')
    end

    klass.define_instance_method('erb_implementation')

    klass.define_instance_method('erb_implementation=')

    klass.define_instance_method('erb_implementation?')

    klass.define_instance_method('erb_trim_mode')

    klass.define_instance_method('erb_trim_mode=')

    klass.define_instance_method('erb_trim_mode?')

    klass.define_instance_method('escape_whitelist')

    klass.define_instance_method('escape_whitelist=')

    klass.define_instance_method('escape_whitelist?')

    klass.define_instance_method('handles_encoding?')

    klass.define_instance_method('supports_streaming?')
  end

  defs.define_constant('ActionView::Template::Handlers::ERB::ENCODING_TAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Template::Handlers::Erubis') do |klass|
    klass.inherits(defs.constant_proxy('Erubis::Eruby', RubyLint.registry))

    klass.define_instance_method('add_expr') do |method|
      method.define_argument('src')
      method.define_argument('code')
      method.define_argument('indicator')
    end

    klass.define_instance_method('add_expr_escaped') do |method|
      method.define_argument('src')
      method.define_argument('code')
    end

    klass.define_instance_method('add_expr_literal') do |method|
      method.define_argument('src')
      method.define_argument('code')
    end

    klass.define_instance_method('add_postamble') do |method|
      method.define_argument('src')
    end

    klass.define_instance_method('add_preamble') do |method|
      method.define_argument('src')
    end

    klass.define_instance_method('add_stmt') do |method|
      method.define_argument('src')
      method.define_argument('code')
    end

    klass.define_instance_method('add_text') do |method|
      method.define_argument('src')
      method.define_argument('text')
    end

    klass.define_instance_method('flush_newline_if_pending') do |method|
      method.define_argument('src')
    end
  end

  defs.define_constant('ActionView::Template::Handlers::Erubis::BLOCK_EXPR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Template::Handlers::Erubis::DEFAULT_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::Template::Handlers::Raw') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('call') do |method|
      method.define_argument('template')
    end
  end

  defs.define_constant('ActionView::Template::Text') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('formats')

    klass.define_instance_method('identifier')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('string')
      method.define_optional_argument('type')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('inspect')

    klass.define_instance_method('render') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('to_str')

    klass.define_instance_method('type')

    klass.define_instance_method('type=')
  end

  defs.define_constant('ActionView::Template::Types') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_argument('type')
    end

    klass.define_method('delegate_to') do |method|
      method.define_argument('klass')
    end

    klass.define_method('type_klass')

    klass.define_method('type_klass=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('type_klass')

    klass.define_instance_method('type_klass=') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('ActionView::Template::Types::Type') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('[]') do |method|
      method.define_argument('type')
    end

    klass.define_method('register') do |method|
      method.define_rest_argument('t')
    end

    klass.define_method('types')

    klass.define_method('types=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('type')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('symbol')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('ref')

    klass.define_instance_method('symbol')

    klass.define_instance_method('to_s') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('to_str') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('to_sym') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('types')

    klass.define_instance_method('types=') do |method|
      method.define_argument('obj')
    end
  end

  defs.define_constant('ActionView::TemplateError') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::ActionViewError', RubyLint.registry))

    klass.define_instance_method('annoted_source_code')

    klass.define_instance_method('backtrace')

    klass.define_instance_method('file_name')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('template')
      method.define_argument('original_exception')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('line_number')

    klass.define_instance_method('original_exception')

    klass.define_instance_method('source_extract') do |method|
      method.define_optional_argument('indentation')
      method.define_optional_argument('output')
    end

    klass.define_instance_method('sub_template_message')

    klass.define_instance_method('sub_template_of') do |method|
      method.define_argument('template_path')
    end
  end

  defs.define_constant('ActionView::TemplateRenderer') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::AbstractRenderer', RubyLint.registry))

    klass.define_instance_method('determine_template') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('find_layout') do |method|
      method.define_argument('layout')
      method.define_argument('keys')
    end

    klass.define_instance_method('render') do |method|
      method.define_argument('context')
      method.define_argument('options')
    end

    klass.define_instance_method('render_template') do |method|
      method.define_argument('template')
      method.define_optional_argument('layout_name')
      method.define_optional_argument('locals')
    end

    klass.define_instance_method('render_with_layout') do |method|
      method.define_argument('path')
      method.define_argument('locals')
    end

    klass.define_instance_method('resolve_layout') do |method|
      method.define_argument('layout')
      method.define_argument('keys')
    end
  end

  defs.define_constant('ActionView::TestCase') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::TestCase', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::TestCase::Behavior', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::RoutingUrlFor', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Routing::UrlFor', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Testing::ConstantLookup', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::TranslationHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::RenderingHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::RecordTagHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::RecordIdentifier', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::FormHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::ModelNaming', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Routing::PolymorphicRoutes', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionController::ModelNaming', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Context', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::CompiledTemplates', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::TestProcess', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::OutputSafetyHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::NumberHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::JavaScriptHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::FormOptionsHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::FormTagHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::TextHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::DebugHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::SanitizeHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::CacheHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::AtomFeedHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::UrlHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::AssetTagHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::AssetUrlHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::ActiveModelHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActiveSupport::Benchmarkable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::TagHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::DateHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::CsrfHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::ControllerHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::CaptureHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('AbstractController::Helpers', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionController::TemplateAssertions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Assertions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Assertions::TagAssertions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Assertions::SelectorAssertions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Assertions::RoutingAssertions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Assertions::ResponseAssertions', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::Assertions::DomAssertions', RubyLint.registry))

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

    klass.define_method('_setup_callbacks')

    klass.define_method('_teardown_callbacks')

    klass.define_instance_method('_helper_methods')

    klass.define_instance_method('_helper_methods=')

    klass.define_instance_method('_helper_methods?')

    klass.define_instance_method('_helpers')

    klass.define_instance_method('_helpers=')

    klass.define_instance_method('_helpers?')
  end

  defs.define_constant('ActionView::TestCase::ASSET_EXTENSIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::ASSET_PUBLIC_DIRECTORIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::ActiveModelHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::ActiveModelInstanceTag') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('content_tag') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('error_message')

    klass.define_instance_method('error_wrapping') do |method|
      method.define_argument('html_tag')
    end

    klass.define_instance_method('object')

    klass.define_instance_method('tag') do |method|
      method.define_argument('type')
      method.define_argument('options')
      method.define_rest_argument('arg3')
    end
  end

  defs.define_constant('ActionView::TestCase::Assertion') do |klass|
    klass.inherits(defs.constant_proxy('Exception', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::AssetTagHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('audio_tag') do |method|
      method.define_rest_argument('sources')
    end

    klass.define_instance_method('auto_discovery_link_tag') do |method|
      method.define_optional_argument('type')
      method.define_optional_argument('url_options')
      method.define_optional_argument('tag_options')
    end

    klass.define_instance_method('favicon_link_tag') do |method|
      method.define_optional_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('image_alt') do |method|
      method.define_argument('src')
    end

    klass.define_instance_method('image_tag') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('javascript_include_tag') do |method|
      method.define_rest_argument('sources')
    end

    klass.define_instance_method('stylesheet_link_tag') do |method|
      method.define_rest_argument('sources')
    end

    klass.define_instance_method('video_tag') do |method|
      method.define_rest_argument('sources')
    end
  end

  defs.define_constant('ActionView::TestCase::AssetUrlHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('asset_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('asset_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('audio_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('audio_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('compute_asset_extname') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('compute_asset_host') do |method|
      method.define_optional_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('compute_asset_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('font_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('font_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('image_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('image_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('javascript_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('javascript_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_asset') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_audio') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_font') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_image') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_javascript') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_stylesheet') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('path_to_video') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('stylesheet_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('stylesheet_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_asset') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_audio') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_font') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_image') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_javascript') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_stylesheet') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_to_video') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('video_path') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('video_url') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::TestCase::AtomBuilder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('xml')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('ActionView::TestCase::AtomFeedBuilder') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::Helpers::AtomFeedHelper::AtomBuilder', RubyLint.registry))

    klass.define_instance_method('entry') do |method|
      method.define_argument('record')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_argument('xml')
      method.define_argument('view')
      method.define_optional_argument('feed_options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('updated') do |method|
      method.define_optional_argument('date_or_time')
    end
  end

  defs.define_constant('ActionView::TestCase::AtomFeedHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('atom_feed') do |method|
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::TestCase::BOOLEAN_ATTRIBUTES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::Behavior') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('config')

    klass.define_instance_method('controller')

    klass.define_instance_method('controller=')

    klass.define_instance_method('lookup_context') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('output_buffer')

    klass.define_instance_method('output_buffer=')

    klass.define_instance_method('render') do |method|
      method.define_optional_argument('options')
      method.define_optional_argument('local_assigns')
      method.define_block_argument('block')
    end

    klass.define_instance_method('rendered')

    klass.define_instance_method('rendered=')

    klass.define_instance_method('rendered_views')

    klass.define_instance_method('setup_with_controller')
  end

  defs.define_constant('ActionView::TestCase::Behavior::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('determine_default_helper_class') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('helper_class')

    klass.define_instance_method('helper_class=')

    klass.define_instance_method('helper_method') do |method|
      method.define_rest_argument('methods')
    end

    klass.define_instance_method('new') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('tests') do |method|
      method.define_argument('helper_class')
    end
  end

  defs.define_constant('ActionView::TestCase::Behavior::INTERNAL_IVARS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::Behavior::JOIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::Behavior::Locals') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('render') do |method|
      method.define_optional_argument('options')
      method.define_optional_argument('local_assigns')
    end

    klass.define_instance_method('rendered_views')

    klass.define_instance_method('rendered_views=')
  end

  defs.define_constant('ActionView::TestCase::Behavior::NEW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::Behavior::RenderedViewsCollection') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('view')
      method.define_argument('locals')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('locals_for') do |method|
      method.define_argument('view')
    end

    klass.define_instance_method('rendered_views')

    klass.define_instance_method('view_rendered?') do |method|
      method.define_argument('view')
      method.define_argument('expected_locals')
    end
  end

  defs.define_constant('ActionView::TestCase::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::CacheHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cache_fragment_name') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('cache_if') do |method|
      method.define_argument('condition')
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cache_unless') do |method|
      method.define_argument('condition')
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::TestCase::Callback') do |klass|
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

  defs.define_constant('ActionView::TestCase::CallbackChain') do |klass|
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

  defs.define_constant('ActionView::TestCase::CaptureHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('capture') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('content_for') do |method|
      method.define_argument('name')
      method.define_optional_argument('content')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('content_for?') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('flush_output_buffer')

    klass.define_instance_method('provide') do |method|
      method.define_argument('name')
      method.define_optional_argument('content')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with_output_buffer') do |method|
      method.define_optional_argument('buf')
    end
  end

  defs.define_constant('ActionView::TestCase::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('determine_default_helper_class') do |method|
      method.define_argument('name')
    end

    klass.define_instance_method('helper_class')

    klass.define_instance_method('helper_class=')

    klass.define_instance_method('helper_method') do |method|
      method.define_rest_argument('methods')
    end

    klass.define_instance_method('new') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('tests') do |method|
      method.define_argument('helper_class')
    end
  end

  defs.define_constant('ActionView::TestCase::ControllerHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('action_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assign_controller') do |method|
      method.define_argument('controller')
    end

    klass.define_instance_method('controller')

    klass.define_instance_method('controller=')

    klass.define_instance_method('controller_name') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('controller_path') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('cookies') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('flash') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('headers') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('logger')

    klass.define_instance_method('params') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('request')

    klass.define_instance_method('request=')

    klass.define_instance_method('request_forgery_protection_token') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('response') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('session') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::TestCase::CsrfHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('csrf_meta_tag')

    klass.define_instance_method('csrf_meta_tags')
  end

  defs.define_constant('ActionView::TestCase::Cycle') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('current_value')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('first_value')
      method.define_rest_argument('values')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('reset')

    klass.define_instance_method('to_s')

    klass.define_instance_method('values')
  end

  defs.define_constant('ActionView::TestCase::DateHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('date_select') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('datetime_select') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('distance_of_time_in_words') do |method|
      method.define_argument('from_time')
      method.define_optional_argument('to_time')
      method.define_optional_argument('include_seconds_or_options')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('distance_of_time_in_words_to_now') do |method|
      method.define_argument('from_time')
      method.define_optional_argument('include_seconds_or_options')
    end

    klass.define_instance_method('select_date') do |method|
      method.define_optional_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_datetime') do |method|
      method.define_optional_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_day') do |method|
      method.define_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_hour') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_minute') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_month') do |method|
      method.define_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_second') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_time') do |method|
      method.define_optional_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('select_year') do |method|
      method.define_argument('date')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_ago_in_words') do |method|
      method.define_argument('from_time')
      method.define_optional_argument('include_seconds_or_options')
    end

    klass.define_instance_method('time_select') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_tag') do |method|
      method.define_argument('date_or_time')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::TestCase::DateTimeSelector') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::TagHelper', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::Helpers::CaptureHelper', RubyLint.registry))

    klass.define_instance_method('day')

    klass.define_instance_method('hour')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('datetime')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('min')

    klass.define_instance_method('month')

    klass.define_instance_method('sec')

    klass.define_instance_method('select_date')

    klass.define_instance_method('select_datetime')

    klass.define_instance_method('select_day')

    klass.define_instance_method('select_hour')

    klass.define_instance_method('select_minute')

    klass.define_instance_method('select_month')

    klass.define_instance_method('select_second')

    klass.define_instance_method('select_time')

    klass.define_instance_method('select_year')

    klass.define_instance_method('year')
  end

  defs.define_constant('ActionView::TestCase::DebugHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('debug') do |method|
      method.define_argument('object')
    end
  end

  defs.define_constant('ActionView::TestCase::DomAssertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_dom_equal') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_dom_not_equal') do |method|
      method.define_argument('expected')
      method.define_argument('actual')
      method.define_optional_argument('message')
    end
  end

  defs.define_constant('ActionView::TestCase::FormBuilder') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionView::ModelNaming', RubyLint.registry))

    klass.define_method('_to_partial_path')

    klass.define_method('field_helpers')

    klass.define_method('field_helpers=') do |method|
      method.define_argument('val')
    end

    klass.define_method('field_helpers?')

    klass.define_instance_method('button') do |method|
      method.define_optional_argument('value')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('check_box') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('checked_value')
      method.define_optional_argument('unchecked_value')
    end

    klass.define_instance_method('collection_check_boxes') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection_radio_buttons') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection_select') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('color_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('datetime_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_local_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('email_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('emitted_hidden_id?')

    klass.define_instance_method('field_helpers')

    klass.define_instance_method('field_helpers=')

    klass.define_instance_method('field_helpers?')

    klass.define_instance_method('fields_for') do |method|
      method.define_argument('record_name')
      method.define_optional_argument('record_object')
      method.define_optional_argument('fields_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('file_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('grouped_collection_select') do |method|
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('group_method')
      method.define_argument('group_label_method')
      method.define_argument('option_key_method')
      method.define_argument('option_value_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('hidden_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('index')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('object_name')
      method.define_argument('object')
      method.define_argument('template')
      method.define_argument('options')
      method.define_optional_argument('block')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label') do |method|
      method.define_argument('method')
      method.define_optional_argument('text')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('month_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('multipart')

    klass.define_instance_method('multipart=') do |method|
      method.define_argument('multipart')
    end

    klass.define_instance_method('multipart?')

    klass.define_instance_method('number_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('object')

    klass.define_instance_method('object=')

    klass.define_instance_method('object_name')

    klass.define_instance_method('object_name=')

    klass.define_instance_method('options')

    klass.define_instance_method('options=')

    klass.define_instance_method('password_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('phone_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('radio_button') do |method|
      method.define_argument('method')
      method.define_argument('tag_value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('range_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('search_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('select') do |method|
      method.define_argument('method')
      method.define_argument('choices')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('submit') do |method|
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('telephone_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_area') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_zone_select') do |method|
      method.define_argument('method')
      method.define_optional_argument('priority_zones')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('to_model')

    klass.define_instance_method('to_partial_path')

    klass.define_instance_method('url_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('week_field') do |method|
      method.define_argument('method')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::TestCase::FormHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('check_box') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
      method.define_optional_argument('checked_value')
      method.define_optional_argument('unchecked_value')
    end

    klass.define_instance_method('color_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_local_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('email_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('fields_for') do |method|
      method.define_argument('record_name')
      method.define_optional_argument('record_object')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('file_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('form_for') do |method|
      method.define_argument('record')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('hidden_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('label') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('content_or_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('month_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('password_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('phone_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('radio_button') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_argument('tag_value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('range_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('search_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('telephone_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_area') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('week_field') do |method|
      method.define_argument('object_name')
      method.define_argument('method')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::TestCase::FormOptionsHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('collection_check_boxes') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection_radio_buttons') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('collection_select') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('grouped_collection_select') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_argument('collection')
      method.define_argument('group_method')
      method.define_argument('group_label_method')
      method.define_argument('option_key_method')
      method.define_argument('option_value_method')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('grouped_options_for_select') do |method|
      method.define_argument('grouped_options')
      method.define_optional_argument('selected_key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('option_groups_from_collection_for_select') do |method|
      method.define_argument('collection')
      method.define_argument('group_method')
      method.define_argument('group_label_method')
      method.define_argument('option_key_method')
      method.define_argument('option_value_method')
      method.define_optional_argument('selected_key')
    end

    klass.define_instance_method('options_for_select') do |method|
      method.define_argument('container')
      method.define_optional_argument('selected')
    end

    klass.define_instance_method('options_from_collection_for_select') do |method|
      method.define_argument('collection')
      method.define_argument('value_method')
      method.define_argument('text_method')
      method.define_optional_argument('selected')
    end

    klass.define_instance_method('select') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_argument('choices')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('time_zone_options_for_select') do |method|
      method.define_optional_argument('selected')
      method.define_optional_argument('priority_zones')
      method.define_optional_argument('model')
    end

    klass.define_instance_method('time_zone_select') do |method|
      method.define_argument('object')
      method.define_argument('method')
      method.define_optional_argument('priority_zones')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
    end
  end

  defs.define_constant('ActionView::TestCase::FormTagHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('embed_authenticity_token_in_remote_forms')

    klass.define_method('embed_authenticity_token_in_remote_forms=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('button_tag') do |method|
      method.define_optional_argument('content_or_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('check_box_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('checked')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('color_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('date_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('datetime_local_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('email_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('embed_authenticity_token_in_remote_forms')

    klass.define_instance_method('embed_authenticity_token_in_remote_forms=') do |method|
      method.define_argument('obj')
    end

    klass.define_instance_method('field_set_tag') do |method|
      method.define_optional_argument('legend')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('file_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('form_tag') do |method|
      method.define_optional_argument('url_for_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('hidden_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('image_submit_tag') do |method|
      method.define_argument('source')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('label_tag') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('content_or_options')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('month_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('password_field_tag') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('phone_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('radio_button_tag') do |method|
      method.define_argument('name')
      method.define_argument('value')
      method.define_optional_argument('checked')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('range_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('search_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('select_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('option_tags')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('submit_tag') do |method|
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('telephone_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_area_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('content')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('text_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('time_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('url_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('utf8_enforcer_tag')

    klass.define_instance_method('week_field_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('value')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::TestCase::INTERNAL_IVARS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::InvalidNumberError') do |klass|
    klass.inherits(defs.constant_proxy('StandardError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('number')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('number')

    klass.define_instance_method('number=')
  end

  defs.define_constant('ActionView::TestCase::JOIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::JS_ESCAPE_MAP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::JavaScriptHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('button_to_function') do |method|
      method.define_argument('name')
      method.define_optional_argument('function')
      method.define_optional_argument('html_options')
    end

    klass.define_instance_method('escape_javascript') do |method|
      method.define_argument('javascript')
    end

    klass.define_instance_method('j') do |method|
      method.define_argument('javascript')
    end

    klass.define_instance_method('javascript_cdata_section') do |method|
      method.define_argument('content')
    end

    klass.define_instance_method('javascript_tag') do |method|
      method.define_optional_argument('content_or_options_with_block')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('link_to_function') do |method|
      method.define_argument('name')
      method.define_argument('function')
      method.define_optional_argument('html_options')
    end
  end

  defs.define_constant('ActionView::TestCase::Locals') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('render') do |method|
      method.define_optional_argument('options')
      method.define_optional_argument('local_assigns')
    end

    klass.define_instance_method('rendered_views')

    klass.define_instance_method('rendered_views=')
  end

  defs.define_constant('ActionView::TestCase::NEW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::NO_STRIP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::NumberHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('number_to_currency') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_human') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_human_size') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_percentage') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_to_phone') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_with_delimiter') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('number_with_precision') do |method|
      method.define_argument('number')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::TestCase::OutputSafetyHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('raw') do |method|
      method.define_argument('stringish')
    end

    klass.define_instance_method('safe_join') do |method|
      method.define_argument('array')
      method.define_optional_argument('sep')
    end
  end

  defs.define_constant('ActionView::TestCase::PASSTHROUGH_EXCEPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::PRE_CONTENT_STRINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::RecordTagHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('content_tag_for') do |method|
      method.define_argument('tag_name')
      method.define_argument('single_or_multiple_records')
      method.define_optional_argument('prefix')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('div_for') do |method|
      method.define_argument('record')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::TestCase::RenderedViewsCollection') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('view')
      method.define_argument('locals')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('locals_for') do |method|
      method.define_argument('view')
    end

    klass.define_instance_method('rendered_views')

    klass.define_instance_method('view_rendered?') do |method|
      method.define_argument('view')
      method.define_argument('expected_locals')
    end
  end

  defs.define_constant('ActionView::TestCase::RenderingHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_layout_for') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('render') do |method|
      method.define_optional_argument('options')
      method.define_optional_argument('locals')
      method.define_block_argument('block')
    end
  end

  defs.define_constant('ActionView::TestCase::ResponseAssertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_redirected_to') do |method|
      method.define_optional_argument('options')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_response') do |method|
      method.define_argument('type')
      method.define_optional_argument('message')
    end
  end

  defs.define_constant('ActionView::TestCase::RoutingAssertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_generates') do |method|
      method.define_argument('expected_path')
      method.define_argument('options')
      method.define_optional_argument('defaults')
      method.define_optional_argument('extras')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('assert_recognizes') do |method|
      method.define_argument('expected_options')
      method.define_argument('path')
      method.define_optional_argument('extras')
      method.define_optional_argument('msg')
    end

    klass.define_instance_method('assert_routing') do |method|
      method.define_argument('path')
      method.define_argument('options')
      method.define_optional_argument('defaults')
      method.define_optional_argument('extras')
      method.define_optional_argument('message')
    end

    klass.define_instance_method('method_missing') do |method|
      method.define_argument('selector')
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('with_routing')
  end

  defs.define_constant('ActionView::TestCase::SanitizeHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('sanitize') do |method|
      method.define_argument('html')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('sanitize_css') do |method|
      method.define_argument('style')
    end

    klass.define_instance_method('strip_links') do |method|
      method.define_argument('html')
    end

    klass.define_instance_method('strip_tags') do |method|
      method.define_argument('html')
    end
  end

  defs.define_constant('ActionView::TestCase::SelectorAssertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_select') do |method|
      method.define_rest_argument('args')
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_select_email') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('assert_select_encoded') do |method|
      method.define_optional_argument('element')
      method.define_block_argument('block')
    end

    klass.define_instance_method('count_description') do |method|
      method.define_argument('min')
      method.define_argument('max')
      method.define_argument('count')
    end

    klass.define_instance_method('css_select') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('response_from_page')
  end

  defs.define_constant('ActionView::TestCase::TagAssertions') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('assert_no_tag') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('assert_tag') do |method|
      method.define_rest_argument('opts')
    end

    klass.define_instance_method('find_all_tag') do |method|
      method.define_argument('conditions')
    end

    klass.define_instance_method('find_tag') do |method|
      method.define_argument('conditions')
    end

    klass.define_instance_method('html_document')
  end

  defs.define_constant('ActionView::TestCase::TagHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cdata_section') do |method|
      method.define_argument('content')
    end

    klass.define_instance_method('content_tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('content_or_options_with_block')
      method.define_optional_argument('options')
      method.define_optional_argument('escape')
      method.define_block_argument('block')
    end

    klass.define_instance_method('escape_once') do |method|
      method.define_argument('html')
    end

    klass.define_instance_method('tag') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('open')
      method.define_optional_argument('escape')
    end
  end

  defs.define_constant('ActionView::TestCase::Tags') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController') do |klass|
    klass.inherits(defs.constant_proxy('ActionController::Base', RubyLint.registry))
    klass.inherits(defs.constant_proxy('ActionDispatch::TestProcess', RubyLint.registry))

    klass.define_method('_helpers')

    klass.define_method('controller_path=')

    klass.define_method('middleware_stack')

    klass.define_instance_method('controller_path=') do |method|
      method.define_argument('path')
    end

    klass.define_instance_method('initialize')

    klass.define_instance_method('params')

    klass.define_instance_method('params=')

    klass.define_instance_method('request')

    klass.define_instance_method('request=')

    klass.define_instance_method('response')

    klass.define_instance_method('response=')
  end

  defs.define_constant('ActionView::TestCase::TestController::ACTION_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::All') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::CALLBACK_FILTER_TYPES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::Callback') do |klass|
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

  defs.define_constant('ActionView::TestCase::TestController::CallbackChain') do |klass|
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

  defs.define_constant('ActionView::TestCase::TestController::ClassMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_set_wrapper_options') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('inherited') do |method|
      method.define_argument('klass')
    end

    klass.define_instance_method('wrap_parameters') do |method|
      method.define_argument('name_or_model_or_options')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::TestCase::TestController::Collector') do |klass|
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
      method.define_argument('mime_type')
      method.define_block_argument('block')
    end

    klass.define_instance_method('format')

    klass.define_instance_method('format=')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('mimes')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('negotiate_format') do |method|
      method.define_argument('request')
    end

    klass.define_instance_method('order')

    klass.define_instance_method('order=')

    klass.define_instance_method('response')
  end

  defs.define_constant('ActionView::TestCase::TestController::ConfigMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('cache_store')

    klass.define_instance_method('cache_store=') do |method|
      method.define_argument('store')
    end
  end

  defs.define_constant('ActionView::TestCase::TestController::Configuration') do |klass|
    klass.inherits(defs.constant_proxy('ActiveSupport::InheritableOptions', RubyLint.registry))

    klass.define_method('compile_methods!') do |method|
      method.define_argument('keys')
    end

    klass.define_instance_method('compile_methods!')
  end

  defs.define_constant('ActionView::TestCase::TestController::DEFAULT_PROTECTED_INSTANCE_VARIABLES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::DEFAULT_SEND_FILE_DISPOSITION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::DEFAULT_SEND_FILE_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::EXCLUDE_PARAMETERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::FileBody') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('path')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('to_path')
  end

  defs.define_constant('ActionView::TestCase::TestController::Fragments') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('expire_fragment') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('fragment_cache_key') do |method|
      method.define_argument('key')
    end

    klass.define_instance_method('fragment_exist?') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('instrument_fragment_cache') do |method|
      method.define_argument('name')
      method.define_argument('key')
    end

    klass.define_instance_method('read_fragment') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('write_fragment') do |method|
      method.define_argument('key')
      method.define_argument('content')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::TestCase::TestController::INSTANCE_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::MODULES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::MODULE_MESSAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::Options') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from_hash') do |method|
      method.define_argument('hash')
    end

    klass.define_instance_method('include')

    klass.define_instance_method('initialize') do |method|
      method.define_argument('name')
      method.define_argument('format')
      method.define_argument('include')
      method.define_argument('exclude')
      method.define_argument('klass')
      method.define_argument('model')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('lock')

    klass.define_instance_method('locked?')

    klass.define_instance_method('model')

    klass.define_instance_method('name')

    klass.define_instance_method('synchronize') do |method|
      method.define_block_argument('block')
    end

    klass.define_instance_method('try_lock')

    klass.define_instance_method('unlock')
  end

  defs.define_constant('ActionView::TestCase::TestController::ProtectionMethods') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::REDIRECT_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::RENDERERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TestController::URL_OPTIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::TextHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('concat') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('current_cycle') do |method|
      method.define_optional_argument('name')
    end

    klass.define_instance_method('cycle') do |method|
      method.define_argument('first_value')
      method.define_rest_argument('values')
    end

    klass.define_instance_method('excerpt') do |method|
      method.define_argument('text')
      method.define_argument('phrase')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('highlight') do |method|
      method.define_argument('text')
      method.define_argument('phrases')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('pluralize') do |method|
      method.define_argument('count')
      method.define_argument('singular')
      method.define_optional_argument('plural')
    end

    klass.define_instance_method('reset_cycle') do |method|
      method.define_optional_argument('name')
    end

    klass.define_instance_method('safe_concat') do |method|
      method.define_argument('string')
    end

    klass.define_instance_method('simple_format') do |method|
      method.define_argument('text')
      method.define_optional_argument('html_options')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('truncate') do |method|
      method.define_argument('text')
      method.define_optional_argument('options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('word_wrap') do |method|
      method.define_argument('text')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::TestCase::TranslationHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('l') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('localize') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('t') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end

    klass.define_instance_method('translate') do |method|
      method.define_argument('key')
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::TestCase::UNDEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('inspect')
  end

  defs.define_constant('ActionView::TestCase::URI_REGEXP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('ActionView::TestCase::UrlHelper') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('_back_url')

    klass.define_instance_method('button_to') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('current_page?') do |method|
      method.define_argument('options')
    end

    klass.define_instance_method('link_to') do |method|
      method.define_optional_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('link_to_if') do |method|
      method.define_argument('condition')
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('link_to_unless') do |method|
      method.define_argument('condition')
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('link_to_unless_current') do |method|
      method.define_argument('name')
      method.define_optional_argument('options')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('mail_to') do |method|
      method.define_argument('email_address')
      method.define_optional_argument('name')
      method.define_optional_argument('html_options')
      method.define_block_argument('block')
    end

    klass.define_instance_method('url_for') do |method|
      method.define_optional_argument('options')
    end
  end

  defs.define_constant('ActionView::WrongEncodingError') do |klass|
    klass.inherits(defs.constant_proxy('ActionView::EncodingError', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_argument('string')
      method.define_argument('encoding')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('message')
  end
end
