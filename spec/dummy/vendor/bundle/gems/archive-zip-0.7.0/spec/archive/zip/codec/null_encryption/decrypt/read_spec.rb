# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/null_encryption'

describe "Archive::Zip::Codec::NullEncryption::Decrypt#read" do
  it "calls the read method of the delegate" do
    delegate = MiniTest::Mock.new
    delegate.expect(:read, nil, [Integer])
    delegate.expect(:close, nil)
    Archive::Zip::Codec::NullEncryption::Decrypt.open(delegate) do |d|
      d.read
    end
  end

  it "passes data through unmodified" do
    NullEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::NullEncryption::Decrypt.open(ed) do |d|
        d.read.must_equal(NullEncryptionSpecs.test_data)
      end
    end
  end
end
