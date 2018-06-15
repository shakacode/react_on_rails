# Redux Store

First things first. You don't need to use the `redux_store` api to use redux. This api was setup to support multiple calls to `react_component` on one page that all talk to the same redux store.

If you are only rendering one react component on a page, as is typical to do a "Single Page App" in React, then you should pass the props to your React component in a "generator function." 

Consider using the `redux_store` helper for the two following use cases:

1. You want to have multiple React components accessing the same store at once.
2. You want to place the props to hydrate the client side stores at the very end of your HTML so that the browser can render all earlier HTML first. This is particularly useful if your props will be large.

## Controller Extension

Include the module `ReactOnRails::Controller` in your controller, probably in ApplicationController. This will provide the following controller method, which you can call in your controller actions:

`redux_store(store_name, props: {})`

- **store_name:** A name for the store. You'll refer to this name in 2 places in your JavaScript:
  1. You'll call `ReactOnRails.registerStore({storeName})` in the same place that you register your components.
  2. In your component definition, you'll call `ReactOnRails.getStore('storeName')` to get the hydrated Redux store to attach to your components.
- **props:**  Named parameter `props`. ReactOnRails takes care of setting up the hydration of your store with props from the view.

For an example, see [spec/dummy/app/controllers/pages_controller.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/controllers/pages_controller.rb). Note: this is preferable to using the equivalent view_helper `redux_store` in that you can be assured that the store is initialized before your components.

## View Helper

`redux_store(store_name, props: {})`

This method has the same API as the controller extension. **HOWEVER**, we recommend the controller extension instead because the Rails executes the template code in the controller action's view file (`erb`, `haml`, `slim`, etc.) before the layout. So long as you call `redux_store` at the beginning of your action's view file, this will work. However, it's an easy mistake to put this call in the wrong place. Calling `redux_store` in the controller action ensures proper load order, regardless of where you call this in the controller action. Note: you won't know of this subtle ordering issue until you server render and you find that your store is not hydrated properly.

`redux_store_hydration_data`

Place this view helper (no parameters) at the end of your shared layout so ReactOnRails will render the redux store hydration data. Since we're going to be setting up the stores in the controllers, we need to know where on the view to put the client-side rendering of this hydration data, which is a hidden div with a matching class that contains a data props. For an example, see [spec/dummy/app/views/layouts/application.html.erb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/views/layouts/application.html.erb).

# More Details

* [lib/react_on_rails/controller.rb](../../lib/react_on_rails/controller.rb) source
* [lib/react_on_rails/react_on_rails_helper.rb](../../lib/react_on_rails/react_on_rails_helper.rb) source
