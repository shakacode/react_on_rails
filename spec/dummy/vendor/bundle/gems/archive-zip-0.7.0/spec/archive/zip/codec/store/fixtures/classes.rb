# encoding: UTF-8

class StoreSpecs
  class << self
    def test_data
      File.open(File.join(File.dirname(__FILE__), 'raw_file.txt'), 'rb') do |f|
        block_given? ? yield(f) : f.read
      end
    end
    alias :compressed_data :test_data
  end
end
