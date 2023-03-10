# frozen_string_literal: true

module ApplicationHelper
  def self.include_code(path)
    File.read(Rails.root.join("client/app/#{path}"))
  end
end
