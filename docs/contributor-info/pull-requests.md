# Pull Requests

## Checklist before Committing

1. Run all linters and specs (you need Docker set up, see below).
2. Did you need any more tests for your change?
3. Did you document your change? Update the README.md?
4. Did you add a CHANGELOG.md entry?

For non-doc fixes:

- Provide changelog entry in the [unreleased section of the CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md#unreleased).
- Ensure CI passes and that you added a test that passes with the fix and fails without the fix.
- Squash all commits down to one with a nice commit message _ONLY_ once final review is given. Make sure this single commit is rebased on top of master.
- Please address all code review comments.
- Ensure that docs are updated accordingly if a feature is added.

## Commit Messages

From [How to Write a Git Commit Message](http://chris.beams.io/posts/git-commit/)

### The seven rules of a great git commit message

> Keep in mind: This has all been said before.

1. Separate subject from body with a blank line
1. Limit the subject line to 50 characters
1. Capitalize the subject line
1. Do not end the subject line with a period
1. Use the imperative mood in the subject line
1. Wrap the body at 72 characters
1. Use the body to explain what and why vs. how

## Doc Changes

When making doc changes, we want the change to work on both the gitbook and the regular github site. The issue is that non-doc files will not go to the gitbook site, so doc references to non doc files must use the github URL.

### Links to other docs

- When making references to source code files, use a full GitHub URL, for example:
  `[spec/dummy/config/initializers/react_on_rails.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb)`
