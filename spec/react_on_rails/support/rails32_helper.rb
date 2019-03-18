# frozen_string_literal: true

def using_rails32?
  File.basename(ENV["BUNDLE_GEMFILE"] || "") == "Gemfile.rails32"
end
