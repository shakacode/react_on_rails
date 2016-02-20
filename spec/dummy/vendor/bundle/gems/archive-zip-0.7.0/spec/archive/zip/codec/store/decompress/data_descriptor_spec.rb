# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/zip/codec/store'

describe "Archive::Zip::Codec::Store::Decompress#data_descriptor" do
  it "is an instance of Archive::Zip::DataDescriptor" do
    StoreSpecs.compressed_data do |cd|
      closed_decompressor = Archive::Zip::Codec::Store::Decompress.open(
        cd
      ) do |decompressor|
        decompressor.read
        decompressor.data_descriptor.must_be_instance_of(
          Archive::Zip::DataDescriptor
        )
        decompressor
      end
      closed_decompressor.data_descriptor.must_be_instance_of(
        Archive::Zip::DataDescriptor
      )
    end
  end

  it "has a crc32 attribute containing the CRC32 checksum" do
    crc32 = Zlib.crc32(StoreSpecs.test_data)
    StoreSpecs.compressed_data do |cd|
      closed_decompressor = Archive::Zip::Codec::Store::Decompress.open(
        cd
      ) do |decompressor|
        decompressor.read
        decompressor.data_descriptor.crc32.must_equal(crc32)
        decompressor
      end
      closed_decompressor.data_descriptor.crc32.must_equal(crc32)
    end
  end

  it "has a compressed_size attribute containing the size of the compressed data" do
    compressed_size = StoreSpecs.compressed_data.size
    StoreSpecs.compressed_data do |cd|
      closed_decompressor = Archive::Zip::Codec::Store::Decompress.open(
        cd
      ) do |decompressor|
        decompressor.read
        decompressor.data_descriptor.compressed_size.must_equal(compressed_size)
        decompressor
      end
      closed_decompressor.data_descriptor.compressed_size.must_equal(
        compressed_size
      )
    end
  end

  it "has an uncompressed_size attribute containing the size of the input data" do
    uncompressed_size = StoreSpecs.test_data.size
    StoreSpecs.compressed_data do |cd|
      closed_decompressor = Archive::Zip::Codec::Store::Decompress.open(
        cd
      ) do |decompressor|
        decompressor.read
        decompressor.data_descriptor.uncompressed_size.must_equal(
          uncompressed_size
        )
        decompressor
      end
      closed_decompressor.data_descriptor.uncompressed_size.must_equal(
        uncompressed_size
      )
    end
  end
end
