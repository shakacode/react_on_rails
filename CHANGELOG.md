# Change Log
All notable changes to this project will be documented in this file. Items under `Unreleased` is upcoming features that will be out in next version.

Contributors: please follow the recommendations outlined at [keepachangelog.com](http://keepachangelog.com/). Please use the existing headings and styling as a guide, and add a link for the version diff at the bottom of the file. Also, please update the `Unreleased` link to compare to the latest release version.

## [Unreleased]
##### Added
- Added forman to gemspec in case new dev does not have it globally installed. [#248](https://github.com/shakacode/react_on_rails/pull/248)

##### Changed
- Changed the EnsureAssetsCompiled feature that ensures RSpec tests are run with the latest webpack bundles. Previously, webpack bundles would be rebuilt every test run, whether or not they actually needed to be. While one could around this by running webpack in the background to rebuild the static assets, doing so required users to name their webpack build script exactly correct as the technique relied on a `pgrep`.

  Instead, the new functionality checks the mdate on each generated webpack bundle/asset against the mdate of every file inside of the `client` directory, which is all encapsulated by the standard library method `FileUtils.uptodate?` and is very performant. This eliminates the need to check for an existing webpack process because the webpack bundles will be up to date anyway if the latter is running.

  Users need not make any changes to their code to benefit from the enhancement, assuming all of their generated files are output to `javascripts/generated`, `stylesheets/generated`, `fonts/generated`, or `images/generated`. [#251](https://github.com/shakacode/react_on_rails/pull/251)
  
##### Breaking Change  
  Renamed `ReactOnRails.configure_rspec_to_compile_assets` to `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`

## [2.3.0] - 2016-02-01
##### Added
- Added polyfills for `setInterval` and `setTimeout` in case other libraries expect these to exist.
- Added much improved debugging for errors in the server JavaScript webpack file.
- See [#244](https://github.com/shakacode/react_on_rails/pull/244/) for these improvements.

## [2.2.0] - 2016-01-29
##### Added
- New JavaScript API for debugging TurboLinks issues. Be sure to see [turbolinks docs](docs/additional_reading/turbolinks.md). `ReactOnRails.setOptions({ traceTurbolinks: true });`. Removed the file `debug_turbolinks` added in 2.1.1. See [#243](https://github.com/shakacode/react_on_rails/pull/243).

## [2.1.1] - 2016-01-28

##### Fixed
- Fixed regression where apps that were not using Turbolinks would not render components on page load.

##### Added
- `ReactOnRails.render` returns a virtualDomElement Reference to your React component's backing instance. See [#234](https://github.com/shakacode/react_on_rails/pull/234).
- `debug_turbolinks` helper for debugging turbolinks issues. See [turbolinks](docs/additional_reading/turbolinks.md).
- Enhanced regression testing for non-turbolinks apps. Runs all tests for dummy app with turbolinks both disabled and enabled.

## [2.1.0] - 2016-01-26
##### Added
- Added EnsureAssetsCompiled feature so that you do not accidentally run tests without properly compiling the JavaScript bundles. Add a line to your `rails_helper.rb` file to check that the latest Webpack bundles have been generated prior to running tests that may depend on your client-side code. See [docs](docs/additional_reading/rspec_configuration.md) for more detailed instructions. [#222](https://github.com/shakacode/react_on_rails/pull/222)
- Added [migration guide](https://github.com/shakacode/react_on_rails#migrate-from-react-rails) for migrating from React-Rails. [#219](https://github.com/shakacode/react_on_rails/pull/219)
- Added [React on Rails Doctrine](docs/doctrine.md) to docs. Discusses the project's motivations, conventions, and principles. [#220](https://github.com/shakacode/react_on_rails/pull/220)
- Added ability to skip `display:none` style in the generated content tag for a component. Some developers may want to disable inline styles for security reasons. See generated config [initializer file](lib/generators/react_on_rails/templates/base/base/config/initializers/react_on_rails.rb#L27) for example on setting `skip_display_none`. [#218](https://github.com/shakacode/react_on_rails/pull/218)

##### Changed
- Changed message when running the dev (a.k.a. "express" server). [#227](https://github.com/shakacode/react_on_rails/commit/543ae70254d0c7b477e2c92af86f40746e58a431)

##### Fixed
- Fixed handling of Turbolinks. Code was checking that Turbolinks was installed when it was not yet because some setups load Turbolinks after the bundles. The changes to the code will check if Turbolinks is installed after the page loaded event fires. Code was also added to allow easy debugging of Turbolinks, which should be useful when v5 of Turbolinks is released shortly. Details of how to configure Turbolinks with troubleshooting were added to docs/additional_reading/turbolinks.md. [#221](https://github.com/shakacode/react_on_rails/pull/221)
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

[Unreleased]: https://github.com/shakacode/react_on_rails/compare/2.3.0...HEAD
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
