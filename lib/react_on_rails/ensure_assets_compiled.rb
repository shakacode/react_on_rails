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

      puts "Webpack #{type}-rendering assets built.\n\n"
    end
  end

  class WebpackProcessChecker
    def running?
      is_running = check_running_for_type("client")
      is_running &&= check_running_for_type("server") if Utils.server_rendering_is_enabled?
      is_running
    end

    private

    def check_running_for_type(type)
      type = type.to_sym

      response = `pgrep -fl 'bin/webpack\s\\-w(atch)?\s\\-\\-config\s.*#{type}.*\\.js'`
      is_running = Utils.last_process_completed_successfully?

      puts "#{type} webpack process is running: #{response.ai}" if is_running

      is_running
    end
  end
end
