# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/deflate'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Deflate::Decompress.new" do
  it "returns a new instance" do
    d = Archive::Zip::Codec::Deflate::Decompress.new(BinaryStringIO.new)
    d.must_be_instance_of(Archive::Zip::Codec::Deflate::Decompress)
    d.close
  end
end
