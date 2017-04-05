# Turbolinks

* See [Turbolinks on Github](https://github.com/rails/turbolinks)
* React on Rails currently supports 2.5.x of Turbolinks and 5.0.0 of Turbolinks 5.
* You may include Turbolinks either via yarn (recommended) or via the gem.

## Why Turbolinks?
As you switch between Rails HTML controller requests, you will only load the HTML and you will
not reload JavaScript and stylesheets. This definitely can make an app perform better, even if
the JavaScript and stylesheets are cached by the browser, as they will still require parsing.

## Requirements for Using Turbolinks
1. You are **not using [react-router](https://github.com/ReactTraining/react-router)** or you are prepared to deal with some potential issues with where react-router and Turbolinks overlaps.
2. You are **using one JS and one CSS file** throughout your app. Otherwise, you will have to figure out how best to handle multiple JS and CSS files throughout the app given Turbolinks.

## Why Not Turbolinks
1. [react-router](https://github.com/ReactTraining/react-router) handles the back and forward buttons, as does TurboLinks. You *might* be able to make this work. *Please share your findings.*
1. You want to do code splitting to minimize the JavaScript loaded.

## More Information
* CSRF tokens need thorough checking with Turbolinks5. Turbolinks5 changes the head element by JavaScript (not only body) on page changes with the correct csrf meta tag, but if the JS code parsed this from head when several windows were opened, then our specs were not all passing. I didn't look details however, may be it is app code related, not library code. Anyway it may need additional check because there is CSRF helper in ReactOnRails and it need to work with Turbolinks5.
* Turbolinks5 send requests without the `Accept: */*` in the header, only exactly like `Accept: text/html` which makes Rails behave a bit specifically compared to normal and mime-parsing, which is skipped by when Rails see */*. For some more details on Rails and */* can read [Mime Type Resolution in Rails](http://blog.bigbinary.com/2010/11/23/mime-type-resolution-in-rails.html)
* If you're using multiple Webpack bundles, be sure to ensure that there are no name conflicts between JS objects or redux store paths.

### Install Checklist
1. Include turbolinks via yarn as shown in the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/blob/8a6c8aa2e3b7ae5b08b0a9744fb3a63a2fe0f002/client/webpack.client.base.config.js#L22) or include the gem "turbolinks".
1. Included the proper "track" tags when you include the javascript and stylesheet:
  ```erb
    <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track' => 'reload' %>
    <%= javascript_include_tag 'application', 'data-turbolinks-track' => 'reload' %>
  ```
  NOTE: for Turbolinks 2.x, use 'data-turbolinks-track' => true
1. Add turbolinks to your `application.js` file:
   ```javascript
   //= require turbolinks
   ```

## Turbolinks 5
Turbolinks 5 is now being supported. React on Rails will automatically detect which version of Turbolinks you are using and use the correct event handlers.

For more information on Turbolinks 5: [https://github.com/turbolinks/turbolinks](https://github.com/turbolinks/turbolinks)

## Turbolinks from NPM

See the [instructions on installing from NPM](https://github.com/turbolinks/turbolinks#installation-using-npm).

```js
import Turbolinks from "turbolinks";
Turbolinks.start();
```

### async script loading
Generally async script loading can be done like:
```erb
  <%= javascript_include_tag 'application', async: Rails.env.production? %>
```
If you use ```document.addEventListener("turbolinks:load", function() {...});``` somewhere in your code, you will notice, that Turbolinks 5 does not fire ```turbolinks:load``` on initial page load. A quick workaround is to use ```defer``` instead of ```async```:
```erb
  <%= javascript_include_tag 'application', defer: Rails.env.production? %>
```
More information on this issue can be found here: https://github.com/turbolinks/turbolinks/issues/28

When loading your scripts asynchronously you may experience, that your Components are not registered correctly. Call ```ReactOnRails.reactOnRailsPageLoaded()``` to re-initialize like so:
```
  document.addEventListener("turbolinks:load", function() {
    ReactOnRails.reactOnRailsPageLoaded();
  });
```

## Troubleshooting
To turn on tracing of Turbolinks events, put this in your registration file, where you register your components.

```js
   ReactOnRails.setOptions({
     traceTurbolinks: true,
   });
```

Rather than setting the value to true, you could set it to TRACE_TURBOLINKS, and then you could place this in your `webpack.client.base.config.js`:

Define this const at the top of the file:
```js
  const devBuild = process.env.NODE_ENV !== 'production';
```

Add this DefinePlugin option:
```js
  plugins: [
   new webpack.DefinePlugin({
     TRACE_TURBOLINKS: devBuild,
   }),
```

At Webpack compile time, the value of devBuild is inserted into your file.

Once you do that, you'll see messages prefixed with **TURBO:** like this in the browser console:

Turbolinks Classic:
```
TURBO: WITH TURBOLINKS: document page:before-unload and page:change handlers installed. (program)
TURBO: reactOnRailsPageLoaded
```

Turbolinks 5:
```
TURBO: WITH TURBOLINKS 5: document turbolinks:before-render and turbolinks:render handlers installed. (program)
TURBO: reactOnRailsPageLoaded
```

We've noticed that Turbolinks doesn't work if you use the ruby gem version of jQuery and jQuery ujs. Therefore we recommend using the node packages instead. See the [tutorial app](https://github.com/shakacode/react-webpack-rails-tutorial) for how to accomplish this.

![2016-02-02_10-38-07](https://cloud.githubusercontent.com/assets/1118459/12760060/6546e254-c999-11e5-828b-a8aaa473e5bd.png)
