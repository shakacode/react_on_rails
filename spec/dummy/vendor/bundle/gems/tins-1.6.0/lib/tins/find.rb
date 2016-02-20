require 'enumerator'
require 'pathname'
require 'tins/module_group'

module Tins
  module Find
    EXPECTED_STANDARD_ERRORS = ModuleGroup[
      Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR, Errno::ELOOP,
      Errno::ENAMETOOLONG
    ]

    class Finder
      module PathExtension
        attr_accessor :finder

        def finder_stat
          finder.protect_from_errors do
            finder.follow_symlinks ? File.stat(self) : File.lstat(self)
          end
        end

        def file
          finder.protect_from_errors do
            File.new(self) if file?
          end
        end

        def file?
          finder.protect_from_errors { s = finder_stat and s.file? }
        end

        def directory?
          finder.protect_from_errors { s = finder_stat and s.directory? }
        end

        def exist?
          finder.protect_from_errors { File.exist?(self) }
        end

        def stat
          finder.protect_from_errors { File.stat(self) }
        end

        def lstat
          finder.protect_from_errors { File.lstat(self) }
        end

        def pathname
          Pathname.new(self)
        end

        def suffix
          pathname.extname[1..-1] || ''
        end
      end

      def initialize(opts = {})
        @show_hidden     = opts.fetch(:show_hidden)     { true }
        @raise_errors    = opts.fetch(:raise_errors)    { false }
        @follow_symlinks = opts.fetch(:follow_symlinks) { true }
        opts[:suffix].full? { |s| @suffix = [*s] }
      end

      attr_accessor :show_hidden

      attr_accessor :raise_errors

      attr_accessor :follow_symlinks

      attr_accessor :suffix

      def visit_path?(path)
        @suffix.nil? || @suffix.include?(path.suffix)
      end

      def find(*paths)
        block_given? or return enum_for(__method__, *paths)
        paths.collect! { |d| d.dup }
        while path = paths.shift
          path = prepare_path(path)
          catch(:prune) do
            stat = path.finder_stat or next
            visit_path?(path) and yield path
            if stat.directory?
              ps = protect_from_errors { Dir.entries(path) } or next
              ps.sort!
              ps.reverse_each do |p|
                next if p == "." or p == ".."
                next if !@show_hidden && p.start_with?('.')
                p = File.join(path, p)
                paths.unshift p.untaint
              end
            end
          end
        end
      end

      def prepare_path(path)
        path = path.dup.taint
        path.extend PathExtension
        path.finder = self
        path
      end

      def protect_from_errors(errors = Find::EXPECTED_STANDARD_ERRORS)
        yield
      rescue errors
        raise_errors and raise
        return
      end
    end

    #
    # Calls the associated block with the name of every path and directory
    # listed as arguments, then recursively on their subdirectories, and so on.
    #
    # See the +Find+ module documentation for an example.
    #
    def find(*paths, &block) # :yield: path
      opts = Hash === paths.last ? paths.pop : {}
      Finder.new(opts).find(*paths, &block)
    end

    #
    # Skips the current path or directory, restarting the loop with the next
    # entry. If the current path is a directory, that directory will not be
    # recursively entered. Meaningful only within the block associated with
    # Find::find.
    #
    # See the +Find+ module documentation for an example.
    #
    def prune
      throw :prune
    end

    module_function :find, :prune
  end
end
