# Node Dependencies, NPM, and Yarn
## Updating
After installing the files, you may want to update the node dependencies. This is analogous to updating gem versions:

```bash
cd client
yarn global add yarn-check-updates
npm-check-updates -a -u
yarn
```

Confirm that the hot replacement dev server and the Rails server both work. You may have to delete `node_modules` and then run `yarn`.

## Adding New Dependencies
Typically, you can add your Node dependencies as you normally would.

```bash
cd client
yarn add module_name@version
# or
# yarn add --dev module_name@version
```
