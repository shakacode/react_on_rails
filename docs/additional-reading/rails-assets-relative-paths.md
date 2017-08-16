*Note: this doc needs updating to reflect how v8.x+ no longer puts Webpack generated files through the asset pipeline. PR's welcome!*

# Using Webpack bundled assets with the Rails Asset Pipeline

**If you're looking to use assets in your react components, look no further. This doc is for you.**

As most of you know, when you spin up a Rails application all of your asset files that live within your `app/assets/` directory will be added into your application's Asset Pipeline. If you would like to view any of these assets (most commonly you'd want to view images), run your rails server in development mode and in a browser visit a url similar to: `localhost:3000/assets/sample_image.png`. In this case, if I had an image `sample_image.png` in my `app/assets/images/` directory, visiting the url `localhost:3000/assets/sample_image.png` in a browser would display the image to me. Meaning that `/assets/sample_image.png` is my path to that individual asset.

## The Problem

Sometimes we would like to use images directly in our react components or even component specific CSS. This can cause problems because it is difficult to maintain the relative path to assets in our pipeline. Normally, we would use erb to get around this, using something like `<img src="<%= asset_path('my-image.png') %>" />`. Unfortunately, that will not play well with webpack.

Now we could always just place these assets in our `app/assets/` directory like normal and then reference them in our react with things like `<img src="/assets/asset-name.ext" />`, and that would work! But that also will move this image out of our client side app, which isn't always ideal. Also hardcoding the path to an asset isn't a good approach considering file paths can always change, and that would then require a source code change. That's just no bueno.

So how do we get around this? And find the relative paths to our assets without hardcoding the paths?

## The Solution: The lowdown on Webpack's url-loader & file-loader, outputPaths and publicPaths

Loaders are an incredibly useful part of Webpack. Simply put, they allow you to load and bundle different types of sources/files (you can load anything from images, CSS, to CoffeeScript).

##### Url Loader vs. File Loader

Two very common, and quite useful, Webpack loaders are the [url-loader](https://github.com/webpack-contrib/url-loader) and the [file-loader](https://github.com/webpack-contrib/file-loader). They allow you to load and access files in an easy manner. Both of these loaders are incredibly similar to one another, and in fact work together to accomplish their goals, with a very slight difference. The url-loader will load any file(s) and when accessed, will return a Data Url that can be used to access the file(s) (commonly used to inline images). File-loader on the other hand, will bundle and output the file(s) to a desired directory so they can live in the assets on your webserver along with your outputted webpack bundle. These bundled assets can then be accessed by their public paths, making it very easy to include and use them in your JavaScript code.

The url-loader is great to use for smaller images! It is most commonly used with a set byte limit on the size of the files that can be loaded. When this is the case, anything below the byte limit will be loaded and returned as a Data Url. Anything that exceeds the byte limit, will delegate to file-loader for loading, passing any set query parameters as well to file-loader (if that sounds like gibberish right now, don't worry. You'll learn all about it soon!).

The benefit of using url-loader first, and falling back on file-loader, is that the use of Data Urls saves HTTP Requests that need to be made to fetch files. That is very important in regards to how fast a webpage will load. Generally speaking, the less HTTP requests that need to be made, the faster a page will load. For more information about usage, and the pros & cons of Data Urls read [here](https://css-tricks.com/data-uris/).

Note: _For the rest of this doc, we will be using file-loader. This is because its usage can be a little bit trickier and it is used as url-loader's back up. Keep in mind that the usage for the two are EXTREMELY similar. For more info about the url-loader's usage, check out its configuration for the `react_on_rails` sample app [here](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/webpack.client.base.config.js) (specifically lines 82-84)._

##### Configuring Webpack with file-loader

Once you have added file-loader (or whatever loader you would like to use) to your project, you can start configuring your `webpack.config.js` file to bundle these assets. Inside your `module["loaders"]` list you will add a new object to represent your loader. This loader will include a few attributes:

1. `test`: a regular expression that specifies the types of files that can be loaded.
2. `loader`: the name of the loader you will be using (in this doc we will be using [file-loader](https://github.com/webpack-contrib/file-loader))
3. `query`: query parameters are additional configuration options that get passed to the loader. This can either be appended to your `loader` attribute like follows:


```javascript
loader: "file-loader?name=[name].[ext]"
```

or as a JSON object:

```javascript
query: {
  name: "[name].[ext]"
}
```

both of these two example above do the exact same thing, just using different syntaxes. For the rest of this doc we will be using the JSON object style. For more information about webpack loaders, read [this](https://webpack.github.io/docs/using-loaders.html).

_For the sake of this doc, we're also going to add a `resolve["alias"]` inside our webpack.config to make it easier to include our assets in our jsx files. In `resolve["alias"]`, simply add:_

```javascript
'assets': path.resolve('./app/assets')
```

##### Configuring your file-loader Query Parameters

The first property we'll want to set is our file's resulting name after bundling. For now we're just going to use:

```javascript
name: "[name][md5:hash].[ext]"
```

This will just set the name to the file's original name + a md5 digested hash + the extension of the original file (.png, .jpg, etc).

Next we'll set the outputPath for our files. This is the directory we want the files to be placed in after webpack runs. When Webpack runs with file-loader, all files (in this case assets) that have been used in the bundled JavaScript will be bundled and outputted to the output destination. **Keep in mind that react_on_rails outputs by default to the `app/assets/webpack/` directory so when we specify the outputPath here it will be relative the `app/assets/webpack` directory.** You can set the outputPath to whatever you want, in this example we will add it to a directory `/app/assets/webpack/webpack-assets/`, and here's how we would do that:

```javascript
outputPath: "webpack-assets/"
```

Note: _You can output these files in the asset pipeline wherever you see fit. My preference is outputting somewhere inside the `app/assets/webpack/` directory just because anything in this directory is already ignored by git due to the react_on_rails generated gitignore, meaning they will not be added by git twice! (once in your `client/app/assets/` and once in your outputted path after webpack bundling)_

Lastly, we will set the publicPath to our file(s). This will be the endpoint on our rails web server that you can visit to reach the asset (if you don't know how this works, read the [intro](#using-webpack-bundled-assets-with-the-rails-asset-pipeline)). If you've been following the previous steps, you know that we set our outputPath for our assets to be absolute at `app/assets/webpack/webpack-assets/`, which your rails app should end up hosting at `/assets/webpack-assets/file-name+hash.ext` when the server is run.

Note: _If you're having a hard time figuring out what an asset's path will be on your rails server, simply run `rake assets:precompile` and `cd public/`. The path from there to your file will then be the path/url on your web server to that asset. On top of this, it is also a good idea to check out [this doc](./rails-assets.md) to understand how `react_on_rails` allows us to access these files after precompilation, when Rails applies another hash onto the asset._

Our publicPath setting will match the path to our outputted assets on our rails web server. Given our assets in this example will be outputted to `/app/assets/webpack/webpack-assets/` and hosted at `/assets/webpack-assets/`, our publicPath would be:

```javascript
publicPath: "/assets/webpack-assets/"
```

Voila! Your webpack setup is complete.

##### Adding/Using `client/` Assets

Now for the fun part, we actually get to use our client assets now. The first thing you'll want to do is create an assets directory inside your client directory. The best place for this directory is probably at `client/app/assets`. Put any assets you want in there, images, stylesheets, whatever. Now that the assets are in place, we can simply `import` or `require` them in our jsx files for use in our components. For example:

```javascript
import myImage from 'assets/images/my-image.png'; // This uses the assets alias we created earlier to map to the client/app/assets/ directory followed by `images/my-image.png`

export default class MyImageBox extends React.Component {
  constructor(props, context) {
    super(props, context);
  }

  render() {
    return <img src={myImage} />
  }
}
```

`myImage` in the example above will resolve to the path of that asset on the web server. Therefore using it as an img's source would then properly display the image/assets when this react component is rendered.

Note: **Any assets in our `client/` directory that are not imported/required for use in our jsx files will NOT be bundled and outputted by webpack.**

## Summary: Welcome people who are tired of reading

If you've read this far, you probably have a grip on everything. If you didn't, and want a condensed version, here you go:

- Add webpack's file-loader to your project
- Add a new loader module in your webpack.config.js file
- Set this loader's test attribute to a regex of the file extensions you would like to load
- Set the loader attribute to "file-loader"
- Set name to something like `"[name][md5:hash].[ext]"`
- Set outputPath attribute to directory of choice, relative to `app/assets/webpack` directory
- Set publicPath attribute, this should be the same as where the rails asset pipeline will serve your asset(s) on the server. See [this](#configuring-your-file-loader-query-parameters) for more info.
- Add assets directory in `client/app/`, and place whatever you would like in there
- Import or Require these files in your jsx and use them all you want!

### Here's a full example of a webpack.config.js configured with file-loader to load images:

```javascript
const webpack = require('webpack');
const path = require('path');

const devBuild = process.env.NODE_ENV !== 'production';
const nodeEnv = devBuild ? 'development' : 'production';

module.exports = {
  entry: [
    './app/bundles/HelloWorld/startup/registration',
  ],

  output: {
    filename: 'hello-world-bundle.js',
    path: '../app/assets/webpack'
  },

  resolve: {
    extensions: ['', '.js', '.jsx'],
    alias: {
      assets: path.resolve('./app/assets'), // Makes it easier to reference our assets in jsx files
      react: path.resolve('./node_modules/react'),
      'react-dom': path.resolve('./node_modules/react-dom'),
    },
  },

  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify(nodeEnv),
      }
    })
  ],
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        loader: 'babel-loader',
        exclude: /node_modules/,
      },
      {
        test: require.resolve('react'),
        use: {
          loader: 'imports-loader',
          options: {
            shim: 'es5-shim/es5-shim',
            sham: 'es5-shim/es5-sham',
          },
        }
      },
      {
        // The important stuff
        test: /\.(jpg|jpeg|png)(\?.*)?$/, // Load only .jpg .jpeg, and .png files
        use: {
          loader: 'file-loader', 
          options: {
            name: '[name][md5:hash].[ext]', // Name of bundled asset
            outputPath: 'webpack-assets/', // Output location for assets. Final: `app/assets/webpack/webpack-assets/`
            publicPath: '/assets/webpack-assets/' // Endpoint asset can be found at on Rails server
          }
        }
      }
    ]
  }
};
```

If you'd like to understand how react_on_rails handles these bundled assets after asset precompilation and in production mode, check out: [Rails Assets](./rails-assets.md).
