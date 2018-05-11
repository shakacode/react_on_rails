# Webpack

Webpack is used to generate JavaScript and CSS "bundles" directly to your `/public` directory. [webpacker](https://github.com/rails/webpacker) provides view helpers to access the Webpack generated (and fingerprinted) JS and CSS. These files totally skip the Rails asset pipeline. You are responsible for properly processing your Webpack output via the Webpack config files.



## Why Webpack?

This usage of webpack fits neatly and simply into existing Rails apps. You can include React components on a Rails view with a simple helper.

Compare this to some alternative approaches for SPAs (Single Page Apps) that utilize Webpack and Rails. They will use a separate node server to distribute web pages, JavaScript assets, CSS, etc., and will still use Rails as an API server. A good example of this is our ShakaCode team member Alex's article [
Universal React with Rails: Part I](https://medium.com/@alexfedoseev/isomorphic-react-with-rails-part-i-440754e82a59).



## Webpack Configuration: custom setup for Webpack or rails/webpacker?

Version 9 of React on Rails added support for the rails/webpacker view helpers so that Webpack produced assets would no longer pass through the Rails asset pipeline. As part of this change, React on Rails added a configuration option to support customization of the node_modules directory. This allowed React on Rails to support the rails/webpacker configuration of the Webpack configuration.

A key decision in your use React on Rails is whether you go with the rails/webpacker default setup or the traditional React on Rails setup of putting all your client side files under the `/client` directory. While there are technically 2 independent choices involved, the directory structure and the mechanism of Webpack configuration, for simplicity sake we'll assume that these choices go together.

### Traditional React on Rails using the /client directory

Until version 9, all React on Rails apps used the `/client` directory for configuring React on Rails in terms of the configuration of Webpack and location of your JavaScript and Webpack files, including the node_modules directory. Version 9 changed the default to `/` for the `node_modules` location using this value in `config/initializers/react_on_rails.rb`: `config.node_modules_location`. 

The [ShakaCode Team](http://www.shakacode.com) _recommends_ this approach for projects beyond the simplest cases as it provides the greatest transparency in your webpack and overall client-side setup. The *big advantage* to this is that almost everything within the `/client` directory will apply if you wish to convert your client-side code to a pure Single Page Application that runs without Rails. This allows you to google for how to do something with Webpack configuration and what applies to a non-Rails app will apply just as well to a React on Rails app.

The two best examples of this patten are the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) and the integration test example in [spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy).

In this case, you don't need to understand the nuances of customization of your Wepback config via the [Webpacker mechanism](../../docs/webpack.md).

### rails/webpacker Setup

Typical rails/webpacker apps have a standard directory structure as documented [here](https://github.com/rails/webpacker/blob/master/docs/folder-structure.md). If you follow the steps in the the [basic tutorial](../../docs/tutorial.md), you will see this pattern in action. In order to customize the Webpack configuration, you need to consult with the [rails/webpacker Webpack configuration](https://github.com/rails/webpacker/blob/master/docs/webpack.md). 

Version 9 made this the default for generated apps for 2 reasons:

1. It's less code to generate and thus less to explain.
2. `rails/webpacker` might be viewed as a convention in the Rails community.

The *advantage* of this is that there is very little code needed to get started and you don't need to understand really anything about Webpack customization. The *big disadvantage* to this is that you will need to learn the ins and outs of the [rails/webpacker way to customize Webpack](https://github.com/rails/webpacker/blob/master/docs/webpack.md) which differs from the plain [Webpack way](https://webpack.js.org/).

Overall, consider carefully if you prefer the `rails/webpacker` directory structure and Webpack configuration, over the placement of all client side files within the `/client` directory along with conventional Webpack configuration.

See [Issue 982: Tutorial Generating Correct Project Structure?](https://github.com/shakacode/react_on_rails/issues/982) to discuss this issue.

