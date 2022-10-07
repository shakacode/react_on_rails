![reactrails](https://user-images.githubusercontent.com/10421828/79436261-52159b80-7fd9-11ea-994e-2a98dd43e540.png)

<p align="center">
 <a href="https://shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436256-517d0500-7fd9-11ea-9300-dfbc7c293f26.png"></a>
 <a href="https://forum.shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436266-53df5f00-7fd9-11ea-94b3-b985e1b05bdc.png"></a>
 <a href="https://www.shakacode.com/react-on-rails-pro"><img src="https://user-images.githubusercontent.com/10421828/79436265-53df5f00-7fd9-11ea-8220-fc474f6a856c.png"></a>
 <a href="https://github.com/sponsors/shakacode"><img src="https://user-images.githubusercontent.com/10421828/79466109-cdd90d80-8004-11ea-88e5-25f9a9ddcf44.png"></a>
</p>

---

[![License](https://img.shields.io/badge/license-mit-green.svg)](LICENSE.md)[![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Code Climate](https://codeclimate.com/github/shakacode/react_on_rails/badges/gpa.svg)](https://codeclimate.com/github/shakacode/react_on_rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master) [![](https://ruby-gem-downloads-badge.herokuapp.com/react_on_rails?type=total)](https://rubygems.org/gems/react_on_rails)

[![Build Main](https://github.com/shakacode/react_on_rails/actions/workflows/main.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/main.yml)
[![Build JS Tests](https://github.com/shakacode/react_on_rails/actions/workflows/package-js-tests.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/package-js-tests.yml)
[![Build Rspec Tests](https://github.com/shakacode/react_on_rails/actions/workflows/rspec-package-specs.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/rspec-package-specs.yml)
[![Linting](https://github.com/shakacode/react_on_rails/actions/workflows/lint-js-and-ruby.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/lint-js-and-ruby.yml)

# News
* ShakaCode now maintains the official successor to `rails/webpacker`, [`shakapacker`](https://github.com/shakacode/shakapacker).
* Project is updated to support Rails 7 and Shakapacker v6+!

-----

*These are the docs for React on Rails 13. To see the older docs: [v12](https://github.com/shakacode/react_on_rails/tree/12.6.0) and [v11](https://github.com/shakacode/react_on_rails/tree/11.3.0).*

#### About
React on Rails integrates Rails with (server rendering of) Facebook's [React](https://github.com/facebook/react) front-end framework.

This project is maintained by the software consulting firm [ShakaCode](https://www.shakacode.com). We focus on Ruby on Rails applications with React front-ends, often using TypeScript or ReScript (ReasonML). We also build React Native apps and Gatsby sites. See [our recent work](https://www.shakacode.com/recent-work) for examples of what we do. ShakaCode.com (HiChee.com) is [hiring developers that like working on open-source](https://www.shakacode.com/career/).

Are you interested in optimizing your webpack setup for React on Rails including code
splitting with [react-router](https://github.com/ReactTraining/react-router#readme) and
 [loadable-components](https://loadable-components.com/) with server-side rendering for SEO and hot-reloading for developers?
We did this for Popmenu, [lowering Heroku costs 20-25% while getting a 73% decrease in average response times](https://www.shakacode.com/recent-work/popmenu/). Several years later, Popmenu is serving millions of SSR requests per day with React on Rails.

Check out [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/). For more information, feel free to contact Justin Gordon, [justin@shakacode.com](mailto:justin@shakacode.com), maintainer of React on Rails.

# Documentation

See the documentation at **[shakacode.com/react-on-rails/docs](https://www.shakacode.com/react-on-rails/docs/)**.

## Project Objective

To provide a high performance framework for integrating Ruby on Rails with React via the [**Webpacker**](https://github.com/rails/webpacker) gem, especially regarding React Server-Side Rendering for better SEO and improved performance.

## Features and Why React on Rails?

Given that `rails/webpacker` gem already provides basic React integration, why would you use "React on Rails"?

1. Automatic configuration of what bundles are added to the page based on what React components are on the page. This results in faster browser loading time via smaller bundle sizes.
1. Keep up with the latest changes of different versions of React. React 18 is supported.
1. Easy passing of props directly from your Rails view to your React components rather than having your Rails view load and then make a separate request to your API.
Tight integration with [shakapacker](https://github.com/shakacode/shakapacker) (or it's predecessor [rails/webpacker](https://github.com/rails/webpacker)).
1. Server-Side Rendering (SSR), often used for SEO crawler indexing and UX performance.
1. [Automated optimized entry-point creation and bundle inclusion when placing a component on a page. With this feature, you no longer need to configure `javascript_pack_tags` and `stylesheet_pack_tags` on your layouts based on what’s shown. “It just works!”](https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md)
1. [Redux](https://github.com/reactjs/redux) and [React Router](https://github.com/ReactTraining/react-router#readme) integration with server-side-rendering.
1. [Internationalization (I18n) and (localization)](https://www.shakacode.com/react-on-rails/docs/guides/i18n)
1. A supportive community. This [web search shows how live public sites are using React on Rails](https://publicwww.com/websites/%22react-on-rails%22++-undeveloped.com+depth%3Aall/).
1. [ReScript Support](https://github.com/shakacode/rescript-react-on-rails-example).

See [Rails/Webpacker React Integration Options](https://www.shakacode.com/react-on-rails/docs/guides/rails-webpacker-react-integration-options) for comparisons to other gems.

## Online demo
* See the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) for an example of a live implementation and code.
* A deployed version of the project `spec/dummy` which demonstrates several uses of `react_on_rails` is available on heroku [through this link](https://ror-spec-dummy.herokuapp.com/)

## ShakaCode Forum Premium Content
_Requires creating a free account._

* [How to use different versions of a file for client and server rendering](https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352)
* [How to conditionally render server side based on the device type](https://forum.shakacode.com/t/how-to-conditionally-render-server-side-based-on-the-device-type/1473)

## Prerequisites

Ruby on Rails >=5, rails/webpacker >= 4.2 or shakapacker > 6, Ruby >= 2.7

# Support

* [Click to join **React + Rails Slack**](https://reactrails.slack.com/join/shared_invite/enQtNjY3NTczMjczNzYxLTlmYjdiZmY3MTVlMzU2YWE0OWM0MzNiZDI0MzdkZGFiZTFkYTFkOGVjODBmOWEyYWQ3MzA2NGE1YWJjNmVlMGE).
- [**Subscribe**](https://app.mailerlite.com/webforms/landing/l1d9x5) for announcements of new releases of React on Rails and of our latest [blog articles](https://blog.shakacode.com) and tutorials.
- [Discussions](https://github.com/shakacode/react_on_rails/discussions): Post your questions regarding React on Rails
- **[forum.shakacode.com](https://forum.shakacode.com)**: Other discussions
- **[@railsonmaui on Twitter](https://twitter.com/railsonmaui)**
- *See [NEWS.md](https://github.com/shakacode/react_on_rails/tree/master/NEWS.md) for more notes over time.*
- See [Projects](https://github.com/shakacode/react_on_rails/tree/master/PROJECTS.md) using and [KUDOS](https://github.com/shakacode/react_on_rails/tree/master/KUDOS.md) for React on Rails. Please submit yours! Please edit either page or [email us](mailto:contact@shakacode.com) and we'll add your info. We also **love stars** as it helps us attract new users and contributors.

## Contributing

Bug reports and pull requests are welcome. See [Contributing](https://github.com/shakacode/react_on_rails/tree/master/CONTRIBUTING.md) to get started, and the [list of help wanted issues](https://github.com/shakacode/react_on_rails/labels/contributions%3A%20up%20for%20grabs%21).

# Work with Us
ShakaCode is **[hiring passionate software engineers](http://www.shakacode.com/career)** to work on our projects, including [HiChee](https://hichee.com)!

# License

The gem is available as open source under the terms of the [MIT License](https://github.com/shakacode/react_on_rails/tree/master/LICENSE.md).

# Supporters

<a href="https://www.jetbrains.com">
  <img src="https://user-images.githubusercontent.com/4244251/184881139-42e4076b-024b-4b30-8c60-c3cd0e758c0a.png" alt="JetBrains" height="120px">
</a>
<a href="https://scoutapp.com">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://user-images.githubusercontent.com/4244251/184881147-0d077438-3978-40da-ace9-4f650d2efe2e.png">
    <source media="(prefers-color-scheme: light)" srcset="https://user-images.githubusercontent.com/4244251/184881152-9f2d8fba-88ac-4ba6-873b-22387f8711c5.png">
    <img alt="ScoutAPM" src="https://user-images.githubusercontent.com/4244251/184881152-9f2d8fba-88ac-4ba6-873b-22387f8711c5.png" height="120px">
  </picture>
</a>
<br />
<a href="https://www.browserstack.com">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://user-images.githubusercontent.com/4244251/184881122-407dcc29-df78-4b20-a9ad-f597b56f6cdb.png">
    <source media="(prefers-color-scheme: light)" srcset="https://user-images.githubusercontent.com/4244251/184881129-e1edf4b7-3ae1-4ea8-9e6d-3595cf01609e.png">
    <img alt="BrowserStack" src="https://user-images.githubusercontent.com/4244251/184881129-e1edf4b7-3ae1-4ea8-9e6d-3595cf01609e.png" height="55px">
  </picture>
</a>
<a href="https://railsautoscale.com">
  <img src="https://user-images.githubusercontent.com/4244251/184881144-95c2c25c-9879-4069-864d-4e67d6ed39d2.png" alt="Rails Autoscale" height="55px">
</a>
<a href="https://www.honeybadger.io">
  <img src="https://user-images.githubusercontent.com/4244251/184881133-79ee9c3c-8165-4852-958e-31687b9536f4.png" alt="Honeybadger" height="55px">
</a>

<br />
<br />

The following companies support our open source projects, and ShakaCode uses their products!
