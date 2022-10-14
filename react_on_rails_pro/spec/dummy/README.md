# Example of React on Rails Pro Using Default @rails/webpacker Configuration

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Webpack Configuration](#webpack-configuration)
- [Loadable Components](#loadable-components)
- [Caching](#caching)
- [Run yarn if not done yet](#run-yarn-if-not-done-yet)
- [Starting the Sample App](#starting-the-sample-app)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Installation

```sh
cd react_on_rails_pro
bundle && yarn && cd spec/dummy && bundle && yarn
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
This example builds on the standard @rails/webpacker configuration, as demonstrated
by repo (shakacode/react_on_rails_tutorial_with_ssr_and_hmr_fast_refresh](https://github.com/shakacode/react_on_rails_tutorial_with_ssr_and_hmr_fast_refresh) 

* [config/webpacker.yml](./config/webpacker.yml)
* [config/webpack directory](./config/webpack)

## Loadable Components
See more details in [docs/code-splitting-loadable-components](../../docs/code-splitting-loadable-components.md).

Note that the webpack configuration substitutes files with the extension `imports-loadable.js` with `imports-hmr.js`. See the file `config/webpack/environment.js` code where the NormalModuleReplacementPlugin is used to make this substitution.

## Caching

To toggle caching in development, as explained in [this article](http://guides.rubyonrails.org/caching_with_rails.html#caching-in-development)
`rails dev:cache`

## Error Handling

This sample app includes both Honeybadger and Sentry integration, including Sentry tracing integration.

## Starting the Sample App
                             
### Using HMR and no loadable-components
```sh
overmind start -f Procfile.dev
```
   
### Using loadable-components and no HMR
```sh
overmind start -f Procfile.static
```
