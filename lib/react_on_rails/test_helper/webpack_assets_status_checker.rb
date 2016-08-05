require "rake"
require "fileutils"

# You can replace this implementation with your own for use by the
# ReactOnRails::TestHelper.ensure_assets_compiled helper
module ReactOnRails
  module TestHelper
    class WebpackAssetsStatusChecker
      # client_dir is typically /client, where all client files go
      attr_reader :client_dir, :generated_assets_dir

      def initialize(generated_assets_dir, client_dir, webpack_generated_files)
        @generated_assets_dir = generated_assets_dir
        @client_dir = client_dir
        @webpack_generated_files = webpack_generated_files
      end

      def stale_generated_webpack_files
        most_recent_mtime = find_most_recent_mtime
        all_compiled_assets.each_with_object([]) do |webpack_generated_file, stale_gen_list|
          if !File.exist?(webpack_generated_file) ||
             File.mtime(webpack_generated_file) < most_recent_mtime
            stale_gen_list << webpack_generated_file
          end
          stale_gen_list
        end
      end

      private

      def find_most_recent_mtime
        client_files.reduce(1.year.ago) do |newest_time, file|
          mt = File.mtime(file)
          mt > newest_time ? mt : newest_time
        end
      end

      def all_compiled_assets
        @all_compiled_assets ||= begin
          webpack_generated_files = @webpack_generated_files.map do |file|
            File.join(@generated_assets_dir, file)
          end
          if webpack_generated_files.present?
            webpack_generated_files
          else
            file_list = make_file_list(make_globs(generated_assets_dir)).to_ary
            puts "V" * 80
            puts "Please define config.webpack_generated_files (array) so the test helper knows "\
            "which files are required."
            puts "Detected the possible following files to check for webpack compilation in "\
              "#{generated_assets_dir}"
            puts file_list.join("\n")
            puts "^" * 80
            file_list
          end
        end
      end

      def client_files
        @client_files ||= make_file_list(make_globs(client_dir)).to_ary
      end

      def make_globs(dirs)
        Array(dirs).map { |dir| File.join(dir, "**", "*") }
      end

      def assets_exist?
        !all_compiled_assets.empty?
      end

      def make_file_list(glob)
        FileList.new(glob) do |fl|
          fl.exclude(%r{/node_modules})
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
