# React on Rails Pro: Quick Start from Scratch

This guide walks you through creating a complete React on Rails Pro application with server-side rendering via the Node Renderer, from an empty directory to a running app.

**Time:** ~5 minutes

**Prerequisites:** Ruby 3.0+, Rails 7.0+, Node.js 18+, npm/yarn/pnpm

## Step 1: Create a new Rails app

```bash
rails new my-pro-app --skip-javascript --skip-docker
cd my-pro-app
```

`--skip-javascript` is required because Shakapacker handles JavaScript bundling.

## Step 2: Add gems

```ruby
# Append to Gemfile
gem "shakapacker", "~> 9.5"
gem "react_on_rails", "~> 16.3"
gem "react_on_rails_pro", "~> 16.3"
```

Then install:

```bash
bundle install
```

## Step 3: Install Shakapacker

```bash
rails shakapacker:install
```

## Step 4: Commit (required by generator)

The React on Rails generator requires a clean git working tree:

```bash
git add -A && git commit -m "Rails app with Shakapacker"
```

## Step 5: Install React on Rails with Pro

This single command sets up everything — base React on Rails, Pro configuration, Node Renderer, webpack configs, and npm packages:

```bash
rails generate react_on_rails:install --pro
```

The `--pro` flag creates:

| File | Purpose |
|------|---------|
| `config/initializers/react_on_rails.rb` | Base React on Rails config |
| `config/initializers/react_on_rails_pro.rb` | Pro config with NodeRenderer settings |
| `client/node-renderer.js` | Fastify-based Node.js SSR server entry |
| `config/webpack/serverWebpackConfig.js` | Server webpack config with `target: 'node'` and `libraryTarget: 'commonjs2'` |
| `app/javascript/src/HelloWorld/` | Example React component with SSR |
| `app/controllers/hello_world_controller.rb` | Rails controller |
| `app/views/hello_world/index.html.erb` | View using `react_component` helper |
| `Procfile.dev` | All dev processes including Node Renderer |

Commit:

```bash
git add -A && git commit -m "react_on_rails:install --pro"
```

## Step 6: Start the app

```bash
./bin/dev
```

This starts four processes:
- **Rails server** on port 3000
- **Webpack dev server** (HMR) on port 3035
- **Webpack SSR watcher** for server bundle
- **Node Renderer** on port 3800

## Step 7: Visit the app

Open [http://localhost:3000/hello_world](http://localhost:3000/hello_world)

You should see the HelloWorld component rendered with SSR. View the page source to confirm pre-rendered HTML. The input field is interactive (client-side hydration).

## What the generator configured

### Rails-side (config/initializers/react_on_rails_pro.rb)

```ruby
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.renderer_url = ENV.fetch("REACT_RENDERER_URL", "http://localhost:3800")
  config.renderer_password = ENV.fetch("RENDERER_PASSWORD", "devPassword")
  config.prerender_caching = true
end
```

### Node-side (client/node-renderer.js)

```js
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');

reactOnRailsProNodeRenderer({
  serverBundleCachePath: path.resolve(__dirname, './.node-renderer-bundles'),
  port: Number(process.env.RENDERER_PORT) || 3800,
  supportModules: true,
  workersCount: Number(process.env.NODE_RENDERER_CONCURRENCY || 3),
});
```

### Key configuration options

| Rails Config | Node Config | Purpose |
|-------------|-------------|---------|
| `config.renderer_url` | `port` | Must point to the same host:port |
| `config.renderer_password` | `password` | Shared authentication secret |
| `config.prerender_caching` | — | Cache SSR results in Rails cache |
| `config.server_renderer` | — | Must be `"NodeRenderer"` to use the Node process |

## Adding React Server Components

To add RSC support to your Pro app:

```bash
rails generate react_on_rails:rsc
```

Or for a fresh app with RSC from the start:

```bash
rails generate react_on_rails:install --rsc
```

See the [RSC tutorial](https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/tutorial/) for details.

## Next Steps

- [Configuration Reference](https://www.shakacode.com/react-on-rails-pro/docs/configuration/) — All Pro config options
- [Node Renderer Configuration](https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/js-configuration/) — All Node Renderer options
- [Caching Guide](https://www.shakacode.com/react-on-rails-pro/docs/caching/) — Fragment and prerender caching
- [Streaming SSR](https://www.shakacode.com/react-on-rails-pro/docs/streaming-server-rendering/) — Progressive rendering
- [Code Splitting](https://www.shakacode.com/react-on-rails-pro/docs/code-splitting/) — Loadable components with SSR

## Troubleshooting

**"uninitialized constant ReactOnRailsPro"**: The `react_on_rails_pro` gem is not in your Gemfile. Run `bundle add react_on_rails_pro`.

**"You have the Pro gem installed but are using the base 'react-on-rails' package"**: Uninstall `react-on-rails` and install `react-on-rails-pro` instead. The `--pro` generator handles this automatically.

**Node Renderer not connecting**: Ensure the `renderer_url` in `react_on_rails_pro.rb` matches the `port` in `node-renderer.js` (default: 3800).

**Server bundle errors**: Ensure `serverWebpackConfig.js` has `target: 'node'` and `libraryTarget: 'commonjs2'` set. The `--pro` generator configures this automatically.
