Because the renderer communicates over a port to the server, you can start a renderer instance in this repo and hack on it.

# Yalc vs Yarn Link

The project is setup to use [yalc](https://github.com/whitecolor/yalc). This means that at the top level
directory, `yalc publish` will send the node package files to the global yalc store. Running `yarn` in the
`/spec/dummy/client` directory will copy the files from the global yalc store over to the local `node_modules`
directory.

# Debugging the Node Renderer

1. cd to the top level of the project.
1. `yarn` to install any libraries.
1. To compile renderer files on changes, open console and run `yarn build:dev`.
1. Open another console tab and run `RENDERER_LOG_LEVEL=debug yarn start`
1. Reload the browser page that causes the renderer issue. You can then update the JS code, and restart the `yarn start` to run the renderer with the new code.
1. Be sure to restart the rails server if you change any ruby code in loaded gems.
1. Note, the default setup for spec/dummy to reference the pro renderer is to use yalc, which may or may not be using a link, which means that you have to re-run yarn to get the files updated when changing the renderer.
1. Check out the top level nps task `nps renderer.debug` and `spec/dummy/package.json` which has script `"node-renderer-debug"`.

## Debugging using the Node debugger

1. See [this article](https://github.com/shakacode/react_on_rails/issues/1196) on setting up the debugger.

## Debugging Jest tests

1. See [the Jest documentation](https://jestjs.io/docs/troubleshooting) for overall guidance.
2. For RubyMine, see [the RubyMine documentation](https://www.jetbrains.com/help/ruby/running-unit-tests-on-jest.html) for the current information. The original [Testing With Jest in WebStorm](https://blog.jetbrains.com/webstorm/2018/10/testing-with-jest-in-webstorm/) post can be useful as well.

# Debugging the Ruby gem

Open the gemfile in the problematic app.

```ruby
gem "react_on_rails_pro", path: "../../../shakacode/react-on-rails/react_on_rails_pro"
```

Optionally, also specify react_on_rails to be local:

```ruby
gem "react_on_rails", path: "../../../shakacode/react-on-rails/react_on_rails"
```
