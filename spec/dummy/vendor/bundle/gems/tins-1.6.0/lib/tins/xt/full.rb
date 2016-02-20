require 'tins/xt/blank'

module Tins
  module Full
    # Returns the object if it isn't blank (as in Object#blank?), otherwise it
    # returns nil. If a block was given as an argument and the object isn't
    # blank, the block is executed with the object as its first argument. If an
    # argument +dispatch+ was given and the object wasn't blank the method
    # given by dispatch is called on the object. This is the same as
    # foo.full?(&:bar) in the previous block form.
    def full?(dispatch = nil, *args)
      if blank?
        obj = nil
      #elsif Module === dispatch # TODO
      #  dispatch.found?(self)
      elsif dispatch
        obj = __send__(dispatch, *args)
        obj = nil if obj.blank?
      else
        obj = self
      end
      if block_given? and obj
        yield obj
      else
        obj
      end
    end

    def all_full?
      if respond_to?(:all?) && all?(&:full?)
        block_given? ? yield(self) : self
      end
    end
  end

  class ::Object
    include Full
  end
end
