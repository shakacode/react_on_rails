# frozen_string_literal: true

require "English"
require "open3"

module ReactOnRails
  module TaskHelpers
    # Returns the root folder of the react_on_rails gem
    def gem_root
      File.expand_path("..", __dir__)
    end

    # Returns the folder where examples are located
    def examples_dir
      File.join(gem_root, "gen-examples", "examples")
    end

    def dummy_app_dir
      File.join(gem_root, "spec/dummy")
    end

    # Executes a string or an array of strings in a shell in the given directory in an unbundled environment
    def sh_in_dir(dir, *shell_commands)
      shell_commands.flatten.each { |shell_command| sh %(cd #{dir} && #{shell_command.strip}) }
    end

    # Executes a string or an array of strings in a shell in the given directory
    def unbundled_sh_in_dir(dir, *shell_commands)
      Dir.chdir(dir) do
        # Without `with_unbundled_env`, running bundle in the child directories won't correctly
        # update the Gemfile.lock
        Bundler.with_unbundled_env do
          shell_commands.flatten.each do |shell_command|
            sh(shell_command.strip)
          end
        end
      end
    end

    def bundle_install_in(dir)
      # Auto-detect and switch to required Ruby version if needed
      switch_to_required_ruby_version(dir)

      unbundled_sh_in_dir(dir, "bundle install")
    end

    private

    # Detects the required Ruby version from Bundler and switches to it if needed
    def switch_to_required_ruby_version(dir)
      required_version = detect_bundler_ruby_version(dir)
      return unless required_version

      current_version = RUBY_VERSION
      return if versions_match?(current_version, required_version)

      puts "  Switching Ruby version: #{current_version} → #{required_version}"
      switch_ruby_version(required_version)
    end

    # Detects the required Ruby version using Bundler
    def detect_bundler_ruby_version(dir)
      stdout, stderr, status = Open3.capture3("bundle platform --ruby", chdir: dir)

      unless status.success?
        puts "  ⚠️  Failed to detect Ruby version in #{dir}"
        puts "  Error: #{stderr.strip}" unless stderr.strip.empty?
        return nil
      end

      # Parse "ruby 3.3.7" or "ruby 3.3.7-rc1" or "ruby 3.4.0-preview1"
      # Regex matches: digits.dots followed by optional -prerelease
      match = stdout.strip.match(/ruby\s+([\d.]+(?:-[a-zA-Z0-9.]+)?)/)
      match ? match[1] : nil
    rescue StandardError => e
      puts "  ⚠️  Error detecting Ruby version: #{e.message}"
      nil
    end

    # Checks if two Ruby versions match
    def versions_match?(current, required)
      # Require exact match since Bundler enforces exact version requirements
      current == required
    end

    # Switches to the specified Ruby version using the configured version manager
    def switch_ruby_version(version)
      version_manager = ENV.fetch("RUBY_VERSION_MANAGER", "rvm")

      case version_manager
      when "rvm"
        sh "rvm use #{version}"
      when "rbenv"
        sh "rbenv shell #{version}"
      when "asdf"
        sh "asdf shell ruby #{version}"
      else
        # TODO: Support chruby if possible
        puts "  ⚠️  Unknown RUBY_VERSION_MANAGER: #{version_manager}"
        puts "  Supported values: rvm, rbenv, asdf"
        puts "  Note: chruby is not supported due to shell function limitations"
        raise "Ruby version #{version} required. Current: #{RUBY_VERSION}"
      end
    rescue StandardError => e
      puts "  ⚠️  Failed to switch Ruby version: #{e.message}"
      puts "  Please manually switch to Ruby #{version} and try again"
      raise
    end

    public

    def bundle_install_in_no_turbolinks(dir)
      sh_in_dir(dir, "DISABLE_TURBOLINKS=TRUE bundle install")
    end

    # Runs bundle exec using that directory's Gemfile
    def bundle_exec(dir: nil, args: nil, env_vars: "")
      sh_in_dir(dir, "#{env_vars} bundle exec #{args}")
    end

    def generators_source_dir
      File.join(gem_root, "lib/generators/react_on_rails")
    end

    def symbolize_keys(hash)
      hash.each_with_object({}) do |(key, value), new_hash|
        new_key = key.is_a?(String) ? key.to_sym : key
        new_value = value.is_a?(Hash) ? symbolize_keys(value) : value
        new_hash[new_key] = new_value
      end
    end
  end
end
