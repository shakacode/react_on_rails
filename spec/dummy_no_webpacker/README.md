Using NPM for react_on_rails

* Use 'yarn link' to hook up the spec/dummy/client/node_modules to the top level
* Be sure to install yarn dependencies in spec/dummy/client

## Setup yarn link

```sh
cd react_on_rails
yarn link
cd spec/dummy/client
yarn link react_on_rails
```

## Run yarn if not done yet

```sh
cd react_on_rails
yarn run dummy:install 
```

# Starting the Sample App


## Hot Reloading of Rails Assets

```sh
foreman start -f Procfile.hot
```

## Static Loading of Rails Assets
```sh
foreman start -f Procfile.static
```

## Creating Assets for Tests
```sh
foreman start -f Procfile.spec
```


# NOTES on the dummy_no_webpacker testing setup

1. As many files are replaced with symlinks as possible.
2. The routes.rb file is slightly different to support the old rails.
3. The client/app folder cannot use a symlink or else you get the below error.
4. The specs are common with the /spec/dummy folder, so be aware of changing the app and specs there. You may have to copy over the changed files if they are not symlinked.



```
https://travis-ci.org/shakacode/react_on_rails/jobs/369435000
Building Webpack assets...
================================================================================
React on Rails FATAL ERROR!
Error in building webpack assets!
cmd: cd "client" && yarn run build:test
exitstatus: 1
stdout:
yarn run v0.27.5
$ yarn run build:client && yarn run build:server
Webpack dev build for Rails
Hash: 49f5ea122a19622c08e4
Version: webpack 2.7.0
Time: 311ms
           Asset     Size  Chunks             Chunk Names
   app-bundle.js  2.31 kB       0  [emitted]  app
vendor-bundle.js  5.95 kB       1  [emitted]  vendor
   [0] /home/travis/build/shakacode/react_on_rails/spec/dummy/client/app/startup/clientRegistration.jsx 1.84 kB {0} [built] [failed] [1 error]
   [1] multi ./app/startup/clientRegistration 28 bytes {0} [built]
ERROR in /home/travis/build/shakacode/react_on_rails/spec/dummy/client/app/startup/clientRegistration.jsx
Module build failed: ReferenceError: Unknown plugin "react-hot-loader/babel" specified in "/home/travis/build/shakacode/react_on_rails/spec/dummy/client/.babelrc" at 0, attempted to resolve relative to "/home/travis/build/shakacode/react_on_rails/spec/dummy/client"
    at /home/travis/build/shakacode/react_on_rails/spec/dummy_no_webpacker/client/node_modules/babel-core/lib/transformation/file/options/option-manager.js:180:17
    at Array.map (<anonymous>)
    at Function.normalisePlugins (/home/travis/build/shakacode/react_on_rails/spec/dummy_no_webpacker/client/node_modules/babel-core/lib/transformation/file/options/option-manager.js:158:20)
    at OptionManager.mergeOptions (/home/travis/build/shakacode/react_on_rails/spec/dummy_no_webpacker/client/node_modules/babel-core/lib/transformation/file/options/option-manager.js:234:36)
    at OptionManager.init (/home/travis/build/shakacode/react_on_rails/spec/dummy_no_webpacker/client/node_modules/babel-core/lib/transformation/file/options/option-manager.js:368:12)
    at File.initOptions (/home/travis/build/shakacode/react_on_rails/spec/dummy_no_webpacker/client/node_modules/babel-core/lib/transformation/file/index.js:212:65)
    at new File (/home/travis/build/shakacode/react_on_rails/spec/dummy_no_webpacker/client/node_modules/babel-core/lib/transformation/file/index.js:135:24)
    at Pipeline.transform (/home/travis/build/shakacode/react_on_rails/spec/dummy_no_webpacker/client/node_modules/babel-core/lib/transformation/pipeline.js:46:16)
    at transpile (/home/travis/build/shakacode/react_on_rails/spec/dummy_no_webpacker/client/node_modules/babel-loader/lib/index.js:46:20)
    at Object.module.exports (/home/travis/build/shakacode/react_on_rails/spec/dummy_no_webpacker/client/node_modules/babel-loader/lib/index.js:163:20)
 @ multi ./app/startup/clientRegistration
info Visit https://yarnpkg.com/en/docs/cli/run for documentation about this command.
```
