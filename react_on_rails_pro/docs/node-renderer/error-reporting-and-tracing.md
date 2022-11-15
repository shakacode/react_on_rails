# Error Reporting and Tracing for Sentry and HoneyBadger

## Sentry
1. Create a new Sentry Node project. After creating it, you will get directed to a [page like this](https://sentry.io/react-on-rails-pro/nodejs/getting-started/node/). You need to know your
1. Install these 2 packages: `@sentry/node` and `@sentry/tracing`.
2. Set the `sentryDsn` config value. To find your DSN, click on the gear icon next to your project
   name to get to the settings screen. Then click on the left side menu **Client Keys (DSN)**.

### Sentry Tracing
To use this feature, you need to add `config.sentryTracing = true` (or ENV `SENTRY_TRACING=true`)
and optionally the `config.sentryTracesSampleRate = 0.1` (or ENV `SENTRY_TRACES_SAMPLE_RATE=0.1`).
The value of the sample rate is the percentage of requests to trace. The default
**config.sentryTracesSampleRate** is **0.1**, meaning 10% of requests are traced.

For documentation of Sentry Tracing, see the
* [Sentry Performance Monitoring Docs](https://docs.sentry.io/platforms/ruby/performance/)
* [Sentry Distributed Tracing Docs](https://docs.sentry.io/product/performance/distributed-tracing/)
* [Sentry Sampling Transactions Docs](https://docs.sentry.io/platforms/ruby/performance/sampling/).

## Honeybadger
1. Install package: `@honeybadger-io/js`
2. Set the `honeybadgerApiKey` config value.
