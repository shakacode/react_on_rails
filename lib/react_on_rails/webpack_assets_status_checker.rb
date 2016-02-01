require "rake"

module ReactOnRails
  class WebpackAssetsStatusChecker
    attr_reader :client_dir, :compiled_dirs

    def initialize(args = {})
      @compiled_dirs = args.fetch(:compiled_dirs)
      @client_dir = args.fetch(:client_dir)
    end

    def up_to_date?
      return false unless assets_exist?
      all_compiled_assets.all? { |asset| FileUtils.uptodate?(asset, client_files) }
    end

    private

    def all_compiled_assets
      @all_compiled_assets ||= make_file_list(make_globs(compiled_dirs)).to_ary
    end

    def client_files
      @client_files ||= make_file_list(make_globs(client_dir)).to_ary
    end

    def make_globs(dirs)
      Array(dirs).map { |dir| File.join(dir, "**", "*") }
    end

    def assets_exist?
      all_compiled_assets.to_ary.size > 0
    end

    def make_file_list(glob)
      FileList.new(glob) do |fl|
        fl.exclude(".DS_Store")
        fl.exclude(".keep")
        fl.exclude("thumbs.db")
        fl.exclude(".")
        fl.exclude("..")
      end
    end
  end
end
