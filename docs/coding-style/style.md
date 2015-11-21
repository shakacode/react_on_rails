# Code Style
This document describes the coding style of [ShakaCode](http://www.shakacode.com). Yes, it's opinionated, as all style guidelines should be. We shall put as little as possible into this guide and instead rely on:

* Use of linters with our standard linter configuration.
* References to existing style guidelines that support the linter configuration.
* Anything additional goes next.

## Client Side JavaScript and React
* Use [Redux](https://github.com/rackt/redux) for your flux store.
* Use [Lodash](https://lodash.com/) rather than Underscore.
* Place all JavaScript for the client app in `/client`
* Organize your app into high level domains which map to JavaScript bundles. These are like mini-apps that live within your entire app. Create directories named like `/client/app/<bundle>` and configure Webpack to generate different corresponding bundles.
* Carefully organize your React components into [Smart and Dumb Components](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0#.ygdkh1l7b):
   1. "dumb" components that live in the `/client/app/<bundle>/components/` directories. These components should take props, including values and callbacks, and should not talk directly to Redux or any AJAX endpoints.
   2. "smart" components that live in the `/client/app/<bundle>/containers/` directory. These components will talk to the Redux store and AJAX endpoints.
* Place common code shared across bundles in `/client/app/libs` and configure Webpack to generate a common bundle for this one.
* Prefix Immutable.js variable names and properties with `$$`. By doing this, you will clearly know that you are dealing with an Immutable.js object and not a standard JavaScript Object or Array.
* Bind callbacks passed to react components with `_.bind`

## Style Guides to Follow
Follow these style guidelines per the linter configuration. Basically, lint your code and if you have questions about the suggested fixes, look here:

### Ruby Coding Standards
* [RailsOnMaui Ruby Coding Standards](https://github.com/justin808/ruby)

### JavaScript Coding Standards
* [AirBnb Javascript](https://github.com/airbnb/javascript)

### Git coding Standards
* [Git Coding Standards](http://chlg.co/1GV2m9p)

### Sass Coding Standards
* [Sass Guidelines](http://sass-guidelin.es/) by [Hugo Giraudel](http://hugogiraudel.com/)
* [Github Front End Guidelines](http://primercss.io/guidelines/)

# Git Usage
* Follow a github-flow model where you branch off of master for features.
* Before merging a branch to master, rebase it on top of master, by using command like `git fetch; git checkout my-branch; git rebase -i origin/master`. Clean up your commit message at this point. Be super careful to communicate with anybody else working on this branch and do not do this when others have uncommitted changes. Ideally, your merge of your feature back to master should be one nice commit.
* Run hosted CI and code coverage.
