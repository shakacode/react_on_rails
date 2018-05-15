# Change Log
All notable changes to this project's source code will be documented in this file. Items under `Unreleased` is upcoming features that will be out in next version. NOTE: major versions of the npm module and the gem must be kept in sync.

Contributors: please follow the recommendations outlined at [keepachangelog.com](http://keepachangelog.com/). Please use the existing headings and styling as a guide, and add a link for the version diff at the bottom of the file. Also, please update the `Unreleased` link to compare to the latest release version.

See [Upgrading React on Rails](./docs/basics/upgrading-react-on-rails.md) for more concise instructions on upgrading.

## [Unreleased]
Changes since last non-beta release.

*Please add entries here for your pull requests that are not yet released.*

#### Changed

### [11.0.6] - 2018-05-11
- Even more detailed errors for Honeybadger and Sentry when there's a JSON parse error on server rendering. [PR 1086](https://github.com/shakacode/react_on_rails/pull/1086) by [justin808](https://github.com/justin808).

### [11.0.5] - 2018-05-11
- More detailed errors for Honeybadger and Sentry. [PR 1081](https://github.com/shakacode/react_on_rails/pull/1081) by [justin808](https://github.com/justin808).

### [11.0.4] - 2018-05-3

#### Changed
- Throw if configuration.generated_assets_dir specified, and using webpacker, and if that doesn't match the public_output_path. Otherwise, warn if generated_assets_dir is specified
- Fix the setup for tests for spec/dummy so they automatically rebuild by correctly setting the source_path in the webpacker.yml
- Updated documentation for the testing setup.
- Above in [PR 1072](https://github.com/shakacode/react_on_rails/pull/1072) by [justin808](https://github.com/justin808).
- `react_component_hash` has implicit `prerender: true` because it makes no sense to have react_component_hash not use prerrender. Improved docs on `react_component_hash`. Also, fixed issue where checking gem existence. [PR 1077](https://github.com/shakacode/react_on_rails/pull/1077) by [justin808](https://github.com/justin808).

### [11.0.3] - 2018-04-24

#### Fixed
- Fixed issue with component script initialization when using react_component_hash. [PR 1071](https://github.com/shakacode/react_on_rails/pull/1071) by [jblasco3](https://github.com/jblasco3).

### [11.0.2] - 2018-04-24

#### Fixed
- Server rendering error for React on Rails Pro. [PR 1069](https://github.com/shakacode/react_on_rails/pull/1069) by [justin808](https://github.com/justin808).

### [11.0.1] - 2018-04-23

#### Added
- `react_component` allows logging_on_server specified at the component level. [PR 1068](https://github.com/shakacode/react_on_rails/pull/1068) by [justin808](https://github.com/justin808).

#### Fixed
- Missing class when throwing some error messages. [PR 1068](https://github.com/shakacode/react_on_rails/pull/1068) by [justin808](https://github.com/justin808).

### [11.0.0] - 2018-04-21

## MIGRATION for v11
- Unused `server_render_method` was removed from the configuration. If you want to use a custom renderer, contact justin@shakacode.com. We have a custom node rendering solution in production for egghead.io.
- Removed ReactOnRails::Utils.server_bundle_file_name and ReactOnRails::Utils.bundle_file_name. These are part of the performance features of "React on Rails Pro".
- Removed ENV["TRACE_REACT_ON_RAILS"] usage and replacing it with config.trace.

#### Enhancements: Better Error Messages, Support for React on Rails Pro
- Tracing (debugging) options are simplified with a single `config.trace` setting that defaults to true for development and false otherwise.
- Calls to setTimeout, setInterval, clearTimeout will now always log some message if config.trace is true. Your JavaScript code should not be calling setTimout when server rendering. 
- Errors raised are of type ReactOnRailsError, so you can see they came from React on Rails for debugging.
- Removed ReactOnRails::Utils.server_bundle_file_name and ReactOnRails::Utils.bundle_file_name.
- No longer logging the `railsContext` when server logging.
- Rails.env is provided in the default railsContext, as suggested in [issue #697](https://github.com/shakacode/react_on_rails/issues/697).
[PR 1065](https://github.com/shakacode/react_on_rails/pull/1065) by [justin808](https://github.com/justin808).

#### Fixes
- More exact version checking. We keep the react_on_rails gem and the react-on-rails node package at
the same exact versions so that we can be sure that the interaction between them is precise.
This is so that if a bug is detected after some update, it's critical that
both the gem and the node package get the updates. This change ensures that the package.json specification does not use a
~ or ^ as reported in [issue #1062](https://github.com/shakacode/react_on_rails/issues/1062). [PR 1063](https://github.com/shakacode/react_on_rails/pull/1063) by [justin808](https://github.com/justin808).
- Sprockets: Now use the most recent manifest when creating symlinks. See [issue #1023](https://github.com/shakacode/react_on_rails/issues/1023). [PR 1064](https://github.com/shakacode/react_on_rails/pull/1064) by [justin808](https://github.com/justin808).

### [10.1.4] - 2018-04-11

#### Fixed
- Changed i18n parsing to convert ruby i18n argument syntax into FormatJS argument syntax. [PR 1046](https://github.com/shakacode/react_on_rails/pull/1046) by [sepehr500](https://github.com/sepehr500).

- Fixed an issue where the spec compiler check would fail if the project path contained spaces. [PR 1045](https://github.com/shakacode/react_on_rails/pull/1045) by [andrewmarkle](https://github.com/andrewmarkle).

- Updated the default `build_production_command` that caused production assets to be built with development settings. [PR 1053](https://github.com/shakacode/react_on_rails/pull/1053) by [Roman Kushnir](https://github.com/RKushnir).

### [10.1.3] - 2018-02-28
#### Fixed
- Improved error reporting on version mismatches between Javascript and Ruby packages. [PR 1025](https://github.com/shakacode/react_on_rails/pull/1025) by [theJoeBiz](https://github.com/squadette).

### [10.1.2] - 2018-02-27
#### Fixed
- Use ReactDOM.hydrate() for hydrating a SSR component if available. ReactDOM.render() has been deprecated for use on SSR components in React 16 and this addresses the warning. [PR 1028](https://github.com/shakacode/react_on_rails/pull/1028) by [theJoeBiz](https://github.com/theJoeBiz).

### [10.1.1] - 2018-01-26
#### Fixed
- Fixed issue with server-rendering error handler: [PR 1020](https://github.com/shakacode/react_on_rails/pull/1020) by [jblasco3](https://github.com/jblasco3).

### [10.1.0] - 2018-01-23
#### Added
- Added 2 cache helpers: ReactOnRails::Utils.bundle_file_name(bundle_name) and ReactOnRails::Utils.server_bundle_file_name
for easy access to the hashed filenames for use in cache keys. [PR 1018](https://github.com/shakacode/react_on_rails/pull/1018) by [justin808](https://github.com/justin808).

#### Fixed
- Use redux component in generated redux Hello World example: [PR 1006](https://github.com/shakacode/react_on_rails/pull/1006) by [lewaabahmad](https://github.com/lewaabahmad).
- Fixed `Utils.bundle_js_file_path` generating the incorrect path for `manifest.json` in webpacker projects: [Issue #1011](https://github.com/shakacode/react_on_rails/issues/1011) by [elstgav](https://github.com/elstgav)

### [10.0.2] - 2017-11-10
#### Fixed
- Remove unnecessary dependencies from released NPM package: [PR 968](https://github.com/shakacode/react_on_rails/pull/968) by [tricknotes](https://github.com/tricknotes).

### [10.0.1] - 2017-10-28
#### Fixed
- Fixed `react_component_hash` functionality in cases of prerendering errors: [PR 960](https://github.com/shakacode/react_on_rails/pull/960) by [Judahmeek](https://github.com/Judahmeek).
- Fix to add missing dependency to run generator spec individually: [PR 962](https://github.com/shakacode/react_on_rails/pull/962) by [tricknotes](https://github.com/tricknotes).
- Fixes check for i18n_dir in LocalesToJs returning false when i18n_dir was set. [PR 899](https://github.com/shakacode/react_on_rails/pull/899) by [hakongit](https://github.com/hakongit).
- Fixed mistake in rubocop comments that led to errors when handling exceptions in ReactOnRails::ServerRendering::Exec [PR 963](https://github.com/shakacode/react_on_rails/pull/963) by [railsme](https://github.com/railsme).
- Fixed and improved I18n directories checks: [PR 967](https://github.com/shakacode/react_on_rails/pull/967) by [railsme](https://github.com/railsme)

### [10.0.0] - 2017-10-08
#### Created
- Created `react_component_hash` method for react_helmet support.
#### Deprecated
- Deprecated `react_component` functionality for react_helmet support.
To clarify, the method itself is not deprecated, only certain functionality which has been moved to `react_component_hash`
[PR 951](https://github.com/shakacode/react_on_rails/pull/951) by [Judahmeek](https://github.com/Judahmeek).

### [9.0.3] - 2017-09-20
#### Improved
- Improved comments in generated Procfile.dev-server. [PR 940](https://github.com/shakacode/react_on_rails/pull/940) by [justin808](https://github.com/justin808).

### [9.0.2] - 2017-09-10
#### Fixed
- Improved post install doc comments for generator. [PR 933](https://github.com/shakacode/react_on_rails/pull/933) by [justin808](https://github.com/justin808).

### [9.0.1] - 2017-09-10

#### Fixed
- Fixes Rails 3.2 compatability issues. [PR 926](https://github.com/shakacode/react_on_rails/pull/926) by [morozovm](https://github.com/morozovm).

### [9.0.0] - 2017-09-06
Updated React on Rails to depend on [rails/webpacker](https://github.com/rails/webpacker). [PR 908](https://github.com/shakacode/react_on_rails/pull/908) by [justin808](https://github.com/justin808).


#### 9.0 from 8.x. Upgrade Instructions
Moved to [our documentation](docs/basics/upgrading-react-on-rails.md#upgrading-to-version-9).

### [8.0.7] - 2017-08-16
#### Fixed
- Fixes generator bug by keeping blank line at top in case existing .gitignore does not end in a newline. [#916](https://github.com/shakacode/react_on_rails/pull/916) by [justin808](https://github.com/justin808).

### [8.0.6] - 2017-07-19
#### Fixed
- Fixes server rendering when using a CDN. Server rendering would try to fetch a file with the "asset_host". This change updates the webpacker_lite dependency to 2.1.0 which has a new helper `pack_path`. [#901](https://github.com/shakacode/react_on_rails/pull/901) by [justin808](https://github.com/justin808). Be sure to update webpacker_lite to 2.1.0.
- The package.json file created by the generator now creates minified javascript production builds by default. This was done by adding the -p flag to webpack on the build:production script. [#895](https://github.com/shakacode/react_on_rails/pull/895) by [serodriguez68 ](https://github.com/serodriguez68)
- Fixes GitUtils.uncommitted_changes? throwing an error when called in an environment without Git, and allows install generator to be run successfully with `--ignore-warnings` [#878](https://github.com/shakacode/react_on_rails/pull/878) by [jasonblalock](https://github.com/jasonblalock).

## [8.0.5] - 2017-07-04
### fixed
 - Corrects `devBuild` value for webpack production build from webpackConfigLoader. [#877](https://github.com/shakacode/react_on_rails/pull/877) by [chenqingspring](https://github.com/chenqingspring).
 - Remove contentBase deprecation warning message. [#878](https://github.com/shakacode/react_on_rails/pull/878) by [ened ](https://github.com/ened).
 - Removes invalid reference to _railsContext in the generated files. [#886](https://github.com/shakacode/react_on_rails/pull/886) by [justin808](https://github.com/justin808).
 - All tests run against Rails 5.1.2

*Note: 8.0.4 skipped.*

## [8.0.3] - 2017-06-19
### Fixed
- Ruby 2.1 issue due to `<<~` as reported in [issue #870](https://github.com/shakacode/react_on_rails/issues/870). [#867](https://github.com/shakacode/react_on_rails/pull/867) by [justin808](https://github.com/justin808)

## [8.0.2] - 2017-06-04
### Fixed
- Any failure in webpack to build test files quits tests.
- Fixed a Ruby 2.4 potential crash which could cause a crash due to pathname change in Ruby 2.4.
- CI Improvements:
  - Switched to yarn link and removed relative path install of react-on-rails
  - Removed testing of Turbolinks 2
  - All tests run against Rails 5.1.1
  - Fixed test failures against Ruby 2.4
- [#862](https://github.com/shakacode/react_on_rails/pull/862) by [justin808](https://github.com/justin808)

## [8.0.1] - 2017-05-30
### Fixed
- Generator no longer modifies `assets.rb`. [#859](https://github.com/shakacode/react_on_rails/pull/859) by [justin808](https://github.com/justin808)

## [8.0.0] - 2017-05-29
- Generators and full support for [webpacker_lite](https://github.com/shakacode/webpacker_lite)
- No breaking changes to move to 8.0.0 other than the default for this setting changed to nil. If you depended on the default of this setting and are using the asset pipeline (and not webpacker_lite), then add this to your `config/initializers/react_on_rails.rb`:
  ```
  symlink_non_digested_assets_regex: /\.(png|jpg|jpeg|gif|tiff|woff|ttf|eot|svg|map)/,
  ```
- For an example of migration, see: [react-webpack-rails-tutorial PR #395](https://github.com/shakacode/react-webpack-rails-tutorial/pull/395)
- For a simple example of the webpacker_lite setup, run the basic generator.

## [8.0.0-beta.3] - 2017-05-27
### Changed
- Major updates for WebpackerLite 2.0.2. [#844](https://github.com/shakacode/react_on_rails/pull/845) by [justin808](https://github.com/justin808) with help from ](https://github.com/robwise)
- Logging no longer occurs when trace is turned to false. [#845](https://github.com/shakacode/react_on_rails/pull/845) by [conturbo](https://github.com/Conturbo)

## [8.0.0-beta.2] - 2017-05-08

### Changed
Removed unnecessary values in default paths.yml files for generators. [#834](https://github.com/shakacode/react_on_rails/pull/834) by [justin808](https://github.com/justin808).

## [8.0.0-beta.1] - 2017-05-03

### Added
Support for WebpackerLite in the generators. [#822](https://github.com/shakacode/react_on_rails/pull/822) by [kaizencodes](https://github.com/kaizencodes) and [justin808](https://github.com/justin808).

### Changed
Breaking change is that the default value of symlink_non_digested_assets_regex has changed from this
old value to nil. This is a breaking change if you didn't have this value set in your
config/initializers/react_on_rails.rb file and you need this because you're using webpack's CSS
features and you have not switched to webpacker lite.

```
symlink_non_digested_assets_regex: /\.(png|jpg|jpeg|gif|tiff|woff|ttf|eot|svg|map)/,
```

## [7.0.4] - 2017-04-27
- Return empty json when nil in json_safe_and_pretty [#824](https://github.com/shakacode/react_on_rails/pull/824) by [dzirtusss](https://github.com/dzirtusss)

## [7.0.3] - 2017-04-27
Same as 7.0.1.

## 7.0.2 - 2017-04-27
*Accidental release of beta gem here*

## [7.0.1] - 2017-04-27
### Fixed
- Fix to handle nil values in json_safe_and_pretty [#823](https://github.com/shakacode/react_on_rails/pull/823) by [dzirtusss](https://github.com/dzirtusss)

## [7.0.0] - 2017-04-25
### Changed
- Any version differences in gem and node package for React on Rails throw an error [#821](https://github.com/shakacode/react_on_rails/pull/821) by [justin808](https://github.com/justin808)

### Fixed
- Fixes serious performance regression when using String props for rendering. [#821](https://github.com/shakacode/react_on_rails/pull/821) by [justin808](https://github.com/justin808)

## [6.10.1] - 2017-04-23
### Fixed
- Improve json conversion with tests and support for older Rails 3.x. [#787](https://github.com/shakacode/react_on_rails/pull/787) by [cheremukhin23](https://github.com/cheremukhin23) and [Ynote](https://github.com/Ynote).

## [6.10.0] - 2017-04-13

### Added
- Add an ability to return multiple HTML strings in a `Hash` as a result of `react_component` method call. Allows to build `<head>` contents with [React Helmet](https://github.com/nfl/react-helmet). [#800](https://github.com/shakacode/react_on_rails/pull/800) by [udovenko](https://github.com/udovenko).

### Fixed
- Fix PropTypes, createClass deprecation warnings for React 15.5.x. [#804](https://github.com/shakacode/react_on_rails/pull/804) by [udovenko ](https://github.com/udovenko).

## [6.9.3] - 2017-04-03

### Fixed
- Removed call of to_json on strings when formatting props. [#791](https://github.com/shakacode/react_on_rails/pull/791) by [justin808](https://github.com/justin808).

## [6.9.2] - 2017-04-02

### Changed
- Update version_checker.rb to `logger.error` rather than `logger.warn` for gem/npm version mismatch. [#788](https://github.com/shakacode/react_on_rails/issues/788) by [justin808](https://github.com/justin808).

### Fixed
- Remove pretty formatting of JSON in development. [#789](https://github.com/shakacode/react_on_rails/pull/789) by [justin808](https://github.com/justin808)
- Clear hydrated stores with each server rendered block. [#785](https://github.com/shakacode/react_on_rails/pull/785) by [udovenko](https://github.com/udovenko)

## [6.9.1] - 2017-03-30

### Fixed
- Fixes Crash in Development for String Props. [#784](https://github.com/shakacode/react_on_rails/issues/784) by [justin808](https://github.com/justin808).

## [6.9.0] - 2017-03-29

### Fixed
- Fixed error in the release script. [#767](https://github.com/shakacode/react_on_rails/issues/767) by [isolo](https://github.com/isolo).

### Changed
- Use <script type="application/json"> for props and store instead of hidden div. [#775] (https://github.com/shakacode/react_on_rails/pull/775) by [cheremukhin23](https://github.com/cheremukhin23).

### Added
- Add option to specify i18n_yml_dir in order to include only subset of locale files when generating translations.js & default.js for react-intl.
[#777](https://github.com/shakacode/react_on_rails/pull/777) by [danijel](https://github.com/danijel).

## [6.8.2] - 2017-03-24
### Fixed
- Change webpack output path to absolute and update webpack to version ^2.3.1. [#771](https://github.com/shakacode/react_on_rails/pull/771) by [cheremukhin23](https://github.com/cheremukhin23).

## [6.8.1] - 2017-03-21
### Fixed
- Fixed error "The node you're attempting to unmount was rendered by another copy of React." [#706](https://github.com/shakacode/react_on_rails/issues/706) when navigating to cached page using Turbolinks  [#763](https://github.com/shakacode/react_on_rails/pull/763) by [szyablitsky](https://github.com/szyablitsky).

## [6.8.0] - 2017-03-06
## Added
- Converted to Webpack v2 for generators, tests, and all example code. [#742](https://github.com/shakacode/react_on_rails/pull/742) by [justin808](https://github.com/justin808).

## [6.7.2] - 2017-03-05
### Improved
- Improve i18n Integration with a better error message if the value of the i18n directory is invalid. [#748](https://github.com/shakacode/react_on_rails/pull/748) by [justin808](https://github.com/justin808).

## [6.7.1] - 2017-02-28
No changes other than a test fix.

## [6.7.0] - 2017-02-28

### IMPORTANT
- If you installed 6.6.0, you will need to comment out the line matching i18n_dir unless you are using this feature. 6.7.1 will give you an error like:

```
Errno::ENOENT: No such file or directory @ rb_sysopen - /tmp/build_1444a5bb9dd16ddb2561c7aff40f0fc7/my-app-816d31e9896edd90cecf1402acd002c724269333/client/app/libs/i18n/translations.js
```

Commenting out this line addresses the issue:

```
config.i18n_dir = Rails.root.join("client", "app", "libs", "i18n")
```

### Added
- Allow using rake task to generate javascript locale files. The test helper automatically creates the localization files when needed. [#717](https://github.com/shakacode/react_on_rails/pull/717) by [JasonYCHuang](https://github.com/JasonYCHuang).

### Fixed
- Upgrade Rails to 4.2.8 to fix security vulnerabilities in 4.2.5. [#735](https://github.com/shakacode/react_on_rails/pull/735) by [hrishimittal](https://github.com/hrishimittal).
- Fix spec failing due to duplicate component. [#734](https://github.com/shakacode/react_on_rails/pull/734) by [hrishimittal](https://github.com/hrishimittal).

## [6.6.0] - 2017-02-18
### Added
- Switched to yarn! [#715](https://github.com/shakacode/react_on_rails/pull/715) by [squadette](https://github.com/squadette).

## [6.5.1] - 2017-02-11
### Fixed
- Allow using gem without sprockets. [#671](https://github.com/shakacode/react_on_rails/pull/671) by [fc-arny](https://github.com/fc-arny).
- Fixed issue [#706](https://github.com/shakacode/react_on_rails/issues/706) with "flickering" components when they are unmounted too early [#709](https://github.com/shakacode/react_on_rails/pull/709) by [szyablitsky](https://github.com/szyablitsky).
- Small formatting fix for errors [#703](https://github.com/shakacode/react_on_rails/pull/703) by [justin808](https://github.com/justin808).

## [6.5.0] - 2017-01-31
### Added
- Allow generator function to return Object with property `renderedHtml` (already could return Object with props `redirectLocation, error`) rather than a React component or a function that returns a React component. One reason to use a generator function is that sometimes in server rendering, specifically with React Router v4, you need to return the result of calling ReactDOMServer.renderToString(element). [#689](https://github.com/shakacode/react_on_rails/issues/689) by [justin808](https://github.com/justin808).

### Fixed
- Fix incorrect "this" references of Node.js SSR [#690](https://github.com/shakacode/react_on_rails/issues/689) by [nostophilia](https://github.com/nostophilia).

## [6.4.2] - 2017-01-17
### Fixed
- Added OS detection for install generator, system call for Windows and unit-tests for it. [#666](https://github.com/shakacode/react_on_rails/pull/666) by [GeorgeGorbanev](https://github.com/GeorgeGorbanev).

## [6.4.1] - 2017-1-17
No changes.

## [6.4.0] - 2017-1-12

### Possible Breaking Change
- Since foreman is no longer a dependency of the React on Rails gem, please run `gem install foreman`. If you are using rvm, you may wish to run `rvm @global do gem install foreman` to install foreman for all your gemsets.

### Fixed
- Removed foreman as a dependency. [#678](https://github.com/shakacode/react_on_rails/pull/678) by [x2es](https://github.com/x2es).

### Added
- Automatically generate __i18n__ javascript files for `react-intl` when the serve starts up. [#642](https://github.com/shakacode/react_on_rails/pull/642) by [JasonYCHuang](https://github.com/JasonYCHuang).

## [6.3.5] - 2017-1-6
### Fixed
- The redux generator now creates a HelloWorld component that uses redux rather than local state. [#669](https://github.com/shakacode/react_on_rails/issues/669) by [justin808](https://github.com/justin808).

## [6.3.4] - 2016-12-25
##### Fixed
- Disable Turbolinks support when not supported. [#650](https://github.com/shakacode/react_on_rails/pull/650) by [ka2n](https://github.com/ka2n).

## [6.3.3] - 2016-12-25
##### Fixed
- By using the hook on `turbolinks:before-visit` to unmount the components, we can ensure that components are unmounted even when Turbolinks cache is disabled. Previously, we used `turbolinks:before-cache` event hook. [#644](https://github.com/shakacode/react_on_rails/pull/644) by [volkanunsal](https://github.com/volkanunsal).
- Added support for Ruby 2.0 [#651](https://github.com/shakacode/react_on_rails/pull/651) by [bbonamin](https://github.com/bbonamin).

## [6.3.2] - 2016-12-5
##### Fixed
- The `react_component` method was raising a `NameError` when `ReactOnRailsHelper` was included in a plain object. [#636](https://github.com/shakacode/react_on_rails/pull/636) by [jtibbertsma](https://github.com/jtibbertsma).
- "Node parse error" for node server rendering. [#641](https://github.com/shakacode/react_on_rails/pull/641) by [alleycat-at-git](https://github.com/alleycat-at-git) and [rocLv](https://github.com/rocLv)
- Better error handling when the react-on-rails node package entry is missing.[#602](https://github.com/shakacode/react_on_rails/pull/602) by [benjiwheeler](https://github.com/benjiwheeler).

## [6.3.1] - 2016-11-30
##### Changed
- Improved generator post-install help messages. [#631](https://github.com/shakacode/react_on_rails/pull/631) by [justin808](https://github.com/justin808).

## [6.3.0] - 2016-11-30
##### Changed
- Modified register API to allow registration of renderers, allowing a user to manually render their app to the DOM. This allows for code splitting and deferred loading. [#581](https://github.com/shakacode/react_on_rails/pull/581) by [jtibbertsma](https://github.com/jtibbertsma).

- Updated Basic Generator & Linters. Examples are simpler. [#624](https://github.com/shakacode/react_on_rails/pull/624) by [Judahmeek](https://github.com/Judahmeek).

- Slight improvement to the 'no hydrated stores' error. [#605](https://github.com/shakacode/react_on_rails/pull/605) by [cookiefission](https://github.com/cookiefission).

- Don't assume ActionMailer is available. [#608](https://github.com/shakacode/react_on_rails/pull/608) by [tuzz](https://github.com/tuzz).

## [6.2.1] - 2016-11-19
- Removed unnecesary passing of context in the HelloWorld Container example and basic generator. [#612](https://github.com/shakacode/react_on_rails/pull/612) by [justin808](https://github.com/justin808)

- Turbolinks 5 bugfix to use `before-cache`, not `before-render`. [#611](https://github.com/shakacode/react_on_rails/pull/611) by [volkanunsal](https://github.com/volkanunsal).

## [6.2.0] - 2016-11-19
##### Changed
- Updated the generator templates to reflect current best practices, especially for the redux version. [#584](https://github.com/shakacode/react_on_rails/pull/584) by [nostophilia](https://github.com/nostophilia).

## [6.1.2] - 2016-10-24
##### Fixed
- Added compatibility with older manifest.yml files produced by Rails 3 Sprockets when symlinking digested assets during precompilation [#566](https://github.com/shakacode/react_on_rails/pull/566) by [etripier](https://github.com/etripier).

## [6.1.1] - 2016-09-09
##### Fixed
- React on Rails was incorrectly failing to create symlinks when a file existed in the location for the new symlink. [#491](https://github.com/shakacode/react_on_rails/pull/541) by [robwise ](https://github.com/robwise) and [justin808](https://github.com/justin808).

## [6.1.0] - 2016-08-21

##### Added
- Node option for installer added as alternative for server rendering [#469](https://github.com/shakacode/react_on_rails/pull/469) by [jbhatab](https://github.com/jbhatab).
- Server rendering now supports contexts outside of browser rendering, such as ActionMailer templates [#486](https://github.com/shakacode/react_on_rails/pull/486) by [eacaps](https://github.com/eacaps).
- Added authenticityToken() and authenticityHeaders() javascript helpers for easier use when working with CSRF protection tag generated by Rails [#517](https://github.com/shakacode/react_on_rails/pull/517) by [dzirtusss](https://github.com/dzirtusss).
- Updated JavaScript error handling on the client side. Errors in client rendering now pass through to the browser [#521](https://github.com/shakacode/react_on_rails/pull/521) by [dzirtusss](https://github.com/dzirtusss).

##### Fixed
- React on Rails now correctly parses single-digit version strings from package.json [#491](https://github.com/shakacode/react_on_rails/pull/491) by [samphilipd ](https://github.com/samphilipd).
- Fixed assets symlinking to correctly use filenames with spaces. Begining in [#510](https://github.com/shakacode/react_on_rails/pull/510), ending in [#513](https://github.com/shakacode/react_on_rails/pull/513) by [dzirtusss](https://github.com/dzirtusss).
- Check encoding of request's original URL and force it to UTF-8 [#527](https://github.com/shakacode/react_on_rails/pull/527) by [lucke84](https://github.com/lucke84)

## [6.0.5] - 2016-07-11
##### Added
- Added better error messages to avoid issues with shared redux stores [#470](https://github.com/shakacode/react_on_rails/pull/470) by by [justin808](https://github.com/justin808).

## [6.0.4] - 2016-06-13
##### Fixed
- Added polyfill for clearTimeout which is used by babel-polyfill [#451](https://github.com/shakacode/react_on_rails/pull/451) by [martyphee](https://github.com/martyphee)

## [6.0.3] - 2016-06-07
##### Fixed
- Added assets symlinking support on Heroku [#446](https://github.com/shakacode/react_on_rails/pull/446) by [Alexey Karasev](https://github.com/alleycat-at-git).

## [6.0.2] - 2016-06-06
##### Fixed
- Fix colisions in ids of DOM nodes generated by `react_component` by indexing in using an UUID rather than an auto-increment value. This means that it should be overriden using the `id` parameter of `react_component` if one wants to generate a predictable id (_e.g._ for testing purpose). See [Issue #437](https://github.com/shakacode/react_on_rails/issues/437). Fixed in [#438](https://github.com/shakacode/react_on_rails/pull/438) by [Michael Baudino](https://github.com/michaelbaudino).

## [6.0.1] - 2016-05-27
##### Fixed
- Allow for older version of manifest.json for older versions of sprockets. See [Issue #435](https://github.com/shakacode/react_on_rails/issues/435). Fixed in [#436](https://github.com/shakacode/react_on_rails/pull/436) by [alleycat-at-git](https://github.com/alleycat-at-git).

## [6.0.0] - 2016-05-25
##### Breaking Changes
- Added automatic compilation of assets at precompile is now done by ReactOnRails. Thus, you don't need to provide your own assets.rake file that does the precompilation.
  [#398](https://github.com/shakacode/react_on_rails/pull/398) by [robwise](https://github.com/robwise), [jbhatab](https://github.com/jbhatab), and [justin808](https://github.com/justin808).
- **Migration to v6**
  - Do not run the generator again if you've already run it.

  - See [shakacode/react-webpack-rails-tutorial/pull/287](https://github.com/shakacode/react-webpack-rails-tutorial/pull/287) for an    example of upgrading from v5.

  - To configure the asset compliation you can either
    1. Specify a `config/react_on_rails` setting for `build_production_command` to be nil to turn this feature off.
    2. Specify the script command you want to run to build your production assets, and remove your assets.rake file.

  - If you are using the ReactOnRails test helper, then you will need to add the 'config.npm_build_test_command' to your config to tell react_on_rails what command to run when you run rspec.

- See [shakacode/react-webpack-rails-tutorial #287](https://github.com/shakacode/react-webpack-rails-tutorial/pull/287/files) for an upgrade example. The PR has a few comments on the upgrade.

Here is the addition to the generated config file:
```ruby
  # This configures the script to run to build the production assets by webpack. Set this to nil
  # if you don't want react_on_rails building this file for you.
  config.build_production_command = "npm run build:production"

  # If you are using the ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  # with rspec then this controls what npm command is run
  # to automatically refresh your webpack assets on every test run.
  config.npm_build_test_command = "npm run build:test"
```

##### Fixed
- Fixed errors when server rendered props contain \u2028 or \u2029 characters [#375](https://github.com/shakacode/react_on_rails/pull/375) by [mariusandra](https://github.com/mariusandra)
- Fixed "too early unmount" which caused problems with Turbolinks 5 not updating the screen [#425](https://github.com/shakacode/react_on_rails/pull/425) by [szyablitsky](https://github.com/szyablitsky)

##### Added
- Experimental ability to use node.js process for server rendering. See [#380](https://github.com/shakacode/react_on_rails/pull/380) by [alleycat-at-git](https://github.com/alleycat-at-git).
- Non-digested version of assets in public folder [#413](https://github.com/shakacode/react_on_rails/pull/413) by [alleycat-at-git](https://github.com/alleycat-at-git).
- Cache client/node_modules directory to prevent Heroku from reinstalling all modules from scratch [#324](https://github.com/shakacode/react_on_rails/pull/324) by [modosc](https://github.com/modosc).
- ReactOnRails.reactOnRailsPageLoaded() is exposed in case one needs to call this manually and information on async script loading added. See [#315](https://github.com/shakacode/react_on_rails/pull/315) by [SqueezedLight](https://github.com/SqueezedLight).

##### Changed
- [#398](https://github.com/shakacode/react_on_rails/pull/398) by [robwise](https://github.com/robwise), [jbhatab](https://github.com/jbhatab), and [justin808](https://github.com/justin808) contains:
  - Only one webpack config is generated for server and client config. Package.json files were changed to reflect this.
  - Added npm_build_test_command to allow developers to change what npm command is automatically run from rspec.
- Replace URI with Addressable gem. See [#405](https://github.com/shakacode/react_on_rails/pull/405) by [lucke84](https://github.com/lucke84)

##### Removed
- [#398](https://github.com/shakacode/react_on_rails/pull/398) by [robwise](https://github.com/robwise), [jbhatab](https://github.com/jbhatab), and [justin808](https://github.com/justin808) contains:
  - Server rendering is no longer an option in the generator and is always accessible.
  - Removed lodash, jquery, and loggerMiddleware from the generated code.
  - Removed webpack watch check for test helper automatic compilation.

## [5.2.0] - 2016-04-08
##### Added
- Support for React 15.0 to react_on_rails. See [#379](https://github.com/shakacode/react_on_rails/pull/379) by [brucek](https://github.com/brucek).
- Support for Node.js server side rendering. See [#380](https://github.com/shakacode/react_on_rails/pull/380) by [alleycat](https://github.com/alleycat-at-git) and [doc](https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/node-server-rendering.md)

##### Removed
- Generator removals to simplify installer. See [#364](https://github.com/shakacode/react_on_rails/pull/364) by [jbhatab](https://github.com/jbhatab).
  - Removed options for heroku, boostrap, and the linters from generator.
  - Removed install for the Webpack Dev Server, as we can now do hot reloading with Rails, so the complexity of this feature is not justified. Nevertheless, the setup of React on Rails still supports this setup, just not with the generator.
  - Documentation added for removed installer options.

## [5.1.1] - 2016-04-04
##### Fixed
- Security Fixes: Address failure to sanitize console messages when server rendering and displaying in the browser console. See [#366](https://github.com/shakacode/react_on_rails/pull/366) and [#370](https://github.com/shakacode/react_on_rails/pull/370) by [justin808](https://github.com/justin808)

##### Added
- railsContext includes the port number and a boolean if the code is being run on the server or client.

## [5.1.0] - 2016-04-03
##### Added
All 5.1.0 changes can be found in [#362](https://github.com/shakacode/react_on_rails/pull/362) by [justin808](https://github.com/justin808).
- Generator enhancements
  - Generator adds line to spec/rails_helper.rb so that running specs will ensure assets are compiled.
  - Other small changes to the generator including adding necessary npm scripts to allow React on Rails to build assets.
  - Npm modules updated for generator.
  - Added babel-runtime in to the client/package.json created.
- Server rendering
  - Added more diagnostics for server rendering.
  - Calls to setTimeout and setInterval are not logged for server rendering unless env TRACE_REACT_ON_RAILS is set to YES.
- Updated all project npm dependencies to latest.
- Update to node 5.10.0 for CI.
- Added babel-runtime as a peer dependency for the npm module.

## [5.0.0] - 2016-04-01

##### Added
- Added `railsContext`, an object which gets passed always as the second parameter to both react component and redux store generator functions, both for server and client rendering. This provides data like the current locale, the pathname, etc. The data values are customizable by a new configuration called `rendering_extension` where you can create a module with a method called `rendering_extension`. This allows you to add additional values to the Rails Context. Implement one static method called `custom_context(view_context)` and return a Hash. See [#345](https://github.com/shakacode/react_on_rails/pull/345) by [justin808](https://github.com/justin808)

##### Changed
- Previously, you could pass arbitrary additional html attributes to react_component. Now, you need to pass them in as a named parameter `html_options` to react_component.

##### Breaking Changes
- You must provide named attributes, including `props` for view helper `react_component`. See [this commit](https://github.com/shakacode/react-webpack-rails-tutorial/commit/a97fa90042cbe27be7fd7fa70b5622bfcf9c3673) for an example migration used for [www.reactrails.com](http://www.reactrails.com).

## [4.0.3] - 2016-03-17

##### Fixed
- `ReactOnRailsHelper#react_component`: Invalid deprecation message when called with only one paramter, the component name.

## [4.0.2] - 2016-03-17

##### Fixed
- `ReactOnRails::Controller#redux_store`: 2nd parameter changed to a named parameter `props` for consistency.

## [4.0.1] - 2016-03-16

##### Fixed
- Switched to `heroku buildpacks:set` syntax rather than using a `.buildpacks` file, which is deprecated. See [#319](https://github.com/shakacode/react_on_rails/pull/319) by [esauter5](https://github.com/esauter5). Includes both generator and doc updates.

## [4.0.0] - 2016-03-14

##### Added
- [spec/dummy](spec/dummy) is a full sample app of React on Rails techniques **including** the hot reloading of assets from Rails!
- Added helpers `env_stylesheet_link_tag` and `env_javascript_include_tag` to support hot reloading Rails. See the [README.md](./README.md) for more details and see the example application in `spec/dummy`. Also see how this is used in the [tutorial: application.html.erb](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/app%2Fviews%2Flayouts%2Fapplication.html.erb#L6)
- Added optional parameter for ReactOnRails.getStore(name, throwIfMissing = true) so that you can check if a store is defined easily.
- Added controller `module ReactOnRails::Controller`. Adds method `redux_store` to setup redux stores in the view.
- Added option `defer: true` for view helper `redux_store`. This allows the view helper to specify the props for store hydration, yet still render the props at the bottom of the view.
- Added view helper `redux_store_hydration_data` to render the props on the application's layout, near the bottom. This allows for the client hydration data to be parsed after the server rendering, which may result in a faster load time.
- The checker for outdated bundles before running tests will two configuration options: `generated_assets_dir` and `webpack_generated_files`.
- Better support for Turbolinks 5!
-	Fixed generator check of uncommitted code for foreign languages. See [#303](https://github.com/shakacode/react_on_rails/pull/303) by [nmatyukov](https://github.com/nmatyukov).
- Added several parameters used for ensuring webpack assets are built for running tests:
  - `config.generated_assets_dir`: Directory where your generated webpack assets go. You can have only **one** directory for this.
  - `config.webpack_generated_files`: List of files that will get created in the `generated_assets_dir`. The test runner helper will ensure these generated files are newer than any of the files in the client directory.

##### Changed
 - Generator default for webpack generated assets is now `app/assets/webpack` as we use this for both JavaScript and CSS generated assets.

##### Fixed
- The test runner "assets up to date checker" is greatly improved.
- Lots of doc updates!
- Improved the **spec/dummy** sample app so that it supports CSS modules, hot reloading, etc, and it can server as a template for a new ReactOnRails installation.

##### Breaking Changes
- Deprecated calling `redux_store(store_name, props)`. The API has changed. Use `redux_store(store_name, props: props, defer: false)` A new option called `defer` allows the rendering of store hydration at the bottom of the your layout.  Place `redux_store_hydration_data` on your layout.
- `config.server_bundle_js_file` has changed. The default value is now blank, meaning no server rendering. Addtionally, if you specify the file name, you should not include the path, as that should be specified in the `config.generated_assets_dir`.
- `config.generated_assets_dirs` has been renamed to `config.generated_assets_dir` (singular) and it only takes one directory.

## [3.0.6] - 2016-03-01
##### Fixed
-	Improved errors when registered store is not found. See [#301](https://github.com/shakacode/react_on_rails/pull/301) by [justin808](https://github.com/justin808).

## [3.0.5] - 2016-02-26
##### Fixed
-	Fixed error in linters rake file for generator. See [#299](https://github.com/shakacode/react_on_rails/pull/299) by [mpugach](https://github.com/mpugach).

## [3.0.4] - 2016-02-25
##### Fixed
- Updated CHANGELOG.md to include contributors for each PR.
-	Fixed config.server_bundle_js file value in generator to match generator setting of server rendering. See [#295](https://github.com/shakacode/react_on_rails/pull/295) by [aaronvb](https://github.com/aaronvb).

## [3.0.3] - 2016-02-21
##### Fixed
- Cleaned up code in `spec/dummy` to latest React and Redux APIs. See [#282](https://github.com/shakacode/react_on_rails/pull/282).
- Update generator messages with helpful information. See [#279](https://github.com/shakacode/react_on_rails/pull/279).
- Other small generated comment fixes and doc fixes.

## [3.0.2] - 2016-02-15
##### Fixed
- Fixed missing information in the helpful message after running the base install generator regarding how to run the node server with hot reloading support.

## [3.0.1] - 2016-02-15
##### Fixed
- Fixed several jscs linter issues.

## [3.0.0] - 2016-02-15
##### Fixed
- Fix Bootstrap Sass Append to Gemfile, missing new line. [#262](https://github.com/shakacode/react_on_rails/pull/262).

##### Added
- Added helper `redux_store` and associated JavaScript APIs that allow multiple React components to use the same store. Thus, you initialize the store, with props, separately from the components.
- Added forman to gemspec in case new dev does not have it globally installed. [#248](https://github.com/shakacode/react_on_rails/pull/248).
- Support for Turbolinks 5! [#270](https://github.com/shakacode/react_on_rails/pull/270).
- Added better error messages for `ReactOnRails.register()`. [#273](https://github.com/shakacode/react_on_rails/pull/273).

##### Breaking Change
- Calls to `react_component` should use a named argument of props. For example, change this:
  ```ruby
  <%= react_component("ReduxSharedStoreApp", {}, prerender: false, trace: true) %>
  ```

  to
  ```ruby
  <%= react_component("ReduxSharedStoreApp", props: {}, prerender: false, trace: true) %>
  ```
  You'll get a deprecation message to change this.
- Renamed `ReactOnRails.configure_rspec_to_compile_assets` to `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`. The code has also been optimized to check for whether or not the compiled webpack bundles are up to date or not and will not run if not necessary. If you are using non-standard directories for your generated webpack assets (`app/assets/javascripts/generated` and `app/assets/stylesheets/generated`) or have additional directories you wish the helper to check, you need to update your ReactOnRails configuration accordingly. See [documentation](https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/rspec_configuration.md) for how to do this.  [#253](https://github.com/shakacode/react_on_rails/pull/253).
- You have to call `ReactOnRails.register` to register react components. This was deprecated in v2. [#273](https://github.com/shakacode/react_on_rails/pull/273).

##### Migration Steps v2 to v3
- [spec/dummy/spec/rails_helper.rb](https://github.com/shakacode/react_on_rails/blob/master/spec%2Fdummy%2Fspec%2Frails_helper.rb#L36..38) for an example. Add this line to your `rails_helper.rb`:
```ruby
RSpec.configure do |config|
  # Ensure that if we are running js tests, we are using latest webpack assets
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
```
- Change view helper calls to react_component to use the named param of `props`. See forum post [Using Regexp to update to ReactOnRails v3](http://forum.shakacode.com/t/using-regexp-to-update-to-reactonrails-v3/481).

## [2.3.0] - 2016-02-01
##### Added
- Added polyfills for `setInterval` and `setTimeout` in case other libraries expect these to exist.
- Added much improved debugging for errors in the server JavaScript webpack file.
- See [#244](https://github.com/shakacode/react_on_rails/pull/244/) for these improvements.

## [2.2.0] - 2016-01-29
##### Added
- New JavaScript API for debugging TurboLinks issues. Be sure to see [turbolinks docs](docs/additional-reading/turbolinks.md). `ReactOnRails.setOptions({ traceTurbolinks: true });`. Removed the file `debug_turbolinks` added in 2.1.1. See [#243](https://github.com/shakacode/react_on_rails/pull/243).

## [2.1.1] - 2016-01-28

##### Fixed
- Fixed regression where apps that were not using Turbolinks would not render components on page load.

##### Added
- `ReactOnRails.render` returns a virtualDomElement Reference to your React component's backing instance. See [#234](https://github.com/shakacode/react_on_rails/pull/234).
- `debug_turbolinks` helper for debugging turbolinks issues. See [turbolinks](docs/additional-reading/turbolinks.md).
- Enhanced regression testing for non-turbolinks apps. Runs all tests for dummy app with turbolinks both disabled and enabled.

## [2.1.0] - 2016-01-26
##### Added
- Added EnsureAssetsCompiled feature so that you do not accidentally run tests without properly compiling the JavaScript bundles. Add a line to your `rails_helper.rb` file to check that the latest Webpack bundles have been generated prior to running tests that may depend on your client-side code. See [docs](docs/additional-reading/rspec_configuration.md) for more detailed instructions. [#222](https://github.com/shakacode/react_on_rails/pull/222)
- Added [migration guide](https://github.com/shakacode/react_on_rails#migrate-from-react-rails) for migrating from React-Rails. [#219](https://github.com/shakacode/react_on_rails/pull/219)
- Added [React on Rails Doctrine](docs/doctrine.md) to docs. Discusses the project's motivations, conventions, and principles. [#220](https://github.com/shakacode/react_on_rails/pull/220)
- Added ability to skip `display:none` style in the generated content tag for a component. Some developers may want to disable inline styles for security reasons. See generated config [initializer file](lib/generators/react_on_rails/templates/base/base/config/initializers/react_on_rails.rb#L27) for example on setting `skip_display_none`. [#218](https://github.com/shakacode/react_on_rails/pull/218)

##### Changed
- Changed message when running the dev (a.k.a. "express" server). [#227](https://github.com/shakacode/react_on_rails/commit/543ae70254d0c7b477e2c92af86f40746e58a431)

##### Fixed
- Fixed handling of Turbolinks. Code was checking that Turbolinks was installed when it was not yet because some setups load Turbolinks after the bundles. The changes to the code will check if Turbolinks is installed after the page loaded event fires. Code was also added to allow easy debugging of Turbolinks, which should be useful when v5 of Turbolinks is released shortly. Details of how to configure Turbolinks with troubleshooting were added to docs/additional-reading/turbolinks.md. [#221](https://github.com/shakacode/react_on_rails/pull/221)
- Fixed issue with already initialized constant warning appearing when starting a Rails server [#226](https://github.com/shakacode/react_on_rails/pull/226)
- Fixed to make backwards compatible with Ruby v2.0 and updated all Ruby and Node dependencies.

---

## [2.0.2]
- Added better messages after generator runs. [#210](https://github.com/shakacode/react_on_rails/pull/210)

## [2.0.1]
- Fixed bug with version matching between gem and npm package.

## [2.0.0]
- Move JavaScript part of react_on_rails to npm package 'react-on-rails'.
- Converted JavaScript code to ES6! with tests!
- No global namespace pollution. ReactOnRails is the only global added.
- New API. Instead of placing React components on the global namespace, you instead call ReactOnRails.register, passing an object where keys are the names of your components:
```
import ReactOnRails from 'react-on-rails';
ReactOnRails.register({name: component});
```
Best done with Object destructing:
```
  import ReactOnRails from 'react-on-rails';
  ReactOnRails.register(
    {
      Component1,
      Component2
    }
  );
```
  Previously, you used
  ```
  window.Component1 = Component1;
  window.Component2 = Component2;
  ```
  This would pollute the global namespace. See details in the README.md for more information.
- Your jade template for the WebpackDevServer setup should use the new API:
```
  ReactOnRails.render(componentName, props, domNodeId);
```
  such as:
```
  ReactOnRails.render("HelloWorldApp", {name: "Stranger"}, 'app');
```
- All npm dependency libraries updated. Most notable is going to Babel 6.
- Dropped support for react 0.13.
- JS Linter uses ShakaCode JavaScript style: https://github.com/shakacode/style-guide-javascript
- Generators account these differences.

##### Migration Steps v1 to v2
[Example of upgrading](https://github.com/shakacode/react-webpack-rails-tutorial/commit/5b1b8698e8daf0f0b94e987740bc85ee237ef608)

1. Update the `react_on_rails` gem.
2. Remove `//= require react_on_rails` from any files such as `app/assets/javascripts/application.js`. This file comes from npm now.
3. Search you app for 'generator_function' and remove lines in layouts and rb files that contain it. Determination of a generator function is handled automatically.
4. Find your files where you registered client and server globals, and use the new ReactOnRails.register syntax. Optionally rename the files `clientRegistration.jsx` and `serverRegistration.jsx` rather than `Globals`.
5. Update your index.jade to use the new API `ReactOnRails.render("MyApp", !{props}, 'app');`
6. Update your webpack files per the example commit. Remove globally exposing React and ReactDom, as well as their inclusion in the `entry` section. These are automatically included now.
7. Run `cd client && npm i --save react-on-rails` to get react-on-rails into your `client/package.json`.
8. You should also update any other dependencies if possible to match up with the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/). This includes updating to Babel 6.
9. If you want to stick with Babel 5 for a bit, see [Issue #238](https://github.com/shakacode/react_on_rails/issues/238).

---

## [1.2.2]
##### Fixed
- Missing Lodash from generated package.json [#175](https://github.com/shakacode/react_on_rails/pull/175)
- Rails 3.2 could not run generators [#182](https://github.com/shakacode/react_on_rails/pull/182)
- Better placement of jquery_ujs dependency [#171](https://github.com/shakacode/react_on_rails/pull/171)
- Add more detailed description when adding --help option to generator [#161](https://github.com/shakacode/react_on_rails/pull/161)
- Lots of better docs.

## [1.2.0]
##### Added
- Support `--skip-bootstrap` or `-b` option for generator.
- Create examples tasks to test generated example apps.

##### Fixed
- Fix non-server rendering configuration issues.
- Fix application.js incorrect overwritten issue.
- Fix Gemfile dependencies.
- Fix several generator issues.

##### Removed
- Removed templates/client folder.

---

## [1.1.1] - 2015-11-28
##### Added
- Support for React Router.
- Error and redirect handling.
- Turbolinks support.

##### Fixed
- Fix several generator related issues.

[Unreleased]: https://github.com/shakacode/react_on_rails/compare/11.0.6...master
[11.0.6]: https://github.com/shakacode/react_on_rails/compare/11.0.5...11.0.6
[11.0.5]: https://github.com/shakacode/react_on_rails/compare/11.0.4...11.0.5
[11.0.4]: https://github.com/shakacode/react_on_rails/compare/11.0.3...11.0.4
[11.0.3]: https://github.com/shakacode/react_on_rails/compare/11.0.2...11.0.3
[11.0.2]: https://github.com/shakacode/react_on_rails/compare/11.0.1...11.0.2
[11.0.1]: https://github.com/shakacode/react_on_rails/compare/11.0.0...11.0.1
[11.0.0]: https://github.com/shakacode/react_on_rails/compare/10.1.4...11.0.0
[10.1.4]: https://github.com/shakacode/react_on_rails/compare/10.1.3...10.1.4
[10.1.3]: https://github.com/shakacode/react_on_rails/compare/10.1.2...10.1.3
[10.1.2]: https://github.com/shakacode/react_on_rails/compare/10.1.1...10.1.2
[10.1.1]: https://github.com/shakacode/react_on_rails/compare/10.1.0...10.1.1
[10.1.0]: https://github.com/shakacode/react_on_rails/compare/10.0.2...10.1.0
[10.0.2]: https://github.com/shakacode/react_on_rails/compare/10.0.1...10.0.2
[10.0.1]: https://github.com/shakacode/react_on_rails/compare/10.0.0...10.0.1
[10.0.0]: https://github.com/shakacode/react_on_rails/compare/9.0.3...10.0.0
[9.0.3]: https://github.com/shakacode/react_on_rails/compare/9.0.2...9.0.3
[9.0.2]: https://github.com/shakacode/react_on_rails/compare/9.0.1...9.0.2
[9.0.1]: https://github.com/shakacode/react_on_rails/compare/9.0.0...9.0.1
[9.0.0]: https://github.com/shakacode/react_on_rails/compare/8.0.7...9.0.0
[8.0.7]: https://github.com/shakacode/react_on_rails/compare/8.0.6...8.0.7
[8.0.6]: https://github.com/shakacode/react_on_rails/compare/8.0.5...8.0.6
[8.0.5]: https://github.com/shakacode/react_on_rails/compare/8.0.3...8.0.5
[8.0.3]: https://github.com/shakacode/react_on_rails/compare/8.0.2...8.0.3
[8.0.2]: https://github.com/shakacode/react_on_rails/compare/8.0.1...8.0.2
[8.0.1]: https://github.com/shakacode/react_on_rails/compare/8.0.0...8.0.1
[8.0.0]: https://github.com/shakacode/react_on_rails/compare/7.0.4...8.0.0
[8.0.0-beta.3]: https://github.com/shakacode/react_on_rails/compare/8.0.0-beta.2...8.0.0-beta.3
[8.0.0-beta.2]: https://github.com/shakacode/react_on_rails/compare/8.0.0-beta.1...8.0.0-beta.2
[8.0.0-beta.1]: https://github.com/shakacode/react_on_rails/compare/7.0.4...8.0.0-beta.1
[7.0.4]: https://github.com/shakacode/react_on_rails/compare/7.0.3...7.0.4
[7.0.3]: https://github.com/shakacode/react_on_rails/compare/7.0.1...7.0.3
[7.0.1]: https://github.com/shakacode/react_on_rails/compare/7.0.0...7.0.1
[7.0.0]: https://github.com/shakacode/react_on_rails/compare/6.10.1...7.0.0
[6.10.1]: https://github.com/shakacode/react_on_rails/compare/6.10.0...6.10.1
[6.10.0]: https://github.com/shakacode/react_on_rails/compare/6.9.3...6.10.0
[6.9.3]: https://github.com/shakacode/react_on_rails/compare/6.9.1...6.9.3
[6.9.2]: https://github.com/shakacode/react_on_rails/compare/6.9.1...6.9.2
[6.9.1]: https://github.com/shakacode/react_on_rails/compare/6.8.2...6.9.1
[6.9.0]: https://github.com/shakacode/react_on_rails/compare/6.8.2...6.9.0
[6.8.2]: https://github.com/shakacode/react_on_rails/compare/6.8.1...6.8.2
[6.8.1]: https://github.com/shakacode/react_on_rails/compare/6.8.0...6.8.1
[6.8.0]: https://github.com/shakacode/react_on_rails/compare/6.7.2...6.8.0
[6.7.2]: https://github.com/shakacode/react_on_rails/compare/6.7.1...6.7.2
[6.7.1]: https://github.com/shakacode/react_on_rails/compare/6.7.0...6.7.1
[6.7.0]: https://github.com/shakacode/react_on_rails/compare/6.6.0...6.7.0
[6.6.0]: https://github.com/shakacode/react_on_rails/compare/6.5.1...6.6.0
[6.5.1]: https://github.com/shakacode/react_on_rails/compare/6.5.0...6.5.1
[6.5.0]: https://github.com/shakacode/react_on_rails/compare/6.4.2...6.5.0
[6.4.2]: https://github.com/shakacode/react_on_rails/compare/6.4.1...6.4.2
[6.4.1]: https://github.com/shakacode/react_on_rails/compare/6.4.0...6.4.1
[6.4.0]: https://github.com/shakacode/react_on_rails/compare/6.3.5...6.4.0
[6.3.5]: https://github.com/shakacode/react_on_rails/compare/6.3.4...6.3.5
[6.3.4]: https://github.com/shakacode/react_on_rails/compare/6.3.3...6.3.4
[6.3.3]: https://github.com/shakacode/react_on_rails/compare/6.3.2...6.3.3
[6.3.2]: https://github.com/shakacode/react_on_rails/compare/6.3.1...6.3.2
[6.3.1]: https://github.com/shakacode/react_on_rails/compare/6.3.0...6.3.1
[6.3.0]: https://github.com/shakacode/react_on_rails/compare/6.2.1...6.3.0
[6.2.1]: https://github.com/shakacode/react_on_rails/compare/6.2.0...6.2.1
[6.2.0]: https://github.com/shakacode/react_on_rails/compare/6.1.2...6.2.0
[6.1.2]: https://github.com/shakacode/react_on_rails/compare/6.1.1...6.1.2
[6.1.1]: https://github.com/shakacode/react_on_rails/compare/6.1.0...6.1.1
[6.1.0]: https://github.com/shakacode/react_on_rails/compare/6.0.5...6.1.0
[6.0.5]: https://github.com/shakacode/react_on_rails/compare/6.0.4...6.0.5
[6.0.4]: https://github.com/shakacode/react_on_rails/compare/6.0.3...6.0.4
[6.0.3]: https://github.com/shakacode/react_on_rails/compare/6.0.2...6.0.3
[6.0.2]: https://github.com/shakacode/react_on_rails/compare/6.0.1...6.0.2
[6.0.1]: https://github.com/shakacode/react_on_rails/compare/6.0.0...6.0.1
[6.0.0]: https://github.com/shakacode/react_on_rails/compare/5.2.0...6.0.0
[5.2.0]: https://github.com/shakacode/react_on_rails/compare/5.1.1...5.2.0
[5.1.1]: https://github.com/shakacode/react_on_rails/compare/5.1.0...5.1.1
[5.1.0]: https://github.com/shakacode/react_on_rails/compare/5.0.0...5.1.0
[5.0.0]: https://github.com/shakacode/react_on_rails/compare/4.0.3...5.0.0
[4.0.3]: https://github.com/shakacode/react_on_rails/compare/4.0.2...4.0.3
[4.0.2]: https://github.com/shakacode/react_on_rails/compare/4.0.1...4.0.2
[4.0.1]: https://github.com/shakacode/react_on_rails/compare/4.0.0...4.0.1
[4.0.0]: https://github.com/shakacode/react_on_rails/compare/3.0.6...4.0.0
[3.0.6]: https://github.com/shakacode/react_on_rails/compare/3.0.5...3.0.6
[3.0.5]: https://github.com/shakacode/react_on_rails/compare/3.0.4...3.0.5
[3.0.4]: https://github.com/shakacode/react_on_rails/compare/3.0.3...3.0.4
[3.0.3]: https://github.com/shakacode/react_on_rails/compare/3.0.2...3.0.3
[3.0.2]: https://github.com/shakacode/react_on_rails/compare/3.0.1...3.0.2
[3.0.1]: https://github.com/shakacode/react_on_rails/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/shakacode/react_on_rails/compare/2.3.0...3.0.0
[2.3.0]: https://github.com/shakacode/react_on_rails/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/shakacode/react_on_rails/compare/2.1.1...2.2.0
[2.1.1]: https://github.com/shakacode/react_on_rails/compare/v2.1.0...2.1.1
[2.1.0]: https://github.com/shakacode/react_on_rails/compare/v2.0.2...v2.1.0
[2.0.2]: https://github.com/shakacode/react_on_rails/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/shakacode/react_on_rails/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/shakacode/react_on_rails/compare/v1.2.2...v2.0.0
[1.2.2]: https://github.com/shakacode/react_on_rails/compare/v1.2.0...v1.2.2
[1.2.0]: https://github.com/shakacode/react_on_rails/compare/v1.1.0...v1.2.0
[1.1.1]: https://github.com/shakacode/react_on_rails/compare/v1.1.1...v1.0.0
