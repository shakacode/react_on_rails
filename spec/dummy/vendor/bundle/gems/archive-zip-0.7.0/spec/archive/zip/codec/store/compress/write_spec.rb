# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Compress#write" do
  it "calls the write method of the delegate" do
    delegate = MiniTest::Mock.new
    delegate.expect(
      :write, StoreSpecs.compressed_data.size, [StoreSpecs.compressed_data]
    )
    delegate.expect(:close, nil)
    Archive::Zip::Codec::Store::Compress.open(delegate) do |c|
      c.write(StoreSpecs.test_data)
    end
  end

  it "passes data through unmodified" do
    compressed_data = BinaryStringIO.new
    Archive::Zip::Codec::Store::Compress.open(compressed_data) do |c|
      c.write(StoreSpecs.test_data)
    end
    compressed_data.string.must_equal(StoreSpecs.compressed_data)
  end
end
