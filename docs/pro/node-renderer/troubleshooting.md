# Node Renderer Troubleshooting

## Worker restart configuration

- If you enable restarts (setting `allWorkersRestartInterval` and `delayBetweenIndividualWorkerRestarts`), use high values to avoid all workers being down simultaneously.
- If your app contains streamed pages that take time to complete, either don't set `gracefulWorkerRestartTimeout` or set it to a high value, so workers are not killed while serving active requests.

## Connection refused

If Rails cannot connect to the renderer, check:

1. The renderer is running (`curl http://localhost:3800/`)
2. `config.renderer_url` in `config/initializers/react_on_rails_pro.rb` matches the renderer's port
3. On Heroku, ensure the renderer is started via `Procfile.web` (see [Heroku deployment](./heroku.md))

## Memory issues

- Use `node --inspect` to profile memory (see [Profiling guide](../profiling-server-side-rendering-code.md))
- Use `config.ssr_pre_hook_js` to clear global state leaks between renders
- Enable rolling restarts as insurance against slow memory leaks

For additional troubleshooting, see the [main troubleshooting guide](../troubleshooting.md).
