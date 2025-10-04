# Webpack Tips

## Where can I learn about advanced Webpack setups, including e.g. "CSS Modules", "Code Splitting", etc.?

You can try our example app, [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial). We're building comprehensive production examples in our new, premium product, [**React on Rails Pro**](https://forum.shakacode.com/t/introducing-react-on-rails-pro-subscriptions/785). If you're interested, please see the details in [this forum post](https://forum.shakacode.com/t/introducing-react-on-rails-pro-subscriptions/785).

## yarn or npm?

Yarn v1 is our current recommendation!

## Entry Points

You should ensure you configure the entry points correctly for Webpack if you want to break out libraries into a "vendor" bundle where your libraries are packaged separately from your app's code. If you send web clients your vendor bundle separately from your app bundles, then web clients might have the vendor bundle cached while they receive updates for your app.

Webpack v2 makes this very convenient! See:

- [Implicit Common Vendor Chunk](https://webpack.js.org/guides/code-splitting-libraries/#implicit-common-vendor-chunk)
- [Manifest File](https://webpack.js.org/guides/code-splitting-libraries/#manifest-file)

## Webpack v5

Webpack v5 is highly recommended. See [the release post](https://webpack.js.org/blog/2020-10-10-webpack-5-release/) and [the official migration documentation](https://webpack.js.org/migrate/5/).

If you need help with migrating your project to Webpack v5, please contact Justin Gordon at [justin@shakacode.com](mailto:justin@shakacode.com).
