# Code Style
This document describes the coding style of [ShakaCode](http://www.shakacode.com). Yes, it's opinionated, as all style guidelines should be. We shall put as little as possible into this guide and instead rely on:

* Use of linters with our standard linter configuration.
* References to existing style guidelines that support the linter configuration.
* Anything additional goes next.

## Client Side JavaScript and React
* See the [Shakacode JavaScript Style Guide](https://github.com/shakacode/style-guide-javascript)

## Style Guides to Follow
Follow these style guidelines per the linter configuration. Basically, lint your code and if you have questions about the suggested fixes, look here:

### Ruby Coding Standards
* [ShakaCode Ruby Coding Standards](https://github.com/shakacode/style-guide-ruby)
* [Ruby Documentation](http://guides.rubyonrails.org/api_documentation_guidelines.html)

### JavaScript Coding Standards
* [ShakaCode Javascript](https://github.com/shakacode/style-guide-javascript)
* Use the [eslint-config-shakacode](https://github.com/shakacode/style-guide-javascript/tree/master/packages/eslint-config-shakacode) npm package with eslint.
* [JSDoc](http://usejsdoc.org/)

### Git coding Standards
* [Git Coding Standards](http://chlg.co/1GV2m9p)

### Sass Coding Standards
* [Sass Guidelines](http://sass-guidelin.es/) by [Hugo Giraudel](http://hugogiraudel.com/)
* [Github Front End Guidelines](http://primercss.io/guidelines/)

# Git Usage
* Follow a github-flow model where you branch off of master for features.
* Before merging a branch to master, rebase it on top of master, by using command like `git fetch; git checkout my-branch; git rebase -i origin/master`. Clean up your commit message at this point. Be super careful to communicate with anybody else working on this branch and do not do this when others have uncommitted changes. Ideally, your merge of your feature back to master should be one nice commit.
* Run hosted CI and code coverage.
