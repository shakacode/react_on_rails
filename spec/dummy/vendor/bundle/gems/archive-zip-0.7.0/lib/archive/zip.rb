# encoding: UTF-8

require 'fileutils'
require 'set'
require 'tempfile'

require 'archive/support/ioextensions'
require 'archive/support/iowindow'
require 'archive/support/time'
require 'archive/support/zlib'
require 'archive/zip/codec'
require 'archive/zip/entry'
require 'archive/zip/error'

module Archive # :nodoc:
  # Archive::Zip represents a ZIP archive compatible with InfoZip tools and the
  # archives they generate.  It currently supports both stored and deflated ZIP
  # entries, directory entries, file entries, and symlink entries.  File and
  # directory accessed and modified times, POSIX permissions, and ownerships can
  # be archived and restored as well depending on platform support for such
  # metadata.  Traditional (weak) encryption is also supported.
  #
  # Zip64, digital signatures, and strong encryption are not supported.  ZIP
  # archives can only be read from seekable kinds of IO, such as files; reading
  # archives from pipes or any other non-seekable kind of IO is not supported.
  # However, writing to such IO objects <b><em>IS</em></b> supported.
  class Zip
    include Enumerable

    # The lead-in marker for the end of central directory record.
    EOCD_SIGNATURE     = "PK\x5\x6" # 0x06054b50
    # The lead-in marker for the digital signature record.
    DS_SIGNATURE       = "PK\x5\x5" # 0x05054b50
    # The lead-in marker for the ZIP64 end of central directory record.
    Z64EOCD_SIGNATURE  = "PK\x6\x6" # 0x06064b50
    # The lead-in marker for the ZIP64 end of central directory locator record.
    Z64EOCDL_SIGNATURE = "PK\x6\x7" # 0x07064b50
    # The lead-in marker for a central file record.
    CFH_SIGNATURE      = "PK\x1\x2" # 0x02014b50
    # The lead-in marker for a local file record.
    LFH_SIGNATURE      = "PK\x3\x4" # 0x04034b50
    # The lead-in marker for data descriptor record.
    DD_SIGNATURE       = "PK\x7\x8" # 0x08074b50


    # Creates or possibly updates an archive using _paths_ for new contents.
    #
    # If _archive_ is a String, it is treated as a file path which will receive
    # the archive contents.  If the file already exists, it is assumed to be an
    # archive and will be updated "in place".  Otherwise, a new archive
    # is created.  The archive will be closed once written.
    #
    # If _archive_ has any other kind of value, it is treated as a writable
    # IO-like object which will be left open after the completion of this
    # method.
    #
    # <b>NOTE:</b> No attempt is made to prevent adding multiple entries with
    # the same archive path.
    #
    # See the instance method #archive for more information about _paths_ and
    # _options_.
    def self.archive(archive, paths, options = {})
      if archive.kind_of?(String) && File.exist?(archive) then
        # Update the archive "in place".
        tmp_archive_path = nil
        File.open(archive) do |archive_in|
          Tempfile.open(*File.split(archive_in.path).reverse) do |archive_out|
            # Save off the path so that the temporary file can be renamed to the
            # archive file later.
            tmp_archive_path = archive_out.path
            # Ensure the file is in binary mode for Windows.
            archive_out.binmode
            # Update the archive.
            open(archive_in, :r) do |z_in|
              open(archive_out, :w) do |z_out|
                z_in.each  { |entry| z_out << entry }
                z_out.archive(paths, options)
              end
            end
          end
        end
        # Set more reasonable permissions than those set by Tempfile.
        File.chmod(0666 & ~File.umask, tmp_archive_path)
        # Replace the input archive with the output archive.
        File.rename(tmp_archive_path, archive)
      else
        open(archive, :w) { |z| z.archive(paths, options) }
      end
    end

    # Extracts the entries from an archive to _destination_.
    #
    # If _archive_ is a String, it is treated as a file path pointing to an
    # existing archive file.  Otherwise, it is treated as a seekable and
    # readable IO-like object.
    #
    # See the instance method #extract for more information about _destination_
    # and _options_.
    def self.extract(archive, destination, options = {})
      open(archive, :r) { |z| z.extract(destination, options) }
    end

    # Calls #new with the given arguments and yields the resulting Zip instance
    # to the given block.  Returns the result of the block and ensures that the
    # Zip instance is closed.
    #
    # This is a synonym for #new if no block is given.
    def self.open(archive, mode = :r)
      zf = new(archive, mode)
      return zf unless block_given?

      begin
        yield(zf)
      ensure
        zf.close unless zf.closed?
      end
    end

    # Opens an existing archive and/or creates a new archive.
    #
    # If _archive_ is a String, it will be treated as a file path; otherwise, it
    # is assumed to be an IO-like object with the necessary read or write
    # support depending on the setting of _mode_.  IO-like objects are not
    # closed when the archive is closed, but files opened from file paths are.
    # Set _mode_ to <tt>:r</tt> or <tt>"r"</tt> to read the archive, and set it
    # to <tt>:w</tt> or <tt>"w"</tt> to write the archive.
    #
    # <b>NOTE:</b> The #close method must be called in order to save any
    # modifications to the archive.  Due to limitations in the Ruby finalization
    # capabilities, the #close method is _not_ automatically called when this
    # object is garbage collected.  Make sure to call #close when finished with
    # this object.
    def initialize(archive, mode = :r)
      @archive = archive
      mode = mode.to_sym
      if mode == :r || mode == :w then
        @mode = mode
      else
        raise ArgumentError, "illegal access mode #{mode}"
      end

      @close_delegate = false
      if @archive.kind_of?(String) then
        @close_delegate = true
        if mode == :r then
          @archive = File.open(@archive, 'rb')
        else
          @archive = File.open(@archive, 'wb')
        end
      end
      @entries = []
      @comment = ''
      @closed = false
    end

    # A comment string for the ZIP archive.
    attr_accessor :comment

    # Closes the archive.
    #
    # Failure to close the archive by calling this method may result in a loss
    # of data for writable archives.
    #
    # <b>NOTE:</b> The underlying stream is only closed if the archive was
    # opened with a String for the _archive_ parameter.
    #
    # Raises Archive::Zip::IOError if called more than once.
    def close
      raise IOError, 'closed archive' if closed?

      if writable? then
        # Write the new archive contents.
        dump(@archive)
      end

      # Note that we only close delegate streams which are opened by us so that
      # the user may do so for other delegate streams at his/her discretion.
      @archive.close if @close_delegate

      @closed = true
      nil
    end

    # Returns +true+ if the ZIP archive is closed, +false+ otherwise.
    def closed?
      @closed
    end

    # Returns +true+ if the ZIP archive is readable, +false+ otherwise.
    def readable?
      @mode == :r
    end

    # Returns +true+ if the ZIP archive is writable, +false+ otherwise.
    def writable?
      @mode == :w
    end

    # Iterates through each entry of a readable ZIP archive in turn yielding
    # each one to the given block.
    #
    # Raises Archive::Zip::IOError if called on a non-readable archive or after
    # the archive is closed.
    def each(&b)
      raise IOError, 'non-readable archive' unless readable?
      raise IOError, 'closed archive' if closed?

      unless @parse_complete then
        parse(@archive)
        @parse_complete = true
      end
      @entries.each(&b)
    end

    # Adds _entry_ into a writable ZIP archive.
    #
    # <b>NOTE:</b> No attempt is made to prevent adding multiple entries with
    # the same archive path.
    #
    # Raises Archive::Zip::IOError if called on a non-writable archive or after
    # the archive is closed.
    def add_entry(entry)
      raise IOError, 'non-writable archive' unless writable?
      raise IOError, 'closed archive' if closed?
      unless entry.kind_of?(Entry) then
        raise ArgumentError, 'Archive::Zip::Entry instance required'
      end

      @entries << entry
      self
    end
    alias :<< :add_entry

    # Adds _paths_ to the archive.  _paths_ may be either a single path or an
    # Array of paths.  The files and directories referenced by _paths_ are added
    # using their respective basenames as their zip paths.  The exception to
    # this is when the basename for a path is either <tt>"."</tt> or
    # <tt>".."</tt>.  In this case, the path is replaced with the paths to the
    # contents of the directory it references.
    #
    # _options_ is a Hash optionally containing the following:
    # <b>:path_prefix</b>::
    #   Specifies a prefix to be added to the zip_path attribute of each entry
    #   where `/' is the file separator character.  This defaults to the empty
    #   string.  All values are passed through Archive::Zip::Entry.expand_path
    #   before use.
    # <b>:recursion</b>::
    #   When set to +true+ (the default), the contents of directories are
    #   recursively added to the archive.
    # <b>:directories</b>::
    #   When set to +true+ (the default), entries are added to the archive for
    #   directories.  Otherwise, the entries for directories will not be added;
    #   however, the contents of the directories will still be considered if the
    #   <b>:recursion</b> option is +true+.
    # <b>:symlinks</b>::
    #   When set to +false+ (the default), entries for symlinks are excluded
    #   from the archive.  Otherwise, they are included.  <b>NOTE:</b> Unless
    #   <b>:follow_symlinks</b> is explicitly set, it will be set to the logical
    #   NOT of this option in calls to Archive::Zip::Entry.from_file.  If
    #   symlinks should be completely ignored, set both this option and
    #   <b>:follow_symlinks</b> to +false+.  See Archive::Zip::Entry.from_file
    #   for details regarding <b>:follow_symlinks</b>.
    # <b>:flatten</b>::
    #   When set to +false+ (the default), the directory paths containing
    #   archived files will be included in the zip paths of entries representing
    #   the files.  When set to +true+, files are archived without any
    #   containing directory structure in the zip paths.  Setting to +true+
    #   implies that <b>:directories</b> is +false+ and <b>:path_prefix</b> is
    #   empty.
    # <b>:exclude</b>::
    #   Specifies a proc or lambda which takes a single argument containing a
    #   prospective zip entry and returns +true+ if the entry should be excluded
    #   from the archive and +false+ if it should be included.  <b>NOTE:</b> If
    #   a directory is excluded in this way, the <b>:recursion</b> option has no
    #   effect for it.
    # <b>:password</b>::
    #   Specifies a proc, lambda, or a String.  If a proc or lambda is used, it
    #   must take a single argument containing a zip entry and return a String
    #   to be used as an encryption key for the entry.  If a String is used, it
    #   will be used as an encryption key for all encrypted entries.
    # <b>:on_error</b>::
    #   Specifies a proc or lambda which is called when an exception is raised
    #   during the archival of an entry.  It takes two arguments, a file path
    #   and an exception object generated while attempting to archive the entry.
    #   If <tt>:retry</tt> is returned, archival of the entry is attempted
    #   again.  If <tt>:skip</tt> is returned, the entry is skipped.  Otherwise,
    #   the exception is raised.
    # Any other options which are supported by Archive::Zip::Entry.from_file are
    # also supported.
    #
    # <b>NOTE:</b> No attempt is made to prevent adding multiple entries with
    # the same archive path.
    #
    # Raises Archive::Zip::IOError if called on a non-writable archive or after
    # the archive is closed.  Raises Archive::Zip::EntryError if the
    # <b>:on_error</b> option is either unset or indicates that the error should
    # be raised and Archive::Zip::Entry.from_file raises an error.
    #
    # == Example
    #
    # A directory contains:
    #   zip-test
    #   +- dir1
    #   |  +- file2.txt
    #   +- dir2
    #   +- file1.txt
    #
    # Create some archives:
    #   Archive::Zip.open('zip-test1.zip') do |z|
    #     z.archive('zip-test')
    #   end
    #
    #   Archive::Zip.open('zip-test2.zip') do |z|
    #     z.archive('zip-test/.', :path_prefix => 'a/b/c/d')
    #   end
    #
    #   Archive::Zip.open('zip-test3.zip') do |z|
    #     z.archive('zip-test', :directories => false)
    #   end
    #
    #   Archive::Zip.open('zip-test4.zip') do |z|
    #     z.archive('zip-test', :exclude => lambda { |e| e.file? })
    #   end
    #
    # The archives contain:
    #   zip-test1.zip -> zip-test/
    #                    zip-test/dir1/
    #                    zip-test/dir1/file2.txt
    #                    zip-test/dir2/
    #                    zip-test/file1.txt
    #
    #   zip-test2.zip -> a/b/c/d/dir1/
    #                    a/b/c/d/dir1/file2.txt
    #                    a/b/c/d/dir2/
    #                    a/b/c/d/file1.txt
    #
    #   zip-test3.zip -> zip-test/dir1/file2.txt
    #                    zip-test/file1.txt
    #
    #   zip-test4.zip -> zip-test/
    #                    zip-test/dir1/
    #                    zip-test/dir2/
    def archive(paths, options = {})
      raise IOError, 'non-writable archive' unless writable?
      raise IOError, 'closed archive' if closed?

      # Ensure that paths is an enumerable.
      paths = [paths] unless paths.kind_of?(Enumerable)
      # If the basename of a path is '.' or '..', replace the path with the
      # paths of all the entries contained within the directory referenced by
      # the original path.
      paths = paths.collect do |path|
        basename = File.basename(path)
        if basename == '.' || basename == '..' then
          Dir.entries(path).reject do |e|
            e == '.' || e == '..'
          end.collect do |e|
            File.join(path, e)
          end
        else
          path
        end
      end.flatten.uniq

      # Ensure that unspecified options have default values.
      options[:path_prefix]  = ''    unless options.has_key?(:path_prefix)
      options[:recursion]    = true  unless options.has_key?(:recursion)
      options[:directories]  = true  unless options.has_key?(:directories)
      options[:symlinks]     = false unless options.has_key?(:symlinks)
      options[:flatten]      = false unless options.has_key?(:flatten)

      # Flattening the directory structure implies that directories are skipped
      # and that the path prefix should be ignored.
      if options[:flatten] then
        options[:path_prefix] = ''
        options[:directories] = false
      end

      # Clean up the path prefix.
      options[:path_prefix] = Entry.expand_path(options[:path_prefix].to_s)

      paths.each do |path|
        # Generate the zip path.
        zip_entry_path = File.basename(path)
        zip_entry_path += '/' if File.directory?(path)
        unless options[:path_prefix].empty? then
          zip_entry_path = "#{options[:path_prefix]}/#{zip_entry_path}"
        end

        begin
          # Create the entry, but do not add it to the archive yet.
          zip_entry = Zip::Entry.from_file(
            path,
            options.merge(
              :zip_path        => zip_entry_path,
              :follow_symlinks => options.has_key?(:follow_symlinks) ?
                                  options[:follow_symlinks] :
                                  ! options[:symlinks]
            )
          )
        rescue StandardError => error
          unless options[:on_error].nil? then
            case options[:on_error][path, error]
            when :retry
              retry
            when :skip
              next
            else
              raise
            end
          else
            raise
          end
        end

        # Skip this entry if so directed.
        if (zip_entry.symlink? && ! options[:symlinks]) ||
           (! options[:exclude].nil? && options[:exclude][zip_entry]) then
          next
        end

        # Set the encryption key for the entry.
        if options[:password].kind_of?(String) then
          zip_entry.password = options[:password]
        elsif ! options[:password].nil? then
          zip_entry.password = options[:password][zip_entry]
        end

        # Add entries for directories (if requested) and files/symlinks.
        if (! zip_entry.directory? || options[:directories]) then
          add_entry(zip_entry)
        end

        # Recurse into subdirectories (if requested).
        if zip_entry.directory? && options[:recursion] then
          archive(
            Dir.entries(path).reject do |e|
              e == '.' || e == '..'
            end.collect do |e|
              File.join(path, e)
            end,
            options.merge(:path_prefix => zip_entry_path)
          )
        end
      end

      nil
    end

    # Extracts the contents of the archive to _destination_, where _destination_
    # is a path to a directory which will contain the contents of the archive.
    # The destination path will be created if it does not already exist.
    #
    # _options_ is a Hash optionally containing the following:
    # <b>:directories</b>::
    #   When set to +true+ (the default), entries representing directories in
    #   the archive are extracted.  This happens after all non-directory entries
    #   are extracted so that directory metadata can be properly updated.
    # <b>:symlinks</b>::
    #   When set to +false+ (the default), entries representing symlinks in the
    #   archive are skipped.  When set to +true+, such entries are extracted.
    #   Exceptions may be raised on plaforms/file systems which do not support
    #   symlinks.
    # <b>:overwrite</b>::
    #   When set to <tt>:all</tt> (the default), files which already exist will
    #   be replaced.  When set to <tt>:older</tt>, such files will only be
    #   replaced if they are older according to their last modified times than
    #   the zip entry which would replace them.  When set to <tt>:none</tt>,
    #   such files will never be replaced.  Any other value is the same as
    #   <tt>:all</tt>.
    # <b>:create</b>::
    #   When set to +true+ (the default), files and directories which do not
    #   already exist will be extracted.  When set to +false+, only files and
    #   directories which already exist will be extracted (depending on the
    #   setting of <b>:overwrite</b>).
    # <b>:flatten</b>::
    #   When set to +false+ (the default), the directory paths containing
    #   extracted files will be created within +destination+ in order to contain
    #   the files.  When set to +true+, files are extracted directly to
    #   +destination+ and directory entries are skipped.
    # <b>:exclude</b>::
    #   Specifies a proc or lambda which takes a single argument containing a
    #   zip entry and returns +true+ if the entry should be skipped during
    #   extraction and +false+ if it should be extracted.
    # <b>:password</b>::
    #   Specifies a proc, lambda, or a String.  If a proc or lambda is used, it
    #   must take a single argument containing a zip entry and return a String
    #   to be used as a decryption key for the entry.  If a String is used, it
    #   will be used as a decryption key for all encrypted entries.
    # <b>:on_error</b>::
    #   Specifies a proc or lambda which is called when an exception is raised
    #   during the extraction of an entry.  It takes two arguments, a zip entry
    #   and an exception object generated while attempting to extract the entry.
    #   If <tt>:retry</tt> is returned, extraction of the entry is attempted
    #   again.  If <tt>:skip</tt> is returned, the entry is skipped.  Otherwise,
    #   the exception is raised.
    # Any other options which are supported by Archive::Zip::Entry#extract are
    # also supported.
    #
    # Raises Archive::Zip::IOError if called on a non-readable archive or after
    # the archive is closed.
    #
    # == Example
    #
    # An archive, <tt>archive.zip</tt>, contains:
    #   zip-test/
    #   zip-test/dir1/
    #   zip-test/dir1/file2.txt
    #   zip-test/dir2/
    #   zip-test/file1.txt
    #
    # A directory, <tt>extract4</tt>, contains:
    #   zip-test
    #   +- dir1
    #   +- file1.txt
    #
    # Extract the archive:
    #   Archive::Zip.open('archive.zip') do |z|
    #     z.extract('extract1')
    #   end
    #
    #   Archive::Zip.open('archive.zip') do |z|
    #     z.extract('extract2', :flatten => true)
    #   end
    #
    #   Archive::Zip.open('archive.zip') do |z|
    #     z.extract('extract3', :create => false)
    #   end
    #
    #   Archive::Zip.open('archive.zip') do |z|
    #     z.extract('extract3', :create => true)
    #   end
    #
    #   Archive::Zip.open('archive.zip') do |z|
    #     z.extract( 'extract5', :exclude => lambda { |e| e.file? })
    #   end
    #
    # The directories contain:
    #   extract1 -> zip-test
    #               +- dir1
    #               |  +- file2.txt
    #               +- dir2
    #               +- file1.txt
    #
    #   extract2 -> file2.txt
    #               file1.txt
    #
    #   extract3 -> <empty>
    #
    #   extract4 -> zip-test
    #               +- dir2
    #               +- file1.txt       <- from archive contents
    #
    #   extract5 -> zip-test
    #               +- dir1
    #               +- dir2
    def extract(destination, options = {})
      raise IOError, 'non-readable archive' unless readable?
      raise IOError, 'closed archive' if closed?

      # Ensure that unspecified options have default values.
      options[:directories] = true  unless options.has_key?(:directories)
      options[:symlinks]    = false unless options.has_key?(:symlinks)
      options[:overwrite]   = :all  unless options[:overwrite] == :older ||
                                           options[:overwrite] == :never
      options[:create]      = true  unless options.has_key?(:create)
      options[:flatten]     = false unless options.has_key?(:flatten)

      # Flattening the archive structure implies that directory entries are
      # skipped.
      options[:directories] = false if options[:flatten]

      # First extract all non-directory entries.
      directories = []
      each do |entry|
        # Compute the target file path.
        file_path = entry.zip_path
        file_path = File.basename(file_path) if options[:flatten]
        file_path = File.join(destination, file_path)

        # Cache some information about the file path.
        file_exists = File.exist?(file_path)
        file_mtime = File.mtime(file_path) if file_exists

        begin
          # Skip this entry if so directed.
          if (! file_exists && ! options[:create]) ||
             (file_exists &&
              (options[:overwrite] == :never ||
               options[:overwrite] == :older && entry.mtime <= file_mtime)) ||
             (! options[:exclude].nil? && options[:exclude][entry]) then
            next
          end

          # Set the decryption key for the entry.
          if options[:password].kind_of?(String) then
            entry.password = options[:password]
          elsif ! options[:password].nil? then
            entry.password = options[:password][entry]
          end

          if entry.directory? then
            # Record the directories as they are encountered.
            directories << entry
          elsif entry.file? || (entry.symlink? && options[:symlinks]) then
            # Extract files and symlinks.
            entry.extract(
              options.merge(:file_path => file_path)
            )
          end
        rescue StandardError => error
          unless options[:on_error].nil? then
            case options[:on_error][entry, error]
            when :retry
              retry
            when :skip
            else
              raise
            end
          else
            raise
          end
        end
      end

      if options[:directories] then
        # Then extract the directory entries in depth first order so that time
        # stamps, ownerships, and permissions can be properly restored.
        directories.sort { |a, b| b.zip_path <=> a.zip_path }.each do |entry|
          begin
            entry.extract(
              options.merge(
                :file_path => File.join(destination, entry.zip_path)
              )
            )
          rescue StandardError => error
            unless options[:on_error].nil? then
              case options[:on_error][entry, error]
              when :retry
                retry
              when :skip
              else
                raise
              end
            else
              raise
            end
          end
        end
      end

      nil
    end

    private

    # <b>NOTE:</b> For now _io_ MUST be seekable.
    def parse(io)
      socd_pos = find_central_directory(io)
      io.seek(socd_pos)
      # Parse each entry in the central directory.
      loop do
        signature = IOExtensions.read_exactly(io, 4)
        break unless signature == CFH_SIGNATURE
        @entries << Zip::Entry.parse(io)
      end
      # Maybe add support for digital signatures and ZIP64 records... Later

      nil
    end

    # Returns the file offset of the first record in the central directory.
    # _io_ must be a seekable, readable, IO-like object.
    #
    # Raises Archive::Zip::UnzipError if the end of central directory signature
    # is not found where expected or at all.
    def find_central_directory(io)
      # First find the offset to the end of central directory record.
      # It is expected that the variable length comment field will usually be
      # empty and as a result the initial value of eocd_offset is all that is
      # necessary.
      #
      # NOTE: A cleverly crafted comment could throw this thing off if the
      # comment itself looks like a valid end of central directory record.
      eocd_offset = -22
      loop do
        io.seek(eocd_offset, IO::SEEK_END)
        if IOExtensions.read_exactly(io, 4) == EOCD_SIGNATURE then
          io.seek(16, IO::SEEK_CUR)
          if IOExtensions.read_exactly(io, 2).unpack('v')[0] ==
               (eocd_offset + 22).abs then
            break
          end
        end
        eocd_offset -= 1
      end
      # At this point, eocd_offset should point to the location of the end of
      # central directory record relative to the end of the archive.
      # Now, jump into the location in the record which contains a pointer to
      # the start of the central directory record and return the value.
      io.seek(eocd_offset + 16, IO::SEEK_END)
      return IOExtensions.read_exactly(io, 4).unpack('V')[0]
    rescue Errno::EINVAL
      raise Zip::UnzipError, 'unable to locate end-of-central-directory record'
    end

    # Writes all the entries of this archive to _io_.  _io_ must be a writable,
    # IO-like object providing a _write_ method.  Returns the total number of
    # bytes written.
    def dump(io)
      bytes_written = 0
      @entries.each do |entry|
        bytes_written += entry.dump_local_file_record(io, bytes_written)
      end
      central_directory_offset = bytes_written
      @entries.each do |entry|
        bytes_written += entry.dump_central_file_record(io)
      end
      central_directory_length = bytes_written - central_directory_offset
      bytes_written += io.write(EOCD_SIGNATURE)
      bytes_written += io.write(
        [
          0,
          0,
          @entries.length,
          @entries.length,
          central_directory_length,
          central_directory_offset,
          comment.bytesize
        ].pack('vvvvVVv')
      )
      bytes_written += io.write(comment)

      bytes_written
    end
  end
end
