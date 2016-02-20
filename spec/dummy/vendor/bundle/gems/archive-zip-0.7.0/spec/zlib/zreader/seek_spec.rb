# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'

describe "Zlib::ZReader#seek" do
  it "can seek to the beginning of the stream when the delegate responds to rewind" do
    ZlibSpecs.compressed_data do |cd|
      Zlib::ZReader.open(cd) do |zr|
        zr.read(4)
        zr.seek(0).must_equal 0
      end
    end
  end

  it "raises Errno::EINVAL when attempting to seek to the beginning of the stream when the delegate does not respond to rewind" do
    Zlib::ZReader.open(Object.new) do |zr|
      lambda { zr.seek(0) }.must_raise Errno::EINVAL
    end
  end

  it "raises Errno::EINVAL when seeking forward or backward from the current position of the stream" do
    ZlibSpecs.compressed_data do |cd|
      Zlib::ZReader.open(cd) do |zr|
        # Disable read buffering to avoid some seeking optimizations implemented
        # by IO::Like which allow seeking forward within the buffer.
        zr.fill_size = 0

        zr.read(4)
        lambda { zr.seek(1, IO::SEEK_CUR) }.must_raise Errno::EINVAL
        lambda { zr.seek(-1, IO::SEEK_CUR) }.must_raise Errno::EINVAL
      end
    end
  end

  it "raises Errno::EINVAL when seeking a non-zero offset relative to the beginning of the stream" do
    ZlibSpecs.compressed_data do |cd|
      Zlib::ZReader.open(cd) do |zr|
        lambda { zr.seek(-1, IO::SEEK_SET) }.must_raise Errno::EINVAL
        lambda { zr.seek(1, IO::SEEK_SET) }.must_raise Errno::EINVAL
      end
    end
  end

  it "raises Errno::EINVAL when seeking relative to the end of the stream" do
    ZlibSpecs.compressed_data do |cd|
      Zlib::ZReader.open(cd) do |zr|
        lambda { zr.seek(0, IO::SEEK_END) }.must_raise Errno::EINVAL
        lambda { zr.seek(-1, IO::SEEK_END) }.must_raise Errno::EINVAL
        lambda { zr.seek(1, IO::SEEK_END) }.must_raise Errno::EINVAL
      end
    end
  end
end
