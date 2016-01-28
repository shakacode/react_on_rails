# Turbolinks

* See [Turbolinks on Github](https://github.com/rails/turbolinks)
* Currently support 2.5.x of Turbolinks. We plan to update to Turbolinks 5 soon.

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

## Troubleshooting
To turn on tracing of Turbolinks events, require `debug_turbolinks` (provided by ReactOnRails) inside of `app/assets/javascripts/application.js` **at the beginning of the file**. This will print out events related to the initialization of the components created with the view helper `react_component`.

We've noticed that Turbolinks doesn't work if you use the ruby gem version of jQuery and jQuery ujs. Therefore we recommend using the node packages instead. See the [tutorial app](https://github.com/shakacode/react-webpack-rails-tutorial) for how to accomplish this.
