# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

module ReactOnRails
  def self.configure
    yield(configuration)
    configuration.setup_config_values
  end

  DEFAULT_GENERATED_ASSETS_DIR = File.join(%w[public webpack], Rails.env).freeze
  DEFAULT_COMPONENT_REGISTRY_TIMEOUT = 5000

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
      server_renderer_pool_size: 1,
      server_renderer_timeout: 20,
      skip_display_none: nil,
      # skip_display_none is deprecated
      webpack_generated_files: %w[manifest.json],
      rendering_extension: nil,
      rendering_props_extension: nil,
      server_render_method: nil,
      build_test_command: "",
      build_production_command: "",
      random_dom_id: true,
      same_bundle_for_client_and_server: false,
      i18n_output_format: nil,
      components_subdirectory: nil,
      make_generated_server_bundle_the_entrypoint: false,
      defer_generated_component_packs: false,
      # React on Rails Pro (licensed) feature - enables immediate hydration of React components
      immediate_hydration: false,
      # Maximum time in milliseconds to wait for client-side component registration after page load.
      # If exceeded, an error will be thrown for server-side rendered components not registered on the client.
      # Set to 0 to disable the timeout and wait indefinitely for component registration.
      component_registry_timeout: DEFAULT_COMPONENT_REGISTRY_TIMEOUT,
      generated_component_packs_loading_strategy: nil,
      server_bundle_output_path: "ssr-generated",
      enforce_private_server_bundles: false
    )
  end

  class Configuration
    attr_accessor :node_modules_location, :server_bundle_js_file, :prerender, :replay_console,
                  :trace, :development_mode, :logging_on_server, :server_renderer_pool_size,
                  :server_renderer_timeout, :skip_display_none, :raise_on_prerender_error,
                  :generated_assets_dirs, :generated_assets_dir, :components_subdirectory,
                  :webpack_generated_files, :rendering_extension, :build_test_command,
                  :build_production_command, :i18n_dir, :i18n_yml_dir, :i18n_output_format,
                  :i18n_yml_safe_load_options, :defer_generated_component_packs,
                  :server_render_method, :random_dom_id, :auto_load_bundle,
                  :same_bundle_for_client_and_server, :rendering_props_extension,
                  :make_generated_server_bundle_the_entrypoint,
                  :generated_component_packs_loading_strategy, :immediate_hydration,
                  :component_registry_timeout,
                  :server_bundle_output_path, :enforce_private_server_bundles

    # rubocop:disable Metrics/AbcSize
    def initialize(node_modules_location: nil, server_bundle_js_file: nil, prerender: nil,
                   replay_console: nil, make_generated_server_bundle_the_entrypoint: nil,
                   trace: nil, development_mode: nil, defer_generated_component_packs: nil,
                   logging_on_server: nil, server_renderer_pool_size: nil,
                   server_renderer_timeout: nil, raise_on_prerender_error: true,
                   skip_display_none: nil, generated_assets_dirs: nil,
                   generated_assets_dir: nil, webpack_generated_files: nil,
                   rendering_extension: nil, build_test_command: nil,
                   build_production_command: nil, generated_component_packs_loading_strategy: nil,
                   same_bundle_for_client_and_server: nil,
                   i18n_dir: nil, i18n_yml_dir: nil, i18n_output_format: nil, i18n_yml_safe_load_options: nil,
                   random_dom_id: nil, server_render_method: nil, rendering_props_extension: nil,
                   components_subdirectory: nil, auto_load_bundle: nil, immediate_hydration: nil,
                   component_registry_timeout: nil, server_bundle_output_path: nil, enforce_private_server_bundles: nil)
      self.node_modules_location = node_modules_location.present? ? node_modules_location : Rails.root
      self.generated_assets_dirs = generated_assets_dirs
      self.generated_assets_dir = generated_assets_dir
      self.build_test_command = build_test_command
      self.build_production_command = build_production_command
      self.i18n_dir = i18n_dir
      self.i18n_yml_dir = i18n_yml_dir
      self.i18n_output_format = i18n_output_format
      self.i18n_yml_safe_load_options = i18n_yml_safe_load_options

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
      self.component_registry_timeout = component_registry_timeout

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
      self.make_generated_server_bundle_the_entrypoint = make_generated_server_bundle_the_entrypoint
      self.defer_generated_component_packs = defer_generated_component_packs
      self.immediate_hydration = immediate_hydration
      self.generated_component_packs_loading_strategy = generated_component_packs_loading_strategy
      self.server_bundle_output_path = server_bundle_output_path
      self.enforce_private_server_bundles = enforce_private_server_bundles
    end
    # rubocop:enable Metrics/AbcSize

    # on ReactOnRails
    def setup_config_values
      check_autobundling_requirements if auto_load_bundle
      ensure_webpack_generated_files_exists
      configure_generated_assets_dirs_deprecation
      configure_skip_display_none_deprecation
      check_server_render_method_is_only_execjs
      error_if_using_packer_and_generated_assets_dir_not_match_public_output_path
      # check_deprecated_settings
      adjust_precompile_task
      check_component_registry_timeout
      validate_generated_component_packs_loading_strategy
      validate_enforce_private_server_bundles
    end

    private

    def check_component_registry_timeout
      self.component_registry_timeout = DEFAULT_COMPONENT_REGISTRY_TIMEOUT if component_registry_timeout.nil?

      return if component_registry_timeout.is_a?(Integer) && component_registry_timeout >= 0

      raise ReactOnRails::Error, "component_registry_timeout must be a positive integer"
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def validate_generated_component_packs_loading_strategy
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      if defer_generated_component_packs
        if %i[async sync].include?(generated_component_packs_loading_strategy)
          Rails.logger.warn "**WARNING** ReactOnRails: config.defer_generated_component_packs is " \
                            "superseded by config.generated_component_packs_loading_strategy"
        else
          Rails.logger.warn "[DEPRECATION] ReactOnRails: Use config." \
                            "generated_component_packs_loading_strategy = :defer rather than " \
                            "defer_generated_component_packs"
          self.generated_component_packs_loading_strategy ||= :defer
        end
      end

      msg = <<~MSG
        ReactOnRails: Your current version of shakapacker \
        does not support async script loading. Please either:
        1. Use :defer or :sync loading strategy instead of :async
        2. Upgrade to Shakapacker v8.2.0 or above to enable async script loading
      MSG
      if PackerUtils.supports_async_loading?
        self.generated_component_packs_loading_strategy ||= :async
      elsif generated_component_packs_loading_strategy.nil?
        # Use defer as the default for older Shakapacker versions to ensure
        # generated component packs load and register components before main bundle executes
        self.generated_component_packs_loading_strategy = :defer
      elsif generated_component_packs_loading_strategy == :async
        raise ReactOnRails::Error, "**ERROR** #{msg}"
      end

      return if %i[async defer sync].include?(generated_component_packs_loading_strategy)

      raise ReactOnRails::Error, "generated_component_packs_loading_strategy must be either :async, :defer, or :sync"
    end

    def validate_enforce_private_server_bundles
      return unless enforce_private_server_bundles

      # Check if server_bundle_output_path is nil
      if server_bundle_output_path.nil?
        raise ReactOnRails::Error, "enforce_private_server_bundles is set to true, but " \
                                   "server_bundle_output_path is nil. Please set server_bundle_output_path " \
                                   "to a directory outside of the public directory."
      end

      # Check if server_bundle_output_path is inside public directory
      # Skip validation if Rails.root is not available (e.g., in tests)
      return unless defined?(Rails) && Rails.root

      public_path = Rails.root.join("public").to_s
      server_output_path = File.expand_path(server_bundle_output_path, Rails.root.to_s)

      return unless server_output_path.start_with?(public_path)

      raise ReactOnRails::Error, "enforce_private_server_bundles is set to true, but " \
                                 "server_bundle_output_path (#{server_bundle_output_path}) is inside " \
                                 "the public directory. Please set it to a directory outside of public."
    end

    def check_minimum_shakapacker_version
      ReactOnRails::PackerUtils.raise_shakapacker_version_incompatible_for_basic_pack_generation unless
        ReactOnRails::PackerUtils.supports_basic_pack_generation?
    end

    def check_autobundling_requirements
      raise_missing_components_subdirectory unless components_subdirectory.present?

      ReactOnRails::PackerUtils.raise_shakapacker_version_incompatible_for_autobundling unless
        ReactOnRails::PackerUtils.supports_autobundling?
      ReactOnRails::PackerUtils.raise_nested_entries_disabled unless ReactOnRails::PackerUtils.nested_entries?
    end

    def adjust_precompile_task
      skip_react_on_rails_precompile = %w[no false n f].include?(ENV.fetch("REACT_ON_RAILS_PRECOMPILE", nil))

      return if skip_react_on_rails_precompile || build_production_command.blank?

      raise(ReactOnRails::Error, compile_command_conflict_message) if ReactOnRails::PackerUtils.precompile?

      precompile_tasks = lambda {
        # Skip generate_packs if shakapacker has a precompile hook configured
        if ReactOnRails::PackerUtils.shakapacker_precompile_hook_configured?
          hook_value = ReactOnRails::PackerUtils.shakapacker_precompile_hook_value
          puts "Skipping react_on_rails:generate_packs (configured in shakapacker precompile hook: #{hook_value})"
        else
          Rake::Task["react_on_rails:generate_packs"].invoke
        end

        Rake::Task["react_on_rails:assets:webpack"].invoke

        # VERSIONS is per the shakacode/shakapacker clean method definition.
        # We set it very big so that it is not used, and then clean just
        # removes files older than 1 hour.
        versions = 100_000
        puts "Invoking task shakapacker:clean from React on Rails"
        Rake::Task["shakapacker:clean"].invoke(versions)
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

    def error_if_using_packer_and_generated_assets_dir_not_match_public_output_path
      return if generated_assets_dir.blank?

      packer_public_output_path = ReactOnRails::PackerUtils.packer_public_output_path

      if File.expand_path(generated_assets_dir) == packer_public_output_path.to_s
        Rails.logger.warn("You specified generated_assets_dir in `config/initializers/react_on_rails.rb` " \
                          "with Shakapacker. " \
                          "Remove this line from your configuration file.")
      else
        msg = <<~MSG
          Error configuring /config/initializers/react_on_rails.rb: You are using Shakapacker
          and your specified value for generated_assets_dir = #{generated_assets_dir}
          that does not match the value for public_output_path specified in
          shakapacker.yml = #{packer_public_output_path}. You should remove the configuration
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

    def configure_generated_assets_dirs_deprecation
      return if generated_assets_dirs.blank?

      packer_public_output_path = ReactOnRails::PackerUtils.packer_public_output_path

      msg = <<~MSG
        ReactOnRails Configuration Warning: The 'generated_assets_dirs' configuration option is no longer supported.
        Since Shakapacker is now required, public asset paths are automatically determined from your shakapacker.yml configuration.
        Please remove 'config.generated_assets_dirs' from your config/initializers/react_on_rails.rb file.
        Public assets will be loaded from: #{packer_public_output_path}
        If you need to customize the public output path, configure it in config/shakapacker.yml under 'public_output_path'.
        Note: Private server bundles are configured separately via server_bundle_output_path.
      MSG

      Rails.logger.warn msg
    end

    def ensure_webpack_generated_files_exists
      return unless webpack_generated_files.empty?

      self.webpack_generated_files = [
        "manifest.json",
        server_bundle_js_file,
        rsc_bundle_js_file,
        react_client_manifest_file,
        react_server_client_manifest_file
      ].compact_blank
    end

    def configure_skip_display_none_deprecation
      return if skip_display_none.nil?

      Rails.logger.warn "[DEPRECATION] ReactOnRails: remove skip_display_none from configuration."
    end

    def raise_missing_components_subdirectory
      msg = <<~MSG
        **ERROR** ReactOnRails: auto_load_bundle is set to true, yet components_subdirectory is not configured.\
        Please set components_subdirectory to the desired directory.  For more information, please see \
        https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md
      MSG

      raise ReactOnRails::Error, msg
    end

    def compile_command_conflict_message
      <<~MSG

        React on Rails and Shakapacker error in configuration!
        In order to use config/react_on_rails.rb config.build_production_command,
        you must edit config/shakapacker.yml to include this value in the default configuration:
        'shakapacker_precompile: false'

        Alternatively, remove the config/react_on_rails.rb config.build_production_command and the
        default bin/shakapacker script will be used for assets:precompile.

      MSG
    end
  end
end
# rubocop:enable Metrics/ClassLength
