Using NPM for react_on_rails

* Use 'yalc link' to hook up the spec/dummy/client/node_modules to the top level
* Be sure to install yarn dependencies in spec/dummy/client

## Initial setup

Read [Dev Initial Setup in Tips for Contributors](/CONTRIBUTING.md#dev-initial-setup).

## Setup yalc

```sh
cd react_on_rails
bundle install
yalc publish
cd spec/dummy
bundle install
yalc link react-on-rails
```

## Run yarn if not done yet

```sh
cd react_on_rails
yarn run dummy:install 
cd spec/dummy
yarn rescript:build
```

# Starting the Sample App


## Hot Reloading of Rails Assets

```sh
foreman start -f Procfile.dev
```

## Static Loading of Rails Assets
```sh
foreman start -f Procfile.dev-static
```

## Creating Assets for Tests
```sh
foreman start -f Procfile.spec
```
