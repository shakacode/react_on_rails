# Getting Started with an existing Rails app

**Also consult the instructions for installing on a fresh Rails app**, see the [React on Rails Basic Tutorial](https://www.shakacode.com/react-on-rails/docs/guides/tutorial).

**If you have rails-5 API only project**, first [convert the rails-5 API only app to rails app](https://www.shakacode.com/react-on-rails/docs/rails/convert-rails-5-api-only-app-to-rails-app).

1. Add the following to your Gemfile and `bundle install`. We recommend fixing the version of React on Rails, as you will need to keep the exact version in sync with the version in your `package.json` file.

   ```ruby
   gem "react_on_rails", "12.0.0" # Update to the current version
   gem "webpacker", "~> 5"
   ```

1. Add the webpacker and react_on_rails gems
_Use the latest version for react_on_rails._

```
bundle add webpacker                 
bundle add react_on_rails --version=12.0.4 --strict
```

2. Run the following 2 commands to install Webpacker with React. Note, if you are using an older version of Rails than 5.1, you'll need to install webpacker with React per the instructions [here](https://github.com/rails/webpacker).

   ```bash
   bundle exec rails webpacker:install
   bundle exec rails webpacker:install:react
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

See the [Installation Overview](https://www.shakacode.com/react-on-rails/docs/additional-details/manual-installation-overview) for a concise set summary of what's in a React on Rails installation.


## NPM

All JavaScript in React On Rails is loaded from npm: [react-on-rails](https://www.npmjs.com/package/react-on-rails). To manually install this (you did not use the generator), assuming you have a standard configuration, run this command (assuming you are in the directory where you have your `node_modules`):

```bash
$ yarn add react-on-rails --exact
```

That will install the latest version and update your package.json. **NOTE:** the `--exact` flag will ensure that you do not have a "~" or "^" for your react-on-rails version in your package.json.
