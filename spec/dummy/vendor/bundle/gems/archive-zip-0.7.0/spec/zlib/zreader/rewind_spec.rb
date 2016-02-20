# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'

describe "Zlib::ZReader#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    ZlibSpecs.compressed_data do |cd|
      Zlib::ZReader.open(cd) do |zr|
        zr.read(4)
        zr.rewind
        zr.read.must_equal ZlibSpecs.test_data
      end
    end
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    Zlib::ZReader.open(Object.new) do |zr|
      lambda { zr.rewind }.must_raise Errno::EINVAL
    end
  end
end
