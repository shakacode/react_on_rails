# encoding: UTF-8

class Time
  # Returns a DOSTime representing this time object as a DOS date-time
  # structure.  Times are bracketed by the limits of the ability of the DOS
  # date-time structure to represent them.  Accuracy is 2 seconds and years
  # range from 1980 to 2099.  The returned structure represents as closely as
  # possible the time of this object.
  #
  # See DOSTime#new for a description of this structure.
  def to_dos_time
    dos_sec  = sec/2
    dos_year = year - 1980
    dos_year = 0   if dos_year < 0
    dos_year = 119 if dos_year > 119

    Archive::DOSTime.new(
      (dos_sec       ) |
      (min      <<  5) |
      (hour     << 11) |
      (day      << 16) |
      (month    << 21) |
      (dos_year << 25)
    )
  end
end

module Archive
  # A representation of the DOS time structure which can be converted into
  # instances of Time.
  class DOSTime
    include Comparable

    # Creates a new instance of DOSTime.  _dos_time_ is a 4 byte String or
    # unsigned number (Integer) representing an MS-DOS time structure where:
    # Bits 0-4::   2 second increments (0-29)
    # Bits 5-10::  minutes (0-59)
    # Bits 11-15:: hours (0-24)
    # Bits 16-20:: day (1-31)
    # Bits 21-24:: month (1-12)
    # Bits 25-31:: four digit year minus 1980 (0-119)
    #
    # If _dos_time_ is ommitted or +nil+, a new instance is created based on the
    # current time.
    def initialize(dos_time = nil)
      case dos_time
      when nil
        @dos_time = Time.now.to_dos_time.dos_time
      when Integer
        @dos_time = dos_time
      else
        unless dos_time.length == 4 then
          raise ArgumentError, 'length of DOS time structure is not 4'
        end
        @dos_time = dos_time.unpack('V')[0]
      end
    end

    # Returns -1 if _other_ is a time earlier than this one, 0 if _other_ is the
    # same time, and 1 if _other_ is a later time.
    def cmp(other)
      to_i <=> other.to_i
    end
    alias :<=> :cmp

    # Returns the time value of this object as an integer representing the DOS
    # time structure.
    def to_i
      @dos_time
    end

    # Returns the 32 bit integer that backs this object packed into a String in
    # little endian format.  This is suitable for use with #new.
    def pack
      [to_i].pack('V')
    end

    # Returns a Time instance which is equivalent to the time represented by
    # this object.
    def to_time
      second = ((0b11111         & @dos_time)      ) * 2
      minute = ((0b111111  << 5  & @dos_time) >>  5)
      hour   = ((0b11111   << 11 & @dos_time) >> 11)
      day    = ((0b11111   << 16 & @dos_time) >> 16)
      month  = ((0b1111    << 21 & @dos_time) >> 21)
      year   = ((0b1111111 << 25 & @dos_time) >> 25) + 1980
      return Time.local(year, month, day, hour, minute, second)
    end
  end
end
