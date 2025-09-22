![reactrails](https://user-images.githubusercontent.com/10421828/79436261-52159b80-7fd9-11ea-994e-2a98dd43e540.png)

<p align="center">
 <a href="https://shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436256-517d0500-7fd9-11ea-9300-dfbc7c293f26.png"></a>
 <a href="https://forum.shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436266-53df5f00-7fd9-11ea-94b3-b985e1b05bdc.png"></a>
 <a href="https://www.shakacode.com/react-on-rails-pro"><img src="https://user-images.githubusercontent.com/10421828/79436265-53df5f00-7fd9-11ea-8220-fc474f6a856c.png"></a>
 <a href="https://github.com/sponsors/shakacode"><img src="https://user-images.githubusercontent.com/10421828/79466109-cdd90d80-8004-11ea-88e5-25f9a9ddcf44.png"></a>
</p>

---

[![License](https://img.shields.io/badge/license-mit-green.svg)](LICENSE.md)[![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master) [![](https://ruby-gem-downloads-badge.herokuapp.com/react_on_rails?type=total)](https://rubygems.org/gems/react_on_rails)

[![Build Main](https://github.com/shakacode/react_on_rails/actions/workflows/main.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/main.yml)
[![Build JS Tests](https://github.com/shakacode/react_on_rails/actions/workflows/package-js-tests.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/package-js-tests.yml)
[![Build Rspec Tests](https://github.com/shakacode/react_on_rails/actions/workflows/rspec-package-specs.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/rspec-package-specs.yml)
[![Linting](https://github.com/shakacode/react_on_rails/actions/workflows/lint-js-and-ruby.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/lint-js-and-ruby.yml)

# News

**🚀 React on Rails v16.0 Released!** Major modernization with ESM support, enhanced React Server Components, and streamlined configuration.

- **ESM-only package**: Modern module system with better tree-shaking and performance
- **React Server Components**: Improved rendering flow and new `RSCRoute` component for seamless SSR
- **Performance improvements**: New async loading strategies and optimized bundle generation
- **Webpacker removal**: Streamlined for Shakapacker-only support (>= 6.0)
- [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/) supports the latest features of React 18, including [React Server Components](https://react.dev/reference/rsc/server-components) and [streaming](https://react.dev/reference/react-dom/server/renderToPipeableStream). Contact [Justin Gordon](mailto:justin@shakacode.com) for more information.
- ShakaCode now maintains the official successor to `rails/webpacker`, [`shakapacker`](https://github.com/shakacode/shakapacker).

---

_These are the docs for React on Rails 16. To see the older docs and code: [v14](https://github.com/shakacode/react_on_rails/tree/14.0.0), [v13](https://github.com/shakacode/react_on_rails/tree/13.4.0), [v12](https://github.com/shakacode/react_on_rails/tree/12.6.0), and [v11](https://github.com/shakacode/react_on_rails/tree/11.3.0)._

# About

React on Rails integrates Rails with (server rendering of) [React](https://github.com/facebook/react).

This project is maintained by [ShakaCode](https://www.shakacode.com).

## ShakaCode Upgrade Support

ShakaCode focuses on helping Ruby on Rails teams better use React and Webpack. We can upgrade your project and improve your development and customer experiences, allowing you to focus on building new features or fixing bugs instead.

For an overview of working with us, see our [Client Engagement Model](https://www.shakacode.com/blog/client-engagement-model/) article and [how we bill for time](https://www.shakacode.com/blog/shortcut-jira-trello-github-toggl-time-and-task-tracking/).

We also specialize in helping development teams lower infrastructure and CI costs. Check out our project [Control Plane Flow](https://github.com/shakacode/control-plane-flow/), which can allow you to get the ease of Heroku with the power of Kubernetes and big cost savings.

If you think ShakaCode can help your project, [click here](https://meetings.hubspot.com/justingordon/30-minute-consultation) to book a call with [Justin Gordon](mailto:justin@shakacode.com), the creator of React on Rails.

## Upgrading React on Rails

After upgrading to a new major version, run the generator to get latest defaults:

```bash
rails generate react_on_rails:install
```

**Important**: Review changes carefully before applying to avoid overwriting custom configurations. The generator updates:

- `bin/dev` (improved development workflow)
- webpack configurations
- `shakapacker.yml` settings
- other configuration files

### Troubleshooting Setup Issues

If you encounter issues during installation or after upgrading, use the doctor command to diagnose your setup:

```bash
rake react_on_rails:doctor
```

The doctor command checks your environment, dependencies, and configuration files to identify potential issues. Use `VERBOSE=true rake react_on_rails:doctor` for detailed output.

For detailed upgrade instructions, see [upgrade guide documentation](docs/guides/upgrading-react-on-rails.md).

## React on Rails Pro

Some features of React on Rails regarding performance require a React on Rails Pro subscription.

Note: the subscription price is free for evaluation and non-production use.

Notable new features include:

- React Server Components
- Streaming SSR
- Loadable Components
- Code Splitting with React Router

React on Rails Pro is the best way to optimize your Webpack setup for React on Rails, including code splitting with [React Router](https://reactrouter.com/) and [loadable-components](https://loadable-components.com/) with server-side rendering for SEO and hot-reloading for developers.

We did this for Popmenu, [lowering Heroku costs 20-25% while getting a 73% decrease in average response times](https://www.shakacode.com/recent-work/popmenu/). Several years later, Popmenu serves tens of millions of SSR requests daily with React on Rails Pro.

If you're interested, read more about [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/) and [book a call](https://meetings.hubspot.com/justingordon/30-minute-consultation).

# Documentation

See the documentation at **[shakacode.com/react-on-rails/docs](https://www.shakacode.com/react-on-rails/docs/)** and [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/).

## Project Objective

To provide a high-performance framework for integrating Ruby on Rails with React, especially regarding React Server-Side Rendering for better SEO and improved performance.

## Features and Why React on Rails?

Given that `shakacode/shakapacker` gem already provides basic React integration, why would you use "React on Rails"?

1. **Modern ESM-only package** with optimized tree-shaking for smaller bundle sizes and better performance.
1. **Advanced loading strategies** with `sync`, `async`, and `defer` options for optimal performance based on your needs.
1. **Automatic configuration** of what bundles are added to the page based on what React components are on the page. This results in faster browser loading time via smaller bundle sizes.
1. **Keep up with the latest changes** in different versions of React. React 18+ is fully supported with enhanced React Server Components.
1. **Easy prop passing** directly from your Rails view to your React components rather than having your Rails view load and then make a separate request to your API.
   Tight integration with [shakapacker](https://github.com/shakacode/shakapacker).
1. **Server-Side Rendering (SSR)** with enhanced React Server Components support, often used for SEO crawler indexing and UX performance.
1. **[Automated optimized entry-point creation and bundle inclusion](https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation/)** when placing a component on a page. With this feature, you no longer need to configure `javascript_pack_tags` and `stylesheet_pack_tags` on your layouts based on what's shown. "It just works!"
1. **[Redux](https://redux.js.org/) and [React Router](https://reactrouter.com/) integration** with server-side-rendering.
1. **[Internationalization (I18n) and (localization)](https://www.shakacode.com/react-on-rails/docs/guides/i18n)** support.
1. **Supportive community**. This [web search shows how live public sites are using React on Rails](https://publicwww.com/websites/%22react-on-rails%22++-undeveloped.com+depth%3Aall/).
1. **[ReScript Support](https://github.com/shakacode/rescript-react-on-rails-example)**.

See [Rails/Shakapacker React Integration Options](https://www.shakacode.com/react-on-rails/docs/guides/rails-webpacker-react-integration-options) for comparisons to other gems.

## Online demo

- See the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) for an example of a live implementation and code.
- A deployed version of the project `spec/dummy`, which demonstrates several uses of `react_on_rails`, will soon be available on [Control Plane through this link](https://ror-spec-dummy.reactrails.com/)

## ShakaCode Forum Premium Content

_Requires creating a free account._

- [How to use different versions of a file for client and server rendering](https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352)
- [How to conditionally render server side based on the device type](https://forum.shakacode.com/t/how-to-conditionally-render-server-side-based-on-the-device-type/1473)

## Prerequisites

- Ruby on Rails >= 5
- Shakapacker >= 6.0 (Webpacker is no longer supported as of v16)
- Ruby >= 3.2 (CI tested: 3.2 - 3.4)
- Node.js >= 20 (CI tested: 20 - 22)
- A JavaScript package manager (npm, yarn, pnpm, or bun)

# 🆘 Get Help & Support

**Need immediate help?** Here are your options, ordered by response time:

- 🚀 **Professional Support**: [react_on_rails@shakacode.com](mailto:react_on_rails@shakacode.com) - Fastest resolution for bugs, upgrades, and consulting
- 💬 **React + Rails Slack**: [Join our community](https://invite.reactrails.com) - Chat with other developers
- 🆓 **GitHub Issues**: [Report bugs](https://github.com/shakacode/react_on_rails/issues) - Community support
- 📖 **Discussions**: [Ask questions](https://github.com/shakacode/react_on_rails/discussions) - General help

**Additional Resources:**
- [**Subscribe**](https://app.mailerlite.com/webforms/landing/l1d9x5) for announcements of new releases and tutorials
- **[forum.shakacode.com](https://forum.shakacode.com)** - Development discussions
- **[@railsonmaui on Twitter](https://twitter.com/railsonmaui)** - Updates and tips
- [Projects using React on Rails](https://github.com/shakacode/react_on_rails/tree/master/PROJECTS.md) - Submit yours!

## Contributing

Bug reports and pull requests are welcome. To get started, see [Contributing](https://github.com/shakacode/react_on_rails/tree/master/CONTRIBUTING.md) and the [list of help wanted issues](https://github.com/shakacode/react_on_rails/labels/contributions%3A%20up%20for%20grabs%21).

# Work with Us

ShakaCode is **[hiring passionate software engineers](http://www.shakacode.com/career)** to work on our projects, including [HiChee](https://hichee.com)!

# License

The gem is available as open source under the terms of the [MIT License](https://github.com/shakacode/react_on_rails/tree/master/LICENSE.md).

Note, some features are available only with a React on Rails Pro subscription. See [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/) for more information.

# Supporters

The following companies support our open-source projects, and ShakaCode uses their products!

<br />
<br />

<a href="https://jb.gg/OpenSource" style="margin-right: 20px;">
  <img src="https://resources.jetbrains.com/storage/products/company/brand/logos/jetbrains.png" alt="JetBrains" height="120px">
</a>
<a href="https://scoutapp.com">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://user-images.githubusercontent.com/4244251/184881147-0d077438-3978-40da-ace9-4f650d2efe2e.png">
    <source media="(prefers-color-scheme: light)" srcset="https://user-images.githubusercontent.com/4244251/184881152-9f2d8fba-88ac-4ba6-873b-22387f8711c5.png">
    <img alt="ScoutAPM" src="https://user-images.githubusercontent.com/4244251/184881152-9f2d8fba-88ac-4ba6-873b-22387f8711c5.png" height="120px">
  </picture>
</a>
<a href="https://shakacode.controlplane.com">
  <picture>
    <img alt="Control Plane" src="https://github.com/shakacode/.github/assets/20628911/90babd87-62c4-4de3-baa4-3d78ef4bec25" height="120px">
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
<a href="https://reviewable.io">
  <img src="https://user-images.githubusercontent.com/20628911/230848305-c94510a4-82d7-468f-bf9f-eeb81d3f2ce0.png" alt="Reviewable" height="55px">
</a>
