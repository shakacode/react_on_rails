![reactrails](https://user-images.githubusercontent.com/10421828/79436261-52159b80-7fd9-11ea-994e-2a98dd43e540.png)

<p align="center">
 <a href="https://shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436256-517d0500-7fd9-11ea-9300-dfbc7c293f26.png"></a>
 <a href="https://forum.shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436266-53df5f00-7fd9-11ea-94b3-b985e1b05bdc.png"></a>
 <a href="https://www.shakacode.com/react-on-rails-pro"><img src="https://user-images.githubusercontent.com/10421828/79436265-53df5f00-7fd9-11ea-8220-fc474f6a856c.png"></a>
 <a href="https://github.com/sponsors/shakacode"><img src="https://user-images.githubusercontent.com/10421828/79466109-cdd90d80-8004-11ea-88e5-25f9a9ddcf44.png"></a>
</p>

---

[![License](https://img.shields.io/badge/license-mit-green.svg)](LICENSE.md) [![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails) [![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Code Climate](https://codeclimate.com/github/shakacode/react_on_rails/badges/gpa.svg)](https://codeclimate.com/github/shakacode/react_on_rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master) [![](https://ruby-gem-downloads-badge.herokuapp.com/react_on_rails?type=total)](https://rubygems.org/gems/react_on_rails)

# React and Webpack with Ruby on Rails
The current version of https://github.com/rails/webpacker will soon ship. While it won't be the default for Rails 7, it is not "deprecated." The core webpack configuration has become slimmer, allowing easier extension. If you want to get started today, use the master branch of  [shakacode/react_on_rails_tutorial_with_ssr_and_hmr_fast_refresh](https://github.com/shakacode/react_on_rails_tutorial_with_ssr_and_hmr_fast_refresh) with `gem "webpacker", "6.0.0.rc.6"` Any updates to get to v6 from this point forward should be simple.

If you have time, please comment on Justin's final proposals for Webpacker v6: [webpacker/pulls/justin808](https://github.com/rails/webpacker/pulls/justin808).

-----

*These are the docs for React on Rails 12. To see the version 11 docs, [click here](https://github.com/shakacode/react_on_rails/tree/11.3.0).*

#### About
React on Rails integrates Rails with (server rendering of) Facebook's [React](https://github.com/facebook/react) front-end framework.

This project is maintained by the software consulting firm [ShakaCode](https://www.shakacode.com). We focus on Ruby on Rails applications with React front-ends, often using TypeScript or ReScript (ReasonML). We also build React Native apps and Gatsby sites. See [our recent work](https://www.shakacode.com/recent-work) for examples of what we do. ShakaCode.com (HiChee.com) is [hiring developers that like working on open-source](https://www.shakacode.com/career/).

Are you interested in optimizing your webpack setup for React on Rails including code
splitting with [react-router](https://github.com/ReactTraining/react-router#readme) and
 [loadable-components](https://loadable-components.com/) with server-side rendering for SEO and hot-reloading for developers?
We did this for Popmenu, [lowering Heroku costs 20-25% while getting a 73% decrease in average response times](https://www.shakacode.com/recent-work/popmenu/). Check out [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/).

For more information, feel free to contact Justin Gordon, [justin@shakacode.com](mailto:justin@shakacode.com), maintainer of React on Rails.

# Documentation

See the documentation at [shakacode.com/react-on-rails/docs](https://www.shakacode.com/react-on-rails/docs/).

## Project Objective

To provide a high performance framework for integrating Ruby on Rails with React via the [**Webpacker**](https://github.com/rails/webpacker) gem, especially regarding React Server-Side Rendering for better SEO and improved performance.

## Features and Why React on Rails?

Given that `rails/webpacker` gem already provides basic React integration, why would you use "React on Rails"?

1. Easy passing of props directly from your Rails view to your React components rather than having your Rails view load and then make a separate request to your API.
1. Tight integration with [rails/webpacker](https://github.com/rails/webpacker).
1. Server-Side Rendering (SSR), often used for SEO crawler indexing and UX performance, is not offered by `rails/webpacker`.
1. [Redux](https://github.com/reactjs/redux) and [React Router](https://github.com/ReactTraining/react-router#readme) integration with server-side-rendering.
1. [Internationalization (I18n) and (localization)](https://www.shakacode.com/react-on-rails/docs/guides/i18n)
1. A supportive community. This [web search shows how live public sites are using React on Rails](https://publicwww.com/websites/%22react-on-rails%22++-undeveloped.com+depth%3Aall/).
1. [Reason ML Support](https://github.com/shakacode/reason-react-on-rails-example).

See [Rails/Webpacker React Integration Options](https://www.shakacode.com/react-on-rails/docs/guides/rails-webpacker-react-integration-options) for comparisons to other gems.

See the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) for an example of a live implementation and code.

## Online demo

A deployed version of the project `spec/dummy` which demonstrates several uses of `react_on_rails` is available on heroku [through this link](https://ror-spec-dummy.herokuapp.com/)

## ShakaCode Forum Premium Content
_Requires creating a free account._

* [How to use different versions of a file for client and server rendering](https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352)
* [How to conditionally render server side based on the device type](https://forum.shakacode.com/t/how-to-conditionally-render-server-side-based-on-the-device-type/1473)


## Prerequisites

Ruby on Rails >=5 and rails/webpacker 4.2+.

# Support

* [Click to join **React + Rails Slack**](https://reactrails.slack.com/join/shared_invite/enQtNjY3NTczMjczNzYxLTlmYjdiZmY3MTVlMzU2YWE0OWM0MzNiZDI0MzdkZGFiZTFkYTFkOGVjODBmOWEyYWQ3MzA2NGE1YWJjNmVlMGE).
- [**Subscribe**](https://app.mailerlite.com/webforms/landing/l1d9x5) for announcements of new releases of React on Rails and of our latest [blog articles](https://blog.shakacode.com) and tutorials.
- **[forum.shakacode.com](https://forum.shakacode.com)**: Post your questions
- **[@railsonmaui on Twitter](https://twitter.com/railsonmaui)**
- *See [NEWS.md](https://github.com/shakacode/react_on_rails/tree/master/NEWS.md) for more notes over time.*
- See [Projects](https://github.com/shakacode/react_on_rails/tree/master/PROJECTS.md) using and [KUDOS](https://github.com/shakacode/react_on_rails/tree/master/KUDOS.md) for React on Rails. Please submit yours! Please edit either page or [email us](mailto:contact@shakacode.com) and we'll add your info. We also **love stars** as it helps us attract new users and contributors.
- *See [NEWS.md](https://github.com/shakacode/react_on_rails/tree/master/NEWS.md) for more notes over time.*

## Contributing

Bug reports and pull requests are welcome. See [Contributing](https://github.com/shakacode/react_on_rails/tree/master/CONTRIBUTING.md) to get started, and the [list of help wanted issues](https://github.com/shakacode/react_on_rails/labels/contributions%3A%20up%20for%20grabs%21).

# Supporters

The following companies support this open source project, and ShakaCode uses their products! Justin writes React on Rails on [RubyMine](https://www.jetbrains.com/ruby/). We use [Scout](https://scoutapp.com/) to monitor the live performance of [HiChee.com](https://HiChee.com), [Rails AutoScale](https://railsautoscale.com) to scale the dynos of HiChee, and [HoneyBadger](https://www.honeybadger.io/) to monitor application errors. We love [BrowserStack](https://www.browserstack.com) to solve problems with oddball browsers. [Status Hero](https://statushero.com/) keeps the team posted on daily progress; it's so much better than live standups.

[![RubyMine](https://user-images.githubusercontent.com/1118459/114100597-3b0e3000-9860-11eb-9b12-73beb1a184b2.png)](https://www.jetbrains.com/ruby/)
[![Scout](https://user-images.githubusercontent.com/1118459/41828269-106b40f8-77d0-11e8-8d19-9c4b167ef9d8.png)](https://scoutapp.com/)
[![Rails AutoScale](https://user-images.githubusercontent.com/1118459/103197530-48dc0e80-488a-11eb-8b1b-a16664b30274.png)](https://railsautoscale.com/)
[![BrowserStack](https://cloud.githubusercontent.com/assets/1118459/23203304/1261e468-f886-11e6-819e-93b1a3f17da4.png)](https://www.browserstack.com)
[![HoneyBadger](https://user-images.githubusercontent.com/1118459/114100696-63962a00-9860-11eb-8ac1-75ca02856d8e.png)](https://www.honeybadger.io/)
[![StatusHero](https://user-images.githubusercontent.com/1118459/126868048-3fe64e54-4d6d-4066-9df2-8cf6fbaeb314.png)](https://statushero.com/)

ShakaCode's favorite project tracking tool is [Shortcut](https://shortcut.com/). If you want to **try Shortcut and get 2 months free beyond the 14-day trial period**, click [here to use ShakaCode's referral code](http://r.clbh.se/mvfoNeH). We're participating in their awesome triple-sided referral program, which you can read about [here](https://clubhouse.io/referral/). By using our [referral code](http://r.clbh.se/mvfoNeH) you'll be supporting ShakaCode and, thus, React on Rails!

Aloha and best wishes from Justin and the ShakaCode team!

# Work with Us
ShakaCode is **[hiring passionate software engineers](http://www.shakacode.com/career)** to work on our projects, including [HiChee](https://hichee.com)!

# License

The gem is available as open source under the terms of the [MIT License](https://github.com/shakacode/react_on_rails/tree/master/LICENSE.md).
