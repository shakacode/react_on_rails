# encoding: UTF-8

require 'archive/support/zlib'
require 'archive/zip/codec'
require 'archive/zip/data_descriptor'

module Archive; class Zip; module Codec
  # Archive::Zip::Codec::Deflate is a handle for the deflate-inflate codec
  # as defined in Zlib which provides convenient interfaces for writing and
  # reading deflated streams.
  class Deflate
    # Archive::Zip::Codec::Deflate::Compress extends Zlib::ZWriter in order to
    # specify the standard Zlib options required by ZIP archives and to provide
    # a close method which can optionally close the delegate IO-like object.
    # In addition a convenience method is provided for generating DataDescriptor
    # objects based on the data which is passed through this object.
    #
    # Instances of this class should only be accessed via the
    # Archive::Zip::Codec::Deflate#compressor method.
    class Compress < Zlib::ZWriter
      # Creates a new instance of this class with the given arguments using #new
      # and then passes the instance to the given block.  The #close method is
      # guaranteed to be called after the block completes.
      #
      # Equivalent to #new if no block is given.
      def self.open(io, compression_level)
        deflate_io = new(io, compression_level)
        return deflate_io unless block_given?

        begin
          yield(deflate_io)
        ensure
          deflate_io.close unless deflate_io.closed?
        end
      end

      # Creates a new instance of this class using _io_ as a data sink.  _io_
      # must be writable and must provide a _write_ method as IO does or errors
      # will be raised when performing write operations.  _compression_level_
      # must be one of Zlib::DEFAULT_COMPRESSION, Zlib::BEST_COMPRESSION,
      # Zlib::BEST_SPEED, or Zlib::NO_COMPRESSION and specifies the amount of
      # compression to be applied to the data stream.
      def initialize(io, compression_level)
        super(io, compression_level, -Zlib::MAX_WBITS)
        @crc32 = 0
      end

      # The CRC32 checksum of the uncompressed data written using this object.
      #
      # <b>NOTE:</b> Anything still in the internal write buffer has not been
      # processed, so calling #flush prior to examining this attribute may be
      # necessary for an accurate computation.
      attr_reader :crc32
      alias :checksum :crc32

      # Closes this object so that further write operations will fail.  If
      # _close_delegate_ is +true+, the delegate object used as a data sink will
      # also be closed using its close method.
      def close(close_delegate = true)
        super()
        delegate.close if close_delegate
      end

      # Returns an instance of Archive::Zip::DataDescriptor with information
      # regarding the data which has passed through this object to the delegate
      # object.  The close or flush methods should be called before using this
      # method in order to ensure that any possibly buffered data is flushed to
      # the delegate object; otherwise, the contents of the data descriptor may
      # be inaccurate.
      def data_descriptor
        DataDescriptor.new(crc32, compressed_size, uncompressed_size)
      end

      private

      def unbuffered_seek(offset, whence = IO::SEEK_SET)
        result = super(offset, whence)
        @crc32 = 0 if whence == IO::SEEK_SET
        result
      end

      def unbuffered_write(string)
        result = super(string)
        @crc32 = Zlib.crc32(string, @crc32)
        result
      end
    end

    # Archive::Zip::Codec::Deflate::Decompress extends Zlib::ZReader in order to
    # specify the standard Zlib options required by ZIP archives and to provide
    # a close method which can optionally close the delegate IO-like object.
    # In addition a convenience method is provided for generating DataDescriptor
    # objects based on the data which is passed through this object.
    #
    # Instances of this class should only be accessed via the
    # Archive::Zip::Codec::Deflate#decompressor method.
    class Decompress < Zlib::ZReader
      # Creates a new instance of this class with the given arguments using #new
      # and then passes the instance to the given block.  The #close method is
      # guaranteed to be called after the block completes.
      #
      # Equivalent to #new if no block is given.
      def self.open(io)
        inflate_io = new(io)
        return inflate_io unless block_given?

        begin
          yield(inflate_io)
        ensure
          inflate_io.close unless inflate_io.closed?
        end
      end

      # Creates a new instance of this class using _io_ as a data source.  _io_
      # must be readable and provide a _read_ method as IO does or errors will
      # be raised when performing read operations.  If _io_ provides a _rewind_
      # method, this class' _rewind_ method will be enabled.
      def initialize(io)
        super(io, -Zlib::MAX_WBITS)
        @crc32 = 0
      end

      # The CRC32 checksum of the uncompressed data read using this object.
      #
      # <b>NOTE:</b> The contents of the internal read buffer are immediately
      # processed any time the internal buffer is filled, so this checksum is
      # only accurate if all data has been read out of this object.
      attr_reader :crc32
      alias :checksum :crc32

      # Closes this object so that further read operations will fail.  If
      # _close_delegate_ is +true+, the delegate object used as a data source
      # will also be closed using its close method.
      def close(close_delegate = true)
        super()
        delegate.close if close_delegate
      end

      # Returns an instance of Archive::Zip::DataDescriptor with information
      # regarding the data which has passed through this object from the
      # delegate object.  It is recommended to call the close method before
      # calling this in order to ensure that no further read operations change
      # the state of this object.
      def data_descriptor
        DataDescriptor.new(crc32, compressed_size, uncompressed_size)
      end

      private

      def unbuffered_read(length)
        result = super(length)
        @crc32 = Zlib.crc32(result, @crc32)
        result
      end

      def unbuffered_seek(offset, whence = IO::SEEK_SET)
        result = super(offset, whence)
        @crc32 = 0 if whence == IO::SEEK_SET
        result
      end
    end

    # The numeric identifier assigned to this compression codec by the ZIP
    # specification.
    ID = 8

    # Register this compression codec.
    COMPRESSION_CODECS[ID] = self

    # A bit mask used to denote that Zlib's default compression level should be
    # used.
    NORMAL = 0b000
    # A bit mask used to denote that Zlib's highest/slowest compression level
    # should be used.
    MAXIMUM = 0b010
    # A bit mask used to denote that Zlib's lowest/fastest compression level
    # should be used.
    FAST = 0b100
    # A bit mask used to denote that Zlib should not compress data at all.
    SUPER_FAST = 0b110

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # Creates a new instance of this class using bits 1 and 2 of
    # _general_purpose_flags_ to select a compression level to be used by
    # #compressor to set up a compression IO object.  The constants NORMAL,
    # MAXIMUM, FAST, and SUPER_FAST can be used for _general_purpose_flags_ to
    # manually set the compression level.
    def initialize(general_purpose_flags = NORMAL)
      @compression_level = general_purpose_flags & 0b110
      @zlib_compression_level = case @compression_level
                                when NORMAL
                                  Zlib::DEFAULT_COMPRESSION
                                when MAXIMUM
                                  Zlib::BEST_COMPRESSION
                                when FAST
                                  Zlib::BEST_SPEED
                                when SUPER_FAST
                                  Zlib::NO_COMPRESSION
                                else
                                  raise Error, 'Invalid compression level'
                                end
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::Deflate::Compress object using that class' open
    # method.  The compression level for the open method is pulled from the
    # value of the _general_purpose_flags_ argument of new.
    def compressor(io, &b)
      Compress.open(io, @zlib_compression_level, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::Deflate::Decompress object using that class' open
    # method.
    def decompressor(io, &b)
      Decompress.open(io, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # Returns an integer which indicates the version of the official ZIP
    # specification which introduced support for this compression codec.
    def version_needed_to_extract
      0x0014
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # Returns an integer used to flag that this compression codec is used for a
    # particular ZIP archive entry.
    def compression_method
      ID
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # Returns an integer representing the general purpose flags of a ZIP archive
    # entry where bits 1 and 2 are set according to the compression level
    # selected for this object.  All other bits are zero'd out.
    def general_purpose_flags
      @compression_level
    end
  end
end; end; end

