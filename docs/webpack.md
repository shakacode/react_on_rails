# Entry Points and Globally Exposing Objects

In `webpack.server.rails.config.js`, you should ensure you config the entry points correctly.

When `React.version >= '0.14'`, the entry points might include below:

```
['./app/bundles/HelloWorld/startup/serverGlobals', 'react-dom/server', 'react']
```

Otherwise, when `React.version < '0.14'`, then entry points will be:

```
['/app/bundles/HelloWorld/startup/serverGlobals']
```