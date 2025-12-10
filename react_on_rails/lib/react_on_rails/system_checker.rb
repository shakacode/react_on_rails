# frozen_string_literal: true

require "open3"

module ReactOnRails
  # SystemChecker provides validation methods for React on Rails setup
  # Used by install generator and doctor rake task
  # rubocop:disable Metrics/ClassLength
  class SystemChecker
    attr_reader :messages

    def initialize
      @messages = []
    end

    def add_error(message)
      @messages << { type: :error, content: message }
    end

    def add_warning(message)
      @messages << { type: :warning, content: message }
    end

    def add_success(message)
      @messages << { type: :success, content: message }
    end

    def add_info(message)
      @messages << { type: :info, content: message }
    end

    def errors?
      @messages.any? { |msg| msg[:type] == :error }
    end

    def warnings?
      @messages.any? { |msg| msg[:type] == :warning }
    end

    # Node.js validation
    def check_node_installation
      if node_missing?
        add_error(<<~MSG.strip)
          🚫 Node.js is required but not found on your system.

          Please install Node.js before continuing:
          • Download from: https://nodejs.org/en/
          • Recommended: Use a version manager like nvm, fnm, or volta
          • Minimum required version: Node.js 18+

          After installation, restart your terminal and try again.
        MSG
        return false
      end

      check_node_version
      true
    end

    def check_node_version
      stdout, stderr, status = Open3.capture3("node", "--version")

      # Use stdout if available, fallback to stderr if stdout is empty
      node_version = stdout.strip
      node_version = stderr.strip if node_version.empty?

      # Return early if node is not found (non-zero status) or no output
      return if !status.success? || node_version.empty?

      # Extract major version number (e.g., "v18.17.0" -> 18)
      major_version = node_version[/v(\d+)/, 1]&.to_i
      return unless major_version

      if major_version < 18
        add_warning(<<~MSG.strip)
          ⚠️  Node.js version #{node_version} detected.

          React on Rails recommends Node.js 18+ for best compatibility.
          You may experience issues with older versions.

          Consider upgrading: https://nodejs.org/en/
        MSG
      else
        add_success("✅ Node.js #{node_version} is installed and compatible")
      end
    end

    # Package manager validation
    def check_package_manager
      package_managers = %w[npm pnpm yarn bun]
      available_managers = package_managers.select { |pm| cli_exists?(pm) }

      if available_managers.empty?
        add_error(<<~MSG.strip)
          🚫 No JavaScript package manager found on your system.

          React on Rails requires a JavaScript package manager to install dependencies.
          Please install one of the following:

          • npm: Usually comes with Node.js (https://nodejs.org/en/)
          • yarn: npm install -g yarn (https://yarnpkg.com/)
          • pnpm: npm install -g pnpm (https://pnpm.io/)
          • bun: Install from https://bun.sh/

          After installation, restart your terminal and try again.
        MSG
        return false
      end

      # Detect which package manager is actually being used
      used_manager = detect_used_package_manager
      if used_manager
        version_info = get_package_manager_version(used_manager)
        deprecation_note = get_deprecation_note(used_manager, version_info)
        message = "✅ Package manager in use: #{used_manager} #{version_info}"
        message += deprecation_note if deprecation_note
        add_success(message)
      else
        add_success("✅ Package managers available: #{available_managers.join(', ')}")
        add_info("ℹ️  No lock file detected - run npm/yarn/pnpm install to establish which manager is used")
      end
      true
    end

    # Shakapacker validation
    def check_shakapacker_configuration
      unless shakapacker_configured?
        add_error(<<~MSG.strip)
          🚫 Shakapacker is not properly configured.

          Missing one or more required files:
          • bin/shakapacker
          • bin/shakapacker-dev-server
          • config/shakapacker.yml
          • config/webpack/webpack.config.js

          Run: bundle exec rails shakapacker:install
        MSG
        return false
      end

      report_shakapacker_version_with_threshold
      check_shakapacker_in_gemfile
      true
    end

    def check_shakapacker_in_gemfile
      if shakapacker_in_gemfile?
        add_success("✅ Shakapacker is declared in Gemfile")
      else
        add_warning(<<~MSG.strip)
          ⚠️  Shakapacker not found in Gemfile.

          While Shakapacker might be available as a dependency,
          it's recommended to add it explicitly to your Gemfile:

          bundle add shakapacker --strict
        MSG
      end
    end

    # React on Rails package validation
    def check_react_on_rails_packages
      check_react_on_rails_gem
      check_react_on_rails_npm_package
      check_package_version_sync
      check_gemfile_version_patterns
    end

    def check_react_on_rails_gem
      require "react_on_rails"
      add_success("✅ React on Rails gem #{ReactOnRails::VERSION} is loaded")
    rescue LoadError
      add_error(<<~MSG.strip)
        🚫 React on Rails gem is not available.

        Add to your Gemfile:
        gem 'react_on_rails'

        Then run: bundle install
      MSG
    end

    def check_react_on_rails_npm_package
      package_json_path = "package.json"
      return unless File.exist?(package_json_path)

      package_json = JSON.parse(File.read(package_json_path))
      npm_version = package_json.dig("dependencies", "react-on-rails") ||
                    package_json.dig("devDependencies", "react-on-rails")

      if npm_version
        add_success("✅ react-on-rails NPM package #{npm_version} is declared")
      else
        add_warning(<<~MSG.strip)
          ⚠️  react-on-rails NPM package not found in package.json.

          Install it with:
          npm install react-on-rails
        MSG
      end
    rescue JSON::ParserError
      add_warning("⚠️  Could not parse package.json")
    end

    def check_package_version_sync
      return unless File.exist?("package.json")

      begin
        package_json = JSON.parse(File.read("package.json"))
        npm_version = package_json.dig("dependencies", "react-on-rails") ||
                      package_json.dig("devDependencies", "react-on-rails")

        return unless npm_version && defined?(ReactOnRails::VERSION)

        # Normalize NPM version format to Ruby gem format for comparison
        # Uses existing VersionSyntaxConverter to handle dash/dot differences
        # (e.g., "16.2.0-beta.10" → "16.2.0.beta.10")
        converter = ReactOnRails::VersionSyntaxConverter.new
        normalized_npm_version = converter.npm_to_rubygem(npm_version)
        gem_version = ReactOnRails::VERSION

        if normalized_npm_version == gem_version
          add_success("✅ React on Rails gem and NPM package versions match (#{gem_version})")
          check_version_patterns(npm_version, gem_version)
        else
          # Check for major version differences
          gem_major = gem_version.split(".")[0].to_i
          npm_major = normalized_npm_version.split(".")[0].to_i

          if gem_major != npm_major # rubocop:disable Style/NegatedIfElseCondition
            add_error(<<~MSG.strip)
              🚫 Major version mismatch detected:
              • Gem version: #{gem_version} (major: #{gem_major})
              • NPM version: #{npm_version} (major: #{npm_major})

              Major version differences can cause serious compatibility issues.
              Update both packages to use the same major version immediately.
            MSG
          else
            add_warning(<<~MSG.strip)
              ⚠️  Version mismatch detected:
              • Gem version: #{gem_version}
              • NPM version: #{npm_version}

              Consider updating to exact, fixed matching versions of gem and npm package for best compatibility.
            MSG
          end
        end
      rescue JSON::ParserError
        # Ignore parsing errors, already handled elsewhere
      rescue StandardError
        # Handle other errors gracefully
      end
    end

    # React dependencies validation
    def check_react_dependencies
      return unless File.exist?("package.json")

      package_json = parse_package_json
      return unless package_json

      # Check core React dependencies
      required_deps = required_react_dependencies
      missing_deps = find_missing_dependencies(package_json, required_deps)
      report_dependency_status(required_deps, missing_deps, package_json)

      # Check additional build dependencies (informational)
      check_build_dependencies(package_json)

      # Report versions
      report_dependency_versions(package_json)
    end

    # Rails integration validation

    def check_react_on_rails_initializer
      initializer_path = "config/initializers/react_on_rails.rb"
      if File.exist?(initializer_path)
        add_success("✅ React on Rails initializer exists")
      else
        add_warning(<<~MSG.strip)
          ⚠️  React on Rails initializer not found.

          Create: config/initializers/react_on_rails.rb
          Or run: rails generate react_on_rails:install
        MSG
      end
    end

    # Webpack configuration validation
    def check_webpack_configuration
      webpack_config_path = "config/webpack/webpack.config.js"
      if File.exist?(webpack_config_path)
        add_success("✅ Webpack configuration exists")
        check_webpack_config_content
        suggest_webpack_inspection
      else
        add_error(<<~MSG.strip)
          🚫 Webpack configuration not found.

          Expected: config/webpack/webpack.config.js
          Run: rails generate react_on_rails:install
        MSG
      end
    end

    def suggest_webpack_inspection
      add_info("💡 To debug webpack builds:")
      add_info("    bin/shakapacker --mode=development --progress")
      add_info("    bin/shakapacker --mode=production --progress")
      add_info("    bin/shakapacker --debug-shakapacker  # Debug Shakapacker configuration")

      add_info("💡 Advanced webpack debugging:")
      add_info("    1. Add 'debugger;' before 'module.exports' in config/webpack/webpack.config.js")
      add_info("    2. Run: ./bin/shakapacker --debug-shakapacker")
      add_info("    3. Open Chrome DevTools to inspect config object")
      add_info("    📖 See: https://github.com/shakacode/shakapacker/blob/main/docs/troubleshooting.md#debugging-your-webpack-config")

      add_info("💡 To analyze bundle size:")
      if bundle_analyzer_available?
        add_info("    ANALYZE=true bin/shakapacker")
        add_info("    This opens webpack-bundle-analyzer in your browser")
      else
        add_info("    1. yarn add --dev webpack-bundle-analyzer")
        add_info("    2. Add to config/webpack/webpack.config.js:")
        add_info("       const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');")
        add_info("       // Add to plugins array when process.env.ANALYZE")
        add_info("    3. ANALYZE=true bin/shakapacker")
        add_info("    Or use Shakapacker's built-in support if available")
      end

      add_info("💡 Generate webpack stats for analysis:")
      add_info("    bin/shakapacker --json > webpack-stats.json")
      add_info("    Upload to webpack.github.io/analyse or webpack-bundle-analyzer.com")
    end

    def bundle_analyzer_available?
      return false unless File.exist?("package.json")

      begin
        package_json = JSON.parse(File.read("package.json"))
        all_deps = package_json["dependencies"]&.merge(package_json["devDependencies"] || {}) || {}
        all_deps["webpack-bundle-analyzer"]
      rescue StandardError
        false
      end
    end

    def check_webpack_config_content
      webpack_config_path = "config/webpack/webpack.config.js"
      content = File.read(webpack_config_path)

      if react_on_rails_config?(content)
        add_success("✅ Webpack config includes React on Rails environment configuration")
        add_info("    ℹ️  Environment-specific configs detected for optimal React on Rails integration")
      elsif standard_shakapacker_config?(content)
        add_warning(<<~MSG.strip)
          ⚠️  Standard Shakapacker webpack config detected.

          React on Rails works better with environment-specific configuration.
          Consider running: rails generate react_on_rails:install --force
          This adds client and server environment configs for better performance.
        MSG
      else
        add_info("ℹ️  Custom webpack config detected")
        add_info("    💡 Ensure config supports both client and server rendering")
        add_info("    💡 Verify React JSX transformation is configured")
        add_info("    💡 Check that asset output paths match Rails expectations")
      end
    end

    private

    def node_missing?
      command = ReactOnRails::Utils.running_on_windows? ? "where" : "which"
      _stdout, _stderr, status = Open3.capture3(command, "node")
      !status.success?
    end

    def cli_exists?(command)
      which_command = ReactOnRails::Utils.running_on_windows? ? "where" : "which"
      _stdout, _stderr, status = Open3.capture3(which_command, command)
      status.success?
    end

    def detect_used_package_manager
      # Check for lock files to determine which package manager is being used
      if File.exist?("yarn.lock")
        "yarn"
      elsif File.exist?("pnpm-lock.yaml")
        "pnpm"
      elsif File.exist?("bun.lockb")
        "bun"
      elsif File.exist?("package-lock.json")
        "npm"
      end
    end

    def get_package_manager_version(manager)
      begin
        stdout, _stderr, status = Open3.capture3(manager, "--version")
        return stdout.strip if status.success? && !stdout.strip.empty?
      rescue StandardError
        # Ignore errors
      end
      "(version unknown)"
    end

    def get_deprecation_note(manager, version)
      case manager
      when "yarn"
        " (Classic Yarn v1 - consider upgrading to Yarn Modern)" if /^1\./.match?(version)
      end
    end

    def shakapacker_configured?
      File.exist?("bin/shakapacker") &&
        File.exist?("bin/shakapacker-dev-server") &&
        File.exist?("config/shakapacker.yml") &&
        File.exist?("config/webpack/webpack.config.js")
    end

    def shakapacker_in_gemfile?
      gemfile = ENV["BUNDLE_GEMFILE"] || "Gemfile"
      File.file?(gemfile) &&
        File.foreach(gemfile).any? { |l| l.match?(/^\s*gem\s+['"]shakapacker['"]/) }
    end

    def react_on_rails_config?(content)
      content.include?("envSpecificConfig") || content.include?("env.nodeEnv")
    end

    def standard_shakapacker_config?(content)
      normalized = normalize_config_content(content)
      shakapacker_patterns = [
        /generateWebpackConfig.*require.*shakapacker/,
        /webpackConfig.*require.*shakapacker/
      ]
      shakapacker_patterns.any? { |pattern| normalized.match?(pattern) }
    end

    def normalize_config_content(content)
      content.gsub(%r{//.*$}, "")                    # Remove single-line comments
             .gsub(%r{/\*.*?\*/}m, "")               # Remove multi-line comments
             .gsub(/\s+/, " ")                       # Normalize whitespace
             .strip
    end

    def required_react_dependencies
      {
        "react" => "React library",
        "react-dom" => "React DOM library",
        "@babel/preset-react" => "Babel React preset"
      }
    end

    def additional_build_dependencies
      {
        "webpack" => "Webpack bundler",
        "@babel/core" => "Babel compiler core",
        "@babel/preset-env" => "Babel environment preset",
        "css-loader" => "CSS loader for Webpack",
        "style-loader" => "Style loader for Webpack",
        "mini-css-extract-plugin" => "CSS extraction plugin",
        "webpack-dev-server" => "Webpack development server"
      }
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def check_build_dependencies(package_json)
      build_deps = additional_build_dependencies
      all_deps = package_json["dependencies"]&.merge(package_json["devDependencies"] || {}) || {}

      present_deps = []
      missing_deps = []

      build_deps.each do |package, description|
        if all_deps[package]
          present_deps << "#{description} (#{package})"
        else
          missing_deps << "#{description} (#{package})"
        end
      end

      unless present_deps.empty?
        short_list = present_deps.take(3).join(", ")
        suffix = present_deps.length > 3 ? "..." : ""
        add_info("✅ Build dependencies found: #{short_list}#{suffix}")
      end

      return if missing_deps.empty?

      short_list = missing_deps.take(3).join(", ")
      suffix = missing_deps.length > 3 ? "..." : ""
      add_info("ℹ️  Optional build dependencies: #{short_list}#{suffix}")
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def parse_package_json
      JSON.parse(File.read("package.json"))
    rescue JSON::ParserError
      add_warning("⚠️  Could not parse package.json to check React dependencies")
      nil
    end

    def find_missing_dependencies(package_json, required_deps)
      all_deps = package_json["dependencies"]&.merge(package_json["devDependencies"] || {}) || {}
      required_deps.keys.reject { |dep| all_deps[dep] }
    end

    def report_dependency_status(required_deps, missing_deps, package_json)
      all_deps = package_json["dependencies"]&.merge(package_json["devDependencies"] || {}) || {}

      required_deps.each do |dep, description|
        add_success("✅ #{description} (#{dep}) is installed") if all_deps[dep]
      end

      return unless missing_deps.any?

      add_warning(<<~MSG.strip)
        ⚠️  Missing React dependencies: #{missing_deps.join(', ')}

        Install them with:
        npm install #{missing_deps.join(' ')}
      MSG
    end

    def check_version_patterns(npm_version, gem_version)
      # Check for version range patterns in package.json
      return unless /^[\^~]/.match?(npm_version)

      pattern_type = npm_version[0] == "^" ? "caret (^)" : "tilde (~)"
      add_warning(<<~MSG.strip)
        ⚠️  NPM package uses #{pattern_type} version pattern: #{npm_version}

        While versions match, consider using exact version "#{gem_version}" in package.json
        for guaranteed compatibility with the React on Rails gem.
      MSG
    end

    def check_gemfile_version_patterns
      gemfile_path = ENV["BUNDLE_GEMFILE"] || "Gemfile"
      return unless File.exist?(gemfile_path)

      begin
        gemfile_content = File.read(gemfile_path)
        react_on_rails_line = gemfile_content.lines.find { |line| line.match(/^\s*gem\s+['"]react_on_rails['"]/) }

        return unless react_on_rails_line

        # Check for version patterns in Gemfile
        if /['"][~]/.match?(react_on_rails_line)
          add_warning(<<~MSG.strip)
            ⚠️  Gemfile uses version pattern for react_on_rails gem.

            Consider using exact version in Gemfile for guaranteed compatibility:
            gem 'react_on_rails', '#{ReactOnRails::VERSION}'
          MSG
        elsif />=\s*/.match?(react_on_rails_line)
          add_warning(<<~MSG.strip)
            ⚠️  Gemfile uses version range (>=) for react_on_rails gem.

            Consider using exact version in Gemfile for guaranteed compatibility:
            gem 'react_on_rails', '#{ReactOnRails::VERSION}'
          MSG
        end
      rescue StandardError
        # Ignore errors reading Gemfile
      end
    end

    def report_dependency_versions(package_json)
      all_deps = package_json["dependencies"]&.merge(package_json["devDependencies"] || {}) || {}

      react_version = all_deps["react"]
      react_dom_version = all_deps["react-dom"]

      if react_version && react_dom_version
        add_success("✅ React #{react_version}, React DOM #{react_dom_version}")
      elsif react_version
        add_success("✅ React #{react_version}")
        add_warning("⚠️  React DOM not found")
      elsif react_dom_version
        add_warning("⚠️  React not found")
        add_success("✅ React DOM #{react_dom_version}")
      end
    end

    def report_shakapacker_version
      return unless File.exist?("Gemfile.lock")

      begin
        lockfile_content = File.read("Gemfile.lock")
        # Parse exact installed version from Gemfile.lock GEM section
        shakapacker_match = lockfile_content.match(/^\s{4}shakapacker \(([^)>=<~]+)\)/)
        if shakapacker_match
          version = shakapacker_match[1].strip
          add_info("📦 Shakapacker version: #{version}")
        end
      rescue StandardError
        # Ignore errors in parsing Gemfile.lock
      end
    end

    def report_shakapacker_version_with_threshold
      return unless File.exist?("Gemfile.lock")

      begin
        lockfile_content = File.read("Gemfile.lock")
        # Look for the exact installed version in the GEM section, not the dependency requirement
        # This matches "    shakapacker (8.0.0)" but not "      shakapacker (>= 6.0)"
        shakapacker_match = lockfile_content.match(/^\s{4}shakapacker \(([^)>=<~]+)\)/)

        if shakapacker_match
          version = shakapacker_match[1].strip

          begin
            # Validate version string format
            Gem::Version.new(version)

            if ReactOnRails::PackerUtils.supports_autobundling?
              add_success("✅ Shakapacker #{version} (supports React on Rails auto-bundling)")
            else
              add_warning("⚠️  Shakapacker #{version} - Version 7.0+ with nested_entries support needed " \
                          "for React on Rails auto-bundling")
            end
          rescue ArgumentError
            # Fallback for invalid version strings
            add_success("✅ Shakapacker #{version}")
          end
        else
          add_success("✅ Shakapacker is configured")
        end
      rescue StandardError
        add_success("✅ Shakapacker is configured")
      end
    end

    def report_webpack_version
      return unless File.exist?("package.json")

      begin
        package_json = JSON.parse(File.read("package.json"))
        all_deps = package_json["dependencies"]&.merge(package_json["devDependencies"] || {}) || {}

        webpack_version = all_deps["webpack"]
        add_info("📦 Webpack version: #{webpack_version}") if webpack_version
      rescue JSON::ParserError
        # Handle JSON parsing errors
      rescue StandardError
        # Handle other file/access errors
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
