# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/null_encryption'

describe "Archive::Zip::Codec::NullEncryption::Decrypt#tell" do
  it "returns the current position of the stream" do
    NullEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::NullEncryption::Decrypt.open(ed) do |d|
        d.tell.must_equal(0)
        d.read(4)
        d.tell.must_equal(4)
        d.read
        d.tell.must_equal(235)
        d.rewind
        d.tell.must_equal(0)
      end
    end
  end
end
