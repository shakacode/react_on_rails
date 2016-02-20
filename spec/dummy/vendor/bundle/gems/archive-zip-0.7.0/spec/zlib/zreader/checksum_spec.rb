# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'

describe "Zlib::ZReader#checksum" do
  it "computes the ADLER32 checksum of zlib formatted data" do
    closed_zr = ZlibSpecs.compressed_data do |f|
      Zlib::ZReader.open(f, 15) do |zr|
        zr.read
        zr.checksum.must_equal Zlib.adler32(ZlibSpecs.test_data)
        zr
      end
    end
    closed_zr.checksum.must_equal Zlib.adler32(ZlibSpecs.test_data)
  end

  it "computes the CRC32 checksum of gzip formatted data" do
    closed_zr = ZlibSpecs.compressed_data_gzip do |f|
      Zlib::ZReader.open(f, 31) do |zr|
        zr.read
        zr.checksum.must_equal Zlib.crc32(ZlibSpecs.test_data)
        zr
      end
    end
    closed_zr.checksum.must_equal Zlib.crc32(ZlibSpecs.test_data)
  end

  it "does not compute a checksum for raw zlib data" do
    closed_zr = ZlibSpecs.compressed_data_raw do |f|
      Zlib::ZReader.open(f, -15) do |zr|
        zr.read
        zr.checksum.must_equal nil
        zr
      end
    end
    closed_zr.checksum.must_equal nil
  end
end
