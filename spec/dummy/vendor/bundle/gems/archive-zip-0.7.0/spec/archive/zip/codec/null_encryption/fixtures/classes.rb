# encoding: UTF-8

class NullEncryptionSpecs
  class << self
    def test_data
      File.open(File.join(File.dirname(__FILE__), 'raw_file.txt'), 'rb') do |f|
        block_given? ? yield(f) : f.read
      end
    end
    alias :encrypted_data :test_data
  end
end
