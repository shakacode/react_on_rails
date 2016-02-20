# encoding: UTF-8

require 'archive/support/io-like'

# IOWindow represents an IO object which wraps another one allowing read and/or
# write access to a subset of the data within the stream.
#
# <b>NOTE:</b> This object is NOT thread safe.
class IOWindow
  include IO::Like

  # Creates a new instance of this class using _io_ as the data source
  # and where _window_position_ and _window_size_ define the location and size
  # of data window respectively.
  #
  # _io_ must be opened for reading and must be seekable.  _window_position_
  # must be an integer greater than or equal to 0.  _window_size_ must be an
  # integer greater than or equal to 0.
  def initialize(io, window_position, window_size)
    @io = io
    @unbuffered_pos = 0
    self.window_position = window_position
    self.window_size = window_size
  end

  # The file position at which this window begins.
  attr_reader :window_position

  # Set the file position at which this window begins.
  # _window_position_ must be an integer greater than or equal to 0.
  def window_position=(window_position)
    unless window_position.respond_to?(:to_int) then
      raise TypeError, "can't convert #{window_position.class} into Integer"
    end
    window_position = window_position.to_int
    if window_position < 0 then
      raise ArgumentError, 'non-positive window position given'
    end

    @window_position = window_position
  end

  # The size of the window.
  attr_reader :window_size

  # Set the size of the window.
  # _window_size_ must be an integer greater than or equal to 0.
  def window_size=(window_size)
    unless window_size.respond_to?(:to_int) then
      raise TypeError, "can't convert #{window_size.class} into Integer"
    end
    window_size = window_size.to_int
    raise ArgumentError, 'non-positive window size given' if window_size < 0

    @window_size = window_size
  end

  private

  def unbuffered_read(length)
    restore_self

    # Error out if the end of the window is reached.
    raise EOFError, 'end of file reached' if @unbuffered_pos >= @window_size

    # Limit the read operation to the window.
    length = @window_size - @unbuffered_pos if @unbuffered_pos + length > @window_size

    # Fill a buffer with the data from the delegate.
    buffer = @io.read(length)
    # Error out if the end of the delegate is reached.
    raise EOFError, 'end of file reached' if buffer.nil?

    # Update the position.
    @unbuffered_pos += buffer.length

    buffer
  ensure
    restore_delegate
  end

  def unbuffered_seek(offset, whence = IO::SEEK_SET)
    # Convert the offset and whence into an absolute position.
    case whence
    when IO::SEEK_SET
      new_pos = offset
    when IO::SEEK_CUR
      new_pos = @unbuffered_pos + offset
    when IO::SEEK_END
      new_pos = @window_size + offset
    end

    # Error out if the position is outside the window.
    raise Errno::EINVAL, 'Invalid argument' if new_pos < 0 or new_pos > @window_size

    # Set the new position.
    @unbuffered_pos = new_pos
  end

  # Restores the state of the delegate IO object to that saved by a prior call
  # to #restore_self.
  def restore_delegate
    @io.pos = @delegate_pos
    @io.lineno = @delegate_lineno
  end

  # Saves the state of the delegate IO object so that it can be restored later
  # using #restore_delegate and then configures the delegate so as to restore
  # the state of this object.
  def restore_self
    @delegate_pos = @io.pos
    @delegate_lineno = @io.lineno
    @io.pos = @window_position + @unbuffered_pos
  end
end
