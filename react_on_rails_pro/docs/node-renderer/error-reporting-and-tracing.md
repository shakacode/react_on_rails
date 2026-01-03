# Error Reporting and Tracing

[Please see this documentation for versions before 4.0.0](https://github.com/shakacode/react_on_rails_pro/blob/ac2afba93c672f49f16bf967d6accbed0fda386e/docs/node-renderer/error-reporting-and-tracing.md).

To integrate with error reporting and tracing services,
you need a custom configuration script as described in [Node Renderer JavaScript Configuration](./js-configuration.md).

It should initialize the services according to your requirements and then enable integrations.

## Sentry

1. [Set up Sentry](https://docs.sentry.io/platforms/javascript/guides/fastify/). You may create an `instrument.js` file as described there and require it in your configuration script, but it is simpler to call `Sentry.init` directly in your configuration script.
2. Call `Sentry.init` with the desired options according to [the documentation](https://docs.sentry.io/platforms/javascript/guides/fastify/configuration/).
3. Then load the integration:

   ```js
   require('react-on-rails-pro-node-renderer/integrations/sentry').init();
   ```

   - Use `react-on-rails-pro-node-renderer/integrations/sentry6` instead of `.../sentry` for versions of Sentry SDK older than 7.63.0.
   - For Sentry SDK v8+ you can use `.init({ fastify: true })` to capture additional Fastify-related information.

### Sentry Tracing

To enable Sentry Tracing:

1. Include `enableTracing`, `tracesSampleRate`, or `tracesSampler` in your `Sentry.init` call. See [the Sentry documentation](https://docs.sentry.io/platforms/javascript/tracing/) for details, but ignore `Sentry.browserTracingIntegration()`.
2. Depending on your Sentry SDK version:
   - if it is older than 7.63.0, install `@sentry/tracing` as well as `@sentry/node` (with the same exact version) and pass `integrations: [new Sentry.Integrations.Http({ tracing: true })]` to `Sentry.init`.
   - for newer v7.x.y, pass `integrations: Sentry.autoDiscoverNodePerformanceMonitoringIntegrations()`.
   - for v8.x.y, Node HTTP tracing is included by default.
3. Pass `{ tracing: true }` to the `init` function of the integration. It can be combined with `fastify: true`.

### Sentry Profiling

[Follow this documentation](https://docs.sentry.io/platforms/javascript/guides/fastify/profiling/).

## Honeybadger

1. [Set up Honeybadger](https://docs.honeybadger.io/lib/javascript/integration/node/). Call `Honeybadger.configure` with the desired options in the configuration script.
2. Then load the integration:

   ```js
   require('react-on-rails-pro-node-renderer/integrations/honeybadger').init();
   ```

   Use `init({ fastify: true })` to capture additional Fastify-related information.

## Other services

You can create your own integrations in the same way as the provided ones.
If you have access to the React on Rails Pro repository,
you can use [their implementations](https://github.com/shakacode/react_on_rails_pro/tree/master/packages/node-renderer/src/integrations) as examples.
Import these functions from `react-on-rails-pro-node-renderer/integrations/api`:

### Error reporting services

- `addErrorNotifier` and `addMessageNotifier` tell React on Rails Pro how to report errors to your chosen service.
- Use `addNotifier` if the service uses the same reporting function for both JavaScript `Error`s and string messages.

For example, integrating with BugSnag can be as simple as

```js
const Bugsnag = require('@bugsnag/js');
const { addNotifier } = require('react-on-rails-pro-node-renderer/integrations/api');

Bugsnag.start({
  /* your options */
});

addNotifier((msg) => {
  Bugsnag.notify(msg);
});
```

### Tracing services

- `setupTracing` takes an object with two properties:
  - `executor` should wrap an async function in the service's unit of work.
  - Since the only units of work we currently track are rendering requests, the options to start them are specified in `startSsrRequestOptions`.

To track requests as [sessions](https://docs.bugsnag.com/platforms/javascript/capturing-sessions/#startsession) in BugSnag 8.x+,
the above example becomes

```js
const Bugsnag = require('@bugsnag/js');
const { addNotifier, setupTracing } = require('react-on-rails-pro-node-renderer/integrations/api');

Bugsnag.start({
  /* your options */
});

addNotifier((msg) => {
  Bugsnag.notify(msg);
});
setupTracing({
  executor: async (fn) => {
    Bugsnag.startSession();
    try {
      return await fn();
    } finally {
      Bugsnag.pauseSession();
    }
  },
});
```

You can optionally add `startSsrRequestOptions` property to capture the request data:

```js
setupTracing({
  startSsrRequestOptions: ({ renderingRequest }) => ({ bugsnag: { renderingRequest } }),
  executor: async (fn, { bugsnag }) => {
    Bugsnag.startSession();
    // bugsnag will look like { renderingRequest }
    Bugsnag.leaveBreadcrumb('SSR request', bugsnag, 'request');
    try {
      return await fn();
    } finally {
      Bugsnag.pauseSession();
    }
  },
});
```

Bugsnag v7 is a bit more complicated:

```js
const Bugsnag = require('@bugsnag/js');
const { addNotifier, setupTracing } = require('react-on-rails-pro-node-renderer/integrations/api');

Bugsnag.start({
  /* your options */
});

addNotifier((msg, { bugsnag = Bugsnag }) => {
  bugsnag.notify(msg);
});
setupTracing({
  executor: async (fn) => {
    const bugsnag = Bugsnag.startSession();
    try {
      return await fn({ bugsnag });
    } finally {
      bugsnag.pauseSession();
    }
  },
});
```

### Fastify integrations

If you want to report HTTP requests from Fastify, you can use `configureFastify` to add hooks or plugins as necessary.
Extending the above example:

```js
const { configureFastify } = require('react-on-rails-pro-node-renderer/integrations/api');

configureFastify((app) => {
  app.addHook('onError', (_req, _reply, error, done) => {
    Bugsnag.notify(error);
    done();
  });
});
```

You could also treat Fastify requests as sessions
using [onRequest](https://fastify.dev/docs/latest/Reference/Hooks/#onrequest)
or [preHandler](https://fastify.dev/docs/latest/Reference/Hooks/#prehandler) hooks.

It isn't recommended to use the [fastify-bugsnag](https://github.com/ZigaStrgar/fastify-bugsnag) plugin
since it wants to start Bugsnag on its own.
