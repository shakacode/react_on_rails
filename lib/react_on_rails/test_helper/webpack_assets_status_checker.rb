require "rake"
require "fileutils"

# You can replace this implementation with your own for use by the
# ReactOnRails::TestHelper.ensure_assets_compiled helper
module ReactOnRails
  module TestHelper
    class WebpackAssetsStatusChecker
      attr_reader :client_dir, :compiled_dirs

      def initialize(args = {})
        @compiled_dirs = args.fetch(:compiled_dirs)
        @client_dir = args.fetch(:client_dir)
        @last_stale_files = ""
      end

      def up_to_date?
        # binding.pry
        return false unless assets_exist?
        all_compiled_assets.all? do |asset|
          FileUtils.uptodate?(asset, client_files)
        end
      end

      def whats_not_up_to_date
        return [] unless assets_exist?
        result = []
        all_compiled_assets.all? do |asset|
          result += whats_not_up_to_date_worker(asset, client_files)
        end
        result.uniq
      end

      private

      def whats_not_up_to_date_worker(new, old_list)
        # derived from lib/ruby/2.2.0/fileutils.rb:147
        not_up_to_date = []
        new_time = File.mtime(new)
        old_list.each do |old|
          if File.exist?(old)
            not_up_to_date << old unless new_time > File.mtime(old)
          end
        end
        not_up_to_date
      end

      def all_compiled_assets
        make_file_list(make_globs(compiled_dirs)).to_ary
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
          fl.exclude(%r{/node_modules/})
          fl.exclude(".DS_Store")
          fl.exclude(".keep")
          fl.exclude("thumbs.db")
          fl.exclude(".")
          fl.exclude("..")
        end
      end
    end
  end
end
