# frozen_string_literal: true

require "English"

module ReactOnRails
  module TaskHelpers
    # Returns the root folder of the monorepo
    def monorepo_root
      File.expand_path("..", __dir__)
    end

    # Returns the root folder of the react_on_rails gem
    def gem_root
      File.join(monorepo_root, "react_on_rails")
    end

    # Returns the root folder of the react_on_rails_pro gem
    def pro_gem_root
      File.join(monorepo_root, "react_on_rails_pro")
    end

    # Returns the folder where examples are located
    def examples_dir
      File.join(monorepo_root, "gen-examples", "examples")
    end

    def dummy_app_dir
      File.join(gem_root, "spec/dummy")
    end

    def pro_dummy_app_dir
      File.join(pro_gem_root, "spec", "dummy")
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
      required_version = detect_bundler_ruby_version(dir)

      if required_version && required_version != RUBY_VERSION
        puts "  Switching Ruby version: #{RUBY_VERSION} → #{required_version}"
        # Run version switch and bundle install in the same shell context
        bundle_install_with_ruby_version(dir, required_version)
      else
        unbundled_sh_in_dir(dir, "bundle install")
      end
    end

    private

    # Runs bundle install with the specified Ruby version in the same shell context
    def bundle_install_with_ruby_version(dir, version)
      version_manager = ENV.fetch("RUBY_VERSION_MANAGER", "rvm")

      command = case version_manager
                when "rvm"
                  "rvm #{version} do bundle install"
                when "rbenv"
                  "RBENV_VERSION=#{version} bundle install"
                when "asdf"
                  "asdf shell ruby #{version} && bundle install"
                else
                  # TODO: add support for chruby
                  puts "  ⚠️  Unknown RUBY_VERSION_MANAGER: #{version_manager}"
                  puts "  Supported values: rvm, rbenv, asdf"
                  raise "Ruby version #{version} required. Current: #{RUBY_VERSION}"
                end

      unbundled_sh_in_dir(dir, command)
    rescue StandardError => e
      puts "  ⚠️  Failed to switch Ruby version and run bundle install: #{e.message}"
      puts "  Please manually switch to Ruby #{version} and try again"
      raise
    end

    # Detects the required Ruby version using Bundler
    def detect_bundler_ruby_version(dir)
      output = nil
      exit_status = nil

      # Run in unbundled environment to avoid conflicts with parent Bundler context
      Bundler.with_unbundled_env do
        Dir.chdir(dir) do
          output = `bundle platform --ruby 2>&1`
          exit_status = $CHILD_STATUS.exitstatus
        end
      end

      unless exit_status.zero?
        puts "  ⚠️  Failed to detect Ruby version in #{dir}"
        puts "  Error: #{output.strip}" unless output.strip.empty?
        return nil
      end

      # Parse "ruby 3.3.7" or "ruby 3.3.7-rc1" or "ruby 3.4.0-preview1"
      # Regex matches: digits.dots followed by optional -prerelease
      match = output.strip.match(/ruby\s+([\d.]+(?:-[a-zA-Z0-9.]+)?)/)
      match ? match[1] : nil
    rescue StandardError => e
      puts "  ⚠️  Error detecting Ruby version: #{e.message}"
      nil
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
