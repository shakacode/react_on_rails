# NEWS

*We'll keep a history of the news. A few bullets at the top will also show on the [README.md](./README.md).*

* Always see the [CHANGELOG.md](./CHANGELOG.md) for the latest project changes.
* 2016-03-17: **4.0.2** Shipped! Includes using the new Heroku buildpack steps.
  * Better support for hot reloading of assets from Rails with new helpers and updates to the sample testing app, [spec/dummy](spec/dummy).
  * Better support for Turbolinks 5.
  * Controller rendering of shared redux stores and ability to render store data at bottom of HTML page.
  * See [#311](https://github.com/shakacode/react_on_rails/pull/311/files).
  * Some breaking changes! See [CHANGELOG.md](./CHANGELOG.md) for details.
* 2016-02-28: We added a [Projects page](PROJECTS.md). Please edit the page your project or [email us](mailto:contact@shakacode.com) and we'll add you. We also love stars as it helps us attract new users and contributors. [jbhatab](https://github.com/jbhatab) is leading an effort to ease the onboarding process for newbies with simpler project generators. See [#245](https://github.com/shakacode/react_on_rails/issues/245).
* 3.0.6 shipped on Tuesday, 2016-03-01. Please see the [Changelog](CHANGELOG.md) for details, and let us know if you see any issues! [Migration steps from 1.x](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md#migration-steps-v1-to-v2). [Migration steps from 2.x](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md#migration-steps-v2-to-v3).
  * [RubyGems](https://rubygems.org/gems/react_on_rails/)
  * [NPM](https://www.npmjs.com/package/react-on-rails)
* 3.0.0 Highlights:
  1. Support for ensuring JavaScript is current when running tests.
  2. Support for multiple React components with one Redux store. So you can have a header React component and different body React components talking to the same Redux store!
  3. Support for Turbolinks 5!
* There was a fatal error when using the lastest version of Redux for server rendering. See [Redux #1335](https://github.com/reactjs/redux/issues/1335). See [diff 3.1.6...3.1.4](https://github.com/reactjs/redux/commit/e2e14d26f09ca729ae0555442f50fcfc45bfb423#diff-1fdf421c05c1140f6d71444ea2b27638). Workaround for server rendering: Use Redux 3.1.7 or upgrade to React On Rails v2.3.0. [this commit](https://github.com/shakacode/react_on_rails/commit/59f1e68d3d233775e6abc63bff180ea59ac2d79e) on [PR #244](https://github.com/shakacode/react_on_rails/pull/244/).
* 2.x Highlights:
  1. Fixed a **critical** problem with TurboLinks. Be sure to see [turbolinks docs](docs/additional_reading/turbolinks.md) for more information on how to debug TurboLinks issues.
  2. Provides a convenient helper to ensure that JavaScript assets are compiled before running tests.
* React on Rails does not yet have *generator* support for building new apps that use CSS modules and hot reloading via the Rails server as is demonstrated in the [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/). *We do support this, but we don't generate the code.* If you did generate a fresh app from react_on_rails and want to move to CSS Modules, then see [PR 175: Babel 6 / CSS Modules / Rails hot reloading](https://github.com/shakacode/react-webpack-rails-tutorial/pull/175). Note, while there are probably fixes after this PR was accepted, this has the majority of the changes. See [the tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/#news) for more information. Ping us if you want to help!
* [ShakaCode](http://www.shakacode.com) is doing Skype plus Slack/Github based coaching for "React on Rails". [Click here](http://www.shakacode.com/work/index.html) for more information.
* Be sure to read our article [The React on Rails Doctrine](https://medium.com/@railsonmaui/the-react-on-rails-doctrine-3c59a778c724).

