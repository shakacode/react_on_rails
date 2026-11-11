![reactrails](https://user-images.githubusercontent.com/10421828/79436261-52159b80-7fd9-11ea-994e-2a98dd43e540.png)

<p align="center">
 <a href="https://shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436256-517d0500-7fd9-11ea-9300-dfbc7c293f26.png"></a>
 <a href="https://forum.shakacode.com/"><img src="https://user-images.githubusercontent.com/10421828/79436266-53df5f00-7fd9-11ea-94b3-b985e1b05bdc.png"></a>
 <a href="https://github.com/sponsors/shakacode"><img src="https://user-images.githubusercontent.com/10421828/79466109-cdd90d80-8004-11ea-88e5-25f9a9ddcf44.png"></a>
</p>

---

[![License](https://img.shields.io/badge/license-mit-green.svg)](LICENSE.md)[![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Gem Downloads](https://img.shields.io/gem/dt/react_on_rails)](https://rubygems.org/gems/react_on_rails)

[![Integration Tests](https://github.com/shakacode/react_on_rails/actions/workflows/integration-tests.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/integration-tests.yml)
[![Gem Tests](https://github.com/shakacode/react_on_rails/actions/workflows/gem-tests.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/gem-tests.yml)
[![JS Tests](https://github.com/shakacode/react_on_rails/actions/workflows/package-js-tests.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/package-js-tests.yml)
[![Linting](https://github.com/shakacode/react_on_rails/actions/workflows/lint-js-and-ruby.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/lint-js-and-ruby.yml)

<p align="center">
  <a href="https://reactonrails.com/docs/">Documentation</a> ·
  <a href="https://reactonrails.com/docs/getting-started/quick-start/">Quick Start</a> ·
  <a href="https://reactonrails.com/examples/">Examples</a> ·
  <a href="https://reactonrails.com/docs/pro/">Pro</a> ·
  <a href="https://reactonrails.com/pricing/">Free & Pro</a>
</p>

## React on Rails

React on Rails integrates React into Ruby on Rails applications with Rails view
helpers, server-side rendering, hot reloading, and automatic bundle generation.

This README is intentionally brief. For setup guides, architecture, API
reference, upgrades, examples, and Pro features, use the main documentation
site: [reactonrails.com/docs](https://reactonrails.com/docs/).

React on Rails is maintained by [ShakaCode](https://www.shakacode.com).

## Start Here

1. [Documentation home](https://reactonrails.com/docs/)
2. [Quick Start](https://reactonrails.com/docs/getting-started/quick-start/)
3. [Create a new app](https://reactonrails.com/docs/getting-started/create-react-on-rails-app/)
4. [Install into an existing Rails app](https://reactonrails.com/docs/getting-started/existing-rails-app/)
5. [Examples](https://reactonrails.com/examples/)
6. [Compare OSS and Pro](https://reactonrails.com/docs/getting-started/oss-vs-pro/)
7. [Free & Pro](https://reactonrails.com/pricing/) and [sign up](https://pro.reactonrails.com/)
8. [Compare with alternatives](https://reactonrails.com/docs/getting-started/comparison-with-alternatives/)
9. [Changelog](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md)

These docs are for React on Rails 17. Historical docs and code are available for
[v15](https://github.com/shakacode/react_on_rails/tree/15.0.0/docs)
([code](https://github.com/shakacode/react_on_rails/tree/15.0.0)),
[v14](https://github.com/shakacode/react_on_rails/tree/14.0.0),
[v13](https://github.com/shakacode/react_on_rails/tree/13.4.0),
[v12](https://github.com/shakacode/react_on_rails/tree/12.6.0), and
[v11](https://github.com/shakacode/react_on_rails/tree/11.3.0). See the
[upgrade guide](https://reactonrails.com/docs/upgrading/upgrading-react-on-rails/#v15-retraction-notice)
before using v15 material.

## Install in 30 Seconds

Create a new React on Rails app:

```bash
npx create-react-on-rails-app my-app
cd my-app
bin/rails db:prepare
bin/dev
```

New apps default to React on Rails Pro for React 19.2 support. Use `--standard`
only when you intentionally want an open-source-only setup.

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

React on Rails Pro is free in development, test, CI, and staging for everyone.
Production use that serves real users or supports a live application requires
ShakaStack Pro unless the organization qualifies for a free use. Organizations
qualify when they meet all three limits across their affiliates: fewer than 10
people, under $1M revenue in the last twelve months, and under $1M in outside
capital raised ever. Charities, educational institutions, and hospitals are free
at any size.

ShakaStack Pro includes React on Rails Pro, ShakaPerf, and Inertia Rails SSR Cache
for every affiliate, application, environment, repository, and developer in your
organization, with Slack support and no limit on headcount or revenue. It costs
$1,800 per year per organization at
[pro.reactonrails.com](https://pro.reactonrails.com/). An active React on Rails Pro
subscription already counts as ShakaStack Pro. ShakaPerf follows its own free use
rules, including for CI. No license key is needed to run React on Rails Pro; a key
only marks your pages `Licensed`. See
[The ShakaStack License](https://github.com/shakacode/react_on_rails/blob/main/REACT-ON-RAILS-PRO-LICENSE.md).

Start with the docs here:

1. [React on Rails Pro docs](https://reactonrails.com/docs/pro/)
2. [OSS vs Pro feature comparison](https://reactonrails.com/docs/getting-started/oss-vs-pro/)
3. [Upgrade to Pro](https://reactonrails.com/docs/pro/upgrading-to-pro/)
4. [Free & Pro](https://reactonrails.com/pricing/) and [sign up](https://pro.reactonrails.com/)

## Requirements

- Ruby on Rails >= 5.2
- Shakapacker >= 6.0 (autobundling requires >= 7.0; CI tested: 8.2.0 - 10.3.2)
- Ruby >= 3.3 (CI tested: 3.3 - 4.0)
- Node.js >= 18
- A JavaScript package manager such as pnpm, npm, yarn, or bun

## Help

- [Documentation](https://reactonrails.com/docs/) for the canonical guides and
  API reference
- [GitHub Discussions](https://github.com/shakacode/react_on_rails/discussions)
  for questions
- [GitHub Issues](https://github.com/shakacode/react_on_rails/issues) for bugs
- [React + Rails Slack](https://reactrails.slack.com) for community chat
  (existing members; non-members, please use GitHub Discussions above)
- [Commercial support](mailto:react_on_rails@shakacode.com) for upgrades,
  consulting, and Pro guidance
- [AI Agent User Guide](AGENTS_USER_GUIDE.md) for AI coding assistants

## Contributing

Bug reports and pull requests are welcome. Start with
[CONTRIBUTING.md](https://github.com/shakacode/react_on_rails/blob/main/CONTRIBUTING.md)
and the
[help wanted issues](https://github.com/shakacode/react_on_rails/labels/contributions%3A%20up%20for%20grabs%21).

## Security

Suspected security vulnerabilities should be reported privately. See
[SECURITY.md](SECURITY.md) for the disclosure process and supported version
policy. Please do not open a public issue for security reports.

## License

React on Rails is available as open source under the terms of the
[MIT License](https://github.com/shakacode/react_on_rails/blob/main/LICENSE.md).

React on Rails Pro is offered under
[The ShakaStack License, version 1.0, applied to React on Rails Pro](https://github.com/shakacode/react_on_rails/blob/main/REACT-ON-RAILS-PRO-LICENSE.md).
React on Rails Pro development, test, CI, and staging use is free for everyone.
Production use requires [ShakaStack Pro](https://pro.reactonrails.com/) unless a
free use applies. One $1,800 yearly subscription covers your whole organization
across React on Rails Pro, ShakaPerf, and Inertia Rails SSR Cache. No license key
is needed to run React on Rails Pro. Questions:
[contact@shakacode.com](mailto:contact@shakacode.com).

## Supporters

Thanks to the companies supporting ShakaCode's open-source work.

<p>
  <a href="https://jb.gg/OpenSource">
    <img src="https://resources.jetbrains.com/storage/products/company/brand/logos/jetbrains.png" alt="JetBrains" height="34">
  </a>
  <a href="https://scoutapp.com">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://user-images.githubusercontent.com/4244251/184881147-0d077438-3978-40da-ace9-4f650d2efe2e.png">
      <source media="(prefers-color-scheme: light)" srcset="https://user-images.githubusercontent.com/4244251/184881152-9f2d8fba-88ac-4ba6-873b-22387f8711c5.png">
      <img alt="Scout" src="https://user-images.githubusercontent.com/4244251/184881152-9f2d8fba-88ac-4ba6-873b-22387f8711c5.png" height="58">
    </picture>
  </a>
  <a href="https://shakacode.controlplane.com">
    <picture>
      <img alt="Control Plane" src="https://github.com/shakacode/.github/assets/20628911/90babd87-62c4-4de3-baa4-3d78ef4bec25" height="44">
    </picture>
  </a>
  <a href="https://www.browserstack.com">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://user-images.githubusercontent.com/4244251/184881122-407dcc29-df78-4b20-a9ad-f597b56f6cdb.png">
      <source media="(prefers-color-scheme: light)" srcset="https://user-images.githubusercontent.com/4244251/184881129-e1edf4b7-3ae1-4ea8-9e6d-3595cf01609e.png">
      <img alt="BrowserStack" src="https://user-images.githubusercontent.com/4244251/184881129-e1edf4b7-3ae1-4ea8-9e6d-3595cf01609e.png" height="44">
    </picture>
  </a>
  <a href="https://www.honeybadger.io">
    <img src="https://user-images.githubusercontent.com/4244251/184881133-79ee9c3c-8165-4852-958e-31687b9536f4.png" alt="Honeybadger" height="44">
  </a>
  <a href="https://coderabbit.ai">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://docs.coderabbit.ai/coderabbit-logo-dark.svg">
      <source media="(prefers-color-scheme: light)" srcset="https://docs.coderabbit.ai/coderabbit-logo-light.svg">
      <img alt="CodeRabbit" src="https://docs.coderabbit.ai/coderabbit-logo-light.svg" height="34">
    </picture>
  </a>
</p>
