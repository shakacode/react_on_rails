# Using React Helmet to build ```<head>``` content

## Installation and general usage
See https://github.com/nfl/react-helmet for details. Run ```yarn add react-helmet``` in your ```client``` directory to add this package to your application.

## Example
Here is what you need to do in order to configure your Rails application to work with **ReactHelmet**.

 Create generator function for server rendering like this:

```javascript
export default (props, _railsContext) => {
  const YourAppRegistrationKey = renderToString(<App {...props} />);
  const helmet = Helmet.renderStatic();

  const renderedHtml = {
    YourAppRegistrationKey,
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

Put **ReactHelmet** component somewhere in your ```<App>```:
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
import YourAppRegistrationKey from '../ClientApp';

ReactOnRails.register({
  YourAppRegistrationKey
});
```
```javascript
import YourAppRegistrationKey from '../ServerApp';

ReactOnRails.register({
  YourAppRegistrationKey
});
```
Now when ```react_component``` helper will be called with **"YourAppRegistrationKey"** as a first argument it will return a hash instead of HTML string:
```ruby
<% render_hash = react_component("ReactHelmetApp", prerender: true, props: { hello: "world" }, trace: true) %>

<% content_for :title do %>
  <%= render_hash['title'] %>
<% end %>

<%= render_hash["ReactHelmetApp"] %>
```

So now we're able to insert received title tag to our application layout:
```ruby
 <%= yield(:title) if content_for?(:title) %>
```
