# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZReader.open" do
  it "returns a new instance when run without a block" do
    Zlib::ZReader.open(BinaryStringIO.new).class.must_equal Zlib::ZReader
  end

  it "executes a block with a new instance as an argument" do
    Zlib::ZReader.open(BinaryStringIO.new) { |zr| zr.class.must_equal Zlib::ZReader }
  end

  it "closes the object after executing a block" do
    Zlib::ZReader.open(BinaryStringIO.new) { |zr| zr }.closed?.must_equal true
  end

  it "does not require window_bits to be set" do
    data = ZlibSpecs.test_data
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(compressed_data) do |zw|
      zw.write(data)
    end
    compressed_data.rewind

    Zlib::ZReader.open(compressed_data) do |zr|
      zr.read.must_equal data
    end
  end

  it "allows window_bits to be set" do
    data = ZlibSpecs.test_data
    compressed_data = BinaryStringIO.new
    window_bits = -Zlib::MAX_WBITS
    Zlib::ZWriter.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION, window_bits
    ) do |zw|
      zw.write(data)
    end
    compressed_data.rewind

    Zlib::ZReader.open(compressed_data, window_bits) do |zr|
      zr.read.must_equal data
    end
  end
end
