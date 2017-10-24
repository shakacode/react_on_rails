# Using React Helmet to build `<head>` content

## Installation and general usage
See https://github.com/nfl/react-helmet for details. Run `yarn add react-helmet` in your `client` directory to add this package to your application.

## Example
Here is what you need to do in order to configure your Rails application to work with **ReactHelmet**.

 Create generator function for server rendering like this:

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
You can add more **helmet** properties to result, e.g. **meta**, **base** and so on. See https://github.com/nfl/react-helmet#server-usage.

Use regular component or generator function for client-side:

```javascript
export default (props, _railsContext) => (
  <App {...props} />
);
```

Put **ReactHelmet** component somewhere in your `<App>`:
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
  ReactHelmetApp
});
```
```javascript
import ReactHelmetApp from '../ReactHelmetServerApp';

ReactOnRails.register({
  ReactHelmetApp
});
```
Now when the `react_component_hash` helper is called with **"ReactHelmetApp"** as a first argument it will return a hash instead of HTML string:
```ruby
<% react_helmet_app = react_component_hash("ReactHelmetApp", prerender: true, props: { hello: "world" }, trace: true) %>

<% content_for :title do %>
  <%= react_helmet_app['title'] %>
<% end %>

<%= react_helmet_app["componentHtml"] %>
```

So now we're able to insert received title tag to our application layout:
```ruby
 <%= yield(:title) if content_for?(:title) %>
```

Note: Use of `react_component` for this functionality is deprecated. Please use `react_component_hash` instead.
