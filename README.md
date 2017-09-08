[![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails) [![Codeship Status for shakacode/react_on_rails](https://app.codeship.com/projects/cec6c040-971f-0134-488f-0a5146246bd8/status?branch=master)](https://app.codeship.com/projects/187011) [![Dependency Status](https://gemnasium.com/shakacode/react_on_rails.svg)](https://gemnasium.com/shakacode/react_on_rails) [![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Code Climate](https://codeclimate.com/github/shakacode/react_on_rails/badges/gpa.svg)](https://codeclimate.com/github/shakacode/react_on_rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master)

*If this projects helps you, please give us a star!*

[rails/webpacker](https://github.com/rails/webpacker) just shipped 3.0. This now enables me to ship version 9.0. See [PR #908](https://github.com/shakacode/react_on_rails/pull/908) for more details.

# React on Rails v9 is based on Webpacker 3.0!

* See the updated [Tutorial](https://github.com/shakacode/react_on_rails/blob/master/docs/tutorial.md).
* See the [CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md) for migration instructions. 

## Steps to a New App with rails/webpacker v3 plus React on Rails v9.beta:
First be sure to run `rails -v` and check that you are using Rails 5.1.3 or above. If you are using an older version of Rails, you'll need to install webpacker with React per the instructions [here](https://github.com/rails/webpacker).

### Basic installation

1. New Rails app: `rails new my-app --webpack=react`. `cd` into the directory.
2. Add beta gem version: `gem 'react_on_rails', '~> 9.0.0.beta.12'`
3. Run the generator: `rails generate react_on_rails:install`
4. Start the app: `foreman start -f Procfile.dev`
5. Visit http://localhost:3000/hello_world

### Turn on HMR (Hot reloading)

1. Edit `config/webpacker.yml` and set `hmr: true`
2. Start the app: `foreman start -f Procfile.dev-server`
3. Visit http://localhost:3000/hello_world
4. Edit `app/javascript/bundles/HelloWorld/components/HelloWorld.jsx`, hit save, and see the screen update.

### Turn on server rendering

*Does not work with hot reloading, yet, per [Webpacker issue #732](https://github.com/rails/webpacker/issues/732)*

1. Edit `app/views/hello_world/index.html.erb` and set `prerender` to `true`.
2. Refresh the page.

This is the line where you turn server rendering on by setting prerender to true:

```
<%%= react_component("HelloWorld", props: @hello_world_props, prerender: false) %>
```

---------------

## Thank you from Justin Gordon and [ShakaCode](http://www.shakacode.com)

Thank you for considering using [React on Rails](https://github.com/shakacode/react_on_rails).

* **Video:** [Front-End Sadness to Happiness: The React on Rails Story](https://www.youtube.com/watch?v=SGkTvKRPYrk): History, motivations, philosophy, and overview.
* [Front-End Sadness to Happiness: The React on Rails Story at GORUCO 2017](https://blog.shakacode.com/front-end-sadness-to-happiness-the-react-on-rails-story-at-goruco-2017-d63b8fd26ca4)

We at [ShakaCode](http://www.shakacode.com) are a small, boutique, remote-first application development company. We fund this project by:

* Providing priority support and training for anything related to React + Webpack + Rails in our [Coaching Program](http://www.shakacode.com/work/shakacode-coaching-plan.pdf).
* Building custom web and mobile (React Native) applications. We typically work with a technical founder or CTO and instantly provide a full development team including designers.
* Migrating **Angular** + Rails to React + Rails. You can see an example of React on Rails and our work converting Angular to React on Rails at [egghead.io](https://egghead.io/browse/frameworks).
* Augmenting your team to get your product completed more efficiently and quickly.

My article "[Why Hire ShakaCode?](https://blog.shakacode.com/can-shakacode-help-you-4a5b1e5a8a63#.jex6tg9w9)" provides additional details about our projects.

If any of this resonates with you, please email me, [justin@shakacode.com](mailto:justin@shakacode.com). I offer a free half-hour project consultation, on anything from React on Rails to any aspect of web or mobile application development for both consumer and enterprise products.

We are **[currently looking to hire](http://www.shakacode.com/about/#work-with-us)** like-minded developers that wish to work on our projects, including [Friends and Guests](https://www.friendsandguests.com).

I appreciate your attention and sharing of these offerings with anybody that we can help. Your support allows me to bring you and your team [front-end happiness in the Rails world](https://www.youtube.com/watch?v=SGkTvKRPYrk).

Aloha and best wishes from the ShakaCode team!

------

# Community
Please [**click to subscribe**](https://app.mailerlite.com/webforms/landing/l1d9x5) to keep in touch with Justin Gordon and [ShakaCode](http://www.shakacode.com/). I intend to send announcements of new releases of React on Rails and of our latest [blog articles](https://blog.shakacode.com) and tutorials. Subscribers will also have access to **exclusive content**, including tips and examples.

[![2017-01-31_14-16-56](https://cloud.githubusercontent.com/assets/1118459/22490211/f7a70418-e7bf-11e6-9bef-b3ccd715dbf8.png)](https://app.mailerlite.com/webforms/landing/l1d9x5)

* **Slack Room**: [Contact us](mailto:contact@shakacode.com) for an invite to the ShakaCode Slack room! Let us know if you want to contribute.
* **[forum.shakacode.com](https://forum.shakacode.com)**: Post your questions
* **[@ShakaCode on Twitter](https://twitter.com/shakacode)**
* For a live, [open source](https://github.com/shakacode/react-webpack-rails-tutorial), example of this gem, see [www.reactrails.com](http://www.reactrails.com).

------

# Testimonials
From Joel Hooks, Co-Founder, Chief Nerd at [egghead.io](https://egghead.io/), January 30, 2017:

![2017-01-30_11-33-59](https://cloud.githubusercontent.com/assets/1118459/22443635/b3549fb4-e6e3-11e6-8ea2-6f589dc93ed3.png)

For more testimonials, see [Live Projects](PROJECTS.md) and [Kudos](./KUDOS.md).

-------

# Articles, Videos, and Podcasts

### Articles

* [Front-End Sadness to Happiness: The React on Rails Story at GORUCO 2017](https://blog.shakacode.com/front-end-sadness-to-happiness-the-react-on-rails-story-at-goruco-2017-d63b8fd26ca4)
* [Webpacker Lite: Why Fork Webpacker?](https://blog.shakacode.com/webpacker-lite-why-fork-webpacker-f0a7707fac92)
* [React on Rails, 2000+ 🌟 Stars](https://medium.com/shakacode/react-on-rails-2000-stars-32ff5cfacfbf#.6gmfb2gpy)
* [The React on Rails Doctrine](https://medium.com/@railsonmaui/the-react-on-rails-doctrine-3c59a778c724)

### Videos
1. [GORUCO 2017: Front-End Sadness to Happiness: The React on Rails Story by Justin Gordon](https://www.youtube.com/watch?v=SGkTvKRPYrk)
1. [egghead.io: Creating a component with React on Rails](https://egghead.io/lessons/react-creating-a-component-with-react-on-rails)
1. [egghead.io: Creating a redux component with React on Rails](https://egghead.io/lessons/react-add-redux-state-management-to-a-react-on-rails-project)
1. [React On Rails Tutorial Series](https://www.youtube.com/playlist?list=PL5VAKH-U1M6dj84BApfUtvBjvF-0-JfEU)
  1. [History and Motivation](https://youtu.be/F4oymbUHvoY)
  1. [Basic Tutorial Walkthrough](https://youtu.be/_bjScw60FBk)
  1. [Code Walkthrough](https://youtu.be/McQ9UM-_ocQ)

### Podcasts
* [284 Ruby Rogues: React on Rails with Justin Gordon and Rob Wise](https://devchat.tv/ruby-rogues/284-rr-react-on-rails-with-justin-gordon-and-rob-wise)

------

# NEWS
* 2017-09-06: **VERSION 9.0.0 shipped!** This version depends on Webpacker directly. See the [CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md) for migration instructions.
* [VERSION 8.1.0](https://rubygems.org/gems/react_on_rails/) shipped with [webpacker_lite](https://github.com/shakacode/webpacker_lite) (soon [**webpacker**](https://github.com/rails/webpacker/issues/464#issuecomment-310986140) support! [react-webpack-rails-tutorial PR #395](https://github.com/shakacode/react-webpack-rails-tutorial/pull/395) shows the changes needed to migrate from the Asset Pipeline to Webpacker Lite. For more information, see my article: [Webpacker Lite: Why Fork Webpacker?](https://blog.shakacode.com/webpacker-lite-why-fork-webpacker-f0a7707fac92). Per recent discussions, we [will merge Webpacker Lite changes back into Webpacker](https://github.com/rails/webpacker/issues/464#issuecomment-310986140). There's no reason to wait for this. The upgrade will eventually be trivial.
* The Docs here on `master` refer to 9.x including support for [rails/webpacker](https://github.com/rails/webpacker).
*Use the [7.0.4 docs](https://github.com/shakacode/react_on_rails/tree/7.0.4) to refer to the older asset pipeline way.*
* *See [NEWS.md](NEWS.md) for more notes over time.*

------

# React on Rails

**Project Objective**: To provide an opinionated and optimal framework for integrating Ruby on Rails with modern JavaScript tooling and libraries, including [**Webpack**](http://webpack.github.io/), [**Babel**](https://babeljs.io/), [**React**](https://facebook.github.io/react/), [**Redux**](https://github.com/reactjs/redux), [**React-Router**](https://github.com/reactjs/react-router). This differs significantly from typical Rails architecture. When considering what goes into **react_on_rails**, we ask ourselves, is the functionality related to the intersection of using Rails and modern JavaScript? If so, then the functionality belongs right here. In other cases, we're releasing separate npm packages or Ruby gems. If you are interested in implementing React using traditional Rails architecture, see [react-rails](https://github.com/reactjs/react-rails).

React on Rails integrates Facebook's [React](https://github.com/facebook/react) front-end framework with Rails. React v0.14.x and greater is supported, with server rendering. [Redux](https://github.com/reactjs/redux) and [React-Router](https://github.com/reactjs/react-redux) are supported as well, also with server rendering, using **execJS**. See the Rails on Maui [blog post](http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/) that started it all!

## Table of Contents

+ [Features](#features)
+ [Why Webpack?](#why-webpack)
+ [Getting Started](#getting-started)
    - [Installation Overview](#installation-overview)
    - [Initializer Configuration: config/initializers/react_on_rails.rb](#initializer-configuration)
    - [Including your React Component in your Rails Views](#including-your-react-component-in-your-rails-views)
    - [I18n](#i18n)
+ [How it Works](#how-it-works)
    - [Client-Side Rendering vs. Server-Side Rendering](#client-side-rendering-vs-server-side-rendering)
    - [Building the Bundles](#building-the-bundles)
    - [Rails Context](#rails-context)
    - [Globally Exposing Your React Components](#globally-exposing-your-react-components)
    - [ReactOnRails View Helpers API](#reactonrails-view-helpers-api)
    - [ReactOnRails JavaScript API](#reactonrails-javascript-api)
    - [React-Router](#react-router)
    - [Deployment](#deployment)
+ [Integration with Node.js for Server Rendering](#user-content-integration-with-nodejs-for-server-rendering)
+ [Additional Documentation](#additional-documentation)
+ [Contributing](#contributing)
+ [License](#license)
+ [Authors](#authors)
+ [About ShakaCode](#about-shakacode)

---

## Features
Like the [react-rails](https://github.com/reactjs/react-rails) gem, React on Rails is capable of server-side rendering with fragment caching and is compatible with [turbolinks](https://github.com/turbolinks/turbolinks). Unlike react-rails, which depends heavily on sprockets and jquery-ujs, React on Rails uses [webpack](http://webpack.github.io/) and does not depend on jQuery. While the initial setup is slightly more involved, it allows for advanced functionality such as:

+ [Redux](https://github.com/reactjs/redux)
+ [Webpack optimization functionality](https://github.com/webpack/docs/wiki/optimization)
+ [React Router](https://github.com/reactjs/react-router)

See the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) for an example of a live implementation and code.

## Why Webpack?

Webpack is used to generate JavaScript and CSS "bundles" directly to your `/public` directory. [webpacker](https://github.com/rails/webpacker) provides view helpers to access the Webpack generated (and fingerprinted) JS and CSS. These files totally skip the Rails asset pipeline. You are responsible for properly processing your Webpack output via the Webpack config files.

This usage of webpack fits neatly and simply into existing Rails apps. You can include React components on a Rails view with a simple helper.

Compare this to some alternative approaches for SPAs (Single Page Apps) that utilize Webpack and Rails. They will use a separate node server to distribute web pages, JavaScript assets, CSS, etc., and will still use Rails as an API server. A good example of this is our ShakaCode team member Alex's article [
Universal React with Rails: Part I](https://medium.com/@alexfedoseev/isomorphic-react-with-rails-part-i-440754e82a59).

## Upgrade

To upgrade existing apps to React on Rails 8 see the [Installation Overview](docs/basics/installation-overview.md)

## Getting Started

**For more detailed instructions**, see the [React on Rails Basic Tutorial](docs/tutorial.md).

1. Add the following to your Gemfile and `bundle install`. We recommend fixing the version of React on Rails, as you will need to keep the exact version in sync with the version in your `client/package.json` file.

  ```ruby
  gem "react_on_rails", "9.0.0"
  gem "webpacker", "~> 3.0"
  ```

2. Run the following 2 commands to install Webpacker with React:
   ```
   bundle exec rails webpacker:install
   bundle exec rails webpacker:install:react
   
   ```

2. Commit this to git (or else you cannot run the generator unless you pass the option `--ignore-warnings`).

3. See help for the generator:

  ```bash
  rails generate react_on_rails:install --help
  ```

4. Run the generator with a simple "Hello World" example (more options below):

  ```bash
  rails generate react_on_rails:install
  ```

5. Ensure that you have `foreman` installed: `gem install foreman`.

7. Start your Rails server:

  ```bash
  foreman start -f Procfile.dev
  ```

8. Visit [localhost:3000/hello_world](http://localhost:3000/hello_world). Note, `foreman` defaults to PORT 5000 unless you set the value of PORT in your environment. For example, you can `export PORT=3000` to use the Rails default port of 3000. For the hello_world example this is already set.

### Installation Overview

See the [Installation Overview](docs/basics/installation-overview.md) for a concise set summary of what's in a React on Rails installation.

### Initializer Configuration

Configure the `config/initializers/react_on_rails.rb`. You can adjust some necessary settings and defaults. See file [spec/dummy/config/initializers/react_on_rails.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb) for a detailed example of configuration, including comments on the different values to configure.

### Including your React Component in your Rails Views

+ *Normal Mode (React component will be rendered on client):*

  ```erb
  <%= react_component("HelloWorld", props: @some_props) %>
  ```
+ *Server-Side Rendering (React component is first rendered into HTML on the server):*

  ```erb
  <%= react_component("HelloWorld", props: @some_props, prerender: true) %>
  ```

+ The `component_name` parameter is a string matching the name you used to expose your React component globally. So, in the above examples, if you had a React component named "HelloWorld", you would register it with the following lines:

  ```js
  import ReactOnRails from 'react-on-rails';
  import HelloWorld from './HelloWorld';
  ReactOnRails.register({ HelloWorld });
  ```

  Exposing your component in this way is how React on Rails is able to reference your component from a Rails view. You can expose as many components as you like, as long as their names do not collide. See below for the details of how you expose your components via the react_on_rails webpack configuration.

+ `@some_props` can be either a hash or JSON string. This is an optional argument assuming you do not need to pass any options (if you want to pass options, such as `prerender: true`, but you do not want to pass any properties, simply pass an empty hash `{}`). This will make the data available in your component:

  ```ruby
    # Rails View
    <%= react_component("HelloWorld", props: { name: "Stranger" }) %>
  ```

  ```javascript
    // inside your React component
    this.props.name // "Stranger"
  ```

### I18n

You can enable the i18n functionality with [react-intl](https://github.com/yahoo/react-intl).

React on Rails provides an option for automatic conversions of Rails `*.yml` locale files into `*.js` files for `react-intl`.

See the [How to add I18n](docs/basics/i18n.md) for a summary of adding I18n.

## NPM
All JavaScript in React On Rails is loaded from npm: [react-on-rails](https://www.npmjs.com/package/react-on-rails). To manually install this (you did not use the generator), assuming you have a standard configuration, run this command:

```bash
cd client && yarn add react-on-rails
```

That will install the latest version and update your package.json.

## Webpacker Configuration

React on Rails users should set configuration value `compile` to false, as React on Rails handles compilation for test and production environments.


## How it Works
The generator installs your webpack files in the `client` folder. Foreman uses webpack to compile your code and output the bundled results to `app/assets/webpack`, which are then loaded by sprockets. These generated bundle files have been added to your `.gitignore` for your convenience.

Inside your Rails views, you can now use the `react_component` helper method provided by React on Rails. You can pass props directly to the react component helper. You can also initialize a Redux store with view or controller helper `redux_store` so that the store can be shared amongst multiple React components. See the docs for `redux_store` below and scan the code inside of the [/spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy) sample app.

### Client-Side Rendering vs. Server-Side Rendering
In most cases, you should use the `prerender: false` (default behavior) with the provided helper method to render the React component from your Rails views. In some cases, such as when SEO is vital, or many users will not have JavaScript enabled, you can enable server-rendering by passing `prerender: true` to your helper, or you can simply change the default in `config/initializers/react_on_rails`.

Now the server will interpret your JavaScript using [ExecJS](https://github.com/rails/execjs) and pass the resulting HTML to the client. We recommend using [mini_racer](https://github.com/discourse/mini_racer) as ExecJS's runtime. The generator will automatically add it to your Gemfile for you (once we complete [#501](https://github.com/shakacode/react_on_rails/issues/501)).

In the following screenshot you can see the 3 parts of React on Rails rendering:

1. A hidden HTML div contains the properties of the React component, such as the registered name and any props. A JavaScript function runs after the page loads to take this data and build initialize React components.
2. The wrapper div `<div id="HelloWorld-react-component-0">` specifies the div where to place the React rendering. It encloses the server-rendered HTML for the React component
3. Additional JavaScript is placed to console-log any messages, such as server rendering errors. Note, these server side logs can be configured only to be sent to the server logs.

**Note**:

* If server rendering is not used (prerender: false), then the major difference is that the HTML rendered for the React component only contains the outer div: `<div id="HelloWorld-react-component-0"/>`. The first specification of the React component is just the same.
* The below image is not yet updated for version 7.0.0 which uses a `<script>` tag for the props. Instead of a hidden div, we have the props inside of the `<script>` tag.

![Comparison of a normal React Component with its server-rendered version](https://cloud.githubusercontent.com/assets/1118459/12607542/a959d5c8-c48a-11e5-8187-2433d543ccaa.png)

### Building the Bundles
Each time you change your client code, you will need to re-generate the bundles (the webpack-created JavaScript files included in application.js). The included Foreman `Procfile.dev` will take care of this for you by watching your JavaScript code files for changes. Simply run `foreman start -f Procfile.dev`.

On production deployments that use asset precompilation, such as Heroku deployments, React on Rails, by default, will automatically run webpack to build your JavaScript bundles. You can see the source code for what gets added to your precompilation [here](https://github.com/shakacode/react_on_rails/tree/master/lib/tasks/assets.rake). For more information on this topic, see [the doc on Heroku deployment](./docs/additional-reading/heroku-deployment.md#more-details-on-precompilation-using-webpack-to-create-javascript-assets).

If you have used the provided generator, these bundles will automatically be added to your `.gitignore` to prevent extraneous noise from re-generated code in your pull requests. You will want to do this manually if you do not use the provided generator.


### Generator Functions
Why would you create a function that returns a React component rather than simply an Object that is a React class?

1. You need access to the `railsContext`. See documentation for the railsContext in terms of why you might need it. You **need** a generator function to access the `railsContext`.
1. You may want the ability to use the passed-in props to initialize a redux store or set up react-router
1. You may want to return different components depending on what's in the props.

ReactOnRails will automatically detect a registered generator function. Thus, there is no difference between registering a React Component versus a "generator function."

Another reason to use a generator function is that sometimes in server rendering, specifically with React Router, you need to return the result of calling ReactDOMServer.renderToString(element). You can do this by returning an object with the following shape: { renderedHtml, redirectLocation, error }.

For server rendering, if you wish to return multiple HTML strings from a generator function, you may return an Object from your generator function with a single top level property of `renderedHtml`. Inside this Object, place a key called `componentHtml`, along with any other needed keys. An example scenario of this is when you are using side effects libraries like [React Helmet](https://github.com/nfl/react-helmet). Your Ruby code will get this Object as a Hash containing keys componentHtml and any other custom keys that you added:
{ renderedHtml: { componentHtml, customKey1, customKey2} }

### Rails Context and Generator Functions
When you use a "generator function" to create react components (or renderedHtml on the server), or you used shared redux stores, you get two params passed to your function that creates a React component:

1. `props`: Props that you pass in the view helper of either `react_component` or `redux_store`
2. `railsContext`: Rails contextual information, such as the current pathname. You can customize this in your config file. **Note**: The `railsContext` is not related to the concept of a ["context" for React components](https://facebook.github.io/react/docs/context.html#how-to-use-context).

This parameters (`props` and `railsContext`) will be the same regardless of either client or server side rendering, except for the key `serverSide` based on whether or not you are server rendering.

While you could manually configure your Rails code to pass the "`railsContext` information" with the rest of your "props", the `railsContext` is a convenience because it's passed consistently to all invocations of generator functions.

For example, suppose you create a "generator function" called MyAppComponent.

```js
import React from 'react';
const MyAppComponent = (props, railsContext) => (
  <div>
    <p>props are: {JSON.stringify(props)}</p>
    <p>railsContext is: {JSON.stringify(railsContext)}
    </p>
  </div>
);
export default MyAppComponent;
```

*Note: you will get a React browser console warning if you try to serverRender this since the value of `serverSide` will be different for server rendering.*

So if you register your generator function `MyAppComponent`, it will get called like:

```js
reactComponent = MyAppComponent(props, railsContext);
```

and, similarly, any redux store always initialized with 2 parameters:

```js
reduxStore = MyReduxStore(props, railsContext);
```

Note, you never make these calls. React on Rails makes these calls when it does either client or server rendering. You will define functions that take these 2 params and return a React component or a Redux Store. Naturally, you do not have to use second parameter of the railsContext if you do not need it.

(Note, see below [section](#multiple-react-components-on-a-page-with-one-store) on how to setup redux stores that allow multiple components to talk to the same store.)

The `railsContext` has: (see implementation in file [react_on_rails_helper.rb](https://github.com/shakacode/react_on_rails/tree/master/app/helpers/react_on_rails_helper.rb), method `rails_context` for the definitive list).

```ruby
  {
    # URL settings
    href: request.original_url,
    location: "#{uri.path}#{uri.query.present? ? "?#{uri.query}": ""}",
    scheme: uri.scheme, # http
    host: uri.host, # foo.com
    port: uri.port,
    pathname: uri.path, # /posts
    search: uri.query, # id=30&limit=5

    # Other
    serverSide: boolean # Are we being called on the server or client? NOTE, if you conditionally
     # render something different on the server than the client, then React will only show the
     # server version!
  }
```

#### Why the railsContext is only passed to generator functions
There's no reason that the railsContext would ever get passed to your React component unless the value is explicitly put into the props used for rendering. If you create a react component, rather than a generator function, for use by React on Rails, then you get whatever props are passed in from the view helper, which **does not include the Rails Context**. It's trivial to wrap your component in a "generator function" to return a new component that takes both:

```js
import React from 'react';
import AppComponent from './AppComponent';
const AppComponentWithRailsContext = (props, railsContext) => (
  <AppComponent {...{...props, railsContext}}/>
)
export default AppComponentWithRailsContext;
```

Consider this line in depth:

```js
  <AppComponent {...{ ...props, railsContext }}/>
```

The outer `{...` is for the [JSX spread operator for attributes](https://facebook.github.io/react/docs/jsx-in-depth.html#spread-attributes) and the innner `{...` is for the [Spread in object literals](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_operator#Spread_in_object_literals).

#### Use Cases
##### Needing the current URL path for server rendering
Suppose you want to display a nav bar with the current navigation link highlighted by the URL. When you server-render the code, your code will need to know the current URL/path. The new `railsContext` has this information. Your application will apply something like an "active" class on the server rendering.

##### Configuring different code for server side rendering
Suppose you want to turn off animation when doing server side rendering. The `serverSide` value is just what you need.

#### Customization of the rails_context
You can customize the values passed in the `railsContext` in your `config/initializers/react_on_rails.rb`. Here's how.

Set the config value for the `rendering_extension`:

```ruby
  config.rendering_extension = RenderingExtension
```

Implement it like this above in the same file. Create a class method on the module called `custom_context` that takes the `view_context` for a param.

See [spec/dummy/config/initializers/react_on_rails.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb) for a detailed example.

```ruby
module RenderingExtension

  # Return a Hash that contains custom values from the view context that will get merged with
  # the standard rails_context values and passed to all calls to generator functions used by the
  # react_component and redux_store view helpers
  def self.custom_context(view_context)
    {
     somethingUseful: view_context.session[:something_useful]
    }
  end
end
```

In this case, a prop and value for `somethingUseful` will go into the railsContext passed to all react_component and redux_store calls. You may set any values available in the view rendering context.

### Globally Exposing Your React Components
Place your JavaScript code inside of the default `app/javascript` folder. Use modules just as you would when using webpack alone. The difference here is that instead of mounting React components directly to an element using `React.render`, you **register your components to ReactOnRails and then mount them with helpers inside of your Rails views**.

This is how to expose a component to the `react_component` view helper.

  ```javascript
  // app/javascript/packs/hello-world-bundle.js
  import HelloWorld from '../components/HelloWorld';
  import ReactOnRails from 'react-on-rails';
  ReactOnRails.register({ HelloWorld });
  ```

#### Different Server-Side Rendering Code (and a Server Specific Bundle)

You may want different initialization for your server-rendered components. For example, if you have an animation that runs when a component is displayed, you might need to turn that off when server rendering. However, the `railsContext` will tell you if your JavaScript code is running client side or server side. So code that required a different server bundle previously may no longer require this!

If you want different code to run, you'd set up a separate webpack compilation file and you'd specify a different, server side entry file. ex. 'serverHelloWorld.jsx'. Note, you might be initializing HelloWorld with version specialized for server rendering.

#### Renderer Functions
A renderer function is a generator function that accepts three arguments: `(props, railsContext, domNodeId) => { ... }`. Instead of returning a React component, a renderer is responsible for calling `ReactDOM.render` to render a React component into the dom. Why would you want to call `ReactDOM.render` yourself? One possible use case is [code splitting](./docs/additional-reading/code-splitting.md).

Renderer functions are not meant to be used on the server since there's no DOM on the server. Instead, use a generator function. Attempting to server render with a renderer function will cause an error.

## ReactOnRails View Helpers API
Once the bundled files have been generated in your `app/assets/webpack` folder and you have registered your components, you will want to render these components on your Rails views using the included helper method, `react_component`.

### react_component
```ruby
react_component(component_name,
                props: {},
                prerender: nil,
                trace: nil,
                replay_console: nil,
                raise_on_prerender_error: nil,
                id: nil,
                html_options: {})
```

+ **component_name:** Can be a React component, created using an ES6 class or a generator function that returns a React component (or, only on the server side, an object with shape { redirectLocation, error, renderedHtml }), or a "renderer function" that manually renders a React component to the dom (client side only).
+ **options:**
  + **props:** Ruby Hash which contains the properties to pass to the react object, or a JSON string. If you pass a string, we'll escape it for you.
  + **prerender:** enable server-side rendering of a component. Set to false when debugging!
  + **id:** Id for the div, will be used to attach the React component. This will get assigned automatically if you do not provide an id. Must be unique.
  + **html_options:** Any other HTML options get placed on the added div for the component. For example, you can set a class (or inline style) on the outer div so that it behaves like a span, with the styling of `display:inline-block`.
  + **trace:** set to true to print additional debugging information in the browser. Defaults to true for development, off otherwise. Note, on the client, you will see both the `railsContext` and your props. On the server, you only see the `railsContext` being logged.
  + **replay_console:** Default is true. False will disable echoing server-rendering logs to the browser. While this can make troubleshooting server rendering difficult, so long as you have the default configuration of `logging_on_server` set to true, you'll still see the errors on the server.
  + **raise_on_prerender_error:** Default is false. True will throw an error on the server side rendering. Your controller will have to handle the error.

### redux_store
#### Controller Extension
Include the module `ReactOnRails::Controller` in your controller, probably in ApplicationController. This will provide the following controller method, which you can call in your controller actions:

`redux_store(store_name, props: {})`

+ **store_name:** A name for the store. You'll refer to this name in 2 places in your JavaScript:
  1. You'll call `ReactOnRails.registerStore({storeName})` in the same place that you register your components.
  2. In your component definition, you'll call `ReactOnRails.getStore('storeName')` to get the hydrated Redux store to attach to your components.
+ **props:**  Named parameter `props`. ReactOnRails takes care of setting up the hydration of your store with props from the view.

For an example, see [spec/dummy/app/controllers/pages_controller.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/controllers/pages_controller.rb). Note, this is preferable to using the equivalent view_helper `redux_store` in that you can be assured that the store is initialized before your components.

#### View Helper
`redux_store(store_name, props: {})`

This method has the same API as the controller extension. **HOWEVER**, we recommend the controller extension instead because the Rails executes the template code in the controller action's view file (`erb`, `haml`, `slim`, etc.) before the layout. So long as you call `redux_store` at the beginning of your action's view file, this will work. However, it's an easy mistake to put this call in the wrong place. Calling `redux_store` in the controller action ensures proper load order, regardless of where you call this in the controller action. Note, you won't know of this subtle ordering issue until you server render and you find that your store is not hydrated properly.

`redux_store_hydration_data`

Place this view helper (no parameters) at the end of your shared layout so ReactOnRails will render the redux store hydration data. Since we're going to be setting up the stores in the controllers, we need to know where on the view to put the client-side rendering of this hydration data, which is a hidden div with a matching class that contains a data props. For an example, see [spec/dummy/app/views/layouts/application.html.erb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/views/layouts/application.html.erb).

#### Redux Store Notes
Note, you don't need to initialize your redux store. You can pass the props to your React component in a "generator function." However, consider using the `redux_store` helper for the two following use cases:

1. You want to have multiple React components accessing the same store at once.
2. You want to place the props to hydrate the client side stores at the very end of your HTML so that the browser can render all earlier HTML first. This is particularly useful if your props will be large.

### server_render_js
`server_render_js(js_expression, options = {})`

+ js_expression, like 2 + 3, and not a block of js code. If you have more than one line that needs to be executed, wrap it in an [IIFE](https://en.wikipedia.org/wiki/Immediately-invoked_function_expression). JS exceptions will be caught, and console messages will be handled properly
+ Currently, the only option you may pass is `replay_console` (boolean)

This is a helper method that takes any JavaScript expression and returns the output from evaluating it. If you have more than one line that needs to be executed, wrap it in an IIFE. JS exceptions will be caught and console messages handled properly.

## Multiple React Components on a Page with One Store
You may wish to have 2 React components share the same the Redux store. For example, if your navbar is a React component, you may want it to use the same store as your component in the main area of the page. You may even want multiple React components in the main area, which allows for greater modularity. Also, you may want this to work with Turbolinks to minimize reloading the JavaScript. A good example of this would be something like a notifications counter in a header. As each notification is read in the body of the page, you would like to update the header. If both the header and body share the same Redux store, then this is trivial. Otherwise, we have to rely on other solutions, such as the header polling the server to see how many unread notifications exist.

Suppose the Redux store is called `appStore`, and you have 3 React components that each needs to connect to a store: `NavbarApp`, `CommentsApp`, and `BlogsApp`. I named them with `App` to indicate that they are the registered components.

You will need to make a function that can create the store you will be using for all components and register it via the `registerStore` method. Note, this is a **storeCreator**, meaning that it is a function that takes (props, location) and returns a store:

```js
function appStore(props, railsContext) {
  // Create a hydrated redux store, using props and the railsContext (object with
  // Rails contextual information).
  return myAppStore;
}

ReactOnRails.registerStore({
  appStore
});
```

When registering your component with React on Rails, you can get the store via `ReactOnRails.getStore`:

```js
// getStore will initialize the store if not already initialized, so creates or retrieves store
const appStore = ReactOnRails.getStore("appStore");
return (
  <Provider store={appStore}>
    <CommentsApp />
  </Provider>
);
```

From your Rails view, you can use the provided helper `redux_store(store_name, props)` to create a fresh version of the store (because it may already exist if you came from visiting a previous page). Note, for this example, since we're initializing this from the main layout, we're using a generic name of `@react_props`. In other words, the Rails controller would set `@react_props` to the properties to hydrate the Redux store.

**app/views/layouts/application.html.erb**
```erb
...
<%= redux_store("appStore", props: @react_props) %>;
<%= react_component("NavbarApp") %>
yield
...
```

Components are created as [stateless function(al) components](https://facebook.github.io/react/docs/reusable-components.html#stateless-functions). Since you can pass in initial props via the helper `redux_store`, you do not need to pass any props directly to the component. Instead, the component hydrates by connecting to the store.

**_comments.html.erb**
```erb
<%= react_component("CommentsApp") %>
```

**_blogs.html.erb**
```erb
<%= react_component("BlogsApp") %>
```

*Note:* You will not be doing any partial updates to the Redux store when loading a new page. When the page content loads, React on Rails will rehydrate a new version of the store with whatever props are placed on the page.

## ReactOnRails JavaScript API
See [ReactOnRails JavaScript API](docs/api/javascript-api.md).

#### Using Rails built-in CSRF protection in JavaScript

Rails has built-in protection for Cross-Site Request Forgery (CSRF), see [Rails Documentation](http://guides.rubyonrails.org/security.html#cross-site-request-forgery-csrf). To nicely utilize this feature in JavaScript requests, React on Rails provides two helpers that can be used as following for POST, PUT or DELETE requests:

```js
import ReactOnRails from 'react-on-rails';

// reads from DOM csrf token generated by Rails in <%= csrf_meta_tags %>
csrfToken = ReactOnRails.authenticityToken();

// compose Rails specific request header as following { X-CSRF-Token: csrfToken, X-Requested-With: XMLHttpRequest }
header = ReactOnRails.authenticityHeaders(otherHeader);
```

If you are using [jquery-ujs](https://github.com/rails/jquery-ujs) for AJAX calls, then these helpers are not needed because the [jquery-ujs](https://github.com/rails/jquery-ujs) library updates header automatically, see [jquery-ujs documentation](https://robots.thoughtbot.com/a-tour-of-rails-jquery-ujs#cross-site-request-forgery-protection).

## React Router
[React Router](https://github.com/reactjs/react-router) is supported, including server-side rendering! See:

1. [React on Rails docs for react-router](./docs/additional-reading/react-router.md)
1. Examples in [spec/dummy/app/views/react_router](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/views/react_router) and follow to the JavaScript code in the [spec/dummy/client/app/startup/ServerRouterApp.jsx](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/app/startup/ServerRouterApp.jsx).
1. [Code Splitting docs](./docs/additional-reading/code-splitting.md) for information about how to set up code splitting for server rendered routes.

## Deployment
* Version 6.0 puts the necessary precompile steps automatically in the rake precompile step. You can, however, disable this by setting certain values to nil in the [config/initializers/react_on_rails.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb).
  * `config.symlink_non_digested_assets_regex`: Set to nil to turn off the setup of non-js assets.
  * `build_production_command`: Set to nil to turn off the precompilation of the js assets.
* See the [Heroku Deployment](./docs/additional-reading/heroku-deployment.md) doc for specifics regarding Heroku. The information here should apply to other deployments.

## Integration with Node.js for Server Rendering

If you want to use a node server for server rendering, [get in touch](mailto:justin@shakacode.com). ShakaCode has built a premium Node rendering server for React on Rails.

## Additional Documentation
**Try out our new [Documentation Gitbook](https://shakacode.gitbooks.io/react-on-rails/content/) for improved readability & reference!**
+ **Webpacker Lite**
  + [Webpacker Lite: Why Fork Webpacker?](https://blog.shakacode.com/webpacker-lite-why-fork-webpacker-f0a7707fac92)

+ **Rails**
  + [Rails Assets](./docs/additional-reading/rails-assets.md)
  + [Rails Engine Integration](./docs/additional-reading/rails-engine-integration.md)
  + [Rails View Rendering from Inline JavaScript](./docs/additional-reading/rails_view_rendering_from_inline_javascript.md)
  + [RSpec Configuration](./docs/additional-reading/rspec-configuration.md)
  + [Turbolinks](./docs/additional-reading/turbolinks.md)

+ **Javascript**
  + [Node Dependencies, NPM, and Yarn](./docs/additional-reading/node-dependencies-and-npm.md)
  + [Babel](./docs/additional-reading/babel.md)
  + [React Router](./docs/additional-reading/react-router.md)
  + [React & Redux](./docs/additional-reading/react-and-redux.md)
  + [Webpack](./docs/additional-reading/webpack.md)
  + [Webpack Configuration](./docs/additional-reading/webpack.md)
  + [Webpack Cookbook](https://christianalfoni.github.io/react-webpack-cookbook/index.html)
  + [Developing with the Webpack Dev Server](docs/additional-reading/webpack-dev-server.md)
  + [Node Server Rendering](./docs/additional-reading/node-server-rendering.md)
  + [Server Rendering Tips](./docs/additional-reading/server-rendering-tips.md)
  + [Code Splitting](./docs/additional-reading/code-splitting.md)
  + [AngularJS Integration and Migration to React on Rails](./docs/additional-reading/angular-js-integration-migration.md)
  + [Webpack, the Asset Pipeline, and Using Assets w/ React](./docs/additional-reading/rails-assets-relative-paths.md)

+ **Development**
  + [React on Rails Basic Installation Tutorial](./docs/tutorial.md) ([live demo](https://hello-react-on-rails.herokuapp.com))
  + [Installation Overview](./docs/basics/installation-overview.md)
  + [Configuration](./docs/basics/configuration.md)
  + [Migration from react-rails](./docs/basics/migrating-from-react-rails.md)
  + [Recommended Project Structure](./docs/additional-reading/recommended-project-structure.md)
  + [Generator Tips](./docs/basics/generator.md)
  + [Hot Reloading of Assets For Rails Development](./docs/additional-reading/hot-reloading-rails-development.md)
  + [Heroku Deployment](./docs/additional-reading/heroku-deployment.md)
  + [Updating Dependencies](./docs/additional-reading/updating-dependencies.md)

+ **API**
  + [JavaScript API](./docs/api/javascript-api.md)
  + [Ruby API](./docs/api/ruby-api.md)
  + [Setting up Hot Reloading during Rails Development, API docs](./docs/api/ruby-api-hot-reload-view-helpers.md)

+ **[CONTRIBUTING](CONTRIBUTING.md)**
  + [Generator Testing](./docs/contributor-info/generator-testing.md)
  + [Linting](./docs/contributor-info/linters.md)
  + [Releasing](./docs/contributor-info/releasing.md)

+ **Misc**
  + [Tips](./docs/additional-reading/tips.md)
  + [Changelog](./CHANGELOG.md)
  + [Projects](./PROJECTS.md)
  + [Shaka Code Style](./docs/coding-style/style.md)
  + [React on Rails, Slides](http://www.slideshare.net/justingordon/react-on-rails-v61)
  + [Code of Conduct](./docs/misc/code_of_conduct.md)
  + [The React on Rails Doctrine](https://medium.com/@railsonmaui/the-react-on-rails-doctrine-3c59a778c724)
  + [React on Rails, 2000+ 🌟 Stars](https://medium.com/shakacode/react-on-rails-2000-stars-32ff5cfacfbf#.6gmfb2gpy)

## Demos
+ [www.reactrails.com](http://www.reactrails.com) with the source at [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/).
+ [spec app](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy): Great simple examples used for our tests.
  ```
  cd spec/dummy
  bundle && yarn
  foreman start
  ```

## Dependencies
+ Ruby 2.1 or greater
+ Rails 4.2 or greater
  + Rails 3.2 will work and is tested up to 6.8.x. We are not testing it for new releases. If you find an issue, you will have to submit a PR to get it fixed.
+ Node 5.5 or greater

## Contributing
Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to our version of the [Contributor Covenant Code of Conduct](docs/misc/code_of_conduct.md)).

See [Contributing](CONTRIBUTING.md) to get started.

## License
The gem is available as open source under the terms of the [MIT License](./docs/LICENSE.md).

## Authors
[The Shaka Code team!](http://www.shakacode.com/about/)

The origins of the project began with the need to do a rich JavaScript interface for ShakaCode's client [Madrone](http://madroneco.com/) and the choice to use Webpack and Rails, as described in [Fast Rich Client Rails Development With Webpack and the ES6 Transpiler](http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/).

The gem project started with [Justin Gordon](https://github.com/justin808/) pairing with [Samnang Chhun](https://github.com/samnang) to figure out how to do server rendering with Webpack plus Rails. [Alex Fedoseev](https://github.com/alexfedoseev) then joined in. [Rob Wise](https://github.com/robwise), [Aaron Van Bokhoven](https://github.com/aaronvb), and [Andy Wang](https://github.com/yorzi) did the bulk of the generators. Many others have [contributed](https://github.com/shakacode/react_on_rails/graphs/contributors).

We owe much gratitude to the work of the [react-rails gem](https://github.com/reactjs/react-rails).

# Thanks!
The following companies support open source, and ShakaCode uses their products!

* [JetBrains](https://www.jetbrains.com/)
* [![2017-02-21_22-35-32](https://cloud.githubusercontent.com/assets/1118459/23203304/1261e468-f886-11e6-819e-93b1a3f17da4.png)](https://www.browserstack.com)

*If you'd like to support React on Rails and have your company listed here, [get in touch](mailto:justin@shakacode.com).*

# FINAL NOTES
* See [Projects](PROJECTS.md) using and [KUDOS](./KUDOS.md) for React on Rails. Please submit yours! Please edit either page or [email us](mailto:contact@shakacode.com) and we'll add your info. We also **love stars** as it helps us attract new users and contributors.
* Follow [@railsonmaui](https://twitter.com/railsonmaui) and [@shakacode](https://twitter.com/shakacode) on Twitter for updates on releases. We've also got a forum category dedicated to [react_on_rails](https://forum.shakacode.com/c/rails/reactonrails).
* Please [Subscribe](https://app.mailerlite.com/webforms/landing/l1d9x5) to keep in touch with Justin Gordon and [ShakaCode](http://www.shakacode.com/). I intend to send announcements of new releases of React on Rails and of our latest [blog articles](https://blog.shakacode.com) and tutorials. Subscribers will also have access to **exclusive content**, including tips and examples.

[![2017-01-31_14-16-56](https://cloud.githubusercontent.com/assets/1118459/22490211/f7a70418-e7bf-11e6-9bef-b3ccd715dbf8.png)](https://app.mailerlite.com/webforms/landing/l1d9x5)

---

*Identical to top of page*

## Thank you from Justin Gordon and [ShakaCode](http://www.shakacode.com)

Thank you for considering using [React on Rails](https://github.com/shakacode/react_on_rails).

* **Video:** [Front-End Sadness to Happiness: The React on Rails Story](https://www.youtube.com/watch?v=SGkTvKRPYrk): History, motivations, philosophy, and overview.
* *[Click here for talk slides](http://www.shakacode.com/talks).*

We at [ShakaCode](http://www.shakacode.com) are a small, boutique, remote-first application development company. We fund this project by:

* Providing priority support and training for anything related to React + Webpack + Rails in our [Coaching Program](http://www.shakacode.com/work/shakacode-coaching-plan.pdf).
* Building custom web and mobile (React Native) applications. We typically work with a technical founder or CTO and instantly provide a full development team including designers.
* Migrating **Angular** + Rails to React + Rails. You can see an example of React on Rails and our work converting Angular to React on Rails at [egghead.io](https://egghead.io/browse/frameworks).
* Augmenting your team to get your product completed more efficiently and quickly.

My article "[Why Hire ShakaCode?](https://blog.shakacode.com/can-shakacode-help-you-4a5b1e5a8a63#.jex6tg9w9)" provides additional details about our projects.

If any of this resonates with you, please email me, [justin@shakacode.com](mailto:justin@shakacode.com). I offer a free half-hour project consultation, on anything from React on Rails to any aspect of web or mobile application development for both consumer and enterprise products.

We are **[currently looking to hire](http://www.shakacode.com/about/#work-with-us)** like-minded developers that wish to work on our projects, including [Friends and Guests](https://www.friendsandguests.com).

I appreciate your attention and sharing of these offerings with anybody that we can help. Your support allows me to bring you and your team [front-end happiness in the Rails world](https://www.youtube.com/watch?v=SGkTvKRPYrk).

Aloha and best wishes from the ShakaCode team!

------
