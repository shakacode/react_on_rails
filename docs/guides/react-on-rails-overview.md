# React on Rails

React on Rails integrates Rails with (server rendering of) Facebook's [React](https://github.com/facebook/react) front-end framework.

---

# Project Objective

To provide a high performance framework for integrating Ruby on Rails with React via the [**Webpacker**](https://github.com/rails/webpacker) gem especially in regards to React Server-Side Rendering for better SEO and improved performance.

# Features and Why React on Rails?

Given that [`rails/webpacker`](https://github.com/rails/webpacker/) gem already provides basic React integration, why would you use "React on Rails"?

1. Easy passing of props directly from your Rails view to your React components rather than having your Rails view load and then make a separate request to your API.
1. Tight integration with [rails/webpacker](https://github.com/rails/webpacker).
1. Server-Side Rendering (SSR), often used for SEO crawler indexing and UX performance, is not offered by `rails/webpacker`.
1. Support for HMR for a great developer experience.
1. Supports latest versions of React with hooks.
1. [Redux](https://github.com/reactjs/redux) and [React Router](https://github.com/ReactTraining/react-router#readme) integration including server-side-rendering.
1. [Internationalization (I18n) and (localization)](https://www.shakacode.com/react-on-rails/docs/guides/i18n/)
1. A supportive community. This [web search shows how live public sites are using React on Rails](https://publicwww.com/websites/%22react-on-rails%22++-undeveloped.com+depth%3Aall/).
1. [ReScript (Reason ML) Support](https://github.com/shakacode/reason-react-on-rails-example).

See the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) for an example of a live implementation and code.
----

## Prerequisites

Ruby on Rails >=5 and rails/webpacker 4.2+.
