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

## References

* [Heroku Node Settings](https://github.com/damianmr/heroku-node-settings)
