# encoding: UTF-8

require 'archive/zip/error'

module Archive; class Zip; module ExtraField
  # Archive::Zip::Entry::ExtraField::ExtendedTimestamp represents an extra field
  # which optionally contains the last modified time, last accessed time, and
  # file creation time for a ZIP archive entry and stored in a Unix time format
  # (seconds since the epoc).
  class ExtendedTimestamp
    # The identifier reserved for this extra field type.
    ID = 0x5455

    # Register this extra field for use.
    EXTRA_FIELDS[ID] = self

    class << self
      # This method signature is part of the interface contract expected by
      # Archive::Zip::Entry for extra field objects.
      #
      # Parses _data_ which is expected to be a String formatted according to
      # the documentation provided with InfoZip's sources.
      #
      # Raises Archive::Zip::ExtraFieldError if _data_ contains invalid data.
      def parse_central(data)
        unless data.size == 5 || data.size == 9 || data.size == 13 then
          raise Zip::ExtraFieldError,
            "invalid size for extended timestamp: #{data.size}"
        end
        flags, *times = data.unpack('CV*')
        mtime = nil
        atime = nil
        crtime = nil
        if flags & 0b001 != 0 then
          if times.size == 0 then
            # Report an error if the flags indicate that the last modified time
            # field should be present when it is not.
            raise Zip::ExtraFieldError,
              'corrupt extended timestamp: last modified time field not present'
          end
          mtime = Time.at(times.shift)
        end
        if flags & 0b010 != 0 then
          # If parsing the central file record version of this field, this flag
          # may be set without having the corresponding time value.
          # Use the time value if available, but ignore it if it's missing.
          if times.size > 0 then
            atime = Time.at(times.shift)
          end
        end
        if flags & 0b100 != 0 then
          # If parsing the central file record version of this field, this flag
          # may be set without having the corresponding time value.
          # Use the time value if available, but ignore it if it's missing.
          if times.size > 0 then
            crtime = Time.at(times.shift)
          end
        end
        new(mtime, atime, crtime)
      end

      # This method signature is part of the interface contract expected by
      # Archive::Zip::Entry for extra field objects.
      #
      # Parses _data_ which is expected to be a String formatted according to
      # the documentation provided with InfoZip's sources.
      #
      # Raises Archive::Zip::ExtraFieldError if _data_ contains invalid data.
      def parse_local(data)
        unless data.size == 5 || data.size == 9 || data.size == 13 then
          raise Zip::ExtraFieldError,
            "invalid size for extended timestamp: #{data.size}"
        end
        flags, *times = data.unpack('CV*')
        mtime = nil
        atime = nil
        crtime = nil
        if flags & 0b001 != 0 then
          if times.size == 0 then
            # Report an error if the flags indicate that the last modified time
            # field should be present when it is not.
            raise Zip::ExtraFieldError,
              'corrupt extended timestamp: last modified time field not present'
          end
          mtime = Time.at(times.shift)
        end
        if flags & 0b010 != 0 then
          if times.size == 0 then
            # Report an error if the flags indicate that the last modified time
            # field should be present when it is not.
            raise Zip::ExtraFieldError,
              'corrupt extended timestamp: last accessed time field not present'
          end
          atime = Time.at(times.shift)
        end
        if flags & 0b100 != 0 then
          if times.size == 0 then
            # Report an error if the flags indicate that the file creation time
            # field should be present when it is not.
            raise Zip::ExtraFieldError,
              'corrupt extended timestamp: file creation time field not present'
          end
          crtime = Time.at(times.shift)
        end
        new(mtime, atime, crtime)
      end
    end

    # Creates a new instance of this class.  _mtime_, _atime_, and _crtime_
    # should be Time instances or +nil+.  When set to +nil+ the field is
    # considered to be unset and will not be stored in the archive.
    def initialize(mtime, atime, crtime)
      @header_id = ID
      self.mtime = mtime unless mtime.nil?
      self.atime = atime unless atime.nil?
      self.crtime = crtime unless crtime.nil?
    end

    # Returns the header ID for this ExtraField.
    attr_reader :header_id
    # The last modified time for an entry.  Set to either a Time instance or
    # +nil+.
    attr_accessor :mtime
    # The last accessed time for an entry.  Set to either a Time instance or
    # +nil+.
    attr_accessor :atime
    # The creation time for an entry.  Set to either a Time instance or +nil+.
    attr_accessor :crtime

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

      @mtime = other.mtime unless other.mtime.nil?
      @atime = other.atime unless other.atime.nil?
      @crtime = other.crtime unless other.crtime.nil?

      self
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Returns a String suitable to writing to a central file record in a ZIP
    # archive file which contains the data for this object.
    def dump_central
      times = []
      times << mtime.to_i unless mtime.nil?
      ([ID, 4 * times.size + 1, flags] + times).pack('vvC' + 'V' * times.size)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Returns a String suitable to writing to a local file record in a ZIP
    # archive file which contains the data for this object.
    def dump_local
      times = []
      times << mtime.to_i unless mtime.nil?
      times << atime.to_i unless atime.nil?
      times << crtime.to_i unless crtime.nil?
      ([ID, 4 * times.size + 1, flags] + times).pack('vvC' + 'V' * times.size)
    end

    private

    def flags
      flags = 0
      flags |= 0b001 unless mtime.nil?
      flags |= 0b010 unless atime.nil?
      flags |= 0b100 unless crtime.nil?
      flags
    end
  end
end; end; end
