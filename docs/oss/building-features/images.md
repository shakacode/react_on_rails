# Configuring Images and Assets with Webpack

This page covers the **bundling** side of images: configuring webpack so images
imported from your JavaScript/SCSS resolve correctly. For the **performance**
side — responsive `srcset`, lazy loading, CLS prevention, LCP preloading, and
AVIF/WebP — see [Fast Images in React on Rails](./fast-images.md).

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

A full example can be found at [react_on_rails/spec/dummy/client/app/startup/ImageExample.tsx](../../../react_on_rails/spec/dummy/client/app/startup/ImageExample.tsx)

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

## See also

- [Fast Images in React on Rails](./fast-images.md) — responsive `srcset`,
  lazy loading, CLS prevention, LCP preloading, and modern formats using Rails
  primitives.
- [Font Optimization](./fonts.md) — self-hosting and optimizing web fonts
  (preload, `font-display`, and a `size-adjust` metric-matched fallback to
  eliminate layout shift).
