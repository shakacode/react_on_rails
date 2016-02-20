# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/deflate'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Deflate::Compress#write" do
  it "calls the write method of the delegate" do
    delegate = MiniTest::Mock.new
    delegate.expect(
      :write, DeflateSpecs.compressed_data.size, [DeflateSpecs.compressed_data]
    )
    delegate.expect(:close, nil)
    Archive::Zip::Codec::Deflate::Compress.open(
      delegate, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      compressor.write(DeflateSpecs.test_data)
    end
  end

  it "writes compressed data to the delegate" do
    compressed_data = BinaryStringIO.new
    Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      compressor.write(DeflateSpecs.test_data)
    end
    compressed_data.string.must_equal(DeflateSpecs.compressed_data)
  end

  it "writes compressed data to a delegate that only performs partial writes" do
    compressed_data = BinaryStringIO.new
    # Override compressed_data.write to perform writes 1 byte at a time.
    class << compressed_data
      alias :write_orig :write
      def write(buffer)
        write_orig(buffer.slice(0, 1))
      end
    end

    Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      compressor.write(DeflateSpecs.test_data)
    end
    compressed_data.string.must_equal(DeflateSpecs.compressed_data)
  end

  it "writes compressed data to a delegate that raises Errno::EAGAIN" do
    compressed_data = BinaryStringIO.new
    # Override compressed_data.write to raise Errno::EAGAIN every other time
    # it's called.
    class << compressed_data
      alias :write_orig :write
      def write(buffer)
        if @error_raised then
          @error_raised = false
          write_orig(buffer)
        else
          @error_raised = true
          raise Errno::EAGAIN
        end
      end
    end

    Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      begin
        compressor.write(DeflateSpecs.test_data)
      rescue Errno::EAGAIN
        retry
      end
    end
    compressed_data.string.must_equal(DeflateSpecs.compressed_data)
  end

  it "writes compressed data to a delegate that raises Errno::EINTR" do
    compressed_data = BinaryStringIO.new
    # Override compressed_data.write to raise Errno::EINTR every other time it's
    # called.
    class << compressed_data
      alias :write_orig :write
      def write(buffer)
        if @error_raised then
          @error_raised = false
          write_orig(buffer)
        else
          @error_raised = true
          raise Errno::EINTR
        end
      end
    end

    Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      begin
        compressor.write(DeflateSpecs.test_data)
      rescue Errno::EINTR
        retry
      end
    end
    compressed_data.string.must_equal(DeflateSpecs.compressed_data)
  end
end
