# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter.close" do
  it "closes the stream" do
    zw = Zlib::ZWriter.new(BinaryStringIO.new)
    zw.close
    zw.closed?.must_equal true
  end
end
