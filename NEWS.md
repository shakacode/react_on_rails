# NEWS

_A history of the news. A few bullets at the top will also show on the [README.md](./README.md)._

- **October 14, 2020**: [RUBY ROGUES
  RR 474: React on Rails V12 – Don’t Shave That Yak! with Justin Gordon](https://devchat.tv/ruby-rogues/rr-474-react-on-rails-v12-dont-shave-that-yak-with-justin-gordon/).

- **October 1, 2020**: See the [spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy) example repo for a simple configuration of Webpack via the rails/webpacker gem
  that supports SSR.
- **August 2, 2020**: See the example repo of [React on Rails Tutorial With SSR, HMR fast refresh, and TypeScript](https://github.com/shakacode/react_on_rails_demo_ssr_hmr) for a new way to set up the creation of your SSR bundle with `rails/webpacker`.
- July 8, 2020: Release **v12**.
  1. **React Hooks Support** for top level components
  2. **Typescript bindings**
  3. **rails/webpacker** "just works" with React on Rails by default.
  4. i18n support for generating a JSON file rather than a JS file.
- 2018-02-27: **Version 10.1.2** Supports the React API for ReactDOM.hydrate.
- 2017-09-06: **VERSION 9.0.0 shipped!** This version depends on Webpacker directly. See [Upgrading React on Rails](./docs/guides/upgrading-react-on-rails.md) for more concise instructions on upgrading.
- Always see the [CHANGELOG.md](./CHANGELOG.md) for the latest project changes.
- [VERSION 8.1.0](https://rubygems.org/gems/react_on_rails/) shipped with [webpacker_lite](https://github.com/shakacode/webpacker_lite) (soon [**webpacker**](https://github.com/rails/webpacker/issues/464#issuecomment-310986140) support! [react-webpack-rails-tutorial PR #395](https://github.com/shakacode/react-webpack-rails-tutorial/pull/395) shows the changes needed to migrate from the Asset Pipeline to Webpacker Lite. For more information, see my article: [Webpacker Lite: Why Fork Webpacker?](https://blog.shakacode.com/webpacker-lite-why-fork-webpacker-f0a7707fac92). Per recent discussions, we [will merge Webpacker Lite changes back into Webpacker](https://github.com/rails/webpacker/issues/464#issuecomment-310986140). There's no reason to wait for this. The upgrade will eventually be trivial.
- 2017-04-25: 7.0.0 Shipped! Performance improvements! Please upgrade! Only "breaking" change is that you have to update both the node module and the Ruby gem.
- 2017-04-09: 8.0.0 beta work to include webpacker_lite gem has begun. See [#786](https://github.com/shakacode/react_on_rails/issues/786).
- 2017-04-03: 6.9.3 Released! Props rendered in JSON script tag. Page size is smaller now due to less escaping!
- 2017-03-06: Updated to Webpack v2!
- 2017-03-02: Demo of internationalization (i18n) is live at [reactrails.com](https://www.reactrails.com/). Docs [here](docs/guides/i18n.md).
- 2017-02-28: See [discussions here on Webpacker](https://github.com/rails/webpacker/issues/139) regarding how Webpacker will allow React on Rails to avoid using the asset pipeline in the near future.
- 2017-02-28: Upgrade to Webpack v2 or use the `--bail` option in your Webpack script for test and production builds. See the discussion on [PR #730](https://github.com/shakacode/react_on_rails/pull/730).
- 2016-11-03: Spoke at [LA Ruby: "React on Rails: Why, What, and How?"](http://www.meetup.com/laruby/events/234825187/). [Video and pictures in this article](https://blog.shakacode.com/my-react-on-rails-talk-at-the-la-ruby-rails-meetup-november-10-2016-eaaa83aff800#.ej6h4eglp).
- 2016-12-20: New Video on Egghead.io: [Creating a component with React on Rails](https://egghead.io/lessons/react-creating-a-component-with-react-on-rails)
- 2016-11-03: Spoke at [LA Ruby, 7pm, Thursday, November 10 in Venice, CA: "React on Rails: Why, What, and How?"](http://www.meetup.com/laruby/events/234825187/). [Video and pictures in this article](https://blog.shakacode.com/my-react-on-rails-talk-at-the-la-ruby-rails-meetup-november-10-2016-eaaa83aff800#.ej6h4eglp).
- 2016-08-27: We now have a [Documentation Gitbook](https://shakacode.gitbooks.io/react-on-rails/content/) for improved readability & reference.
- 2016-08-21: v6.1 ships with several new features and bug fixes. See the [Changelog](CHANGELOG.md).
- 2016-07-28: If you're doing server rendering, be sure to use mini_racer! See [issues/428](https://github.com/shakacode/react_on_rails/issues/428). It's supposedly much faster than `therubyracer`.

- 2016-08-27: We now have a [Documentation Gitbook](https://shakacode.gitbooks.io/react-on-rails/content/) for improved readability & reference.
- 2016-08-21: v6.1 ships with several new features and bug fixes. See the [Changelog](CHANGELOG.md).
- 2016-06-13: 6.0.4 shipped with a critical fix regarding a missing polyfill for `clearTimeout`, used by babel-polyfill.
- 2016-06-06: 6.0.2 shipped with a critical fix if you are fragment caching the server generated React.
- 2016-05-24: 6.0.0 Released! Simplified generator and install process! See the [CHANGELOG.md](./CHANGELOG.md) for details.
- 2016-04-08: 5.2.0 Released! Support for React 15.0 and updates to the Generator.
- 2016-03-18: [Slides on React on Rails](http://www.slideshare.net/justingordon/react-on-rails-v4032).
- 2016-03-17: **4.0.3** Shipped! Includes using the new Heroku buildpack steps, several smaller changes detailed in the [CHANGELOG.md](./CHANGELOG.md).
- 2016-03-17: **4.0.2** Shipped! Includes using the new Heroku buildpack steps.
  - Better support for hot reloading of assets from Rails with new helpers and updates to the sample testing app, [spec/dummy](spec/dummy).
  - Better support for Turbolinks 5.
  - Controller rendering of shared Redux stores and ability to render store data at bottom of HTML page.
  - See [#311](https://github.com/shakacode/react_on_rails/pull/311/files).
  - Some breaking changes! See [CHANGELOG.md](./CHANGELOG.md) for details.
- 2016-02-28: We added a [Projects page](PROJECTS.md). Please edit the page your project or [email us](mailto:contact@shakacode.com) and we'll add you. We also love stars as it helps us attract new users and contributors. [jbhatab](https://github.com/jbhatab) is leading an effort to ease the onboarding process for newbies with simpler project generators. See [#245](https://github.com/shakacode/react_on_rails/issues/245).
- 3.0.6 shipped on Tuesday, 2016-03-01. Please see the [Changelog](CHANGELOG.md) for details, and let us know if you see any issues! [Migration steps from 1.x](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md#migration-steps-v1-to-v2). [Migration steps from 2.x](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md#migration-steps-v2-to-v3).
  - [RubyGems](https://rubygems.org/gems/react_on_rails/)
  - [NPM](https://www.npmjs.com/package/react-on-rails)
- 3.0.0 Highlights:
  1. Support for ensuring JavaScript is current when running tests.
  2. Support for multiple React components with one Redux store. So you can have a header React component and different body React components talking to the same Redux store!
  3. Support for Turbolinks 5!
- There was a fatal error when using the latest version of Redux for server rendering. See [Redux #1335](https://github.com/reactjs/redux/issues/1335). See [diff 3.1.6...3.1.4](https://github.com/reactjs/redux/commit/e2e14d26f09ca729ae0555442f50fcfc45bfb423#diff-1fdf421c05c1140f6d71444ea2b27638). Workaround for server rendering: Use Redux 3.1.7 or upgrade to React On Rails v2.3.0. [this commit](https://github.com/shakacode/react_on_rails/commit/59f1e68d3d233775e6abc63bff180ea59ac2d79e) on [PR #244](https://github.com/shakacode/react_on_rails/pull/244/).
- 2.x Highlights:
  1. Fixed a **critical** problem with TurboLinks. Be sure to see [turbolinks docs](docs/additional-reading/turbolinks.md) for more information on how to debug TurboLinks issues.
  2. Provides a convenient helper to ensure that JavaScript assets are compiled before running tests.
- React on Rails does not yet have _generator_ support for building new apps that use CSS modules and hot reloading via the Rails server as is demonstrated in the [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/). _We do support this, but we don't generate the code._ If you did generate a fresh app from react_on_rails and want to move to CSS Modules, then see [PR 175: Babel 6 / CSS Modules / Rails hot reloading](https://github.com/shakacode/react-webpack-rails-tutorial/pull/175). Note, while there are probably fixes after this PR was accepted, this has the majority of the changes. See [the tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/#news) for more information. Ping us if you want to help!
- [ShakaCode](http://www.shakacode.com) is doing Skype plus Slack/GitHub based coaching for "React on Rails". [Click here](http://www.shakacode.com/work/index.html) for more information.
- Be sure to read our article [The React on Rails Doctrine](https://medium.com/@railsonmaui/the-react-on-rails-doctrine-3c59a778c724).
