# Webpack V1 Tips

The following only apply to Webpack V1. Take 1 hour and update to v2! It's worth it!

## Use the `--bail` Option When Running Webpack for CI or Deployments if using Webpack V1

For your scripts that statically build your Webpack bundles, use the `--bail` option. This will ensure that CI and your product deployment **halt** if Webpack cannot complete. For more details, see the documentation for [Webpack's `--bail` option](https://webpack.js.org/configuration/other-options/#bail). Note, you might not want to use the `--bail` option if you want to see all the errors, rather than only the first error. Then make sure to check the Webpack exit code.

## Entry Points

You should ensure you configure the entry points correctly for Webpack if you want to break out libraries into a "vendor" bundle where your libraries are packaged separately from your app's code. If you send web clients your vendor bundle separately from your app bundles, then web clients might have the vendor bundle cached while they receive updates for your app.

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
