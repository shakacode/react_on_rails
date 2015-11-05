# Node Dependencies and NPM
## Updating
After installing the files, you may want to update the node dependencies. This is analogous to updating gem versions:

```bash
cd client
npm install -g npm-check-updates
rm npm-shrinkwrap.json
npm-check-updates -u
npm install
npm prune
npm shrinkwrap
```

Confirm that the hot replacement dev server and the Rails server both work. You may have to delete `node_modules` and `npm-shrinkwrap.json` and then run `npm shrinkwrap`.

*Note: `npm prune` is required before running `npm shrinkwrap` to remove dependencies that are no longer needed after doing updates.*

## Adding New Dependencies
Typically, you can add your Node dependencies as you normally would. Occasionally, adding a new dependency may require removing and re-running `npm shrinkwrap`:

```bash
cd client
npm install --save module_name@version
# or
# npm install --save_dev module_name@version
rm npm-shrinkwrap.json
npm shrinkwrap
```
