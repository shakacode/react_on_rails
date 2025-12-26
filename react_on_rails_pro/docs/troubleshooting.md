# Troubleshooting

## Invalid Token Workaround

On June 27, 2024, tokens mysteriously did not work for a few hours. The problem resolved itself within a few hours.

If you do see this problem, get in touch with the package maintainers via Slack. You can also message
Justin Gordon at +1-808-281-7272.

As an alternative to the token issue, if you have an account with access to the docs and this file, you can
create a new token and follow these steps.

To create a new token, visit https://github.com/settings/apps:

1. Developer Settings
2. Personal access tokens
3. Tokens (classic)
4. Generate a new token, classic
5. 30-day expiration (to be safer)
6. Repo privileges (not ideal) but shouldn't last long

Then follow these steps to use your token:

- [Ruby Gem](https://github.com/shakacode/react_on_rails_pro/blob/master/docs/installation.md#using-a-branch-in-your-gemfile)
- [Node Package](https://github.com/shakacode/react_on_rails_pro/blob/master/docs/installation.md#instructions-for-using-a-branch)

Note that this token gives `repo` access, so you want to revoke this token ASAP.
