Example NPM Package
===========================
We've included an example package.json from https://github.com/shakacode/react-webpack-rails-tutorial which should get you started with your React project.

Starting the node.js server:
```
npm start
```

Building client javascript files for production:
```
npm run build:client
```

Building server javascript files for production:
```
npm run build:server
```

Building client javascript files for development:
```
npm run build:dev:client
```

Building server javascript files for development:
```
npm run build:dev:server
```

Running all linters:
```
npm run lint
```

Running eslint:
```
npm run eslint
```

Running jscs:
```
npm run jscs
```

dependencies vs devDependencies
===========================
Anything needed for heroku deployment needs to go in "dependencies", and anything not needed for heroku deployment should go in "devDependencies".


Updating Node Dependencies
===========================

```
npm install -g npm-check-updates
```

Then run this to update the dependencies (starting at the top level).

```
# Make sure you are in the top directory, then run:
cd client
rm npm-shrinkwrap.json
npm-check-updates -u
npm install
npm prune
npm shrinkwrap
```

Then confirm that the hot reload server and the rails server both work fine. You
may have to delete `node_modules` and `npm-shrinkwrap.json` and then run `npm
shrinkwrap`.

Note: `npm prune` is required before running `npm shrinkwrap` to remove dependencies that are no longer needed after doing updates.


Adding Node Modules
=====================================
Suppose you want to add a dependency to "module_name"....

Before you do so, consider:

1. Do we really need the module and the extra JS code?
2. Is the module well maintained?

```bash
cd client
npm install --save module_name@version
# or
# npm install --save_dev module_name@version
rm npm-shrinkwrap.json
npm shrinkwrap
```

Setting Up a Basic REST API
=====================================
See server.js in our tutorial at
https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/server.js
