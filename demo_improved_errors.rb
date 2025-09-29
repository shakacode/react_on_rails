#!/usr/bin/env ruby
# frozen_string_literal: true

# Demonstration of improved error messages in React on Rails

require_relative "lib/react_on_rails"
require_relative "lib/react_on_rails/smart_error"

puts "\n" + "=" * 80
puts "React on Rails: Improved Error Messages Demonstration"
puts "=" * 80 + "\n\n"

# Example 1: Component Not Registered Error
puts "Example 1: Component Not Registered"
puts "-" * 40 + "\n"

begin
  raise ReactOnRails::SmartError.new(
    error_type: :component_not_registered,
    component_name: "ProductCard",
    available_components: %w[ProductList ProductDetails UserProfile HelloWorld]
  )
rescue ReactOnRails::SmartError => e
  puts e.message
end

puts "\n" + "=" * 80 + "\n"

# Example 2: Missing Auto-loaded Bundle
puts "Example 2: Missing Auto-loaded Bundle"
puts "-" * 40 + "\n"

begin
  raise ReactOnRails::SmartError.new(
    error_type: :missing_auto_loaded_bundle,
    component_name: "Dashboard",
    expected_path: "/app/javascript/generated/Dashboard.js"
  )
rescue ReactOnRails::SmartError => e
  puts e.message
end

puts "\n" + "=" * 80 + "\n"

# Example 3: Server Rendering Error
puts "Example 3: Server Rendering Error (Browser API)"
puts "-" * 40 + "\n"

begin
  raise ReactOnRails::SmartError.new(
    error_type: :server_rendering_error,
    component_name: "UserProfile",
    error_message: "ReferenceError: window is not defined"
  )
rescue ReactOnRails::SmartError => e
  puts e.message
end

puts "\n" + "=" * 80 + "\n"

# Example 4: Hydration Mismatch
puts "Example 4: Hydration Mismatch"
puts "-" * 40 + "\n"

begin
  raise ReactOnRails::SmartError.new(
    error_type: :hydration_mismatch,
    component_name: "DynamicContent"
  )
rescue ReactOnRails::SmartError => e
  puts e.message
end

puts "\n" + "=" * 80 + "\n"

# Example 5: Redux Store Not Found
puts "Example 5: Redux Store Not Found"
puts "-" * 40 + "\n"

begin
  raise ReactOnRails::SmartError.new(
    error_type: :redux_store_not_found,
    store_name: "AppStore",
    available_stores: %w[UserStore ProductStore CartStore]
  )
rescue ReactOnRails::SmartError => e
  puts e.message
end

puts "\n" + "=" * 80
puts "End of Demonstration"
puts "=" * 80