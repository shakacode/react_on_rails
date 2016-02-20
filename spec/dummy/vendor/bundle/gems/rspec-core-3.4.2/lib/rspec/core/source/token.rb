RSpec::Support.require_rspec_core "source/location"

module RSpec
  module Core
    class Source
      # @private
      # A wrapper for Ripper token which is generated with `Ripper.lex`.
      class Token
        attr_reader :token

        def self.tokens_from_ripper_tokens(ripper_tokens)
          ripper_tokens.map { |ripper_token| new(ripper_token) }.freeze
        end

        def initialize(ripper_token)
          @token = ripper_token.freeze
        end

        def location
          @location ||= Location.new(*token[0])
        end

        def type
          token[1]
        end

        def string
          token[2]
        end

        def ==(other)
          token == other.token
        end

        alias_method :eql?, :==

        def inspect
          "#<#{self.class} #{type} #{string.inspect}>"
        end
      end
    end
  end
end
