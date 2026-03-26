# Using ReactOnRails in JavaScript

You can easily render React components in your JavaScript with `render` method. Under React 18+, it returns a React root. Under React 16/17, it returns the rendered component instance.

```js
/**
 * ReactOnRails.render("HelloWorldApp", {name: "Stranger"}, 'app');
 *
 * Under React 16/17, this is equivalent to:
 *   ReactDOM.render(React.createElement(HelloWorldApp, {name: "Stranger"}),
 *     document.getElementById('app'))
 *
 * Under React 18+, it uses:
 *   const root = ReactDOMClient.createRoot(document.getElementById('app'));
 *   root.render(React.createElement(HelloWorldApp, {name: "Stranger"}));
 *   return root;
 *
 * @param name Name of your registered component
 * @param props Props to pass to your component
 * @param domNodeId
 * @param hydrate [optional] Pass truthy to update server rendered html. Default is falsy
 * @returns {Root|Component|Element|void} React root in React 18+, or legacy return values in
 *   React 16/17 depending on the render or hydrate path
 */
ReactOnRails.render(componentName, props, domNodeId);
```

## Why do we need this?

Imagine that some external JavaScript decides when a component should mount with the current value.

```html
<input id="input" type="range" min="0" max="100" />
<div id="root"></div>

<script>
  var input = $('#input');
  ReactOnRails.render('componentName', { value: input.val() }, 'root');
</script>
```

For subsequent updates on the same DOM node, let the mounted React component manage its own
state or props flow. `ReactOnRails.render` skips duplicate renders for the same connected node,
so calling it repeatedly on `#root` will be ignored unless that node is replaced first.
