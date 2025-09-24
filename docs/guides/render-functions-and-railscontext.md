# Render-Functions and the Rails Context

## Render-Functions

When you use a render-function to create React components (or `renderedHtml` on the server), or you
use shared Redux stores, you get two params passed to your function that creates a React component:

1. `props`: Props that you pass in the view helper of either `react_component` or `redux_store`
2. `railsContext`: Rails contextual information, such as the current pathname. You can customize
   this in your config file. **Note**: The `railsContext` is not related to the concept of a
   ["context" for React components](https://react.dev/reference/react/useContext).

These parameters (`props` and `railsContext`) will be the same for client- and server-side rendering,
except for the property `railsContext.serverSide` which tells you which one it is.

While you could manually configure your Rails code to pass the "`railsContext` information" with
the rest of your "props", the `railsContext` is a convenience because it's passed consistently to
all invocations of Render-Functions.

For example, suppose you create a "render-function" called `MyAppComponent`.

```js
import React from 'react';
const MyAppComponent =
  (props, railsContext) =>
  // NOTE: need to wrap in a function so this is a proper React function component that can use hooks

  // the props get passed again, but we ignore since we use a closure
  // or should we
  () => (
    <div>
      <p>props are: {JSON.stringify(props)}</p>
      <p>railsContext is: {JSON.stringify(railsContext)}</p>
    </div>
  );
export default MyAppComponent;
```

---

_This would be an alternate API where you have to call `React.createElement` and the React on Rails code doesn't do that._

```js
import React from 'react';
const MyAppComponent = (props, railsContext) =>
  // NOTE: need to wrap in a function so this is proper React function component that can use
  // hooks
  React.createElement(
    () => (
      <div>
        <p>props are: {JSON.stringify(props)}</p>
        <p>railsContext is: {JSON.stringify(railsContext)}</p>
      </div>
    ),
    props,
  );
export default MyAppComponent;
```

---

> [!NOTE]
> You will get a React browser console warning if you try to render this on the server since the value of `serverSide` will be different for server rendering.

So if you register your render-function `MyAppComponent`, it will get called like:

```js
reactComponent = MyAppComponent(props, railsContext);
```

Similarly, any Redux store is always initialized with 2 parameters:

```js
reduxStore = MyReduxStore(props, railsContext);
```

> [!NOTE]
> You never make these calls. React on Rails makes these calls when it does either client or server rendering. You will define functions that take these 2 params and return a React component or a Redux Store. Naturally, you do not have to use second parameter, `railsContext`, if you do not need it. If you don't take a second parameter, then you're probably defining a React function component and you will simply return a React Element, often just JSX.

> [!NOTE]
> See [Redux Store](../api/redux-store-api.md#multiple-react-components-on-a-page-with-one-store) on how to set up Redux stores that allow multiple components to talk to the same store.

The `railsContext` has: (see the implementation in [ReactOnRails::Helper](https://github.com/shakacode/react_on_rails/tree/master/lib/react_on_rails/helper.rb), method `rails_context` for the definitive list).

```ruby
  {
    railsEnv: Rails.env,
    inMailer: in_mailer?,
    # Locale settings
    i18nLocale: I18n.locale,
    i18nDefaultLocale: I18n.default_locale,
    rorVersion: ReactOnRails::VERSION,
    rorPro: ReactOnRails::Utils.react_on_rails_pro?,

    # URL settings
    href: request.original_url,
    location: "#{uri.path}#{uri.query.present? ? "?#{uri.query}": ""}",
    scheme: uri.scheme, # http
    host: uri.host, # foo.com
    port: uri.port,
    pathname: uri.path, # /posts
    search: uri.query, # id=30&limit=5
    httpAcceptLanguage: request.env["HTTP_ACCEPT_LANGUAGE"],

    # Other
    serverSide: boolean,
    # Are we being called on the server or client? Note: if you conditionally
     # render something different on the server than the client, then React will only show the
     # server version!
  }
```

Plus, you can add your customizations to this. See "rendering extension" below.

## Rails Context

The `railsContext` is a second param passed to your render-functions for React components. This is in addition to the props that are passed from the `react_component` Rails helper. For example:

ERB view file:

```erb
  # Rails View
  <%= react_component("HelloWorld", props: { name: "Stranger" }) %>
```

This is what your HelloWorld.js file might contain. The railsContext is always available for any parameters that you _always_ want available for your React components. It has _nothing_ to do with the concept of the [React Context](https://reactjs.org/docs/context.html).

```js
import React from 'react';

export default (props, railsContext) => {
  // Note, wrap in a function so this is React function component
  return () => (
    <div>
      Your locale is {railsContext.i18nLocale}.<br />
      Hello, {props.name}!
    </div>
  );
};
```

## Why is the railsContext only passed to render-functions?

There's no reason that the railsContext would ever get passed to your React component unless the value is explicitly put into the props used for rendering. If you create a React component, rather than a render-function, for use by React on Rails, then you get whatever props are passed in from the view helper, which **does not include the Rails Context**. It's trivial to wrap your component in a "render-function" to return a new component that takes both:

```js
import React from 'react';
import AppComponent from './AppComponent';
const AppComponentWithRailsContext =
  (props, railsContext) =>
  // Create a React Function Component so you can
  // use the React Hooks API in this React Function Component
  () => <AppComponent {...{ ...props, railsContext }} />;
export default AppComponentWithRailsContext;
```

Consider this line in depth:

```js
<AppComponent {...{ ...props, railsContext }} />
```

The outer `{...` is for the [JSX spread operator for attributes](https://legacy.reactjs.org/docs/jsx-in-depth.html#spread-attributes) and the inner `{...` is for the [Spread in object literals](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_operator#Spread_in_object_literals).

## Use Cases

### Heroku Preboot Considerations

[Heroku Preboot](https://devcenter.heroku.com/articles/preboot) is a feature on Heroku that allows for faster deploy times. When you promote your staging app to production, Preboot simply switches the production server to point at the staging app's container. This means it can deploy much faster since it doesn't have to rebuild anything. However, this means that if you use the [Define Plugin](https://github.com/webpack/docs/wiki/list-of-plugins#defineplugin) to provide the Rails environment to your client code as a variable, that variable will erroneously still have a value of `Staging` instead of `Production`. The `Rails.env` provided at runtime in the railsContext is, however, accurate.

### Needing the current URL path for server rendering

Suppose you want to display a nav bar with the current navigation link highlighted by the URL. When you server-render the code, your code will need to know the current URL/path. The new `railsContext` has this information. Your application will apply something like an "active" class on the server rendering.

### Configuring different code for server side rendering

Suppose you want to turn off animation when doing server side rendering. The `serverSide` value is just what you need.

## Customization of the Rails context

You can customize the values passed in the `railsContext` in your `config/initializers/react_on_rails.rb`. Here's how.

Set the config value for the `rendering_extension`:

```ruby
  config.rendering_extension = RenderingExtension
```

Implement it like this above in the same file. Create a class method on the module called `custom_context` that takes the `view_context` for a param.

See [spec/dummy/config/initializers/react_on_rails.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb) for a detailed example.

```ruby
module RenderingExtension

  # Return a Hash that contains custom values from the view context that will get merged with
  # the standard rails_context values and passed to all calls to render-functions used by the
  # react_component and redux_store view helpers
  def self.custom_context(view_context)
    {
     somethingUseful: view_context.session[:something_useful]
    }
  end
end
```

In this case, a prop and value for `somethingUseful` will go into the `railsContext` passed to all `react_component` and `redux_store` calls. You may set any values available in the view rendering context.
