module RubyLint
  ##
  # The FileList class acts as a small wrapper around `Dir.glob` and is mainly
  # used to turn a list of filenames/directory names into a list of just file
  # names (excluding ones that don't exist).
  #
  class FileList
    ##
    # @param [Array] files
    # @return [Array]
    # @raise [Errno::ENOENT] Raised if a file or directory does not exist.
    #
    def process(files)
      existing = []

      files.each do |file|
        file = File.expand_path(file)

        if File.file?(file)
          existing << file

        elsif File.directory?(file)
          existing = existing | glob_files(file)

        else
          raise Errno::ENOENT, file
        end
      end

      return existing
    end

    ##
    # Returns a list of Ruby files in the given directory. This list includes
    # deeply nested files.
    #
    # @return [Array]
    #
    def glob_files(directory)
      return Dir.glob(File.join(directory, '**/*.rb'))
    end
  end # FileList
end # RubyLint
