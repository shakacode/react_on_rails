

# Get the oauth token from justin@shakacode.com

* Justin:
  * Creates a github user, like <customer>-rorp with email <customer-rorp>@friendsandguests.com created via a Google apps group.
  * Confirm email for account
  * Add user to have read-only access for shakacode/react_on_rails_pro
  * Create a auth token for this user.


# Update the Gemfile

```ruby
CUSTOMER_GITHUB_AUTH = '3f5fblahblahblah:x-oauth-basic'
gem "react_on_rails_pro", git: "https://#{CUSTOMER_GITHUB_AUTH}@github.com/shakacode/react_on_rails_pro.git", tag: '0.9.0'
```

# Update the client/package.json

```sh
yarn add https://3f5fc97e214f9f75f076108bf6d7bb745a8cb3cf:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git\#0.9.0
```
