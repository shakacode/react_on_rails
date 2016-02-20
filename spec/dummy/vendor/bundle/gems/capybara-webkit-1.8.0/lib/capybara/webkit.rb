require "capybara"

module Capybara
  module Webkit
    def self.configure(&block)
      Capybara::Webkit::Configuration.modify(&block)
    end
  end
end

require "capybara/webkit/driver"
require "capybara/webkit/configuration"

Capybara.register_driver :webkit do |app|
  Capybara::Webkit::Driver.new(app, Capybara::Webkit::Configuration.to_hash)
end

Capybara.register_driver :webkit_debug do |app|
  Capybara::Webkit::Driver.new(
    app,
    Capybara::Webkit::Configuration.to_hash.merge(debug: true)
  )
end
