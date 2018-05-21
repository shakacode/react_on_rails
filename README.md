# ReactOnRails

[![License](https://img.shields.io/badge/license-mit-green.svg)](docs/LICENSE.md) [![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails) [![Codeship Status for shakacode/react_on_rails](https://app.codeship.com/projects/cec6c040-971f-0134-488f-0a5146246bd8/status?branch=master)](https://app.codeship.com/projects/187011) [![Dependency Status](https://gemnasium.com/shakacode/react_on_rails.svg)](https://gemnasium.com/shakacode/react_on_rails) [![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Code Climate](https://codeclimate.com/github/shakacode/react_on_rails/badges/gpa.svg)](https://codeclimate.com/github/shakacode/react_on_rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master)

React on Rails integrates Facebook's [React](https://github.com/facebook/react) front-end framework with Rails. React v0.14.x and greater is supported, with server rendering. [Redux](https://github.com/reactjs/redux) and [React-Router](https://github.com/reactjs/react-router) are supported as well, also with server rendering, using **execJS**.

#### Project Objective

To provide an opinionated and optimal framework for integrating Ruby on Rails with React via the [**Webpacker**](https://github.com/rails/webpacker) gem.

#### Features

Like the [react-rails](https://github.com/reactjs/react-rails) gem, React on Rails is capable of server-side rendering with fragment caching and is compatible with [turbolinks](https://github.com/turbolinks/turbolinks). While the initial setup is slightly more involved, it allows for advanced functionality such as:

- [Redux](https://github.com/reactjs/redux)
- [Webpack optimization functionality](https://github.com/webpack/docs/wiki/optimization)
- [React Router](https://github.com/reactjs/react-router)

See the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) for an example of a live implementation and code.

#### How it Works

Check our [docs](docs/basics/HOW_IT_WORKS.md) to see how it works.

#### Why React on Rails?

Given that Webpacker already provides React integration, why would you use "React on Rails"? Additional features of React on Rails include:

1. Server rendering, often for SEO optimization.
2. Easy passing of props directly from your Rails view to your React components rather than having your Rails view load and then make a separate request to your API.
3. Redux and React-Router integration
4. Localization support
5. Rspec test helpers to ensure your Webpack bundles are ready for tests
6. A supportive community

#### Support

The ability to use a standalone Node Rendering server for better performance and tooling is supported for React on Rails Pro.

Contact [justin@shakacode.com](mailto:justin@shakacode.com) for more information.

## Getting Started

If you have an existing Rails app, please follow the instructions in [this guide](docs/basics/getting-started-existing.md).

### Prerequisites

* Rails 5.13+
  * If you are using an older version of Rails, you'll need to install webpacker with React per the instructions [here](https://github.com/rails/webpacker).
* Ruby 2.1+
* Node 5.5+

### Installation

1. Create a new Rails app:

   ``````bash
   $ rails new my-app --webpack=react
   $ cd my-app
   ``````

2. Add `react_on_rails` gem to Gemfile:

   ```ruby
   gem 'react_on_rails', '11.0.0' # Use the exact gem version to match npm version
   ```

3. Install the `react_on_rails` gem:

   ```bash
   $ bundle install
   ```

4. Commit this to git (or else you cannot run the generator unless you pass the option `--ignore-warnings`).

5. Run the generator:

   ```bash
   $ rails generate react_on_rails:install
   ```

6. Start the app:

   ```bash
   $ rails s
   ```

7. Visit http://localhost:3000/hello_world.

## Usage

### Demos

- [www.reactrails.com](http://www.reactrails.com) with the source at [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/).

- [spec app](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy): Great simple examples used for our tests.

  ```bash
  $ cd spec/dummy
  $ bundle && yarn
  $ foreman start
  ```

### Server Rendering

#### Turn on server rendering

1. Edit `app/views/hello_world/index.html.erb` and set `prerender` to `true`.
2. Refresh the page.

This is the line where you turn server rendering on by setting prerender to true:

```erb
<%= react_component("HelloWorld", props: @hello_world_props, prerender: false) %>
```

For more information on view helpers check our [View Helpers API](docs/api/view-helpers-api.md).

#### Integration with Node.js for Server Rendering

If you want to use a node server for server rendering, [get in touch](mailto:justin@shakacode.com). ShakaCode has built a premium Node rendering server for React on Rails.

### Webpack

Check out our [Webpack Configuration Guide](docs/basics/webpack-configuration.md) for more information.

### Caching and Performance

Consider fragment and http caching of pages that contain React on Rails components. See [Caching and Performance](docs/additional-reading/caching-and-performance.md) for more details.

### React Router

[React Router](https://github.com/reactjs/react-router) is supported, including server-side rendering! See:

1. [React on Rails docs for react-router](docs/additional-reading/react-router.md)
2. Examples in [spec/dummy/app/views/react_router](./spec/dummy/app/views/react_router) and follow to the JavaScript code in the [spec/dummy/client/app/startup/ServerRouterApp.jsx](spec/dummy/client/app/startup/ServerRouterApp.jsx).
3. [Code Splitting docs](docs/additional-reading/code-splitting.md) for information about how to set up code splitting for server rendered routes.



### Deployment

Check out our [Deployment Guide](docs/basics/deployment.md).



## Support

### Need Help with Rails + Webpack + React? Want better performance?

Aloha, I'm Justin Gordon the creator and maintainer of React on Rails. I offer a React on Rails **Pro Support Plan**, and I can help you with:

- Optimizing your webpack setup for React on Rails.
- Upgrading from older React on Rails to newer versions.
- Better performance client and server side.
- Migrating from Angular to React.
- Best practices based on 4 years of React on Rails experience.
- Early access to the React on Rails Pro Gem and Node code, including:
  - ShakaCode's Node.js rendering server for better performance for server rendering (used now at egghead.io).
  - Performance helpers, especially for server rendering
  - Webpack configuration examples

Please email me for a free half-hour project consultation, on anything from React on Rails to any aspect of web development.

### Testimonials

Check our [testimonials](docs/TESTIMONIALS.md).

## Additional Documentation

Please check our [docs](docs/index.md) for additional information or our [articles section](docs/ARTICLES.md).

## Community Resources

Please [**click to subscribe**](https://app.mailerlite.com/webforms/landing/l1d9x5) to keep in touch with Justin Gordon and [ShakaCode](http://www.shakacode.com/). I intend to send announcements of new releases of React on Rails and of our latest [blog articles](https://blog.shakacode.com) and tutorials. Subscribers will also have access to **exclusive content**, including tips and examples.

[![2017-01-31_14-16-56](https://cloud.githubusercontent.com/assets/1118459/22490211/f7a70418-e7bf-11e6-9bef-b3ccd715dbf8.png)](https://app.mailerlite.com/webforms/landing/l1d9x5)

- **Slack Room**: [Contact us](mailto:contact@shakacode.com) for an invite to the ShakaCode Slack room! Let us know if you want to contribute.
- **[forum.shakacode.com](https://forum.shakacode.com)**: Post your questions
- **[@railsonmaui on Twitter](https://twitter.com/railsonmaui)**
- For a live, [open source](https://github.com/shakacode/react-webpack-rails-tutorial), example of this gem, see [www.reactrails.com](http://www.reactrails.com).
- See [Projects](PROJECTS.md) using and [KUDOS](./KUDOS.md) for React on Rails. Please submit yours! Please edit either page or [email us](mailto:contact@shakacode.com) and we'll add your info. We also **love stars** as it helps us attract new users and contributors.
- *See [NEWS.md](NEWS.md) for more notes over time.*

##Contributing

Bug reports and pull requests are welcome. This project is intended to be a welcoming space for collaboration, and contributors are expected to adhere to our version of the [Contributor Covenant Code of Conduct](docs/misc/code_of_conduct.md)).

See [Contributing](CONTRIBUTING.md) to get started. See [contribution help wanted](https://github.com/shakacode/react_on_rails/labels/contributions%3A%20up%20for%20grabs%21).

## Credits

The following companies support open source, and ShakaCode uses their products!

- [JetBrains](https://www.jetbrains.com/)
- [![2017-02-21_22-35-32](https://cloud.githubusercontent.com/assets/1118459/23203304/1261e468-f886-11e6-819e-93b1a3f17da4.png)](https://www.browserstack.com)

*If you'd like to support React on Rails and have your company listed here, [get in touch](mailto:justin@shakacode.com).*

### Thank you from Justin Gordon and [ShakaCode](http://www.shakacode.com)

Thank you for considering using [React on Rails](https://github.com/shakacode/react_on_rails).

We at [ShakaCode](http://www.shakacode.com) are a small, boutique, remote-first application development company. We fund this project by:

- Providing priority support and training for anything related to React + Webpack + Rails in our [Pro Support program](http://www.shakacode.com/work/shakacode-pro-support.pdf).
- Building custom web and mobile (React Native) applications. We typically work with a technical founder or CTO and instantly provide a full development team including designers.
- Migrating **Angular** + Rails to React + Rails. You can see an example of React on Rails and our work converting Angular to React on Rails at [egghead.io](https://egghead.io/browse/frameworks).
- Augmenting your team to get your product completed more efficiently and quickly.

My article "[Why Hire ShakaCode?](https://blog.shakacode.com/can-shakacode-help-you-4a5b1e5a8a63#.jex6tg9w9)" provides additional details about our projects.

If any of this resonates with you, please email me, [justin@shakacode.com](mailto:justin@shakacode.com). I offer a free half-hour project consultation, on anything from React on Rails to any aspect of web or mobile application development for both consumer and enterprise products.

We are **[currently looking to hire](http://www.shakacode.com/about/#work-with-us)** like-minded developers that wish to work on our projects, including [Hawaii Chee](https://www.hawaiichee.com).

Aloha and best wishes from Justin and the ShakaCode team!

## Error Handling
* All errors from ReactOnRails will be of type ReactOnRails::Error.
* Prerendering (server rendering) errors get context information for HoneyBadger and Sentry for easier debugging.

## Caching and Performance
Consider fragment and http caching of pages that contain React on Rails components. See [Caching and Performance](./docs/additional-reading/caching-and-performance.md) for more details.

## Authors

[The Shaka Code team!](http://www.shakacode.com/about/)

The origins of the project began with the need to do a rich JavaScript interface for a ShakaCode's client. The choice to use Webpack and Rails is described in [Fast Rich Client Rails Development With Webpack and the ES6 Transpiler](http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/).

The gem project started with [Justin Gordon](https://github.com/justin808/) pairing with [Samnang Chhun](https://github.com/samnang) to figure out how to do server rendering with Webpack plus Rails. [Alex Fedoseev](https://github.com/alexfedoseev) then joined in. [Rob Wise](https://github.com/robwise), [Aaron Van Bokhoven](https://github.com/aaronvb), and [Andy Wang](https://github.com/yorzi) did the bulk of the generators. Many others have [contributed](https://github.com/shakacode/react_on_rails/graphs/contributors).

The gem was initially inspired by the [react-rails gem](https://github.com/reactjs/react-rails).

## License

The gem is available as open source under the terms of the [MIT License](docs/LICENSE.md).