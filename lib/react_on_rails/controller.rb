# frozen_string_literal: true

module ReactOnRails
  module Controller
    # Separate initialization of store from react_component allows multiple react_component calls to
    # use the same Redux store.
    #
    # store_name: name of the store, corresponding to your call to ReactOnRails.registerStores in your
    #             JavaScript code.
    # props: Named parameter props which is a Ruby Hash or JSON string which contains the properties
    #        to pass to the redux store.
    # immediate_hydration: React on Rails Pro (licensed) feature. When nil (default), Pro users get
    #                      immediate hydration, non-Pro users don't. Can be explicitly overridden.
    #
    # Be sure to include view helper `redux_store_hydration_data` at the end of your layout or view
    # or else there will be no client side hydration of your stores.
    def redux_store(store_name, props: {}, immediate_hydration: nil)
      # If non-Pro user explicitly sets immediate_hydration: true, warn and override to false
      if immediate_hydration == true && !ReactOnRails::Utils.react_on_rails_pro?
        Rails.logger.warn <<~WARNING
          [REACT ON RAILS] Warning: immediate_hydration: true requires a React on Rails Pro license.
          Store '#{store_name}' will fall back to standard hydration behavior.
          Visit https://www.shakacode.com/react-on-rails-pro/ for licensing information.
        WARNING
        immediate_hydration = false
      elsif immediate_hydration.nil?
        immediate_hydration = ReactOnRails::Utils.react_on_rails_pro?
      end

      redux_store_data = { store_name: store_name,
                           props: props,
                           immediate_hydration: immediate_hydration }
      @registered_stores_defer_render ||= []
      @registered_stores_defer_render << redux_store_data
    end
  end
end
