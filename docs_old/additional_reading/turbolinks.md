# Turbolinks

* See [Turbolinks on Github](https://github.com/rails/turbolinks)
* Currently support 2.5.x of Turbolinks and 5.0.0.beta1 of Turbolinks 5.
* Turbolinks is currently included only via the Rails gem and the Rails manifest file rather than NPM. [Turbolinks Issue #658 ](https://github.com/rails/turbolinks/issues/658) discusses this.

## Why Turbolinks?
As you switch between Rails HTML controller requests, you will only load the HTML and you will
not reload JavaScript and stylesheets. This definitely can make an app perform better, even if
the JavaScript and stylesheets are cached by the browser, as they will still require parsing.

### Install Checklist
1. Include the gem "turbolinks".
1. Included the proper "track" tags when you include the javascript and stylesheet:
  ```erb
    <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track' => true %>
    <%= javascript_include_tag 'application', 'data-turbolinks-track' => true %>
  ```
1. Add turbolinks to your `application.js` file:
   ```javascript
   //= require turbolinks
   ```
Note, in the future, we might change to installing this via npm.

## Turbolinks 5
Turbolinks 5 is now being supported. React on Rails will automatically detect which version of Turbolinks you are using and use the correct event handlers.

For more information on Turbolinks 5: [https://github.com/turbolinks/turbolinks](https://github.com/turbolinks/turbolinks)

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
TURBO: WITH TURBOLINKS 5: document turbolinks:before-cache and turbolinks:load handlers installed. (program)
TURBO: reactOnRailsPageLoaded
```

We've noticed that Turbolinks doesn't work if you use the ruby gem version of jQuery and jQuery ujs. Therefore we recommend using the node packages instead. See the [tutorial app](https://github.com/shakacode/react-webpack-rails-tutorial) for how to accomplish this.

![2016-02-02_10-38-07](https://cloud.githubusercontent.com/assets/1118459/12760060/6546e254-c999-11e5-828b-a8aaa473e5bd.png)
