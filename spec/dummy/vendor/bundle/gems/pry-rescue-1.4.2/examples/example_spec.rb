#!/usr/bin/env ruby
require 'rspec'
require 'rspec/autorun'

$:.unshift File.expand_path '../../lib', __FILE__
require 'pry-rescue/rspec'

describe "Float" do
  it "should be able to add" do
    (0.1 + 0.2).should == 0.3
  end
end
