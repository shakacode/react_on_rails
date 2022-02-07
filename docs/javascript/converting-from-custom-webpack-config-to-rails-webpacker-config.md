# Converting from Custom Webpack Config to Rails Webpacker Config

1. Compare your package.json and the dependencies in https://github.com/rails/webpacker/blob/master/package.json
  and avoid any duplicates. We don't want different versions of the same packages.
  We want the versions from rails/webpacker unless we specifically want to override them.
2. Search the rails/webpacker repo for anything you're not sure about in terms of package names.
3. run `bin/webpacker` and make sure there are zero errors
4. update webpack plugins and loaders to current or close to current
5. Make sure that your bin/webpacker and bin/webpacker match the latest on
https://github.com/rails/webpacker/tree/master/lib/install/bin
