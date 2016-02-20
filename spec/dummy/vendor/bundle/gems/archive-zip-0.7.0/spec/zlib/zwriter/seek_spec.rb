# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter#seek" do
  it "can seek to the beginning of the stream when the delegate responds to rewind" do
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(compressed_data) do |c|
      c.write('test')
      c.seek(0).must_equal 0
    end
  end

  it "raises Errno::EINVAL when attempting to seek to the beginning of the stream when the delegate does not respond to rewind" do
    delegate = MiniTest::Mock.new
    delegate.expect(:write, 8, [String])
    Zlib::ZWriter.open(delegate) do |c|
      lambda { c.seek(0) }.must_raise Errno::EINVAL
    end
  end

  it "raises Errno::EINVAL when seeking forward or backward from the current position of the stream" do
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(compressed_data) do |c|
      c.write('test')
      lambda { c.seek(1, IO::SEEK_CUR) }.must_raise Errno::EINVAL
      lambda { c.seek(-1, IO::SEEK_CUR) }.must_raise Errno::EINVAL
    end
  end

  it "raises Errno::EINVAL when seeking a non-zero offset relative to the beginning of the stream" do
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(compressed_data) do |c|
      lambda { c.seek(-1, IO::SEEK_SET) }.must_raise Errno::EINVAL
      lambda { c.seek(1, IO::SEEK_SET) }.must_raise Errno::EINVAL
    end
  end

  it "raises Errno::EINVAL when seeking relative to the end of the stream" do
    compressed_data = BinaryStringIO.new
    Zlib::ZWriter.open(compressed_data) do |c|
      lambda { c.seek(0, IO::SEEK_END) }.must_raise Errno::EINVAL
      lambda { c.seek(-1, IO::SEEK_END) }.must_raise Errno::EINVAL
      lambda { c.seek(1, IO::SEEK_END) }.must_raise Errno::EINVAL
    end
  end
end
