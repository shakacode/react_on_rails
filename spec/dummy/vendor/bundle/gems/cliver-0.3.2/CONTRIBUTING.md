# Contributing

`Cliver` is [MIT-liennsed](LICENSE.txt) and intends to follow the
[pull-request-hack][].

## Git-Flow

`Cliver` follows the [git-flow][] branching model, which means that every
commit on `master` is a release. The default working branch is `develop`, so
in general please keep feature pull-requests based against the current
`develop`.

 - fork cliver
 - use the git-flow model to start your feature or hotfix
 - make some commits (please include specs)
 - submit a pull-request

## Bug Reporting

Please include clear steps-to-reproduce. Spec files are especially welcome;
a failing spec can be contributed as a pull-request against `develop`.

## Ruby Appraiser

`Cliver` uses the [ruby-appraiser][] gem via [pre-commit][] hook, which can be
activated by installing [icefox/git-hooks][] and running `git-hooks --install`.
Reek and Rubocop are strong guidelines; use them to reduce defects as much as
you can, but if you believe clarity will be sacrificed they can be bypassed
with the `--no-verify` flag.

[git-flow]: http://nvie.com/posts/a-successful-git-branching-model/
[pre-commit]: .githooks/pre-commit/ruby-appraiser
[ruby-appraiser]: https://github.com/simplymeasured/ruby-appraiser
[icefox/git-hooks]: https://github.com/icefox/git-hooks
[pull-request-hack]: http://felixge.de/2013/03/11/the-pull-request-hack.html
