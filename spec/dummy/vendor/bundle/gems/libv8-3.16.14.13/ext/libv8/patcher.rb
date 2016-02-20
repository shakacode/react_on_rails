module Libv8
  module Patcher
    PATCH_DIRECTORY = File.expand_path '../../../patches', __FILE__

    module_function

    def patch_directories_for(compiler)
      patch_directories = []

      case
      when compiler.target =~ /arm/
        patch_directories << 'arm'
      end

      case compiler
      when Compiler::GCC
        patch_directories << 'gcc48' if compiler.version >= '4.8'
      when Compiler::Clang
        patch_directories << 'clang'
        patch_directories << 'clang33' if compiler.version >= '3.3'
        patch_directories << 'clang51' if compiler.version >= '5.1'
        patch_directories << 'clang70' if compiler.version >= '7.0'
      end

      patch_directories
    end

    def patch_directories(*additional_directories)
      absolute_paths = [PATCH_DIRECTORY]

      additional_directories.each do |directory|
        absolute_paths << File.join(PATCH_DIRECTORY, directory)
      end

      absolute_paths.uniq
    end

    def patches(*additional_directories)
      patch_directories(*additional_directories).map do |directory|
        Dir.glob(File.join directory, '*.patch')
      end.flatten.sort
    end

    def patch!(*additional_directories)
      File.open(".applied_patches", File::RDWR|File::CREAT) do |f|
        available_patches = patches *additional_directories
        applied_patches = f.readlines.map(&:chomp)

        (available_patches - applied_patches).each do |patch|
          `patch -p1 -N < #{patch}`
          fail 'failed to apply patch' unless $?.success?
          f.puts patch
        end
      end
    end
  end
end
