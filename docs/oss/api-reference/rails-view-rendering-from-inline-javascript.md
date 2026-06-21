# Using ReactOnRails in JavaScript

You can easily render React components in your JavaScript with the `render` method. Under React 18+, it returns a React root. Under React 16/17, legacy return values vary by render or hydrate path, such as a component instance, an element, or `void`.

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
  const input = document.getElementById('input');
  ReactOnRails.render('componentName', { value: input.value }, 'root');
</script>
```

For subsequent updates on the same DOM node, let the mounted React component manage its own
state or props flow. The public `ReactOnRails.render` API does not deduplicate repeated calls,
so calling it on `#root` will invoke React unless you unmount or replace that node first.
