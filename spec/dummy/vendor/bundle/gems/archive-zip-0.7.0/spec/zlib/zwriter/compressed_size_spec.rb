# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter#compressed_size" do
  it "returns the number of bytes of compressed data" do
    compressed_data = BinaryStringIO.new
    closed_zw = Zlib::ZWriter.open(compressed_data, nil, -15) do |zw|
      zw.sync = true
      zw.write(ZlibSpecs.test_data)
      zw.compressed_size.must_be :>=, 0
      zw
    end
    closed_zw.compressed_size.must_equal 160
  end
end
