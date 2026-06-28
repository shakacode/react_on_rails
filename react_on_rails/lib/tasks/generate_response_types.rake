# frozen_string_literal: true

require_relative "../react_on_rails"

namespace :react_on_rails do
  desc "Generate TypeScript declarations for registered Rails JSON response contracts. " \
       "Set REACT_ON_RAILS_RESPONSE_TYPES_OUT to override the default output path " \
       "(app/javascript/types/react_on_rails_response_types.d.ts)."
  task generate_response_types: :environment do
    output_path = ENV.fetch("REACT_ON_RAILS_RESPONSE_TYPES_OUT", nil)
    Rails.application.eager_load!
    generated_path = ReactOnRails::TypeScriptResponseTypes.generate(output_path:)

    puts "Generated React on Rails response types in #{generated_path}"
  end
end
