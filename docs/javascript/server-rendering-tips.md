# Server Rendering Tips

For the best performance with Server Rendering, consider using [React on Rails Pro]

## General Tips

- Your code can't reference `document`. Server-side JS execution does not have access to `document`,
  so jQuery and some other libraries won't work in this environment. You can debug this by putting in
  `console.log` statements in your code.
- You can conditionally avoid running code that references document by either checking if `window`
  is defined or using the "railsContext"
  in your top-level React component. Since the Hash passed in `props` from the view helper applies to
  both client- and server-side code, the best way to do this is to use a Render-Function.
- If you're serious about server-side rendering, it's worth the effort to have different entry points for client-side and server-side rendering. It's worth the extra complexity. The point is that you have separate files for top-level client and server side, and you pass some extra option indicating that rendering is happening server-side.
- You can enable Node.js server rendering via [React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki).

## Troubleshooting Server Rendering

1. First make sure your code works with server rendering disabled (`prerender: false`).
2. Set `config.trace` to true. You will get the server invocation code that renders your component. If you're not using Shakapacker, you will also get the whole file used to set up the JavaScript context.

## CSS

Server bundles must always have CSS extracted.

## setTimeout, setInterval, and clearTimeout

These methods are polyfilled for server rendering to be no-ops. We log calls to these when in `trace` mode. In the past, some libraries, namely babel-polyfill, did call `setTimeout`.

Here's an example of this, showing the line numbers that end up calling `setTimeout`:

```text
➜  ~/shakacode/react_on_rails/gen-examples/examples/basic-server-rendering (add-rails-helper-to-generator u=) ✗ export SERVER_TRACE_REACT_ON_RAILS=TRUE
➜  ~/shakacode/react_on_rails/gen-examples/examples/basic-server-rendering (add-rails-helper-to-generator u=) ✗ rspec
Hello World
Building Webpack client-rendering assets...
Completed building Webpack client-rendering assets.
ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
react_renderer.rb: 92
wrote file tmp/server-generated.js
ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
react_renderer.rb: 92
wrote file tmp/base_js_code.js
ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
[SERVER] setTimeout is not defined for execJS. See https://github.com/sstephenson/execjs#faq. Note babel-polyfill will call this.
[SERVER] at setTimeout (<eval>:31:17)
at defer (<eval>:4422:8)
at setImmediate (<eval>:4387:6)
at notify (<eval>:4481:16)
at module.exports (<eval>:4490:6)
at notify (<eval>:4081:4)
at Promise.$resolve (<eval>:4189:8)
at <eval>:793:18
at Function.resolve (<eval>:4265:6)
  the hello world example works
```
