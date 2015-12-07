# Change Log
All notable changes to this project will be documented in this file. Items under `Unreleased` is upcoming features that will be out in next version.

## v2.0.0
- Move JavaScript part of react_on_rails to npm package 'react-on-rails'.
- Converted JavaScript code to ES6! with tests!
- No global namespace pollution. ReactOnRails is the only global added.
- New API. Instead of placing React components on the global namespace, you instead call ReactOnRails.register, passing an object where keys are the names of your components.
  ```
  import ReactOnRails from 'react-on-rails';
  ReactOnRails.registerComponent({name: component});
  ```
  Best done with Object destructing
  ```
  import ReactOnRails from 'react-on-rails';
  ReactOnRails.registerComponent(
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

## v1.2.2
### Fixed
- Missing Lodash from generated package.json [#175](https://github.com/shakacode/react_on_rails/pull/175)
- Rails 3.2 could not run generators [#182](https://github.com/shakacode/react_on_rails/pull/182)
- Better placement of jquery_ujs dependency [#171](https://github.com/shakacode/react_on_rails/pull/171)
- Add more detailed description when adding --help option to generator [#161](https://github.com/shakacode/react_on_rails/pull/161)
- Lots of better docs.

## v1.2.0
### Added
- Support `--skip-bootstrap` or `-b` option for generator.
- Create examples tasks to test generated example apps.

### Fixed
- Fix non-server rendering configuration issues.
- Fix application.js incorrect overwritten issue.
- Fix Gemfile dependencies.
- Fix several generator issues.

### Removed
- Remove templates/client folder.

## [1.1.1] - 2015-11-28
### Added
- Support for React Router.
- Error and redirect handling.
- Turbolinks support.

### Fixed
- Fix several generator related issues.

### Deprecated
- Nothing.

### Removed
- Nothing.

[Unreleased]: https://github.com/shakacode/react_on_rails/compare/v1.0.0...HEAD
[1.1.1]: https://github.com/shakacode/react_on_rails/compare/v1.0.0...v1.1.1
