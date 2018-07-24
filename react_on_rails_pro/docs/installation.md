# Installation
Since the repository is private, you will need a **GitHub OAuth** token. This is available from **Settings/Developer settings/Personal access tokens**. ShakaCode will generate a Github OAuth token, referred to below as **`your-github-token`**. This is done for a "machine user" github account. The reason for this is that this machine user has access to ONLY this one private repo. Justin can get this for you. If you use your personal token, it's good for any repos that you have access to.

Substitute that value in the commands below.

Ask [justin@shakacode.com](mailto:justin@shakacode.com) to give you one.

# Ruby
## Gem Installation
1. Ensure your **Rails** app is using the **react_on_rails** gem, version greater than 11.0.7.
1. Add the `react_on_rails_pro` gem to your **Gemfile**. Substitute the appropriate tag. Note, you should probably use an ENV value for the token so that you don't check this into your source code.
   ```ruby
   gem "react_on_rails_pro", git: "https://[your-github-token]:x-oauth-basic@github.com/shakacode/react_on_rails-pro.git", tag: "1.1.0"
   ```
1. Run `bundle install`.

## Rails Configuration
You don't need to create a initializer if you are satisfied with the default as described in 
[Configuration](./docs/configuration.md)

# Node Package
You only need to install the Node Package if you are using the standalone node renderer, `VmRenderer`.

## Installation

Install the vm-renderer executable, possibly globally. Substitute the branch name or tag for `master`
```
yarn global add https://<your-github-token>:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git\#master
```

This installs a binary `vm-renderer`.

## Configuration
See [VmRenderer JavaScript Configuration](./vm-renderer/js-configuration.md).
