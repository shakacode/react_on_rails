module Tins
  module Subhash
    # Create a subhash from this hash, that only contains key-value pairs
    # matching +patterns+ and return it. +patterns+ can be for example /^foo/
    # to put 'foobar' and 'foobaz' or 'foo'/:foo to put 'foo' into the subhash.
    #
    # If a block is given this method yields to it after the first pattern
    # matched with a 3-tuple of +(key, value, match_data)+ using the return
    # value of the block as the value of the result hash. +match_data+ is a
    # MatchData instance if the matching pattern was a regular rexpression
    # otherwise it is nil.
    def subhash(*patterns)
      patterns.map! do |pat|
        pat = pat.to_sym.to_s if pat.respond_to?(:to_sym)
        pat.respond_to?(:match) ? pat : pat.to_s
      end
      result =
        if default_proc
          self.class.new(&default_proc)
        else
          self.class.new(default)
        end
      if block_given?
        each do |k, v|
          patterns.each { |pat|
            if pat === k.to_s
              result[k] = yield(k, v, $~)
              break
            end
          }
        end
      else
        each do |k, v|
          result[k] = v if patterns.any? { |pat| pat === k.to_s }
        end
      end
      result
    end
  end
end

require 'tins/alias'
