# Using a Branch Rather Than a Published Package
_And Old Installation Instructions_

## Get the oauth token from justin@shakacode.com

* ShakaCode does:
  * Creates a github user, like customer-rorp with email customer-rorp@shakacode.com created via a Google apps group.
  * Confirm email for account
  * Add user to have read-only access for shakacode/react_on_rails_pro
  * Create an auth token for this user.


## Update the Gemfile

```ruby
CUSTOMER_GITHUB_AUTH = '3f5fblahblahblah:x-oauth-basic'
gem "react_on_rails_pro", git: "https://#{CUSTOMER_GITHUB_AUTH}@github.com/shakacode/react_on_rails_pro.git", tag: '1.0.0'
```

## Update the client/package.json

```sh
CUSTOMER_GITHUB_AUTH=3f5fblahblahblah
yarn add https://${CUSTOMER_GITHUB_AUTH}:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git\#1.0.0
```
