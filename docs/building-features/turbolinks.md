# Turbolinks and Turbo Support

## React on Rails Updated to support Turbo, August 2024

- See [PR 1620](https://github.com/shakacode/react_on_rails/pull/1620).
- See [PR 1374](https://github.com/shakacode/react_on_rails/pull/1374).
- Ability to use with [Turbo (`@hotwired/turbo`)](https://turbo.hotwired.dev/), as Turbolinks becomes obsolete.

## Using Turbo

Turbo is the modern replacement for Turbolinks, providing fast navigation through your Rails app without full page reloads.

### Basic Setup

**1. Install Turbo**

Add the Turbo Rails gem and JavaScript package:

```bash
# Gemfile
gem "turbo-rails"

# JavaScript
yarn add @hotwired/turbo-rails
```

**2. Enable Turbo in React on Rails**

Import Turbo and configure React on Rails to work with it:

```js
// app/javascript/packs/application.js
import '@hotwired/turbo-rails';

ReactOnRails.setOptions({
  turbo: true, // Enable Turbo support (not auto-detected)
});
```

**3. Use Turbo Frames** (works out of the box)

Turbo Frames work with React components without any special configuration:

```erb
<%# app/views/items/index.html.erb %>
<%= turbo_frame_tag 'item-list' do %>
  <%= react_component("ItemList", props: @items) %>
<% end %>

<%# Clicking a link that responds with another turbo_frame_tag will update just that frame %>
```

### Turbo Streams (Requires React on Rails Pro)

> **⚡️ React on Rails Pro Feature**
>
> Turbo Streams require the `immediate_hydration: true` option, which is a [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/) licensed feature.

**Why Turbo Streams Need Special Handling:**

Unlike Turbo Frames, Turbo Streams don't dispatch the normal `turbo:render` events that React on Rails uses to hydrate components. Instead, they directly manipulate the DOM. The `immediate_hydration` option tells React on Rails to hydrate the component immediately when it's inserted into the DOM, without waiting for page load events.

**Example: Create a Turbo Stream Response**

```erb
<%# app/views/items/index.html.erb - Initial page with frame %>
<%= turbo_frame_tag 'item-list' do %>
  <%= button_to "Load Items", items_path, method: :post %>
<% end %>
```

```erb
<%# app/views/items/create.turbo_stream.erb - Turbo Stream response %>
<%= turbo_stream.update 'item-list' do %>
  <%= react_component("ItemList",
                      props: @items,
                      immediate_hydration: true) %>
<% end %>
```

**What Happens:**

1. User clicks "Load Items" button
2. Rails responds with `create.turbo_stream.erb`
3. Turbo Stream updates the `item-list` frame with the new React component
4. `immediate_hydration: true` ensures the component hydrates immediately

**Learn More:**

- See [v16.0 Release Notes](../upgrading/release-notes/16.0.0.md#enhanced-script-loading-strategies) for full `immediate_hydration` documentation
- See [Streaming Server Rendering](./streaming-server-rendering.md) for another Pro use case
- Working example in codebase: `spec/dummy/app/views/pages/turbo_stream_send_hello_world.turbo_stream.erb`
- Contact [justin@shakacode.com](mailto:justin@shakacode.com) for React on Rails Pro licensing

**Migration Note:** If you're referencing [PR #1620](https://github.com/shakacode/react_on_rails/pull/1620) discussions, note that `force_load` was renamed to `immediate_hydration` in v16.0.

## Legacy Turbolinks Support

_The following documentation covers older Turbolinks versions (2.x and 5.x). While still supported by React on Rails, we recommend migrating to Turbo when possible._

React on Rails currently supports:

- **Turbolinks 5.x** (e.g., 5.0.0+) - Auto-detected
- **Turbolinks 2.x** (Classic) - Auto-detected
- See [Turbolinks on Github](https://github.com/rails/turbolinks)

You may include Turbolinks either via yarn (recommended) or via the gem.

### Why Turbolinks?

As you switch between Rails HTML controller requests, you will only load the HTML and you will not reload JavaScript and stylesheets.
This definitely can make an app perform better, even if the JavaScript and stylesheets are cached by the browser, as they will still require parsing.

### Requirements for Using Turbolinks

1. Either **avoid using [React Router](https://reactrouter.com/)** or be prepared to deal with any conflicts between it and Turbolinks.
2. **Use one JS and one CSS file** throughout your app. Otherwise, you will have to figure out how best to handle multiple JS and CSS files throughout the app given Turbolinks.

### Why Not Turbolinks

1. [React Router](https://reactrouter.com/) handles the back and forward buttons, as does Turbolinks. You _might_ be able to make this work. _Please share your findings._
1. You want to do code splitting to minimize the JavaScript loaded.

### Installation

#### Install Checklist

1. Include turbolinks via yarn as shown in the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/blob/8a6c8aa2e3b7ae5b08b0a9744fb3a63a2fe0f002/client/webpack.client.base.config.js#L22) or include the gem "turbolinks".
1. Included the proper "track" tags when you include the javascript and stylesheet:

**For Turbolinks 5.x:**

```erb
  <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track' => 'reload' %>
  <%= javascript_include_tag 'application', 'data-turbolinks-track' => 'reload' %>
```

**For Turbolinks 2.x (Classic):**

```erb
  <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track' => true %>
  <%= javascript_include_tag 'application', 'data-turbolinks-track' => true %>
```

**Note:** If you're using modern Turbo (recommended), use `'data-turbo-track' => 'reload'` instead of `'data-turbolinks-track'`. See the "Using Turbo" section at the top of this document.

1. Add turbolinks to your `application.js` file:
   ```javascript
   //= require turbolinks
   ```

#### Turbolinks from NPM

See the [instructions on installing from NPM](https://github.com/turbolinks/turbolinks#installation-using-npm).

```js
import Turbolinks from 'turbolinks';
Turbolinks.start();
```

##### Async script loading

Async script loading can be done like this (starting with Shakapacker 8.2):

```erb
  <%= javascript_include_tag 'application', async: Rails.env.production? %>
```

If you use `document.addEventListener("turbolinks:load", function() {...});` somewhere in your code, you will notice that Turbolinks 5 does not fire `turbolinks:load` on initial page load. A quick workaround for React on Rails earlier than 15 is to use `defer` instead of `async`:

```erb
  <%= javascript_include_tag 'application', defer: Rails.env.production? %>
```

More information on this issue can be found here: https://github.com/turbolinks/turbolinks/issues/28

When loading your scripts asynchronously your components may not be registered correctly. Call `ReactOnRails.reactOnRailsPageLoaded()` to re-initialize like so:

```js
document.addEventListener('turbolinks:load', function () {
  ReactOnRails.reactOnRailsPageLoaded();
});
```

React on Rails 15 fixes both issues, so if you still have the listener it can be removed (and should be as `reactOnRailsPageLoaded()` is now async).

> [!WARNING] > **Async Scripts with Turbolinks Require Pro Feature**
>
> If you use async script loading with Turbolinks, you must enable `immediate_hydration: true` to prevent race conditions. This is a React on Rails Pro feature.
>
> Without `immediate_hydration: true`, async scripts may not be ready when Turbolinks fires navigation events, causing components to fail hydration.
>
> **Alternatives:**
>
> - Use `defer` instead of `async` (waits for full page load before hydration)
> - Upgrade to modern Turbo (recommended)
> - Use React on Rails Pro for `immediate_hydration: true`

### Turbolinks 5 Specific Information

React on Rails will automatically detect which version of Turbolinks you are using (2.x or 5.x) and use the correct event handlers.

For more information on Turbolinks 5: [https://github.com/turbolinks/turbolinks](https://github.com/turbolinks/turbolinks)

### Technical Details and Troubleshooting

#### CSRF and MIME Type Handling

- **CSRF tokens**: Turbolinks 5 changes the head element by JavaScript (not only body) on page changes with the correct csrf meta tag. Be thorough checking CSRF tokens, especially when multiple windows are opened, as the CSRF helper in ReactOnRails needs to work with Turbolinks5.
- **MIME type handling**: Turbolinks 5 sends requests with `Accept: text/html` only (not `Accept: */*`), which makes Rails behave differently compared to normal requests. For more details on the special handling of `*/*` you can read [Mime Type Resolution in Rails](http://blog.bigbinary.com/2010/11/23/mime-type-resolution-in-rails.html).
- **Multiple Webpack bundles**: If you're using multiple Webpack bundles, make sure that there are no name conflicts between JS objects or Redux store paths.

#### Debugging Turbolinks Events

To turn on tracing of Turbolinks events, put this in your registration file, where you register your components.

```js
ReactOnRails.setOptions({
  traceTurbolinks: true,
  turbo: true,
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

```text
TURBO: WITH TURBOLINKS: document page:before-unload and page:change handlers installed. (program)
TURBO: reactOnRailsPageLoaded
```

Turbolinks 5:

```text
TURBO: WITH TURBOLINKS 5: document turbolinks:before-render and turbolinks:render handlers installed. (program)
TURBO: reactOnRailsPageLoaded
```

We've noticed that Turbolinks doesn't work if you use the RubyGem versions of jQuery and jQuery ujs. Therefore, we recommend using the JS packages instead. See the [tutorial app](https://github.com/shakacode/react-webpack-rails-tutorial) for how to accomplish this.

![Show we only install the Turbolinks handlers once](https://cloud.githubusercontent.com/assets/1118459/12760060/6546e254-c999-11e5-828b-a8aaa473e5bd.png)
