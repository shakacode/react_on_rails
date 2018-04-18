# frozen_string_literal: true

# NOTE: ReactOnRails::Utils.using_webpacker? always will return false when called here.

module ReactOnRails
  def self.configure
    yield(configuration)
    setup_config_values
  end

  DEFAULT_GENERATED_ASSETS_DIR = File.join(%w[public webpack], Rails.env).freeze

  def self.setup_config_values
    ensure_webpack_generated_files_exists
    configure_generated_assets_dirs_deprecation
    configure_skip_display_none_deprecation
    ensure_generated_assets_dir_present
    ensure_server_bundle_js_file_has_no_path
    check_i18n_directory_exists
    check_i18n_yml_directory_exists
    check_server_render_method_is_only_execjs
  end

  def self.check_server_render_method_is_only_execjs
    return if @configuration.server_render_method.blank? ||
              @configuration.server_render_method == "ExecJS"

    msg = <<-MSG.strip_heredoc
      Error configuring /config/react_on_rails.rb: invalid value for `config.server_render_method`.
      If you wish to use a server render method other than ExecJS, contact justin@shakacode.com
      for details.
    MSG
    raise ReactOnRails::Error, msg
  end

  def self.check_i18n_directory_exists
    return if @configuration.i18n_dir.nil?
    return if Dir.exist?(@configuration.i18n_dir)

    msg = <<-MSG.strip_heredoc
      Error configuring /config/react_on_rails.rb: invalid value for `config.i18n_dir`.
      Directory does not exist: #{@configuration.i18n_dir}. Set to value to nil or comment it
      out if not using the React on Rails i18n feature.
    MSG
    raise ReactOnRails::Error, msg
  end

  def self.check_i18n_yml_directory_exists
    return if @configuration.i18n_yml_dir.nil?
    return if Dir.exist?(@configuration.i18n_yml_dir)

    msg = <<-MSG.strip_heredoc
      Error configuring /config/react_on_rails.rb: invalid value for `config.i18n_yml_dir`.
      Directory does not exist: #{@configuration.i18n_yml_dir}. Set to value to nil or comment it
      out if not using this i18n with React on Rails, or if you want to use all translation files.
    MSG
    raise ReactOnRails::Error, msg
  end

  def self.ensure_generated_assets_dir_present
    return if @configuration.generated_assets_dir.present?

    @configuration.generated_assets_dir = DEFAULT_GENERATED_ASSETS_DIR
    puts "ReactOnRails: Set generated_assets_dir to default: #{DEFAULT_GENERATED_ASSETS_DIR}"
  end

  def self.configure_generated_assets_dirs_deprecation
    return if @configuration.generated_assets_dirs.blank?

    puts "[DEPRECATION] ReactOnRails: Use config.generated_assets_dir rather than "\
        "generated_assets_dirs"
    if @configuration.generated_assets_dir.blank?
      @configuration.generated_assets_dir = @configuration.generated_assets_dirs
    else
      puts "[DEPRECATION] ReactOnRails. You have both generated_assets_dirs and "\
          "generated_assets_dir defined. Define ONLY generated_assets_dir"
    end
  end

  def self.ensure_webpack_generated_files_exists
    return unless @configuration.webpack_generated_files.empty?

    files = ["hello-world-bundle.js"]
    files << @configuration.server_bundle_js_file if @configuration.server_bundle_js_file.present?

    @configuration.webpack_generated_files = files
  end

  def self.ensure_server_bundle_js_file_has_no_path
    return unless @configuration.server_bundle_js_file.include?(File::SEPARATOR)

    puts "[DEPRECATION] ReactOnRails: remove path from server_bundle_js_file in configuration. "\
        "All generated files must go in #{@configuration.generated_assets_dir}"
    @configuration.server_bundle_js_file = File.basename(@configuration.server_bundle_js_file)
  end

  def self.configure_skip_display_none_deprecation
    return if @configuration.skip_display_none.nil?
    puts "[DEPRECATION] ReactOnRails: remove skip_display_none from configuration."
  end

  def self.configuration
    @configuration ||= Configuration.new(
      node_modules_location: nil,
      generated_assets_dirs: nil,
      # generated_assets_dirs is deprecated
      generated_assets_dir: "",
      server_bundle_js_file: "",
      prerender: false,
      replay_console: true,
      logging_on_server: true,
      raise_on_prerender_error: false,
      trace: Rails.env.development?,
      development_mode: Rails.env.development?,
      server_renderer_pool_size: 1,
      server_renderer_timeout: 20,
      skip_display_none: nil,
      # skip_display_none is deprecated
      webpack_generated_files: %w[manifest.json],
      rendering_extension: nil,
      server_render_method: nil,
      symlink_non_digested_assets_regex: nil,
      build_test_command: "",
      build_production_command: ""
    )
  end

  class Configuration
    attr_accessor :node_modules_location, :server_bundle_js_file, :prerender, :replay_console,
                  :trace, :development_mode,
                  :logging_on_server, :server_renderer_pool_size,
                  :server_renderer_timeout, :skip_display_none, :raise_on_prerender_error,
                  :generated_assets_dirs, :generated_assets_dir,
                  :webpack_generated_files, :rendering_extension, :build_test_command,
                  :build_production_command,
                  :i18n_dir, :i18n_yml_dir,
                  :server_render_method, :symlink_non_digested_assets_regex

    def initialize(node_modules_location: nil, server_bundle_js_file: nil, prerender: nil,
                   replay_console: nil,
                   trace: nil, development_mode: nil,
                   logging_on_server: nil, server_renderer_pool_size: nil,
                   server_renderer_timeout: nil, raise_on_prerender_error: true,
                   skip_display_none: nil, generated_assets_dirs: nil,
                   generated_assets_dir: nil, webpack_generated_files: nil,
                   rendering_extension: nil, build_test_command: nil,
                   build_production_command: nil,
                   i18n_dir: nil, i18n_yml_dir: nil,
                   server_render_method: nil, symlink_non_digested_assets_regex: nil)
      self.node_modules_location = node_modules_location.present? ? node_modules_location : Rails.root
      self.server_bundle_js_file = server_bundle_js_file
      self.generated_assets_dirs = generated_assets_dirs
      self.generated_assets_dir = generated_assets_dir
      self.build_test_command = build_test_command
      self.build_production_command = build_production_command
      self.i18n_dir = i18n_dir
      self.i18n_yml_dir = i18n_yml_dir

      self.prerender = prerender
      self.replay_console = replay_console
      self.logging_on_server = logging_on_server
      self.development_mode = if development_mode.nil?
                                Rails.env.development?
                              else
                                development_mode
                              end
      self.trace = trace.nil? ? Rails.env.development? : trace
      self.raise_on_prerender_error = raise_on_prerender_error
      self.skip_display_none = skip_display_none

      # Server rendering:
      self.server_renderer_pool_size = self.development_mode ? 1 : server_renderer_pool_size
      self.server_renderer_timeout = server_renderer_timeout # seconds

      self.webpack_generated_files = webpack_generated_files
      self.rendering_extension = rendering_extension

      self.server_render_method = server_render_method
      self.symlink_non_digested_assets_regex = symlink_non_digested_assets_regex
    end
  end
end
