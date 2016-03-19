# Entry Points and Globally Exposing Objects

You should ensure you configure the entry points correctly for webpack.

## When using React 0.14 and greater

You need both include `react-dom/server` and `react` as values for `entry`, like this:

```
  entry: {

    // See use of 'vendor' in the CommonsChunkPlugin inclusion below.
    vendor: [
      'babel-core/polyfill',
      'jquery',
      'jquery-ujs',
      'react',
      'react-dom',
    ],
```

and you need to expose them:

```
      // React is necessary for the client rendering:
      {test: require.resolve('react'), loader: 'expose?React'},
      {test: require.resolve('react-dom'), loader: 'expose?ReactDOM'},
      {test: require.resolve('jquery'), loader: 'expose?jQuery'},
      {test: require.resolve('jquery'), loader: 'expose?$'},
```

`webpack.server.config.js` is similar, but substitute:

```
 entry: ['./yourCode', 'react-dom/server', 'react'],
```

and use this line rather than `{test: require.resolve('react-dom'), loader: 'expose?ReactDOM'},`:

```
   {test: require.resolve('react-dom/server'), loader: 'expose?ReactDOMServer'},
```

## When you use React 0.13

You don't need to put in react-dom.