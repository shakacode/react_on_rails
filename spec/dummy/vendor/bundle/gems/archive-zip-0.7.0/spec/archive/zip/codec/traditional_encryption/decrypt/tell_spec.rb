# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt#tell" do
  it "returns the current position of the stream" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
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
