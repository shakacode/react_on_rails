require 'spec_helper'

describe 'Enumerable#sum' do
  it 'sums up the numbers of an enum' do
    expect((1..3).sum).to eq(6)
  end

  it 'returns nil when invoked on an empty collection' do
    expect([].sum).to be_nil
  end

  it 'returns default value when invoked on an empty collection' do
    expect([].sum(0)).to be_zero
  end
end
