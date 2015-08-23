Please see parent directory README.md.

ESLint
==========================
The `.eslintrc` file is based on the AirBnb [eslintrc](https://github.com/airbnb/javascript/blob/master/linters/.eslintrc).

It also includes many eslint defaults that the AirBnb eslint does not include.

Running linter:
===========================

Soon to be in gulpfile....but gulp-eslint depends on eslint depends on 

```
    "eslint-plugin-react": "^2.0.2",
```

So don't use `npm run gulp lint` yet. 

For now: 

    bin/lint
    
    
Updating Node Dependenencies
===========================

```
npm install -g npm-check-updates
```
 
  
```
# Make sure you are in the `client` directory, then run:
cd client 
rm npm-shrinkwrap.json
npm-check-updates -u
npm install
npm shrinkwrap
```

Then confirm that the hot reload server and the rails server both work fine. You
may have to delete `node_modules` and `npm-shrinkwrap.json` and then run `npm
shrinkwrap`.

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
