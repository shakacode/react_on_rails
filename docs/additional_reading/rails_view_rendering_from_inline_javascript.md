# Using ReactOnRails in JavaScript
You can easily render React components in your JavaScript with `render` method that returns a [reference to the component](https://facebook.github.io/react/docs/more-about-refs.html) (virtual DOM element).

```js
/**
 * ReactOnRails.render("HelloWorldApp", {name: "Stranger"}, 'app');
 *
 * Does this:
 *   ReactDOM.render(React.createElement(HelloWorldApp, {name: "Stranger"}),
 *     document.getElementById('app'))
 *
 * @param name Name of your registered component
 * @param props Props to pass to your component
 * @param domNodeId
 * @returns {virtualDomElement} Reference to your component's backing instance
 */
ReactOnRails.render(componentName, props, elementId)
```

## Why do we need this?
Imagine that we have some event with jQuery, it allows us to set component state manually.

```html
<input id="input" type="range" min="0" max="100" />
<div id="root"></div>

<script>
  var input = $("#input");
  var component = ReactOnRails.render("componentName", { value: input.val() }, "root");

  input.on("change", function(e) {
    component.setState({ value: input.val() });
  });
</script>
```
