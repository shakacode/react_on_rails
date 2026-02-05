# React on Rails Basic Tutorial

_Also see the example repo of [React on Rails Tutorial With SSR, HMR fast refresh, and TypeScript](https://github.com/shakacode/react_on_rails_demo_ssr_hmr)_

---

_Updated for Ruby 3.0+, Rails 7, React on Rails v16, and Shakapacker v7_

This tutorial guides you through setting up a new or existing Rails app with **React on Rails**, demonstrating Rails + React + Redux + Server Rendering.

After finishing this tutorial you will get an application that can do the following (live on Heroku):

![example](https://cloud.githubusercontent.com/assets/371302/17368567/111cc722-596b-11e6-9b72-ac5967a60e42.gif)

You can find it here:

- [Source code for this app in PR, using the --redux option](https://github.com/shakacode/react_on_rails-test-new-redux-generation/pull/17) and [for Heroku](https://github.com/shakacode/react_on_rails-test-new-redux-generation/pull/18).
- [Live on Heroku](https://reactrails.com/)

By the time you read this, the latest may have changed. Be sure to check the versions here:

- [https://rubygems.org/gems/react_on_rails](https://rubygems.org/gems/react_on_rails)
- [https://www.npmjs.com/package/react-on-rails](https://www.npmjs.com/package/react-on-rails)

## Table of Contents

- [Installation](#installation)
  - [Setting up your environment](#setting-up-your-environment)
  - [Create a new Ruby on Rails App](#create-a-new-ruby-on-rails-app)
  - [Add the Shakapacker and react_on_rails gems](#add-the-shakapacker-and-react_on_rails-gems)
  - [Run the Shakapacker generator](#run-the-shakapacker-generator)
  - [Run the React on Rails Generator](#run-the-react-on-rails-generator)
  - [Setting up your environment variables](#setting-up-your-environment-variables)
  - [Running the app](#running-the-app)
- [HMR vs. React Hot Reloading](#hmr-vs-react-hot-reloading)
- [Deployment](#deployment)
- [Going Further](#going-further)
  - [Turning on Server Rendering](#turning-on-server-rendering)
  - [Optional Configuration](#optional-configuration)
    - [Moving from the Rails default `/app/javascript` to the recommended `/client` structure](#moving-from-the-rails-default-appjavascript-to-the-recommended-client-structure)
    - [Custom IP & PORT setup (Cloud9 example)](#custom-ip--port-setup-cloud9-example)
    - [RubyMine performance tip](#rubymine-performance-tip)
- [Conclusion](#conclusion)

## Installation

### Setting up your environment

Trying out **React on Rails** is super easy, so long as you have the basic prerequisites.

- **Ruby:** We support all active Ruby versions but recommend using the latest stable Ruby version. Solutions like [rvm](https://rvm.io) or [rbenv](https://github.com/rbenv/rbenv) make it easy to have multiple Ruby versions on your machine.
- **Rails:** This tutorial targets Rails 7.0+. React on Rails supports Rails 6 and later, but some tutorial steps may differ for Rails 6.
- **Node.js:** We support all [active Node versions](https://github.com/nodejs/release#release-schedule) but recommend using the latest LTS release of Nodejs for the longest support. Older inactive node versions might still work but is not guaranteed. We also recommend using [nvm](https://github.com/nvm-sh/nvm/) to ease using different node versions in different projects.
- **Node Package manager:** You can use [npm](https://npmjs.com/), Yarn ([Classic](https://classic.yarnpkg.com/) or [Berry](https://yarnpkg.com/)), or [pnpm](https://pnpm.io/).
- You need to have either [Overmind](https://github.com/DarthSim/overmind) or [Foreman](https://rubygems.org/gems/foreman) as a process manager.

### Create a new Ruby on Rails App

Then we need to create a fresh Rails application as follows.

First, be sure to run `rails -v` and check you are using Rails 7.0 or above for this tutorial.

```bash
# For Rails 6.x
rails new test-react-on-rails --skip-javascript

# For Rails 7.x
rails new test-react-on-rails --skip-javascript

cd test-react-on-rails
```

Note: You can use `--database=postgresql` option to use Postgresql for the database.

### Add the Shakapacker and react_on_rails gems

We recommend using the latest version of these gems. Otherwise, specify the
exact versions of both the gem and npm packages. In other words, don't use
the `^` or `~` in the version specifications.

```bash
bundle add react_on_rails --strict
bundle add shakapacker --strict
```

Note: The latest released React On Rails version is considered stable. Please use the latest
version to ensure you get all the security patches and the best support.

### Run the Shakapacker generator

```bash
bundle exec rails shakapacker:install
```

Commit all the changes so far to avoid getting errors in the next step.

```bash
git commit -am "Initial commit"
```

Alternatively, you can use `--ignore-warnings` in the next step.

### Run the React on Rails Generator

```bash
rails generate react_on_rails:install
```

You will be prompted to approve changes in certain files. Press `enter` to proceed
one by one or enter `a` to replace all configuration files required by the project.
You can check the diffs before you commit to see what changed.

**Note on Redux:** The basic installer uses React Hooks for state management. However, this tutorial demonstrates Redux integration (as used in the [live example](https://reactrails.com/)). To follow this tutorial with Redux, run:

```bash
rails generate react_on_rails:install --redux
```

If you prefer to use React Hooks instead of Redux, run the basic installer without the `--redux` flag.

### Setting up your environment variables

Add the following variable to your environment:

```
EXECJS_RUNTIME=Node
```

Then run the server with one of the following options:

### Running the app

```bash
./bin/dev # For HMR
# or
./bin/dev static # Without HMR, statically creating the bundles
```

Visit [http://localhost:3000/hello_world](http://localhost:3000/hello_world) and see your **React On Rails** app running!

## HMR vs. React Hot Reloading

First, check that the `hmr` and the `inline` options are `true` in your `config/shakapacker.yml` file.

The basic setup will have HMR working with the default Shakapacker setup. When you run `./bin/dev` and change a JSX file, the browser will automatically refresh!

The basic [HMR](https://webpack.js.org/concepts/hot-module-replacement/), without a special React setup, will cause a full page refresh each time you save a file.

If you want to go further with HMR, take a look at these links:

- [webpack-dev-server](https://github.com/rails/webpacker/blob/5-x-stable/docs/webpack-dev-server.md)
- [DevServer](https://webpack.js.org/configuration/dev-server/)
- [Hot Module Replacement](https://webpack.js.org/concepts/hot-module-replacement/)

React on Rails will automatically handle disabling server rendering if there is only one bundle file created by the Webpack development server by `shakapacker`.

## Deployment

Now that you have React on Rails working locally, you're ready to deploy to production!

For detailed deployment instructions, see:

- **[Heroku Deployment Guide](../deployment/heroku-deployment.md)** - Step-by-step Heroku deployment
- **[General Deployment Guide](../deployment/index.md)** - Production deployment strategies for any platform

These guides cover:

- Configuring buildpacks
- Database setup (PostgreSQL)
- Asset compilation
- Environment variables
- Troubleshooting common deployment issues

## Going Further

### Turning on Server Rendering

You can turn on server rendering by simply changing the `prerender` option to `true`:

```erb
<%= react_component("HelloWorld", props: @hello_world_props, prerender: true) %>
```

If you want to test this out with HMR, then you also need to add this line to your
`config/intializers/react_on_rails.rb`

```ruby
  config.same_bundle_for_client_and_server = true
```

More likely, you will create a different build file for server rendering. However, if you want to
use the same file from the shakapacker-dev-server, you'll need to add that line.

When you look at the source code for the page (right click, view source in Chrome), you can see the difference between non-server rendering, where your DIV containing your React looks like this:

```html
<div id="HelloWorld-react-component-b7ae1dc6-396c-411d-886a-269633b3f604"></div>
```

versus with server rendering:

```html
<div id="HelloWorld-react-component-d846ce53-3b82-4c4a-8f32-ffc347c8444a">
  <div data-reactroot="">
    <h3>
      Hello,
      <!-- -->Stranger<!-- -->!
    </h3>
    <hr />
    <form><label for="name">Say hello to:</label><input type="text" id="name" value="Stranger" /></form>
  </div>
</div>
```

For more details on server rendering, see:

- [Client vs. Server Rendering](../core-concepts/client-vs-server-rendering.md)
- [React Server Rendering](../core-concepts/react-server-rendering.md)

### Optional Configuration

#### Moving from the Rails default `/app/javascript` to the recommended `/client` structure

ShakaCode recommends that you use `/client` for your client side app. This way a non-Rails, front-end developer can be at home just by opening up the `/client` directory.

1. Move the directory:

```bash
mv app/javascript client
```

2. Edit your `/config/shakapacker.yml` file. Change the `default/source_path`:

```yml
source_path: client
```

#### Custom IP & PORT setup (Cloud9 example)

In case you are running some custom setup with different IP or PORT you should also edit Procfile.dev. For example, to be able to run on free Cloud9 IDE we are putting IP 0.0.0.0 and PORT 8080. The default generated file `Procfile.dev` uses `-p 3000`.

```Procfile.dev
web: rails s -p 8080 -b 0.0.0.0
```

Then visit https://your-shared-addr.c9users.io:8080/hello_world

#### RubyMine performance tip

It's super important to exclude certain directories from RubyMine or else it will slow to a crawl as it tries to parse all the npm files.

- Generated files, per the settings in your `config/shakapacker.yml`, which default to `public/packs` and `public/packs-test`
- `node_modules`

## Conclusion

- Browse the docs on [our documentation website](https://www.shakacode.com/react-on-rails/docs/)

Feedback is greatly appreciated! As are stars on github!

If you want personalized help, don't hesitate to get in touch with us at [contact@shakacode.com](mailto:contact@shakacode.com). We offer [React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki) and consulting so you can focus on your app and not on how to make Webpack plus Rails work optimally.
