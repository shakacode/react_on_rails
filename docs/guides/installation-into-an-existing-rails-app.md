# Getting Started with an existing Rails app

**Also consult the instructions for installing on a fresh Rails app**, see the [React on Rails Basic Tutorial](https://www.shakacode.com/react-on-rails/docs/guides/tutorial/).

**If you have rails-5 API only project**, first [convert the rails-5 API only app to rails app](https://www.shakacode.com/react-on-rails/docs/rails/convert-rails-5-api-only-app-to-rails-app/).

1. Add the following to your Gemfile and `bundle install`. We recommend fixing the version of React on Rails, as you will need to keep the exact version in sync with the version in your `package.json` file.

   ```ruby
   gem "react_on_rails", "13.3.1" # Use the latest and the exact version
   gem "shakapacker", "6.5.5"
   ```

   Or use `bundle add`:

   ```bash
   bundle add react_on_rails --version=13.3.1 --strict
   bundle add shakapacker --version=6.5.5 --strict
   ```

2. Run the following 2 commands to install Shakapakcer (Webpacker) with React. Note, if you are using an older version of Rails than 5.1, you'll need to install webpacker with React per the instructions [here](https://github.com/rails/webpacker).

   ```bash
   rails webpacker:install
   ```

3. Commit this to git (or else you cannot run the generator unless you pass the option `--ignore-warnings`).

4. Run the generator with a simple "Hello World" example (more options below):

   ```bash
   rails generate react_on_rails:install
   ```

   For more information about this generator use `--help` option:

   ```bash
   rails generate react_on_rails:install --help
   ```
5. Ensure that you have `overmind` or `foreman` installed.

   Note: `foreman` should be installed on the system not on your project. [Read more](https://github.com/ddollar/foreman/wiki/Don't-Bundle-Foreman)

6. Start your Rails server:

   ```bash
   ./bin/dev
   ```
   Note: `foreman` defaults to PORT 5000 unless you set the value of PORT in your environment. For example, you can `export PORT=3000` to use the Rails default port of 3000. For the hello_world example, this is already set.

7. Visit [localhost:3000/hello_world](http://localhost:3000/hello_world).

## Installation

See the [Installation Overview](https://www.shakacode.com/react-on-rails/docs/additional-details/manual-installation-overview/) for a concise set summary of what's in a React on Rails installation.


## NPM

All JavaScript in React On Rails is loaded from npm: [react-on-rails](https://www.npmjs.com/package/react-on-rails). To manually install this (you did not use the generator), assuming you have a standard configuration, run this command (assuming you are in the directory where you have your `node_modules`):

```bash
yarn add react-on-rails --exact
```

That will install the latest version and update your package.json. **NOTE:** the `--exact` flag will ensure that you do not have a "~" or "^" for your react-on-rails version in your package.json.
