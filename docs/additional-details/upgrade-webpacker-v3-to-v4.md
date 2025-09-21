# Upgrading rails/webpacker v3.5 to v4 (Outdated)

_Note: This document is outdated. The configuration files referenced below were removed from React on Rails. For current configuration, see the [install generator templates](https://github.com/shakacode/react_on_rails/tree/master/lib/generators/react_on_rails/templates) or consider upgrading to [Shakapacker](https://github.com/shakacode/shakapacker)._

The following steps could be followed to update a Webpacker v3.5 app to v4:

1. Update the gem `webpacker` and the package `@rails/webpacker`
1. Merge changes from the new default `.babelrc` to your `/.babelrc`. If you are using React, you need to add `"@babel/preset-react"`, to the list of `presets`.
1. Copy the file `.browserslistrc` to `/`.
1. Merge any differences between `config/webpacker.yml` and your `/config/webpacker.yml`.

Here is an [example commit of these changes](https://github.com/shakacode/react_on_rails-tutorial-v11/pull/1/files).
