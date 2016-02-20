# encoding: UTF-8

# IOExtensions provides convenience wrappers for certain IO functionality.
module IOExtensions
  # Reads and returns exactly _length_ bytes from _io_ using the read method on
  # _io_.  If there is insufficient data available, an EOFError is raised.
  def self.read_exactly(io, length, buffer = '')
    buffer.slice!(0..-1) unless buffer.empty?
    while buffer.size < length do
      internal = io.read(length - buffer.size)
      raise EOFError, 'unexpected end of file' if internal.nil?
      buffer << internal
    end
    buffer
  end
end
