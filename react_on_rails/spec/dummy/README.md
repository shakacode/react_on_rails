Using NPM for React on Rails

- Use `yalc link` to hook up the spec/dummy/client/node_modules to the top level
- Be sure to install NPM dependencies in spec/dummy/client

## Initial setup

Read [Dev Initial Setup in Tips for Contributors](/CONTRIBUTING.md#dev-initial-setup).

## Set up yalc

```sh
cd packages/react-on-rails
pnpm install
pnpm build
yalc publish
cd ../../react_on_rails
bundle install
cd spec/dummy
bundle install
yalc link react-on-rails
```

## Run PNPM if not done yet

```sh
pnpm install -r
cd react_on_rails/spec/dummy
pnpm build:rescript
```

# Starting the Sample App

## Hot Reloading of Rails Assets

```sh
foreman start -f Procfile.dev
```

## Static Loading of Rails Assets

```sh
foreman start -f Procfile.dev-static-assets
```
