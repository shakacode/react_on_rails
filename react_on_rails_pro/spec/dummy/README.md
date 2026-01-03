# Example of React on Rails Pro Using Default Shakapacker Configuration

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents**

- [Webpack Configuration](#webpack-configuration)
- [Loadable Components](#loadable-components)
- [Caching](#caching)
- [Starting the Sample App](#starting-the-sample-app)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Installation

```sh
pnpm install -r
cd react_on_rails_pro
bundle
cd spec/dummy
bundle && pnpm install
```

To use the `React 18 Apollo with GraphQL` example you need to seed the testing database inside `spec/dummy` directory.

```sh
rake db:seed
```

## Running

Run one of these Procfiles:

1. [Procfile.dev](./Procfile.dev): Development setup with HMR and with loadable-components.
2. [Procfile.static](./Procfile.static): Development setup using `webpack --watch`. No HMR, but loadable-components is used.

## Webpack Configuration

This example builds on the standard Shakapacker configuration, as demonstrated
by repo [shakacode/react_on_rails_tutorial_with_ssr_and_hmr_fast_refresh](https://github.com/shakacode/react_on_rails_tutorial_with_ssr_and_hmr_fast_refresh)

- [config/shakapacker.yml](./config/shakapacker.yml)
- [config/webpack directory](./config/webpack)

## Loadable Components

See more details in [docs/code-splitting-loadable-components](../../docs/code-splitting-loadable-components.md).

Note that the webpack configuration substitutes files with the extension `imports-loadable.js` with `imports-hmr.js`. See the use of `NormalModuleReplacementPlugin` in [`config/webpack/commonWebpackConfig.js`](./config/webpack/commonWebpackConfig.js).

## Caching

To toggle caching in development, as explained in [this article](http://guides.rubyonrails.org/caching_with_rails.html#caching-in-development)
`rails dev:cache`

## Error Handling

This sample app includes both Honeybadger and Sentry integration, including Sentry tracing integration.

## Other necessary steps

Please check [CONTRIBUTING.md](../../CONTRIBUTING.md), it has the other necessary steps before you are able to run the demo app.

## Starting the Sample App

### Using HMR and no loadable-components

```sh
overmind start -f Procfile.dev
```

### Using loadable-components and no HMR

```sh
overmind start -f Procfile.static
```
