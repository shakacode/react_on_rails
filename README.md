![reactrails](https://user-images.githubusercontent.com/10421828/79436261-52159b80-7fd9-11ea-994e-2a98dd43e540.png)

<p align="center">
 <a href="https://shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436256-517d0500-7fd9-11ea-9300-dfbc7c293f26.png"></a>
 <a href="https://forum.shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436266-53df5f00-7fd9-11ea-94b3-b985e1b05bdc.png"></a>
 <a href="https://www.shakacode.com/react-on-rails-pro"><img src="https://user-images.githubusercontent.com/10421828/79436265-53df5f00-7fd9-11ea-8220-fc474f6a856c.png"></a>
 <a href="https://github.com/sponsors/shakacode"><img src="https://user-images.githubusercontent.com/10421828/79466109-cdd90d80-8004-11ea-88e5-25f9a9ddcf44.png"></a>
</p>

---

[![License](https://img.shields.io/badge/license-mit-green.svg)](LICENSE.md) [![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails) [![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Code Climate](https://codeclimate.com/github/shakacode/react_on_rails/badges/gpa.svg)](https://codeclimate.com/github/shakacode/react_on_rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master) [![](https://ruby-gem-downloads-badge.herokuapp.com/react_on_rails?type=total)](https://rubygems.org/gems/react_on_rails)

*These are the docs for React on Rails 12. To see the version 11 docs, [click here](https://github.com/shakacode/react_on_rails/tree/11.3.0).*

#### News
**October 14, 2020**: [RUBY ROGUES
RR 474: React on Rails V12 – Don’t Shave That Yak! with Justin Gordon](https://devchat.tv/ruby-rogues/rr-474-react-on-rails-v12-dont-shave-that-yak-with-justin-gordon/).

**October 1, 2020**: See the [spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy) example repo for a simple configuration of webpack via the rails/webpacker gem
that supports SSR.

**August 2, 2020**: See the example repo of [React on Rails Tutorial With SSR, HMR fast refresh, and TypeScript](https://github.com/shakacode/react_on_rails_tutorial_with_ssr_and_hmr_fast_refresh) for a new way to setup the creation of your SSR bundle with `rails/webpacker`.

**July 8, 2020**: Release v12 of React on Rails.

**Major Improvements**

1. **React Hooks Support** for top level components
2. **Typescript bindings**
3. **rails/webpacker** "just works" with React on Rails by default.
4. i18n support for generating a JSON file rather than a JS file.

Be sure to see the [CHANGELOG.md](https://github.com/shakacode/react_on_rails/tree/master/CHANGELOG.md) and read the upgrade instructions:
[docs/basics/upgrading-react-on-rails](https://www.shakacode.com/react-on-rails/docs/basics/upgrading-react-on-rails#upgrading-to-v12).

* See Justin's RailsConf talk: [Webpacker, It-Just-Works, But How?](http://railsconf.com/2020/video/justin-gordon-webpacker-it-just-works-but-how).
* Are you interested in support for React on Rails? Do you want to use Node.js to do your server-side rendering so libraries like Emotion and Loadable Components just work, as compared to rendering via Ruby embedded JS? If so check out [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro).
* HMR is working with [Loadable Components](https://loadable-components.com) for a both amazing hot-reloading developer experience and great runtime performance. Please [email me](mailto:justin@shakacode.com) if you'd like to use [Loadable Components Code Splitting](https://loadable-components.com/docs/code-splitting/) to speed up your app by reducing your bundle sizes and lazily loading the code that's needed.
---

#### About
React on Rails integrates Rails with (server rendering of) Facebook's [React](https://github.com/facebook/react) front-end framework.

This project is maintained by the software consulting firm [ShakaCode](https://www.shakacode.com). We focus on Ruby on Rails applications with React front-ends, often using TypeScript or ReasonML. We also build Gatsby sites. See [our recent work](https://www.shakacode.com/recent-work) for examples of what we do.

Interested in optimizing your webpack setup for React on Rails including code
splitting with [react-router](https://github.com/ReactTraining/react-router#readme),
and [loadable-components](https://loadable-components.com/) with server-side rendering?
We just did this for Popmenu, [lowering Heroku costs 20-25% while getting a 73% decrease in average response times](https://www.shakacode.com/recent-work/popmenu/).

Feel free to contact Justin Gordon, [justin@shakacode.com](mailto:justin@shakacode.com), maintainer of React on Rails, for more information.

[Click to join **React + Rails Slack**](https://reactrails.slack.com/join/shared_invite/enQtNjY3NTczMjczNzYxLTlmYjdiZmY3MTVlMzU2YWE0OWM0MzNiZDI0MzdkZGFiZTFkYTFkOGVjODBmOWEyYWQ3MzA2NGE1YWJjNmVlMGE).

# Intro

## Project Objective

To provide a high performance framework for integrating Ruby on Rails with React via the [**Webpacker**](https://github.com/rails/webpacker) gem especially in regards to React Server-Side Rendering for better SEO and improved performance.

## Features and Why React on Rails?

Given that `rails/webpacker` gem already provides basic React integration, why would you use "React on Rails"?

1. Easy passing of props directly from your Rails view to your React components rather than having your Rails view load and then make a separate request to your API.
1. Tight integration with [rails/webpacker](https://github.com/rails/webpacker).
1. Server-Side Rendering (SSR), often used for SEO crawler indexing and UX performance, is not offered by `rails/webpacker`.
1. [Redux](https://github.com/reactjs/redux) and [React Router](https://github.com/ReactTraining/react-router#readme) integration with server-side-rendering.
1. [Internationalization (I18n) and (localization)](https://www.shakacode.com/react-on-rails/docs/basics/i18n)
1. A supportive community. This [web search shows how live public sites are using React on Rails](https://publicwww.com/websites/%22react-on-rails%22++-undeveloped.com+depth%3Aall/).
1. [Reason ML Support](https://github.com/shakacode/reason-react-on-rails-example).

See [Rails/Webpacker React Integration Options](./docs/rails-webpacker-react-integration-options.md) for comparisons to other gems.

See the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) for an example of a live implementation and code.

## ShakaCode Forum Premium Content
_Requires creating a free account._

* [How to use different versions of a file for client and server rendering](https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352)
* [How to conditionally render server side based on the device type](https://forum.shakacode.com/t/how-to-conditionally-render-server-side-based-on-the-device-type/1473)

----

# Docs

**Consider browsing this on our [website](https://www.shakacode.com/react-on-rails/docs/).**

## Prerequisites

Ruby on Rails >=5 and rails/webpacker 4.2+.

## Getting Started

Note, the best way to understand how to use ReactOnRails is to study a few simple examples. You can do a quick demo setup, either on your existing app or on a new Rails app.

1. Do the quick [tutorial](https://www.shakacode.com/react-on-rails/docs/basics/tutorial).
2. Add React on Rails to an existing Rails app per [the instructions](https://www.shakacode.com/react-on-rails/docs/basics/installation-into-an-existing-rails-app).
3. Look at [spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy), a simple, no DB example.
3. Look at [github.com/shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial); it's a full-featured example live at [www.reactrails.com](http://www.reactrails.com).

## Basic Installation

*See also [the instructions for installing into an existing Rails app](https://www.shakacode.com/react-on-rails/docs/basics/installation-into-an-existing-rails-app).*

2. Add the `react_on_rails` gem to Gemfile:

   ```bash
   bundle add react_on_rails --strict
   ```

4. Commit this to git (or else you cannot run the generator unless you pass the option `--ignore-warnings`).

5. Run the generator:

   ```bash
   rails generate react_on_rails:install
   ```

6. Start the app:

   ```bash
   rails s
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

Note, if you got an error in your console regarding "ReferenceError: window is not defined",
then you need to edit `config/webpacker.yml` and set `hmr: false` and `inline: false`.
See [rails/webpacker PR 2644](https://github.com/rails/webpacker/pull/2644) for a fix for this
issue.

## Basic Usage

### Configuration

* Configure `config/initializers/react_on_rails.rb`. You can adjust some necessary settings and defaults. See file [docs/basics/configuration.md](https://www.shakacode.com/react-on-rails/docs/basics/configuration) for documentation of all configuration options.
* Configure `config/webpacker.yml`. If you used the generator and the default webpacker setup, you don't need to touch this file. If you are customizing your setup, then consult the [spec/dummy/config/webpacker.yml](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/webpacker.yml) example or the official default [webpacker.yml](https://github.com/rails/webpacker/blob/master/lib/install/config/webpacker.yml).
  * Tip: set `compile: false` for development if you know that you'll always be compiling with a watch process. Otherwise, every request will check if compilation is needed.
  * Your `public_output_path` must match your custom Webpack configuration for `output` of your bundles.
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

  Exposing your component in this way is how React on Rails is able to reference your component from a Rails view. You can expose as many components as you like, as long as their names do not collide. See below for the details of how you expose your components via the react_on_rails webpack configuration. You may call `ReactOnRails.register` many times.

- `@some_props` can be either a hash or JSON string. This is an optional argument assuming you do not need to pass any options (if you want to pass options, such as `prerender: true`, but you do not want to pass any properties, simply pass an empty hash `{}`). This will make the data available in your component:

  ```ruby
    # Rails View
    <%= react_component("HelloWorld", props: { name: "Stranger" }) %>
  ```

- This is what your HelloWorld.js file might contain. The railsContext is always available for any parameters that you _always_ want available for your React components. It has _nothing_ to do with the concept of the [React Context](https://reactjs.org/docs/context.html). See [Render-Functions and the RailsContext](https://www.shakacode.com/react-on-rails/docs/basics/render-functions-and-railscontext) for more details on this topic.

  ```js
  import React from 'react';

  export default (props, railsContext) => {
    // Note wrap in a function to make this a React function component
    return () => (
      <div>
        Your locale is {railsContext.i18nLocale}.<br/>
        Hello, {props.name}!
      </div>
    );
  };
  ```

See the [View Helpers API](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api) for more details on `react_component` and its sibling function `react_component_hash`.

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

## Specifying Your React Components: Register directly or use render-functions

You have two ways to specify your React components. You can either register the React component (either function or class component) directly, or you can create a function that returns a React component, which we using the name of a "render-function". Creating a render-function allows:

1. You to have access to the `railsContext`. See [documentation for the railsContext](https://www.shakacode.com/react-on-rails/docs/basics/render-functions-and-railscontext) in terms of why you might need it. You **need** a Render-Function to access the `railsContext`.
2. You can use the passed-in props to initialize a redux store or set up react-router.
3. You can return different components depending on what's in the props.

Note, the return value of a **Render-Function** should be either a React Function or Class Component, or an object representing server rendering results.

Do not return a React Element (JSX).

ReactOnRails will automatically detect a registered Render-Function by the fact that the function takes
more than 1 parameter. In other words, if you want the ability to provide a function that returns the
React component, then you need to specify at least a second parameter. This is the `railsContext`.
If you're not using this parameter, declare your function with the unused param:

```js
const MyComponentGenerator = (props, _railsContext) => {
  if (props.print) {
    // This is a React FunctionComponent because it is wrapped in a function.
    return () => <H1>{JSON.stringify(props)}</H1>;
  }
}
```

Thus, there is no difference between registering a React Function Component or class Component versus a "Render-Function." Just call `ReactOnRails.register`.

## react_component_hash for Render-Functions

Another reason to use a Render-Function is that sometimes in server rendering, specifically with React Router, you need to return the result of calling ReactDOMServer.renderToString(element). You can do this by returning an object with the following shape: { renderedHtml, redirectLocation, error }. Make sure you use this function with `react_component_hash`.

For server rendering, if you wish to return multiple HTML strings from a Render-Function, you may return an Object from your Render-Function with a single top-level property of `renderedHtml`. Inside this Object, place a key called `componentHtml`, along with any other needed keys. An example scenario of this is when you are using side effects libraries like [React Helmet](https://github.com/nfl/react-helmet). Your Ruby code will get this Object as a Hash containing keys componentHtml and any other custom keys that you added:

```js
{ renderedHtml: { componentHtml, customKey1, customKey2} }
```

For details on using react_component_hash with react-helmet, see [our react-helmet documentation](https://www.shakacode.com/react-on-rails/docs/additional-reading/react-helmet).

## Error Handling

* All errors from ReactOnRails will be of type ReactOnRails::Error.
* Prerendering (server rendering) errors get context information for HoneyBadger and Sentry for easier debugging.

## I18n

React on Rails provides an option for automatic conversions of Rails `*.yml` locale files into `*.json` or `*.js*.
See the [How to add I18n](https://www.shakacode.com/react-on-rails/docs/basics/i18n) for a summary of adding I18n.

## More Details

Browse the links in the [Summary Table of Contents](https://github.com/shakacode/react_on_rails/tree/master/SUMMARY.md)

Here are some highly recommended next articles to read:

1. [How React on Rails Works](https://www.shakacode.com/react-on-rails/docs/basics/how-react-on-rails-works)
1. [Webpack Configuration](https://www.shakacode.com/react-on-rails/docs/basics/webpack-configuration)
1. [View Helpers API](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api)
1. [Caching and Performance: React on Rails Pro](https://www.shakacode.com/react-on-rails-pro).
1. [Deployment](https://www.shakacode.com/react-on-rails/docs/basics/deployment).

# Support

[Click to join **React + Rails Slack**](https://reactrails.slack.com/join/shared_invite/enQtNjY3NTczMjczNzYxLTlmYjdiZmY3MTVlMzU2YWE0OWM0MzNiZDI0MzdkZGFiZTFkYTFkOGVjODBmOWEyYWQ3MzA2NGE1YWJjNmVlMGE).

## Community Resources

Please [**click to subscribe**](https://app.mailerlite.com/webforms/landing/l1d9x5) to keep in touch with Justin Gordon and [ShakaCode](http://www.shakacode.com/). I intend to send announcements of new releases of React on Rails and of our latest [blog articles](https://blog.shakacode.com) and tutorials.

[![2017-01-31_14-16-56](https://cloud.githubusercontent.com/assets/1118459/22490211/f7a70418-e7bf-11e6-9bef-b3ccd715dbf8.png)](https://app.mailerlite.com/webforms/landing/l1d9x5)

- **Slack Room**: [Contact us](mailto:contact@shakacode.com) for an invite to the ShakaCode Slack room! Let us know if you want to contribute.
- **[forum.shakacode.com](https://forum.shakacode.com)**: Post your questions
- **[@railsonmaui on Twitter](https://twitter.com/railsonmaui)**
- For a live, [open source](https://github.com/shakacode/react-webpack-rails-tutorial), example of this gem, see [www.reactrails.com](http://www.reactrails.com).
- See [Projects](https://github.com/shakacode/react_on_rails/tree/master/PROJECTS.md) using and [KUDOS](https://github.com/shakacode/react_on_rails/tree/master/KUDOS.md) for React on Rails. Please submit yours! Please edit either page or [email us](mailto:contact@shakacode.com) and we'll add your info. We also **love stars** as it helps us attract new users and contributors.
- *See [NEWS.md](https://github.com/shakacode/react_on_rails/tree/master/NEWS.md) for more notes over time.*

## Contributing

Bug reports and pull requests are welcome. See [Contributing](https://github.com/shakacode/react_on_rails/tree/master/CONTRIBUTING.md) to get started, and the [list of help wanted issues](https://github.com/shakacode/react_on_rails/labels/contributions%3A%20up%20for%20grabs%21).

## React on Rails Pro

Support React on Rails Pro development [by becoming a Github sponsor](https://github.com/sponsors/shakacode) and get these benefits.

React on Rails Pro includes Node server rendering, fragment caching, code-splitting, and other performance enhancements for React on Rails. For a case study, see the article [HVMN’s 90% Reduction in Server Response Time from React on Rails Pro](https://www.shakacode.com/blog/hvmns-90-reduction-in-server-response-time-from-react-on-rails-pro/). The [Wiki](https://github.com/shakacode/react_on_rails/wiki) contains more details.

[![2018-09-11_10-31-11](https://user-images.githubusercontent.com/1118459/45467845-5bcc7400-b6bd-11e8-91e1-e0cf806d4ea4.png)](https://blog.shakacode.com/hvmns-90-reduction-in-server-response-time-from-react-on-rails-pro-eb08226687db)

The [React on Rails Pro Support Plan](https://www.shakacode.com/react-on-rails-pro) can help!

* Optimizing your webpack setup to the latest Webpack for React on Rails including code splitting with loadable-components.
* Upgrading your app to use the current `rails/webpacker` setup that skips the Sprockets asset pipeline.
* Better performance client and server side.
* Best practices based on over 6 years of React on Rails experience on many production projects.
* Using [Reason](https://reasonml.github.io/) with (or without) React on Rails.

ShakaCode can also help you with your custom software development needs. We specialize in marketplace and e-commerce applications that utilize both Rails and React. Because we own [HiChee.com](https://hichee.com), we can leverage that code for your app!

Please email Justin Gordon [justin@shakacode.com](mailto:justin@shakacode.com), the maintainer of React on Rails, for more information.

### Pro: Fragment Caching

Fragment caching is a [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro) feature. Fragment caching is a **HUGE** performance booster for your apps. Use the `cached_react_component` and `cached_react_component_hash`. The API is the same as `react_component` and `react_component_hash`, but for 2 differences:

1. The `cache_key` takes the same parameters as any Rails `cache` view helper.
1. The **props** are passed via a block so that evaluation of the props is not done unless the cache is broken. Suppose you put your props calculation into some method called `some_slow_method_that_returns_props`:

```ruby
<%= cached_react_component("App", cache_key: [@user, @post], prerender: true) do
  some_slow_method_that_returns_props
end %>
```

Such fragment caching saves CPU work for your web server and greatly reduces the request time. It completely skips the evaluation costs of:

1. Database calls to compute the props.
2. Serialization the props values hash into a JSON string for evaluating JavaScript to server render.
3. Costs associated with evaluating JavaScript from your Ruby code.
4. Creating the HTML string containing the props and the server-rendered JavaScript code.

Note, even without server rendering (without step 3 above), fragment caching is still effective.

### Pro: Integration with Node.js for Server Rendering

Default server rendering is done by ExecJS. If you want to use a Node.js server for better performing server rendering, [email justin@shakacode.com](mailto:justin@shakacode.com). ShakaCode has built a premium Node rendering server that is part of [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro).

## Testimonials for ShakaCode
[HVMN Testimonial, by Paul Benigeri, October 12, 2018](https://www.shakacode.com/react-on-rails/docs/testimonials/hvmn)
> The price we paid for the consultation + the React on Rails pro license has already been made back a couple of times from hosting fees alone. The entire process was super hands off, and our core team was able to focus on shipping new feature during that sprint.

[ResortPass Testimonial, by Leora Juster, December 10, 2018](https://www.shakacode.com/react-on-rails/docs/testimonials/resortpass)

> Justin and his team were instrumental in assisting us in setting design foundations and standards for our transition to a react on rails application. Just three months of work with the team at Shaka code and we have a main page of our application server-side rendering at exponentially improved speeds.

From Joel Hooks, Co-Founder, Chief Nerd at [egghead.io](https://egghead.io/), January 30, 2017:

![2017-01-30_11-33-59](https://cloud.githubusercontent.com/assets/1118459/22443635/b3549fb4-e6e3-11e6-8ea2-6f589dc93ed3.png)

For more testimonials, see [Live Projects](https://github.com/shakacode/react_on_rails/tree/master/PROJECTS.md) and [Kudos](https://github.com/shakacode/react_on_rails/tree/master/KUDOS.md).

# Supporters

The following companies support this open source project, and ShakaCode uses their products! Justin writes React on Rails on [RubyMine](https://www.jetbrains.com/ruby/). We use [Scout](https://scoutapp.com/) to monitor the live performance of [HiChee.com](https://HiChee.com), [Rails AutoScale](https://railsautoscale.com) to scale the dynos of HiChee, [BrowserStack](https://www.browserstack.com) to solve problems with oddball browsers.

[![2019-09-24_17-48-00](https://user-images.githubusercontent.com/1118459/65567887-96353780-def3-11e9-926d-4a55e2e186ff.png)](https://www.jetbrains.com/ruby/)
[![Scout](https://user-images.githubusercontent.com/1118459/41828269-106b40f8-77d0-11e8-8d19-9c4b167ef9d8.png)](https://scoutapp.com/)
[![2020-12-27_21-26-19](https://user-images.githubusercontent.com/1118459/103197530-48dc0e80-488a-11eb-8b1b-a16664b30274.png)](https://railsautoscale.com/)
[![BrowserStack](https://cloud.githubusercontent.com/assets/1118459/23203304/1261e468-f886-11e6-819e-93b1a3f17da4.png)](https://www.browserstack.com)


## Clubhouse
I've just moved ShakaCode's development to [ClubHouse](https://clubhouse.io/) from Trello. We're going to be doing this with all our projects. If you want to **try ClubHouse and get 2 months free beyond the 14-day trial period**, click [here to use ShakaCode's referral code](http://r.clbh.se/mvfoNeH). We're participating in their awesome triple-sided referral program, which you can read about [here](https://clubhouse.io/blog/clubhouse-referral-program-5f614bb437c3). By using our [referral code](http://r.clbh.se/mvfoNeH) you'll be supporting ShakaCode and, thus, React on Rails!

*If you'd like to support React on Rails and have your company listed here, [get in touch](mailto:justin@shakacode.com).*

Aloha and best wishes from Justin and the ShakaCode team!

# Work with Us
ShakaCode is **[currently looking to hire](http://www.shakacode.com/about/#work-with-us)** like-minded, remote-first, developers that wish to work on our projects, including [HiChee](https://hichee.com). Your main coding interview will be pairing with us on our open source! We're also using [ReasonML](https://reasonml.github.io/) extensively!

# License

The gem is available as open source under the terms of the [MIT License](https://github.com/shakacode/react_on_rails/tree/master/LICENSE.md).
