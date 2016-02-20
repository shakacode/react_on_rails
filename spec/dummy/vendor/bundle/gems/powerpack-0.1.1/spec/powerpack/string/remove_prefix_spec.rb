require 'spec_helper'

describe 'String#remove_prefix' do
  it 'removes a prefix in a string' do
    expect('Ladies Night'.remove_prefix('Ladies ')).to eq('Night')
  end
end

describe 'String#remove_prefix!' do
  it 'removes a prefix in a string' do
    expect('Ladies Night'.remove_prefix!('Ladies ')).to eq('Night')
  end
end
