module ReactOnRails
  class EnsureAssetsCompiled
    COMPILED_DIR_NAMES = %w(javascripts stylesheets fonts images).freeze

    def self.build
      client_dir = Rails.root.join("client")
      compiled_dirs = COMPILED_DIR_NAMES.map { |dir| Rails.root.join("app", "assets", dir, "generated") }

      assets_checker = WebpackAssetsStatusChecker.new(client_dir: client_dir, compiled_dirs: compiled_dirs)
      process_checker = WebpackProcessChecker.new
      compiler = WebpackAssetsCompiler.new

      new(assets_checker, compiler, process_checker)
    end

    attr_reader :webpack_assets_checker, :webpack_assets_compiler, :webpack_process_checker, :assets_have_been_compiled

    def initialize(webpack_assets_checker, webpack_assets_compiler, webpack_process_checker)
      @webpack_assets_compiler = webpack_assets_compiler
      @webpack_assets_checker = webpack_assets_checker
      @webpack_process_checker = webpack_process_checker
      @assets_have_been_compiled = false
    end

    def call
      loop do
        should_skip_compiling = assets_have_been_compiled || @webpack_assets_checker.up_to_date?
        break if should_skip_compiling

        if webpack_process_checker.running?
          sleep 1
        else
          webpack_assets_compiler.compile
          break
        end
      end

      @assets_have_been_compiled = true
    end
  end

  class WebpackAssetsCompiler
    def compile
      compile_type(:client)
      compile_type(:server) if Utils.server_rendering_is_enabled?
    end

    private

    def compile_type(type)
      puts "\n\nBuilding Webpack #{type}-rendering assets..."
      build_output = `cd client && npm run build:#{type}`

      fail "Error in building assets!\n#{build_output}" unless Utils.last_process_completed_successfully?

      puts "Webpack #{type}-rendering assets built. If you are frequently running\n"\
           "tests, you can run webpack in watch mode to speed up this process.\n"\
           "See the official documentation:\n"\
           "https://github.com/shakacode/react_on_rails/blob/master/docs/additional_reading/rspec_configuration.md\n\n"
    end
  end

  class WebpackProcessChecker
    def running?
      client_running = check_running_for_type("client")
      return client_running unless Utils.server_rendering_is_enabled?

      server_running = check_running_for_type("server")

      fail_if_only_running_for_one_type(client_running, server_running)

      client_running && server_running
    end

    private

    def fail_if_only_running_for_one_type(client_running, server_running)
      return unless client_running ^ server_running
      fail "\n\nError: detected webpack is not running for both types of assets:\n"\
           "***Webpack Client Process Running?: #{client_running}\n"\
           "***Webpack Server Process Running?: #{server_running}"
    end

    def check_running_for_type(type)
      type = type.to_sym

      response = `pgrep -fl 'bin/webpack\s(\\-w|\\-\\-watch)\s\\-\\-config\s.*#{type}.*\\.js'`
      is_running = Utils.last_process_completed_successfully?

      puts "#{type} webpack process is running: #{response.ai}" if is_running

      is_running
    end
  end
end
