# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/store'

describe "Archive::Zip::Codec::Store::Decompress#read" do
  it "calls the read method of the delegate" do
    delegate = MiniTest::Mock.new
    delegate.expect(:read, nil, [Integer])
    delegate.expect(:close, nil)
    Archive::Zip::Codec::Store::Decompress.open(delegate) do |d|
      d.read
    end
  end

  it "passes data through unmodified" do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Decompress.open(cd) do |d|
        d.read.must_equal(StoreSpecs.test_data)
      end
    end
  end
end
