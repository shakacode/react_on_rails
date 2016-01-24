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

You cans set a global debug flag in your `application.js` to turn on tracing of Turbolinks events
as they pertain to React on Rails.

1. Add this line to your `application.js`:
   ```javascript
   //= require testGlobals
   ```
2. Initialie the global debug value of `DEBUG_TURBOLINKS` like this:
   ```javascript
   window.DEBUG_TURBOLINKS = true;
   console.log('window.DEBUG_TURBOLINKS = true;');
   ```
   
This will print out events related to the initialization of the components created with the view 
helper `react_component`.
