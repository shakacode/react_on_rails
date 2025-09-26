# frozen_string_literal: true

def cache_data
  Rails.cache.instance_variable_get(:@data)
end
