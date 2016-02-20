module Tins
  module PartialApplication
    # If this module is included into a Proc (or similar object), it tampers
    # with its Proc#arity method.
    def self.included(modul)
      modul.module_eval do
        old_arity = instance_method(:arity)
        define_method(:arity) do
          @__arity__ or old_arity.bind(self).call
        end
      end
      super
    end

    # Create a partial application of this Proc (or similar object) using
    # _args_ as the already applied arguments.
    def partial(*args)
      if args.empty?
        dup
      elsif args.size > arity
        raise ArgumentError, "wrong number of arguments (#{args.size} for #{arity})"
      else
        f = lambda { |*b| call(*(args + b)) }
        f.instance_variable_set :@__arity__, arity - args.size
        f
      end
    end
  end
end

require 'tins/alias'
