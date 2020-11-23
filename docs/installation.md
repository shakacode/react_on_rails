# Installation
Since the repository is private, you will need a **GitHub OAuth** token. This is available from **Settings/Developer settings/Personal access tokens**. ShakaCode will generate a Github OAuth token, referred to below as **`your-github-token`**. This is done for a "machine user" github account. The reason for this is that this machine user has access to ONLY this one private repo. Justin can get this for you. If you use your personal token, it's good for any repos that you have access to.

Substitute that value in the commands below.

Ask [justin@shakacode.com](mailto:justin@shakacode.com) to give you one.

# Ruby
## Gem Installation
1. Ensure your **Rails** app is using the **react_on_rails** gem, version greater than 11.0.7.
1. Add the `react_on_rails_pro` gem to your **Gemfile**. Substitute the appropriate version number. 
   

## Gemfile Change

Replace the following in the snippet for the Gemfile
1. `<account>` for the api key
2. `<api-key>`
3. `<version>` desired

```ruby
source "https://rorp-<account>:<api-key>@"\
  "rubygems.pkg.github.com/shakacode-tools" do
  gem "react_on_rails_pro", "<version>"
end
```

## Alternate installation keeping the key out of your Gemfile

```ruby
source "https://rubygems.pkg.github.com/shakacode-tools" do
  gem "react_on_rails_pro", "1.5.4"
end
```
Or use the `gem install` command:

```bash
gem install react_on_rails_pro --version "1.5.6" --source "https://rubygems.pkg.github.com/shakacode-tools"
```

Then edit your permissions for bundler at the command line:

```
bundle config set rubygems.pkg.github.com <username>:<token>
```

## Using a branch in your Gemfile
Note, you should probably use an ENV value for the token so that you don't check this into your source code.
   ```ruby
   gem "react_on_rails_pro", version: "1.5.4", git: "https://[your-github-token]:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git", tag: "1.5.4"
   ```

## Rails Configuration
You don't need to create a initializer if you are satisfied with the default as described in 
[Configuration](./configuration.md)

# Node Package
Note, you only need to install the Node Package if you are using the standalone node renderer, `VmRenderer`.

## Installation

1. Create a subdirectory of your rails project for the Node renderer. Let's use `react-on-rails-pro`.
   
2. Create a file `react-on-rails-pro/.npmrc` with the following
```
always-auth=true
//npm.pkg.github.com/:_authToken=<TOKEN>
@shakacode-tools:registry=https://npm.pkg.github.com
```

3. Create a `react-on-rails-pro/package.json`
```json
{
  "private": true,
  "dependencies": {
    "@shakacode-tools/react-on-rails-pro-vm-renderer": "1.5.4"
  },
  "scripts": {
    "node-renderer": "echo 'Starting React on Rails Pro VM Renderer.' && node ./react-on-rails-pro-node-renderer.js"
  }
}
```

4. Be sure to run `npm i` **and not** `yarn` as only npm seems to work with the private github packages.

If you really want to use yarn, see [Yarn can't find private Github npm registry](https://stackoverflow.com/questions/58316109/yarn-cant-find-private-github-npm-registry)

5. You can start the renderer with either the executable `vm-renderer` or, preferably, with 
   a startup JS file, say called `react-on-rails-pro/react-on-rails-pro-node-renderer.js` with
   these contents. _Note the use of the namespaced **`@shakacode-tools/react-on-rails-pro-vm-renderer`** for the package.

```js
const path = require('path')
const {
  reactOnRailsProVmRenderer,
} = require('@shakacode-tools/react-on-rails-pro-vm-renderer')

const env = process.env

const config = {
  bundlePath: path.resolve(__dirname, '../tmp/bundles'),

  // Listen at RENDERER_PORT env value or default port 3800
  logLevel: env.RENDERER_LOG_LEVEL || 'debug', // show all logs

  // See value in /config/initializers/react_on_rails_pro.rb. Should use env
  // value in real app.
  password: 'myPassword1',

  // Save bundle to "tmp/bundles" dir of our dummy app
  // This is the default
  port: env.RENDERER_PORT || 3800,

  // supportModules should be set to true to allow the server-bundle code to
  // see require, exports, etc.
  // `false` is like the ExecJS behavior
  // this option is required to equal `true` in order to use loadable components
  supportModules: true,

  // workersCount defaults to the number of CPUs minus 1
  workersCount: Number(process.env.VM_RENDERER_CONCURRENCY || 3),

  // Next 2 params, allWorkersRestartInterval and
  // delayBetweenIndividualWorkerRestarts must both should be set if you wish
  // to have automatic worker restarting, say to clear memory leaks.
  // time is in minutes between restarting all workers
  // Enable next 2 if the renderer is running out of memory
  // allWorkersRestartInterval: 15,
  // time in minutes between each worker restarting when restarting all workers
  // delayBetweenIndividualWorkerRestarts: 2,
}

// Renderer detects a total number of CPUs on virtual hostings like Heroku
// or CircleCI instead of CPUs number allocated for current container. This
// results in spawning many workers while only 1-2 of them really needed.
if (env.CI) {
  config.workersCount = 2
}

reactOnRailsProVmRenderer(config)
```

## Instructions for using a branch

Install the vm-renderer executable, possibly globally. Substitute the branch name or tag for `master`
```
yarn global add https://<your-github-token>:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git\#master
```

This installs a binary `vm-renderer`.

### Using Github packages

Login into npm

```bash
npm install @shakacode-tools/react-on-rails-pro-vm-renderer@1.5.4
```                      

or edit package.json directly
```json
"@shakacode-tools/react-on-rails-pro-vm-renderer": "1.5.4"
```                     

### Configuration
See [VmRenderer JavaScript Configuration](./vm-renderer/js-configuration.md).

## Authentication when using Github packages
[Auth for the npm package](https://docs.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-npm-for-use-with-github-packages#authenticating-to-github-packages)

Create a new ~/.npmrc file if one doesn't exist.
```
//npm.pkg.github.com/:_authToken=TOKEN
```                  

To configure bundler if you don't want the token in your Gemfile:
```
bundle config https://rubygems.pkg.github.com/OWNER USERNAME:TOKEN
``` 
