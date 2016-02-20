module Tins
  module FileBinary
    module Constants
      SEEK_SET = ::File::SEEK_SET

      ZERO   = "\x00"
      BINARY = "\x01-\x1f\x7f-\xff"

      if defined?(::Encoding)
        ZERO.force_encoding(Encoding::ASCII_8BIT)
        BINARY.force_encoding(Encoding::ASCII_8BIT)
      end
    end

    class << self
      # Default options can be queried/set via this hash.
      attr_accessor :default_options
    end
    self.default_options = {
      :offset            => 0,
      :buffer_size       => 2 ** 13,
      :percentage_binary => 30.0,
      :percentage_zeros  => 0.0,
    }

    # Returns true if this file is considered to be binary, false if it is not
    # considered to be binary, and nil if it was empty.
    #
    # A file is considered to be binary if the percentage of zeros exceeds
    # <tt>options[:percentage_zeros]</tt> or the percentage of binary bytes
    # (8-th bit is 1) exceeds <tt>options[:percentage_binary]</tt> in the
    # buffer of size <tt>options[:buffer_size]</tt> that is checked (beginning
    # from offset <tt>options[:offset]</tt>). If an option isn't given the one
    # from FileBinary.default_options is used instead.
    def binary?(options = {})
      options = FileBinary.default_options.merge(options)
      old_pos = tell
      seek options[:offset], Constants::SEEK_SET
      data = read options[:buffer_size]
      !data or data.empty? and return nil
      data_size = data.size
      data.count(Constants::ZERO).to_f / data_size >
        options[:percentage_zeros] / 100.0 and return true
      data.count(Constants::BINARY).to_f / data_size >
        options[:percentage_binary] / 100.0
    ensure
      old_pos and seek old_pos, Constants::SEEK_SET
    end

    # Returns true if FileBinary#binary? returns false, false if
    # FileBinary#binary? returns true, and nil otherwise. For an explanation of
    # +options+, see FileBinary#binary?.
    def ascii?(options = {})
      case binary?(options)
      when true   then false
      when false  then true
      end
    end

    def self.included(modul)
      modul.instance_eval do
        extend ClassMethods
      end
      super
    end

    module ClassMethods
      # Returns true if the file with name +name+ is considered to be binary
      # using the FileBinary#binary? method.
      def binary?(name, options = {})
        open(name, 'rb') { |f| f.binary?(options) }
      end

      # Returns true if the file with name +name+ is considered to be ascii
      # using the FileBinary#ascii? method.
      def ascii?(name, options = {})
        open(name, 'rb') { |f| f.ascii?(options) }
      end
    end
  end
end

require 'tins/alias'
