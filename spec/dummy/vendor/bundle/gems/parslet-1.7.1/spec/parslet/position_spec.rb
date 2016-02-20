# Encoding: UTF-8

require 'spec_helper'

describe Parslet::Position do
  slet(:position) { described_class.new('öäüö', 4) }

  it 'should have a charpos of 2' do
    position.charpos.should == 2
  end
  it 'should have a bytepos of 4' do
    position.bytepos.should == 4
  end
end