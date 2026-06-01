# frozen_string_literal: true

require "json"

# rubocop:disable Metrics/ModuleLength
module GeneratorHelper
  def package_json
    # Lazy load package_json gem only when actually needed for dependency management

    require "package_json" unless defined?(PackageJson)
    @package_json ||= PackageJson.read
  rescue LoadError
    unless @package_json_unavailable_warned
      say_status :warning, "package_json gem not available. This is expected before Shakapacker installation.", :yellow
      say_status :warning, "Dependencies will be installed using the default package manager after Shakapacker setup.",
                 :yellow
      @package_json_unavailable_warned = true
    end
    nil
  rescue StandardError => e
    say_status :warning, "Could not read package.json: #{e.message}", :yellow
    say_status :warning, "This is normal before Shakapacker creates the package.json file.", :yellow
    nil
  end

  # Safe wrapper for package_json operations
  def add_npm_dependencies(packages, dev: false)
    pj = package_json
    return false unless pj

    begin
      result = if dev
                 pj.manager.add(packages, type: :dev, exact: true)
               else
                 pj.manager.add(packages, exact: true)
               end
      # package_json#add can return nil for successful side-effect operations.
      result != false
    rescue StandardError => e
      say_status :warning, "Could not add packages via package_json gem: #{e.message}", :yellow
      say_status :warning, "Will fall back to direct npm commands.", :yellow
      false
    end
  end

  # Detect whether config/routes.rb defines any non-commented root route.
  #
  # @param routes_path [String] absolute path to routes.rb
  # @return [Boolean] true when a root route exists
  def root_route_present?(routes_path = File.join(destination_root, "config/routes.rb"))
    return false unless File.file?(routes_path)

    File.foreach(routes_path).any? do |line|
      !line.match?(/^\s*#/) && line.match?(/^\s*root\b/)
    end
  end

  def add_documentation_reference(message, source)
    "#{message} \n#{source}"
  end

  def print_generator_messages
    # GeneratorMessages stores pre-colored strings, so we strip ANSI manually for --no-color output.
    no_color = !shell.is_a?(Thor::Shell::Color)
    GeneratorMessages.messages.each do |message|
      say(no_color ? message.to_s.gsub(/\e\[[0-9;]*m/, "") : message)
      say "" # Blank line after each message for readability
    end
  end

  def component_extension(options)
    options.typescript? ? "tsx" : "jsx"
  end

  # Check if a gem is present in Gemfile.lock
  # Always checks the target app's Gemfile.lock, not inherited BUNDLE_GEMFILE
  # See: https://github.com/shakacode/react_on_rails/issues/2287
  #
  # @param gem_name [String] Name of the gem to check
  # @return [Boolean] true if the gem is in Gemfile.lock
  def gem_in_lockfile?(gem_name)
    File.file?("Gemfile.lock") &&
      File.foreach("Gemfile.lock").any? { |line| line.match?(/^\s{4}#{Regexp.escape(gem_name)}\s\(/) }
  rescue StandardError
    false
  end

  # Check if React on Rails Pro gem is installed (real state — never "scheduled to be installed").
  #
  # Detection priority:
  # 1. Gem.loaded_specs - gem is loaded in current Ruby process (most reliable)
  # 2. Gemfile.lock - gem is resolved and installed
  #
  # Use {#pro_gem_install_deferred?} for the broader "present, or will be installed by this
  # generator run" meaning. Use {#invalidate_pro_gem_installed_cache!} after an operation
  # that changes real state (e.g., bundle add) so the next call re-reads the lockfile.
  #
  # @return [Boolean] true if react_on_rails_pro gem is installed
  def pro_gem_installed?
    return @pro_gem_installed if defined?(@pro_gem_installed)

    @pro_gem_installed = Gem.loaded_specs.key?("react_on_rails_pro") || gem_in_lockfile?("react_on_rails_pro")
  end

  # Check if Pro features should be enabled.
  # Returns true if --pro or --rsc is set (RSC implies Pro).
  #
  # @return [Boolean] true if Pro setup should be included
  def use_pro?
    options[:pro] || options[:rsc]
  end

  # Check if RSC (React Server Components) should be enabled.
  # Returns true if --rsc is set.
  #
  # @return [Boolean] true if RSC setup should be included
  def use_rsc?
    options[:rsc]
  end

  # Determine if the project is using rspack as the bundler.
  #
  # Detection priority:
  # 1. Explicit --rspack option (most reliable during fresh installs)
  # 2. config/shakapacker.yml assets_bundler setting (for standalone generators
  #    like `rails g react_on_rails:rsc` on an existing rspack project)
  #
  # @return [Boolean] true if rspack is the configured bundler
  def using_rspack?
    return @using_rspack if defined?(@using_rspack)

    # An explicit bundler flag always wins. When none was passed (or the generator doesn't
    # declare the flags, e.g. RscGenerator/ProGenerator), fall back to the bundler default,
    # which each generator defines for its own context.
    explicit = explicit_bundler_choice
    @using_rspack = explicit.nil? ? rspack_bundler_default : explicit
  end

  # Resolve the explicit bundler flags into a single choice.
  #
  # --rspack selects Rspack; --no-rspack and --webpack select Webpack (--webpack is a friendly
  # alias for --no-rspack, and the auto-generated --no-webpack mirrors --rspack). Returns true
  # for Rspack, false for Webpack, or nil when no bundler flag was passed (so the caller falls
  # back to rspack_bundler_default).
  #
  # IMPORTANT: this relies on Thor NOT including a nil-defaulted option in the hash when the flag
  # is absent — options.key?(:rspack)/(:webpack) is true only when the user passed that flag.
  # Re-adding `default:` to either class_option would make the key always present and break both
  # the "no flag given" fallback and the conflict detection here.
  # (Thor's omit-when-no-default behavior verified against Thor 1.5.0; see Gemfile.lock.)
  #
  # Passing contradictory flags (e.g. --rspack --webpack) raises a Thor::Error.
  def explicit_bundler_choice
    choices = []
    choices << options[:rspack] if options.key?(:rspack)
    # --webpack means "use Webpack" (rspack = false); --no-webpack means "use Rspack".
    # Name the inverted webpack flag so the rspack-boolean intent reads directly.
    rspack_via_webpack_flag = !options[:webpack]
    choices << rspack_via_webpack_flag if options.key?(:webpack)
    return nil if choices.empty?

    if choices.uniq.length > 1
      raise Thor::Error,
            "Conflicting bundler flags: pass either Rspack (--rspack) or Webpack " \
            "(--webpack / --no-rspack), not both."
    end

    choices.first
  end

  # True when the user passed any explicit bundler flag
  # (--rspack/--no-rspack/--webpack/--no-webpack).
  def bundler_flag_given?
    options.key?(:rspack) || options.key?(:webpack)
  end

  # Bundler to use when no explicit bundler flag was passed.
  # Default (standalone generators like RscGenerator/ProGenerator): respect the existing
  # project's shakapacker.yml and never impose a bundler. InstallGenerator/BaseGenerator
  # override this to default fresh installs to Rspack.
  def rspack_bundler_default
    rspack_configured_in_project?
  end

  # Remap a config path from config/webpack/ to config/rspack/ when using rspack.
  # Source templates always live under config/webpack/ (template names are stable);
  # this method handles the destination remapping.
  #
  # @param path [String] relative path, e.g. "config/webpack/serverWebpackConfig.js"
  # @return [String] remapped path when rspack, unchanged otherwise
  def destination_config_path(path)
    return path unless using_rspack?

    path.sub(%r{\Aconfig/webpack/}, "config/rspack/")
  end

  # Detect the installed React version from package.json
  # Uses VERSION_PARTS_REGEX pattern from VersionChecker for consistency
  #
  # @return [String, nil] React version string (e.g., "19.0.3") or nil if not found/parseable
  def detect_react_version
    pj = package_json
    return nil unless pj

    dependencies = pj.fetch("dependencies", {})
    react_version = dependencies["react"]
    return nil unless react_version

    # Skip non-version strings (workspace:*, file:, link:, http://, etc.)
    return nil if react_version.include?("/") || react_version.start_with?("workspace:")

    # Extract version using the same regex pattern as VersionChecker
    # Handles: "19.0.3", "^19.0.3", "~19.0.3", "19.0.3-beta.1", etc.
    match = react_version.match(/(\d+)\.(\d+)\.(\d+)(?:[-.]([0-9A-Za-z.-]+))?/)
    return nil unless match

    # Return the matched version (without pre-release suffix for comparison)
    "#{match[1]}.#{match[2]}.#{match[3]}"
  rescue StandardError
    nil
  end

  # Check if Shakapacker 9.0 or higher is available
  # Returns true if Shakapacker >= 9.0, false otherwise
  #
  # This method is used during code generation to determine which configuration
  # patterns to use in generated files (e.g., config.privateOutputPath vs hardcoded paths).
  #
  # @return [Boolean] true if Shakapacker 9.0+ is available or likely to be installed
  #
  # @note Default behavior: Returns true when Shakapacker is not yet installed
  #   Rationale: During fresh installations, we optimistically assume users will install
  #   the latest Shakapacker version. This ensures new projects get best-practice configs.
  #   If users later install an older version, the generated webpack config includes
  #   fallback logic (e.g., `config.privateOutputPath || hardcodedPath`) that prevents
  #   breakage, and validation warnings guide them to fix any misconfigurations.
  def shakapacker_version_9_or_higher?
    return @shakapacker_version_9_or_higher if defined?(@shakapacker_version_9_or_higher)

    @shakapacker_version_9_or_higher = begin
      # If Shakapacker is not available yet (fresh install), default to true
      # since we're likely installing the latest version
      return true unless defined?(ReactOnRails::PackerUtils)

      ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")
    rescue StandardError
      # If we can't determine version, assume latest
      true
    end
  end

  # Check if SWC is configured as the JavaScript transpiler in shakapacker.yml
  #
  # @return [Boolean] true if SWC is configured or should be used by default
  #
  # Detection logic:
  # 1. If shakapacker.yml exists and specifies javascript_transpiler: parse it
  # 2. For Shakapacker 9.3.0+, SWC is the default if not specified
  # 3. Returns true for fresh installations (SWC is recommended default)
  #
  # @note This method is used to determine whether to install SWC dependencies
  #   (@swc/core, swc-loader) instead of Babel dependencies during generation.
  #
  # @note Caching: The result is memoized for the lifetime of the generator instance.
  #   If shakapacker.yml changes during generator execution (unlikely), the cached
  #   value will not update. This is acceptable since generators run quickly.
  def using_swc?
    return @using_swc if defined?(@using_swc)

    @using_swc = detect_swc_configuration
  end

  # Resolve the path to ServerClientOrBoth.js, handling the legacy name.
  # Old installs may still use generateWebpackConfigs.js; this renames it
  # and updates references in environment configs so downstream transforms
  # can rely on the canonical name.
  #
  # @return [String, nil] relative config path, or nil if neither file exists
  def resolve_server_client_or_both_path
    new_path = destination_config_path("config/webpack/ServerClientOrBoth.js")
    old_path = destination_config_path("config/webpack/generateWebpackConfigs.js")
    full_new = File.join(destination_root, new_path)
    full_old = File.join(destination_root, old_path)

    if File.exist?(full_new)
      new_path
    elsif File.exist?(full_old)
      FileUtils.mv(full_old, full_new)
      %w[development.js production.js test.js].each do |env_file|
        env_path = destination_config_path("config/webpack/#{env_file}")
        if File.exist?(File.join(destination_root, env_path))
          gsub_file(env_path, /generateWebpackConfigs/, "ServerClientOrBoth")
        end
      end
      new_path
    end
  end

  private

  # Clear the memoized {#pro_gem_installed?} result so the next call re-checks
  # Gem.loaded_specs / Gemfile.lock. Call after any operation that may change real state.
  def invalidate_pro_gem_installed_cache!
    remove_instance_variable(:@pro_gem_installed) if defined?(@pro_gem_installed)
  end

  # True when a later step in this generator run will install the Pro gem
  # (e.g., the Gemfile swap performed by ProGenerator). Distinct from
  # {#pro_gem_installed?}, which only reports real present state.
  def pro_gem_install_deferred?
    @pro_gem_install_deferred == true
  end

  # Record that a later step in this generator run will install the Pro gem.
  def defer_pro_gem_install!
    @pro_gem_install_deferred = true
  end

  # NOTE: only the `default:` section is inspected — same assumption as
  # rspack_configured_in_project?. Projects that set `javascript_transpiler`
  # only in per-environment sections (without a `default:` block) will not be
  # detected. In practice Shakapacker always places it in `default: &default`.
  def detect_swc_configuration
    shakapacker_yml_path = File.join(destination_root, "config/shakapacker.yml")

    if File.exist?(shakapacker_yml_path)
      config = parse_shakapacker_yml(shakapacker_yml_path)
      transpiler = config.dig("default", "javascript_transpiler")

      # Explicit configuration takes precedence
      return transpiler == "swc" if transpiler

      # For Shakapacker 9.3.0+, SWC is the default
      return shakapacker_version_9_3_or_higher?
    end

    # Fresh install: SWC is recommended default for Shakapacker 9.3.0+
    shakapacker_version_9_3_or_higher?
  end

  def parse_shakapacker_yml(path)
    require "yaml"
    # Use safe_load_file for security (defense-in-depth, even though this is user's own config)
    # permitted_classes: [Symbol] allows symbol keys which shakapacker.yml may use
    # aliases: true allows YAML anchors (&default, *default) commonly used in Rails configs
    YAML.safe_load_file(path, permitted_classes: [Symbol], aliases: true)
  rescue ArgumentError
    # Older Psych versions don't support all parameters - try without aliases
    begin
      YAML.safe_load_file(path, permitted_classes: [Symbol])
    rescue ArgumentError
      # Very old Psych - fall back to safe_load with File.read
      YAML.safe_load(File.read(path), permitted_classes: [Symbol]) # rubocop:disable Style/YAMLFileRead
    end
  rescue StandardError
    # If we can't parse the file, return empty config
    {}
  end

  # Check if Shakapacker 9.3.0 or higher is available
  # This version made SWC the default JavaScript transpiler
  def shakapacker_version_9_3_or_higher?
    return true unless defined?(ReactOnRails::PackerUtils)

    ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.3.0")
  rescue StandardError
    # If we can't determine version, assume latest (which uses SWC)
    true
  end

  # Detect rspack from config/shakapacker.yml when no explicit --rspack option is available.
  # Used by standalone generators (RscGenerator, ProGenerator) on existing projects.
  #
  # Note: only the `default:` section is inspected. Projects that set `assets_bundler`
  # only in per-environment sections (without a `default:` block) will not be detected.
  # This is not a concern in practice: Shakapacker's install template always places
  # `assets_bundler` inside the `default: &default` block, and our generator writes
  # it there too via configure_rspack_in_shakapacker.
  def rspack_configured_in_project?
    shakapacker_assets_bundler_value == "rspack"
  end

  # Fresh-install bundler default used by InstallGenerator/BaseGenerator: prefer Rspack
  # when Shakapacker supports it (Rspack landed in Shakapacker 9.0), but never override an
  # existing app's explicit assets_bundler choice. On a brand-new install where Shakapacker
  # isn't loaded yet, shakapacker_version_9_or_higher? optimistically returns true.
  def fresh_install_rspack_default
    return rspack_configured_in_project? if project_declares_assets_bundler?

    shakapacker_version_9_or_higher?
  end

  # True when config/shakapacker.yml exists and its default: section declares an
  # assets_bundler (i.e., the project has already made an explicit bundler choice).
  def project_declares_assets_bundler?
    !shakapacker_assets_bundler_value.nil?
  end

  # Single source for the config/shakapacker.yml default-section read shared by
  # rspack_configured_in_project? and project_declares_assets_bundler?. Returns the
  # assets_bundler value (e.g. "rspack"), or nil when the file is absent or the key is unset.
  # Only the default: section is inspected (see rspack_configured_in_project? for the rationale).
  def shakapacker_assets_bundler_value
    shakapacker_yml_path = File.join(destination_root, "config/shakapacker.yml")
    return nil unless File.exist?(shakapacker_yml_path)

    parse_shakapacker_yml(shakapacker_yml_path).dig("default", "assets_bundler")
  end
end
# rubocop:enable Metrics/ModuleLength
