# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt#tell" do
  it "returns the current position of the stream" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.tell.must_equal(0)
      e.write('test1')
      e.tell.must_equal(5)
      e.write('test2')
      e.tell.must_equal(10)
      e.rewind
      e.tell.must_equal(0)
    end
  end

  it "raises IOError on closed stream" do
    delegate = MiniTest::Mock.new
    delegate.expect(:write, 12, [String])
    delegate.expect(:close, nil)
    lambda do
      Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
        delegate,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) { |e| e }.tell
    end.must_raise(IOError)
  end
end
