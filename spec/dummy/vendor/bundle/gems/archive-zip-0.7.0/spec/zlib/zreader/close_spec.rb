# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZReader.close" do
  it "closes the stream" do
    zr = Zlib::ZReader.new(BinaryStringIO.new)
    zr.close
    zr.closed?.must_equal true
  end
end
