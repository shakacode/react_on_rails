# Configuring Images and Assets with Webpack

A leading slash is necessary on the `name` option for file-loader/url-loader and the `publicPath` option for output.

```javascript
const assetLoaderRules = [
  {
    test: /\.(jpe?g|png|gif|ico|woff)$/,
    use: {
      loader: 'url-loader',
      options: {
        limit: urlFileSizeCutover,
        // Leading slash is 100% needed
        name: 'images/[hash].[ext]',
      },
    },
  },
  {
    test: /\.(ttf|eot|svg)$/,
    use: {
      loader: 'file-loader',
      options: {
        // Leading slash is 100% needed
        name: '/images/[hash].[ext]',
      },
    },
  },
];
```

A full example can be found at [react_on_rails/spec/dummy/client/app/startup/ImageExample.jsx](https://github.com/shakacode/react_on_rails/tree/main/react_on_rails/spec/dummy/client/app/startup/ImageExample.jsx)

You are free to use images either in image tags or as background images in SCSS files. In current
apps, prefer relative imports from files under `app/javascript`, or define your own webpack alias
if you want a global asset path.

React on Rails does not define an `images` alias by default. If you want one, add it explicitly.
For example, if your images live in `app/javascript/images`, then `"images/foobar.jpg"` can point
to `app/javascript/images/foobar.jpg` with a custom alias like this:

```javascript
resolve: {
    alias: {
      images: join(process.cwd(), 'app', 'javascript', 'images'),
    },
  },
```
