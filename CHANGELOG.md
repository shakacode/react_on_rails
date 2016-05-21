# Change Log
All notable changes to this project will be documented in this file. Items under `Unreleased` is upcoming features that will be out in next version.

Contributors: please follow the recommendations outlined at [keepachangelog.com](http://keepachangelog.com/). Please use the existing headings and styling as a guide, and add a link for the version diff at the bottom of the file. Also, please update the `Unreleased` link to compare to the latest release version.
## [Unreleased]

## [6.0.0-rc.5]
##### Breaking Changes
- Added automatic compilation of assets at precompile is now done by ReactOnRails. Thus, you don't need to provide your own assets.rake file that does the precompilation. 
  [#398](https://github.com/shakacode/react_on_rails/pull/398) by [robwise](https://github.com/robwise), [jbhatab](https://github.com/jbhatab), and [justin808](https://github.com/justin808).
- **Migration to v6**
  
  - To configure the asset compliation you can either
    1. Specify a `config/react_on_rails` setting for `npm_build_production_command` to be nil to turn this feature off.
    2. Specify the script command you want to run to build your production assets, and remove your assets.rake file.

  - If you are using the ReactOnRails test helper, then you will need to add the 'config.npm_build_test_command' to your config to tell react_on_rails what command to run when you run rspec.
   
- See [shakacode/react-webpack-rails-tutorial #287](https://github.com/shakacode/react-webpack-rails-tutorial/pull/287/files) for an upgrade example. The PR has a few comments on the upgrade.

Here is the addition to the generated config file:
```ruby
  # This configures the script to run to build the production assets by webpack. Set this to nil
  # if you don't want react_on_rails building this file for you.
  config.npm_build_production_command = "npm run build:production"

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
- Generator removals to simplify installer. See [#363](https://github.com/shakacode/react_on_rails/pull/363) by [jbhatab](https://github.com/jbhatab).
  - Removed options for heroku, boostrap, and the linters from generator.
  - Removed install for the Webpack Dev Server, as we can now do hot reloading with Rails, so the complexity of this feature is not justified. Nevertheless, the setup of React on Rails still supports this setup, just not with the generator.
  - Documentation added for removed installer options.

## [5.1.1] - 2016-04-04
##### Fixed
- [Security] Address failure to sanitize console messages when server rendering and displaying in the browser console. See [#366](https://github.com/shakacode/react_on_rails/pull/366) and [#370](https://github.com/shakacode/react_on_rails/pull/370) by [justin808](https://github.com/justin808)

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
- You must provide named attributes, including `props` for view helper `react_compnent`. See [this commit]](https://github.com/shakacode/react-webpack-rails-tutorial/commit/a97fa90042cbe27be7fd7fa70b5622bfcf9c3673) for an example migration used for [www.reactrails.com](http://www.reactrails.com).

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

[Unreleased]: https://github.com/shakacode/react_on_rails/compare/5.2.0...master
[6.0.0-rc.5]: https://github.com/shakacode/react_on_rails/compare/5.2.0...6.0.0-rc.5
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
