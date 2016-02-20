module Byebug
  module Helpers
    #
    # Utilities for managing gem paths
    #
    module PathHelper
      def bin_file
        @bin_file ||= Gem.bin_path('byebug', 'byebug')
      end

      def root_path
        @root_path ||= File.expand_path('../..', bin_file)
      end

      def lib_files
        @lib_files ||= expand_from_root('lib/**/*.{rb,yml}')
      end

      def ext_files
        @ext_files ||= expand_from_root('ext/**/*.{c,h,rb}')
      end

      def test_files
        @test_files ||= expand_from_root('test/**/*.rb')
      end

      def gem_files
        @gem_files ||= [bin_file] + lib_files + ext_files
      end

      def all_files
        @all_files ||= gem_files + test_files
      end

      private

      def expand_from_root(glob)
        Dir.glob(File.expand_path(glob, root_path))
      end
    end
  end
end
