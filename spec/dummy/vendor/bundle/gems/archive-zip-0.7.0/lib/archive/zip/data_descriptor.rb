# encoding: UTF-8

module Archive; class Zip
  # Archive::Zip::DataDescriptor is a convenience class which bundles important
  # information concerning the compressed data in a ZIP archive entry and allows
  # easy comparisons between instances of itself.
  class DataDescriptor
    # Create a new instance of this class where <em>crc32</em>,
    # _compressed_size_, and _uncompressed_size_ are all integers representing a
    # CRC32 checksum of uncompressed data, the size of compressed data, and the
    # size of uncompressed data respectively.
    def initialize(crc32, compressed_size, uncompressed_size)
      @crc32 = crc32
      @compressed_size = compressed_size
      @uncompressed_size = uncompressed_size
    end

    # A CRC32 checksum over some set of uncompressed data.
    attr_reader :crc32
    # A count of the number of bytes of compressed data associated with a set of
    # uncompressed data.
    attr_reader :compressed_size
    # A count of the number of bytes of a set of uncompressed data.
    attr_reader :uncompressed_size

    # Compares the crc32 and uncompressed_size attributes of this object with
    # like-named attributes of _other_ and raises Archive::Zip::Error for any
    # mismatches.
    #
    # <b>NOTE:</b> The compressed_size attribute is not checked because
    # encrypted entries may have misleading compressed sizes.  Checking only the
    # CRC32 and uncompressed size of the data should be sufficient to ensure
    # that an entry has been successfully extracted.
    def verify(other)
      unless crc32 == other.crc32 then
        raise Zip::Error,
          "CRC32 mismatch: #{crc32.to_s(16)} vs. #{other.crc32.to_s(16)}"
      end
      unless uncompressed_size == other.uncompressed_size then
        raise Zip::Error,
          "uncompressed size mismatch: #{uncompressed_size} vs. #{other.uncompressed_size}"
      end
    end

    # Writes the data wrapped in this object to _io_ which must be a writable,
    # IO-like object providing a _write_ method.  Returns the number of bytes
    # written.
    def dump(io)
      io.write(
        [
          crc32,
          compressed_size,
          uncompressed_size
        ].pack('VVV')
      )
    end
  end
end; end
