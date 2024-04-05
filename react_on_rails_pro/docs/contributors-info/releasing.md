# Install and Release
Github packages and gems are used for distribution from the https://github.com/shakacode-tools/react_on_rails_pro repo.
1. Check that the CHANGELOG.md is updated
2. See below for Prerequisites and then run the release command like this

```
rake release[1.5.7]
```

or for a beta release. Note the period, not dash, before the 'beta'.

```
rake release[1.5.6.beta.2]
```

## Testing the Gem before Release from a Rails App
See [Contributing](https://github.com/shakacode/react_on_rails_pro/blob/master/CONTRIBUTING.md)

### Prerequisites
Before this command can be run, a bit of setup is required:

1. Get a Github personal access token that provides both Repo and write:packages access
2. In `~/.npmrc`
```
//npm.pkg.github.com/:_authToken=<TOKEN>
always-auth=true
```
3. Ensure that you set the ENV value when you will run the script. A `.envrc` is convenient for this.
```
export GITHUB_TOKEN=<TOKEN>
```

### Details
1. See `/package.json` for how npm release and release-it know how to publish the package to Github
2. See `/react_on_rails.gemspec` for the gem specification.
3. See `/rakelib/release.rake` for details on how a release is done. The gem is set to publish to
   Github by the `gem_push_command`
