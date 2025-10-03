# Using React Helmet to build `<head>` content

## Installation and general usage

See [nfl/react-helmet](https://github.com/nfl/react-helmet) for details on how to use this package.
Run `yarn add react-helmet` to add this package to your application.

## Example

Here is what you need to do in order to configure your Rails application to work with **ReactHelmet**.

Create a render-function for server rendering like this:

```javascript
export default (props, _railsContext) => {
  const componentHtml = renderToString(<App {...props} />);
  const helmet = Helmet.renderStatic();

  const renderedHtml = {
    componentHtml,
    title: helmet.title.toString(),
  };
  return { renderedHtml };
};
```

You can add more **helmet** properties to the result, e.g. **meta**, **base** and so on. See https://github.com/nfl/react-helmet#server-usage.

Use a regular React functional or class component or a render-function for your client-side bundle:

```javascript
// React functional component
export default (props) => <App {...props} />;
```

Or a render-function. Note you can't return just the JSX (React element), but you need to return
either a React functional or class component.

```javascript
// React functional component
export default (props, railsContext) => (
  () => <App {{railsContext, ...props}} />
);
```

Note, this doesn't work, because this function just returns a React element rather than a React component

```javascript
// React functional component
export default (props, railsContext) => (
  <App {{railsContext, ...props}} />
);
```

Put the **ReactHelmet** component somewhere in your `<App>`:

```javascript
import { Helmet } from 'react-helmet';

const App = (props) => (
  <div>
    <Helmet>
      <title>Custom page title</title>
    </Helmet>
    ...
  </div>
);

export default App;
```

Register your generators for client and server sides:

```javascript
import ReactHelmetApp from '../ReactHelmetClientApp';

ReactOnRails.register({
  ReactHelmetApp,
});
```

```javascript
// Note the import from the server file.
import ReactHelmetApp from '../ReactHelmetServerApp';

ReactOnRails.register({
  ReactHelmetApp,
});
```

Now when the `react_component_hash` helper is called with **"ReactHelmetApp"** as a first argument it
will return a hash instead of an HTML string. Note, there is no need to specify "prerender" as it would not
make sense to use react_component_hash without server rendering:

```erb
<% react_helmet_app = react_component_hash("ReactHelmetApp", props: { hello: "world" }, trace: true) %>

<% content_for :title do %>
  <%= react_helmet_app['title'] %>
<% end %>

<%= react_helmet_app["componentHtml"] %>
```

So now we're able to insert received title tag to our application layout:

```erb
 <%= yield(:title) if content_for?(:title) %>
```
