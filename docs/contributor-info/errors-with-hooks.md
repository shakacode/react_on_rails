# Invalid hook call error

```
react.development.js:1465 Uncaught Error: Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for one of the following reasons:
1. You might have mismatching versions of React and the renderer (such as React DOM)
2. You might be breaking the Rules of Hooks
3. You might have more than one copy of React in the same app
See https://fb.me/react-invalid-hook-call for tips about how to debug and fix this problem.
```

The main reason to get this is due to multiple versions of React installed.

```
cd <top level>
npm ls react

cd spec/dummy
npm ls react
```

For the second one, you might get:

```
react_on_rails@ /Users/justin/shakacode/react-on-rails/react_on_rails/spec/dummy
├── react@16.13.1
└─┬ react-on-rails@12.0.0 -> /Users/justin/shakacode/react-on-rails/react_on_rails invalid
  └── react@16.13.1  extraneous

npm ERR! invalid: react-on-rails@12.0.0 /Users/justin/shakacode/react-on-rails/react_on_rails/spec/dummy/node_modules/react-on-rails
npm ERR! extraneous: react@16.13.1 /Users/justin/shakacode/react-on-rails/react_on_rails/spec/dummy/node_modules/react-on-rails/node_modules/react
```

Make sure there is only one version of React installed!

If you used yarn link, then you'll have two versions of React installed.

Instead use [Yalc](https://github.com/whitecolor/yalc).

```
cd <top level>
yalc publish

cd spec/dummy
yalc link react-on-rails
```
