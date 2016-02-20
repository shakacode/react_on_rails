# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter#tell" do
  it "returns the current position of the stream" do
    sio = BinaryStringIO.new
    Zlib::ZWriter.open(sio) do |zw|
      zw.tell.must_equal 0
      zw.write('test1')
      zw.tell.must_equal 5
      zw.write('test2')
      zw.tell.must_equal 10
      zw.rewind
      zw.tell.must_equal 0
    end
  end

  it "raises IOError on closed stream" do
    delegate = MiniTest::Mock.new
    delegate.expect(:write, 8, [String])
    lambda do
      Zlib::ZWriter.open(delegate) { |zw| zw }.tell
    end.must_raise IOError
  end
end
