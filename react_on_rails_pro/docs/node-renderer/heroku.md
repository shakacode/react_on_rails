# Heroku Deployment

Most React on Rails Pro installations of the Node SSR Renderer will deploy the Rails and Renderer
instances on the same server. This technique results in better performance since it avoids network
latency.

Scroll down if you want to have different servers.

## Deploying to the Same Server As Your App Server

[buildpack for runit](https://github.com/danp/heroku-buildpack-runit)

### Procfile

`/Procfile`

```
web: bin/runsvdir-dyno
```

### Procfile.web

`/Procfile.web`

```
puma: bundle exec puma -C config/puma.rb
renderer: bin/node-renderer
```

### bin/node-renderer

```
#!/bin/bash
cd client
yarn run node-renderer
```

Be sure your script to run the node-renderer sets some port, like 3800 which is also set as the
config.renderer_url for your Rails server.

### node-renderer

Any task in client/package.json that starts the node-renderer

### Modifying Precompile Task

_Not necessary if you are using [bundle caching](../bundle-caching.md) as doing so will result in the below being done automatically._

To avoid the initial round trip to get a bundle on the renderer, you can do something like this to copy the file during precompile.

See [lib/tasks/assets.rake](https://github.com/shakacode/react_on_rails_pro/blob/master/lib/tasks/assets.rake) for a couple tasks that you can use.

If you're using the default tmp/bundles subdirectory for the node-renderer, you don't need to set the
ENV value for `RENDERER_BUNDLE_PATH`. Otherwise, please set this ENV value so the files get copied
to the right place.

Then you can use the rake task: `react_on_rails_pro:pre_stage_bundle_for_node_renderer`.

You might do something like this:

```ruby
Rake::Task["assets:precompile"]
    .clear_prerequisites
    .enhance([:environment, "react_on_rails:assets:compile_environment"])
    .enhance do
  Rake::Task["react_on_rails_pro:pre_stage_bundle_for_node_renderer"].invoke
end
```

## Troubleshooting

If you get this sort of error, then you're forgetting to configure the PORT on the node-renderer and
setting the config.renderer_url on the Rails App.

```
bundler: failed to load command: puma (/app/vendor/bundle/ruby/2.6.0/bin/puma)
Errno::EADDRINUSE: Address already in use - bind(2) for "0.0.0.0" port 21752
  /app/vendor/bundle/ruby/2.6.0/gems/puma-4.3.3/lib/puma/binder.rb:229:in `initialize'
```

## Separate Rails and Node Render Instances

### Deploy Node renderer to Heroku

1. Create your **Heroku** app with **Node.js** buildpack, say `renderer-test.herokuapp.com`.
2. In your JS configuration file or
   1. If setting the port, ensure the port uses `process.env.PORT` so it will use port number provided by **Heroku** environment. The default is to use the env value RENDERER*PORT if available. (\_TODO: Need to check on this*)
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
