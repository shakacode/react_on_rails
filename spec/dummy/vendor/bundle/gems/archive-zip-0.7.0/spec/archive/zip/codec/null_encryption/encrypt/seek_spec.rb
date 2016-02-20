# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt#seek" do
  it "can seek to the beginning of the stream when the delegate responds to rewind" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      e.write('test')
      e.seek(0).must_equal(0)
    end
  end

  it "raises Errno::EINVAL when attempting to seek to the beginning of the stream when the delegate does not respond to rewind" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    Archive::Zip::Codec::NullEncryption::Encrypt.open(delegate) do |e|
      lambda { e.seek(0) }.must_raise(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking forward or backward from the current position of the stream" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      e.write('test')
      lambda { e.seek(1, IO::SEEK_CUR) }.must_raise(Errno::EINVAL)
      lambda { e.seek(-1, IO::SEEK_CUR) }.must_raise(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking a non-zero offset relative to the beginning of the stream" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      lambda { e.seek(-1, IO::SEEK_SET) }.must_raise(Errno::EINVAL)
      lambda { e.seek(1, IO::SEEK_SET) }.must_raise(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking relative to the end of the stream" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      lambda { e.seek(0, IO::SEEK_END) }.must_raise(Errno::EINVAL)
      lambda { e.seek(-1, IO::SEEK_END) }.must_raise(Errno::EINVAL)
      lambda { e.seek(1, IO::SEEK_END) }.must_raise(Errno::EINVAL)
    end
  end
end
