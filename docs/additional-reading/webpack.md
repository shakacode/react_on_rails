# Entry Points and Globally Exposing Objects

You should ensure you configure the entry points correctly for webpack.

## When using React 0.14 and greater

You need both include `react-dom/server` and `react` as values for `entry`, like this:

```
  entry: {

    // See use of 'vendor' in the CommonsChunkPlugin inclusion below.
    vendor: [
      'babel-core/polyfill',
      'react',
      'react-dom',
    ],
```

and you need to expose them:

```
      // React is necessary for the client rendering:
      {test: require.resolve('react'), loader: 'expose?React'},
      {test: require.resolve('react-dom'), loader: 'expose?ReactDOM'},
```

and use this line rather than `{test: require.resolve('react-dom'), loader: 'expose?ReactDOM'},`:

```
   {test: require.resolve('react-dom/server'), loader: 'expose?ReactDOMServer'},
```

## When you use React 0.13

You don't need to put in react-dom.