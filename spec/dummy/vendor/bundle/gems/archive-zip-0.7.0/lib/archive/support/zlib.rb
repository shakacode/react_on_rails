# encoding: UTF-8

require 'zlib'

require 'archive/support/io-like'

module Zlib # :nodoc:
  # The maximum size of the zlib history buffer.  Note that zlib allows larger
  # values to enable different inflate modes.  See Zlib::Inflate.new for details.
  # Provided here only for Ruby versions that do not provide it.
  MAX_WBITS = Deflate::MAX_WBITS unless const_defined?(:MAX_WBITS)

  # A deflate strategy which limits match distances to 1, also known as
  # run-length encoding.  Provided here only for Ruby versions that do not
  # provide it.
  RLE = 3 unless const_defined?(:RLE)

  # A deflate strategy which does not use dynamic Huffman codes, allowing for a
  # simpler decoder to be used to inflate.  Provided here only for Ruby versions
  # that do not provide it.
  FIXED = 4 unless const_defined?(:FIXED)

  # Zlib::ZWriter is a writable, IO-like object (includes IO::Like) which wraps
  # other writable, IO-like objects in order to facilitate writing data to those
  # objects using the deflate method of compression.
  class ZWriter
    include IO::Like

    # Creates a new instance of this class with the given arguments using #new
    # and then passes the instance to the given block.  The #close method is
    # guaranteed to be called after the block completes.
    #
    # Equivalent to #new if no block is given.
    def self.open(delegate, level = nil, window_bits = nil, mem_level = nil, strategy = nil)
      zw = new(delegate, level, window_bits, mem_level, strategy)
      return zw unless block_given?

      begin
        yield(zw)
      ensure
        zw.close unless zw.closed?
      end
    end

    # Creates a new instance of this class.  _delegate_ must respond to the
    # _write_ method as an instance of IO would.  _level_, _window_bits_,
    # _mem_level_, and _strategy_ are all passed directly to
    # Zlib::Deflate.new().
    #
    # <b>
    # The following descriptions of _level_, _window_bits_, _mem_level_, and
    # _strategy_ are based upon or pulled largely verbatim from descriptions
    # found in zlib.h version 1.2.3 with changes made to account for different
    # parameter names and to improve readability.  Some of the statements
    # concerning default settings or value ranges may not be accurate depending
    # on the version of the zlib library used by a given Ruby interpreter.
    # </b>
    #
    # The _level_ parameter must be +nil+, Zlib::DEFAULT_COMPRESSION, or between
    # <tt>0</tt> and <tt>9</tt>: <tt>1</tt> gives best speed, <tt>9</tt> gives
    # best compression, <tt>0</tt> gives no compression at all (the input data
    # is simply copied a block at a time).  Zlib::DEFAULT_COMPRESSION requests a
    # default compromise between speed and compression (currently equivalent to
    # level <tt>6</tt>).  If unspecified or +nil+, _level_ defaults to
    # Zlib::DEFAULT_COMPRESSION.
    #
    # The _window_bits_ parameter specifies the size of the history buffer, the
    # format of the compressed stream, and the kind of checksum returned by the
    # checksum method.  The size of the history buffer is specified by setting
    # the value of _window_bits_ in the range of <tt>8</tt>..<tt>15</tt>,
    # inclusive.  A value of <tt>8</tt> indicates a small window which reduces
    # memory usage but lowers the compression ratio while a value of <tt>15</tt>
    # indicates a larger window which increases memory usage but raises the
    # compression ratio.  Modification of this base value for _window_bits_ as
    # noted below dictates what kind of compressed stream and checksum will be
    # produced <b>while preserving the setting for the history buffer</b>.
    #
    # If nothing else is done to the base value of _window_bits_, a zlib stream
    # is to be produced with an appropriate header and trailer.  In this case
    # the checksum method of this object will be an adler32.
    #
    # Adding <tt>16</tt> to the base value of _window_bits_ indicates that a
    # gzip stream is to be produced with an appropriate header and trailer.  The
    # gzip header will have no file name, no extra data, no comment, no
    # modification time (set to zero), no header crc, and the operating system
    # will be set to <tt>255</tt> (unknown).  In this case the checksum
    # attribute of this object will be a crc32.
    #
    # Finally, negating the base value of _window_bits_ indicates that a raw
    # zlib stream is to be produced without any header or trailer.  In this case
    # the checksum method of this object will always return <tt>nil</tt>.  This is
    # for use with other formats that use the deflate compressed data format
    # such as zip.  Such formats should provide their own check values.
    #
    # If unspecified or +nil+, _window_bits_ defaults to <tt>15</tt>.
    #
    # The _mem_level_ parameter specifies how much memory should be allocated
    # for the internal compression state.  A value of <tt>1</tt> uses minimum
    # memory but is slow and reduces compression ratio; a value of <tt>9</tt>
    # uses maximum memory for optimal speed.  The default value is <tt>8</tt> if
    # unspecified or +nil+.
    #
    # The _strategy_ parameter is used to tune the compression algorithm.  It
    # only affects the compression ratio but not the correctness of the
    # compressed output even if it is not set appropriately.  The default value
    # is Zlib::DEFAULT_STRATEGY if unspecified or +nil+.
    #
    # Use the value Zlib::DEFAULT_STRATEGY for normal data, Zlib::FILTERED for
    # data produced by a filter (or predictor), Zlib::HUFFMAN_ONLY to force
    # Huffman encoding only (no string match), Zlib::RLE to limit match
    # distances to 1 (run-length encoding), or Zlib::FIXED to simplify decoder
    # requirements.
    #
    # The effect of Zlib::FILTERED is to force more Huffman coding and less
    # string matching; it is somewhat intermediate between
    # Zlib::DEFAULT_STRATEGY and Zlib::HUFFMAN_ONLY.  Filtered data consists
    # mostly of small values with a somewhat random distribution.  In this case,
    # the compression algorithm is tuned to compress them better.
    #
    # Zlib::RLE is designed to be almost as fast as Zlib::HUFFMAN_ONLY, but give
    # better compression for PNG image data.
    #
    # Zlib::FIXED prevents the use of dynamic Huffman codes, allowing for a
    # simpler decoder for special applications.
    #
    # This class has extremely limited seek capabilities.  It is possible to
    # seek with an offset of <tt>0</tt> and a whence of <tt>IO::SEEK_CUR</tt>.
    # As a result, the _pos_ and _tell_ methods also work as expected.
    #
    # If _delegate_ also responds to _rewind_, then the _rewind_ method of this
    # class can be used to reset the whole stream back to the beginning. Using
    # _seek_ of this class to seek directly to offset <tt>0</tt> using
    # <tt>IO::SEEK_SET</tt> for whence will also work in this case.
    #
    # <b>NOTE:</b> Due to limitations in Ruby's finalization capabilities, the
    # #close method is _not_ automatically called when this object is garbage
    # collected.  Make sure to call #close when finished with this object.
    def initialize(delegate, level = nil, window_bits = nil, mem_level = nil, strategy = nil)
      @delegate = delegate
      @level = level
      @window_bits = window_bits
      @mem_level = mem_level
      @strategy = strategy
      @deflater = Zlib::Deflate.new(@level, @window_bits, @mem_level, @strategy)
      @deflate_buffer = ''
      @checksum = nil
      @compressed_size = nil
      @uncompressed_size = nil
    end

    protected

    # The delegate object to which compressed data is written.
    attr_reader :delegate

    public

    # Returns the checksum computed over the data written to this stream so far.
    #
    # <b>NOTE:</b> Refer to the documentation of #new concerning _window_bits_
    # to learn what kind of checksum will be returned.
    #
    # <b>NOTE:</b> Anything still in the internal write buffer has not been
    # processed, so calling #flush prior to calling this method may be necessary
    # for an accurate checksum.
    def checksum
      return nil if @window_bits < 0
      @deflater.closed? ? @checksum : @deflater.adler
    end

    # Closes the writer by finishing the compressed data and flushing it to the
    # delegate.
    #
    # Raises IOError if called more than once.
    def close
      flush()
      @deflate_buffer << @deflater.finish unless @deflater.finished?
      begin
        until @deflate_buffer.empty? do
          @deflate_buffer.slice!(0, delegate.write(@deflate_buffer))
        end
      rescue Errno::EAGAIN, Errno::EINTR
        retry if write_ready?
      end
      @checksum = @deflater.adler
      @compressed_size = @deflater.total_out
      @uncompressed_size = @deflater.total_in
      @deflater.close
      super()
      nil
    end

    # Returns the number of bytes of compressed data produced so far.
    #
    # <b>NOTE:</b> This value is only updated when both the internal write
    # buffer is flushed and there is enough data to produce a compressed block.
    # It does not necessarily reflect the amount of data written to the
    # delegate until this stream is closed however.  Until then the only
    # guarantee is that the value will be greater than or equal to <tt>0</tt>.
    def compressed_size
      @deflater.closed? ? @compressed_size : @deflater.total_out
    end

    # Returns the number of bytes sent to be compressed so far.
    #
    # <b>NOTE:</b> This value is only updated when the internal write buffer is
    # flushed.
    def uncompressed_size
      @deflater.closed? ? @uncompressed_size : @deflater.total_in
    end

    private

    # Allows resetting this object and the delegate object back to the beginning
    # of the stream or reporting the current position in the stream.
    #
    # Raises Errno::EINVAL unless _offset_ is <tt>0</tt> and _whence_ is either
    # IO::SEEK_SET or IO::SEEK_CUR.  Raises Errno::EINVAL if _whence_ is
    # IO::SEEK_SEK and the delegate object does not respond to the _rewind_
    # method.
    def unbuffered_seek(offset, whence = IO::SEEK_SET)
      unless offset == 0 &&
             ((whence == IO::SEEK_SET && delegate.respond_to?(:rewind)) ||
              whence == IO::SEEK_CUR) then
        raise Errno::EINVAL
      end

      case whence
      when IO::SEEK_SET
        delegate.rewind
        @deflater.finish
        @deflater.close
        @deflater = Zlib::Deflate.new(
          @level, @window_bits, @mem_level, @strategy
        )
        @deflate_buffer = ''
        0
      when IO::SEEK_CUR
        @deflater.total_in
      end
    end

    def unbuffered_write(string)
      # First try to write out the contents of the deflate buffer because if
      # that raises a failure we can let that pass up the call stack without
      # having polluted the deflater instance.
      until @deflate_buffer.empty? do
        @deflate_buffer.slice!(0, delegate.write(@deflate_buffer))
      end
      # At this point we can deflate the given string into a new buffer and
      # behave as if it was written.
      @deflate_buffer = @deflater.deflate(string)
      string.length
    end
  end

  # Zlib::ZReader is a readable, IO-like object (includes IO::Like) which wraps
  # other readable, IO-like objects in order to facilitate reading data from
  # those objects using the inflate method of decompression.
  class ZReader
    include IO::Like

    # The number of bytes to read from the delegate object each time the
    # internal read buffer is filled.
    DEFAULT_DELEGATE_READ_SIZE = 4096

    # Creates a new instance of this class with the given arguments using #new
    # and then passes the instance to the given block.  The #close method is
    # guaranteed to be called after the block completes.
    #
    # Equivalent to #new if no block is given.
    def self.open(delegate, window_bits = nil)
      zr = new(delegate, window_bits)
      return zr unless block_given?

      begin
        yield(zr)
      ensure
        zr.close unless zr.closed?
      end
    end

    # Creates a new instance of this class.  _delegate_ must respond to the
    # _read_ method as an IO instance would.  _window_bits_ is passed directly
    # to Zlib::Inflate.new().
    #
    # <b>
    # The following description of _window_bits_ is based on the description
    # found in zlib.h version 1.2.3.  Some of the statements concerning default
    # settings or value ranges may not be accurate depending on the version of
    # the zlib library used by a given Ruby interpreter.
    # </b>
    #
    # The _window_bits_ parameter specifies the size of the history buffer, the
    # format of the compressed stream, and the kind of checksum returned by the
    # checksum method.  The size of the history buffer is specified by setting
    # the value of _window_bits_ in the range of <tt>8</tt>..<tt>15</tt>,
    # inclusive.  It must be at least as large as the setting used to create the
    # stream or a Zlib::DataError will be raised.  Modification of this base
    # value for _window_bits_ as noted below dictates what kind of compressed
    # stream is expected and what kind of checksum will be produced <b>while
    # preserving the setting for the history buffer</b>.
    #
    # If nothing else is done to the base value of _window_bits_, a zlib stream
    # is expected with an appropriate header and trailer.  In this case the
    # checksum method of this object will be an adler32.
    #
    # Adding <tt>16</tt> to the base value of _window_bits_ indicates that a
    # gzip stream is expected with an appropriate header and trailer.  In this
    # case the checksum method of this object will be a crc32.
    #
    # Adding <tt>32</tt> to the base value of _window_bits_ indicates that an
    # automatic detection of the stream format should be made based on the
    # header in the stream.  In this case the checksum method of this object
    # will depend on whether a zlib or a gzip stream is detected.
    #
    # Finally, negating the base value of _window_bits_ indicates that a raw
    # zlib stream is expected without any header or trailer.  In this case the
    # checksum method of this object will always return <tt>nil</tt>.  This is for
    # use with other formats that use the deflate compressed data format such as
    # zip.  Such formats should provide their own check values.
    #
    # If unspecified or +nil+, _window_bits_ defaults to <tt>15</tt>.
    #
    # In all cases, Zlib::DataError is raised if the wrong stream format is
    # found <b>when reading</b>.
    #
    # This class has extremely limited seek capabilities.  It is possible to
    # seek with an offset of <tt>0</tt> and a whence of <tt>IO::SEEK_CUR</tt>.
    # As a result, the _pos_ and _tell_ methods also work as expected.
    #
    # Due to certain optimizations within IO::Like#seek and if there is data in
    # the read buffer, the _seek_ method can be used to seek forward from the
    # current stream position up to the end of the buffer.  Unless it is known
    # definitively how much data is in the buffer, it is best to avoid relying
    # on this behavior.
    #
    # If _delegate_ also responds to _rewind_, then the _rewind_ method of this
    # class can be used to reset the whole stream back to the beginning. Using
    # _seek_ of this class to seek directly to offset <tt>0</tt> using
    # <tt>IO::SEEK_SET</tt> for whence will also work in this case.
    #
    # Any other seeking attempts, will raise Errno::EINVAL exceptions.
    #
    # <b>NOTE:</b> Due to limitations in Ruby's finalization capabilities, the
    # #close method is _not_ automatically called when this object is garbage
    # collected.  Make sure to call #close when finished with this object.
    def initialize(delegate, window_bits = nil)
      @delegate = delegate
      @delegate_read_size = DEFAULT_DELEGATE_READ_SIZE
      @window_bits = window_bits
      @inflater = Zlib::Inflate.new(@window_bits)
      @inflate_buffer = ''
      @checksum = nil
      @compressed_size = nil
      @uncompressed_size = nil
    end

    # The number of bytes to read from the delegate object each time the
    # internal read buffer is filled.
    attr_accessor :delegate_read_size

    protected

    # The delegate object from which compressed data is read.
    attr_reader :delegate

    public

    # Returns the checksum computed over the data read from this stream.
    #
    # <b>NOTE:</b> Refer to the documentation of #new concerning _window_bits_
    # to learn what kind of checksum will be returned.
    #
    # <b>NOTE:</b> The contents of the internal read buffer are immediately
    # processed any time the internal buffer is filled, so this checksum is only
    # accurate if all data has been read out of this object.
    def checksum
      return nil if @window_bits < 0
      @inflater.closed? ? @checksum : @inflater.adler
    end

    # Closes the reader.
    #
    # Raises IOError if called more than once.
    def close
      super()
      @checksum = @inflater.adler
      @compressed_size = @inflater.total_in
      @uncompressed_size = @inflater.total_out
      @inflater.close
      nil
    end

    # Returns the number of bytes sent to be compressed so far.
    #
    # <b>NOTE:</b> This value is updated whenever the internal read buffer needs
    # to be filled, not when data is read out of this stream.
    def compressed_size
      @inflater.closed? ? @compressed_size : @inflater.total_in
    end

    # Returns the number of bytes of decompressed data produced so far.
    #
    # <b>NOTE:</b> This value is updated whenever the internal read buffer needs
    # to be filled, not when data is read out of this stream.
    def uncompressed_size
      @inflater.closed? ? @uncompressed_size : @inflater.total_out
    end

    private

    def unbuffered_read(length)
      if @inflate_buffer.empty? && @inflater.finished? then
        raise EOFError, 'end of file reached'
      end

      begin
        while @inflate_buffer.length < length && ! @inflater.finished? do
          @inflate_buffer <<
            @inflater.inflate(delegate.read(@delegate_read_size))
        end
      rescue Errno::EINTR, Errno::EAGAIN
        raise if @inflate_buffer.empty?
      end
      @inflate_buffer.slice!(0, length)
    end

    # Allows resetting this object and the delegate object back to the beginning
    # of the stream or reporting the current position in the stream.
    #
    # Raises Errno::EINVAL unless _offset_ is <tt>0</tt> and _whence_ is either
    # IO::SEEK_SET or IO::SEEK_CUR.  Raises Errno::EINVAL if _whence_ is
    # IO::SEEK_SEK and the delegate object does not respond to the _rewind_
    # method.
    def unbuffered_seek(offset, whence = IO::SEEK_SET)
      unless offset == 0 &&
             ((whence == IO::SEEK_SET && delegate.respond_to?(:rewind)) ||
              whence == IO::SEEK_CUR) then
        raise Errno::EINVAL
      end

      case whence
      when IO::SEEK_SET
        delegate.rewind
        @inflater.close
        @inflater = Zlib::Inflate.new(@window_bits)
        @inflate_buffer = ''
        0
      when IO::SEEK_CUR
        @inflater.total_out - @inflate_buffer.length
      end
    end
  end
end
