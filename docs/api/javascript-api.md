# ReactOnRails JavaScript API
The best source of docs is the main [ReactOnRails.js](../../node_package/src/ReactOnRails.js) file. Here's a quick summary. No guarantees that this won't be outdated!

```js
  /**
   * Main entry point to using the react-on-rails npm package. This is how Rails will be able to
   * find you components for rendering. Components get called with props, or you may use a
   * "generator function" to return a React component or an object with the following shape:
   * { renderedHtml, redirectLocation, error }.
   * @param components (key is component name, value is component)
   */
  register(components)

  /**
   * Allows registration of store generators to be used by multiple react components on one Rails
   * view. store generators are functions that take one arg, props, and return a store. Note that
   * the setStore API is different in tha it's the actual store hydrated with props.
   * @param stores (key is store name, value is the store generator)
   */
  registerStore(stores)

  /**
   * Allows retrieval of the store by name. This store will be hydrated by any Rails form props.
   * Pass optional param throwIfMissing = false if you want to use this call to get back null if the
   * store with name is not registered.
   * @param name
   * @param throwIfMissing Defaults to true. Set to false to have this call return undefined if
   *        there is no store with the given name.
   * @returns Redux Store, possibly hydrated
   */
  getStore(name, throwIfMissing = true )

  /**
   * Set options for ReactOnRails, typically before you call ReactOnRails.register
   * Available Options:
   * `traceTurbolinks: true|false Gives you debugging messages on Turbolinks events
   */
  setOptions(options)

  /**
   * Allow directly calling the page loaded script in case the default events that trigger react
   * rendering are not sufficient, such as when loading JavaScript asynchronously with TurboLinks:
   * More details can be found here:
   * https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/turbolinks.md
   */
  reactOnRailsPageLoaded()

  /**
   * Returns CSRF authenticity token inserted by Rails csrf_meta_tags
   * @returns String or null
   */

  authenticityToken()

  /**
   * Returns header with csrf authenticity token and XMLHttpRequest
   * @param {*} other headers
   * @returns {*} header
   */

  authenticityHeaders(otherHeaders = {})
```
