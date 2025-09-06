## How to use different versions of a file for client and server rendering

There are 3 main ways to use different code for server vs. client rendering.

## A. Using different Entry Points

Many projects will have different entry points for client and server rendering. This only works for a top-level entry point such as the entry point for a React Router app component.

Your Client Entry can look like this:

```js
import ReactOnRails from 'react-on-rails/client';
import App from './ClientApp';
ReactOnRails.register({ App });
```

So your Server Entry can look like:

```js
import ReactOnRails from 'react-on-rails';
import App from './ServerApp';
ReactOnRails.register({ App });
```

Note that the only difference is in the imports.

## B. Two Options for Using Webpack Resolve Alias in the Webpack Config

Per [Webpack Docs](https://webpack.js.org/configuration/resolve/#resolve-alias).

### 1. Update `webpack/set-resolve.js` to have a different resolution for the exact file

```js
function setResolve(builderConfig, webpackConfig) {

  // Use a different resolution for Client and Server file
  let SomeJsFile;
  if (builderConfig.serverRendering) {
    SomeJsFile = path.resolve(__dirname, "../bundles/SomeJsFileServer");
  } else {
    SomeJsFile = path.resolve(__dirname, "../bundles/SomeJsFileClient");
  }

 const resolve = {
    alias: {
      ... // blah blah
      SomeJsFile,
      ... // blah blah
    },
```

Then you have this import:

```js
import SomeJsFile from 'SomeJsFile';
```

### 2. Use a different resolution for the right directory of client or server files

#### a. Update `webpack/set-resolve.js` to have something like

```js
function setResolve(builderConfig, webpackConfig) {

  // Use a different resolution for Client and Server file
  let variant;
  if (builderConfig.serverRendering) {
    variant = path.resolve(__dirname, "../bundles/variant/ClientOnly");
  } else {
    variant = path.resolve(__dirname, "../bundles/variant/serverOnly");
  }

 const resolve = {
    alias: {
      ... // blah blah
      variant
      ... // blah blah
    },
```

#### b. Add different versions of the file to the `bundles/variant/ClientOnly` and `bundles/variant/ServerOnly` directories

#### c. Use the `variant` in import in a file that can be used both for client and server rendering

```js
import SomeJsFile from 'variant/SomeJsFile';
import AnotherJsFile from 'variant/AnotherJsFile';
```

## C. Conditional code that can check if `window` is defined.

This is probably the ugliest and hackiest way to do this, but it's quick! Essentially you wrap code that cannot execute server side in a conditional:

```js
if (window) {
  // window should be falsy on the server side
  doSomethingClientOnly();

  // or do an import
  const foobar = require('foobar').default;
}
```
