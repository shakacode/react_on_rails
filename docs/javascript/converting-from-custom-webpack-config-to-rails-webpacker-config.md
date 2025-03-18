# Converting from Custom Webpack Config to Rails Shakapacker Config

1. Compare your `package.json` and the dependencies in https://github.com/shakacode/shakapacker/blob/master/package.json
   and avoid any duplicates. We don't want different versions of the same packages.
   We want the versions from `shakacode/shakapacker` unless we specifically want to override them.
2. Search the `shakacode/shakapacker` repo for anything you're not sure about in terms of package names.
3. Run `bin/shakapacker` and make sure there are zero errors
4. Update Webpack plugins and loaders to current or close to current
5. Make sure that your `bin/shakapacker` and `bin/shakapacker` match the latest on
   https://github.com/shakacode/shakapacker/tree/master/lib/install/bin
