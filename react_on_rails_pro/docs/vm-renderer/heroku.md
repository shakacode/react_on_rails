# Heroku Deployment

## Deploy Node renderer to Heroku

1. Create your **Heroku** app with **Node.js** buildpack, say `renderer-test.herokuapp.com`.
2. In your JS configuration file or 
   1. If setting the port, ensure the port uses `process.env.PORT` so it will use port number provided by **Heroku** environment. The default is to use the env value RENDERER_PORT if available. (*TODO: Need to check on this*)
   2. Set password in your configuration to something like `process.env.RENDERER_PASSWORD` and configure the corresponding **ENV variable** on your **Heroku** dyno so the `config/initializers/react_on_rails_pro.rb` uses this value.
3. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
4. Once deployment process is finished, renderer should start listening from something like `renderer-test.herokuapp.com` host.

## Deploy react_on_rails application to Heroku

1. Create your **Heroku** app for `react_on_rails`. 
2. Configure your app to communicate with renderer app you've created above. Put the following to your `initializers/react_on_rails_pro` (assuming you have **SSL** certificate uploaded to your renderer **Heroku** app or you use **Heroku** wildcard certificate under `*.herokuapp.com`) and configure corresponding **ENV variable** for the render_url and/or password on your **Heroku** dyno.
3. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
4. Once deployment process is finished, all rendering requests form your `react_on_rails` app should be served by `<your-heroku-app>.herokuapp.com` app via **HTTPS**.

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
vm-renderer: bin/vm-renderer
```

### bin/vm-renderer

```
#!/bin/bash
cd client
yarn run vm-renderer
```

### vm-renderer
Any task in client/package.json that starts the vm-renderer

### Modifying Precompile Task

To avoid the initial round trip to get a bundle on the renderer, you can do something like this to copy the file during precompile.

Note, this is a sample. You'll have to configure for your paths used in your renderer setup.

Create `lib/tasks/assets.rake`:

```ruby
Rake::Task["assets:precompile"]
    .clear_prerequisites
    .enhance([:environment, "react_on_rails:assets:compile_environment"])
    .enhance do
  Rake::Task["react_on_rails:assets:symlink_non_digested_assets"].invoke
  Rake::Task["react_on_rails:assets:delete_broken_symlinks"].invoke
  Rake::Task["react_on_rails:assets:pre_stage_bundle_for_vm_renderer"].invoke
end

namespace :react_on_rails do
  namespace :assets do
    task :pre_stage_bundle_for_vm_renderer => :environment do
      src_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
      renderer_bundle_file_name = ReactOnRailsPro::ServerRenderingPool::VmRenderingPool.renderer_bundle_file_name
      dest_path = Rails.root.join('tmp', 'vm-renderer-bundles', "#{renderer_bundle_file_name}").to_s
      mkdir_p Rails.root.join("tmp", "vm-renderer-bundles")
      cp src_bundle_path, dest_path
    end
  end
end
```

## References

* [Heroku Node Settings](https://github.com/damianmr/heroku-node-settings)
