# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'

describe "Zlib::ZReader#tell" do
  it "returns the current position of the stream" do
    ZlibSpecs.compressed_data do |cd|
      Zlib::ZReader.open(cd) do |zr|
        zr.tell.must_equal 0
        zr.read(4)
        zr.tell.must_equal 4
        zr.read
        zr.tell.must_equal 235
        zr.rewind
        zr.tell.must_equal 0
      end
    end
  end
end
