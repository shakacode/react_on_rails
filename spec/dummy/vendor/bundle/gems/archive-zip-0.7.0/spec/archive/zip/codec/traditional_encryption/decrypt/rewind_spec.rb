# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        d.read(4)
        d.rewind
        d.read.must_equal(TraditionalEncryptionSpecs.test_data)
      end
    end
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = MiniTest::Mock.new
    delegate.expect(:read, "\000" * 12, [Integer])
    delegate.expect(:close, nil)
    Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |d|
      lambda { d.rewind }.must_raise(Errno::EINVAL)
    end
  end
end
