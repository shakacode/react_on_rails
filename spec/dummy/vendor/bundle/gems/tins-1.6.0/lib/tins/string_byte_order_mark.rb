require 'tins/concern'

module Tins
  module StringByteOrderMark
    def bom_encoding
      prefix = self[0, 4].force_encoding(Encoding::ASCII_8BIT)
      case prefix
      when /\A\xef\xbb\xbf/n                    then Encoding::UTF_8
      when /\A\x00\x00\xff\xfe/n                then Encoding::UTF_32BE
      when /\A\xff\xfe\x00\x00/n                then Encoding::UTF_32LE
      when /\A\xfe\xff/n                        then Encoding::UTF_16BE
      when /\A\xff\xfe/n                        then Encoding::UTF_16LE
      when /\A\x2b\x2f\x76[\x38-\x39\x2b\x2f]/n then Encoding::UTF_7
      when /\A\x84\x31\x95\x33/n                then Encoding::GB18030
      end
    end
  end
end

require 'tins/alias'
