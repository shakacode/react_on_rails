# Images

1. leading slash necessary on the
   a. Option name for the file-loader and url-loader (todo reference)
   b. Option publicPath for the output (todo reference)

```
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
      }
    },
  },
];

```

A full example can be found at [spec/dummy/client/app/startup/ImageExample.jsx](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/app/startup/ImageExample.jsx)

You are free to use images either in image tags or as background images in SCSS files. You can
use a "global" location of /client/app/assets/images or a relative path to your JS or SCSS file, as
is done with CSS modules.

**images** is a defined alias, so "images/foobar.jpg" would point to the file at
`/client/app/assets/images/foobar.jpg.`

```
 resolve: {
    alias: {
      images: join(process.cwd(), 'app', 'assets', 'images'),
    },
  },
```
