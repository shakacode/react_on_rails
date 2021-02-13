# Upgrading rails/webpacker v3.5 to v4

The following steps can be followed to update a Webpacker v3.5 app to v4.

1. Update the gem `webpacker` and the package `@rails/webpacker`
1. Merge changes from the new default [.babelrc](https://github.com/shakacode/react_on_rails/tree/master/lib/install/config/.babelrc) to your `/.babelrc`. If you are using React, you need to add `"@babel/preset-react"`, to the list of `presets`.
1. Copy the file [.browserslistrc](https://github.com/shakacode/react_on_rails/tree/master/lib/install/config/.browserslistrc) to `/`.
1. Merge any differences between [config/webpacker.yml](https://github.com/shakacode/react_on_rails/tree/master/lib/install/config/webpacker.yml) and your `/config/webpacker.yml`.

Here is an [example commit of these changes](https://github.com/shakacode/react_on_rails-tutorial-v11/pull/1/files).
