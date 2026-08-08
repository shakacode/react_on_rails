# Node Renderer: Heroku Deployment

> **Pro Feature** — Available with [React on Rails Pro](../../../pro/react-on-rails-pro.md).
> Free or very low cost for startups and small companies. [Upgrade or licensing details →](../../../pro/upgrading-to-pro.md#try-pro-risk-free)

Most React on Rails Pro installations of the Node SSR Renderer will deploy the Rails and Renderer
instances on the same server. This technique results in better performance since it avoids network
latency.

Scroll down if you want to have different servers.

## Deploying to the Same Server As Your App Server

[buildpack for runit](https://github.com/danp/heroku-buildpack-runit)

### Procfile

`/Procfile`

```text
web: bin/runsvdir-dyno
```

### Procfile.web

`/Procfile.web`

Your `/Procfile.web` should keep the `puma` line and use the `renderer` line that matches your
package manager:

| Package manager | `renderer` line                    |
| --------------- | ---------------------------------- |
| npm             | `renderer: npm run node-renderer`  |
| yarn            | `renderer: yarn run node-renderer` |
| pnpm            | `renderer: pnpm run node-renderer` |

For example, a complete `/Procfile.web` using pnpm:

```text
puma: bundle exec puma -C config/puma.rb
renderer: pnpm run node-renderer
```

Define the script in your root `package.json` so Heroku can run it from the app root:

```json
{
  "scripts": {
    "node-renderer": "node renderer/node-renderer.js"
  }
}
```

> **Note:** The script above relies on the default
> `port: process.env.RENDERER_PORT || 3800` in the JS configuration example. That default is fine
> for the same-dyno deployment above. If you deploy the renderer as a separate Heroku app, switch
> the renderer config to `process.env.PORT` instead of `RENDERER_PORT`.

Be sure your node-renderer script listens on the same port as the Rails `config.renderer_url`
value, for example `http://localhost:3800`.

### Modifying Precompile Task

_Not necessary if you are using [bundle caching](../bundle-caching.md) as doing so will result in the below being done automatically._

To avoid the initial round trip to get a bundle on the renderer, you can pre-stage the renderer cache during precompile.

See [lib/tasks/assets.rake](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/lib/tasks/assets.rake) for a couple tasks that you can use.

For same-dyno / same-filesystem deployments such as Heroku, the legacy
`react_on_rails_pro:pre_stage_bundle_for_node_renderer` task is deprecated: it emits a deprecation warning and delegates to `react_on_rails_pro:pre_seed_renderer_cache` with `MODE=symlink`. That mode pre-stages the same bundle-hash cache layout the renderer uses at runtime, but does so with symlinks instead of copies. Use `MODE=copy` (the default) for Docker/image-build workflows where the cache needs to be copied into an immutable artifact.

If you're not using the default cache location, set `RENDERER_SERVER_BUNDLE_CACHE_PATH` so the files stage into the right place. `RENDERER_BUNDLE_PATH` remains a deprecated compatibility alias.

Then you can use the rake task: `react_on_rails_pro:pre_seed_renderer_cache MODE=symlink`.

You might do something like this:

```ruby
Rake::Task["assets:precompile"].enhance do
  ReactOnRailsPro::PreSeedRendererCache.call(mode: :symlink)
end
```

## Troubleshooting

If you get this sort of error, then you're forgetting to configure the PORT on the node-renderer and
setting the config.renderer_url on the Rails App.

```text
bundler: failed to load command: puma (/app/vendor/bundle/ruby/2.6.0/bin/puma)
Errno::EADDRINUSE: Address already in use - bind(2) for "0.0.0.0" port 21752
  /app/vendor/bundle/ruby/2.6.0/gems/puma-4.3.3/lib/puma/binder.rb:229:in `initialize'
```

## Separate Rails and Node Render Instances

### Deploy Node renderer to Heroku

1. Create your **Heroku** app with **Node.js** buildpack, say `renderer-test.herokuapp.com`.
2. In your JS configuration file or
   1. If setting the port, ensure the port uses `process.env.PORT` so it will use port number provided by **Heroku** environment. The default is to use the env value `RENDERER_PORT` if available.
   2. Set password in your configuration to something like `process.env.RENDERER_PASSWORD` and configure the corresponding **ENV variable** on your **Heroku** dyno so the `config/initializers/react_on_rails_pro.rb` uses this value.
3. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
4. Once deployment process is finished, renderer should start listening from something like `renderer-test.herokuapp.com` host.

### Deploy react_on_rails application to Heroku

1. Create your **Heroku** app for `react_on_rails`.
2. Configure your app to communicate with renderer app you've created above. Put the following to your `initializers/react_on_rails_pro` (assuming you have **SSL** certificate uploaded to your renderer **Heroku** app or you use **Heroku** wildcard certificate under `*.herokuapp.com`) and configure corresponding **ENV variable** for the render_url and/or password on your **Heroku** dyno.
3. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
4. Once deployment process is finished, all rendering requests form your `react_on_rails` app should be served by `<your-heroku-app>.herokuapp.com` app via **HTTPS**.

## References

- [Heroku Node Settings](https://github.com/damianmr/heroku-node-settings)
