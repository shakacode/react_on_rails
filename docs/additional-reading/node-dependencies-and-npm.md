# Node Dependencies, NPM, and Yarn

## Updating

You can check for outdated versions of packages with `yarn outdated` in your `client` directory.

To upgrade package version, use `yarn upgrade [package]`.  To update all dependencies, use `yarn upgrade`.

Confirm that the hot replacement dev server and the Rails server both work.

## Adding New Dependencies
Typically, you can add your Node dependencies as you normally would.

```bash
cd client
yarn add module_name@version
# or
# yarn add --dev module_name@version
```
