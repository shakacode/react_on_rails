# Upgrading to *react_on_rails* Version 8+ with *webpacker_lite* 

The newest version of *react_on_rails*, 8.0.0, has some key differences compared to version 7.0.4. Most notably, version 8.0.0 will be using the latest version of [webpacker_lite](https://github.com/shakacode/webpacker_lite). This means your webpack-bundles will be placed in your *public* directory and they will not be processed by the asset pipeline. 

Note, you don't *have to* use webpacker_lite, you can simply upgrade the gem and npm versions. Version 8.0.0 still supports putting assets through the asset pipeline. You may need to refer the [version 7.0.4 docs](https://github.com/shakacode/react_on_rails/tree/7.0.4).
 
*Note: These instructions are for 8.0.0, but you should substitute whatever the latest version number is.*

1. Add `gem 'react_on_rails', '8.0.0'` to your Gemfile
2. Add `“react-on-rails": "8.0.0",` to your client/package.json
3. Add `webpacker_lite`, "~>2"` to your Gemfile
4. Configure webpacker_lite
 
                           
Please refer to this [PR #xxxx]() for an example of the upgrade.
  
## Configure webpacker_lite  


1. The webpacker_lite gem generates its webpack assets in the public directory. Thus, you will need to configure your generated assets directory so that they match up with webpacker_lite.

   For example, if your config/initializers/react_on_rails.rb looks like this:
   ```
   config.generated_assets_dir = File.join(%w(app assets webpack))
   ```
   you can change it to this:
   ```
   config.generated_assets_dir = File.join(%w(public webpack)) 
   ```
2. Every time you run your app, webpacker_lite will generate fresh assets/webpack-bundles. Thus, every time you run your app, you'll want to make sure you remove any previously generated webpack assets from your `/public` directory. In general, you can simply remove your `/public/webpack` directory entirely on each run, or you can simply remove the assets for your current environment in case you're running your app in two environments at once, such as test *and* development. 

    For example, on thing you can do is change your Procfile.dev so that it removes the contents of your `public/webpack/development` folder. You can do this by adding the following command *before* your command to run the app:
   ```
   rm -rf public/webpack/development
   ```  
   Your Procfile.dev may end up looking something like this:
   ```
   rails-client-assets: rm -rf public/webpack/development || true && bundle exec rake react_on_rails:locale && yarn run build:dev:client
   ``` 
3. In webpacker_lite, a .yml file called `config/webpacker_lite.yml` is used to configure webpack's manifest. Thus, you'll want to create a file in your `/config` directory called `webpacker_lite.yml`. You'll want to configure it so that it creates a webpack manifest.  Your manifest should be a .json file, typically called `manifest.json`. In `webpacker_lite.yml` you'll also need to configure which directory to put your webpack assets in. To keep things simple for you, here are some example contents of a typical `config/webpacker_lite.yml` file that would be generated for you by the react_on_rails generator. You can just copy/paste if this suits your needs:

    ```yml 
    # Note: Base output directory of /public is assumed for static files
    default: &default
      manifest: manifest.json
      # Used in your webpack configuration. Must be created in the
      # webpack_public_output_dir folder
    
    development:
      <<: *default
      # generated files for development, in /public/webpack/development
      webpack_public_output_dir: webpack/development
    
      # Default is localhost:3500
      hot_reloading_host: localhost:3500
    
      # Developer note: considering removing this option so it can ONLY be turned by using an ENV value.
      # Default is false, ENV 'HOT_RELOAD' will always override
      hot_reloading_enabled_by_default: false
    
    test:
      <<: *default
      # generated files for tests, in /public/webpack/test
      webpack_public_output_dir: webpack/test
    
    production:
      <<: *default
      # generated files for tests, in /public/webpack/production
      webpack_public_output_dir: webpack/production
    
    ```

4. You'll want to make sure you remove any references to your webpack bundles from any files in your asset pipeline. For example, a common reference you might have is a line in your `assets/javascripts/application.js` like the one shown below:
 
    ```javascript
     //= require webpack-bundle
    ```

5. You'll need to add the approrpriate webpacker_lite helpers to your layouts to load the files from  your public deployment directory. The helpers ensure that the bundle names are converted to the correct paths on your rails server. 

   For example, you can do this by adding something like this to your `application.html.erb`:
   ```erb
   <%= javascript_pack_tag 'main' %>
   ```

6. You'll need to configure your webpack-bundle files so that they are placed into your public directory and skip the asset pipeline. For example, you may have some javascript file in your client directory called something like `webpack.config.js`. This webpack config file should have some output code that dictates what path your webpack-bundles are placed into. For example, a change to your code might look something like this:

    ```javascript
    // client/webpack.config.js 
    // before
    output: {
      filename: 'webpack-bundle.js',
      path: pathLib.resolve(__dirname, '../app/assets/webpack'),
    },
    ```
    
    ```javascript
    // client/webpack.config.js
    // after
    output: {
      filename: 'webpack-bundle.js',
      path: pathLib.resolve(__dirname, '../app/public/webpack'),
    },
    ```
    
7. You'll also need to configure webpack to use your manifest appropriately. You'll need to configure webpack to knows your manifest's location and so on. 

   Luckily, react_on_rails makes this easy by using a module called webpackConfigLoader. You can use webpackConfigLoader by simply using `require/webpackConfigLoader`.

    Your manifest will be a key-value pairing that maps generic webpack-bundle filenames to fingerprinted filenames. Thus, you'll want to configure webpack to use the manifest so t

## Update Your `webpack.config.js`
1. Delete your `const pathLib` statement and replace it with the following:
```javascript
const { resolve } = require('path');
```

2. Require the following 2 items
```javascript 
const ManifestPlugin = require('webpack-manifest-plugin');
const webpackConfigLoader = require('react-on-rails/webpackConfigLoader');
```



explain the why to get the webpackConfigLoader to work



3. Initialize your *configPath*:
```javascript
const configPath = resolve('..', 'config');
```

4. Remove the initialization of your *devBuild*:
```javascript
const devBuild = process.env.NODE_ENV !== 'production';
```

5. Replace it with this:
```javascript
const { devBuild, manifest, webpackOutputPath, webpackPublicOutputDir } =
  webpackConfigLoader(configPath);
```

6. In your *config* object, set *context*:
```javascript
context: resolve(__dirname),
```
 
7. Your *entry* might be an array. Change it to an object and add an attribute called  *Entry* should now be an object with a *webpack-bundle* attribute that is the array that the entry attribute originally pointed to
  - In your *entry* object, add a key *webpack-bundle*: that has *entry’s original array value as the *webpack-bundle* value. It should look something like this:
```javascript
entry: {
    'webpack-bundle': [
      'es5-shim/es5-shim',
      'es5-shim/es5-sham',
      'babel-polyfill',
      './app/bundles/HelloWorld/startup/registration',
    ],
  },
```

8. In your *output object*, change *filename* to this:
```javascript
// Name comes from the entry section.
filename: ‘[name]-[hash].js’,
```

9. Add a *publicPath attribute* to the *output object* like this:
```javascript
// Leading slash is necessary
publicPath: `/${webpackPublicOutputDir}`,
```

10. Change your *output object’s path attribute* to this:
```javascript
path: webpackOutputPath,
```

11. Add the following element to your *plugins* array
```javascript
new ManifestPlugin({ fileName: manifest, writeToFileEmit: true }),
```

12. add the following to your ```client/package.json``` and then run ```yarn install```:
```json
"js-yaml": "^3.8.4",
"webpack-manifest-plugin": “^1.1.0"
```
