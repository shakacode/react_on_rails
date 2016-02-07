require_relative "webpack_assets_compiler"
require_relative "webpack_assets_compiler"
require_relative "webpack_process_checker"

module ReactOnRails
  class EnsureAssetsCompiled

    # Main entry point to ensuring assets are compiled.
    # Typical usage passes all params as nil defaults.
    # webpack_assets_checker: provide one method: `def up_to_date?`
    # webpack_process_checker: provide one method: `def running?`
    # webpack_assets_compiler: provide one method: `def compile`
    # client_dir and compiled_dirs are passed into the default webpack_assets_checker if you
    # don't provide one.
    def self.invoke(webpack_assets_checker: nil,
      webpack_assets_compiler: nil,
      webpack_process_checker: nil,
      client_dir: nil,
      compiled_dirs: nil)

      if webpack_assets_checker.nil?
        client_dir ||= Rails.root.join("client")
        compiled_dirs ||= ReactOnRails.configuration.generated_assets_dirs
        webpack_assets_checker ||= WebpackAssetsStatusChecker.new(client_dir: client_dir, compiled_dirs: compiled_dirs)
      end

      webpack_assets_compiler ||= WebpackAssetsCompiler.new
      webpack_process_checker ||= WebpackProcessChecker.new

      loop do
        should_skip_compiling = @has_been_run || webpack_assets_checker.up_to_date?
        break if should_skip_compiling

        if webpack_process_checker.running?
          sleep 1
        else
          webpack_assets_compiler.compile
          break
        end
      end

      @has_been_run = true
    end

    class << self
      attr_accessor :has_been_run
      @has_been_run = false
    end
  end
end

