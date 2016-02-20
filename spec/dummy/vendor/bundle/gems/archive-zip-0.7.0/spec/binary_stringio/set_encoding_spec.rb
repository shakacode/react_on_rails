# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/binary_stringio'

describe "BinaryStringIO#set_encoding" do
  it "raises an exception when called" do
    unless Object.const_defined?(:Encoding)
      skip("Encoding methods are not supported on current Ruby (#{RUBY_DESCRIPTION})")
    end

    lambda do
      BinaryStringIO.new.set_encoding('utf-8')
    end.must_raise RuntimeError
  end
end
