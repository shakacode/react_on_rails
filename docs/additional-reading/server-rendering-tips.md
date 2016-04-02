# Server Rendering Tips

## General Tips
- Your code can't reference `document`. Server side JS execution does not have access to `document`, so jQuery and some
  other libs won't work in this environment. You can debug this by putting in `console.log`
  statements in your code.
- You can conditionally avoid running code that references document by passing in a boolean prop to your top level react
  component. Since the passed in props Hash from the view helper applies to client and server side code, the best way to
  do this is to use a generator function.
- If you're serious about server rendering, it's worth the effort to have different entry points for client and server rendering. It's worth the extra complexity.

The point is that you have separate files for top level client or server side, and you pass some extra option indicating that rendering is happening server side.

## Troubleshooting Server Rendering

1. First be sure your code works with server rendering disabled (`prerender: false`)
2. `export TRACE_REACT_ON_RAILS=YES` Turn this on to get both the invocation code for you component, as well as the whole file used to setup the JavaScript context.

## setTimeout and setInterval

These methods are polyfilled for server rendering to be no-ops. We don't log calls to these by default as some libraries, namely babel-polyfill, will call setTimout. If you wish to log calls to setTimeout and setInterval, set the ENV value: `export TRACE_REACT_ON_RAILS=YES`.

Here's an example of this which shows the line numbers that end up calling setTimeout:
```
➜  ~/shakacode/react_on_rails/gen-examples/examples/basic-server-rendering (add-rails-helper-to-generator u=) ✗ export TRACE_REACT_ON_RAILS=YES
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
