# Copyright (c) 2010-2013 Michael Dvorkin
#
# Awesome Print is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AwesomePrint
  module NoBrainer

    def self.included(base)
      base.send :alias_method, :cast_without_no_brainer, :cast
      base.send :alias_method, :cast, :cast_with_no_brainer
    end

    # Add NoBrainer class names to the dispatcher pipeline.
    #------------------------------------------------------------------------------
    def cast_with_no_brainer(object, type)
      cast = cast_without_no_brainer(object, type)
      if defined?(::NoBrainer::Document)
        if object.is_a?(Class) && object.ancestors.include?(::NoBrainer::Document)
          cast = :no_brainer_class
        elsif object.class.ancestors.include?(::NoBrainer::Document)
          cast = :no_brainer_document
        end
      end
      cast
    end

    # Format NoBrainer class object.
    #------------------------------------------------------------------------------
    def awesome_no_brainer_class(object)
      return object.inspect if !defined?(::ActiveSupport::OrderedHash) || !object.respond_to?(:fields)

      # We want id first
      data = object.fields.sort_by { |key| key[0] == :id ? '_id' : key[0].to_s }.inject(::ActiveSupport::OrderedHash.new) do |hash, c|
        hash[c[0]] = :object
        hash
      end
      "class #{object} < #{object.superclass} " << awesome_hash(data)
    end

    # Format NoBrainer Document object.
    #------------------------------------------------------------------------------
    def awesome_no_brainer_document(object)
      return object.inspect if !defined?(::ActiveSupport::OrderedHash)

      data = object.attributes.sort_by { |key| key }.inject(::ActiveSupport::OrderedHash.new) do |hash, c|
        hash[c[0].to_sym] = c[1]
        hash
      end
      if !object.errors.empty?
        data = {:errors => object.errors, :attributes => data}
      end
      "#{object} #{awesome_hash(data)}"
    end
  end
end

AwesomePrint::Formatter.send(:include, AwesomePrint::NoBrainer)
