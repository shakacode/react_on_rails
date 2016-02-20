module Tins
  # Implementation of the null object pattern in Ruby.
  module Null
    def method_missing(*)
      self
    end

    def const_missing(*)
      self
    end

    def to_s
      ''
    end

    def to_str
      nil
    end

    def to_f
      0.0
    end

    def to_i
      0
    end

    def to_int
      nil
    end

    def to_a
      []
    end

    def to_ary
      nil
    end

    def inspect
      'NULL'
    end

    def nil?
      true
    end

    def blank?
      true
    end

    def as_json(*)
    end

    def to_json(*)
      'null'
    end

    module Kernel
      def null(value = nil)
        value.nil? ? Tins::NULL : value
      end

      alias Null null

      def null_plus(opts = {})
        value = opts[:value]
        opts[:caller] = caller
        if respond_to?(:caller_locations, true)
          opts[:caller_locations] = caller_locations
        end

        value.nil? ? Tins::NullPlus.new(opts) : value
      end

      alias NullPlus null_plus
    end
  end

  class NullClass < Module
    include Tins::Null
  end

  NULL = NullClass.new.freeze

  class NullPlus
    include Tins::Null

    def initialize(opts = {})
      singleton_class.class_eval do
        opts.each do |name, value|
          define_method(name) { value }
        end
      end
    end
  end
end

require 'tins/alias'
