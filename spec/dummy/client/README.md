Please see parent directory README.md.

# ESLint

The `.eslintrc` file is based on the AirBnb [eslintrc](https://github.com/airbnb/javascript/blob/master/linters/.eslintrc).

It also includes many eslint defaults that the AirBnb eslint does not include.

# Running linter

Running the linter:

```bash
yarn run lint
```

or to autofix

```bash
yarn run lint -- --fix
```

# Updating Node Dependencies

```bash
yarn global add npm-check-updates
```

```bash
# Make sure you are in the `client` directory, then run
cd client
npm-check-updates -u -a
yarn
```

Another option for upgrading:

```bash
yarn upgrade
```

Then confirm that the hot reload server and the Rails server both work fine. You
may have to delete `node_modules`.

# Adding Node Modules

Suppose you want to add a dependency to "module_name"....

Before you do so, consider:

1. Do we really need the module and the extra JS code?
2. Is the module well maintained?

```bash
cd client
yarn add module_name@version
# or
# yarn add --dev module_name@version
```
