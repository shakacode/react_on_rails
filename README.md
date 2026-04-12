![reactrails](https://user-images.githubusercontent.com/10421828/79436261-52159b80-7fd9-11ea-994e-2a98dd43e540.png)

<p align="center">
 <a href="https://shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436256-517d0500-7fd9-11ea-9300-dfbc7c293f26.png"></a>
 <a href="https://forum.shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436266-53df5f00-7fd9-11ea-94b3-b985e1b05bdc.png"></a>
 <a href="https://github.com/sponsors/shakacode"><img src="https://user-images.githubusercontent.com/10421828/79466109-cdd90d80-8004-11ea-88e5-25f9a9ddcf44.png"></a>
</p>

---

[![License](https://img.shields.io/badge/license-mit-green.svg)](LICENSE.md)[![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=main&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=main) [![Gem Downloads](https://img.shields.io/gem/dt/react_on_rails)](https://rubygems.org/gems/react_on_rails)

[![Integration Tests](https://github.com/shakacode/react_on_rails/actions/workflows/integration-tests.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/integration-tests.yml)
[![Gem Tests](https://github.com/shakacode/react_on_rails/actions/workflows/gem-tests.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/gem-tests.yml)
[![JS Tests](https://github.com/shakacode/react_on_rails/actions/workflows/package-js-tests.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/package-js-tests.yml)
[![Linting](https://github.com/shakacode/react_on_rails/actions/workflows/lint-js-and-ruby.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/lint-js-and-ruby.yml)

<p align="center">
  <a href="https://reactonrails.com/docs/">Documentation</a> ·
  <a href="https://reactonrails.com/docs/getting-started/quick-start/">Quick Start</a> ·
  <a href="https://reactonrails.com/examples/">Examples</a> ·
  <a href="https://reactonrails.com/docs/pro/">Pro</a>
</p>

## React on Rails

React on Rails integrates React into Ruby on Rails applications with Rails view
helpers, server-side rendering, hot reloading, and automatic bundle generation.

This README is intentionally brief. For setup guides, architecture, API
reference, upgrades, examples, and Pro features, use the main documentation
site: [reactonrails.com/docs](https://reactonrails.com/docs/).

React on Rails is maintained by [ShakaCode](https://www.shakacode.com).

## Start Here

- [Documentation home](https://reactonrails.com/docs/)
- [Quick Start](https://reactonrails.com/docs/getting-started/quick-start/)
- [Create a new app](https://reactonrails.com/docs/getting-started/create-react-on-rails-app/)
- [Install into an existing Rails app](https://reactonrails.com/docs/getting-started/installation-into-an-existing-rails-app/)
- [Examples](https://reactonrails.com/examples/)
- [Compare OSS and Pro](https://reactonrails.com/docs/getting-started/oss-vs-pro/)
- [Compare with alternatives](https://reactonrails.com/docs/getting-started/comparison-with-alternatives/)
- [Changelog](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md)

Older docs and code: [v14](https://github.com/shakacode/react_on_rails/tree/14.0.0),
[v13](https://github.com/shakacode/react_on_rails/tree/13.4.0),
[v12](https://github.com/shakacode/react_on_rails/tree/12.6.0), and
[v11](https://github.com/shakacode/react_on_rails/tree/11.3.0).

## Install in 30 Seconds

Create a new React on Rails app:

```bash
npx create-react-on-rails-app my-app
cd my-app
bin/rails db:prepare
bin/dev
```

Add React on Rails to an existing Rails app:

```bash
bundle add react_on_rails --strict
bundle exec rails generate react_on_rails:install
bin/dev
```

Render a component in any Rails view:

```erb
<%= react_component("HelloWorld", props: { name: "World" }) %>
```

If you hit setup issues, run:

```bash
bundle exec rake react_on_rails:doctor
```

## Why Teams Use React on Rails

- Render React directly inside Rails views with `react_component`.
- Use Rails-oriented SSR in OSS, or upgrade to Pro for Node-rendered SSR,
  streaming SSR, and React Server Components.
- Keep a single Rails app instead of splitting into a separate frontend and API.
- Use modern bundling with Shakapacker, including Rspack support.

## React on Rails Pro

React on Rails Pro adds higher-throughput SSR and advanced rendering features on
top of the open-source gem, including Node renderer support, streaming SSR,
React Server Components, fragment caching, and TanStack Router SSR.

Start with the docs here:

- [React on Rails Pro docs](https://reactonrails.com/docs/pro/)
- [OSS vs Pro feature comparison](https://reactonrails.com/docs/getting-started/oss-vs-pro/)
- [Upgrade to Pro](https://reactonrails.com/docs/pro/upgrading-to-pro/)

## Requirements

- Ruby on Rails >= 5
- Shakapacker >= 6.0 (autobundling requires >= 7.0)
- Ruby >= 3.0
- Node.js >= 18
- A JavaScript package manager such as pnpm, npm, yarn, or bun

## Help

- [Documentation](https://reactonrails.com/docs/) for the canonical guides and
  API reference
- [GitHub Discussions](https://github.com/shakacode/react_on_rails/discussions)
  for questions
- [GitHub Issues](https://github.com/shakacode/react_on_rails/issues) for bugs
- [React + Rails Slack](https://invite.reactrails.com) for community chat
- [Commercial support](mailto:react_on_rails@shakacode.com) for upgrades,
  consulting, and Pro guidance
- [AI Agent User Guide](AGENTS_USER_GUIDE.md) for AI coding assistants

## Contributing

Bug reports and pull requests are welcome. Start with
[CONTRIBUTING.md](https://github.com/shakacode/react_on_rails/tree/main/CONTRIBUTING.md)
and the
[help wanted issues](https://github.com/shakacode/react_on_rails/labels/contributions%3A%20up%20for%20grabs%21).

## License

React on Rails is available as open source under the terms of the
[MIT License](https://github.com/shakacode/react_on_rails/tree/main/LICENSE.md).

Some advanced features require a React on Rails Pro subscription. See
[React on Rails Pro](https://reactonrails.com/docs/pro/) for details.

## Supporters

Thanks to [JetBrains](https://jb.gg/OpenSource), [Scout](https://scoutapp.com),
[Control Plane](https://shakacode.controlplane.com),
[BrowserStack](https://www.browserstack.com),
[Honeybadger](https://www.honeybadger.io), and
[CodeRabbit](https://coderabbit.ai) for supporting ShakaCode's open-source
work.
