# Creating a github OAuth Token

Justin Gordon, justin@shakacode.com, should do the following:

1. Create an email (aka Google Group named `rorp-<customer>`) for the new account. Make sure the group can receive email from anybody.
2. Create a github account with that new email group-name@shakacode.com with account name matching the email. Save the login info.
3. Grant private access for that account to *only* this repo by [adding the account to our "team" for the machine users](https://github.com/orgs/shakacode/teams/react-on-rails-pro-machine-users/members).
4. Open an incognito browser and login as this machine user and accept any pending invite from https://github.com/shakacode.
5. For the machine user, [create a personal access token](https://github.com/settings/tokens/new). Name the token `RORP` and click the top checkbox `repo  Full control of private repositories`. Save the token.
6. Update the Gemfile to have a line like `gem "react_on_rails_pro", git: "https://<OAUTH_TOKEN>:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git", tag: "1.1.0"` where OAUTH_TOKEn is the one generated for the machine user.
7. Update the package.json to have a line like `"react-on-rails-pro-vm-renderer": "https://<OAUTH_TOKEN>:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git#master",`

# Customer Steps
See [Installation](../installation.md).
