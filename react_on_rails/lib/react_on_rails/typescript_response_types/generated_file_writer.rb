# frozen_string_literal: true

require "fileutils"
require "react_on_rails/error"
require "tempfile"

module ReactOnRails
  module TypeScriptResponseTypes
    class GeneratedFileWriter
      def self.write(path, content)
        new(path, content).write
      end

      def initialize(path, content)
        @path = path
        @content = content
      end

      def write
        cleanup_directory = highest_missing_ancestor(path.dirname)
        create_output_directory(path.dirname)
        validate_existing_output_directory!(path.dirname)
        tempfile = Tempfile.new([".react_on_rails_types", ".tmp"], path.dirname)
        tempfile.write(content)
        tempfile.close
        File.chmod(generated_file_mode, tempfile.path)
        prepare_output_path!
        FileUtils.mv(tempfile.path, path.to_s)
      rescue StandardError => error
        cleanup_generated_file_write(tempfile, cleanup_directory, path.dirname)
        raise error
      end

      private

      attr_reader :path, :content

      def prepare_output_path!
        validate_existing_output_directory!(path.dirname)
        path.delete if path.symlink?
        output_path_error!(path.to_s) if path.directory?
      end

      def generated_file_mode
        0o666 & ~File.umask
      end

      def cleanup_generated_file_write(tempfile, cleanup_directory, cleanup_leaf)
        cleanup_tempfile(tempfile)
      rescue StandardError
        nil
      ensure
        cleanup_created_directory(cleanup_directory, cleanup_leaf)
      end

      def cleanup_tempfile(tempfile)
        return unless tempfile

        tempfile.close unless tempfile.closed?
        tempfile.unlink if tempfile.path && File.exist?(tempfile.path)
      end

      def cleanup_created_directory(cleanup_directory, cleanup_leaf)
        return unless cleanup_directory

        current_path = cleanup_leaf
        loop do
          break unless same_or_child_path?(current_path, cleanup_directory)

          begin
            cleanup_path(current_path)
          rescue Errno::ENOENT
            nil
          rescue Errno::ENOTEMPTY, Errno::EEXIST, Errno::ENOTDIR, Errno::EACCES, Errno::EPERM
            break
          end

          break if current_path == cleanup_directory

          current_path = current_path.dirname
        end
      rescue StandardError
        nil
      end

      def cleanup_path(path)
        if path.symlink?
          path.delete
        else
          Dir.rmdir(path.to_s)
        end
      end

      def highest_missing_ancestor(directory)
        missing_path = nil
        current_path = directory

        until current_path.exist? || current_path.symlink?
          missing_path = current_path
          parent_path = current_path.dirname
          break if parent_path == current_path

          current_path = parent_path
        end

        missing_path
      end

      def create_output_directory(directory)
        missing_directories(directory).each do |missing_directory|
          validate_existing_output_directory!(missing_directory.dirname)
          begin
            Dir.mkdir(missing_directory.to_s)
          rescue Errno::EEXIST
            nil
          end
          validate_existing_output_directory!(missing_directory)
        end
      rescue ArgumentError, Errno::ENOENT, Errno::ELOOP, Errno::ENOTDIR, Errno::EINVAL, Errno::EACCES, Errno::EPERM
        output_path_error!(directory.to_s)
      end

      def missing_directories(directory)
        missing_paths = []
        current_path = directory

        until current_path.exist? || current_path.symlink?
          missing_paths << current_path
          parent_path = current_path.dirname
          break if parent_path == current_path

          current_path = parent_path
        end

        missing_paths.reverse
      end

      def validate_existing_output_directory!(directory)
        output_path_error!(directory.to_s) unless directory.directory?

        real_root = Rails.root.expand_path.realpath
        real_directory = directory.realpath
        return if same_or_child_path?(real_directory, real_root)

        output_path_error!(directory.to_s)
      rescue ArgumentError, Errno::ENOENT, Errno::ELOOP, Errno::ENOTDIR, Errno::EINVAL, Errno::EACCES, Errno::EPERM
        output_path_error!(directory.to_s)
      end

      def same_or_child_path?(path, parent_path)
        path.to_s == parent_path.to_s || path.to_s.start_with?("#{parent_path}#{File::SEPARATOR}")
      end

      def output_path_error!(output_path)
        raise ReactOnRails::Error, "Response types output path must be inside Rails.root: #{output_path.inspect}"
      end
    end
  end
end
