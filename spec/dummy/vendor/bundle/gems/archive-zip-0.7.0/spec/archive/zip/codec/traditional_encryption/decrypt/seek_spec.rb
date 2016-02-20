# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt#seek" do
  it "can seek to the beginning of the stream when the delegate responds to rewind" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        d.read(4)
        d.seek(0).must_equal(0)
      end
    end
  end

  it "raises Errno::EINVAL when attempting to seek to the beginning of the stream when the delegate does not respond to rewind" do
    delegate = MiniTest::Mock.new
    delegate.expect(:read, "\000" * 12, [Integer])
    delegate.expect(:close, nil)
    Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |d|
      lambda { d.seek(0) }.must_raise(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking forward or backward from the current position of the stream" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        # Disable read buffering to avoid some seeking optimizations implemented
        # by IO::Like which allow seeking forward within the buffer.
        d.fill_size = 0

        d.read(4)
        lambda { d.seek(1, IO::SEEK_CUR) }.must_raise(Errno::EINVAL)
        lambda { d.seek(-1, IO::SEEK_CUR) }.must_raise(Errno::EINVAL)
      end
    end
  end

  it "raises Errno::EINVAL when seeking a non-zero offset relative to the beginning of the stream" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        lambda { d.seek(-1, IO::SEEK_SET) }.must_raise(Errno::EINVAL)
        lambda { d.seek(1, IO::SEEK_SET) }.must_raise(Errno::EINVAL)
      end
    end
  end

  it "raises Errno::EINVAL when seeking relative to the end of the stream" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        lambda { d.seek(0, IO::SEEK_END) }.must_raise(Errno::EINVAL)
        lambda { d.seek(-1, IO::SEEK_END) }.must_raise(Errno::EINVAL)
        lambda { d.seek(1, IO::SEEK_END) }.must_raise(Errno::EINVAL)
      end
    end
  end
end
