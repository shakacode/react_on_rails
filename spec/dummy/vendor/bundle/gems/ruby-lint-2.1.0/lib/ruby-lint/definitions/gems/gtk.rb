# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: ruby 1.9.3

RubyLint.registry.register('Gtk') do |defs|
  defs.define_constant('Gtk') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('check_version') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('check_version?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('current')

    klass.define_method('current_event')

    klass.define_method('current_event_state')

    klass.define_method('current_event_time')

    klass.define_method('default_language')

    klass.define_method('disable_setlocale')

    klass.define_method('events_pending?')

    klass.define_method('get_event_widget') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('grab_add') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('grab_remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('idle_add') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('idle_add_priority') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('idle_remove') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('init') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('init_add') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('key_snooper_install')

    klass.define_method('key_snooper_remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('main')

    klass.define_method('main_do_event') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('main_iteration')

    klass.define_method('main_iteration_do') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('main_level')

    klass.define_method('main_quit')

    klass.define_method('propagate_event') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('quit_add') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('quit_remove') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('show_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('timeout_add') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('timeout_remove') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end
  end

  defs.define_constant('Gtk::AboutDialog') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Dialog', RubyLint.registry))

    klass.define_method('set_email_hook') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('set_url_hook') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('show') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('artists')

    klass.define_instance_method('artists=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('authors')

    klass.define_instance_method('authors=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('comments')

    klass.define_instance_method('comments=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('copyright')

    klass.define_instance_method('copyright=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('documenters')

    klass.define_instance_method('documenters=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('license')

    klass.define_instance_method('license=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('license_type')

    klass.define_instance_method('license_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('logo')

    klass.define_instance_method('logo=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('logo_icon_name')

    klass.define_instance_method('logo_icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('program_name')

    klass.define_instance_method('program_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_artists') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_authors') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_comments') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_copyright') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_documenters') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_license') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_license_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_logo') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_logo_icon_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_program_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_translator_credits') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_version') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_website') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_website_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_wrap_license') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('translator_credits')

    klass.define_instance_method('translator_credits=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('version')

    klass.define_instance_method('version=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('website')

    klass.define_instance_method('website=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('website_label')

    klass.define_instance_method('website_label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap_license=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap_license?')
  end

  defs.define_constant('Gtk::AboutDialog::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('destroy_with_parent?')

    klass.define_instance_method('modal?')
  end

  defs.define_constant('Gtk::AboutDialog::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::License') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::License::ARTISTIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::License::BSD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::License::CUSTOM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::License::GPL_2_0') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::License::GPL_3_0') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::License::LGPL_2_1') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::License::LGPL_3_0') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::License::MIT_X11') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::License::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::Position') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AboutDialog::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AccelFlags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('locked?')

    klass.define_instance_method('mask?')

    klass.define_instance_method('visible?')
  end

  defs.define_constant('Gtk::AccelFlags::LOCKED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AccelFlags::MASK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AccelFlags::VISIBLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AccelGroup') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_method('activate') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('from_accel_closure') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('from_object') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('activate') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('connect') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('disconnect') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('disconnect_key') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('find')

    klass.define_instance_method('lock')

    klass.define_instance_method('locked?')

    klass.define_instance_method('modifier_mask')

    klass.define_instance_method('query') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('unlock')
  end

  defs.define_constant('Gtk::AccelGroup::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AccelGroupEntry') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('accel_key')

    klass.define_instance_method('accel_path')

    klass.define_instance_method('closure')
  end

  defs.define_constant('Gtk::AccelKey') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('flags')

    klass.define_instance_method('flags=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('key')

    klass.define_instance_method('key=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mods')

    klass.define_instance_method('mods=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_flags') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_key') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_mods') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::AccelLabel') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Label', RubyLint.registry))

    klass.define_instance_method('accel_closure')

    klass.define_instance_method('accel_closure=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('accel_widget')

    klass.define_instance_method('accel_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('accel_width')

    klass.define_instance_method('refetch')

    klass.define_instance_method('set_accel_closure') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_accel_widget') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::AccelLabel::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AccelLabel::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AccelLabel::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AccelLabel::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AccelMap') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_method('add_entry') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('add_filter') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('change_entry') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_method('each')

    klass.define_method('each_unfilterd')

    klass.define_method('get')

    klass.define_method('load') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('lock_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('lookup_entry') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('save') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('unlock_path') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::AccelMap::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accelerator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('default_mod_mask')

    klass.define_method('default_mod_mask=') do |method|
      method.define_argument('val')
    end

    klass.define_method('get_label') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('parse') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('set_default_mod_mask') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('to_name') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('valid') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end

  defs.define_constant('Gtk::Accessible') do |klass|
    klass.inherits(defs.constant_proxy('Atk::Object', RubyLint.registry))

    klass.define_instance_method('connect_widget_destroyed')

    klass.define_instance_method('set_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('widget')

    klass.define_instance_method('widget=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Accessible::LAYER_BACKGROUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::LAYER_CANVAS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::LAYER_INVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::LAYER_MDI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::LAYER_OVERLAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::LAYER_POPUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::LAYER_WIDGET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::LAYER_WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::Layer') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_ACCEL_LABEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_ALERT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_ANIMATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_APPLICATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_ARROW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_AUTOCOMPLETE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_CALENDAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_CANVAS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_CAPTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_CHART') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_CHECK_BOX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_CHECK_MENU_ITEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_COLOR_CHOOSER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_COLUMN_HEADER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_COMBO_BOX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_COMMENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DATE_EDITOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DESKTOP_FRAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DESKTOP_ICON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DIAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DIALOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DIRECTORY_PANE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DOCUMENT_EMAIL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DOCUMENT_FRAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DOCUMENT_PRESENTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DOCUMENT_SPREADSHEET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DOCUMENT_TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DOCUMENT_WEB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_DRAWING_AREA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_EDITBAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_EMBEDDED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_ENTRY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_FILE_CHOOSER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_FILLER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_FONT_CHOOSER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_FOOTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_FORM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_FRAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_GLASS_PANE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_GROUPING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_HEADER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_HEADING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_HTML_CONTAINER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_ICON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_IMAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_IMAGE_MAP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_INFO_BAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_INPUT_METHOD_WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_INTERNAL_FRAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_INVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_LABEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_LAST_DEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_LAYERED_PANE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_LEVEL_BAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_LINK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_LIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_LIST_BOX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_LIST_ITEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_MENU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_MENU_BAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_MENU_ITEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_NOTIFICATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_OPTION_PANE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_PAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_PAGE_TAB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_PAGE_TAB_LIST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_PANEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_PARAGRAPH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_PASSWORD_TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_POPUP_MENU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_PROGRESS_BAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_PUSH_BUTTON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_RADIO_BUTTON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_RADIO_MENU_ITEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_REDUNDANT_OBJECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_ROOT_PANE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_ROW_HEADER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_RULER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_SCROLL_BAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_SCROLL_PANE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_SECTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_SLIDER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_SPIN_BUTTON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_SPLIT_PANE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_STATUSBAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TABLE_CELL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TABLE_COLUMN_HEADER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TABLE_ROW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TABLE_ROW_HEADER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TEAR_OFF_MENU_ITEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TERMINAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TOGGLE_BUTTON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TOOL_BAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TOOL_TIP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TREE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TREE_ITEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_TREE_TABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_VIEWPORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::ROLE_WINDOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Accessible::Role') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

    klass.define_method('for_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('localized_name')
  end

  defs.define_constant('Gtk::Action') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('accel_closure')

    klass.define_instance_method('accel_group=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('accel_path')

    klass.define_instance_method('accel_path=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('action_group')

    klass.define_instance_method('action_group=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('activate')

    klass.define_instance_method('always_show_image=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('always_show_image?')

    klass.define_instance_method('block_activate')

    klass.define_instance_method('block_activate_from') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('connect_accelerator')

    klass.define_instance_method('connect_proxy') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('create_icon') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('create_menu')

    klass.define_instance_method('create_menu_item')

    klass.define_instance_method('create_tool_item')

    klass.define_instance_method('disconnect_accelerator')

    klass.define_instance_method('disconnect_proxy') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('gicon')

    klass.define_instance_method('gicon=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hide_if_empty=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hide_if_empty?')

    klass.define_instance_method('icon_name')

    klass.define_instance_method('icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('important=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('important?')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('is_sensitive?')

    klass.define_instance_method('is_visible?')

    klass.define_instance_method('label')

    klass.define_instance_method('label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('proxies')

    klass.define_instance_method('sensitive=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('sensitive?')

    klass.define_instance_method('set_accel_group') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_accel_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_action_group') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_always_show_image') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gicon') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_hide_if_empty') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_important') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_sensitive') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_short_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stock_id') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tooltip') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible_horizontal') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible_overflown') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible_vertical') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('short_label')

    klass.define_instance_method('short_label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stock_id')

    klass.define_instance_method('stock_id=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tooltip')

    klass.define_instance_method('tooltip=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('unblock_activate')

    klass.define_instance_method('unblock_activate_from') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible?')

    klass.define_instance_method('visible_horizontal=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible_horizontal?')

    klass.define_instance_method('visible_overflown=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible_overflown?')

    klass.define_instance_method('visible_vertical=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible_vertical?')
  end

  defs.define_constant('Gtk::Action::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ActionGroup') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('accel_group')

    klass.define_instance_method('accel_group=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('actions')

    klass.define_instance_method('add_action') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('add_actions') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_radio_actions') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('add_toggle_actions') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_action') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('remove_action') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('sensitive=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('sensitive?')

    klass.define_instance_method('set_accel_group') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_sensitive') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_translate_func')

    klass.define_instance_method('set_translation_domain') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_visible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('translate_string') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('translation_domain=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible?')
  end

  defs.define_constant('Gtk::ActionGroup::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Activatable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('related_action')

    klass.define_instance_method('related_action=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_related_action') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_action_appearance') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_action_appearance=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_action_appearance?')
  end

  defs.define_constant('Gtk::Adjustment') do |klass|
    klass.inherits(defs.constant_proxy('GLib::InitiallyUnowned', RubyLint.registry))

    klass.define_instance_method('changed')

    klass.define_instance_method('clamp_page') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('configure') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
      method.define_argument('arg6')
    end

    klass.define_instance_method('lower')

    klass.define_instance_method('lower=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('minimum_increment')

    klass.define_instance_method('page_increment')

    klass.define_instance_method('page_increment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('page_size')

    klass.define_instance_method('page_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_lower') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_page_increment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_page_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_step_increment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_upper') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_value') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('step_increment')

    klass.define_instance_method('step_increment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('upper')

    klass.define_instance_method('upper=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('value')

    klass.define_instance_method('value=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('value_changed')
  end

  defs.define_constant('Gtk::Adjustment::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Alignment') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))

    klass.define_instance_method('bottom_padding')

    klass.define_instance_method('bottom_padding=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('left_padding')

    klass.define_instance_method('left_padding=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('padding')

    klass.define_instance_method('right_padding')

    klass.define_instance_method('right_padding=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('set_bottom_padding') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_left_padding') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_padding') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('set_right_padding') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_top_padding') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_xalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_xscale') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_yalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_yscale') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('top_padding')

    klass.define_instance_method('top_padding=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('xalign')

    klass.define_instance_method('xalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('xscale')

    klass.define_instance_method('xscale=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('yalign')

    klass.define_instance_method('yalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('yscale')

    klass.define_instance_method('yscale=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Alignment::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Alignment::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Alignment::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Alignment::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Allocation') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('&') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('height')

    klass.define_instance_method('height=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('intersect') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_height') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_width') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_x') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_y') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('to_rect')

    klass.define_instance_method('union') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('width')

    klass.define_instance_method('width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('x')

    klass.define_instance_method('x=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('y')

    klass.define_instance_method('y=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('|') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::AppChooser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('app_info')

    klass.define_instance_method('content_type')

    klass.define_instance_method('refresh')
  end

  defs.define_constant('Gtk::AppChooserButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ComboBox', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::AppChooser', RubyLint.registry))

    klass.define_instance_method('active_custom_item=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('append_custom_item') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('append_separator')

    klass.define_instance_method('heading')

    klass.define_instance_method('heading=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_active_custom_item') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_heading') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_default_item') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_dialog_item') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_default_item=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_default_item?')

    klass.define_instance_method('show_dialog_item=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_dialog_item?')
  end

  defs.define_constant('Gtk::AppChooserButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserDialog') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Dialog', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::AppChooser', RubyLint.registry))

    klass.define_instance_method('gfile')

    klass.define_instance_method('heading')

    klass.define_instance_method('heading=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_heading') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('widget')
  end

  defs.define_constant('Gtk::AppChooserDialog::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserDialog::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('destroy_with_parent?')

    klass.define_instance_method('modal?')
  end

  defs.define_constant('Gtk::AppChooserDialog::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserDialog::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserDialog::Position') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserDialog::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserDialog::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserWidget') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Box', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::AppChooser', RubyLint.registry))

    klass.define_instance_method('default_text')

    klass.define_instance_method('default_text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_default_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_all') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_default') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_fallback') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_other') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_recommended') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_all=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_all?')

    klass.define_instance_method('show_default=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_default?')

    klass.define_instance_method('show_fallback=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_fallback?')

    klass.define_instance_method('show_other=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_other?')

    klass.define_instance_method('show_recommended=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_recommended?')
  end

  defs.define_constant('Gtk::AppChooserWidget::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserWidget::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserWidget::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AppChooserWidget::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Application') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('active_window')

    klass.define_instance_method('add_window') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('app_menu')

    klass.define_instance_method('app_menu=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('menubar')

    klass.define_instance_method('menubar=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('register_session=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('register_session?')

    klass.define_instance_method('remove_window') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_app_menu') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_menubar') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_register_session') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('windows')
  end

  defs.define_constant('Gtk::Application::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Misc', RubyLint.registry))

    klass.define_instance_method('arrow_type')

    klass.define_instance_method('arrow_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_arrow_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_shadow_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('shadow_type')

    klass.define_instance_method('shadow_type=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Arrow::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::Placement') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::Placement::BOTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::Placement::END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::Placement::START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::Type::DOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::Type::LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::Type::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::Type::RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Arrow::Type::UP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AspectFrame') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Frame', RubyLint.registry))

    klass.define_instance_method('obey_child=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('obey_child?')

    klass.define_instance_method('ratio')

    klass.define_instance_method('ratio=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('set_obey_child') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_ratio') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_xalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_yalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('xalign')

    klass.define_instance_method('xalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('yalign')

    klass.define_instance_method('yalign=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::AspectFrame::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AspectFrame::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AspectFrame::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AspectFrame::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Window', RubyLint.registry))

    klass.define_instance_method('add_action_widget') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('append_page') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('commit')

    klass.define_instance_method('current_page')

    klass.define_instance_method('current_page=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('get_nth_page') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_page_complete') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_page_header_image') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('get_page_side_image') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('get_page_title') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_page_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('insert_page') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('n_pages')

    klass.define_instance_method('next_page')

    klass.define_instance_method('prepend_page') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('previous_page')

    klass.define_instance_method('remove_action_widget') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_page') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_current_page') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_forward_page_func')

    klass.define_instance_method('set_page_complete') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_page_header_image') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_page_side_image') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_page_title') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_page_type') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('update_buttons_state')
  end

  defs.define_constant('Gtk::Assistant::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::PageType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::PageType::CONFIRM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::PageType::CONTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::PageType::CUSTOM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::PageType::INTRO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::PageType::PROGRESS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::PageType::SUMMARY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::Position') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Assistant::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::AttachOptions') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('expand?')

    klass.define_instance_method('fill?')

    klass.define_instance_method('shrink?')
  end

  defs.define_constant('Gtk::AttachOptions::EXPAND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AttachOptions::FILL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::AttachOptions::SHRINK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BINARY_AGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BINDING_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BUILD_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Bin') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))

    klass.define_instance_method('child')
  end

  defs.define_constant('Gtk::Bin::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Bin::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Bin::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Bin::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::BindingSet') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_method('find') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('activate') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('add_path') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('add_signal') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('entry_add_signal') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('entry_clear') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('entry_remove') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('entry_skip') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end

  defs.define_constant('Gtk::Border') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('bottom')

    klass.define_instance_method('bottom=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('left')

    klass.define_instance_method('left=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('right')

    klass.define_instance_method('right=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_bottom') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_left') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_right') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_top') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('to_a')

    klass.define_instance_method('top')

    klass.define_instance_method('top=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Box') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))

    klass.define_instance_method('baseline_position')

    klass.define_instance_method('baseline_position=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('homogeneous=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('homogeneous?')

    klass.define_instance_method('pack_end') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('pack_end_defaults') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('pack_start') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('pack_start_defaults') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('query_child_packing') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('reorder_child') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_baseline_position') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_child_packing') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_homogeneous') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_spacing') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('spacing')

    klass.define_instance_method('spacing=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Box::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Box::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Box::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Box::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Buildable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_child') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('builder_name')

    klass.define_instance_method('builder_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('construct_child') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_internal_child') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_buildable_property') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_builder_name') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::Builder') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('<<') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_from_file') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_from_string') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('connect_signals')

    klass.define_instance_method('get_object') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('objects')

    klass.define_instance_method('set_translation_domain') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('translation_domain')

    klass.define_instance_method('translation_domain=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Builder::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::DUPLICATE_ID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::INVALID_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::INVALID_TAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::INVALID_TYPE_FUNCTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::INVALID_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::MISSING_ATTRIBUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::MISSING_PROPERTY_VALUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::OBJECT_TYPE_REFUSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::TEMPLATE_MISMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::UNHANDLED_TAG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::BuilderError::VERSION_MISMATCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Button') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Activatable', RubyLint.registry))

    klass.define_instance_method('activate')

    klass.define_instance_method('alignment')

    klass.define_instance_method('always_show_image=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('always_show_image?')

    klass.define_instance_method('clicked')

    klass.define_instance_method('enter') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('event_window')

    klass.define_instance_method('focus_on_click=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_on_click?')

    klass.define_instance_method('image')

    klass.define_instance_method('image=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('image_position')

    klass.define_instance_method('image_position=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label')

    klass.define_instance_method('label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('leave') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('pressed') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('released') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('relief')

    klass.define_instance_method('relief=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_alignment') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_always_show_image') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_focus_on_click') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_image') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_image_position') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_relief') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_stock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_underline') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_xalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_yalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_stock=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_stock?')

    klass.define_instance_method('use_underline=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_underline?')

    klass.define_instance_method('xalign')

    klass.define_instance_method('xalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('yalign')

    klass.define_instance_method('yalign=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Button::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Button::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Button::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Button::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ButtonBox') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Box', RubyLint.registry))

    klass.define_instance_method('get_child_non_homogeneous') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_child_secondary') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('layout_style')

    klass.define_instance_method('layout_style=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_child_non_homogeneous') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_child_secondary') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_layout_style') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::ButtonBox::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ButtonBox::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ButtonBox::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ButtonBox::Style') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ButtonBox::Style::CENTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ButtonBox::Style::EDGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ButtonBox::Style::END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ButtonBox::Style::SPREAD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ButtonBox::Style::START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ButtonBox::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Calendar') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))

    klass.define_instance_method('clear_marks')

    klass.define_instance_method('date')

    klass.define_instance_method('day')

    klass.define_instance_method('day=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('detail_height_rows')

    klass.define_instance_method('detail_height_rows=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('detail_width_chars')

    klass.define_instance_method('detail_width_chars=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('display_options')

    klass.define_instance_method('display_options=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('freeze') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('mark_day') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('month')

    klass.define_instance_method('month=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('no_month_change=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('no_month_change?')

    klass.define_instance_method('select_day') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('select_month') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_day') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_detail_height_rows') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_detail_width_chars') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_display_options') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_month') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_no_month_change') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_day_names') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_details') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_heading') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_week_numbers') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_year') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_day_names=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_day_names?')

    klass.define_instance_method('show_details=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_details?')

    klass.define_instance_method('show_heading=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_heading?')

    klass.define_instance_method('show_week_numbers=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_week_numbers?')

    klass.define_instance_method('thaw') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('unmark_day') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('year')

    klass.define_instance_method('year=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Calendar::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Calendar::DisplayOptions') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('no_month_change?')

    klass.define_instance_method('show_day_names?')

    klass.define_instance_method('show_details?')

    klass.define_instance_method('show_heading?')

    klass.define_instance_method('show_week_numbers?')
  end

  defs.define_constant('Gtk::Calendar::DisplayOptions::NO_MONTH_CHANGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Calendar::DisplayOptions::SHOW_DAY_NAMES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Calendar::DisplayOptions::SHOW_DETAILS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Calendar::DisplayOptions::SHOW_HEADING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Calendar::DisplayOptions::SHOW_WEEK_NUMBERS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Calendar::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Calendar::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Calendar::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellEditable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('editing_canceled=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editing_canceled?')

    klass.define_instance_method('editing_done')

    klass.define_instance_method('remove_widget')

    klass.define_instance_method('set_editing_canceled') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('start_editing') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::CellLayout') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_attribute') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('cell_data_func=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cells')

    klass.define_instance_method('clear')

    klass.define_instance_method('clear_attributes') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('pack_end') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('pack_start') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('reorder') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_attributes') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_cell_data_func') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::CellRenderer') do |klass|
    klass.inherits(defs.constant_proxy('GLib::InitiallyUnowned', RubyLint.registry))

    klass.define_instance_method('activate') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
      method.define_argument('arg6')
    end

    klass.define_instance_method('cell_background=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cell_background_gdk')

    klass.define_instance_method('cell_background_gdk=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cell_background_rgba')

    klass.define_instance_method('cell_background_rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cell_background_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cell_background_set?')

    klass.define_instance_method('editing?')

    klass.define_instance_method('editing_canceled') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('expanded=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('expanded?')

    klass.define_instance_method('expander=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('expander?')

    klass.define_instance_method('fixed_size')

    klass.define_instance_method('get_preferred_size') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_size') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('height')

    klass.define_instance_method('height=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mode')

    klass.define_instance_method('mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('sensitive=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('sensitive?')

    klass.define_instance_method('set_cell_background') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_cell_background_gdk') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_cell_background_rgba') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_cell_background_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_expanded') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_expander') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_fixed_size') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_height') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_sensitive') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_xalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_xpad') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_yalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_ypad') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('start_editing') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
      method.define_argument('arg6')
    end

    klass.define_instance_method('stop_editing') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible?')

    klass.define_instance_method('width')

    klass.define_instance_method('width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('xalign')

    klass.define_instance_method('xalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('xpad')

    klass.define_instance_method('xpad=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('yalign')

    klass.define_instance_method('yalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('ypad')

    klass.define_instance_method('ypad=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::CellRenderer::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::Mode::ACTIVATABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::Mode::EDITABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::Mode::INERT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::State') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('expandable?')

    klass.define_instance_method('expanded?')

    klass.define_instance_method('focused?')

    klass.define_instance_method('insensitive?')

    klass.define_instance_method('prelit?')

    klass.define_instance_method('selected?')

    klass.define_instance_method('sorted?')
  end

  defs.define_constant('Gtk::CellRenderer::State::EXPANDABLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::State::EXPANDED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::State::FOCUSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::State::INSENSITIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::State::PRELIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::State::SELECTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRenderer::State::SORTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererAccel') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::CellRendererText', RubyLint.registry))

    klass.define_instance_method('accel_key')

    klass.define_instance_method('accel_key=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('accel_mode')

    klass.define_instance_method('accel_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('accel_mods')

    klass.define_instance_method('accel_mods=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('keycode')

    klass.define_instance_method('keycode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_accel_key') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_accel_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_accel_mods') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_keycode') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::CellRendererAccel::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererAccel::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererAccel::Mode::GTK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererAccel::Mode::OTHER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererAccel::State') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('expandable?')

    klass.define_instance_method('expanded?')

    klass.define_instance_method('focused?')

    klass.define_instance_method('insensitive?')

    klass.define_instance_method('prelit?')

    klass.define_instance_method('selected?')

    klass.define_instance_method('sorted?')
  end

  defs.define_constant('Gtk::CellRendererCombo') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::CellRendererText', RubyLint.registry))

    klass.define_instance_method('has_entry=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_entry?')

    klass.define_instance_method('model')

    klass.define_instance_method('model=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_entry') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_model') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text_column')

    klass.define_instance_method('text_column=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::CellRendererCombo::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererCombo::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererCombo::State') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('expandable?')

    klass.define_instance_method('expanded?')

    klass.define_instance_method('focused?')

    klass.define_instance_method('insensitive?')

    klass.define_instance_method('prelit?')

    klass.define_instance_method('selected?')

    klass.define_instance_method('sorted?')
  end

  defs.define_constant('Gtk::CellRendererPixbuf') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::CellRenderer', RubyLint.registry))

    klass.define_instance_method('follow_state=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('follow_state?')

    klass.define_instance_method('gicon')

    klass.define_instance_method('gicon=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon_name')

    klass.define_instance_method('icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixbuf')

    klass.define_instance_method('pixbuf=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixbuf_expander_closed')

    klass.define_instance_method('pixbuf_expander_closed=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixbuf_expander_open')

    klass.define_instance_method('pixbuf_expander_open=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_follow_state') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gicon') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixbuf') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixbuf_expander_closed') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixbuf_expander_open') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stock_detail') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stock_id') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stock_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_surface') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stock_detail')

    klass.define_instance_method('stock_detail=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stock_id')

    klass.define_instance_method('stock_id=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stock_size')

    klass.define_instance_method('stock_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('surface')

    klass.define_instance_method('surface=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::CellRendererPixbuf::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererPixbuf::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererPixbuf::State') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('expandable?')

    klass.define_instance_method('expanded?')

    klass.define_instance_method('focused?')

    klass.define_instance_method('insensitive?')

    klass.define_instance_method('prelit?')

    klass.define_instance_method('selected?')

    klass.define_instance_method('sorted?')
  end

  defs.define_constant('Gtk::CellRendererProgress') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::CellRenderer', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('inverted=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inverted?')

    klass.define_instance_method('pulse')

    klass.define_instance_method('pulse=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_inverted') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pulse') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text_xalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text_yalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_value') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text')

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text_xalign')

    klass.define_instance_method('text_xalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text_yalign')

    klass.define_instance_method('text_yalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('value')

    klass.define_instance_method('value=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::CellRendererProgress::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererProgress::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererProgress::State') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('expandable?')

    klass.define_instance_method('expanded?')

    klass.define_instance_method('focused?')

    klass.define_instance_method('insensitive?')

    klass.define_instance_method('prelit?')

    klass.define_instance_method('selected?')

    klass.define_instance_method('sorted?')
  end

  defs.define_constant('Gtk::CellRendererSpin') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::CellRendererText', RubyLint.registry))

    klass.define_instance_method('adjustment')

    klass.define_instance_method('adjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('climb_rate')

    klass.define_instance_method('climb_rate=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('digits')

    klass.define_instance_method('digits=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_adjustment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_climb_rate') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_digits') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::CellRendererSpin::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererSpin::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererSpin::State') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('expandable?')

    klass.define_instance_method('expanded?')

    klass.define_instance_method('focused?')

    klass.define_instance_method('insensitive?')

    klass.define_instance_method('prelit?')

    klass.define_instance_method('selected?')

    klass.define_instance_method('sorted?')
  end

  defs.define_constant('Gtk::CellRendererSpinner') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::CellRenderer', RubyLint.registry))

    klass.define_instance_method('active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active?')

    klass.define_instance_method('pulse')

    klass.define_instance_method('pulse=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_active') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pulse') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('size=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::CellRendererSpinner::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererSpinner::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererSpinner::State') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('expandable?')

    klass.define_instance_method('expanded?')

    klass.define_instance_method('focused?')

    klass.define_instance_method('insensitive?')

    klass.define_instance_method('prelit?')

    klass.define_instance_method('selected?')

    klass.define_instance_method('sorted?')
  end

  defs.define_constant('Gtk::CellRendererText') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::CellRenderer', RubyLint.registry))

    klass.define_instance_method('align_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('align_set?')

    klass.define_instance_method('alignment')

    klass.define_instance_method('alignment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('attributes')

    klass.define_instance_method('attributes=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_gdk')

    klass.define_instance_method('background_gdk=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_rgba')

    klass.define_instance_method('background_rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_set?')

    klass.define_instance_method('editable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editable?')

    klass.define_instance_method('editable_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editable_set?')

    klass.define_instance_method('ellipsize')

    klass.define_instance_method('ellipsize=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('ellipsize_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('ellipsize_set?')

    klass.define_instance_method('family')

    klass.define_instance_method('family=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('family_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('family_set?')

    klass.define_instance_method('fixed_height_from_font=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('font')

    klass.define_instance_method('font=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('font_desc')

    klass.define_instance_method('font_desc=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('foreground=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('foreground_gdk')

    klass.define_instance_method('foreground_gdk=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('foreground_rgba')

    klass.define_instance_method('foreground_rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('foreground_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('foreground_set?')

    klass.define_instance_method('language')

    klass.define_instance_method('language=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('language_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('language_set?')

    klass.define_instance_method('markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('max_width_chars')

    klass.define_instance_method('max_width_chars=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('placeholder_text')

    klass.define_instance_method('placeholder_text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('rise')

    klass.define_instance_method('rise=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('rise_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('rise_set?')

    klass.define_instance_method('scale')

    klass.define_instance_method('scale=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('scale_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('scale_set?')

    klass.define_instance_method('set_align_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_alignment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_attributes') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_gdk') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_rgba') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_editable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_editable_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_ellipsize') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_ellipsize_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_family') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_family_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_fixed_height_from_font') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_font') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_font_desc') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_foreground') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_foreground_gdk') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_foreground_rgba') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_foreground_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_language') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_language_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_markup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_max_width_chars') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_placeholder_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_rise') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_rise_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_scale') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_scale_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_single_paragraph_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_size_points') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_size_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stretch') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stretch_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_strikethrough') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_strikethrough_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_style') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_style_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_underline') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_underline_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_variant') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_variant_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_weight') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_weight_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_width_chars') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_wrap_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_wrap_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('single_paragraph_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('single_paragraph_mode?')

    klass.define_instance_method('size')

    klass.define_instance_method('size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size_points')

    klass.define_instance_method('size_points=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size_set?')

    klass.define_instance_method('stretch')

    klass.define_instance_method('stretch=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stretch_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stretch_set?')

    klass.define_instance_method('strikethrough=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('strikethrough?')

    klass.define_instance_method('strikethrough_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('strikethrough_set?')

    klass.define_instance_method('style')

    klass.define_instance_method('style=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('style_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('style_set?')

    klass.define_instance_method('text')

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('underline')

    klass.define_instance_method('underline=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('underline_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('underline_set?')

    klass.define_instance_method('variant')

    klass.define_instance_method('variant=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('variant_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('variant_set?')

    klass.define_instance_method('weight')

    klass.define_instance_method('weight=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('weight_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('weight_set?')

    klass.define_instance_method('width_chars')

    klass.define_instance_method('width_chars=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap_mode')

    klass.define_instance_method('wrap_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap_width')

    klass.define_instance_method('wrap_width=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::CellRendererText::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererText::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererText::State') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('expandable?')

    klass.define_instance_method('expanded?')

    klass.define_instance_method('focused?')

    klass.define_instance_method('insensitive?')

    klass.define_instance_method('prelit?')

    klass.define_instance_method('selected?')

    klass.define_instance_method('sorted?')
  end

  defs.define_constant('Gtk::CellRendererToggle') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::CellRenderer', RubyLint.registry))

    klass.define_instance_method('activatable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('activatable?')

    klass.define_instance_method('active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active?')

    klass.define_instance_method('inconsistent=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inconsistent?')

    klass.define_instance_method('indicator_size')

    klass.define_instance_method('indicator_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('radio=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('radio?')

    klass.define_instance_method('set_activatable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_active') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_inconsistent') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_indicator_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_radio') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::CellRendererToggle::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererToggle::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellRendererToggle::State') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('expandable?')

    klass.define_instance_method('expanded?')

    klass.define_instance_method('focused?')

    klass.define_instance_method('insensitive?')

    klass.define_instance_method('prelit?')

    klass.define_instance_method('selected?')

    klass.define_instance_method('sorted?')
  end

  defs.define_constant('Gtk::CellView') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::CellLayout', RubyLint.registry))

    klass.define_instance_method('background=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_gdk')

    klass.define_instance_method('background_gdk=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_rgba')

    klass.define_instance_method('background_rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_set?')

    klass.define_instance_method('cell_area')

    klass.define_instance_method('cell_area_context')

    klass.define_instance_method('cell_renderers') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('displayed_row')

    klass.define_instance_method('displayed_row=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('draw_sensitive=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('draw_sensitive?')

    klass.define_instance_method('fit_model=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('fit_model?')

    klass.define_instance_method('get_size_of_row') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('model')

    klass.define_instance_method('model=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_gdk') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_rgba') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_displayed_row') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_draw_sensitive') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_fit_model') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_model') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::CellView::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellView::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellView::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CellView::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CheckButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ToggleButton', RubyLint.registry))

  end

  defs.define_constant('Gtk::CheckButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CheckButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CheckButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CheckButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CheckMenuItem') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::MenuItem', RubyLint.registry))

    klass.define_instance_method('active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active?')

    klass.define_instance_method('draw_as_radio=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('draw_as_radio?')

    klass.define_instance_method('inconsistent=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inconsistent?')

    klass.define_instance_method('set_active') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_draw_as_radio') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_inconsistent') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('toggled')
  end

  defs.define_constant('Gtk::CheckMenuItem::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CheckMenuItem::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CheckMenuItem::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CheckMenuItem::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Clipboard') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_method('get') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('can_store=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('display')

    klass.define_instance_method('image=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('request_contents') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('request_image')

    klass.define_instance_method('request_rich_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('request_targets')

    klass.define_instance_method('request_text')

    klass.define_instance_method('set') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_can_store') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_image') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('store')

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wait_for_contents') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('wait_for_image')

    klass.define_instance_method('wait_for_rich_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('wait_for_targets')

    klass.define_instance_method('wait_for_text')

    klass.define_instance_method('wait_is_image_available?')

    klass.define_instance_method('wait_is_rich_text_available?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('wait_is_target_available?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('wait_is_text_available?')
  end

  defs.define_constant('Gtk::Clipboard::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Button', RubyLint.registry))

    klass.define_instance_method('alpha')

    klass.define_instance_method('alpha=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('color')

    klass.define_instance_method('color=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('rgba')

    klass.define_instance_method('rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_alpha') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_color') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_rgba') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_title') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_alpha') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('title')

    klass.define_instance_method('title=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_alpha=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_alpha?')
  end

  defs.define_constant('Gtk::ColorButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorSelection') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Box', RubyLint.registry))

    klass.define_method('palette_from_string') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('palette_to_string') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('set_change_palette_hook')

    klass.define_instance_method('adjusting?')

    klass.define_instance_method('current_alpha')

    klass.define_instance_method('current_alpha=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('current_color')

    klass.define_instance_method('current_color=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('current_rgba')

    klass.define_instance_method('current_rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_opacity_control=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_opacity_control?')

    klass.define_instance_method('has_palette=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_palette?')

    klass.define_instance_method('previous_alpha')

    klass.define_instance_method('previous_alpha=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('previous_color')

    klass.define_instance_method('previous_color=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('previous_rgba')

    klass.define_instance_method('previous_rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_current_alpha') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_current_color') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_current_rgba') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_opacity_control') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_palette') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_previous_alpha') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_previous_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_previous_rgba') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::ColorSelection::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorSelection::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorSelection::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorSelection::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorSelectionDialog') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Dialog', RubyLint.registry))

    klass.define_instance_method('cancel_button')

    klass.define_instance_method('color_selection')

    klass.define_instance_method('colorsel') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('help_button')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('ok_button')
  end

  defs.define_constant('Gtk::ColorSelectionDialog::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorSelectionDialog::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('destroy_with_parent?')

    klass.define_instance_method('modal?')
  end

  defs.define_constant('Gtk::ColorSelectionDialog::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorSelectionDialog::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorSelectionDialog::Position') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorSelectionDialog::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ColorSelectionDialog::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ComboBox') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::CellEditable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::CellLayout', RubyLint.registry))

    klass.define_instance_method('active')

    klass.define_instance_method('active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active_id')

    klass.define_instance_method('active_id=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active_iter')

    klass.define_instance_method('active_iter=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active_text') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('add_tearoffs=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('add_tearoffs?')

    klass.define_instance_method('append_text') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('button_sensitivity')

    klass.define_instance_method('button_sensitivity=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cell_area')

    klass.define_instance_method('column_span_column')

    klass.define_instance_method('column_span_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('entry_text_column')

    klass.define_instance_method('entry_text_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_on_click=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_on_click?')

    klass.define_instance_method('has_entry?')

    klass.define_instance_method('has_frame=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_frame?')

    klass.define_instance_method('id_column')

    klass.define_instance_method('id_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('insert_text') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('model')

    klass.define_instance_method('model=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('move_active') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('popdown')

    klass.define_instance_method('popup')

    klass.define_instance_method('popup_accessible')

    klass.define_instance_method('popup_fixed_width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('popup_fixed_width?')

    klass.define_instance_method('popup_for_device') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('popup_shown?')

    klass.define_instance_method('prepend_text') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('remove_text') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('row_span_column')

    klass.define_instance_method('row_span_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_active') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_active_id') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_active_iter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_add_tearoffs') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_button_sensitivity') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_column_span_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_entry_text_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_focus_on_click') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_frame') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_id_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_model') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_popup_fixed_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_row_separator_func')

    klass.define_instance_method('set_row_span_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tearoff_title') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_title') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_wrap_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tearoff_title')

    klass.define_instance_method('tearoff_title=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('title')

    klass.define_instance_method('title=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap_width')

    klass.define_instance_method('wrap_width=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::ComboBox::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ComboBox::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ComboBox::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ComboBox::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ComboBoxText') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ComboBox', RubyLint.registry))

    klass.define_instance_method('active_text')

    klass.define_instance_method('append') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('append_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('insert') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('insert_text') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('prepend') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('prepend_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_all')
  end

  defs.define_constant('Gtk::ComboBoxText::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ComboBoxText::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ComboBoxText::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ComboBoxText::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Container') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))

    klass.define_method('child_properties') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('child_property') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('install_child_property') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('type_register') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('<<') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('add') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('border_width')

    klass.define_instance_method('border_width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('check_resize')

    klass.define_instance_method('child=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('child_get_property') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('child_set_property') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('child_type')

    klass.define_instance_method('children')

    klass.define_instance_method('each') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('each_forall') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('focus_chain')

    klass.define_instance_method('focus_chain=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_child=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_hadjustment')

    klass.define_instance_method('focus_hadjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_vadjustment')

    klass.define_instance_method('focus_vadjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('reallocate_redraws=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('resize_children')

    klass.define_instance_method('resize_container?')

    klass.define_instance_method('resize_mode')

    klass.define_instance_method('resize_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_border_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_child') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_focus_chain') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_focus_child') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_focus_hadjustment') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_focus_vadjustment') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_reallocate_redraws') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_resize_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('unset_focus_chain')
  end

  defs.define_constant('Gtk::Container::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Container::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Container::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Container::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CornerType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::CornerType::BOTTOM_LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CornerType::BOTTOM_RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CornerType::TOP_LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CornerType::TOP_RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::CssProvider') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::StyleProvider', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_method('default')

    klass.define_method('get_named') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('load') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('to_s')
  end

  defs.define_constant('Gtk::CssProvider::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DeleteType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::DeleteType::CHARS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DeleteType::DISPLAY_LINES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DeleteType::DISPLAY_LINE_ENDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DeleteType::PARAGRAPHS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DeleteType::PARAGRAPH_ENDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DeleteType::WHITESPACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DeleteType::WORDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DeleteType::WORD_ENDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Dialog') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Window', RubyLint.registry))

    klass.define_method('alternative_dialog_button_order?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('action_area')

    klass.define_instance_method('add_action_widget') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('add_button') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('add_buttons') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('alternative_button_order=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('content_area')

    klass.define_instance_method('default_response=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('get_response') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_response_for_widget') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_widget_for_response') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('response') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('run')

    klass.define_instance_method('set_alternative_button_order') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_default_response') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_response_sensitive') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('vbox') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end
  end

  defs.define_constant('Gtk::Dialog::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Dialog::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Dialog::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Dialog::Position') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Dialog::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Dialog::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::DirectionType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::DirectionType::DOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DirectionType::LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DirectionType::RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DirectionType::TAB_BACKWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DirectionType::TAB_FORWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DirectionType::UP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Drag') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('begin') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_add_image_targets') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_add_text_targets') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_add_uri_targets') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_find_target') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_get_target_list') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_get_track_motion') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_set') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_set_proxy') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_set_target_list') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_set_track_motion') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('dest_unset') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('finish') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('get_data') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('highlight') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('set_icon') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('set_icon_default') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('set_icon_name') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('source_add_image_targets') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('source_add_text_targets') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('source_add_uri_targets') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('source_get_target_list') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('source_set') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('source_set_icon') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('source_set_icon_name') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('source_set_target_list') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('source_unset') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('threshold?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('unhighlight') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end
  end

  defs.define_constant('Gtk::Drag::DestDefaults') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('all?')

    klass.define_instance_method('drop?')

    klass.define_instance_method('highlight?')

    klass.define_instance_method('motion?')
  end

  defs.define_constant('Gtk::Drag::DestDefaults::ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Drag::DestDefaults::DROP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Drag::DestDefaults::HIGHLIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Drag::DestDefaults::MOTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Drag::TargetFlags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('other_app?')

    klass.define_instance_method('other_widget?')

    klass.define_instance_method('same_app?')

    klass.define_instance_method('same_widget?')
  end

  defs.define_constant('Gtk::Drag::TargetFlags::OTHER_APP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Drag::TargetFlags::OTHER_WIDGET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Drag::TargetFlags::SAME_APP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Drag::TargetFlags::SAME_WIDGET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DrawingArea') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))

  end

  defs.define_constant('Gtk::DrawingArea::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::DrawingArea::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::DrawingArea::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::DrawingArea::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Editable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('copy_clipboard')

    klass.define_instance_method('cut_clipboard')

    klass.define_instance_method('delete_selection')

    klass.define_instance_method('delete_text') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('editable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editable?')

    klass.define_instance_method('get_chars') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('insert_text') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('paste_clipboard')

    klass.define_instance_method('position')

    klass.define_instance_method('position=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('select_region') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('selection_bounds')

    klass.define_instance_method('set_editable') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_position') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::Entry') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::CellEditable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Editable', RubyLint.registry))

    klass.define_instance_method('activate')

    klass.define_instance_method('activates_default=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('activates_default?')

    klass.define_instance_method('attributes')

    klass.define_instance_method('attributes=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('backspace')

    klass.define_instance_method('buffer')

    klass.define_instance_method('buffer=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('caps_lock_warning=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('caps_lock_warning?')

    klass.define_instance_method('completion')

    klass.define_instance_method('completion=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('copy_clipboard')

    klass.define_instance_method('current_icon_drag_source')

    klass.define_instance_method('cursor_hadjustment')

    klass.define_instance_method('cursor_hadjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cursor_position')

    klass.define_instance_method('cut_clipboard')

    klass.define_instance_method('delete_from_cursor') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
    end

    klass.define_instance_method('editable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editable?')

    klass.define_instance_method('get_icon_area') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_icon_at_pos') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('has_frame=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_frame?')

    klass.define_instance_method('im_context_filter_keypress') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('im_module')

    klass.define_instance_method('im_module=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inner_border')

    klass.define_instance_method('inner_border=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('input_hints')

    klass.define_instance_method('input_hints=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('input_purpose')

    klass.define_instance_method('input_purpose=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('insert_at_cursor') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('invisible_char')

    klass.define_instance_method('invisible_char=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('invisible_char_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('invisible_char_set?')

    klass.define_instance_method('layout')

    klass.define_instance_method('layout_index_to_text_index') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('layout_offsets')

    klass.define_instance_method('max_length')

    klass.define_instance_method('max_length=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('move_cursor') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
      method.define_argument('x2')
    end

    klass.define_instance_method('overwrite_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('overwrite_mode?')

    klass.define_instance_method('paste_clipboard')

    klass.define_instance_method('placeholder_text')

    klass.define_instance_method('placeholder_text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('populate_all=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('populate_all?')

    klass.define_instance_method('preedit_changed') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('primary_icon_activatable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('primary_icon_activatable?')

    klass.define_instance_method('primary_icon_gicon')

    klass.define_instance_method('primary_icon_gicon=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('primary_icon_name')

    klass.define_instance_method('primary_icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('primary_icon_pixbuf')

    klass.define_instance_method('primary_icon_pixbuf=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('primary_icon_sensitive=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('primary_icon_sensitive?')

    klass.define_instance_method('primary_icon_stock')

    klass.define_instance_method('primary_icon_stock=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('primary_icon_storage_type')

    klass.define_instance_method('primary_icon_tooltip_markup')

    klass.define_instance_method('primary_icon_tooltip_markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('primary_icon_tooltip_text')

    klass.define_instance_method('primary_icon_tooltip_text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('progress_fraction')

    klass.define_instance_method('progress_fraction=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('progress_pulse')

    klass.define_instance_method('progress_pulse_step')

    klass.define_instance_method('progress_pulse_step=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('reset_im_context')

    klass.define_instance_method('scroll_offset')

    klass.define_instance_method('secondary_icon_activatable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('secondary_icon_activatable?')

    klass.define_instance_method('secondary_icon_gicon')

    klass.define_instance_method('secondary_icon_gicon=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('secondary_icon_name')

    klass.define_instance_method('secondary_icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('secondary_icon_pixbuf')

    klass.define_instance_method('secondary_icon_pixbuf=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('secondary_icon_sensitive=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('secondary_icon_sensitive?')

    klass.define_instance_method('secondary_icon_stock')

    klass.define_instance_method('secondary_icon_stock=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('secondary_icon_storage_type')

    klass.define_instance_method('secondary_icon_tooltip_markup')

    klass.define_instance_method('secondary_icon_tooltip_markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('secondary_icon_tooltip_text')

    klass.define_instance_method('secondary_icon_tooltip_text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('selection_bound')

    klass.define_instance_method('set_activates_default') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_attributes') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_buffer') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_caps_lock_warning') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_completion') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_cursor_hadjustment') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_editable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_frame') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon_drag_source') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_im_module') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_inner_border') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_input_hints') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_input_purpose') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_invisible_char') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_invisible_char_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_max_length') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_overwrite_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_placeholder_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_populate_all') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_primary_icon_activatable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_primary_icon_gicon') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_primary_icon_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_primary_icon_pixbuf') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_primary_icon_sensitive') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_primary_icon_stock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_primary_icon_tooltip_markup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_primary_icon_tooltip_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_progress_fraction') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_progress_pulse_step') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_secondary_icon_activatable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_secondary_icon_gicon') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_secondary_icon_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_secondary_icon_pixbuf') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_secondary_icon_sensitive') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_secondary_icon_stock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_secondary_icon_tooltip_markup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_secondary_icon_tooltip_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_shadow_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tabs') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_truncate_multiline') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visibility') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_width_chars') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_xalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('shadow_type')

    klass.define_instance_method('shadow_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tabs')

    klass.define_instance_method('tabs=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text')

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text_area')

    klass.define_instance_method('text_index_to_layout_index') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('text_length')

    klass.define_instance_method('toggle_overwrite')

    klass.define_instance_method('truncate_multiline=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('truncate_multiline?')

    klass.define_instance_method('unset_invisible_char')

    klass.define_instance_method('visibility=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visibility?')

    klass.define_instance_method('width_chars')

    klass.define_instance_method('width_chars=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('xalign')

    klass.define_instance_method('xalign=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Entry::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Entry::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Entry::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Entry::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::EntryBuffer') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('bytes')

    klass.define_instance_method('delete_text') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('insert_text') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('length')

    klass.define_instance_method('max_length')

    klass.define_instance_method('max_length=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_max_length') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text')

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::EntryBuffer::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::EntryCompletion') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::CellLayout', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('cell_area')

    klass.define_instance_method('complete')

    klass.define_instance_method('completion_prefix')

    klass.define_instance_method('delete_action') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('entry')

    klass.define_instance_method('inline_completion=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inline_completion?')

    klass.define_instance_method('inline_selection=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inline_selection?')

    klass.define_instance_method('insert_action_markup') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('insert_action_text') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('insert_prefix')

    klass.define_instance_method('minimum_key_length')

    klass.define_instance_method('minimum_key_length=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('model')

    klass.define_instance_method('model=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('popup_completion=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('popup_completion?')

    klass.define_instance_method('popup_set_width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('popup_set_width?')

    klass.define_instance_method('popup_single_match=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('popup_single_match?')

    klass.define_instance_method('set_inline_completion') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_inline_selection') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_match_func')

    klass.define_instance_method('set_minimum_key_length') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_model') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_popup_completion') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_popup_set_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_popup_single_match') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text_column') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('text_column')

    klass.define_instance_method('text_column=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::EntryCompletion::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::EventBox') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))

    klass.define_instance_method('above_child=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('above_child?')

    klass.define_instance_method('set_above_child') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible_window') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible_window=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible_window?')
  end

  defs.define_constant('Gtk::EventBox::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::EventBox::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::EventBox::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::EventBox::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Expander') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))

    klass.define_instance_method('activate')

    klass.define_instance_method('expanded=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('expanded?')

    klass.define_instance_method('label')

    klass.define_instance_method('label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('label_fill=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('label_fill?')

    klass.define_instance_method('label_widget')

    klass.define_instance_method('label_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('resize_toplevel=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('resize_toplevel?')

    klass.define_instance_method('set_expanded') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label_fill') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_resize_toplevel') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_spacing') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_markup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_underline') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('spacing')

    klass.define_instance_method('spacing=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_markup?')

    klass.define_instance_method('use_underline=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_underline?')
  end

  defs.define_constant('Gtk::Expander::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Expander::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Expander::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Expander::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ExpanderStyle') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ExpanderStyle::COLLAPSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ExpanderStyle::EXPANDED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ExpanderStyle::SEMI_COLLAPSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ExpanderStyle::SEMI_EXPANDED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('action')

    klass.define_instance_method('action=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('add_filter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_shortcut_folder') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_shortcut_folder_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('create_folders=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('create_folders?')

    klass.define_instance_method('current_folder')

    klass.define_instance_method('current_folder=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('current_folder_file')

    klass.define_instance_method('current_folder_file=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('current_folder_uri')

    klass.define_instance_method('current_folder_uri=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('current_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('do_overwrite_confirmation=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('do_overwrite_confirmation?')

    klass.define_instance_method('extra_widget')

    klass.define_instance_method('extra_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('file')

    klass.define_instance_method('file=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('filename')

    klass.define_instance_method('filename=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('filenames')

    klass.define_instance_method('files')

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('filters')

    klass.define_instance_method('local_only=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('local_only?')

    klass.define_instance_method('preview_file')

    klass.define_instance_method('preview_filename')

    klass.define_instance_method('preview_uri')

    klass.define_instance_method('preview_widget')

    klass.define_instance_method('preview_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('preview_widget_active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('preview_widget_active?')

    klass.define_instance_method('remove_filter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_shortcut_folder') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_shortcut_folder_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('select_all')

    klass.define_instance_method('select_file') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('select_filename') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('select_multiple=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('select_multiple?')

    klass.define_instance_method('select_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_action') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_create_folders') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_current_folder') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_current_folder_file') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_current_folder_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_current_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_do_overwrite_confirmation') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_extra_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_file') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_filename') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_filter') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_local_only') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_preview_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_preview_widget_active') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_select_multiple') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_hidden') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_use_preview_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('shortcut_folder_uris')

    klass.define_instance_method('shortcut_folders')

    klass.define_instance_method('show_hidden=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_hidden?')

    klass.define_instance_method('unselect_all')

    klass.define_instance_method('unselect_file') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('unselect_filename') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('unselect_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('uri')

    klass.define_instance_method('uri=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('uris')

    klass.define_instance_method('use_preview_label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_preview_label?')
  end

  defs.define_constant('Gtk::FileChooser::Action') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooser::Action::CREATE_FOLDER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooser::Action::OPEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooser::Action::SAVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooser::Action::SELECT_FOLDER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooser::Confirmation') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooser::Confirmation::ACCEPT_FILENAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooser::Confirmation::CONFIRM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooser::Confirmation::SELECT_AGAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Box', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::FileChooser', RubyLint.registry))

    klass.define_instance_method('focus_on_click=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_on_click?')

    klass.define_instance_method('set_focus_on_click') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_title') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_width_chars') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('title')

    klass.define_instance_method('title=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('width_chars')

    klass.define_instance_method('width_chars=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::FileChooserButton::Action') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserButton::Confirmation') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserDialog') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Dialog', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::FileChooser', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::FileChooserDialog::Action') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserDialog::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserDialog::Confirmation') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserDialog::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('destroy_with_parent?')

    klass.define_instance_method('modal?')
  end

  defs.define_constant('Gtk::FileChooserDialog::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserDialog::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserDialog::Position') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserDialog::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserDialog::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserEmbed') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::ALREADY_EXISTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::AlreadyExists') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::FileChooserError', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::BAD_FILENAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::BadFilename') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::FileChooserError', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::INCOMPLETE_HOSTNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::IncompleteHostname') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::FileChooserError', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::NONEXISTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::Nonexistent') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::FileChooserError', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::Nonexistent::ALREADY_EXISTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::Nonexistent::AlreadyExists') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::FileChooserError', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::Nonexistent::BAD_FILENAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::Nonexistent::BadFilename') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::FileChooserError', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::Nonexistent::INCOMPLETE_HOSTNAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::Nonexistent::IncompleteHostname') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::FileChooserError', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserError::Nonexistent::NONEXISTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserWidget') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Box', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::FileChooserEmbed', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::FileChooser', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserWidget::Action') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserWidget::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserWidget::Confirmation') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserWidget::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserWidget::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileChooserWidget::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileFilter') do |klass|
    klass.inherits(defs.constant_proxy('GLib::InitiallyUnowned', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('add_custom') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_mime_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_pattern') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_pixbuf_formats')

    klass.define_instance_method('filter?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('needed')

    klass.define_instance_method('set_name') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::FileFilter::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('display_name?')

    klass.define_instance_method('filename?')

    klass.define_instance_method('mime_type?')

    klass.define_instance_method('uri?')
  end

  defs.define_constant('Gtk::FileFilter::Flags::DISPLAY_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileFilter::Flags::FILENAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileFilter::Flags::MIME_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileFilter::Flags::URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FileFilter::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Fixed') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))

    klass.define_instance_method('move') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('put') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end
  end

  defs.define_constant('Gtk::Fixed::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Fixed::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Fixed::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Fixed::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Button', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::FontChooser', RubyLint.registry))

    klass.define_instance_method('font_name')

    klass.define_instance_method('font_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_font_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_style') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_title') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_font') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_size?')

    klass.define_instance_method('show_style=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_style?')

    klass.define_instance_method('title')

    klass.define_instance_method('title=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_font=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_font?')

    klass.define_instance_method('use_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_size?')
  end

  defs.define_constant('Gtk::FontButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('font')

    klass.define_instance_method('font=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('font_desc')

    klass.define_instance_method('font_desc=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('font_face')

    klass.define_instance_method('font_family')

    klass.define_instance_method('font_size')

    klass.define_instance_method('preview_text')

    klass.define_instance_method('preview_text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_filter_func')

    klass.define_instance_method('set_font') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_font_desc') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_preview_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_preview_entry') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_preview_entry=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_preview_entry?')
  end

  defs.define_constant('Gtk::FontChooserDialog') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Dialog', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::FontChooser', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserDialog::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserDialog::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('destroy_with_parent?')

    klass.define_instance_method('modal?')
  end

  defs.define_constant('Gtk::FontChooserDialog::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserDialog::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserDialog::Position') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserDialog::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserDialog::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserWidget') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Box', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::FontChooser', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserWidget::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserWidget::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserWidget::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::FontChooserWidget::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Frame') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))

    klass.define_instance_method('label')

    klass.define_instance_method('label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('label_align')

    klass.define_instance_method('label_widget')

    klass.define_instance_method('label_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('label_xalign')

    klass.define_instance_method('label_xalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('label_yalign')

    klass.define_instance_method('label_yalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label_align') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_label_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label_xalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label_yalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_shadow_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('shadow_type')

    klass.define_instance_method('shadow_type=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Frame::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Frame::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Frame::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Frame::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Grid') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))

    klass.define_instance_method('attach') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('attach_next_to') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('baseline_row')

    klass.define_instance_method('baseline_row=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('column_homogeneous=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('column_homogeneous?')

    klass.define_instance_method('column_spacing')

    klass.define_instance_method('column_spacing=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('get_child_at') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('insert_column') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('insert_next_to') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('insert_row') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('row_homogeneous=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('row_homogeneous?')

    klass.define_instance_method('row_spacing')

    klass.define_instance_method('row_spacing=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_baseline_row') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_column_homogeneous') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_column_spacing') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_row_homogeneous') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_row_spacing') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Grid::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Grid::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Grid::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Grid::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::HBox') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::HButtonBox') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::HPaned') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::HSV') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))

    klass.define_method('to_rgb') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('adjusting?')

    klass.define_instance_method('color')

    klass.define_instance_method('metrics')

    klass.define_instance_method('move') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('set_color') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_metrics') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end

  defs.define_constant('Gtk::HSV::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::HSV::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::HSV::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::HSV::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::HScale') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::HScrollbar') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::HSeparator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::HandleBox') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))

    klass.define_instance_method('child_detached?')

    klass.define_instance_method('handle_position')

    klass.define_instance_method('handle_position=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_handle_position') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_shadow_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_snap_edge') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_snap_edge_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('shadow_type')

    klass.define_instance_method('shadow_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('snap_edge')

    klass.define_instance_method('snap_edge=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('snap_edge_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('snap_edge_set?')
  end

  defs.define_constant('Gtk::HandleBox::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::HandleBox::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::HandleBox::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::HandleBox::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::HeaderBar') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))

    klass.define_instance_method('custom_title')

    klass.define_instance_method('custom_title=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pack_end') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('pack_start') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_custom_title') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_close_button') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_spacing') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_subtitle') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_title') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_close_button=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_close_button?')

    klass.define_instance_method('spacing')

    klass.define_instance_method('spacing=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('subtitle')

    klass.define_instance_method('subtitle=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('title')

    klass.define_instance_method('title=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::HeaderBar::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::HeaderBar::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::HeaderBar::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::HeaderBar::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::IMContext') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('client_window=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cursor_location=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('delete_surrounding') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('filter_keypress') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('focus_in')

    klass.define_instance_method('focus_out')

    klass.define_instance_method('input_hints')

    klass.define_instance_method('input_hints=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('input_purpose')

    klass.define_instance_method('input_purpose=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('preedit_string')

    klass.define_instance_method('reset')

    klass.define_instance_method('set_client_window') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_cursor_location') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_input_hints') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_input_purpose') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_surrounding') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_use_preedit') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('surrounding')

    klass.define_instance_method('use_preedit=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::IMContext::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IMContextSimple') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::IMContext', RubyLint.registry))

    klass.define_instance_method('add_table') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end
  end

  defs.define_constant('Gtk::IMContextSimple::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IMContextSimple::MAX_COMPOSE_LEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IMMulticontext') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::IMContext', RubyLint.registry))

    klass.define_instance_method('append_menuitems') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::IMMulticontext::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::INTERFACE_AGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconFactory') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_method('lookup_default') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('add_default')

    klass.define_instance_method('lookup') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_default')
  end

  defs.define_constant('Gtk::IconFactory::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconInfo') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('attach_points')

    klass.define_instance_method('base_size')

    klass.define_instance_method('builtin_pixbuf')

    klass.define_instance_method('display_name')

    klass.define_instance_method('embedded_rect')

    klass.define_instance_method('filename')

    klass.define_instance_method('load_icon')

    klass.define_instance_method('raw_coordinates=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_raw_coordinates') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::IconInfo::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconSet') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('add_source') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('render_icon') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('render_icon_pixbuf') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('sizes')
  end

  defs.define_constant('Gtk::IconSize') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('from_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('get_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('lookup') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('lookup_for_settings') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('register') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('register_alias') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end

  defs.define_constant('Gtk::IconSize::IconSize') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconSize::IconSize::BUTTON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconSize::IconSize::DIALOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconSize::IconSize::DND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconSize::IconSize::INVALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconSize::IconSize::LARGE_TOOLBAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconSize::IconSize::MENU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconSize::IconSize::SMALL_TOOLBAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconSource') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('direction')

    klass.define_instance_method('direction=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('direction_wildcarded=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('direction_wildcarded?')

    klass.define_instance_method('filename')

    klass.define_instance_method('filename=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon_name')

    klass.define_instance_method('icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixbuf')

    klass.define_instance_method('pixbuf=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_direction') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_direction_wildcarded') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_filename') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_icon_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_pixbuf') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_size') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_size_wildcarded') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_state') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_state_wildcarded') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size_wildcarded=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size_wildcarded?')

    klass.define_instance_method('state')

    klass.define_instance_method('state=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('state_wildcarded=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('state_wildcarded?')
  end

  defs.define_constant('Gtk::IconTheme') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_method('add_builtin_icon') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('default')

    klass.define_method('get_for_screen') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('append_search_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('choose_icon') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('contexts')

    klass.define_instance_method('custom_theme=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('example_icon_name')

    klass.define_instance_method('get_icon_sizes') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_icon?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('icons') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('load_icon') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('lookup_icon') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('prepend_search_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('rescan_if_needed')

    klass.define_instance_method('screen=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('search_path')

    klass.define_instance_method('search_path=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_custom_theme') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_screen') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_search_path') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::IconTheme::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconTheme::LookupFlags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('force_size?')

    klass.define_instance_method('force_svg?')

    klass.define_instance_method('generic_fallback?')

    klass.define_instance_method('no_svg?')

    klass.define_instance_method('use_builtin?')
  end

  defs.define_constant('Gtk::IconTheme::LookupFlags::FORCE_SIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconTheme::LookupFlags::FORCE_SVG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconTheme::LookupFlags::GENERIC_FALLBACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconTheme::LookupFlags::NO_SVG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconTheme::LookupFlags::USE_BUILTIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconThemeError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconThemeError::FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconThemeError::Failed') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::IconThemeError', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconThemeError::NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconThemeError::NotFound') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::IconThemeError', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconThemeError::NotFound::FAILED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconThemeError::NotFound::Failed') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::IconThemeError', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconThemeError::NotFound::NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Scrollable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::CellLayout', RubyLint.registry))

    klass.define_instance_method('activate_cursor_item')

    klass.define_instance_method('activate_on_single_click=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('activate_on_single_click?')

    klass.define_instance_method('cell_area')

    klass.define_instance_method('column_spacing')

    klass.define_instance_method('column_spacing=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('columns')

    klass.define_instance_method('columns=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('create_drag_icon') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('cursor')

    klass.define_instance_method('drag_dest_item')

    klass.define_instance_method('enable_model_drag_dest') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('enable_model_drag_source') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('get_cell_rect') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('get_dest_item') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_item') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_path') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_path_at_pos') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('item_activated') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('item_orientation')

    klass.define_instance_method('item_orientation=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('item_padding')

    klass.define_instance_method('item_padding=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('item_width')

    klass.define_instance_method('item_width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('margin')

    klass.define_instance_method('margin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('markup_column')

    klass.define_instance_method('markup_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('model')

    klass.define_instance_method('model=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('move_cursor') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
    end

    klass.define_instance_method('path_is_selected?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('pixbuf_column')

    klass.define_instance_method('pixbuf_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('reorderable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('reorderable?')

    klass.define_instance_method('row_spacing')

    klass.define_instance_method('row_spacing=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('scroll_to_path') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('select_all')

    klass.define_instance_method('select_cursor_item')

    klass.define_instance_method('select_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('selected_each')

    klass.define_instance_method('selected_items')

    klass.define_instance_method('selection_mode')

    klass.define_instance_method('selection_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_activate_on_single_click') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_column_spacing') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_columns') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_cursor') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_drag_dest_item') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_item_orientation') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_item_padding') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_item_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_margin') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_markup_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_model') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixbuf_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_reorderable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_row_spacing') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_selection_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_spacing') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tooltip_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('spacing')

    klass.define_instance_method('spacing=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text_column')

    klass.define_instance_method('text_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('toggle_cursor_item')

    klass.define_instance_method('tooltip_column')

    klass.define_instance_method('tooltip_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('unselect_all')

    klass.define_instance_method('unselect_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('unset_model_drag_dest')

    klass.define_instance_method('unset_model_drag_source')

    klass.define_instance_method('visible_range')
  end

  defs.define_constant('Gtk::IconView::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::Policy') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::Type::DROP_ABOVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::Type::DROP_BELOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::Type::DROP_INTO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::Type::DROP_LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::Type::DROP_RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::IconView::Type::NO_DROP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Misc', RubyLint.registry))

    klass.define_instance_method('clear')

    klass.define_instance_method('file')

    klass.define_instance_method('file=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gicon')

    klass.define_instance_method('gicon=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon_name')

    klass.define_instance_method('icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon_set')

    klass.define_instance_method('icon_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon_size')

    klass.define_instance_method('icon_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('pixbuf')

    klass.define_instance_method('pixbuf=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixbuf_animation')

    klass.define_instance_method('pixbuf_animation=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixel_size')

    klass.define_instance_method('pixel_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('resource')

    klass.define_instance_method('resource=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_file') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_from_gicon') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_from_icon_set') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_from_stock') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_gicon') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixbuf') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixbuf_animation') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixel_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_resource') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_surface') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_fallback') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stock')

    klass.define_instance_method('stock=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('storage_type')

    klass.define_instance_method('surface')

    klass.define_instance_method('surface=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_fallback=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_fallback?')
  end

  defs.define_constant('Gtk::Image::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::Type::ANIMATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::Type::EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::Type::GICON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::Type::ICON_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::Type::ICON_SET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::Type::PIXBUF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::Type::STOCK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Image::Type::SURFACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ImageMenuItem') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::MenuItem', RubyLint.registry))

    klass.define_instance_method('accel_group=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('always_show_image=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('always_show_image?')

    klass.define_instance_method('image')

    klass.define_instance_method('image=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('set_accel_group') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_always_show_image') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_image') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_stock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_stock=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_stock?')
  end

  defs.define_constant('Gtk::ImageMenuItem::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ImageMenuItem::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ImageMenuItem::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ImageMenuItem::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::InfoBar') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Box', RubyLint.registry))

    klass.define_instance_method('action_area')

    klass.define_instance_method('add_action_widget') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('add_button') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('add_buttons') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('close')

    klass.define_instance_method('content_area')

    klass.define_instance_method('default_response=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('message_type')

    klass.define_instance_method('message_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('response') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_default_response') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_message_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_response_sensitive') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_show_close_button') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_close_button=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_close_button?')
  end

  defs.define_constant('Gtk::InfoBar::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::InfoBar::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::InfoBar::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InfoBar::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::InitError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputHints') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('inhibit_osk?')

    klass.define_instance_method('lowercase?')

    klass.define_instance_method('no_spellcheck?')

    klass.define_instance_method('none?')

    klass.define_instance_method('spellcheck?')

    klass.define_instance_method('uppercase_chars?')

    klass.define_instance_method('uppercase_sentences?')

    klass.define_instance_method('uppercase_words?')

    klass.define_instance_method('word_completion?')
  end

  defs.define_constant('Gtk::InputHints::INHIBIT_OSK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputHints::LOWERCASE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputHints::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputHints::NO_SPELLCHECK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputHints::SPELLCHECK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputHints::UPPERCASE_CHARS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputHints::UPPERCASE_SENTENCES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputHints::UPPERCASE_WORDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputHints::WORD_COMPLETION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose::ALPHA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose::DIGITS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose::EMAIL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose::FREE_FORM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose::NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose::NUMBER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose::PASSWORD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose::PHONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose::PIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::InputPurpose::URL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Invisible') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))

    klass.define_instance_method('screen')

    klass.define_instance_method('screen=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_screen') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Invisible::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Invisible::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Invisible::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Invisible::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Justification') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Justification::CENTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Justification::FILL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Justification::LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Justification::RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Label') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Misc', RubyLint.registry))

    klass.define_instance_method('activate_current_link')

    klass.define_instance_method('angle')

    klass.define_instance_method('angle=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('attributes')

    klass.define_instance_method('attributes=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('copy_clipboard')

    klass.define_instance_method('cursor_position')

    klass.define_instance_method('ellipsize')

    klass.define_instance_method('ellipsize=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('justify')

    klass.define_instance_method('justify=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('label')

    klass.define_instance_method('label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('layout')

    klass.define_instance_method('layout_offsets')

    klass.define_instance_method('lines')

    klass.define_instance_method('lines=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('markup=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('max_width_chars')

    klass.define_instance_method('max_width_chars=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mnemonic_keyval')

    klass.define_instance_method('mnemonic_widget')

    klass.define_instance_method('mnemonic_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('move_cursor') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
      method.define_argument('x2')
    end

    klass.define_instance_method('pattern=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('select_region') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('selectable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('selectable?')

    klass.define_instance_method('selection_bound')

    klass.define_instance_method('selection_bounds')

    klass.define_instance_method('set_angle') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_attributes') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_ellipsize') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_justify') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_lines') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_markup') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_max_width_chars') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_mnemonic_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pattern') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_selectable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_single_line_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_track_visited_links') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_markup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_underline') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_width_chars') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_wrap') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_wrap_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('single_line_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('single_line_mode?')

    klass.define_instance_method('text')

    klass.define_instance_method('text=') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('track_visited_links=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('track_visited_links?')

    klass.define_instance_method('use_markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_markup?')

    klass.define_instance_method('use_underline=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_underline?')

    klass.define_instance_method('width_chars')

    klass.define_instance_method('width_chars=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap?')

    klass.define_instance_method('wrap_mode')

    klass.define_instance_method('wrap_mode=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Label::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Label::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Label::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Label::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Layout') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Scrollable', RubyLint.registry))

    klass.define_instance_method('bin_window')

    klass.define_instance_method('height')

    klass.define_instance_method('height=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('move') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('put') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_height') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_size') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('width')

    klass.define_instance_method('width=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Layout::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Layout::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Layout::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Layout::Policy') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Layout::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::LevelBar') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))

    klass.define_instance_method('add_offset_value') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_offset_value') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('inverted=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inverted?')

    klass.define_instance_method('max_value')

    klass.define_instance_method('max_value=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('min_value')

    klass.define_instance_method('min_value=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mode')

    klass.define_instance_method('mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('remove_offset_value') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_inverted') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_max_value') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_min_value') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_value') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('value')

    klass.define_instance_method('value=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::LevelBar::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::LevelBar::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::LevelBar::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::LevelBar::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::LevelBar::Mode::CONTINUOUS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::LevelBar::Mode::DISCRETE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::LevelBar::OFFSET_HIGH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::LevelBar::OFFSET_LOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::LevelBar::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::LinkButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Button', RubyLint.registry))

    klass.define_method('set_uri_hook') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_uri') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visited') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('uri')

    klass.define_instance_method('uri=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visited=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visited?')
  end

  defs.define_constant('Gtk::LinkButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::LinkButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::LinkButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::LinkButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ListStore') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeSortable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeDragDest', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeDragSource', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeModel', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('append')

    klass.define_instance_method('clear')

    klass.define_instance_method('insert') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('insert_after') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('insert_before') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iter_is_valid?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('move_after') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('move_before') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('prepend')

    klass.define_instance_method('remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('reorder') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_column_types') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_value') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_values') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('swap') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end

  defs.define_constant('Gtk::ListStore::DEFAULT_SORT_COLUMN_ID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ListStore::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('iters_persist?')

    klass.define_instance_method('list_only?')
  end

  defs.define_constant('Gtk::ListStore::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::LockButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Button', RubyLint.registry))

    klass.define_instance_method('permission')

    klass.define_instance_method('permission=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_permission') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text_lock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text_unlock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tooltip_lock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tooltip_not_authorized') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tooltip_unlock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text_lock')

    klass.define_instance_method('text_lock=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text_unlock')

    klass.define_instance_method('text_unlock=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tooltip_lock')

    klass.define_instance_method('tooltip_lock=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tooltip_not_authorized')

    klass.define_instance_method('tooltip_not_authorized=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tooltip_unlock')

    klass.define_instance_method('tooltip_unlock=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::LockButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::LockButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::LockButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::LockButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MAJOR_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MICRO_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MINOR_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Menu') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::MenuShell', RubyLint.registry))

    klass.define_method('get_for_attach_widget') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('accel_group')

    klass.define_instance_method('accel_group=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('accel_path')

    klass.define_instance_method('accel_path=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active')

    klass.define_instance_method('active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('attach') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('attach_to_widget') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('attach_widget')

    klass.define_instance_method('attach_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('detach')

    klass.define_instance_method('monitor')

    klass.define_instance_method('monitor=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('move_scroll') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('popdown')

    klass.define_instance_method('popup') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('reorder_child') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('reposition')

    klass.define_instance_method('reserve_toggle_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('reserve_toggle_size?')

    klass.define_instance_method('screen=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_accel_group') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_accel_path') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_active') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_attach_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_monitor') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_reserve_toggle_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_screen') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_tearoff_state') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tearoff_title') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tearoff_state=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tearoff_state?')

    klass.define_instance_method('tearoff_title')

    klass.define_instance_method('tearoff_title=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Menu::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Menu::DirectionType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Menu::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Menu::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Menu::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuBar') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::MenuShell', RubyLint.registry))

    klass.define_instance_method('child_pack_direction')

    klass.define_instance_method('child_pack_direction=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pack_direction')

    klass.define_instance_method('pack_direction=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_child_pack_direction') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pack_direction') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::MenuBar::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuBar::DirectionType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuBar::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuBar::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuBar::PackDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuBar::PackDirection::BTT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuBar::PackDirection::LTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuBar::PackDirection::RTL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuBar::PackDirection::TTB') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuBar::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ToggleButton', RubyLint.registry))

    klass.define_instance_method('align_widget')

    klass.define_instance_method('align_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('direction')

    klass.define_instance_method('direction=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('menu_model')

    klass.define_instance_method('menu_model=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('popup')

    klass.define_instance_method('popup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_align_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_direction') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_menu_model') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_popup') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::MenuButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuItem') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Activatable', RubyLint.registry))

    klass.define_instance_method('accel_path')

    klass.define_instance_method('accel_path=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('activate')

    klass.define_instance_method('label')

    klass.define_instance_method('label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('remove_submenu') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('right_justified=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('right_justified?')

    klass.define_instance_method('set_accel_path') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_right_justified') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_submenu') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_use_underline') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('submenu')

    klass.define_instance_method('submenu=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('toggle_size_allocate') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('toggle_size_request')

    klass.define_instance_method('use_underline=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_underline?')
  end

  defs.define_constant('Gtk::MenuItem::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuItem::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuItem::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuItem::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuShell') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))

    klass.define_instance_method('activate_current') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('activate_item') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('append') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('cancel')

    klass.define_instance_method('cycle_focus') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('deactivate')

    klass.define_instance_method('deselect')

    klass.define_instance_method('insert') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('move_current') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('prepend') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('select_first') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('select_item') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_take_focus') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('take_focus=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('take_focus?')
  end

  defs.define_constant('Gtk::MenuShell::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuShell::DirectionType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuShell::DirectionType::CHILD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuShell::DirectionType::NEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuShell::DirectionType::PARENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuShell::DirectionType::PREV') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuShell::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuShell::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuShell::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuToolButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ToolButton', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('menu')

    klass.define_instance_method('menu=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_menu') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::MenuToolButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuToolButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuToolButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MenuToolButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Dialog', RubyLint.registry))

    klass.define_instance_method('image')

    klass.define_instance_method('image=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('message_area')

    klass.define_instance_method('message_type')

    klass.define_instance_method('message_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('secondary_text')

    klass.define_instance_method('secondary_text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('secondary_use_markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('secondary_use_markup?')

    klass.define_instance_method('set_image') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_markup') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_message_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_secondary_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_secondary_use_markup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_markup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text')

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_markup?')
  end

  defs.define_constant('Gtk::MessageDialog::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::ButtonsType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::ButtonsType::CANCEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::ButtonsType::CLOSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::ButtonsType::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::ButtonsType::OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::ButtonsType::OK_CANCEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::ButtonsType::YES_NO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('destroy_with_parent?')

    klass.define_instance_method('modal?')
  end

  defs.define_constant('Gtk::MessageDialog::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::Position') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageDialog::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageType::ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageType::INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageType::OTHER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageType::QUESTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MessageType::WARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Misc') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))

    klass.define_instance_method('alignment')

    klass.define_instance_method('padding')

    klass.define_instance_method('set_alignment') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_padding') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_xalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_xpad') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_yalign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_ypad') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('xalign')

    klass.define_instance_method('xalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('xpad')

    klass.define_instance_method('xpad=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('yalign')

    klass.define_instance_method('yalign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('ypad')

    klass.define_instance_method('ypad=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Misc::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Misc::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Misc::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Misc::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep::BUFFER_ENDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep::DISPLAY_LINES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep::DISPLAY_LINE_ENDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep::HORIZONTAL_PAGES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep::LOGICAL_POSITIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep::PAGES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep::PARAGRAPHS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep::PARAGRAPH_ENDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep::VISUAL_POSITIONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::MovementStep::WORDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Notebook') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))

    klass.define_method('set_window_creation_hook') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('append_page') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('append_page_menu') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('change_current_page') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('enable_popup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('enable_popup?')

    klass.define_instance_method('focus_tab') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('get_action_widget') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_menu_label') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_menu_label_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_nth_page') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_tab_detachable') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_tab_label') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_tab_label_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_tab_reorderable') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('group_name')

    klass.define_instance_method('group_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('insert_page') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('insert_page_menu') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('move_focus_out') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('n_pages')

    klass.define_instance_method('next_page')

    klass.define_instance_method('page')

    klass.define_instance_method('page=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('page_num') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('prepend_page') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('prepend_page_menu') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('prev_page')

    klass.define_instance_method('query_tab_label_packing') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('remove_page') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('reorder_child') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('reorder_tab') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
    end

    klass.define_instance_method('scrollable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('scrollable?')

    klass.define_instance_method('select_page') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('set_action_widget') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_enable_popup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_group_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_menu_label') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_menu_label_text') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_page') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_scrollable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_border') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_tabs') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tab_detachable') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_tab_label') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_tab_label_packing') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_tab_label_text') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_tab_pos') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tab_reorderable') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('show_border=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_border?')

    klass.define_instance_method('show_tabs=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_tabs?')

    klass.define_instance_method('tab_hborder')

    klass.define_instance_method('tab_pos')

    klass.define_instance_method('tab_pos=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tab_vborder')
  end

  defs.define_constant('Gtk::Notebook::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Notebook::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Notebook::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Notebook::TAB_FIRST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Notebook::TAB_LAST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Notebook::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::NumerableIcon') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('background_icon')

    klass.define_instance_method('background_icon=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_icon_name')

    klass.define_instance_method('background_icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('count')

    klass.define_instance_method('count=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('label')

    klass.define_instance_method('label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_icon') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_icon_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_count') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_style_context') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('style_context')

    klass.define_instance_method('style_context=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::NumerableIcon::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Orientable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('orientation')

    klass.define_instance_method('orientation=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_orientation') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Orientation') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Orientation::HORIZONTAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Orientation::VERTICAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Overlay') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))

    klass.define_instance_method('add_overlay') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::Overlay::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Overlay::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Overlay::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Overlay::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PRIORITY_RESIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PackType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PackType::END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PackType::START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PageSetup') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('dup')

    klass.define_instance_method('get_bottom_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_left_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_page_height') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_page_width') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_paper_height') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_paper_width') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_right_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_top_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('orientation')

    klass.define_instance_method('orientation=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('paper_size')

    klass.define_instance_method('paper_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('paper_size_and_default_margins=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_bottom_margin') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_left_margin') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_orientation') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_paper_size') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_paper_size_and_default_margins') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_right_margin') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_top_margin') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end

  defs.define_constant('Gtk::PageSetup::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PageSetupUnixDialog') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::Paned') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))

    klass.define_instance_method('accept_position')

    klass.define_instance_method('add1') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add2') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('cancel_position')

    klass.define_instance_method('child1')

    klass.define_instance_method('child1_resize?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('child1_shrink?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('child2')

    klass.define_instance_method('child2_resize?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('child2_shrink?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('cycle_child_focus') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('cycle_handle_focus') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('handle_window')

    klass.define_instance_method('max_position')

    klass.define_instance_method('min_position')

    klass.define_instance_method('move_handle') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('pack1') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('pack2') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('position')

    klass.define_instance_method('position=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('position_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('position_set?')

    klass.define_instance_method('set_position') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_position_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('toggle_handle_focus')
  end

  defs.define_constant('Gtk::Paned::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Paned::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Paned::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Paned::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_method('default')

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('custom?')

    klass.define_instance_method('display_name')

    klass.define_instance_method('get_default_bottom_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_default_left_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_default_right_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_default_top_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_height') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_width') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('ppd_name')

    klass.define_instance_method('set_size') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end
  end

  defs.define_constant('Gtk::PaperSize::A3') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::A4') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::A5') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::B5') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::EXECUTIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::LEGAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::LETTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::Unit') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::Unit::INCH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::Unit::MM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::Unit::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PaperSize::Unit::POINTS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathPriorityType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathPriorityType::APPLICATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathPriorityType::GTK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathPriorityType::HIGHEST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathPriorityType::LOWEST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathPriorityType::RC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathPriorityType::THEME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathType::CLASS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathType::WIDGET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PathType::WIDGET_CLASS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PolicyType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PolicyType::ALWAYS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PolicyType::AUTOMATIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PolicyType::NEVER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PositionType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PositionType::BOTTOM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PositionType::LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PositionType::RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PositionType::TOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintContext') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('cairo_context')

    klass.define_instance_method('create_pango_context')

    klass.define_instance_method('create_pango_layout')

    klass.define_instance_method('dpi_x')

    klass.define_instance_method('dpi_y')

    klass.define_instance_method('height')

    klass.define_instance_method('page_setup')

    klass.define_instance_method('pango_fontmap')

    klass.define_instance_method('set_cairo_context') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('width')
  end

  defs.define_constant('Gtk::PrintContext::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::GENERAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::General') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::PrintError', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::General::GENERAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::General::INTERNAL_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::General::INVALID_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::General::InternalError') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::PrintError', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::General::InvalidFile') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::PrintError', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::General::NOMEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::General::Nomem') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::PrintError', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::INTERNAL_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::INVALID_FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::InternalError') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::PrintError', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::InvalidFile') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::PrintError', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::NOMEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintError::Nomem') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::PrintError', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::PrintOperationPreview', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_method('run_page_setup_dialog') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('allow_async=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('allow_async?')

    klass.define_instance_method('cancel')

    klass.define_instance_method('current_page')

    klass.define_instance_method('current_page=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('custom_tab_label')

    klass.define_instance_method('custom_tab_label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('default_page_setup')

    klass.define_instance_method('default_page_setup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('embed_page_setup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('embed_page_setup?')

    klass.define_instance_method('error')

    klass.define_instance_method('export_filename')

    klass.define_instance_method('export_filename=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('finished?')

    klass.define_instance_method('has_selection=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_selection?')

    klass.define_instance_method('job_name')

    klass.define_instance_method('job_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('n_pages')

    klass.define_instance_method('n_pages=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('n_pages_to_print')

    klass.define_instance_method('print_settings')

    klass.define_instance_method('print_settings=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('run') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_allow_async') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_current_page') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_custom_tab_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_default_page_setup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_embed_page_setup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_export_filename') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_selection') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_job_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_n_pages') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_print_settings') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_progress') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_support_selection') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_track_print_status') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_unit') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_full_page') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_progress=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_progress?')

    klass.define_instance_method('status')

    klass.define_instance_method('status_string')

    klass.define_instance_method('support_selection=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('support_selection?')

    klass.define_instance_method('track_print_status=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('track_print_status?')

    klass.define_instance_method('unit')

    klass.define_instance_method('unit=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_full_page=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_full_page?')
  end

  defs.define_constant('Gtk::PrintOperation::Action') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Action::EXPORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Action::PREVIEW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Action::PRINT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Action::PRINT_DIALOG') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Result') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Result::APPLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Result::CANCEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Result::ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Result::IN_PROGRESS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Status') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Status::FINISHED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Status::FINISHED_ABORTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Status::GENERATING_DATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Status::INITIAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Status::PENDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Status::PENDING_ISSUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Status::PREPARING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Status::PRINTING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperation::Status::SENDING_DATA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintOperationPreview') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('end_preview')

    klass.define_instance_method('render_page') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('selected?') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::PrintSettings') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Enumerable', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('collate=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('collate?')

    klass.define_instance_method('default_source')

    klass.define_instance_method('default_source=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('dither')

    klass.define_instance_method('dither=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('dup')

    klass.define_instance_method('duplex')

    klass.define_instance_method('duplex=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('finishings')

    klass.define_instance_method('finishings=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('get') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('get_bool') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_double') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('get_int') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('get_length') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('has_key?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('media_type')

    klass.define_instance_method('media_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('n_copies')

    klass.define_instance_method('n_copies=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('number_up')

    klass.define_instance_method('number_up=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('orientation')

    klass.define_instance_method('orientation=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('output_bin')

    klass.define_instance_method('output_bin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('page_ranges')

    klass.define_instance_method('page_ranges=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('page_set')

    klass.define_instance_method('page_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('paper_height') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('paper_size')

    klass.define_instance_method('paper_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('paper_width') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('print_pages')

    klass.define_instance_method('print_pages=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('printer')

    klass.define_instance_method('printer=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('quality')

    klass.define_instance_method('quality=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('resolution')

    klass.define_instance_method('resolution=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('reverse=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('reverse?')

    klass.define_instance_method('scale')

    klass.define_instance_method('scale=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_collate') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_default_source') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_dither') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_duplex') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_finishings') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_media_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_n_copies') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_number_up') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_orientation') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_output_bin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_page_ranges') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_page_set') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_paper_height') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_paper_size') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_paper_width') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_print_pages') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_printer') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_quality') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_resolution') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_reverse') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_scale') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_use_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('to_file') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('to_key_file') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('unset') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('use_color=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_color?')
  end

  defs.define_constant('Gtk::PrintSettings::COLLATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::DEFAULT_SOURCE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::DITHER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::DUPLEX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::FINISHINGS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::MEDIA_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::NUMBER_UP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::N_COPIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::ORIENTATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::OUTPUT_BIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::OUTPUT_FILE_FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::OUTPUT_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PAGE_RANGES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PAGE_SET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PAPER_FORMAT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PAPER_HEIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PAPER_WIDTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PRINTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PRINT_PAGES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PageOrientation') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PageOrientation::LANDSCAPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PageOrientation::PORTRAIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PageOrientation::REVERSE_LANDSCAPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PageOrientation::REVERSE_PORTRAIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PageSet') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PageSet::ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PageSet::EVEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PageSet::ODD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintDuplex') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintDuplex::HORIZONTAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintDuplex::SIMPLEX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintDuplex::VERTICAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintPages') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintPages::ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintPages::CURRENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintPages::RANGES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintPages::SELECTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintQuality') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintQuality::DRAFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintQuality::HIGH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintQuality::LOW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::PrintQuality::NORMAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::QUALITY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::RESOLUTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::REVERSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::SCALE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::USE_COLOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::WIN32_DRIVER_EXTRA') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintSettings::WIN32_DRIVER_VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::PrintUnixDialog') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::Printer') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('printers') do |method|
      method.define_optional_argument('wait')
    end
  end

  defs.define_constant('Gtk::ProgressBar') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))

    klass.define_instance_method('activity_mode=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('activity_mode?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('ellipsize')

    klass.define_instance_method('ellipsize=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('fraction')

    klass.define_instance_method('fraction=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inverted=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inverted?')

    klass.define_instance_method('pulse')

    klass.define_instance_method('pulse_step')

    klass.define_instance_method('pulse_step=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_activity_mode') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_ellipsize') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_fraction') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_inverted') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pulse_step') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_text_xalign') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_text_yalign') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('show_text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_text?')

    klass.define_instance_method('text')

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text_xalign') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('text_xalign=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('text_yalign') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('text_yalign=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end
  end

  defs.define_constant('Gtk::ProgressBar::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ProgressBar::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ProgressBar::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ProgressBar::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioAction') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ToggleAction', RubyLint.registry))

    klass.define_instance_method('current_value')

    klass.define_instance_method('current_value=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('group')

    klass.define_instance_method('group=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('set_current_value') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_group') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_value') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('value')

    klass.define_instance_method('value=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::RadioAction::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::CheckButton', RubyLint.registry))

    klass.define_instance_method('group')

    klass.define_instance_method('group=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_group') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::RadioButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioMenuItem') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::CheckMenuItem', RubyLint.registry))

    klass.define_instance_method('group')

    klass.define_instance_method('group=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_group') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::RadioMenuItem::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioMenuItem::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioMenuItem::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioMenuItem::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioToolButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ToggleToolButton', RubyLint.registry))

    klass.define_instance_method('group')

    klass.define_instance_method('group=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_group') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::RadioToolButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioToolButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioToolButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RadioToolButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Range') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))

    klass.define_instance_method('adjustment')

    klass.define_instance_method('adjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('fill_level')

    klass.define_instance_method('fill_level=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inverted=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inverted?')

    klass.define_instance_method('lower_stepper_sensitivity')

    klass.define_instance_method('lower_stepper_sensitivity=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('move_slider') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('restrict_to_fill_level=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('restrict_to_fill_level?')

    klass.define_instance_method('round_digits')

    klass.define_instance_method('round_digits=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_adjustment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_fill_level') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_increments') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_inverted') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_lower_stepper_sensitivity') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_range') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_restrict_to_fill_level') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_round_digits') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_fill_level') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_update_policy') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_upper_stepper_sensitivity') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_value') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('show_fill_level=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_fill_level?')

    klass.define_instance_method('update_policy') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('update_policy=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('upper_stepper_sensitivity')

    klass.define_instance_method('upper_stepper_sensitivity=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('value')

    klass.define_instance_method('value=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Range::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Range::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Range::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Range::SensitivityType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Range::SensitivityType::AUTO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Range::SensitivityType::OFF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Range::SensitivityType::ON') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Range::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentAction') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Action', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::RecentChooser', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('set_show_numbers') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_numbers=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_numbers?')
  end

  defs.define_constant('Gtk::RecentAction::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentAction::SortType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooser') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('add_filter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('current_item')

    klass.define_instance_method('current_uri')

    klass.define_instance_method('current_uri=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('filter')

    klass.define_instance_method('filter=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('filters')

    klass.define_instance_method('items')

    klass.define_instance_method('limit')

    klass.define_instance_method('limit=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('local_only=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('local_only?')

    klass.define_instance_method('remove_filter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('select_all')

    klass.define_instance_method('select_multiple=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('select_multiple?')

    klass.define_instance_method('select_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_current_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_filter') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_limit') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_local_only') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_select_multiple') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_icons') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_not_found') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_numbers') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_show_private') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_tips') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_sort_func')

    klass.define_instance_method('set_sort_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_icons=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_icons?')

    klass.define_instance_method('show_not_found=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_not_found?')

    klass.define_instance_method('show_numbers') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('show_numbers=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('show_private=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_private?')

    klass.define_instance_method('show_tips=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_tips?')

    klass.define_instance_method('sort_type')

    klass.define_instance_method('sort_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('unselect_all')

    klass.define_instance_method('unselect_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('uris')
  end

  defs.define_constant('Gtk::RecentChooserDialog') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Dialog', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::RecentChooser', RubyLint.registry))

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::RecentChooserDialog::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserDialog::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('destroy_with_parent?')

    klass.define_instance_method('modal?')
  end

  defs.define_constant('Gtk::RecentChooserDialog::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserDialog::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserDialog::Position') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserDialog::SortType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserDialog::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserDialog::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserError::INVALID_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserError::InvalidUri') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentChooserError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserError::NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserError::NotFound') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentChooserError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserError::NotFound::INVALID_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserError::NotFound::InvalidUri') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentChooserError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserError::NotFound::NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserMenu') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Menu', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Activatable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::RecentChooser', RubyLint.registry))

    klass.define_instance_method('set_show_numbers') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_numbers=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_numbers?')
  end

  defs.define_constant('Gtk::RecentChooserMenu::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserMenu::DirectionType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserMenu::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserMenu::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserMenu::SortType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserMenu::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserWidget') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Box', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::RecentChooser', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserWidget::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserWidget::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserWidget::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserWidget::SortType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentChooserWidget::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentData') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('app_exec')

    klass.define_instance_method('app_exec=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('app_name')

    klass.define_instance_method('app_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('description')

    klass.define_instance_method('description=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('display_name')

    klass.define_instance_method('display_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('groups')

    klass.define_instance_method('groups=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mime_type')

    klass.define_instance_method('mime_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('private=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('private?')

    klass.define_instance_method('set_app_exec') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_app_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_description') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_display_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_groups') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_mime_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_private') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::RecentFilter') do |klass|
    klass.inherits(defs.constant_proxy('GLib::InitiallyUnowned', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('add_age') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_application') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_custom') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_group') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_mime_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_pattern') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_pixbuf_formats')

    klass.define_instance_method('filter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('needed')

    klass.define_instance_method('set_name') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::RecentFilter::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('age?')

    klass.define_instance_method('application?')

    klass.define_instance_method('display_name?')

    klass.define_instance_method('group?')

    klass.define_instance_method('mime_type?')

    klass.define_instance_method('uri?')
  end

  defs.define_constant('Gtk::RecentFilter::Flags::AGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentFilter::Flags::APPLICATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentFilter::Flags::DISPLAY_NAME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentFilter::Flags::GROUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentFilter::Flags::MIME_TYPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentFilter::Flags::URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentFilter::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentFilterInfo') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('age')

    klass.define_instance_method('age=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('applications')

    klass.define_instance_method('applications=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('contains')

    klass.define_instance_method('contains=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('display_name')

    klass.define_instance_method('display_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('groups')

    klass.define_instance_method('groups=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mime_type')

    klass.define_instance_method('mime_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_age') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_applications') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_contains') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_display_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_groups') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_mime_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_uri') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('uri')

    klass.define_instance_method('uri=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::RecentInfo') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('added')

    klass.define_instance_method('age')

    klass.define_instance_method('application_info') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('applications')

    klass.define_instance_method('description')

    klass.define_instance_method('display_name')

    klass.define_instance_method('exist?')

    klass.define_instance_method('get_icon') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('groups')

    klass.define_instance_method('has_application?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_group?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('last_application')

    klass.define_instance_method('local?')

    klass.define_instance_method('mime_type')

    klass.define_instance_method('modified')

    klass.define_instance_method('private_hint?')

    klass.define_instance_method('short_name')

    klass.define_instance_method('uri')

    klass.define_instance_method('uri_display')

    klass.define_instance_method('visited')
  end

  defs.define_constant('Gtk::RecentManager') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_method('default')

    klass.define_method('get_for_screen') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('add_item') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('filename')

    klass.define_instance_method('has_item?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('items')

    klass.define_instance_method('lookup_item') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('move_item') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('purge_items')

    klass.define_instance_method('remove_item') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('screen=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_screen') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('size')
  end

  defs.define_constant('Gtk::RecentManager::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError') do |klass|
    klass.inherits(defs.constant_proxy('RuntimeError', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::ErrorInfo', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::INVALID_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::INVALID_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::InvalidEncoding') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::InvalidUri') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NOT_REGISTERED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::INVALID_ENCODING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::INVALID_URI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::InvalidEncoding') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::InvalidUri') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::NOT_FOUND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::NOT_REGISTERED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::NotRegistered') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::READ') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::Read') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::Unknown') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::WRITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotFound::Write') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::NotRegistered') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::READ') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::Read') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::UNKNOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::Unknown') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::WRITE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::RecentManagerError::Write') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::RecentManagerError', RubyLint.registry))

  end

  defs.define_constant('Gtk::ReliefStyle') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ReliefStyle::HALF') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ReliefStyle::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ReliefStyle::NORMAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResizeMode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResizeMode::IMMEDIATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResizeMode::PARENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResizeMode::QUEUE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::ACCEPT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::APPLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::CANCEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::CLOSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::DELETE_EVENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::HELP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::NO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::REJECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ResponseType::YES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))

    klass.define_instance_method('child_revealed?')

    klass.define_instance_method('reveal_child=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('reveal_child?')

    klass.define_instance_method('set_reveal_child') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_transition_duration') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_transition_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('transition_duration')

    klass.define_instance_method('transition_duration=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('transition_type')

    klass.define_instance_method('transition_type=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Revealer::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer::TransitionType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer::TransitionType::CROSSFADE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer::TransitionType::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer::TransitionType::SLIDE_DOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer::TransitionType::SLIDE_LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer::TransitionType::SLIDE_RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Revealer::TransitionType::SLIDE_UP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scale') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Range', RubyLint.registry))

    klass.define_instance_method('add_mark') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('clear_marks')

    klass.define_instance_method('digits')

    klass.define_instance_method('digits=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('draw_value=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('draw_value?')

    klass.define_instance_method('has_origin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_origin?')

    klass.define_instance_method('layout')

    klass.define_instance_method('layout_offsets')

    klass.define_instance_method('set_digits') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_draw_value') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_origin') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_value_pos') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('value_pos')

    klass.define_instance_method('value_pos=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Scale::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scale::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scale::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scale::SensitivityType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scale::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScaleButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Button', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))

    klass.define_instance_method('adjustment')

    klass.define_instance_method('adjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icons')

    klass.define_instance_method('icons=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('minus_button')

    klass.define_instance_method('plus_button')

    klass.define_instance_method('popdown')

    klass.define_instance_method('popup')

    klass.define_instance_method('set_adjustment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icons') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_value') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('value')

    klass.define_instance_method('value=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::ScaleButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScaleButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScaleButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScaleButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollStep') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollStep::ENDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollStep::HORIZONTAL_ENDS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollStep::HORIZONTAL_PAGES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollStep::HORIZONTAL_STEPS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollStep::PAGES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollStep::STEPS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::JUMP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::PAGE_BACKWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::PAGE_DOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::PAGE_FORWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::PAGE_LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::PAGE_RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::PAGE_UP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::START') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::STEP_BACKWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::STEP_DOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::STEP_FORWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::STEP_LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::STEP_RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrollType::STEP_UP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scrollable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('hadjustment')

    klass.define_instance_method('hadjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hscroll_policy')

    klass.define_instance_method('hscroll_policy=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_hadjustment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_hscroll_policy') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_vadjustment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_vscroll_policy') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('vadjustment')

    klass.define_instance_method('vadjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('vscroll_policy')

    klass.define_instance_method('vscroll_policy=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Scrollbar') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Range', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scrollbar::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scrollbar::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scrollbar::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scrollbar::SensitivityType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Scrollbar::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrolledWindow') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))

    klass.define_instance_method('add_with_viewport') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('hadjustment')

    klass.define_instance_method('hadjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hscrollbar')

    klass.define_instance_method('hscrollbar_policy')

    klass.define_instance_method('hscrollbar_policy=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('kinetic_scrolling=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('kinetic_scrolling?')

    klass.define_instance_method('min_content_height')

    klass.define_instance_method('min_content_height=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('min_content_width')

    klass.define_instance_method('min_content_width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('move_focus_out') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('placement')

    klass.define_instance_method('placement=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('policy')

    klass.define_instance_method('scroll_child') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
    end

    klass.define_instance_method('set_hadjustment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_hscrollbar_policy') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_kinetic_scrolling') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_min_content_height') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_min_content_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_placement') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_policy') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_shadow_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_vadjustment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_vscrollbar_policy') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_window_placement') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_window_placement_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('shadow_type')

    klass.define_instance_method('shadow_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('unset_placement')

    klass.define_instance_method('vadjustment')

    klass.define_instance_method('vadjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('vscrollbar')

    klass.define_instance_method('vscrollbar_policy')

    klass.define_instance_method('vscrollbar_policy=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('window_placement')

    klass.define_instance_method('window_placement=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('window_placement_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('window_placement_set?')
  end

  defs.define_constant('Gtk::ScrolledWindow::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrolledWindow::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrolledWindow::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ScrolledWindow::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SearchBar') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))

    klass.define_instance_method('connect_entry') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('handle_event?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('search_mode_enabled=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('search_mode_enabled?')

    klass.define_instance_method('set_search_mode_enabled') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_close_button') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_close_button=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_close_button?')
  end

  defs.define_constant('Gtk::SearchBar::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SearchBar::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SearchBar::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SearchBar::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SearchEntry') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Entry', RubyLint.registry))

  end

  defs.define_constant('Gtk::SearchEntry::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SearchEntry::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SearchEntry::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SearchEntry::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Selection') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_target') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_method('add_targets') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('clear_targets') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('convert') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_method('include_image?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('include_rich_text?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('include_text?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('include_uri?') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('owner_set') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_method('remove_all') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::SelectionData') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('data')

    klass.define_instance_method('data_type')

    klass.define_instance_method('display')

    klass.define_instance_method('format')

    klass.define_instance_method('pixbuf')

    klass.define_instance_method('pixbuf=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('selection')

    klass.define_instance_method('set') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_pixbuf') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_uris') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('target')

    klass.define_instance_method('targets')

    klass.define_instance_method('targets_include_image') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('targets_include_rich_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('targets_include_text')

    klass.define_instance_method('targets_include_uri')

    klass.define_instance_method('text')

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('type') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('uris')

    klass.define_instance_method('uris=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::SelectionMode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SelectionMode::BROWSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SelectionMode::MULTIPLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SelectionMode::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SelectionMode::SINGLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Separator') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))

  end

  defs.define_constant('Gtk::Separator::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Separator::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Separator::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Separator::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SeparatorMenuItem') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::MenuItem', RubyLint.registry))

  end

  defs.define_constant('Gtk::SeparatorMenuItem::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SeparatorMenuItem::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SeparatorMenuItem::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SeparatorMenuItem::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SeparatorToolItem') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ToolItem', RubyLint.registry))

    klass.define_instance_method('draw=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('draw?')

    klass.define_instance_method('set_draw') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::SeparatorToolItem::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SeparatorToolItem::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SeparatorToolItem::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SeparatorToolItem::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Settings') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::StyleProvider', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_method('default')

    klass.define_method('get_for_screen') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('install_property') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('rc_property_parse_border') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('rc_property_parse_color') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('rc_property_parse_enum') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('rc_property_parse_flags') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('rc_property_parse_requisition') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('color_hash')

    klass.define_instance_method('gtk_alternative_button_order=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_alternative_button_order?')

    klass.define_instance_method('gtk_alternative_sort_arrows=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_alternative_sort_arrows?')

    klass.define_instance_method('gtk_application_prefer_dark_theme=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_application_prefer_dark_theme?')

    klass.define_instance_method('gtk_auto_mnemonics=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_auto_mnemonics?')

    klass.define_instance_method('gtk_button_images=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_button_images?')

    klass.define_instance_method('gtk_can_change_accels=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_can_change_accels?')

    klass.define_instance_method('gtk_color_palette')

    klass.define_instance_method('gtk_color_palette=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_color_scheme')

    klass.define_instance_method('gtk_color_scheme=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_cursor_blink=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_cursor_blink?')

    klass.define_instance_method('gtk_cursor_blink_time')

    klass.define_instance_method('gtk_cursor_blink_time=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_cursor_blink_timeout')

    klass.define_instance_method('gtk_cursor_blink_timeout=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_cursor_theme_name')

    klass.define_instance_method('gtk_cursor_theme_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_cursor_theme_size')

    klass.define_instance_method('gtk_cursor_theme_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_dnd_drag_threshold')

    klass.define_instance_method('gtk_dnd_drag_threshold=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_double_click_distance')

    klass.define_instance_method('gtk_double_click_distance=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_double_click_time')

    klass.define_instance_method('gtk_double_click_time=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_enable_accels=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_enable_accels?')

    klass.define_instance_method('gtk_enable_animations=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_enable_animations?')

    klass.define_instance_method('gtk_enable_event_sounds=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_enable_event_sounds?')

    klass.define_instance_method('gtk_enable_input_feedback_sounds=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_enable_input_feedback_sounds?')

    klass.define_instance_method('gtk_enable_mnemonics=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_enable_mnemonics?')

    klass.define_instance_method('gtk_enable_primary_paste=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_enable_primary_paste?')

    klass.define_instance_method('gtk_enable_tooltips=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_enable_tooltips?')

    klass.define_instance_method('gtk_entry_password_hint_timeout')

    klass.define_instance_method('gtk_entry_password_hint_timeout=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_entry_select_on_focus=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_entry_select_on_focus?')

    klass.define_instance_method('gtk_error_bell=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_error_bell?')

    klass.define_instance_method('gtk_fallback_icon_theme')

    klass.define_instance_method('gtk_fallback_icon_theme=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_file_chooser_backend')

    klass.define_instance_method('gtk_file_chooser_backend=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_font_name')

    klass.define_instance_method('gtk_font_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_fontconfig_timestamp')

    klass.define_instance_method('gtk_fontconfig_timestamp=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_icon_sizes')

    klass.define_instance_method('gtk_icon_sizes=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_icon_theme_name')

    klass.define_instance_method('gtk_icon_theme_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_im_module')

    klass.define_instance_method('gtk_im_module=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_im_preedit_style')

    klass.define_instance_method('gtk_im_preedit_style=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_im_status_style')

    klass.define_instance_method('gtk_im_status_style=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_key_theme_name')

    klass.define_instance_method('gtk_key_theme_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_keynav_cursor_only=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_keynav_cursor_only?')

    klass.define_instance_method('gtk_keynav_wrap_around=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_keynav_wrap_around?')

    klass.define_instance_method('gtk_label_select_on_focus=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_label_select_on_focus?')

    klass.define_instance_method('gtk_menu_bar_accel')

    klass.define_instance_method('gtk_menu_bar_accel=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_menu_bar_popup_delay')

    klass.define_instance_method('gtk_menu_bar_popup_delay=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_menu_images=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_menu_images?')

    klass.define_instance_method('gtk_menu_popdown_delay')

    klass.define_instance_method('gtk_menu_popdown_delay=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_menu_popup_delay')

    klass.define_instance_method('gtk_menu_popup_delay=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_modules')

    klass.define_instance_method('gtk_modules=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_primary_button_warps_slider=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_primary_button_warps_slider?')

    klass.define_instance_method('gtk_print_backends')

    klass.define_instance_method('gtk_print_backends=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_print_preview_command')

    klass.define_instance_method('gtk_print_preview_command=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_recent_files_enabled=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_recent_files_enabled?')

    klass.define_instance_method('gtk_recent_files_limit')

    klass.define_instance_method('gtk_recent_files_limit=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_recent_files_max_age')

    klass.define_instance_method('gtk_recent_files_max_age=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_scrolled_window_placement')

    klass.define_instance_method('gtk_scrolled_window_placement=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_shell_shows_app_menu=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_shell_shows_app_menu?')

    klass.define_instance_method('gtk_shell_shows_desktop=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_shell_shows_desktop?')

    klass.define_instance_method('gtk_shell_shows_menubar=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_shell_shows_menubar?')

    klass.define_instance_method('gtk_show_input_method_menu=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_show_input_method_menu?')

    klass.define_instance_method('gtk_show_unicode_menu=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_show_unicode_menu?')

    klass.define_instance_method('gtk_sound_theme_name')

    klass.define_instance_method('gtk_sound_theme_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_split_cursor=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_split_cursor?')

    klass.define_instance_method('gtk_theme_name')

    klass.define_instance_method('gtk_theme_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_timeout_expand')

    klass.define_instance_method('gtk_timeout_expand=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_timeout_initial')

    klass.define_instance_method('gtk_timeout_initial=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_timeout_repeat')

    klass.define_instance_method('gtk_timeout_repeat=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_toolbar_icon_size')

    klass.define_instance_method('gtk_toolbar_icon_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_toolbar_style')

    klass.define_instance_method('gtk_toolbar_style=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_tooltip_browse_mode_timeout')

    klass.define_instance_method('gtk_tooltip_browse_mode_timeout=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_tooltip_browse_timeout')

    klass.define_instance_method('gtk_tooltip_browse_timeout=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_tooltip_timeout')

    klass.define_instance_method('gtk_tooltip_timeout=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_touchscreen_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_touchscreen_mode?')

    klass.define_instance_method('gtk_visible_focus')

    klass.define_instance_method('gtk_visible_focus=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_xft_antialias')

    klass.define_instance_method('gtk_xft_antialias=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_xft_dpi')

    klass.define_instance_method('gtk_xft_dpi=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_xft_hinting')

    klass.define_instance_method('gtk_xft_hinting=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_xft_hintstyle')

    klass.define_instance_method('gtk_xft_hintstyle=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('gtk_xft_rgba')

    klass.define_instance_method('gtk_xft_rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_alternative_button_order') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_alternative_sort_arrows') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_application_prefer_dark_theme') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_auto_mnemonics') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_button_images') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_can_change_accels') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_color_palette') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_color_scheme') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_cursor_blink') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_cursor_blink_time') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_cursor_blink_timeout') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_cursor_theme_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_cursor_theme_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_dnd_drag_threshold') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_double_click_distance') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_double_click_time') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_enable_accels') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_enable_animations') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_enable_event_sounds') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_enable_input_feedback_sounds') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_enable_mnemonics') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_enable_primary_paste') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_enable_tooltips') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_entry_password_hint_timeout') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_entry_select_on_focus') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_error_bell') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_fallback_icon_theme') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_file_chooser_backend') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_font_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_fontconfig_timestamp') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_icon_sizes') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_icon_theme_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_im_module') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_im_preedit_style') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_im_status_style') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_key_theme_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_keynav_cursor_only') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_keynav_wrap_around') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_label_select_on_focus') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_menu_bar_accel') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_menu_bar_popup_delay') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_menu_images') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_menu_popdown_delay') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_menu_popup_delay') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_modules') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_primary_button_warps_slider') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_print_backends') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_print_preview_command') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_recent_files_enabled') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_recent_files_limit') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_recent_files_max_age') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_scrolled_window_placement') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_shell_shows_app_menu') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_shell_shows_desktop') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_shell_shows_menubar') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_show_input_method_menu') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_show_unicode_menu') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_sound_theme_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_split_cursor') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_theme_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_timeout_expand') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_timeout_initial') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_timeout_repeat') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_toolbar_icon_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_toolbar_style') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_tooltip_browse_mode_timeout') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_tooltip_browse_timeout') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_tooltip_timeout') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_touchscreen_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_visible_focus') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_xft_antialias') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_xft_dpi') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_xft_hinting') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_xft_hintstyle') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gtk_xft_rgba') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_property_value') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end
  end

  defs.define_constant('Gtk::Settings::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ShadowType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ShadowType::ETCHED_IN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ShadowType::ETCHED_OUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ShadowType::IN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ShadowType::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ShadowType::OUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SizeGroup') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('add_widget') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('ignore_hidden=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('ignore_hidden?')

    klass.define_instance_method('mode')

    klass.define_instance_method('mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('remove_widget') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_ignore_hidden') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('widgets')
  end

  defs.define_constant('Gtk::SizeGroup::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SizeGroup::Mode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SizeGroup::Mode::BOTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SizeGroup::Mode::HORIZONTAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SizeGroup::Mode::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SizeGroup::Mode::VERTICAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SortType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SortType::ASCENDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SortType::DESCENDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Entry', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))

    klass.define_instance_method('adjustment')

    klass.define_instance_method('adjustment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('change_value') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('climb_rate')

    klass.define_instance_method('climb_rate=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('configure') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('digits')

    klass.define_instance_method('digits=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('increments')

    klass.define_instance_method('numeric=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('numeric?')

    klass.define_instance_method('range')

    klass.define_instance_method('set_adjustment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_climb_rate') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_digits') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_increments') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_numeric') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_range') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_snap_to_ticks') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_update_policy') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_value') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_wrap') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('snap_to_ticks=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('snap_to_ticks?')

    klass.define_instance_method('spin') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('update')

    klass.define_instance_method('update_policy')

    klass.define_instance_method('update_policy=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('value')

    klass.define_instance_method('value=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('value_as_int')

    klass.define_instance_method('wrap=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap?')
  end

  defs.define_constant('Gtk::SpinButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::Type') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::Type::END') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::Type::HOME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::Type::PAGE_BACKWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::Type::PAGE_FORWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::Type::STEP_BACKWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::Type::STEP_FORWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::Type::USER_DEFINED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::UpdatePolicy') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::UpdatePolicy::ALWAYS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::SpinButton::UpdatePolicy::IF_VALID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Spinner') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))

    klass.define_instance_method('active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active?')

    klass.define_instance_method('set_active') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('start')

    klass.define_instance_method('stop')
  end

  defs.define_constant('Gtk::Spinner::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Spinner::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Spinner::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Spinner::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('homogeneous=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('homogeneous?')

    klass.define_instance_method('set_homogeneous') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_transition_duration') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_transition_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible_child') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_visible_child_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('transition_duration')

    klass.define_instance_method('transition_duration=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('transition_type')

    klass.define_instance_method('transition_type=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible_child')

    klass.define_instance_method('visible_child_name')

    klass.define_instance_method('visible_child_name=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Stack::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::TransitionType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::TransitionType::CROSSFADE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::TransitionType::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::TransitionType::SLIDE_DOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::TransitionType::SLIDE_LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::TransitionType::SLIDE_LEFT_RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::TransitionType::SLIDE_RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::TransitionType::SLIDE_UP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stack::TransitionType::SLIDE_UP_DOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateFlags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('active?')

    klass.define_instance_method('backdrop?')

    klass.define_instance_method('dir_ltr?')

    klass.define_instance_method('dir_rtl?')

    klass.define_instance_method('focused?')

    klass.define_instance_method('inconsistent?')

    klass.define_instance_method('insensitive?')

    klass.define_instance_method('normal?')

    klass.define_instance_method('prelight?')

    klass.define_instance_method('selected?')
  end

  defs.define_constant('Gtk::StateFlags::ACTIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateFlags::BACKDROP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateFlags::DIR_LTR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateFlags::DIR_RTL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateFlags::FOCUSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateFlags::INCONSISTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateFlags::INSENSITIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateFlags::NORMAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateFlags::PRELIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateFlags::SELECTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateType::ACTIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateType::FOCUSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateType::INCONSISTENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateType::INSENSITIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateType::NORMAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateType::PRELIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StateType::SELECTED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StatusIcon') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('activate')

    klass.define_instance_method('embedded?')

    klass.define_instance_method('file=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('geometry')

    klass.define_instance_method('gicon')

    klass.define_instance_method('gicon=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_tooltip=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_tooltip?')

    klass.define_instance_method('icon_name')

    klass.define_instance_method('icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('orientation')

    klass.define_instance_method('pixbuf')

    klass.define_instance_method('pixbuf=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('popup_menu') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
    end

    klass.define_instance_method('position_menu') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('screen')

    klass.define_instance_method('screen=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_file') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_gicon') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_tooltip') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixbuf') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_screen') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_title') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tooltip_markup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tooltip_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('stock')

    klass.define_instance_method('stock=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('storage_type')

    klass.define_instance_method('title')

    klass.define_instance_method('title=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tooltip_markup')

    klass.define_instance_method('tooltip_markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tooltip_text')

    klass.define_instance_method('tooltip_text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible?')
  end

  defs.define_constant('Gtk::StatusIcon::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Statusbar') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Box', RubyLint.registry))

    klass.define_instance_method('get_context_id') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('pop') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('push') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('remove') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end

  defs.define_constant('Gtk::Statusbar::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Statusbar::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Statusbar::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Statusbar::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('ids')

    klass.define_method('lookup') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('set_translate_func') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('translate_func=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Stock::ABOUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::ADD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::APPLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::BOLD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::CANCEL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::CAPS_LOCK_WARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::CDROM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::CLEAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::CLOSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::COLOR_PICKER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::CONNECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::CONVERT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::COPY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::CUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DELETE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DIALOG_AUTHENTICATION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DIALOG_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DIALOG_INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DIALOG_QUESTION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DIALOG_WARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DIRECTORY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DISCARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DISCONNECT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::DND_MULTIPLE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::EDIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::EXECUTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::FILE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::FIND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::FIND_AND_REPLACE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::FLOPPY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::FULLSCREEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::GOTO_BOTTOM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::GOTO_FIRST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::GOTO_LAST') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::GOTO_TOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::GO_BACK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::GO_DOWN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::GO_FORWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::GO_UP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::HARDDISK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::HELP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::HOME') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::INDENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::INDEX') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::INFO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::ITALIC') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::JUMP_TO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::JUSTIFY_CENTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::JUSTIFY_FILL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::JUSTIFY_LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::JUSTIFY_RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::LEAVE_FULLSCREEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::MEDIA_FORWARD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::MEDIA_NEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::MEDIA_PAUSE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::MEDIA_PLAY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::MEDIA_PREVIOUS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::MEDIA_RECORD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::MEDIA_REWIND') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::MEDIA_STOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::MISSING_IMAGE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::NETWORK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::NEW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::NO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::OK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::OPEN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::ORIENTATION_LANDSCAPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::ORIENTATION_PORTRAIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::ORIENTATION_REVERSE_LANDSCAPE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::ORIENTATION_REVERSE_PORTRAIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::PAGE_SETUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::PASTE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::PREFERENCES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::PRINT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::PRINT_ERROR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::PRINT_PAUSED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::PRINT_PREVIEW') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::PRINT_REPORT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::PRINT_WARNING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::PROPERTIES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::QUIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::REDO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::REFRESH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::REMOVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::REVERT_TO_SAVED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::SAVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::SAVE_AS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::SELECT_ALL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::SELECT_COLOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::SELECT_FONT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::SORT_ASCENDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::SORT_DESCENDING') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::SPELL_CHECK') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::STOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::STRIKETHROUGH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::UNDELETE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::UNDERLINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::UNDO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::UNINDENT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::YES') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::ZOOM_100') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::ZOOM_FIT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::ZOOM_IN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Stock::ZOOM_OUT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StyleContext') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('add_class') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_provider') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('add_region') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('background=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('classes')

    klass.define_instance_method('direction')

    klass.define_instance_method('direction=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('get_background_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_border') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_border_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_font') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_padding') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_property') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_style_property') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_class?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_region') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('invalidate')

    klass.define_instance_method('junction_sides')

    klass.define_instance_method('junction_sides=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('lookup_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('lookup_icon_set') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('paint_clock')

    klass.define_instance_method('paint_clock=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('parent')

    klass.define_instance_method('parent=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('path')

    klass.define_instance_method('path=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pop_animatable_region')

    klass.define_instance_method('push_animatable_region') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('regions')

    klass.define_instance_method('remove_class') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_provider') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_region') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('restore')

    klass.define_instance_method('save')

    klass.define_instance_method('screen')

    klass.define_instance_method('screen=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_direction') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_junction_sides') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_paint_clock') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_parent') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_screen') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_state') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('state')

    klass.define_instance_method('state=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('state_is_running') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::StyleContext::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StyleProperties') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::StyleProvider', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('clear')

    klass.define_instance_method('get_property') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('lookup_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('map_color') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('merge') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_property') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('unset_property') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end

  defs.define_constant('Gtk::StyleProperties::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::StyleProvider') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('get_icon_factory') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_style') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_style_property') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end
  end

  defs.define_constant('Gtk::Switch') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Widget', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Activatable', RubyLint.registry))

    klass.define_instance_method('activate')

    klass.define_instance_method('active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active?')

    klass.define_instance_method('set_active') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Switch::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Switch::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Switch::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Switch::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Table') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))

    klass.define_instance_method('attach') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('attach_defaults') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('column_spacings=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('default_column_spacing')

    klass.define_instance_method('default_row_spacing')

    klass.define_instance_method('get_column_spacing') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_row_spacing') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('homogeneous=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('homogeneous?')

    klass.define_instance_method('n_columns')

    klass.define_instance_method('n_columns=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('n_rows')

    klass.define_instance_method('n_rows=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('resize') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('row_spacings=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_column_spacing') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_column_spacings') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_homogeneous') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_n_columns') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_n_rows') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_row_spacing') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_row_spacings') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('size')
  end

  defs.define_constant('Gtk::Table::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Table::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Table::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Table::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TargetList') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('add_image_targets') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('add_rich_text_targets') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('add_table') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_text_targets') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_uri_targets') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('find') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::TearoffMenuItem') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::MenuItem', RubyLint.registry))

  end

  defs.define_constant('Gtk::TearoffMenuItem::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TearoffMenuItem::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TearoffMenuItem::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TearoffMenuItem::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextAppearance') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('bg_color')

    klass.define_instance_method('bg_color=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('draw_bg=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('draw_bg?')

    klass.define_instance_method('fg_color')

    klass.define_instance_method('fg_color=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inside_selection=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inside_selection?')

    klass.define_instance_method('rise')

    klass.define_instance_method('rise=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_bg_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_draw_bg') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_fg_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_inside_selection') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_rise') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_strikethrough') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_underline') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('strikethrough=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('strikethrough?')

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text?')

    klass.define_instance_method('underline')

    klass.define_instance_method('underline=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::TextAttributes') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('appearance')

    klass.define_instance_method('appearance=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('bg_full_height=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('bg_full_height?')

    klass.define_instance_method('copy_values') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('direction')

    klass.define_instance_method('direction=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editable?')

    klass.define_instance_method('font')

    klass.define_instance_method('font=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('font_scale')

    klass.define_instance_method('font_scale=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('indent')

    klass.define_instance_method('indent=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('invisible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('invisible?')

    klass.define_instance_method('justification')

    klass.define_instance_method('justification=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('language')

    klass.define_instance_method('language=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('left_margin')

    klass.define_instance_method('left_margin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_above_lines')

    klass.define_instance_method('pixels_above_lines=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_below_lines')

    klass.define_instance_method('pixels_below_lines=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_inside_wrap')

    klass.define_instance_method('pixels_inside_wrap=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('realized=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('realized?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('right_margin')

    klass.define_instance_method('right_margin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_appearance') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_bg_full_height') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_direction') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_editable') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_font') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_font_scale') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_indent') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_invisible') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_justification') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_language') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_left_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_pixels_above_lines') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_pixels_below_lines') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_pixels_inside_wrap') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_realized') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_right_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_tabs') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_wrap_mode') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('tabs')

    klass.define_instance_method('tabs=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap_mode')

    klass.define_instance_method('wrap_mode=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::TextBuffer') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('add_mark') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('add_selection_clipboard') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('apply_tag') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('backspace') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('begin_user_action')

    klass.define_instance_method('bounds')

    klass.define_instance_method('char_count')

    klass.define_instance_method('copy_clipboard') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('copy_target_list')

    klass.define_instance_method('create_child_anchor') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('create_mark') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('create_tag') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('cursor_position')

    klass.define_instance_method('cut_clipboard') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('delete') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('delete_interactive') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('delete_mark') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('delete_selection') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('deserialize') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('deserialize_can_create_tags?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('deserialize_formats')

    klass.define_instance_method('deserialize_set_can_create_tags') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('end_iter')

    klass.define_instance_method('end_user_action')

    klass.define_instance_method('get_iter_at') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_iter_at_child_anchor') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('get_iter_at_line') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('get_iter_at_line_index') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('get_iter_at_line_offset') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('get_iter_at_mark') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('get_iter_at_offset') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('get_mark') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_slice') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('get_text') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('has_selection?')

    klass.define_instance_method('insert') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('insert_at_cursor') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('insert_child_anchor') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('insert_interactive') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('insert_interactive_at_cursor') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('insert_pixbuf') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('insert_range') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('insert_range_interactive') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('insert_with_tags') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('line_count')

    klass.define_instance_method('modified=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('modified?')

    klass.define_instance_method('move_mark') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('paste_clipboard') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('paste_target_list')

    klass.define_instance_method('place_cursor') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('register_deserialize_format') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('register_deserialize_target') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('register_serialize_format') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('register_serialize_target') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_all_tags') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('remove_selection_clipboard') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_tag') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('select_range') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('selection_bound')

    klass.define_instance_method('selection_bounds')

    klass.define_instance_method('serialize') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('serialize_formats')

    klass.define_instance_method('set_modified') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('slice')

    klass.define_instance_method('start_iter')

    klass.define_instance_method('tag_table')

    klass.define_instance_method('text')

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('unregister_deserialize_format') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('unregister_serialize_format') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::TextBuffer::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextChildAnchor') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('deleted?')

    klass.define_instance_method('widgets')
  end

  defs.define_constant('Gtk::TextChildAnchor::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextIter') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Comparable', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('attributes')

    klass.define_instance_method('backward_char')

    klass.define_instance_method('backward_chars') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('backward_cursor_position')

    klass.define_instance_method('backward_cursor_positions') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('backward_find_char') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('backward_line')

    klass.define_instance_method('backward_lines') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('backward_search') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('backward_sentence_start')

    klass.define_instance_method('backward_sentence_starts') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('backward_to_tag_toggle') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('backward_visible_cursor_position')

    klass.define_instance_method('backward_visible_cursor_positions') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('backward_visible_line')

    klass.define_instance_method('backward_visible_lines') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('backward_visible_word_start')

    klass.define_instance_method('backward_visible_word_starts') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('backward_word_start')

    klass.define_instance_method('backward_word_starts') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('backword_visible_word_start') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('begins_tag?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('buffer')

    klass.define_instance_method('bytes_in_line')

    klass.define_instance_method('can_insert?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('char')

    klass.define_instance_method('chars_in_line')

    klass.define_instance_method('child_anchor')

    klass.define_instance_method('cursor_position?')

    klass.define_instance_method('editable?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('end?')

    klass.define_instance_method('ends_line?')

    klass.define_instance_method('ends_sentence?')

    klass.define_instance_method('ends_tag?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('ends_word?')

    klass.define_instance_method('forward_char')

    klass.define_instance_method('forward_chars') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('forward_cursor_position')

    klass.define_instance_method('forward_cursor_positions') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('forward_find_char') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('forward_line')

    klass.define_instance_method('forward_lines') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('forward_search') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('forward_sentence_end')

    klass.define_instance_method('forward_sentence_ends') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('forward_to_end')

    klass.define_instance_method('forward_to_line_end')

    klass.define_instance_method('forward_to_tag_toggle') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('forward_visible_cursor_position')

    klass.define_instance_method('forward_visible_cursor_positions') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('forward_visible_line')

    klass.define_instance_method('forward_visible_lines') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('forward_visible_word_end')

    klass.define_instance_method('forward_visible_word_ends') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('forward_word_end')

    klass.define_instance_method('forward_word_ends') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_slice') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_visible_slice') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_visible_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_tag?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('inside_sentence')

    klass.define_instance_method('inside_word?')

    klass.define_instance_method('language')

    klass.define_instance_method('line')

    klass.define_instance_method('line=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('line_index')

    klass.define_instance_method('line_index=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('line_offset')

    klass.define_instance_method('line_offset=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('marks')

    klass.define_instance_method('offset')

    klass.define_instance_method('offset=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixbuf')

    klass.define_instance_method('set_line') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_line_index') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_line_offset') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_offset') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_visible_line_index') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_visible_line_offset') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('start?')

    klass.define_instance_method('starts_line?')

    klass.define_instance_method('starts_sentence?')

    klass.define_instance_method('starts_word?')

    klass.define_instance_method('tags')

    klass.define_instance_method('toggled_tags') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('toggles_tag?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('visible_line_index')

    klass.define_instance_method('visible_line_index=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible_line_offset')

    klass.define_instance_method('visible_line_offset=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::TextIter::SearchFlags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('case_insensitive?')

    klass.define_instance_method('text_only?')

    klass.define_instance_method('visible_only?')
  end

  defs.define_constant('Gtk::TextIter::SearchFlags::CASE_INSENSITIVE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextIter::SearchFlags::TEXT_ONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextIter::SearchFlags::VISIBLE_ONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextMark') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('buffer')

    klass.define_instance_method('deleted?')

    klass.define_instance_method('left_gravity?')

    klass.define_instance_method('name')

    klass.define_instance_method('set_visible') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible?')
  end

  defs.define_constant('Gtk::TextMark::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextTag') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('accumulative_margin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('accumulative_margin?')

    klass.define_instance_method('background=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_full_height=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_full_height?')

    klass.define_instance_method('background_full_height_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_full_height_set?')

    klass.define_instance_method('background_gdk')

    klass.define_instance_method('background_gdk=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_rgba')

    klass.define_instance_method('background_rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('background_set?')

    klass.define_instance_method('direction')

    klass.define_instance_method('direction=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editable?')

    klass.define_instance_method('editable_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editable_set?')

    klass.define_instance_method('event') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('family')

    klass.define_instance_method('family=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('family_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('family_set?')

    klass.define_instance_method('font')

    klass.define_instance_method('font=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('font_desc')

    klass.define_instance_method('font_desc=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('foreground=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('foreground_gdk')

    klass.define_instance_method('foreground_gdk=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('foreground_rgba')

    klass.define_instance_method('foreground_rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('foreground_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('foreground_set?')

    klass.define_instance_method('indent')

    klass.define_instance_method('indent=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('indent_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('indent_set?')

    klass.define_instance_method('invisible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('invisible?')

    klass.define_instance_method('invisible_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('invisible_set?')

    klass.define_instance_method('justification')

    klass.define_instance_method('justification=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('justification_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('justification_set?')

    klass.define_instance_method('language')

    klass.define_instance_method('language=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('language_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('language_set?')

    klass.define_instance_method('left_margin')

    klass.define_instance_method('left_margin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('left_margin_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('left_margin_set?')

    klass.define_instance_method('name')

    klass.define_instance_method('paragraph_background=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('paragraph_background_gdk')

    klass.define_instance_method('paragraph_background_gdk=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('paragraph_background_rgba')

    klass.define_instance_method('paragraph_background_rgba=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('paragraph_background_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('paragraph_background_set?')

    klass.define_instance_method('pixels_above_lines')

    klass.define_instance_method('pixels_above_lines=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_above_lines_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_above_lines_set?')

    klass.define_instance_method('pixels_below_lines')

    klass.define_instance_method('pixels_below_lines=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_below_lines_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_below_lines_set?')

    klass.define_instance_method('pixels_inside_wrap')

    klass.define_instance_method('pixels_inside_wrap=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_inside_wrap_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_inside_wrap_set?')

    klass.define_instance_method('priority')

    klass.define_instance_method('priority=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('right_margin')

    klass.define_instance_method('right_margin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('right_margin_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('right_margin_set?')

    klass.define_instance_method('rise')

    klass.define_instance_method('rise=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('rise_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('rise_set?')

    klass.define_instance_method('scale')

    klass.define_instance_method('scale=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('scale_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('scale_set?')

    klass.define_instance_method('set_accumulative_margin') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_full_height') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_full_height_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_gdk') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_rgba') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_background_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_direction') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_editable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_editable_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_family') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_family_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_font') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_font_desc') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_foreground') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_foreground_gdk') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_foreground_rgba') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_foreground_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_indent') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_indent_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_invisible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_invisible_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_justification') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_justification_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_language') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_language_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_left_margin') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_left_margin_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_paragraph_background') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_paragraph_background_gdk') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_paragraph_background_rgba') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_paragraph_background_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixels_above_lines') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixels_above_lines_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixels_below_lines') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixels_below_lines_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixels_inside_wrap') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixels_inside_wrap_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_priority') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_right_margin') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_right_margin_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_rise') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_rise_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_scale') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_scale_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_size_points') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_size_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stretch') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stretch_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_strikethrough') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_strikethrough_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_style') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_style_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tabs') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tabs_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_underline') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_underline_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_variant') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_variant_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_weight') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_weight_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_wrap_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_wrap_mode_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size_points')

    klass.define_instance_method('size_points=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('size_set?')

    klass.define_instance_method('stretch')

    klass.define_instance_method('stretch=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stretch_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stretch_set?')

    klass.define_instance_method('strikethrough=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('strikethrough?')

    klass.define_instance_method('strikethrough_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('strikethrough_set?')

    klass.define_instance_method('style')

    klass.define_instance_method('style=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('style_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('style_set?')

    klass.define_instance_method('tabs')

    klass.define_instance_method('tabs=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tabs_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tabs_set?')

    klass.define_instance_method('underline')

    klass.define_instance_method('underline=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('underline_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('underline_set?')

    klass.define_instance_method('variant')

    klass.define_instance_method('variant=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('variant_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('variant_set?')

    klass.define_instance_method('weight')

    klass.define_instance_method('weight=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('weight_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('weight_set?')

    klass.define_instance_method('wrap_mode')

    klass.define_instance_method('wrap_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap_mode_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('wrap_mode_set?')
  end

  defs.define_constant('Gtk::TextTag::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextTag::WrapMode') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextTag::WrapMode::CHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextTag::WrapMode::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextTag::WrapMode::WORD') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextTag::WrapMode::WORD_CHAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextTagTable') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('each')

    klass.define_instance_method('lookup') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('size')
  end

  defs.define_constant('Gtk::TextTagTable::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Scrollable', RubyLint.registry))

    klass.define_instance_method('accepts_tab=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('accepts_tab?')

    klass.define_instance_method('add_child_at_anchor') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('add_child_in_window') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('backspace')

    klass.define_instance_method('backward_display_line') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('backward_display_line_start') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('buffer')

    klass.define_instance_method('buffer=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('buffer_to_window_coords') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('copy_clipboard')

    klass.define_instance_method('cursor_visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cursor_visible?')

    klass.define_instance_method('cut_clipboard')

    klass.define_instance_method('default_attributes')

    klass.define_instance_method('delete_from_cursor') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
    end

    klass.define_instance_method('editable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('editable?')

    klass.define_instance_method('forward_display_line') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('forward_display_line_end') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_border_window_size') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_cursor_locations') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('get_iter_at_location') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_iter_at_position') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_iter_location') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_line_at_y') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_line_yrange') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_window') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_window_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('im_context_filter_keypress') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('im_module')

    klass.define_instance_method('im_module=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('indent')

    klass.define_instance_method('indent=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('input_hints')

    klass.define_instance_method('input_hints=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('input_purpose')

    klass.define_instance_method('input_purpose=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('insert_at_cursor') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('justification')

    klass.define_instance_method('justification=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('left_margin')

    klass.define_instance_method('left_margin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('move_child') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('move_cursor') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
      method.define_argument('x2')
    end

    klass.define_instance_method('move_mark_onscreen') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('move_viewport') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
    end

    klass.define_instance_method('move_visually') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('overwrite=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('overwrite?')

    klass.define_instance_method('paste_clipboard')

    klass.define_instance_method('pixels_above_lines')

    klass.define_instance_method('pixels_above_lines=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_below_lines')

    klass.define_instance_method('pixels_below_lines=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pixels_inside_wrap')

    klass.define_instance_method('pixels_inside_wrap=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('place_cursor_onscreen')

    klass.define_instance_method('populate_all=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('populate_all?')

    klass.define_instance_method('preedit_changed') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('reset_im_context')

    klass.define_instance_method('right_margin')

    klass.define_instance_method('right_margin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('scroll_mark_onscreen') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('scroll_to_iter') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('scroll_to_mark') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('select_all') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('set_accepts_tab') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_anchor')

    klass.define_instance_method('set_border_window_size') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_buffer') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_cursor_visible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_editable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_im_module') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_indent') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_input_hints') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_input_purpose') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_justification') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_left_margin') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_overwrite') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixels_above_lines') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixels_below_lines') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_pixels_inside_wrap') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_populate_all') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_right_margin') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tabs') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_wrap_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('starts_display_line') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('tabs')

    klass.define_instance_method('tabs=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('toggle_cursor_visible')

    klass.define_instance_method('toggle_overwrite')

    klass.define_instance_method('visible_rect')

    klass.define_instance_method('window_to_buffer_coords') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('wrap_mode')

    klass.define_instance_method('wrap_mode=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::TextView::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::PRIORITY_VALIDATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::Policy') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::WindowType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::WindowType::BOTTOM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::WindowType::LEFT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::WindowType::PRIVATE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::WindowType::RIGHT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::WindowType::TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::WindowType::TOP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TextView::WindowType::WIDGET') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ThemingEngine') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_method('load') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('direction')

    klass.define_instance_method('get_background_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_border') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_border_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_font') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_margin') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_padding') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_property') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_style_property') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_class?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_region') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('junction_sides')

    klass.define_instance_method('lookup_color') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('path')

    klass.define_instance_method('screen')

    klass.define_instance_method('state')

    klass.define_instance_method('state_is_running') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::ThemingEngine::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToggleAction') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Action', RubyLint.registry))

    klass.define_instance_method('active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active?')

    klass.define_instance_method('draw_as_radio=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('draw_as_radio?')

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('set_active') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_draw_as_radio') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('toggled')
  end

  defs.define_constant('Gtk::ToggleAction::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToggleButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Button', RubyLint.registry))

    klass.define_instance_method('active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active?')

    klass.define_instance_method('draw_indicator=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('draw_indicator?')

    klass.define_instance_method('inconsistent=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('inconsistent?')

    klass.define_instance_method('mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mode?')

    klass.define_instance_method('set_active') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_draw_indicator') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_inconsistent') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_mode') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('toggled')
  end

  defs.define_constant('Gtk::ToggleButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToggleButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToggleButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToggleButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToggleToolButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ToolButton', RubyLint.registry))

    klass.define_instance_method('active=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('active?')

    klass.define_instance_method('set_active') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::ToggleToolButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToggleToolButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToggleToolButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToggleToolButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ToolItem', RubyLint.registry))

    klass.define_instance_method('clicked')

    klass.define_instance_method('icon_name')

    klass.define_instance_method('icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon_widget')

    klass.define_instance_method('icon_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('initialize') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end

    klass.define_instance_method('label')

    klass.define_instance_method('label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('label_widget')

    klass.define_instance_method('label_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_stock_id') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_use_underline') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stock_id')

    klass.define_instance_method('stock_id=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_underline=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_underline?')
  end

  defs.define_constant('Gtk::ToolButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolItem') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Activatable', RubyLint.registry))

    klass.define_instance_method('ellipsize_mode')

    klass.define_instance_method('expand=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('expand?')

    klass.define_instance_method('get_proxy_menu_item') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('homogeneous=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('homogeneous?')

    klass.define_instance_method('icon_size')

    klass.define_instance_method('important=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('important?')

    klass.define_instance_method('orientation')

    klass.define_instance_method('rebuild_menu')

    klass.define_instance_method('relief_style')

    klass.define_instance_method('retrieve_proxy_menu_item')

    klass.define_instance_method('set_expand') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_homogeneous') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_important') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_proxy_menu_item') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_tooltip') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_use_drag_window') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_visible_horizontal') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible_vertical') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('text_alignment')

    klass.define_instance_method('text_orientation')

    klass.define_instance_method('text_size_group')

    klass.define_instance_method('toolbar_reconfigured')

    klass.define_instance_method('toolbar_style')

    klass.define_instance_method('tooltip=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_drag_window=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_drag_window?')

    klass.define_instance_method('visible_horizontal=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible_horizontal?')

    klass.define_instance_method('visible_vertical=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible_vertical?')
  end

  defs.define_constant('Gtk::ToolItem::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolItem::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolItem::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolItem::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolItemGroup') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::ToolShell', RubyLint.registry))

    klass.define_instance_method('collapsed=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('collapsed?')

    klass.define_instance_method('ellipsize')

    klass.define_instance_method('ellipsize=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('get_drop_item') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_nth_item') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('header_relief')

    klass.define_instance_method('header_relief=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('insert') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('label')

    klass.define_instance_method('label=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('label_widget')

    klass.define_instance_method('label_widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('n_items')

    klass.define_instance_method('set_collapsed') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_ellipsize') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_header_relief') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_label_widget') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::ToolItemGroup::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolItemGroup::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolItemGroup::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolItemGroup::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::ToolShell') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('ellipsize_mode')

    klass.define_instance_method('icon_size')

    klass.define_instance_method('orientation')

    klass.define_instance_method('rebuild_menu')

    klass.define_instance_method('relief_style')

    klass.define_instance_method('style')

    klass.define_instance_method('text_alignment')

    klass.define_instance_method('text_orientation')

    klass.define_instance_method('text_size_group')
  end

  defs.define_constant('Gtk::Toolbar') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Orientable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::ToolShell', RubyLint.registry))

    klass.define_instance_method('append') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('append_space') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('drop_index') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('focus_home_or_end') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('get_drop_index') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_item_index') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_nth_item') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('icon_size')

    klass.define_instance_method('icon_size=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon_size_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon_size_set?')

    klass.define_instance_method('insert') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('insert_space') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('item_index') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('n_items')

    klass.define_instance_method('nth_item') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('prepend') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('prepend_space') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('relief_style')

    klass.define_instance_method('remove_space') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_drop_highlight_item') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_icon_size') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon_size_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_show_arrow') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_toolbar_style') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_arrow=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_arrow?')

    klass.define_instance_method('toolbar_style')

    klass.define_instance_method('toolbar_style=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('unset_icon_size')

    klass.define_instance_method('unset_style')
  end

  defs.define_constant('Gtk::Toolbar::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::SpaceStyle') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::SpaceStyle::EMPTY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::SpaceStyle::LINE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::Style') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::Style::BOTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::Style::BOTH_HORIZ') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::Style::ICONS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::Style::TEXT') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Toolbar::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Tooltip') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('custom=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_custom') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_icon') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_icon_from_stock') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_markup') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_text') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('text=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Tooltip::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeDragDest') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeDragSource') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeIter') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('[]') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('[]=') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('first!')

    klass.define_instance_method('first_child')

    klass.define_instance_method('get_value') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_child?')

    klass.define_instance_method('n_children')

    klass.define_instance_method('next!')

    klass.define_instance_method('nth_child') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('parent')

    klass.define_instance_method('path')

    klass.define_instance_method('set_value') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_str')
  end

  defs.define_constant('Gtk::TreeModel') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('each')

    klass.define_instance_method('flags')

    klass.define_instance_method('get_column_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_iter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_value') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('iter_first')

    klass.define_instance_method('iter_is_valid?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('n_columns')

    klass.define_instance_method('row_changed') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('row_deleted') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('row_has_child_toggled') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('row_inserted') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('rows_reordered') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end
  end

  defs.define_constant('Gtk::TreeModelFilter') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeDragSource', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeModel', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('child_model')

    klass.define_instance_method('clear_cache')

    klass.define_instance_method('convert_child_iter_to_iter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('convert_child_path_to_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('convert_iter_to_child_iter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('convert_path_to_child_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('model')

    klass.define_instance_method('refilter')

    klass.define_instance_method('set_modify_func') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_visible_column') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_visible_func')

    klass.define_instance_method('virtual_root')

    klass.define_instance_method('visible_column=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::TreeModelFilter::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('iters_persist?')

    klass.define_instance_method('list_only?')
  end

  defs.define_constant('Gtk::TreeModelFilter::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeModelSort') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeDragSource', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeSortable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeModel', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('clear_cache')

    klass.define_instance_method('convert_child_iter_to_iter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('convert_child_path_to_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('convert_iter_to_child_iter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('convert_path_to_child_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iter_is_valid?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('model')

    klass.define_instance_method('reset_default_sort_func')
  end

  defs.define_constant('Gtk::TreeModelSort::DEFAULT_SORT_COLUMN_ID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeModelSort::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('iters_persist?')

    klass.define_instance_method('list_only?')
  end

  defs.define_constant('Gtk::TreeModelSort::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreePath') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('<=>') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('==') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('ancestor?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('append_index') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('depth')

    klass.define_instance_method('descendant?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('down!')

    klass.define_instance_method('indices')

    klass.define_instance_method('next!')

    klass.define_instance_method('prepend_index') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('prev!')

    klass.define_instance_method('to_s')

    klass.define_instance_method('to_str')

    klass.define_instance_method('up!')
  end

  defs.define_constant('Gtk::TreeRowReference') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_method('deleted') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('inserted') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_method('reordered') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('model')

    klass.define_instance_method('path')

    klass.define_instance_method('valid?')
  end

  defs.define_constant('Gtk::TreeSelection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('count_selected_rows')

    klass.define_instance_method('iter_is_selected?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('mode')

    klass.define_instance_method('mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('path_is_selected?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('select_all')

    klass.define_instance_method('select_iter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('select_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('select_range') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('selected')

    klass.define_instance_method('selected_each')

    klass.define_instance_method('selected_rows')

    klass.define_instance_method('set_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_select_function')

    klass.define_instance_method('tree_view')

    klass.define_instance_method('unselect_all')

    klass.define_instance_method('unselect_iter') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('unselect_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('unselect_range') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end

  defs.define_constant('Gtk::TreeSelection::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeSortable') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_instance_method('has_default_sort_func?')

    klass.define_instance_method('set_default_sort_func')

    klass.define_instance_method('set_sort_column_id') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_sort_func') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('sort_column_changed')

    klass.define_instance_method('sort_column_id')

    klass.define_instance_method('sort_func=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::TreeSortable::DEFAULT_SORT_COLUMN_ID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeStore') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeSortable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeDragDest', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeDragSource', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::TreeModel', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('ancestor?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('append') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('clear')

    klass.define_instance_method('insert') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('insert_after') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('insert_before') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('iter_depth') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iter_is_valid?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('move_after') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('move_before') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('prepend') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('reorder') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_column_types') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('set_value') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('swap') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end
  end

  defs.define_constant('Gtk::TreeStore::DEFAULT_SORT_COLUMN_ID') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeStore::Flags') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('iters_persist?')

    klass.define_instance_method('list_only?')
  end

  defs.define_constant('Gtk::TreeStore::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Container', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Scrollable', RubyLint.registry))

    klass.define_instance_method('activate_on_single_click=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('activate_on_single_click?')

    klass.define_instance_method('append_column') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('bin_window')

    klass.define_instance_method('collapse_all')

    klass.define_instance_method('collapse_row') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('columns')

    klass.define_instance_method('columns_autosize')

    klass.define_instance_method('convert_bin_window_to_tree_coords') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('convert_bin_window_to_widget_coords') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('convert_tree_to_bin_window_coords') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('convert_tree_to_widget_coords') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('convert_widget_to_bin_window_coords') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('convert_widget_to_tree_coords') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('create_row_drag_icon') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('cursor')

    klass.define_instance_method('drag_dest_row')

    klass.define_instance_method('enable_grid_lines')

    klass.define_instance_method('enable_grid_lines=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('enable_model_drag_dest') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('enable_model_drag_source') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('enable_search=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('enable_search?')

    klass.define_instance_method('enable_tree_lines=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('enable_tree_lines?')

    klass.define_instance_method('expand_all')

    klass.define_instance_method('expand_collapse_cursor_row') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
      method.define_argument('x2')
    end

    klass.define_instance_method('expand_row') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('expand_to_path') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('expander_column')

    klass.define_instance_method('expander_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('fixed_height_mode=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('fixed_height_mode?')

    klass.define_instance_method('get_background_area') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_cell_area') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_column') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_dest_row') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_dest_row_at_pos') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_path') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('get_path_at_pos') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('headers_clickable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('headers_clickable?')

    klass.define_instance_method('headers_visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('headers_visible?')

    klass.define_instance_method('hover_expand=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hover_expand?')

    klass.define_instance_method('hover_selection=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hover_selection?')

    klass.define_instance_method('insert_column') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('level_indentation')

    klass.define_instance_method('level_indentation=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('map_expanded_rows')

    klass.define_instance_method('model')

    klass.define_instance_method('model=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('move_column_after') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('move_cursor') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
    end

    klass.define_instance_method('remove_column') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('reorderable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('reorderable?')

    klass.define_instance_method('row_activated') do |method|
      method.define_argument('x0')
      method.define_argument('x1')
    end

    klass.define_instance_method('row_expanded?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('rubber_banding=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('rubber_banding?')

    klass.define_instance_method('rules_hint=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('rules_hint?')

    klass.define_instance_method('scroll_to_cell') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('scroll_to_point') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('search_column')

    klass.define_instance_method('search_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('search_entry')

    klass.define_instance_method('search_entry=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('select_all')

    klass.define_instance_method('select_cursor_parent')

    klass.define_instance_method('select_cursor_row') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('selection')

    klass.define_instance_method('set_activate_on_single_click') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_column_drag_function')

    klass.define_instance_method('set_cursor') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_cursor_on_cell') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('set_drag_dest_row') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_enable_grid_lines') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_enable_search') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_enable_tree_lines') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_expander_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_fixed_height_mode') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_headers_clickable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_headers_visible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_hover_expand') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_hover_selection') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_level_indentation') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_model') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_reorderable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_row_separator_func')

    klass.define_instance_method('set_rubber_banding') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_rules_hint') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_search_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_search_entry') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_search_equal_func')

    klass.define_instance_method('set_search_position_func')

    klass.define_instance_method('set_show_expanders') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tooltip_column') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_expanders=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('show_expanders?')

    klass.define_instance_method('start_interactive_search')

    klass.define_instance_method('toggle_cursor_row')

    klass.define_instance_method('tooltip_column')

    klass.define_instance_method('tooltip_column=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tree_to_widget_coords') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('unselect_all')

    klass.define_instance_method('unset_rows_drag_dest')

    klass.define_instance_method('unset_rows_drag_source')

    klass.define_instance_method('visible_range')

    klass.define_instance_method('visible_rect')

    klass.define_instance_method('widget_to_tree_coords') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end
  end

  defs.define_constant('Gtk::TreeView::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::DropPosition') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::DropPosition::AFTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::DropPosition::BEFORE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::DropPosition::INTO_OR_AFTER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::DropPosition::INTO_OR_BEFORE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::GridLines') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::GridLines::BOTH') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::GridLines::HORIZONTAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::GridLines::NONE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::GridLines::VERTICAL') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::Policy') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeView::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeViewColumn') do |klass|
    klass.inherits(defs.constant_proxy('GLib::InitiallyUnowned', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::CellLayout', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('add_attribute') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('alignment')

    klass.define_instance_method('alignment=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cell_area')

    klass.define_instance_method('cell_data_func=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('cell_is_visible?')

    klass.define_instance_method('cell_renderers') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('cell_set_cell_data') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('cell_size')

    klass.define_instance_method('clear')

    klass.define_instance_method('clear_attributes') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('clickable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('clickable?')

    klass.define_instance_method('clicked')

    klass.define_instance_method('expand=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('expand?')

    klass.define_instance_method('fixed_width')

    klass.define_instance_method('fixed_width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_cell') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('max_width')

    klass.define_instance_method('max_width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('min_width')

    klass.define_instance_method('min_width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('pack_end') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('pack_start') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('queue_resize')

    klass.define_instance_method('reorderable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('reorderable?')

    klass.define_instance_method('resizable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('resizable?')

    klass.define_instance_method('set_alignment') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_attributes') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_cell_data_func') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_clickable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_expand') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_fixed_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_max_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_min_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_reorderable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_resizable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_sizing') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_sort_column_id') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_sort_indicator') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_sort_order') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_spacing') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_title') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_widget') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('sizing')

    klass.define_instance_method('sizing=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('sort_column_id')

    klass.define_instance_method('sort_column_id=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('sort_indicator=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('sort_indicator?')

    klass.define_instance_method('sort_order')

    klass.define_instance_method('sort_order=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('spacing')

    klass.define_instance_method('spacing=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('title')

    klass.define_instance_method('title=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tree_view')

    klass.define_instance_method('visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible?')

    klass.define_instance_method('widget')

    klass.define_instance_method('widget=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('width')

    klass.define_instance_method('x_offset')
  end

  defs.define_constant('Gtk::TreeViewColumn::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeViewColumn::Sizing') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeViewColumn::Sizing::AUTOSIZE') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeViewColumn::Sizing::FIXED') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::TreeViewColumn::Sizing::GROW_ONLY') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_instance_method('[]') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('accel_group')

    klass.define_instance_method('action_groups')

    klass.define_instance_method('add_tearoffs=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('add_tearoffs?')

    klass.define_instance_method('add_ui') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('ensure_update')

    klass.define_instance_method('get_action') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_toplevels') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_widget') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('insert_action_group') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('new_merge_id')

    klass.define_instance_method('remove_action_group') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_ui') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_add_tearoffs') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('ui')
  end

  defs.define_constant('Gtk::UIManager::ItemType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Flags', RubyLint.registry))

    klass.define_instance_method('accelerator?')

    klass.define_instance_method('auto?')

    klass.define_instance_method('menu?')

    klass.define_instance_method('menubar?')

    klass.define_instance_method('menuitem?')

    klass.define_instance_method('placeholder?')

    klass.define_instance_method('popup?')

    klass.define_instance_method('popup_with_accels?')

    klass.define_instance_method('separator?')

    klass.define_instance_method('toolbar?')

    klass.define_instance_method('toolitem?')
  end

  defs.define_constant('Gtk::UIManager::ItemType::ACCELERATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::ItemType::AUTO') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::ItemType::MENU') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::ItemType::MENUBAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::ItemType::MENUITEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::ItemType::PLACEHOLDER') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::ItemType::POPUP') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::ItemType::POPUP_WITH_ACCELS') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::ItemType::SEPARATOR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::ItemType::TOOLBAR') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::ItemType::TOOLITEM') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::UIManager::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::VBox') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::VButtonBox') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::VERSION') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::VPaned') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::VScale') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::VScrollbar') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::VSeparator') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('new') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')

      method.returns { |object| object.instance }
    end
  end

  defs.define_constant('Gtk::Viewport') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Scrollable', RubyLint.registry))

    klass.define_instance_method('set_shadow_type') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('shadow_type')

    klass.define_instance_method('shadow_type=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Viewport::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Viewport::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Viewport::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Viewport::Policy') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Viewport::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::VolumeButton') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::ScaleButton', RubyLint.registry))

    klass.define_instance_method('set_use_symbolic') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_symbolic=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('use_symbolic?')
  end

  defs.define_constant('Gtk::VolumeButton::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::VolumeButton::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::VolumeButton::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::VolumeButton::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Widget') do |klass|
    klass.inherits(defs.constant_proxy('GLib::InitiallyUnowned', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Gtk::Buildable', RubyLint.registry))
    klass.inherits(defs.constant_proxy('Atk::Implementor', RubyLint.registry))
    klass.inherits(defs.constant_proxy('GLib::Interface', RubyLint.registry))

    klass.define_method('binding_set')

    klass.define_method('default_colormap') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('default_colormap=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('default_direction')

    klass.define_method('default_direction=') do |method|
      method.define_argument('val')
    end

    klass.define_method('default_style') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('default_visual') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('install_style_property') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('pop_colormap') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('pop_composite_child')

    klass.define_method('push_colormap') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('push_composite_child')

    klass.define_method('set_default_colormap') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_method('set_default_direction') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('style_properties') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_method('style_property') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('accel_closures')

    klass.define_instance_method('accessible')

    klass.define_instance_method('action') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('activate')

    klass.define_instance_method('add_accelerator') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('add_device_events') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('add_events') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_mnemonic_label') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('allocated_height')

    klass.define_instance_method('allocated_width')

    klass.define_instance_method('allocation')

    klass.define_instance_method('allocation=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('ancestor?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('app_paintable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('app_paintable?')

    klass.define_instance_method('bindings_activate') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('can_activate_accel?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('can_default=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('can_default?')

    klass.define_instance_method('can_focus=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('can_focus?')

    klass.define_instance_method('child_focus') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('child_notify') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('child_requisition') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('child_visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('child_visible?')

    klass.define_instance_method('class_path') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('colormap') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('colormap=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('composite_child?')

    klass.define_instance_method('composite_name')

    klass.define_instance_method('composite_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('composited?')

    klass.define_instance_method('composited_changed')

    klass.define_instance_method('compute_expand') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('create_pango_context')

    klass.define_instance_method('create_pango_layout') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('destroy')

    klass.define_instance_method('device_is_shadowed?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('direction')

    klass.define_instance_method('direction=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('display')

    klass.define_instance_method('double_buffered=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('double_buffered?')

    klass.define_instance_method('drag_begin') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('drag_dest_add_image_targets')

    klass.define_instance_method('drag_dest_add_text_targets')

    klass.define_instance_method('drag_dest_add_uri_targets')

    klass.define_instance_method('drag_dest_find_target') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('drag_dest_get_target_list')

    klass.define_instance_method('drag_dest_get_track_motion')

    klass.define_instance_method('drag_dest_set') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('drag_dest_set_proxy') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('drag_dest_set_target_list') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('drag_dest_set_track_motion') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('drag_dest_unset')

    klass.define_instance_method('drag_get_data') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('drag_highlight')

    klass.define_instance_method('drag_source_add_image_targets')

    klass.define_instance_method('drag_source_add_text_targets')

    klass.define_instance_method('drag_source_add_uri_targets')

    klass.define_instance_method('drag_source_get_target_list')

    klass.define_instance_method('drag_source_set') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('drag_source_set_icon') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('drag_source_set_target_list') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('drag_source_unset')

    klass.define_instance_method('drag_threshold?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('drag_unhighlight')

    klass.define_instance_method('draw') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('drawable?')

    klass.define_instance_method('ensure_style') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('error_bell')

    klass.define_instance_method('event') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('events')

    klass.define_instance_method('events=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('expand=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('expand?')

    klass.define_instance_method('flags') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('flags=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('focus=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus?')

    klass.define_instance_method('freeze_child_notify')

    klass.define_instance_method('get_ancestor') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_clipboard') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_device_enabled?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_device_events') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_preferred_height_for_width') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_preferred_width_for_height') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('get_size_request')

    klass.define_instance_method('grab_default')

    klass.define_instance_method('grab_focus')

    klass.define_instance_method('halign')

    klass.define_instance_method('halign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_default=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_default?')

    klass.define_instance_method('has_focus=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_focus?')

    klass.define_instance_method('has_grab?')

    klass.define_instance_method('has_rc_style?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('has_screen?')

    klass.define_instance_method('has_tooltip=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_tooltip?')

    klass.define_instance_method('has_visible_focus?')

    klass.define_instance_method('has_window=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_window?')

    klass.define_instance_method('height_request')

    klass.define_instance_method('height_request=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hexpand=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hexpand?')

    klass.define_instance_method('hexpand_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hexpand_set?')

    klass.define_instance_method('hide')

    klass.define_instance_method('hide_all') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('hide_on_delete')

    klass.define_instance_method('in_destruction?')

    klass.define_instance_method('input_shape_combine_mask') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('input_shape_combine_region') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('intersect') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('keynav_failed')

    klass.define_instance_method('map')

    klass.define_instance_method('mapped=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mapped?')

    klass.define_instance_method('margin')

    klass.define_instance_method('margin=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('margin_bottom')

    klass.define_instance_method('margin_bottom=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('margin_left')

    klass.define_instance_method('margin_left=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('margin_right')

    klass.define_instance_method('margin_right=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('margin_top')

    klass.define_instance_method('margin_top=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mnemonic_activate') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('mnemonic_labels')

    klass.define_instance_method('modifier_style') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('modify_base') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('modify_bg') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('modify_cursor') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('modify_fg') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('modify_font') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('modify_style') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('modify_text') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('move_focus') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('name')

    klass.define_instance_method('name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('no_show_all=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('no_show_all?')

    klass.define_instance_method('no_window?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('opacity')

    klass.define_instance_method('opacity=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('override_background_color') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('override_color') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('override_cursor') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('override_font') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('override_symbolic_color') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('pango_context')

    klass.define_instance_method('parent')

    klass.define_instance_method('parent=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('parent_sensitive?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('parent_window')

    klass.define_instance_method('parent_window=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('path')

    klass.define_instance_method('pointer') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('popup_menu')

    klass.define_instance_method('preferred_height')

    klass.define_instance_method('preferred_size')

    klass.define_instance_method('preferred_width')

    klass.define_instance_method('queue_compute_expand')

    klass.define_instance_method('queue_draw')

    klass.define_instance_method('queue_draw_area') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('queue_draw_region') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('queue_resize')

    klass.define_instance_method('queue_resize_no_redraw')

    klass.define_instance_method('rc_style?') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('realize')

    klass.define_instance_method('realized=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('realized?')

    klass.define_instance_method('receives_default=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('receives_default?')

    klass.define_instance_method('redraw_on_allocate=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('region_intersect') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_accelerator') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('remove_mnemonic_label') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('render_icon') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('render_icon_pixbuf') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('reparent') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('request_mode')

    klass.define_instance_method('requisition') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('reset_rc_styles') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('reset_shapes') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('reset_style')

    klass.define_instance_method('root_window')

    klass.define_instance_method('saved_state') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('scale_factor')

    klass.define_instance_method('screen')

    klass.define_instance_method('send_expose') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('send_focus_change') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('sensitive=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('sensitive?')

    klass.define_instance_method('sensitive_with_parent?')

    klass.define_instance_method('set_accel_path') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_allocation') do |method|
      method.define_rest_argument('args')
    end

    klass.define_instance_method('set_app_paintable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_can_default') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_can_focus') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_child_visible') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_colormap') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_composite_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_device_enabled') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_device_events') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_direction') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_double_buffered') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_events') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_expand') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_flags') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_focus') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_halign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_default') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_focus') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_tooltip') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_window') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_height_request') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_hexpand') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_hexpand_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_mapped') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_margin') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_margin_bottom') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_margin_left') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_margin_right') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_margin_top') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_no_show_all') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_opacity') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_parent') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_parent_window') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_realized') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_receives_default') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_redraw_on_allocate') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_requisition') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_scroll_adjustment') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_scroll_adjustments') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_sensitive') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_size_request') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_state') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('set_state_flags') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_style') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_support_multidevice') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_tooltip_markup') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tooltip_text') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_tooltip_window') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_valign') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_vexpand') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_vexpand_set') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_visual') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_width_request') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_window') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('settings')

    klass.define_instance_method('shape_combine_mask') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('shape_combine_region') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('show')

    klass.define_instance_method('show_all')

    klass.define_instance_method('show_help') do |method|
      method.define_argument('x0')
    end

    klass.define_instance_method('show_now')

    klass.define_instance_method('size_allocate') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('size_request') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('state') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('state=') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('state_flags')

    klass.define_instance_method('style')

    klass.define_instance_method('style=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('style_context')

    klass.define_instance_method('style_get_property') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('support_multidevice=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('support_multidevice?')

    klass.define_instance_method('thaw_child_notify')

    klass.define_instance_method('tooltip_markup')

    klass.define_instance_method('tooltip_markup=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tooltip_text')

    klass.define_instance_method('tooltip_text=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('tooltip_window')

    klass.define_instance_method('tooltip_window=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('toplevel')

    klass.define_instance_method('toplevel?')

    klass.define_instance_method('translate_coordinates') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('trigger_tooltip_query')

    klass.define_instance_method('unmap')

    klass.define_instance_method('unparent')

    klass.define_instance_method('unrealize')

    klass.define_instance_method('unset_flags') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('unset_state_flags') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('valign')

    klass.define_instance_method('valign=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('vexpand=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('vexpand?')

    klass.define_instance_method('vexpand_set=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('vexpand_set?')

    klass.define_instance_method('visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('visible?')

    klass.define_instance_method('visual')

    klass.define_instance_method('visual=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('width_request')

    klass.define_instance_method('width_request=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('window')

    klass.define_instance_method('window=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Widget::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::WidgetPath') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Boxed', RubyLint.registry))

    klass.define_instance_method('append_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('has_parent?') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iter_add_class') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('iter_add_region') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('iter_clear_classes') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iter_clear_regions') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iter_get_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iter_get_object_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iter_has_class?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('iter_has_name?') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('iter_has_region') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('iter_list_classes') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iter_list_regions') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('iter_remove_class') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('iter_remove_region') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('iter_set_name') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('iter_set_object_type') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('length')

    klass.define_instance_method('object_type')

    klass.define_instance_method('prepend_type') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('to_s')

    klass.define_instance_method('type?') do |method|
      method.define_argument('arg1')
    end
  end

  defs.define_constant('Gtk::Window') do |klass|
    klass.inherits(defs.constant_proxy('Gtk::Bin', RubyLint.registry))

    klass.define_method('auto_startup_notification=') do |method|
      method.define_argument('val')
    end

    klass.define_method('default_icon=') do |method|
      method.define_argument('val')
    end

    klass.define_method('default_icon_list')

    klass.define_method('default_icon_list=') do |method|
      method.define_argument('val')
    end

    klass.define_method('default_icon_name')

    klass.define_method('default_icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_method('set_auto_startup_notification') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('set_default_icon') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('set_default_icon_list') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('set_default_icon_name') do |method|
      method.define_argument('arg1')
    end

    klass.define_method('toplevels')

    klass.define_instance_method('accept_focus=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('accept_focus?')

    klass.define_instance_method('activate_default')

    klass.define_instance_method('activate_focus')

    klass.define_instance_method('activate_key') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('active?')

    klass.define_instance_method('active_default') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('active_focus') do |method|
      method.define_rest_argument('margs')
      method.define_block_argument('mblock')
    end

    klass.define_instance_method('add_accel_group') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('add_mnemonic') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('application')

    klass.define_instance_method('application=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('attached_to')

    klass.define_instance_method('attached_to=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('begin_move_drag') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
    end

    klass.define_instance_method('begin_resize_drag') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
      method.define_argument('arg4')
      method.define_argument('arg5')
    end

    klass.define_instance_method('decorated=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('decorated?')

    klass.define_instance_method('default=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('default_height')

    klass.define_instance_method('default_height=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('default_size')

    klass.define_instance_method('default_widget')

    klass.define_instance_method('default_width')

    klass.define_instance_method('default_width=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('deiconify')

    klass.define_instance_method('deletable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('deletable?')

    klass.define_instance_method('destroy_with_parent=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('destroy_with_parent?')

    klass.define_instance_method('focus')

    klass.define_instance_method('focus=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_on_map=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_on_map?')

    klass.define_instance_method('focus_visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('focus_visible?')

    klass.define_instance_method('fullscreen')

    klass.define_instance_method('gravity')

    klass.define_instance_method('gravity=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('group')

    klass.define_instance_method('has_group?')

    klass.define_instance_method('has_resize_grip=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('has_resize_grip?')

    klass.define_instance_method('has_toplevel_focus?')

    klass.define_instance_method('hide_titlebar_when_maximized=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('hide_titlebar_when_maximized?')

    klass.define_instance_method('icon')

    klass.define_instance_method('icon=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon_list')

    klass.define_instance_method('icon_list=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('icon_name')

    klass.define_instance_method('icon_name=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('iconify')

    klass.define_instance_method('keep_above=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('keep_below=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('maximize')

    klass.define_instance_method('mnemonic_activate') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('mnemonic_modifier')

    klass.define_instance_method('mnemonic_modifier=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mnemonics_visible=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('mnemonics_visible?')

    klass.define_instance_method('modal=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('modal?')

    klass.define_instance_method('move') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('parse_geometry') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('position')

    klass.define_instance_method('present') do |method|
      method.define_rest_argument('arg1')
    end

    klass.define_instance_method('propagate_key_event') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_accel_group') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove_mnemonic') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('reshow_with_initial_size')

    klass.define_instance_method('resizable=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('resizable?')

    klass.define_instance_method('resize') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('resize_grip_area')

    klass.define_instance_method('resize_grip_visible?')

    klass.define_instance_method('resize_to_geometry') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('role')

    klass.define_instance_method('role=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('screen')

    klass.define_instance_method('screen=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_accept_focus') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_application') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_attached_to') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_decorated') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_default') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_default_geometry') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_default_height') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_default_size') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('set_default_width') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_deletable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_destroy_with_parent') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_focus') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_focus_on_map') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_focus_visible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_geometry_hints') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
      method.define_argument('arg3')
    end

    klass.define_instance_method('set_gravity') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_has_resize_grip') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_hide_titlebar_when_maximized') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_icon') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_icon_list') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_icon_name') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_keep_above') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_keep_below') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_mnemonic_modifier') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('set_mnemonics_visible') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_modal') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_resizable') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_role') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_screen') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_skip_pager_hint') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_skip_taskbar_hint') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_startup_id') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_title') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_transient_for') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_type_hint') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_urgency_hint') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_window_position') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('set_wmclass') do |method|
      method.define_argument('arg1')
      method.define_argument('arg2')
    end

    klass.define_instance_method('size')

    klass.define_instance_method('skip_pager_hint=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('skip_pager_hint?')

    klass.define_instance_method('skip_taskbar_hint=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('skip_taskbar_hint?')

    klass.define_instance_method('startup_id=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('stick')

    klass.define_instance_method('title')

    klass.define_instance_method('title=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('transient_for')

    klass.define_instance_method('transient_for=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('type')

    klass.define_instance_method('type_hint')

    klass.define_instance_method('type_hint=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('unfullscreen')

    klass.define_instance_method('unmaximize')

    klass.define_instance_method('unstick')

    klass.define_instance_method('urgency_hint=') do |method|
      method.define_argument('val')
    end

    klass.define_instance_method('urgency_hint?')

    klass.define_instance_method('window_position')

    klass.define_instance_method('window_position=') do |method|
      method.define_argument('val')
    end
  end

  defs.define_constant('Gtk::Window::Align') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Window::HelpType') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::Window::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Gtk::Window::TextDirection') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Enum', RubyLint.registry))

  end

  defs.define_constant('Gtk::WindowGroup') do |klass|
    klass.inherits(defs.constant_proxy('GLib::Object', RubyLint.registry))

    klass.define_instance_method('add') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('current_grab')

    klass.define_instance_method('get_current_device_grab') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('remove') do |method|
      method.define_argument('arg1')
    end

    klass.define_instance_method('windows')
  end

  defs.define_constant('Gtk::WindowGroup::LOG_DOMAIN') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
