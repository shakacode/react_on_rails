# frozen_string_literal: true

module ReactOnRailsPro
  module TaskHelpers
    # Returns the root folder of the react_on_rails gem
    def gem_root
      File.expand_path("..", __dir__)
    end

    def dummy_app_dir
      File.join(gem_root, "spec/dummy")
    end

    # Executes a string or an array of strings in a shell in the given directory
    def sh_in_dir(dir, *shell_commands)
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

    def bundle_install_in(dir, frozen: true)
      cmd = "#{frozen ? "BUNDLE_FROZEN=true " : ""}bundle install"
      sh_in_dir(dir, cmd)
    end

    # Runs bundle exec using that directory's Gemfile
    def bundle_exec(dir: nil, args: nil, env_vars: "")
      sh_in_dir(dir, "#{env_vars} #{args}")
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
