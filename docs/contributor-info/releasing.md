# Install and Release

We're now releasing this as a combined ruby gem plus npm package. We will keep the version numbers in sync.

## Testing the Gem before Release from a Rails App

See [Contributing](https://github.com/shakacode/react_on_rails/tree/master/CONTRIBUTING.md)

## Releasing a new gem version

Run `rake -D release` to see instructions on how to release via the rake task.

As of 01-26-2016, this would give you an output like this:

```
rake release[gem_version,dry_run,tools_install]
    Releases both the gem and node package using the given version.

    IMPORTANT: the gem version must be in valid rubygem format (no dashes).
    It will be automatically converted to a valid npm semver by the rake task
    for the node package version. This only makes a difference for pre-release
    versions such as `3.0.0.beta.1` (npm version would be `3.0.0-beta.1`).

    This task will also globally install gem-release (ruby gem) and
    release-it (node package) unless you specify skip installing tools.

    2nd argument: Perform a dry run by passing 'true' as a second argument.
    3rd argument: Skip installing tools by passing 'false' as a third argument (default is true).

    Example: `rake release[2.1.0,false,false]`
```

Running `rake release[2.1.0]` will create a commit that looks like this:

```
commit d07005cde9784c69e41d73fb9a0ebe8922e556b3
Author: Rob Wise <robert.wise@outlook.com>
Date:   Tue Jan 26 19:49:14 2016 -0500

    Release 2.1.0

diff --git a/lib/react_on_rails/version.rb b/lib/react_on_rails/version.rb
index 3de9606..b71aa7a 100644
--- a/lib/react_on_rails/version.rb
+++ b/lib/react_on_rails/version.rb
@@ -1,3 +1,3 @@
 module ReactOnRails
-  VERSION = "2.0.2".freeze
+  VERSION = "2.1.0".freeze
 end
diff --git a/package.json b/package.json
index aa7b000..af8761e 100644
--- a/package.json
+++ b/package.json
@@ -1,6 +1,6 @@
 {
   "name": "react-on-rails",
-  "version": "2.0.2",
+  "version": "2.1.0",
   "description": "react-on-rails JavaScript for react_on_rails Ruby gem",
   "main": "node_package/lib/ReactOnRails.js",
   "directories": {
diff --git a/spec/dummy/Gemfile.lock b/spec/dummy/Gemfile.lock
index 8ef51df..4489bfe 100644
--- a/spec/dummy/Gemfile.lock
+++ b/spec/dummy/Gemfile.lock
@@ -1,7 +1,7 @@
 PATH
   remote: ../..
   specs:
-    react_on_rails (2.0.2)
+    react_on_rails (2.1.0)
       connection_pool
       execjs (~> 2.5)
       rails (>= 3.2)
(END)
```
