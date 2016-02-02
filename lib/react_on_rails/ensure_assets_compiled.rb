module ReactOnRails
  class EnsureAssetsCompiled
    COMPILED_DIR_NAMES = %w(javascripts stylesheets fonts images).freeze

    def self.build
      client_dir = Rails.root.join("client")
      compiled_dirs = COMPILED_DIR_NAMES.map { |dir| Rails.root.join("app", "assets", dir, "generated") }
      checker = WebpackAssetsStatusChecker.new(client_dir: client_dir, compiled_dirs: compiled_dirs)
      compiler = WebpackAssetsCompiler.new
      new(checker, compiler)
    end

    attr_reader :webpack_assets_checker, :webpack_assets_compiler, :assets_have_been_compiled

    def initialize(webpack_assets_checker, webpack_assets_compiler)
      @webpack_assets_compiler = webpack_assets_compiler
      @webpack_assets_checker = webpack_assets_checker
      @assets_have_been_compiled = false
    end

    def call
      should_skip_compiling = assets_have_been_compiled || @webpack_assets_checker.up_to_date?
      webpack_assets_compiler.compile unless should_skip_compiling
      @assets_have_been_compiled = true
    end
  end

  class WebpackAssetsCompiler
    def compile
      compile_type(:client)
      compile_type(:server) if ReactOnRails.configuration.server_bundle_js_file.present?
    end

    private

    def compile_type(type)
      puts "\n\nBuilding Webpack #{type}-rendering assets..."
      build_output = `cd client && npm run build:#{type}`

      if build_output =~ /error/i
        fail "Error in building assets!\n#{build_output}"
      end

      puts "Webpack #{type}-rendering assets built.\n\n"
    end
  end
end
