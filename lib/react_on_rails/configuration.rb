# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

module ReactOnRails
  def self.configure
    yield(configuration)
    configuration.setup_config_values
  end

  DEFAULT_GENERATED_ASSETS_DIR = File.join(%w[public webpack], Rails.env).freeze
  DEFAULT_COMPONENTS_SUBDIRECTORY = nil
  DEFAULT_SERVER_RENDER_TIMEOUT = 20
  DEFAULT_POOL_SIZE = 1
  DEFAULT_RANDOM_DOM_ID = true # for backwards compatability

  def self.configuration
    @configuration ||= Configuration.new(
      node_modules_location: nil,
      generated_assets_dirs: nil,
      # generated_assets_dirs is deprecated
      generated_assets_dir: "",
      server_bundle_js_file: "",
      prerender: false,
      auto_load_bundle: false,
      replay_console: true,
      logging_on_server: true,
      raise_on_prerender_error: Rails.env.development?,
      trace: Rails.env.development?,
      development_mode: Rails.env.development?,
      server_renderer_pool_size: DEFAULT_POOL_SIZE,
      server_renderer_timeout: DEFAULT_SERVER_RENDER_TIMEOUT,
      skip_display_none: nil,
      # skip_display_none is deprecated
      webpack_generated_files: %w[manifest.json],
      rendering_extension: nil,
      rendering_props_extension: nil,
      server_render_method: nil,
      build_test_command: "",
      build_production_command: "",
      random_dom_id: DEFAULT_RANDOM_DOM_ID,
      same_bundle_for_client_and_server: false,
      i18n_output_format: nil,
      components_subdirectory: DEFAULT_COMPONENTS_SUBDIRECTORY
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
                  :i18n_dir, :i18n_yml_dir, :i18n_output_format,
                  :server_render_method, :random_dom_id, :auto_load_bundle,
                  :same_bundle_for_client_and_server, :rendering_props_extension, :components_subdirectory

    # rubocop:disable Metrics/AbcSize
    def initialize(node_modules_location: nil, server_bundle_js_file: nil, prerender: nil,
                   replay_console: nil,
                   trace: nil, development_mode: nil,
                   logging_on_server: nil, server_renderer_pool_size: nil,
                   server_renderer_timeout: nil, raise_on_prerender_error: true,
                   skip_display_none: nil, generated_assets_dirs: nil,
                   generated_assets_dir: nil, webpack_generated_files: nil,
                   rendering_extension: nil, build_test_command: nil,
                   build_production_command: nil,
                   same_bundle_for_client_and_server: nil,
                   i18n_dir: nil, i18n_yml_dir: nil, i18n_output_format: nil,
                   random_dom_id: nil, server_render_method: nil, rendering_props_extension: nil,
                   components_subdirectory: nil, auto_load_bundle: nil)
      self.node_modules_location = node_modules_location.present? ? node_modules_location : Rails.root
      self.generated_assets_dirs = generated_assets_dirs
      self.generated_assets_dir = generated_assets_dir
      self.build_test_command = build_test_command
      self.build_production_command = build_production_command
      self.i18n_dir = i18n_dir
      self.i18n_yml_dir = i18n_yml_dir
      self.i18n_output_format = i18n_output_format

      self.random_dom_id = random_dom_id
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
      self.rendering_props_extension = rendering_props_extension

      # Server rendering:
      self.server_bundle_js_file = server_bundle_js_file
      self.same_bundle_for_client_and_server = same_bundle_for_client_and_server
      self.server_renderer_pool_size = self.development_mode ? 1 : server_renderer_pool_size
      self.server_renderer_timeout = server_renderer_timeout # seconds

      self.webpack_generated_files = webpack_generated_files
      self.rendering_extension = rendering_extension

      self.server_render_method = server_render_method
      self.components_subdirectory = components_subdirectory
      self.auto_load_bundle = auto_load_bundle
    end
    # rubocop:enable Metrics/AbcSize

    # on ReactOnRails
    def setup_config_values
      check_autobundling_requirements_if_configured
      ensure_webpack_generated_files_exists
      configure_generated_assets_dirs_deprecation
      configure_skip_display_none_deprecation
      ensure_generated_assets_dir_present
      check_server_render_method_is_only_execjs
      error_if_using_webpacker_and_generated_assets_dir_not_match_public_output_path
      # check_deprecated_settings
      adjust_precompile_task
    end

    private

    def check_autobundling_requirements_if_configured
      raise_missing_components_subdirectory if auto_load_bundle && !components_subdirectory.present?
      return unless components_subdirectory.present?

      ReactOnRails::WebpackerUtils.raise_shakapacker_not_installed unless ReactOnRails::WebpackerUtils.using_webpacker?
      ReactOnRails::WebpackerUtils.raise_shakapacker_version_incompatible_for_autobundling unless
        ReactOnRails::WebpackerUtils.shackapacker_version_requirement_met?(
          ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION
        )
      ReactOnRails::WebpackerUtils.raise_nested_entries_disabled unless ReactOnRails::WebpackerUtils.nested_entries?
    end

    def adjust_precompile_task
      skip_react_on_rails_precompile = %w[no false n f].include?(ENV["REACT_ON_RAILS_PRECOMPILE"])

      return if skip_react_on_rails_precompile || build_production_command.blank?

      if Webpacker.config.webpacker_precompile?
        msg = <<~MSG

          React on Rails and Shakapacker error in configuration!
          In order to use config/react_on_rails.rb config.build_production_command,
          you must edit config/webpacker.yml to include this value in the default configuration:
          'webpacker_precompile: false'

          Alternatively, remove the config/react_on_rails.rb config.build_production_command and the
          default bin/webpacker script will be used for assets:precompile.

        MSG
        raise ReactOnRails::Error, msg
      end

      precompile_tasks = lambda {
        Rake::Task["react_on_rails:generate_packs"].invoke
        Rake::Task["react_on_rails:assets:webpack"].invoke
        puts "Invoking task webpacker:clean from React on Rails"

        # VERSIONS is per the shakacode/shakapacker clean method definition.
        # We set it very big so that it is not used, and then clean just
        # removes files older than 1 hour.
        versions = 100_000
        Rake::Task["webpacker:clean"].invoke(versions)
      }

      if Rake::Task.task_defined?("assets:precompile")
        Rake::Task["assets:precompile"].enhance do
          precompile_tasks.call
        end
      else
        Rake::Task.define_task("assets:precompile") do
          precompile_tasks.call
        end
      end
    end

    def error_if_using_webpacker_and_generated_assets_dir_not_match_public_output_path
      return unless ReactOnRails::WebpackerUtils.using_webpacker?

      return if generated_assets_dir.blank?

      webpacker_public_output_path = ReactOnRails::WebpackerUtils.webpacker_public_output_path

      if File.expand_path(generated_assets_dir) == webpacker_public_output_path.to_s
        Rails.logger.warn("You specified generated_assets_dir in `config/initializers/react_on_rails.rb` "\
                          "with Webpacker. Remove this line from your configuration file.")
      else
        msg = <<~MSG
          Error configuring /config/initializers/react_on_rails.rb: You are using webpacker
          and your specified value for generated_assets_dir = #{generated_assets_dir}
          that does not match the value for public_output_path specified in
          webpacker.yml = #{webpacker_public_output_path}. You should remove the configuration
          value for "generated_assets_dir" from your config/initializers/react_on_rails.rb file.
        MSG
        raise ReactOnRails::Error, msg
      end
    end

    def check_server_render_method_is_only_execjs
      return if server_render_method.blank? ||
                server_render_method == "ExecJS"

      msg = <<-MSG.strip_heredoc
      Error configuring /config/initializers/react_on_rails.rb: invalid value for `config.server_render_method`.
      If you wish to use a server render method other than ExecJS, contact justin@shakacode.com
      for details.
      MSG
      raise ReactOnRails::Error, msg
    end

    def ensure_generated_assets_dir_present
      return if generated_assets_dir.present? || ReactOnRails::WebpackerUtils.using_webpacker?

      self.generated_assets_dir = DEFAULT_GENERATED_ASSETS_DIR
      Rails.logger.warn "ReactOnRails: Set generated_assets_dir to default: #{DEFAULT_GENERATED_ASSETS_DIR}"
    end

    def configure_generated_assets_dirs_deprecation
      return if generated_assets_dirs.blank?

      if ReactOnRails::WebpackerUtils.using_webpacker?
        webpacker_public_output_path = ReactOnRails::WebpackerUtils.webpacker_public_output_path
        Rails.logger.warn "Error configuring config/initializers/react_on_rails. Define neither the "\
                          "generated_assets_dirs no the generated_assets_dir when using Webpacker. This is defined by "\
                          "public_output_path specified in webpacker.yml = #{webpacker_public_output_path}."
        return
      end

      Rails.logger.warn "[DEPRECATION] ReactOnRails: Use config.generated_assets_dir rather than "\
                        "generated_assets_dirs"
      if generated_assets_dir.blank?
        self.generated_assets_dir = generated_assets_dirs
      else
        Rails.logger.warn "[DEPRECATION] ReactOnRails. You have both generated_assets_dirs and "\
                          "generated_assets_dir defined. Define ONLY generated_assets_dir if NOT using Webpacker"\
                          " and define neither if using Webpacker"
      end
    end

    def ensure_webpack_generated_files_exists
      return unless webpack_generated_files.empty?

      files = ["manifest.json"]
      files << server_bundle_js_file if server_bundle_js_file.present?

      self.webpack_generated_files = files
    end

    def configure_skip_display_none_deprecation
      return if skip_display_none.nil?

      Rails.logger.warn "[DEPRECATION] ReactOnRails: remove skip_display_none from configuration."
    end

    def raise_missing_components_subdirectory
      msg = <<~MSG
        **ERROR** ReactOnRails: auto_load_bundle is set to true, yet components_subdirectory is unconfigured.\
        Please set components_subdirectory to the desired directory.  For more information, please see \
        https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md
      MSG

      raise ReactOnRails::Error, msg
    end
  end
end
# rubocop:enable Metrics/ClassLength
