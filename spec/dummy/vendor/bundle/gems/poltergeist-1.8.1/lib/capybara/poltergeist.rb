if RUBY_VERSION < "1.9.2"
  raise "This version of Capybara/Poltergeist does not support Ruby versions " \
        "less than 1.9.2."
end

require 'capybara'

module Capybara
  module Poltergeist
    require 'capybara/poltergeist/utility'
    require 'capybara/poltergeist/driver'
    require 'capybara/poltergeist/browser'
    require 'capybara/poltergeist/node'
    require 'capybara/poltergeist/server'
    require 'capybara/poltergeist/web_socket_server'
    require 'capybara/poltergeist/client'
    require 'capybara/poltergeist/inspector'
    require 'capybara/poltergeist/json'
    require 'capybara/poltergeist/network_traffic'
    require 'capybara/poltergeist/errors'
    require 'capybara/poltergeist/cookie'
  end
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app)
end
