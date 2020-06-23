Using NPM for react_on_rails

* Use 'yalc link' to hook up the spec/dummy/client/node_modules to the top level
* Be sure to install yarn dependencies in spec/dummy/client

## Setup yalc

```sh
cd react_on_rails
yalc publish
cd spec/dummy
yalc link react-on-rails
```

## Run yarn if not done yet

```sh
cd react_on_rails
yarn run dummy:install 
```

# Starting the Sample App


## Hot Reloading of Rails Assets

```sh
foreman start -f Procfile.hot
```

## Static Loading of Rails Assets
```sh
foreman start -f Procfile.dev
```

## Creating Assets for Tests
```sh
foreman start -f Procfile.spec
```

