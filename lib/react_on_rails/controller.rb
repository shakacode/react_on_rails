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
    # immediate_hydration: React on Rails Pro (licensed) feature. Pass as true if you wish to hydrate this
    #                      store immediately instead of waiting for the page to load.
    #
    # Be sure to include view helper `redux_store_hydration_data` at the end of your layout or view
    # or else there will be no client side hydration of your stores.
    def redux_store(store_name, props: {}, immediate_hydration: nil)
      immediate_hydration = ReactOnRails::ProUtils.immediate_hydration_config if immediate_hydration.nil?
      redux_store_data = { store_name: store_name,
                           props: props,
                           immediate_hydration: immediate_hydration }
      @registered_stores_defer_render ||= []
      @registered_stores_defer_render << redux_store_data
    end
  end
end
