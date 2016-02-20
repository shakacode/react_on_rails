module Tins
  module Blank
    module Object
      def blank?
        respond_to?(:empty?) ? empty? : !self
      end

      def present?
        !blank?
      end
    end

    module NilClass
      def blank?
        true
      end
    end

    module FalseClass
      def blank?
        true
      end
    end

    module TrueClass
      def blank?
        false
      end
    end

    module Array
      def self.included(modul)
        modul.module_eval do
          alias_method :blank?, :empty?
        end
      end
    end

    module Hash
      def self.included(modul)
        modul.module_eval do
          alias_method :blank?, :empty?
        end
      end
    end

    module String
      def blank?
        self !~ /\S/
      end
    end

    module Numeric
      def blank?
        false
      end
    end
  end
end

unless Object.respond_to?(:blank?)
  for k in Tins::Blank.constants
    Object.const_get(k).class_eval do
      include Tins::Blank.const_get(k)
    end
  end
end
