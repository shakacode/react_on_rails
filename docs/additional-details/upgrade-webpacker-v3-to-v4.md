# Upgrading rails/webpacker v3.5 to v4 (Outdated)

_Note: This guide is outdated. The configuration files it references were removed when React on Rails moved to Shakapacker. For migrating from Webpacker to Shakapacker, see the Shakapacker guide to upgrading to [version 6](https://github.com/shakacode/shakapacker/blob/master/docs/v6_upgrade.md) and [version 7](https://github.com/shakacode/shakapacker/blob/master/docs/v7_upgrade.md)._

The following steps can be followed to update a Webpacker v3.5 app to v4.

1. Update the gem `webpacker` and the package `@rails/webpacker`
1. Merge changes from the new default `.babelrc` to your `/.babelrc`. If you are using React, you need to add `"@babel/preset-react"`, to the list of `presets`.
1. Copy the file `.browserslistrc` to `/`.
1. Merge any differences between `config/webpacker.yml` and your `/config/webpacker.yml`.

Here is an [example commit of these changes](https://github.com/shakacode/react_on_rails-tutorial-v11/pull/1/files).
