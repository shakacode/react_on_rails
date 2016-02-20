require 'test_helper'
require 'tins'

module Tins
  class HashSymbolizeKeysRecursiveTest < Test::Unit::TestCase
    require 'tins/xt/hash_symbolize_keys_recursive'

    def test_symbolize
      hash = {
        'key' => [
          {
            'key' => {
              'key' => true
            }
          }
        ],
      }
      hash2 = hash.symbolize_keys_recursive
      assert hash2[:key][0][:key][:key]
      hash.symbolize_keys_recursive!
      assert hash[:key][0][:key][:key]
    end
  end
end
