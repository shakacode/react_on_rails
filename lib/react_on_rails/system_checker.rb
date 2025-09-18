# frozen_string_literal: true

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
      node_version = `node --version 2>/dev/null`.strip
      return if node_version.empty?

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

      add_success("✅ Package managers available: #{available_managers.join(', ')}")
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

      add_success("✅ Shakapacker is properly configured")
      check_shakapacker_in_gemfile
      report_shakapacker_version
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

        # Clean version strings for comparison (remove ^, ~, etc.)
        clean_npm_version = npm_version.gsub(/[^0-9.]/, "")
        gem_version = ReactOnRails::VERSION

        if clean_npm_version == gem_version
          add_success("✅ React on Rails gem and NPM package versions match (#{gem_version})")
        else
          add_warning(<<~MSG.strip)
            ⚠️  Version mismatch detected:
            • Gem version: #{gem_version}
            • NPM version: #{npm_version}

            Consider updating to matching versions for best compatibility.
          MSG
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

      required_deps = required_react_dependencies
      package_json = parse_package_json
      return unless package_json

      missing_deps = find_missing_dependencies(package_json, required_deps)
      report_dependency_status(required_deps, missing_deps, package_json)
      report_dependency_versions(package_json)
    end

    # Rails integration validation

    def check_react_on_rails_initializer
      initializer_path = "config/initializers/react_on_rails.rb"
      if File.exist?(initializer_path)
        add_success("✅ React on Rails initializer exists")

        # Check for common configuration
        content = File.read(initializer_path)
        if content.include?("config.server_bundle_js_file")
          add_success("✅ Server bundle configuration found")
        else
          add_info("ℹ️  Consider configuring server_bundle_js_file in initializer")
        end
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
        report_webpack_version
      else
        add_error(<<~MSG.strip)
          🚫 Webpack configuration not found.

          Expected: config/webpack/webpack.config.js
          Run: rails generate react_on_rails:install
        MSG
      end
    end

    def check_webpack_config_content
      webpack_config_path = "config/webpack/webpack.config.js"
      content = File.read(webpack_config_path)

      if react_on_rails_config?(content)
        add_success("✅ Webpack config appears to be React on Rails compatible")
      elsif standard_shakapacker_config?(content)
        add_warning(<<~MSG.strip)
          ⚠️  Webpack config appears to be standard Shakapacker.

          React on Rails works better with its environment-specific config.
          Consider running: rails generate react_on_rails:install
        MSG
      else
        add_info("ℹ️  Custom webpack config detected - ensure React on Rails compatibility")
      end
    end


    private

    def node_missing?
      if ReactOnRails::Utils.running_on_windows?
        `where node 2>/dev/null`.strip.empty?
      else
        `which node 2>/dev/null`.strip.empty?
      end
    end

    def cli_exists?(command)
      system("which #{command} > /dev/null 2>&1")
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

    def report_dependency_versions(package_json)
      all_deps = package_json["dependencies"]&.merge(package_json["devDependencies"] || {}) || {}

      version_deps = {
        "react" => "React",
        "react-dom" => "React DOM"
      }

      version_deps.each do |dep, name|
        version = all_deps[dep]
        if version
          add_info("📦 #{name} version: #{version}")
        end
      end
    end

    def report_shakapacker_version
      return unless File.exist?("Gemfile.lock")

      begin
        lockfile_content = File.read("Gemfile.lock")
        # Parse shakapacker version from Gemfile.lock
        shakapacker_match = lockfile_content.match(/^\s*shakapacker \(([^)]+)\)/)
        if shakapacker_match
          version = shakapacker_match[1]
          add_info("📦 Shakapacker version: #{version}")
        end
      rescue StandardError
        # Ignore errors in parsing Gemfile.lock
      end
    end

    def report_webpack_version
      return unless File.exist?("package.json")

      begin
        package_json = JSON.parse(File.read("package.json"))
        all_deps = package_json["dependencies"]&.merge(package_json["devDependencies"] || {}) || {}

        webpack_version = all_deps["webpack"]
        if webpack_version
          add_info("📦 Webpack version: #{webpack_version}")
        end
      rescue JSON::ParserError, StandardError
        # Ignore errors in parsing package.json
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end