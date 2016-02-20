# encoding: UTF-8

module Archive; class Zip; module ExtraField
  # Archive::Zip::Entry::ExtraField::Raw represents an unknown extra field.  It
  # is used to store extra fields the Archive::Zip library does not directly
  # support.
  #
  # Do not use this class directly.  Define a new class which supports the extra
  # field of interest directly instead.
  class Raw
    class << self
      # Simply stores _header_id_ and _data_ for later reproduction by
      # #dump_central.
      # This is essentially and alias for #new.
      def parse_central(header_id, data)
        new(header_id, data, true)
      end

      # Simply stores _header_id_ and _data_ for later reproduction by
      # #dump_local.
      # This is essentially and alias for #new.
      def parse_local(header_id, data)
        new(header_id, data, false)
      end
    end

    # Simply stores _header_id_ and _data_ for later reproduction by
    # #dump_central or #dump_local.  _central_record_ indicates that this field
    # resides in the central file record for an entry when +true+.  When
    # +false+, it indicates that this field resides in the local file record for
    # an entry.
    def initialize(header_id, data, central_record)
      @header_id = header_id
      @central_record_data = []
      @local_record_data = []
      if central_record then
        @central_record_data << data
      else
        @local_record_data << data
      end
    end

    # Returns the header ID for this ExtraField.
    attr_reader :header_id
    # Returns the data contained within this ExtraField.
    attr_reader :central_record_data
    attr_reader :local_record_data

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Merges the attributes of _other_ into this object and returns +self+.
    #
    # Raises ArgumentError if _other_ does not have the same header ID as this
    # object.
    def merge(other)
      if header_id != other.header_id then
        raise ArgumentError,
          "Header ID mismatch: #{header_id} != #{other.header_id}"
      end

      @central_record_data += other.central_record_data
      @local_record_data += other.local_record_data

      self
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Returns a String suitable to writing to a central file record in a ZIP
    # archive file which contains the data for this object.
    def dump_central
      @central_record_data.collect do |data|
        [header_id, data.size].pack('vv') + data
      end
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Returns a String suitable to writing to a local file record in a ZIP
    # archive file which contains the data for this object.
    def dump_local
      @local_record_data.collect do |data|
        [header_id, data.size].pack('vv') + data
      end
    end
  end
end; end; end
