# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/deflate'

describe "Archive::Zip::Deflate::Decompress#crc32" do
  it "computes a CRC32 checksum" do
    closed_decompressor = DeflateSpecs.compressed_data do |f|
      Archive::Zip::Codec::Deflate::Decompress.open(f) do |decompressor|
        decompressor.read
        decompressor.crc32.must_equal(Zlib.crc32(DeflateSpecs.test_data))
        decompressor
      end
    end
    closed_decompressor.crc32.must_equal(Zlib.crc32(DeflateSpecs.test_data))
  end
end
