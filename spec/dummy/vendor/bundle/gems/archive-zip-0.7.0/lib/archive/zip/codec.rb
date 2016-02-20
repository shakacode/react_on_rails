# encoding: UTF-8

module Archive; class Zip
  # Archive::Zip::Codec is a factory class for generating codec object instances
  # based on the compression method and general purpose flag fields of ZIP
  # entries.  When adding a new codec, add a mapping in the _CODECS_ constant
  # from the compression method field value reserved for the codec in the ZIP
  # specification to the class implementing the codec.  See the implementations
  # of Archive::Zip::Codec::Deflate and Archive::Zip::Codec::Store for details
  # on implementing custom codecs.
  module Codec
    # A Hash mapping compression methods to compression codec implementations.
    # New compression codecs must add a mapping here when defined in order to be
    # used.
    COMPRESSION_CODECS = {}

    # A Hash mapping encryption methods to encryption codec implementations.
    # New encryption codecs must add a mapping here when defined in order to be
    # used.
    ENCRYPTION_CODECS  = {}

    # Returns a new compression codec instance based on _compression_method_ and
    # _general_purpose_flags_.
    def self.create_compression_codec(compression_method, general_purpose_flags)
      # Load the standard compression codecs.
      require 'archive/zip/codec/deflate'
      require 'archive/zip/codec/store'

      codec = COMPRESSION_CODECS[compression_method].new(general_purpose_flags)
      raise Zip::Error, 'unsupported compression codec' if codec.nil?
      codec
    end

    # Returns a new encryption codec instance based on _general_purpose_flags_.
    #
    # <b>NOTE:</b> The signature of this method will have to change in order to
    # support the strong encryption codecs.  This is intended to be an internal
    # method anyway, so this fact should not cause major issues for users of
    # this library.
    def self.create_encryption_codec(general_purpose_flags)
      general_purpose_flags &= 0b0000000001000001
      if general_purpose_flags == 0b0000000000000000 then
        require 'archive/zip/codec/null_encryption'
        codec = NullEncryption.new
      elsif general_purpose_flags == 0b0000000000000001 then
        require 'archive/zip/codec/traditional_encryption'
        codec = TraditionalEncryption.new
      end
      raise Zip::Error, 'unsupported encryption codec' if codec.nil?
      codec
    end
  end
end; end
