---
name: install-and-upgrade
description: >
  Use when installing React on Rails into an existing Rails app or upgrading its
  gem, npm package, generated configuration, and lockfiles without version skew.
---

# Install or upgrade React on Rails

Read the [version-matched package guide](../../docs/agent/install-and-upgrade.md)
before editing dependencies or generated files.

1. Inspect the Rails, Ruby, Node, Shakapacker, gem, npm package, and lockfile state.
2. Keep the `react_on_rails` gem and `react-on-rails` npm package on the same release.
   For Pro apps, update the Pro gem and JavaScript packages as one coordinated set.
3. Use the app's declared JavaScript package manager and update both Ruby and JavaScript lockfiles.
4. Run the install generator for a new integration. During an upgrade, review its proposed changes
   against app-owned configuration instead of overwriting custom files blindly.
5. Run `bin/rails react_on_rails:doctor FORMAT=json`, resolve every error, and rerun it.
6. Compile assets and run the app's focused tests before calling the change complete.

Use hosted docs only for additional detail after reading the installed guide:
https://reactonrails.com/docs/getting-started/existing-rails-app and
https://reactonrails.com/docs/upgrading/upgrading-react-on-rails.
