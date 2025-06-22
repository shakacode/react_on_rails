# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :with_delay, lambda { |ms|
    sleep(ms / 1000.0)
    all
  }
end
