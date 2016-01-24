# Install and Release

We're now releasing this as a combined ruby gem plus npm package. We will keep the version numbers in sync.

## Testing the Gem before Release from a Rails App
See [Contributing](../contributing.md)

## Releasing a new gem version
Install https://github.com/svenfuchs/gem-release

```bash
# Having the examples prevents publishing
rm -rf tmp/examples
gem bump
# Or manually update the version number
cd spec/dummy
# Update the Gemfile.lock of the tests
bundle
git commit -am "Updated Gemfile.lock"
cd ../..
gem tag
gem release
```


## Releasing a npm version
Be sure to keep the version number the same as the ruby gem!

Use the npm package `release-it`

### Commands Used for Pushing Beta

Note the npm beta version has a dash and the gem version has a dot.

```
gem bump -v 2.0.0.beta.3
gem tag
cd spec/dummy && bundle
ga Gemfile.lock
gc -m "Update Gemfile.lock for spec/dummy"
...
gem release
release-it 2.0.0-beta.3
```
