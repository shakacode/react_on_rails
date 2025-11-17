# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :caching) do
    cache_store = ActiveSupport::Cache::MemoryStore.new
    allow(controller).to receive(:cache_store).and_return(cache_store) if defined?(controller) && controller
    allow(Rails).to receive(:cache).and_return(cache_store)
    ReactOnRailsPro::Cache.instance_variable_set(:@serializer_checksum, nil)
    Rails.cache.clear
  end

  config.around(:each, :caching) do |example|
    caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    example.run
    ActionController::Base.perform_caching = caching
  end
end
