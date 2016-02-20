#!/usr/bin/env ruby
require 'rspec'
require 'rspec/autorun'

$:.unshift File.expand_path '../../lib', __FILE__
require 'pry-rescue/rspec'

require 'capybara/rspec'

describe "Google", :type => :feature, :driver => :selenium do
  it "should make a nice bell-like sound" do
    visit 'http://google.com/'
    page.should have_content 'Bing'
  end
end
