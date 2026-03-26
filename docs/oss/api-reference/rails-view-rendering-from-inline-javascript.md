# Using ReactOnRails in JavaScript

You can easily render React components in your JavaScript with `render` method. Under React 18+, it returns a React root. Under React 16/17, it returns the rendered component instance.

```js
/**
 * ReactOnRails.render("HelloWorldApp", {name: "Stranger"}, 'app');
 *
 * Does this:
 *   ReactDOM.render(React.createElement(HelloWorldApp, {name: "Stranger"}),
 *     document.getElementById('app'))
 *
 * Under React 18+, the return value is a React root. Under React 16/17, it is the rendered
 * component instance (or null for stateless components).
 *
 * @param name Name of your registered component
 * @param props Props to pass to your component
 * @param domNodeId
 * @param hydrate [optional] Pass truthy to update server rendered html. Default is falsy
 * @returns {Root|ReactComponent|ReactElement} React root in React 18+ or a legacy component
 *   instance in React 16/17
 */
ReactOnRails.render(componentName, props, domNodeId);
```

## Why do we need this?

Imagine that we have some event with jQuery and need to re-render with updated props.

```html
<input id="input" type="range" min="0" max="100" />
<div id="root"></div>

<script>
  var input = $('#input');

  function renderComponent() {
    return ReactOnRails.render('componentName', { value: input.val() }, 'root');
  }

  renderComponent();

  input.on('change', function (e) {
    renderComponent();
  });
</script>
```
