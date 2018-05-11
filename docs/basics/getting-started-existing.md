# Getting Started with an existing Rails app

**For more detailed instructions on a fresh Rails app**, see the [React on Rails Basic Tutorial](../../docs/tutorial.md).

**If you have rails-5 API only project**, first [convert the rails-5 API only app to rails app](#convert-rails-5-api-only-app-to-rails-app) before [getting started](#getting-started-with-an-existing-rails-app).

1. Add the following to your Gemfile and `bundle install`. We recommend fixing the version of React on Rails, as you will need to keep the exact version in sync with the version in your `client/package.json` file.

   ```ruby
   gem "react_on_rails", "11.0.0"
   gem "webpacker", "~> 3.0"
   ```

2. Run the following 2 commands to install Webpacker with React:

   ```bash
   $ bundle exec rails webpacker:install
   $ bundle exec rails webpacker:install:react
   ```

3. Commit this to git (or else you cannot run the generator unless you pass the option `--ignore-warnings`).

4. See help for the generator:

   ```bash
   $ rails generate react_on_rails:install --help
   ```

5. Run the generator with a simple "Hello World" example (more options below):

   ```bash
   $ rails generate react_on_rails:install
   ```

6. Ensure that you have `foreman` installed: `gem install foreman`.

7. Start your Rails server:

   ```bash
   $ foreman start -f Procfile.dev
   ```

8. Visit [localhost:3000/hello_world](http://localhost:3000/hello_world). Note: `foreman` defaults to PORT 5000 unless you set the value of PORT in your environment. For example, you can `export PORT=3000` to use the Rails default port of 3000. For the hello_world example this is already set.

## Installation

See the [Installation Overview](../../docs/basics/installation-overview.md) for a concise set summary of what's in a React on Rails installation.

### Initializer Configuration

Configure the file `config/initializers/react_on_rails.rb`. You can adjust some necessary settings and defaults. See file [docs/basics/configuration.md](../../docs/basics/configuration.md) for documentation of all configuration options.

## Including your React Component in your Rails Views

- *Normal Mode (React component will be rendered on client):*

  ```erb
  <%= react_component("HelloWorld", props: @some_props) %>
  ```

- *Server-Side Rendering (React component is first rendered into HTML on the server):*

  ```erb
  <%= react_component("HelloWorld", props: @some_props, prerender: true) %>
  ```

- The `component_name` parameter is a string matching the name you used to expose your React component globally. So, in the above examples, if you had a React component named "HelloWorld", you would register it with the following lines:

  ```js
  import ReactOnRails from 'react-on-rails';
  import HelloWorld from './HelloWorld';
  ReactOnRails.register({ HelloWorld });
  ```

  Exposing your component in this way is how React on Rails is able to reference your component from a Rails view. You can expose as many components as you like, as long as their names do not collide. See below for the details of how you expose your components via the react_on_rails webpack configuration.

- `@some_props` can be either a hash or JSON string. This is an optional argument assuming you do not need to pass any options (if you want to pass options, such as `prerender: true`, but you do not want to pass any properties, simply pass an empty hash `{}`). This will make the data available in your component:

  ```ruby
    # Rails View
    <%= react_component("HelloWorld", props: { name: "Stranger" }) %>
  ```

  ```javascript
    // inside your React component
    this.props.name // "Stranger"
  ```

## I18n

You can enable the i18n functionality with [react-intl](https://github.com/yahoo/react-intl).

React on Rails provides an option for automatic conversions of Rails `*.yml` locale files into `*.js` files for `react-intl`.

See the [How to add I18n](../../docs/basics/i18n.md) for a summary of adding I18n.

## Convert rails-5 API only app to rails app

1. Go to the directory where you created your app

```bash
$ rails new your-current-app-name
```

Rails will start creating the app and will skip the files you have already created. If there is some conflict then it will stop and you need to resolve it manually. be careful at this step as it might replace you current code in conflicted files.

2. Resolve conflicts

```
1. Press "d" to see the difference
2. If it is only adding lines then press "y" to continue
3. If it is removeing some of your code then press "n" and add all additions manually
```

3. Run `bundle install` and follow [Getting started](#getting-started-with-an-existing-rails-app)

## NPM

All JavaScript in React On Rails is loaded from npm: [react-on-rails](https://www.npmjs.com/package/react-on-rails). To manually install this (you did not use the generator), assuming you have a standard configuration, run this command (assuming you are in the directory where you have your `node_modules`):

```bash
$ yarn add react-on-rails --exact
```

That will install the latest version and update your package.json. **NOTE:** the `--exact` flag will ensure that you do not have a "~" or "^" for your react-on-rails version in your package.json.

## Webpacker Configuration

React on Rails users should set configuration value `compile` to false, as React on Rails handles compilation for test and production environments.

