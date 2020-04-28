# Proof of Concept combination of ReactOnRails Pro, Loadable Components, and Hot Module Replacement

## References
1. [Loadable-Components Official Site](https://loadable-components.com/)
2. [React on Rails Pro Docs](https://github.com/shakacode/react_on_rails_pro/blob/master/docs/code-splitting-loadable-components.md)

## Why Change from React-Loadable & React-Hot-Loader?
1. It's the official way as of March 2020 to use dyanamic code splitting with React.
2. react-loadable:
   1. Is not supported for recent versions of React and Webpack
   2. Required ugly code of `#if` from the webpack-conditional-loader

## Setup
1. Run these commands. Ignore the warning on the db:setup. 
```
yarn
bundle
rails db:setup
```

## HMR via React Fast Refresh and the NormalModuleReplacementPlugin
Loadable Components does not work with HMR.

HMR is enabled by using the [NormalModuleReplacementPlugin](https://webpack.js.org/plugins/normal-module-replacement-plugin/)
to swap out the files with suffix `.imports-loadable` with `imports-hmr`.

## Testing Hot Module Replacement
1. Run the following command:
```
foreman start -f Procfile.dev-hot
```
1. Wait for the server & client bundles to compile
1. Navigate to http://localhost:3000/
1. Edit some of the javascript front-end code in `/app/javascript`
1. Watch the web page update without refreshing

## Testing Loadable Components (Code Splitting)
1. Install ruby gems & node packages
1. Run the following command:
```
foreman start -f Procfile.dev-hot
```
1. Wait for the server & client bundles to compile
1. Navigate to http://localhost:3000/
1. Check the network tab of your browsers devtools to confirm separate requests for the page A/B chunks
