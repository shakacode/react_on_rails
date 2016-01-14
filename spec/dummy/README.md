Using NPM for react_on_rails

* Use 'npm link' to hook up the spec/dummy/client/node_modules to the top level
* Be sure to install npm dependencies in spec/dummy/client

## Setup npm link

```sh
cd react_on_rails
npm link
cd spec/dummy/client
npm link react_on_rails
```

## Run npm i if not done yet

```sh
cd react_on_rails
npm run dummy:install 
```

## Starting the spec/dummy

```sh
npm run local
```
