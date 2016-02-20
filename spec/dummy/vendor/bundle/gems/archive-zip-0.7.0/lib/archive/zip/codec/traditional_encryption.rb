# encoding: UTF-8

require 'archive/support/integer'
require 'archive/support/io-like'
require 'archive/support/time'
require 'archive/support/zlib'
require 'archive/zip/codec'

module Archive; class Zip; module Codec
  # Archive::Zip::Codec::TraditionalEncryption is a handle for the traditional
  # encryption codec.
  class TraditionalEncryption
    # Archive::Zip::Codec::TraditionalEncryption::Base provides some basic
    # methods which are shared between
    # Archive::Zip::Codec::TraditionalEncryption::Encrypt and
    # Archive::Zip::Codec::TraditionalEncryption::Decrypt.
    #
    # Do not use this class directly.
    class Base
      # Creates a new instance of this class.  _io_ must be an IO-like object to
      # be used as a delegate for IO operations.  _password_ should be the
      # encryption key.  _mtime_ must be the last modified time of the entry to
      # be encrypted/decrypted.
      def initialize(io, password, mtime)
        @io = io
        @password = password.nil? ? '' : password
        @mtime = mtime
        initialize_keys
      end

      protected

      # The delegate IO-like object.
      attr_reader :io
      # The encryption key.
      attr_reader :password
      # The last modified time of the entry being encrypted.  This is used in
      # the entryption header as a way to check the password.
      attr_reader :mtime

      private

      # Initializes the keys used for encrypting/decrypting data by setting the
      # keys to well known values and then processing them with the password.
      def initialize_keys
        @key0 = 0x12345678
        @key1 = 0x23456789
        @key2 = 0x34567890
        @password.each_byte { |byte| update_keys(byte.chr) }
        nil
      end

      # Updates the keys following the ZIP specification using _char_, which
      # must be a single byte String.
      def update_keys(char)
        # For some reason not explained in the ZIP specification but discovered
        # in the source for InfoZIP, the old CRC value must first have its bits
        # flipped before processing.  The new CRC value must have its bits
        # flipped as well for storage and later use.  This applies to the
        # handling of @key0 and @key2.
        @key0 = ~Zlib.crc32(char, ~@key0)
        @key1 = ((@key1 + (@key0 & 0xff)) * 134775813 + 1) & 0xffffffff
        @key2 = ~Zlib.crc32((@key1 >> 24).chr, ~@key2)
        nil
      end

      # Returns the next decryption byte based on the current keys.
      def decrypt_byte
        temp = (@key2 | 2) & 0x0000ffff
        ((temp * (temp ^ 1)) >> 8) & 0x000000ff
      end
    end

    # Archive::Zip::Codec::TraditionalEncryption::Encrypt is a writable, IO-like
    # object which encrypts data written to it using the traditional encryption
    # algorithm as documented in the ZIP specification and writes the result to
    # a delegate IO object.  A _close_ method is also provided which can
    # optionally close the delegate object.
    #
    # Instances of this class should only be accessed via the
    # Archive::Zip::Codec::TraditionalEncryption#compressor method.
    class Encrypt < Base
      include IO::Like

      # Creates a new instance of this class with the given argument using #new
      # and then passes the instance to the given block.  The #close method is
      # guaranteed to be called after the block completes.
      #
      # Equivalent to #new if no block is given.
      def self.open(io, password, mtime)
        encrypt_io = new(io, password, mtime)
        return encrypt_io unless block_given?

        begin
          yield(encrypt_io)
        ensure
          encrypt_io.close unless encrypt_io.closed?
        end
      end

      # Creates a new instance of this class using _io_ as a data sink.  _io_
      # must be writable and must provide a write method as IO does or errors
      # will be raised when performing write operations.  _password_ should be
      # the encryption key.  _mtime_ must be the last modified time of the entry
      # to be encrypted/decrypted.
      #
      # The _flush_size_ attribute is set to <tt>0</tt> by default under the
      # assumption that _io_ is already buffered.
      def initialize(io, password, mtime)
        # Keep track of the total number of bytes written.
        # Set this here so that the call to #initialize_keys caused by the call
        # to super below does not cause errors in #unbuffered_write due to this
        # attribute being uninitialized.
        @total_bytes_in = 0

        # This buffer is used to hold the encrypted version of the string most
        # recently sent to #unbuffered_write.
        @encrypt_buffer = ''

        super(io, password, mtime)

        # Assume that the delegate IO object is already buffered.
        self.flush_size = 0
      end

      # Closes the stream after flushing the encryption buffer to the delegate.
      # If _close_delegate_ is +true+, the delegate object used as a data sink
      # will also be closed using its close method.
      #
      # Raises IOError if called more than once.
      def close(close_delegate = true)
        flush()
        begin
          until @encrypt_buffer.empty? do
            @encrypt_buffer.slice!(0, io.write(@encrypt_buffer))
          end
        rescue Errno::EAGAIN, Errno::EINTR
          retry if write_ready?
        end

        super()
        io.close if close_delegate
        nil
      end

      private

      # Extend the inherited initialize_keys method to further initialize the
      # keys by encrypting and writing a 12 byte header to the delegate IO
      # object.
      def initialize_keys
        super

        # Create and encrypt a 12 byte header to protect the encrypted file data
        # from attack.  The first 10 bytes are random, and the last 2 bytes are
        # the low order word in little endian byte order of the last modified
        # time of the entry in DOS format.
        header = ''
        10.times do
          header << rand(256).chr
        end
        header << mtime.to_dos_time.pack[0, 2]

        # Take care to ensure that all bytes in the header are written.
        while header.size > 0 do
          begin
            header.slice!(0, unbuffered_write(header))
          rescue Errno::EAGAIN, Errno::EINTR
            sleep(1)
          end
        end

        # Reset the total bytes written in order to disregard the header.
        @total_bytes_in = 0

        nil
      end

      # Allows resetting this object and the delegate object back to the
      # beginning of the stream or reporting the current position in the stream.
      #
      # Raises Errno::EINVAL unless _offset_ is <tt>0</tt> and _whence_ is
      # either IO::SEEK_SET or IO::SEEK_CUR.  Raises Errno::EINVAL if _whence_
      # is IO::SEEK_SEK and the delegate object does not respond to the _rewind_
      # method.
      def unbuffered_seek(offset, whence = IO::SEEK_SET)
        unless offset == 0 &&
               ((whence == IO::SEEK_SET && @io.respond_to?(:rewind)) ||
                whence == IO::SEEK_CUR) then
          raise Errno::EINVAL
        end

        case whence
        when IO::SEEK_SET
          io.rewind
          @encrypt_buffer = ''
          initialize_keys
          @total_bytes_in = 0
        when IO::SEEK_CUR
          @total_bytes_in
        end
      end

      # Encrypts and writes _string_ to the delegate IO object.  Returns the
      # number of bytes of _string_ written.
      def unbuffered_write(string)
        # First try to write out the contents of the encrypt buffer because if
        # that raises a failure we can let that pass up the call stack without
        # having polluted the encryption state.
        until @encrypt_buffer.empty? do
          @encrypt_buffer.slice!(0, io.write(@encrypt_buffer))
        end
        # At this point we can encrypt the given string into a new buffer and
        # behave as if it was written.
        string.each_byte do |byte|
          temp = decrypt_byte
          @encrypt_buffer << (byte ^ temp).chr
          update_keys(byte.chr)
        end
        @total_bytes_in += string.length
        string.length
      end
    end

    # Archive::Zip::Codec::TraditionalEncryption::Decrypt is a readable, IO-like
    # object which decrypts data data it reads from a delegate IO object using
    # the traditional encryption algorithm as documented in the ZIP
    # specification.  A _close_ method is also provided which can optionally
    # close the delegate object.
    #
    # Instances of this class should only be accessed via the
    # Archive::Zip::Codec::TraditionalEncryption#decompressor method.
    class Decrypt < Base
      include IO::Like

      # Creates a new instance of this class with the given argument using #new
      # and then passes the instance to the given block.  The #close method is
      # guaranteed to be called after the block completes.
      #
      # Equivalent to #new if no block is given.
      def self.open(io, password, mtime)
        decrypt_io = new(io, password, mtime)
        return decrypt_io unless block_given?

        begin
          yield(decrypt_io)
        ensure
          decrypt_io.close unless decrypt_io.closed?
        end
      end

      # Creates a new instance of this class using _io_ as a data source.  _io_
      # must be readable and provide a _read_ method as an IO instance would or
      # errors will be raised when performing read operations.  _password_
      # should be the encryption key.  _mtime_ must be the last modified time of
      # the entry to be encrypted/decrypted.
      #
      # This class has extremely limited seek capabilities.  It is possible to
      # seek with an offset of <tt>0</tt> and a whence of <tt>IO::SEEK_CUR</tt>.
      # As a result, the _pos_ and _tell_ methods also work as expected.
      #
      # Due to certain optimizations within IO::Like#seek and if there is data
      # in the read buffer, the _seek_ method can be used to seek forward from
      # the current stream position up to the end of the buffer.  Unless it is
      # known definitively how much data is in the buffer, it is best to avoid
      # relying on this behavior.
      #
      # If _io_ also responds to _rewind_, then the _rewind_ method of this
      # class can be used to reset the whole stream back to the beginning. Using
      # _seek_ of this class to seek directly to offset <tt>0</tt> using
      # <tt>IO::SEEK_SET</tt> for whence will also work in this case.
      #
      # Any other seeking attempts, will raise Errno::EINVAL exceptions.
      #
      # The _fill_size_ attribute is set to <tt>0</tt> by default under the
      # assumption that _io_ is already buffered.
      def initialize(io, password, mtime)
        # Keep track of the total number of bytes read.
        # Set this here so that the call to #initialize_keys caused by the call
        # to super below does not cause errors in #unbuffered_read due to this
        # attribute being uninitialized.
        @total_bytes_out = 0

        super(io, password, mtime)

        # Assume that the delegate IO object is already buffered.
        self.fill_size = 0
      end

      # Closes this object so that further write operations will fail.  If
      # _close_delegate_ is +true+, the delegate object used as a data source
      # will also be closed using its close method.
      def close(close_delegate = true)
        super()
        io.close if close_delegate
      end

      private

      # Extend the inherited initialize_keys method to further initialize the
      # keys by encrypting and writing a 12 byte header to the delegate IO
      # object.
      def initialize_keys
        super

        # Load the 12 byte header taking care to ensure that all bytes are read.
        bytes_needed = 12
        while bytes_needed > 0 do
          begin
            bytes_read = unbuffered_read(bytes_needed)
            bytes_needed -= bytes_read.size
          rescue Errno::EAGAIN, Errno::EINTR
            sleep(1)
          end
        end

        # Reset the total bytes read in order to disregard the header.
        @total_bytes_out = 0

        nil
      end

      # Reads, decrypts, and returns at most _length_ bytes from the delegate IO
      # object.
      #
      # Raises EOFError if there is no data to read.
      def unbuffered_read(length)
        buffer = io.read(length)
        raise EOFError, 'end of file reached' if buffer.nil?
        @total_bytes_out += buffer.length

        0.upto(buffer.length - 1) do |i|
          buffer[i] = (buffer[i].ord ^ decrypt_byte).chr
          update_keys(buffer[i].chr)
        end
        buffer
      end

      # Allows resetting this object and the delegate object back to the
      # beginning of the stream or reporting the current position in the stream.
      #
      # Raises Errno::EINVAL unless _offset_ is <tt>0</tt> and _whence_ is
      # either IO::SEEK_SET or IO::SEEK_CUR.  Raises Errno::EINVAL if _whence_
      # is IO::SEEK_SEK and the delegate object does not respond to the _rewind_
      # method.
      def unbuffered_seek(offset, whence = IO::SEEK_SET)
        unless offset == 0 &&
               ((whence == IO::SEEK_SET && @io.respond_to?(:rewind)) ||
                whence == IO::SEEK_CUR) then
          raise Errno::EINVAL
        end

        case whence
        when IO::SEEK_SET
          io.rewind
          initialize_keys
          @total_bytes_out = 0
        when IO::SEEK_CUR
          @total_bytes_out
        end
      end
    end

    # The last modified time of the entry to be processed.  Set this before
    # calling #encryptor or #decryptor.
    attr_accessor :mtime

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::TraditionalEncryption::Encrypt object using that
    # class' open method.
    def encryptor(io, password, &b)
      Encrypt.open(io, password, mtime, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::TraditionalEncryption::Decrypt object using that
    # class' open method.
    def decryptor(io, password, &b)
      Decrypt.open(io, password, mtime, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns an integer which indicates the version of the official ZIP
    # specification which introduced support for this encryption codec.
    def version_needed_to_extract
      0x0014
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns an integer representing the general purpose flags of a ZIP archive
    # entry using this encryption codec.
    def general_purpose_flags
      0b0000000000000001
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns the size of the encryption header in bytes.
    def header_size
      12
    end
  end
end; end; end
