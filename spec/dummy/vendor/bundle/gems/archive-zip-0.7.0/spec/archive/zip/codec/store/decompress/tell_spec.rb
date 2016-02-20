# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/store'

describe "Archive::Zip::Codec::Store::Decompress#tell" do
  it "returns the current position of the stream" do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Decompress.open(cd) do |d|
        d.tell.must_equal(0)
        d.read(4)
        d.tell.must_equal(4)
        d.read
        d.tell.must_equal(235)
        d.rewind
        d.tell.must_equal(0)
      end
    end
  end
end
