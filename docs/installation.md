# Installation
Since the repository is private, you will need a **GitHub OAuth** token. ShakaCode will generate a Github OAuth token, referred to below as **`your-github-token`**. 
Substitute that value in the commands below.
Ask [justin@shakacode.com](mailto:justin@shakacode.com) to give you one.

# Ruby
## Gem Installation
1. Ensure your **Rails** app is using the **react_on_rails** gem, version greater than 11.0.7.
1. Add the `react_on_rails_pro` gem to your **Gemfile**. Substitute the appropriate tag.            
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
