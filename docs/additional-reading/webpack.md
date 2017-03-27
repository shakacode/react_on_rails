# Webpack Tips

## Where do I learn about advanced Webpack setups, such as with "CSS Modules", "Code Splitting", etc
You can try out example app, [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial). We're building comprehensive production examples in our new, premium product, [**React on Rails Pro**](https://forum.shakacode.com/t/introducing-react-on-rails-pro-subscriptions/785). If you're interested, please see the details in [this forum post](https://forum.shakacode.com/t/introducing-react-on-rails-pro-subscriptions/785).

## Webpack v1 or v2?
We recommend using Webpack version 2.3.1 or greater.

## yarn or npm?
Yarn is the current recommendation!

## Entry Points

You should ensure you configure the entry points correctly for webpack if you want to break out libraries into a "vendor" bundle where your libraries are packaged separately from your app's code. If you send web clients your vendor bundle separately from your app bundles, then web clients might have the vendor bundle cached while they receive updates for your app.

Webpack v2 makes this very convenient! See:

* [Implicit Common Vendor Chunk](https://webpack.js.org/guides/code-splitting-libraries/#implicit-common-vendor-chunk)
* [Manifest File](https://webpack.js.org/guides/code-splitting-libraries/#manifest-file)



