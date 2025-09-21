# Upgrading rails/webpacker v3.5 to v4

The following steps can be followed to update a Webpacker v3.5 app to v4.

1. Update the gem `webpacker` and the package `@rails/webpacker`
1. Merge changes from the new default [babel.config.js](https://github.com/shakacode/react_on_rails/tree/master/lib/generators/react_on_rails/templates/base/base/babel.config.js.tt) to your `/babel.config.js`. If you are using React, you need to add `"@babel/preset-react"`, to the list of `presets`.
1. Copy the file [shakapacker.yml](https://github.com/shakacode/react_on_rails/tree/master/lib/generators/react_on_rails/templates/base/base/config/shakapacker.yml) to `/config/` (Note: newer versions use Shakapacker instead of Webpacker).
1. Check generator templates in [lib/generators/react_on_rails/templates](https://github.com/shakacode/react_on_rails/tree/master/lib/generators/react_on_rails/templates) for current configuration files.

Here is an [example commit of these changes](https://github.com/shakacode/react_on_rails-tutorial-v11/pull/1/files).
