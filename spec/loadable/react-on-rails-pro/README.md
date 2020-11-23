# Example of Standalone Install
This directory is an example of how to install the React on Rails Pro Node Renderer in its own
subdirectory so that you can remove your main `node_modules` directory after `assets::precompile`.

# Notes
1. This directory uses `yarn` to install the renderer. For your app, you will use `npm install` as
yarn has issues with private github packages.
2. Replace the `<TOKEN>` in the `.npmrc` file with your given token.
3. In the `package.json`, use a line like this to include the namespace.
   ```json
   "@shakacode-tools/react-on-rails-pro-vm-renderer": "1.5.4"
   ```
4. In the `react-on-rails-pro-node-renderer.js` file, use a line like:
   ```js
   const {
     reactOnRailsProVmRenderer,
   } = require('@shakacode-tools/react-on-rails-pro-vm-renderer')
   ```
