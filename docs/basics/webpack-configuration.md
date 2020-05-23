# Webpack Configuration: custom setup for Webpack or rails/webpacker?

## Webpack vs. rails/webpacker 

[Webpack](https://webpack.js.org) is the JavaScript npm package that prepares all your client-side assets. The Rails asset pipeline used to be the preferable way to prepare client-side assets. 

[rails/webpacker](https://github.com/rails/webpacker) is the Ruby gem that mainly gives us 2 things:

1. View helpers for placing the Webpack bundles on your Rails views. React on Rails depends on these view helpers.
2. A layer of abstraction on top of Webpack customization. This is great for demo projects, but most real world projects will want a customized version of Webpack.

# React on Rails

Version 9 of React on Rails added support for the rails/webpacker view helpers so that Webpack produced assets would no longer pass through the Rails asset pipeline. As part of this change, React on Rails added a configuration option to support customization of the node_modules directory. This allowed React on Rails to support the rails/webpacker configuration of the Webpack configuration.

A key decision in your use React on Rails is whether you go with the rails/webpacker default setup or the traditional React on Rails setup of putting all your client side files under the `/client` directory. While there are technically 2 independent choices involved, the directory structure and the mechanism of Webpack configuration, for simplicity sake we'll assume that these choices go together.

## Option 1: Recommended: Traditional React on Rails using the /client directory

Until version 9, all React on Rails apps used the `/client` directory for configuring React on Rails in terms of the configuration of Webpack and location of your JavaScript and Webpack files, including the node_modules directory. Version 9 changed the default to `/` for the `node_modules` location using this value in `config/initializers/react_on_rails.rb`: `config.node_modules_location`. The  

The [ShakaCode Team](http://www.shakacode.com) _recommends_ this approach for projects beyond the simplest cases as it provides the greatest transparency in your webpack and overall client-side setup. The *big advantage* to this is that almost everything within the `/client` directory will apply if you wish to convert your client-side code to a pure Single Page Application that runs without Rails. This allows you to google for how to do something with Webpack configuration and what applies to a non-Rails app will apply just as well to a React on Rails app.

The two best examples of this pattern are the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) and the integration test example in [spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy).

In this case, you don't need to understand the nuances of customization of your Webpack config via the [Webpacker mechanism](./docs/additional-reading/webpack-tips.md).

You can access values in the `config/webpacker.yml`

```js
const { config, devServer } = require('@rails/webpacker');
```

You will want consider using some of the same values set in these files:

* https://github.com/rails/webpacker/blob/master/package/environments/base.js
* https://github.com/rails/webpacker/blob/master/package/environments/development.js

**Note**, if your node_modules directory is not at the top level of the Rails project, then you will need to set the
ENV value of WEBPACKER_CONFIG to the location of the `config/webpacker.yml` file per [rails/webpacker PR 2561](https://github.com/rails/webpacker/pull/2561).

## Option 2: Default Generator Setup: rails/webpacker app/javascript

Typical rails/webpacker apps have a standard directory structure as documented [here](https://github.com/rails/webpacker/blob/master/docs/folder-structure.md). If you follow the steps in the the [basic tutorial](../../docs/tutorial.md), you will see this pattern in action. In order to customize the Webpack configuration, you need to consult with the [rails/webpacker Webpack configuration](https://github.com/rails/webpacker/blob/master/docs/webpack.md). 

The *advantage* of using rails/webpacker to configure Webpack is that there is very little code needed to get started and you don't need to understand really anything about Webpack customization. The *big disadvantage* to this is that you will need to learn the ins and outs of the [rails/webpacker way to customize Webpack](https://github.com/rails/webpacker/blob/master/docs/webpack.md) which differs from the plain [Webpack way](https://webpack.js.org/).

Overall, consider carefully if you prefer the `rails/webpacker` directory structure and Webpack configuration, over the placement of all client side files within the `/client` directory along with conventional Webpack configuration. Once again, the `/client` directory setup is recommended.

You can find more details on this topic in [Recommended Project Structure](./recommended-project-structure.md). 
 
See [Issue 982: Tutorial Generating Correct Project Structure?](https://github.com/shakacode/react_on_rails/issues/982) to discuss this issue.

For more details on project setup, see [Recommended Project Structure](./docs/basics/recommended-project-structure.md).
