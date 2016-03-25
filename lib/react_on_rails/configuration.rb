module ReactOnRails
  def self.configure
    yield(configuration)
    setup_config_values
  end

  DEFAULT_GENERATED_ASSETS_DIR = File.join(%w(app assets webpack)).freeze

  def self.setup_config_values
    if @configuration.webpack_generated_files.empty?
      files = ["client-bundle.js"]
      if @configuration.server_bundle_js_files.present?
        files += @configuration.server_bundle_js_files
      end
      @configuration.webpack_generated_files = files
    end

    if @configuration.generated_assets_dirs.present?
      puts "[DEPRECATION] ReactOnRails: Use config.generated_assets_dir rather than "\
        "generated_assets_dirs"
      if @configuration.generated_assets_dir.blank?
        @configuration.generated_assets_dir = @configuration.generated_assets_dirs
      else
        puts "[DEPRECATION] ReactOnRails. You have both generated_assets_dirs and "\
          "generated_assets_dir defined. Define ONLY generated_assets_dir"
      end
    end

    if @configuration.generated_assets_dir.blank?
      @configuration.generated_assets_dir = DEFAULT_GENERATED_ASSETS_DIR
      puts "ReactOnRails: Set generated_assets_dir to default: #{DEFAULT_GENERATED_ASSETS_DIR}"
    end

    @configuration.normalize_server_bundle_js_files!
  end

  def self.configuration
    @configuration ||= Configuration.new(
      generated_assets_dirs: nil,

      # generated_assets_dirs is deprecated
      generated_assets_dir: "",

      server_bundle_js_files: [],
      prerender: false,
      replay_console: true,
      logging_on_server: true,
      raise_on_prerender_error: false,
      trace: Rails.env.development?,
      development_mode: Rails.env.development?,
      server_renderer_pool_size: 1,
      server_renderer_timeout: 20,
      skip_display_none: false,
      webpack_generated_files: []
    )
  end

  class Configuration
    attr_accessor :server_bundle_js_files, :prerender, :replay_console,
                  :trace, :development_mode,
                  :logging_on_server, :server_renderer_pool_size,
                  :server_renderer_timeout, :raise_on_prerender_error,
                  :skip_display_none, :generated_assets_dirs, :generated_assets_dir,
                  :webpack_generated_files

    def initialize(server_bundle_js_files: [], prerender: nil, replay_console: nil,
                   trace: nil, development_mode: nil,
                   logging_on_server: nil, server_renderer_pool_size: nil,
                   server_renderer_timeout: nil, raise_on_prerender_error: nil,
                   skip_display_none: nil, generated_assets_dirs: nil,
                   generated_assets_dir: nil, webpack_generated_files: nil)
      self.server_bundle_js_files = server_bundle_js_files
      self.generated_assets_dirs = generated_assets_dirs
      self.generated_assets_dir = generated_assets_dir

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
    end

    def normalize_server_bundle_js_files!
      @server_bundle_js_files.map! do |server_bundle_js_file|
        if server_bundle_js_file.include?(File::SEPARATOR)
          puts "[DEPRECATION] ReactOnRails: remove path from server_bundle_js_files in configuration. "\
          "All generated files must go in #{@generated_assets_dir}"
          File.basename(server_bundle_js_file)
        else
          server_bundle_js_file
        end
      end
    end
  end
end
