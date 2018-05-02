module CachingHelpers
  # INFO: helper for accessing key/value pairs included in the cache
  #
  #    cache_data #=> {"jbuilder/views/users/1-2018...": <user_partial content>}
  def cache_data
    Rails.cache.instance_variable_get(:@data)
  end
end

RSpec.configure do |config|
  config.include CachingHelpers

  config.before(:each, :caching) do
    cache_store = ActiveSupport::Cache::MemoryStore.new
    allow(controller).to receive(:cache_store).and_return(cache_store)
    allow(::Rails).to receive(:cache).and_return(cache_store)
    Rails.cache.clear
  end

  config.around(:each, :caching) do |example|
    caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    example.run
    ActionController::Base.perform_caching = caching
  end
end
