Because the renderer communicates over a port to the server, you can start a renderer instance in this repo and hack on it.

# Debugging the VM Renderer
1. cd to the top level of the project.
1. `yarn` to install any libraries.
1. To compile renderer files on changes, open console and run `yarn build-watch`.
1. Open another console tab and run `RENDERER_LOG_LEVEL=debug yarn start`
1. Reload the browser page that causes the renderer issue. You can then update the JS code, and restart the `yarn start` to run the renderer with the new code.
1. Be sure to restart the rails server if you change any ruby code in loaded gems.

# Debugging the Ruby gem

Open the gemfile in the problematic app.

```ruby
gem "react_on_rails_pro", path: "../../../shakacode/react-on-rails/react_on_rails_pro"
```

Optionally, also specify react_on_rails to be local:

```ruby
gem "react_on_rails", path: "../../../shakacode/react-on-rails/react_on_rails"
```
