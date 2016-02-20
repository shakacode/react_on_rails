require 'securerandom'

module Tins
  class Token < String
    DEFAULT_ALPHABET =
      "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze

    BASE64_ALPHABET =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".freeze

    BASE64_URL_FILENAME_SAFE_ALPHABET =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".freeze

    BASE32_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".freeze

    BASE32_EXTENDED_HEX_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUV".freeze

    BASE16_ALPHABET = "0123456789ABCDEF".freeze

    def initialize(bits: 128, length: nil, alphabet: DEFAULT_ALPHABET, random: SecureRandom)
      alphabet.size > 1 or raise ArgumentError, 'need at least 2 symbols in alphabet'
      if length
        length > 0 or raise ArgumentError, 'length has to be positive'
      else
        bits > 0 or raise ArgumentError, 'bits has to be positive'
        length = (Math.log(1 << bits) / Math.log(alphabet.size)).ceil
      end
      self.bits = (Math.log(alphabet.size ** length) / Math.log(2)).floor
      token = ''
      length.times { token << alphabet[random.random_number(alphabet.size)] }
      super token
    end

    attr_accessor :bits
  end
end
