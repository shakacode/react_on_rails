# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter.open" do
  it "returns a new instance when run without a block" do
    zw = Zlib::ZWriter.open(BinaryStringIO.new)
    zw.class.must_equal Zlib::ZWriter
    zw.close
  end

  it "executes a block with a new instance as an argument" do
    Zlib::ZWriter.open(BinaryStringIO.new) { |zr| zr.class.must_equal Zlib::ZWriter }
  end

  it "closes the object after executing a block" do
    Zlib::ZWriter.open(BinaryStringIO.new) { |zr| zr }.closed?.must_equal true
  end

  it "provides default settings for level, window_bits, mem_level, and strategy" do
    data = ZlibSpecs.test_data
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(compressed_data) { |zw| zw.write(data) }

    compressed_data.string.must_equal ZlibSpecs.compressed_data
  end

  it "allows level to be set" do
    data = ZlibSpecs.test_data
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(compressed_data, Zlib::NO_COMPRESSION) do |zw|
      zw.write(data)
    end

    compressed_data.string.must_equal ZlibSpecs.compressed_data_nocomp
  end

  it "allows window_bits to be set" do
    data = ZlibSpecs.test_data
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(compressed_data, nil, 8) { |zw| zw.write(data) }

    compressed_data.string.must_equal ZlibSpecs.compressed_data_minwin
  end

  it "allows mem_level to be set" do
    data = ZlibSpecs.test_data
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(compressed_data, nil, nil, 1) { |zw| zw.write(data) }

    compressed_data.string.must_equal ZlibSpecs.compressed_data_minmem
  end

  it "allows strategy to be set" do
    data = ZlibSpecs.test_data
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(
      compressed_data, nil, nil, nil, Zlib::HUFFMAN_ONLY
    ) do |zw|
      zw.write(data)
    end

    compressed_data.string.must_equal ZlibSpecs.compressed_data_huffman
  end
end
