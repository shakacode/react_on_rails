# ReactOnRails

[![License](https://img.shields.io/badge/license-mit-green.svg)](./LICENSE.md) [![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails) [![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Code Climate](https://codeclimate.com/github/shakacode/react_on_rails/badges/gpa.svg)](https://codeclimate.com/github/shakacode/react_on_rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master) [![](https://ruby-gem-downloads-badge.herokuapp.com/react_on_rails?type=total)](https://rubygems.org/gems/react_on_rails)

React on Rails integrates Rails with (server rendering of) Facebook's [React](https://github.com/facebook/react) front-end framework.

Interested in optimizing your webpack setup for React on Rails including code splitting with react-router v4, webpack v4, and react-loadable with server side rendering? [Contact Justin Gordon](mailto:justin@shakacode.com).

# Intro

## Project Objective

To provide an opinionated and optimal framework for integrating Ruby on Rails with React via the [**Webpacker**](https://github.com/rails/webpacker) gem especially in regards to React Server Rendering.

## Features and Why React on Rails?

Given that rails/webpacker gem already provides basic React integration, why would you use "React on Rails"? 

1. Server rendering, often used for SEO crawler indexing and UX performance, is not offered by rails/webpacker.
1. The easy passing of props directly from your Rails view to your React components rather than having your Rails view load and then make a separate request to your API.
1. [Redux](https://github.com/reactjs/redux) and [React Router](https://github.com/reactjs/react-router) integration with server-side-rendering.
1. [Internationalization (I18n) and (localization)](https://github.com/shakacode/react_on_rails/blob/master/docs/basics/i18n.md)
1. [RSpec Test Helpers Configuration](docs/basics/rspec-configuration.md) to ensure your Webpack bundles are ready for tests. _(and for [Minitest](docs/basics/minitest-configuration.md))._
1. A supportive community. This [web search shows how live public sites are using React on Rails](https://publicwww.com/websites/%22react-on-rails%22++-undeveloped.com/).
1. [Reason ML Support](https://github.com/shakacode/reason-react-on-rails-example).


See the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) for an example of a live implementation and code.

## ShakaCode Forum Premium Content
_Requires creating a free account._ 
* [How to use different versions of a file for client and server rendering](https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352)

## React on Rails Pro and ShakaCode Pro Support

React on Rails Pro provides Node server rendering and other performance enhancements for React on Rails. 

[![2018-09-11_10-31-11](https://user-images.githubusercontent.com/1118459/45467845-5bcc7400-b6bd-11e8-91e1-e0cf806d4ea4.png)](https://blog.shakacode.com/hvmns-90-reduction-in-server-response-time-from-react-on-rails-pro-eb08226687db)

* [HVMN Testimonial, by Paul Benigeri, October 12, 2018](./docs/testimonials/hvmn.md)
* [HVMN’s 90% Reduction in Server Response Time from React on Rails Pro](https://blog.shakacode.com/hvmns-90-reduction-in-server-response-time-from-react-on-rails-pro-eb08226687db)
* [Egghead React on Rails Pro Deployment Highlights](https://github.com/shakacode/react_on_rails/wiki/Egghead-React-on-Rails-Pro-Deployment-Highlights)

For more information, see the [React on Rails Pro Docs](https://github.com/shakacode/react_on_rails/wiki).

The [ShakaCode Pro Support Plan](http://www.shakacode.com/work/shakacode-pro-support.pdf) can help you with:

* Optimizing your webpack setup to Webpack v4 for React on Rails including code splitting with react-router v4, webpack v4, and react-loadable.
* Upgrading your app to use the current Webpack setup that skips the Sprockets asset pipeline.
* Better performance client and server side.
* Efficiently migrating from [Angular to React](https://www.shakacode.com/services/angular-to-react/).
* Best practices based on over four years of React on Rails experience.
* Using [Reason](https://reasonml.github.io/) with (or without) React on Rails.

ShakaCode can also help you with your custom software development needs. We specialize in marketplace and e-commerce applications that utilize both Rails and React. Because we own [HawaiiChee.com](https://www.hawaiichee.com), we can leverage that code for your app! 

The article [Why Hire ShakaCode?](https://blog.shakacode.com/can-shakacode-help-you-4a5b1e5a8a63#.jex6tg9w9) provides additional details about our projects.

Please [email me (Justin Gordon), the creator of React on Rails](mailto:justin@shakacode.com), to see if I can help you or if you want an invite to our private Slack room for ShakaCode.

## Testimonials for Hiring ShakaCode and our "Pro Support"

[HVMN Testimonial, Written by Paul Benigeri, October 12, 2018](./docs/testimonials/hvmn.md)

> The price we paid for the consultation + the React on Rails pro license has already been made back a couple of times from hosting fees alone. The entire process was super hands off, and our core team was able to focus on shipping new feature during that sprint.

[ResortPass Testimonial, by Leora Juster, December 10, 2018](./docs/testimonials/resortpass.md)

> Justin and his team were instrumental in assisting us in setting design foundations and standards for our transition to a react on rails application. Just three months of work with the team at Shaka code and we have a main page of our application server-side rendering at exponentially improved speeds.

From Kyle Maune of Cooper Aerial, May 4, 2018

![image](https://user-images.githubusercontent.com/1118459/40891236-9b0b406e-671d-11e8-80ee-c026dbd1d5a2.png)

From Joel Hooks, Co-Founder, Chief Nerd at [egghead.io](https://egghead.io/), January 30, 2017:

![2017-01-30_11-33-59](https://cloud.githubusercontent.com/assets/1118459/22443635/b3549fb4-e6e3-11e6-8ea2-6f589dc93ed3.png)

For more testimonials, see [Live Projects](PROJECTS.md) and [Kudos](./KUDOS.md).

----

# Docs

**Consider browsing this on our [documentation Gitbook](https://shakacode.gitbooks.io/react-on-rails/content/).**

## Prerequisites

React on Rails supports older versions of Rails back to 3.x. Rails/webpacker requires version 4.2+.

## Getting Started

Note, the best way to understand how to use ReactOnRails is to study a few simple examples. You can do a quick demo setup, either on your existing app or on a new Rails app. 

1. Do the quick [tutorial](docs/tutorial.md).
2. Add React on Rails to an existing Rails app per [the instructions](docs/basics/installation-into-an-existing-rails-app.md).
3. Look at [spec/dummy](spec/dummy), a simple, no DB example.
3. Look at [github.com/shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial); it's a full-featured example live at [www.reactrails.com](http://www.reactrails.com).

## Basic Installation

*See also [the instructions for installing into an existing Rails app](docs/basics/installation-into-an-existing-rails-app.md).*

1. Create a new Rails app:

   ``````bash
   $ rails new my-app --webpack=react
   $ cd my-app
   ``````

2. Add the `react_on_rails` gem to Gemfile:

   ```ruby
   gem 'react_on_rails', '11.1.4' # Use the exact gem version to match npm version
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

  
### Turning on server rendering

With the code from running the React on Rails generator above:

1. Edit `app/views/hello_world/index.html.erb` and set `prerender` to `true`.
2. Refresh the page.

Below is the line where you turn server rendering on by setting `prerender` to true:

```erb
<%= react_component("HelloWorld", props: @hello_world_props, prerender: false) %>
```

## Basic Usage

### Configuration

* Configure `config/initializers/react_on_rails.rb`. You can adjust some necessary settings and defaults. See file [docs/basics/configuration.md](docs/basics/configuration.md) for documentation of all configuration options.
* Configure `config/webpacker.yml`. If you used the generator and the default webpacker setup, you don't need to touch this file. If you are customizing your setup, then consult the [spec/dummy/config/webpacker.yml](./spec/dummy/config/webpacker.yml) example
  * Set `compile: false` for all envs
  * Your `public_output_path` must match your Webpack configuration for `output` of your bundles.
  * Only set `cache_manifest` to `true` in your production env.

## Including your React Component on your Rails Views

- React component are rendered via your Rails Views. Here's an ERB sample:

  ```erb
  <%= react_component("HelloWorld", props: @some_props) %>
  ```

- **Server-Side Rendering**: Your react component is first rendered into HTML on the server. Use the **prerender** option:

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
  
- This is what your HelloWorld.js file might contain. The railsContext is always available for any parameters that you _always_ want available for your React components. It has _nothing_ to do with the concept of the [React Context](https://reactjs.org/docs/context.html). See [Generator Functions and the RailsContext](docs/basics/generator-functions-and-railscontext.md) for more details on this topic.
  
  ```js
  import React from 'react';

  export default (props, railsContext) => {
    return (
      <div>
        Your locale is {railsContext.i18nLocale}.<br/>
        Hello, {props.name}!
      </div>
    );
  };
  ``` 
  
See the [View Helpers API](./docs/api/view-helpers-api.md) for more details on `react_component` and its sibling function `react_component_hash`.

## Fragment Caching

Fragment caching is a [React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki) feature. Fragment caching is a **HUGE** performance booster for your apps. Use the `cached_react_component` and `cached_react_component_hash`. The API is the same as `react_component` and `react_component_hash`, but for 2 differences:

1. The `cache_key` takes the same parameters as any Rails `cache` view helper.
1. The **props** are passed via a block so that evaluation of the props is not done unless the cache is broken. Suppose you put your props calculation into some method called `some_slow_method_that_returns_props`:

```ruby
<%= cached_react_component("App", cache_key: [@user, @post], prerender: true) do
  some_slow_method_that_returns_props
end %>
```

Such fragment caching saves a ton of CPU work for your web server and greatly reduces the request time. It completely skips the evaluation costs of:

1. Database calls to compute the props.
2. Serialization the props values hash into a JSON string for evaluating JavaScript to server render.
3. Costs associated with evaluating JavaScript from your Ruby code.
4. Creating the HTML string containing the props and the server-rendered JavaScript code.

Note, even without server rendering (without step 3 above), fragment caching is still effective.
  
## Integration with Node.js for Server Rendering

Default server rendering is done by ExecJS. If you want to use a Node.js server for better performing server rendering, [email justin@shakacode.com](mailto:justin@shakacode.com). ShakaCode has built a premium Node rendering server that is part of [React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki).

## Globally Exposing Your React Components

For the React on Rails view helper `react_component` to use your React components, you will have to **register** them in your JavaScript code.

Use modules just as you would when using Webpack and React without Rails. The difference is that instead of mounting React components directly to an element using `React.render`, you **register your components to ReactOnRails and then mount them with helpers inside of your Rails views**.

This is how to expose a component to the `react_component` view helper.

```javascript
  // app/javascript/packs/hello-world-bundle.js
  import HelloWorld from '../components/HelloWorld';
  import ReactOnRails from 'react-on-rails';
  ReactOnRails.register({ HelloWorld });
```

#### Different Server-Side Rendering Code (and a Server-Specific Bundle)

You may want different code for your server-rendered components running server side versus client side. For example, if you have an animation that runs when a component is displayed, you might need to turn that off when server rendering. One way to handle this is conditional code like `if (window) { doClientOnlyCode() }`. 

Another way is to use a separate webpack configuration file that can use a different server side entry file, like  'serverRegistration.js' as opposed to 'clientRegistration.js.' That would set up different code for server rendering.

For details on techniques to use different code for client and server rendering, see: [How to use different versions of a file for client and server rendering](https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352). (_Requires creating a free account._)

## Specifying Your React Components: Direct or Generator Functions

You have two ways to specify your React components. You can either register the React component directly, or you can create a function that returns a React component. Creating a function has the following benefits:

1. You have access to the `railsContext`. See documentation for the railsContext in terms of why you might need it. You **need** a generator function to access the `railsContext`.
2. You can use the passed-in props to initialize a redux store or set up react-router.
3. You can return different components depending on what's in the props.

ReactOnRails will automatically detect a registered generator function. Thus, there is no difference between registering a React Component versus a "generator function."

## react_component_hash for Generator Functions

Another reason to use a generator function is that sometimes in server rendering, specifically with React Router, you need to return the result of calling ReactDOMServer.renderToString(element). You can do this by returning an object with the following shape: { renderedHtml, redirectLocation, error }. Make sure you use this function with `react_component_hash`. 

For server rendering, if you wish to return multiple HTML strings from a generator function, you may return an Object from your generator function with a single top-level property of `renderedHtml`. Inside this Object, place a key called `componentHtml`, along with any other needed keys. An example scenario of this is when you are using side effects libraries like [React Helmet](https://github.com/nfl/react-helmet). Your Ruby code will get this Object as a Hash containing keys componentHtml and any other custom keys that you added:

```js
{ renderedHtml: { componentHtml, customKey1, customKey2} }
```

For details on using react_component_hash with react-helmet, see the docs below for the helper API and [docs/additional-reading/react-helmet.md](docs/additional-reading/react-helmet.md).

## Error Handling

* All errors from ReactOnRails will be of type ReactOnRails::Error.
* Prerendering (server rendering) errors get context information for HoneyBadger and Sentry for easier debugging.

## I18n

You can enable the i18n functionality with [react-intl](https://github.com/yahoo/react-intl). React on Rails provides an option for automatic conversions of Rails `*.yml` locale files into `*.js` files for `react-intl`. See the [How to add I18n](docs/basics/i18n.md) for a summary of adding I18n.

## More Details

Browse the links in the [Summary Table of Contents](./SUMMARY.md)

Here are some highly recommended next articles to read:

1. [How React on Rails Works](./docs/basics/how-react-on-rails-works.md)
1. [Recommended Project Structure](./docs/basics/recommended-project-structure.md)
1. [Webpack Configuration](./docs/basics/webpack-configuration.md)
1. [View Helpers API](./docs/api/view-helpers-api.md) 
1. [Caching and Performance: React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki).
1. [Deployment](docs/basics/deployment.md).

# Support

## ShakaCode Support

Aloha, I'm Justin Gordon the creator and maintainer of React on Rails. I'm supporting my continued dedication to this project by project by offering a React on Rails **Pro Support Plan**. Please [email me](mailto:justin@shakacode.com) to see if I can help you.

## Community Resources

Please [**click to subscribe**](https://app.mailerlite.com/webforms/landing/l1d9x5) to keep in touch with Justin Gordon and [ShakaCode](http://www.shakacode.com/). I intend to send announcements of new releases of React on Rails and of our latest [blog articles](https://blog.shakacode.com) and tutorials.

[![2017-01-31_14-16-56](https://cloud.githubusercontent.com/assets/1118459/22490211/f7a70418-e7bf-11e6-9bef-b3ccd715dbf8.png)](https://app.mailerlite.com/webforms/landing/l1d9x5)

- **Slack Room**: [Contact us](mailto:contact@shakacode.com) for an invite to the ShakaCode Slack room! Let us know if you want to contribute.
- **[forum.shakacode.com](https://forum.shakacode.com)**: Post your questions
- **[@railsonmaui on Twitter](https://twitter.com/railsonmaui)**
- For a live, [open source](https://github.com/shakacode/react-webpack-rails-tutorial), example of this gem, see [www.reactrails.com](http://www.reactrails.com).
- See [Projects](PROJECTS.md) using and [KUDOS](./KUDOS.md) for React on Rails. Please submit yours! Please edit either page or [email us](mailto:contact@shakacode.com) and we'll add your info. We also **love stars** as it helps us attract new users and contributors.
- *See [NEWS.md](NEWS.md) for more notes over time.*

## Contributing

Bug reports and pull requests are welcome. See [Contributing](CONTRIBUTING.md) to get started, and the [list of help wanted issues](https://github.com/shakacode/react_on_rails/labels/contributions%3A%20up%20for%20grabs%21).

# Supporters

The following companies support this open source project, and ShakaCode uses their products! Justin writes React on Rails on [RubyMine](https://www.jetbrains.com/ruby/). We use [Scout](https://scoutapp.com/) to monitor the live performance of [HawaiiChee.com](https://www.hawaiichee.com), [BrowserStack](https://www.browserstack.com) to solve problems with oddball browsers, and [CodersRank](https://codersrank.io/) to find candidates for our team.

[![Scout](https://user-images.githubusercontent.com/1118459/41828269-106b40f8-77d0-11e8-8d19-9c4b167ef9d8.png)](https://scoutapp.com/)
[![BrowserStack](https://cloud.githubusercontent.com/assets/1118459/23203304/1261e468-f886-11e6-819e-93b1a3f17da4.png)](https://www.browserstack.com)
[![CodersRank](https://user-images.githubusercontent.com/1118459/55040254-ad8a7b00-4fcb-11e9-8936-c6765eb30698.png)](https://codersrank.io/?utm_source=github&utm_medium=banner&utm_campaign=shakacode)

## Clubhouse
I've just moved ShakaCode's development to [ClubHouse](https://clubhouse.io/) from Trello. We're going to be doing this with all our projects. If you want to **try ClubHouse and get 2 months free beyond the 14-day trial period**, click [here to use ShakaCode's referral code](http://r.clbh.se/mvfd30S). We're participating in their awesome triple-sided referral program, which you can read about [here](https://clubhouse.io/blog/clubhouse-referral-program-5f614bb437c3). By using our [referral code](http://r.clbh.se/mvfd30S) you'll be supporting ShakaCode and, thus, React on Rails!

*If you'd like to support React on Rails and have your company listed here, [get in touch](mailto:justin@shakacode.com).*

Aloha and best wishes from Justin and the ShakaCode team!

# Work with Us
ShakaCode is **[currently looking to hire](http://www.shakacode.com/about/#work-with-us)** like-minded, remote-first, developers that wish to work on our projects, including [Hawaii Chee](https://www.hawaiichee.com). Your main coding interview will be pairing with us on our open source! We're getting into [Reason](https://reasonml.github.io/)!

# License

The gem is available as open source under the terms of the [MIT License](LICENSE.md).
