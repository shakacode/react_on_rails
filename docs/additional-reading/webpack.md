# Webpack Tips

## Where do I learn about advanced Webpack setups, such as with "CSS Modules", "Code Splitting", etc
You can try out example app, [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial). We're building comprehensive production examples in our new, premium product, [**React on Rails Pro**](https://forum.shakacode.com/t/introducing-react-on-rails-pro-subscriptions/785). If you're interested, please see the details in [this forum post](https://forum.shakacode.com/t/introducing-react-on-rails-pro-subscriptions/785).

## Webpack v1 or v2?
We recommend using Webpack version 2.2.1 or greater.

## Use the `--bail` Option When Running Webpack for CI or Deployments
For your scripts that statically build your Webpack bundles, use the `--bail` option. This will ensure that CI and your product deployment **halt** if Webpack cannot complete! For more details, see the documentation for [Webpack's `--bail` option](https://webpack.js.org/configuration/other-options/#bail). Note, you might not want to use the `--bail` option if you just want to depend on Webpack returning a non-zero error code and you want to see all the errors, rather than only the first error.

## yarn or npm?
Yarn is the current recommendation!

## Entry Points

You should ensure you configure the entry points correctly for webpack if you want to break out libraries into a "vendor" bundle where your libraries are packaged separately from your app's code. If you send web clients your vendor bundle separately from your app bundles, then web clients might have the vendor bundle cached while they receive updates for your app.

You need both include `react-dom` and `react` as values for `entry`, like this:

```
  entry: {

    // See use of 'vendor' in the CommonsChunkPlugin inclusion below.
    vendor: [
      'babel-core/polyfill',
      'react',
      'react-dom',
    ],
```
