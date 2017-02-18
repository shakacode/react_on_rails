# AngularJS Integration and Migration to React on Rails

[React on Rails](https://github.com/shakacode/react_on_rails) offers a smooth transition to migrating your existing [AngularJS](https://angularjs.org/) + Rails application to use React with Webpack on top of Rails. Here are a few highlights and tips.

## Assets Handling
Ideally, you should have your JavaScript libraries packaged by `webpack` and gathered by `yarn`. If you have not already done this, then you can setup the `ReactOnRails` default JS code directory of `/client` to load the JS libraries related to AngularJS, etc. You can configure Webpack to globally export these libraries, so inclusion this way will be no different than using the Rails asset pipeline. However, so long as you *understand* how your JavaScript will eventually make its way onto your main layout, you will be OK.

## Styling and CSS Modules
Once you move to Webpack, you can start using CSS modules. However, you'll need to carefully consider if your styling needs to apply to legacy AngularJS components in your app.

## ngReact Package

Check out the [ngReact](https://github.com/ngReact/ngReact) package. This package allows your AngularJS components to contain React components, including support for passing props from AngularJS to React. The [ShakaCode team](http://www.shakacode.com/about/) is using this library on a commercial project. However, we're doing this with some limitations:

1. We're only having the data flow in one direction, from AngularJS to React and never back up to the Angular components.
2. When we get to a case where the React components will affect the Angular layout, we try to convert the components up the tree to React.
3. Thus, the React components within AngularJS components will tend to be React "dumb" components, or totally self-contained chunks of React that have no side effects on the Angular code.

## StoryBook

We love using [StoryBook](https://getstorybook.io/) to create a simple testing and inspection area of new React components as we migrate them over from AngularJS Components.

## Overall Approach?

The big question when doing the migration from AngularJS to React is whether you should replace leaf level components first, to minimize the changes before you can deploy your hybrid AngularJS and React app. The alternative is to try to replace larger chunks at once. Both approaches have pros and cons. 

1. Frequent deploys with incremental parts of AngularJS replaced by React allows smaller incremental deploys and easier regression analysis should something break. On the negative side, any ping-pong of data between AngularJS and React can result in a complicated and convoluted architecture.
2. Larger deploys of a full screen can yield efficiencies such as converting the whole screen to use one Redux store. However, this can be a large chunk of code to test and deploy.
