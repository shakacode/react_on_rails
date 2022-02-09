# Webpack Configuration: custom setup for Webpack or rails/webpacker?

## Webpack vs. rails/webpacker

[Webpack](https://webpack.js.org) is the JavaScript npm package that prepares all your client-side assets. The Rails asset pipeline used to be the preferable way to prepare client-side assets.

[rails/webpacker](https://github.com/rails/webpacker) is the Ruby gem that mainly gives us 2 things:

1. View helpers for placing the webpack bundles on your Rails views. React on Rails depends on these view helpers.
2. A layer of abstraction on top of Webpack customization. The base setup works great for the client side webpack configuration.

To get a deeper understanding of `rails/webpacker`, watch [RailsConf 2020 CE - Webpacker, It-Just-Works, But How? by Justin Gordon](https://youtu.be/sJLoOpc5LD8)

Per the example repo [shakacode/react_on_rails_demo_ssr_hmr](https://github.com/shakacode/react_on_rails_demo_ssr_hmr),
you should consider keeping your codebase mostly consistent with the defaults for [rails/webpacker](https://github.com/rails/webpacker).

# React on Rails

Version 9 of React on Rails added support for the rails/webpacker view helpers so that Webpack produced assets would no longer pass through the Rails asset pipeline. As part of this change, React on Rails added a configuration option to support customization of the node_modules directory. This allowed React on Rails to support the rails/webpacker configuration of the Webpack configuration.

A key decision in your use React on Rails is whether you go with the rails/webpacker default setup or the traditional React on Rails setup of putting all your client side files under the `/client` directory. While there are technically 2 independent choices involved, the directory structure and the mechanism of Webpack configuration, for simplicity sake we'll assume that these choices go together.

## Option 1: Default Generator Setup: rails/webpacker app/javascript

Typical rails/webpacker apps have a standard directory structure as documented [here](https://github.com/rails/webpacker/blob/5-x-stable/docs/recommended-project-structure.md). If you follow the steps in the the [basic tutorial](https://www.shakacode.com/react-on-rails/docs/guides/tutorial/), you will see this pattern in action. In order to customize the Webpack configuration, you need to consult with the [rails/webpacker Webpack configuration](https://www.shakacode.com/react-on-rails/docs/javascript/webpack/).

The *advantage* of using rails/webpacker to configure Webpack is that there is very little code needed to get started and you don't need to understand really anything about Webpack customization.

## Option 2: Traditional React on Rails using the /client directory

Until version 9, all React on Rails apps used the `/client` directory for configuring React on Rails in terms of the configuration of Webpack and location of your JavaScript and Webpack files, including the node_modules directory. Version 9 changed the default to `/` for the `node_modules` location using this value in `config/initializers/react_on_rails.rb`: `config.node_modules_location`.

You can access values in the `config/webpacker.yml`

```js
const { config, devServer } = require('shakapacker');
```

You will want consider using some of the same values set in these files:

* https://github.com/rails/webpacker/blob/master/package/environments/base.js
* https://github.com/rails/webpacker/blob/master/package/environments/development.js
