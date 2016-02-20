# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter#write" do
  it "calls the write method of the delegate" do
    delegate = MiniTest::Mock.new
    delegate.expect(
      :write, ZlibSpecs.compressed_data.size, [ZlibSpecs.compressed_data]
    )
    Zlib::ZWriter.open(delegate) do |zw|
      zw.write(ZlibSpecs.test_data)
    end
  end

  it "compresses data" do
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(compressed_data) do |zw|
      zw.write(ZlibSpecs.test_data)
    end
    compressed_data.string.must_equal ZlibSpecs.compressed_data
  end
end
