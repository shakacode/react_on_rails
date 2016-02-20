# encoding: UTF-8

require 'archive/zip/error'

module Archive; class Zip; module ExtraField
  # Archive::Zip::Entry::ExtraField::Unix represents an extra field which
  # contains the last modified time, last accessed time, user name, and group
  # name for a ZIP archive entry.  Times are in Unix time format (seconds since
  # the epoc).
  #
  # This class also optionally stores either major and minor numbers for devices
  # or a link target for either hard or soft links.  Which is in use when given
  # and instance of this class depends upon the external file attributes for the
  # ZIP archive entry associated with this extra field.
  class Unix
    # The identifier reserved for this extra field type.
    ID = 0x000d

    # Register this extra field for use.
    EXTRA_FIELDS[ID] = self

    class << self
      # This method signature is part of the interface contract expected by
      # Archive::Zip::Entry for extra field objects.
      #
      # Parses _data_ which is expected to be a String formatted according to
      # the official ZIP specification.
      #
      # Raises Archive::Zip::ExtraFieldError if _data_ contains invalid data.
      def parse_central(data)
        unless data.length >= 12 then
          raise Zip::ExtraFieldError, "invalid size for Unix data: #{data.size}"
        end
        atime, mtime, uid, gid, rest = data.unpack('VVvva')
        new(Time.at(mtime), Time.at(atime), uid, gid, rest)
      end
      alias :parse_local :parse_central
    end

    # Creates a new instance of this class.  _mtime_ and _atime_ should be Time
    # instances.  _uid_ and _gid_ should be user and group IDs as Integers
    # respectively.  _data_ should be a string containing either major and minor
    # device numbers consecutively packed as little endian, 4-byte, unsigned
    # integers (see the _V_ directive of Array#pack) or a path to use as a link
    # target.
    def initialize(mtime, atime, uid, gid, data = '')
      @header_id = ID
      @mtime = mtime
      @atime = atime
      @uid = uid
      @gid = gid
      @data = data
    end

    # Returns the header ID for this ExtraField.
    attr_reader :header_id
    # A Time object representing the last accessed time for an entry.
    attr_accessor :atime
    # A Time object representing the last modified time for an entry.
    attr_accessor :mtime
    # An integer representing the user ownership for an entry.
    attr_accessor :uid
    # An integer representing the group ownership for an entry.
    attr_accessor :gid

    # Attempts to return a two element array representing the major and minor
    # device numbers which may be stored in the variable data section of this
    # object.
    def device_numbers
      @data.unpack('VV')
    end

    # Takes a two element array containing major and minor device numbers and
    # stores the numbers into the variable data section of this object.
    def device_numbers=(major_minor)
      @data = major_minor.pack('VV')
    end

    # Attempts to return a string representing the path of a file which is
    # either a symlink or hard link target which may be stored in the variable
    # data section of this object.
    def link_target
      @data
    end

    # Takes a string containing the path to a file which is either a symlink or
    # a hardlink target and stores it in the variable data section of this
    # object.
    def link_target=(link_target)
      @data = link_target
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Merges the attributes of _other_ into this object and returns +self+.
    #
    # Raises ArgumentError if _other_ is not the same class as this object.
    def merge(other)
      if self.class != other.class then
        raise ArgumentError, "#{self.class} is not the same as #{other.class}"
      end

      @atime = other.atime
      @mtime = other.mtime
      @uid = other.uid
      @gid = other.gid
      @data = other.data

      self
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Returns a String suitable to writing to a central file record in a ZIP
    # archive file which contains the data for this object.
    def dump_central
      ''
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Returns a String suitable to writing to a local file record in a ZIP
    # archive file which contains the data for this object.
    def dump_local
      [
        ID,
        12 + @data.size,
        @atime.to_i,
        @mtime.to_i,
        @uid,
        @gid
      ].pack('vvVVvv') + @data
    end
    alias :dump_local :dump_central

    protected

    attr_reader :data
  end
end; end; end
