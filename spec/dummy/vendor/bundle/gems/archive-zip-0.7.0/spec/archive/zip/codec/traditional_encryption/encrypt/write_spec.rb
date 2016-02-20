# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt#write" do
  it "writes encrypted data to the delegate" do
    # Ensure repeatable test data is used for encryption header.
    srand(0)
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.write(TraditionalEncryptionSpecs.test_data)
    end
    encrypted_data.string.must_equal(TraditionalEncryptionSpecs.encrypted_data)
  end

  it "writes encrypted data to a delegate that only performs partial writes" do
    # Ensure repeatable test data is used for encryption header.
    srand(0)
    encrypted_data = BinaryStringIO.new
    # Override encrypted_data.write to perform writes 1 byte at a time.
    class << encrypted_data
      alias :write_orig :write
      def write(buffer)
        write_orig(buffer.slice(0, 1))
      end
    end

    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.write(TraditionalEncryptionSpecs.test_data)
    end
    encrypted_data.string.must_equal(TraditionalEncryptionSpecs.encrypted_data)
  end

  it "writes encrypted data to a delegate that raises Errno::EAGAIN" do
    # Ensure repeatable test data is used for encryption header.
    srand(0)
    encrypted_data = BinaryStringIO.new
    # Override encrypted_data.write to raise Errno::EAGAIN every other time it's
    # called.
    class << encrypted_data
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

    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      begin
        e.write(TraditionalEncryptionSpecs.test_data)
      rescue Errno::EAGAIN
        retry
      end
    end
    encrypted_data.string.must_equal(TraditionalEncryptionSpecs.encrypted_data)
  end

  it "writes encrypted data to a delegate that raises Errno::EINTR" do
    # Ensure repeatable test data is used for encryption header.
    srand(0)
    encrypted_data = BinaryStringIO.new
    # Override encrypted_data.write to raise Errno::EINTR every other time it's
    # called.
    class << encrypted_data
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

    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      begin
        e.write(TraditionalEncryptionSpecs.test_data)
      rescue Errno::EINTR
        retry
      end
    end
    encrypted_data.string.must_equal(TraditionalEncryptionSpecs.encrypted_data)
  end
end
