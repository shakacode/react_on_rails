# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter#checksum" do
  it "computes the ADLER32 checksum of zlib formatted data" do
    compressed_data = BinaryStringIO.new
    closed_zw = Zlib::ZWriter.open(compressed_data, nil, 15) do |zw|
      zw.write(ZlibSpecs.test_data)
      zw.flush
      zw.checksum.must_equal Zlib.adler32(ZlibSpecs.test_data)
      zw
    end
    closed_zw.checksum.must_equal Zlib.adler32(ZlibSpecs.test_data)
  end

  it "computes the CRC32 checksum of gzip formatted data" do
    compressed_data = BinaryStringIO.new
    closed_zw = Zlib::ZWriter.open(compressed_data, nil, 31) do |zw|
      zw.write(ZlibSpecs.test_data)
      zw.flush
      zw.checksum.must_equal Zlib.crc32(ZlibSpecs.test_data)
      zw
    end
    closed_zw.checksum.must_equal Zlib.crc32(ZlibSpecs.test_data)
  end

  it "does not compute a checksum for raw zlib data" do
    compressed_data = BinaryStringIO.new
    closed_zw = Zlib::ZWriter.open(compressed_data, nil, -15) do |zw|
      zw.write(ZlibSpecs.test_data)
      zw.flush
      zw.checksum.must_equal nil
      zw
    end
    closed_zw.checksum.must_equal nil
  end
end
