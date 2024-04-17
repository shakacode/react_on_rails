# Change Log
All notable changes to this project will be documented in this file. Items under `Unreleased` is upcoming features that will be out in next release.

## Gem and Package Versions
Gem and package versions are the same except for beta releases where the gem uses a `.beta` and the package uses a `-beta` (same for `rc`).

1. **Gem**: `3.0.0.rc.1`
2. **Package**: `3.0.0-rc.1`

You can find the **package** version numbers from this repo's tags and below in this file.

----

## [Unreleased]
*Add changes in master not yet tagged.*

### Removed
- Drop support for EOL'd Ruby 2.7 [PR 365](https://github.com/shakacode/react_on_rails_pro/pull/365) by [ahangarha](https://github.com/ahangarha).

### Fixed
- Updated multiple JS dependencies for bug fixes.
- Added execute permission for `spec/dummy/bin/dev` [PR 387](https://github.com/shakacode/react_on_rails_pro/pull/387) by [alexeyr](https://github.com/alexeyr).

### Changed
- Converted JS code to TS [PR 386](https://github.com/shakacode/react_on_rails_pro/pull/386) and [PR 389](https://github.com/shakacode/react_on_rails_pro/pull/389) by [alexeyr-ci](https://github.com/alexeyr-ci).

## [3.1.2] - 2023-02-24

### Fixed
- Removed console errors when `setTimeout` is used server-size. The call is silently ignored for seamless integration of https://github.com/petyosi/react-virtuoso
- Numerous Dependabot alerts

## [3.1.1] - 2022-08-03
## Doc and Spec Only Updates
React 18 is now supported! Check the [React on Rails CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md) for details and the updates to the [loadable-components instructions](https://github.com/shakacode/react_on_rails_pro/blob/master/docs/code-splitting-loadable-components.md).

### Improved
- Updated `Rubocop` version from `1.18.3` to `1.36.0`. Fixed Rubocop warnings. [PR 296](https://github.com/shakacode/react_on_rails_pro/pull/296) by [alkesh26](https://github.com/alkesh26).
- Updated dependencies to address known security vulnerabilities

## [3.1.0] - 2022-08-03
### Fixed
- Removes `include_execjs_polyfills` options from RoRP gem configuration & adds `include_timer_polyfills` option for Node Renderer configuration, which enables use of setTimeout & other timer functions during server rendering. [PR 281](https://github.com/shakacode/react_on_rails_pro/pull/281) by [judahmeek](https://github.com/judahmeek).

### Improvement
- Warn, do not raise on missing assets [PR 280](https://github.com/shakacode/react_on_rails_pro/pull/280) by [Romex91](https://github.com/Romex91)

## [3.0.1] - 2022-07-011
### Fixed
- Fix possible `uninitialized constant ReactOnRails (NameError)` in `lib/react_on_rails_pro/error.rb:4`. [PR 277](https://github.com/shakacode/react_on_rails_pro/pull/273) by [alexeyr](https://github.com/alexeyr).

## [3.0.0] - 2022-07-07
### Fixed
- Make asset paths in PrepareNodeRenderBundles relative too. The symlink to the bundle itself was made relative in #231, but asset symlinks remained absolute. This makes them relative too. Fixes #272. [PR 273](https://github.com/shakacode/react_on_rails_pro/pull/273) by [alexeyr](https://github.com/alexeyr).

## [3.0.0-rc.4] - 2022-06-28
### Fixed
- Add RAILS_ENV to bundle cache key. This ensures a development bundle will never get accidentally deployed to production. [PR 270](https://github.com/shakacode/react_on_rails_pro/pull/270) by [justin808](https://github.com/justin808).
- Replace use of utc_timestamp with Utils.bundle_hash. Important fix as timestamps are not stable between build time and the deployment of a Heroku slug. [PR 269](https://github.com/shakacode/react_on_rails_pro/pull/269) by [Judahmeek](https://github.com/Judahmeek).

## [3.0.0-rc.3] - 2022-04-14

### Fixed
- Fix prepare_node_renderer script. [PR 254](https://github.com/shakacode/react_on_rails_pro/pull/254) by [judahmeek](https://github.com/judahmeek).
- Better logging for error 'Request protocol undefined does not match installed renderer protocol'. [PR 252](https://github.com/shakacode/react_on_rails_pro/pull/252) by [justin808](https://github.com/justin808).

## [3.0.0-rc.1] - 2022-02-26

### Fixed
- Use relative source path for bundle symlink which conflicted with extraction of (Heroku) slugs caching resulting in incorrect extraction of the slugs due to absolute paths in the symlinks. [PR 231](https://github.com/shakacode/react_on_rails_pro/pull/231) by [judahmeek](https://github.com/judahmeek).

## [3.0.0-rc.0] - 2021-10-27

### Upgrading to 3.0
1. Changed rake task name from vm to node:
   Rename react_on_rails_pro:pre_stage_bundle_for_vm_renderer to react_on_rails_pro:pre_stage_bundle_for_node_renderer
2. **Bundle Caching**: ReactOnRailsPro::AssetsPrecompile will automatically pre_stage_bundle_for_node_renderer if using the node_renderer. So don't do this twice in another place if using ReactOnRailsPro::AssetsPrecompile for bundle caching. You might have modified your own assets:precompile task.

### Changed
- Moved default location of placed node renderer sym links to be /.node-renderer-bundles as the /tmp directory is typically
  cleared during slug trimming

### Added
- [PR 220](https://github.com/shakacode/react_on_rails_pro/pull/220) by [justin808](https://github.com/justin808).
  - **Add `ssr_timeout` configuration** so the Rails server will not wait more than this many seconds for a SSR request to return once issued.
  - Change default for `renderer_use_fallback_exec_js` to `false`.
  - Change default log level to info.

- Add support for render functions to be async (returning promises). Also add `include_execjs_polyfills` option to configuration for React on Rails to optionally stop stubbing of setTimeout, setInterval, & clearTimeout polyfills while using NodeRenderer. [PR 210](https://github.com/shakacode/react_on_rails_pro/pull/210) by [judahmeek](https://github.com/judahmeek).

### Fixed
- Ability to call `server_render_js(raw_js)` fixed. Previously, always errored.
- Errors during rendering result in ReactOnRails::PrerenderError
- When retrying rendering, the retry message is more clear

## [2.3.0] - 2021-09-22

### Added
- Configuration option for `ssr_timeout` so the Rails server will not wait more than this many seconds
  for a SSR request to return once issued. Default timeout if not set is 5.
  `config.ssr_timeout = 5`

- Added optional method `extra_files_to_cache` to the definition of the module for the configuration of
  the remote_bundle_cache_adapter. This allows files outside of the regular build directory to be
  placed in the cached zip file and then extracted and restored when the cache is restored. The use
  case for this is some files created during the build process that belongs to a location outside of
  the regular deployment directory for files produced by the `build` method of the module.

  [PR 221](https://github.com/shakacode/react_on_rails_pro/pull/221) by
  [justin808](https://github.com/justin808) and [ershadul1](https://github.com/ershadul1).

## [2.2.0] - 2021-07-13
- Change rake react_on_rails_pro:pre_stage_bundle_for_vm_renderer to use symlinks to save slug size. [PR 202](https://github.com/shakacode/react_on_rails_pro/pull/202) by [justin808](https://github.com/justin808).

## [2.1.1] - 2021-05-29
- Add optional extra cache values for bundle caching. The cache adapter can now provide a method cache_keys. [PR 196](https://github.com/shakacode/react_on_rails_pro/pull/196) by [justin808](https://github.com/justin808).

## [2.1.0] - 2021-05-15

### Added
- Optional production bundle caching. [PR 179](https://github.com/shakacode/react_on_rails_pro/pull/179) by [judahmeek](https://github.com/judahmeek).
- Added configurations:
  - `excluded_dependency_globs`: don't include these in caches
  - `remote_bundle_cache_adapter`: See `docs/bundle-caching.md

------

### 2.0 Upgrade Steps
1. Update React on Rails to 12.2.0
2. Be sure to use an API key that has the Github package access and know your API key username. For questions, message Justin Gordon on Slack or [justin@shakacode.com](mailto:justin@shakacode.com).


In your `config/initializers/react_on_rails_pro.rb`:
1. Rename any references from `config.serializer_globs` to `config.dependency_globs`
1. Rename any references from `vm-renderer` to `node-renderer`
1. Rename `vmRenderer` to `NodeRenderer`

Follow the steps for the new installation that uses Github Packages: [docs/installation.md](https://github.com/shakacode/react_on_rails_pro/blob/master/docs/installation.md).
1. Be sure to namespace the package like `require('@shakacode-tools/react-on-rails-pro-node-renderer');`
1. Add the Honeybadger ("@honeybadger-io/js") or Sentry ("@sentry/node") NPM packages, as those used to be **dependencies**. Now they are optional.
1. Add the `@sentry/tracing` package if you want to try Sentry tracing. See [Error Reporting and Tracing for Sentry and HoneyBadger](./docs/node-renderer/error-reporting-and-tracing.md).

For example, the old code might be:
```js
const { reactOnRailsProVmRenderer } = require('react-on-rails-pro-vm-renderer');
```
New
```js
const { reactOnRailsProNodeRenderer } = require('@shakacode-tools/react-on-rails-pro-node-renderer');
```
------
## [2.0.0] - 2021-04-02
- See 2.0 Upgrade steps!

## [2.0.0.beta.3] - 2021-03-31
#### Improved
- Warn, do not raise on missing assets [PR 176](https://github.com/shakacode/react_on_rails_pro/pull/176) by [Romex91](https://github.com/Romex91)

## [2.0.0.beta.2] - 2021-03-23
#### Added
- Added option `config.throw_js_errors` so that any errors in SSR will go to the console plus HoneyBadger/Sentry. [PR 174](https://github.com/shakacode/react_on_rails_pro/pull/174) by [justin808](https://github.com/justin808).

#### Fixed
- Logs missing error reporting packages (Sentry/HoneyBadger) instead of throwing an error. [PR 174](https://github.com/shakacode/react_on_rails_pro/pull/174) by [justin808](https://github.com/justin808).

## [2.0.0.beta.1] - 2021-03-14
* Added Sentry Tracing support. [PR 150](https://github.com/shakacode/react_on_rails_pro/pull/150) by [ashgaliyev](https://github.com/ashgaliyev). To use this feature, you need to add `config.sentryTracing = true` (or ENV `SENTRY_TRACING=true`) and optionally the `config.sentryTracesSampleRate = 0.5` (or ENV `SENTRY_TRACES_SAMPLE_RATE=0.5`). The value of the sample rate is the percentage of requests to trace. For documentation of Sentry Tracing, see the [Sentry Performance Monitoring Docs](https://docs.sentry.io/platforms/ruby/performance/), the [Sentry Distributed Tracing Docs](https://docs.sentry.io/product/performance/distributed-tracing/), and the [Sentry Sampling Transactions Docs](https://docs.sentry.io/platforms/ruby/performance/sampling/). The default **config.sentryTracesSampleRate** is **0.1**.

- Renamed `config.serializer_globs`to `config.dependency_globs`. [PR 165](https://github.com/shakacode/react_on_rails_pro/pull/165) by [judahmeek](https://github.com/judahmeek)
- RORP_CACHE_HIT and RORP_CACHE_KEY is returned for prerender caching, which is only when there is no fragment caching.
- Improve cache information from react_component_hash. Hash result now includes 2 new keys
  * RORP_CACHE_HIT
  * RORP_CACHE_KEY
  Additionally, ReactOnRailsPro::Utils.printable_cache_key(cache_key) added.
- [PR 170](https://github.com/shakacode/react_on_rails_pro/pull/170) by [justin808](https://github.com/justin808).

## [2.0.0.beta.0] - 2020-12-03
* Renamed VM Renderer to Node Renderer. [PR 140](https://github.com/shakacode/react_on_rails_pro/pull/140) by [justin808](https://github.com/justin808).

### Fixed
- Cache key not stable between machines same deploy. [PR 159](https://github.com/shakacode/react_on_rails_pro/pull/136) by [justin808](https://github.com/justin808).

## [1.5.6] - 2020-12-02
Switched to releases being published packages.

### Fixed
- Minor fix to error messages
- Updated gem and package dependencies

## [1.5.5] - 2020-08-17
### Added
- Added request retrying in case of timeouts. [PR 136](https://github.com/shakacode/react_on_rails_pro/pull/136) by [ashgaliyev](https://github.com/ashgaliyev).

## [1.5.4] - 2020-07-22
### Added
- Added support for Github packages. To switch from using the Github private repo with a tag, request a new auth token from justin@shakacode.com.

## [1.5.3] - 2020-06-30
### Added
- Added sentry support. [PR 132](https://github.com/shakacode/react_on_rails_pro/pull/132) by [ashgaliyev](https://github.com/ashgaliyev).

## [1.5.2] - 2020-06-25
### Improved
- Added `process` and `Buffer` to the context if `suppportModules === true`. [PR 131](https://github.com/shakacode/react_on_rails_pro/pull/131) by [ashgaliyev](https://github.com/ashgaliyev).

## [1.5.1] - 2020-03-25
### Improved
- config.assets_to_copy can take a single value in addition to an array. [PR 122](https://github.com/shakacode/react_on_rails_pro/pull/122 ) [justin808](https://github.com/justin808).
- Better handling for an invalid renderer_url configuration. [PR 109](https://github.com/shakacode/react_on_rails_pro/pull/109 ) [justin808](https://github.com/justin808).

## [1.5.0] - 2020-03-17
### Added
- Added support for loadable components SSR [PR 112](https://github.com/shakacode/react_on_rails_pro/pull/112) and [PR 118](https://github.com/shakacode/react_on_rails_pro/pull/118) by [ashgaliyev](https://github.com/ashgaliyev) and [justin808](https://github.com/justin808).
- New option added to the node-renderer: `supportModules`. This setting is necessary for using [loadable-components](https://github.com/gregberge/loadable-components/). See [Server-side rendering with code-splitting using Loadable/Components](https://github.com/shakacode/react_on_rails_pro/blob/master/docs/code-splitting-loadable-components.md) for more detailss.

### Changed
- Updated to bundler V2. [PR 114](https://github.com/shakacode/react_on_rails_pro/pull/114) by [justin808](https://github.com/justin808).
- Updated spec dummy. [PR 115](https://github.com/shakacode/react_on_rails_pro/pull/115) by [justin808](https://github.com/justin808).

- Better handling for an invalid renderer_url configuration

## [1.4.4] - 2019-06-10

### Fixed
- Improve error handling. [PR 103](https://github.com/shakacode/react_on_rails_pro/pull/103) by [justin808](https://github.com/justin808).

## [1.4.3] - 2019-06-06
### Fixed
- Lock timeouts and update error handling. Previously, many renderer errors resulted in crashes rather than a fallback
to ExecJS. Also, lengthened the lock timeouts for the bundle lock. [PR 100](https://github.com/shakacode/react_on_rails_pro/pull/100) by [justin808](https://github.com/justin808).
- Added check to skip pre-render cache for components rendered by `cache_react_component` and `cache_react_component_hash` because this saves on cache storage, thus improving overall performance. [PR 91](https://github.com/shakacode/react_on_rails_pro/pull/91) by [ashgaliyev](https://github.com/ashgaliyev).

## [1.4.2] - 2019-05-26
### Changed
- Removed babel processing. Node v12 recommended. [PR 93](https://github.com/shakacode/react_on_rails_pro/pull/91) by [ashgaliyev](https://github.com/ashgaliyev).

## [1.4.1] - 2019-03-19
### Fixed
- `cached_react_component_hash` incorrectly failed to include the bundle_hash unless `prerender: true` was used as an option. This fix addresses that issue. There is no need to use `prerender: true` as generating a hash only makes sense if prerendering is done. [PR 82](https://github.com/shakacode/react_on_rails_pro/pull/82) by [justin808](https://github.com/justin808).

## [1.4.0] - 2019-01-15
### Added
- Added config option `honeybadgerApiKey` or ENV value `HONEYBADGER_API_KEY` so that errors can flow to HoneyBadger. [PR 93](https://github.com/shakacode/react_on_rails_pro/pull/75) by [ashgaliyev](https://github.com/ashgaliyev).

## [1.3.1] - 2018-12-26
### Added
- Added option `cache_options:` to the cached_react_component_hash and cached_react_component
  a hash including values such as :compress, :expires_in, :race_condition_ttl
- Added option `:if`, `:unless` to the cached_react_component_hash and cached_react_component
  to skip or use caching
- option `cache_keys:` can be passed as a lambda now to delay evaluation when passing the :if or
  :unless options

Above are in [PR 82](https://github.com/shakacode/react_on_rails_pro/pull/82) by [justin808](https://github.com/justin808)

## [1.3.0] - 2018-12-18
* **Migration:** react_on_rails must be updated to version >= 11.2.1.

### Added
- Added `config.ssr_pre_hook_js` to call some JavaScript to clear out state from libraries that
  misbehave during server Rendering. For example, suppose that we had to call `SomeLibrary.clearCache()`
  between calls to server renderer. Note, SomeLibrary needs to be globally exposed in the server
  rendering webpack bundle.

## [1.2.1] - 2018-08-26
### Fixed
* Major overhaul of the node-renderer. Improved logging and error handling, ready for async
* Fixed race conditions with init of renderer
* Improved logging
* Ensuring all places that an error will result in a 400 sent to the rails server.
* Handle threading issue with writing the bundle by using a lockfile.
* Change internals so that async rendering is ready.
* Add debugging instructions
* Promisified some node APIs and wrote everything with careful async/await syntax, ensuring that errors are always caught and that promises are always returned from the async functions.

Above are in [PR 65](https://github.com/shakacode/react_on_rails_pro/pull/65) by [justin808](https://github.com/justin808).

## [1.2.0]
* **Migration:** react_on_rails must be updated to version 11.1.x+.

### Added
- Added `serializer_globs` configuration value to add a MD5 of serializer files to the cache key for fragment caching. [#60](https://github.com/shakacode/react_on_rails_pro/pull/60) by [justin808](https://github.com/justin808).
- More efficient calculation of the request digest. Previously, we would do a regexp replace to filter out the dom node id because if was randomized. React on Rails 11.1.x provides a default to say not to randomize. [#64](https://github.com/shakacode/react_on_rails_pro/pull/64) by [justin808](https://github.com/justin808).

### Fixed
- Fix for truncation of code and better error logs. This fixes the issue with truncation of the code when over 1 MB due to large props. Max changes to 10 MB. [#63](https://github.com/shakacode/react_on_rails_pro/pull/63) by [justin808](https://github.com/justin808).

## [1.1.0]
### Added
- Added `tracing` configuration flag to time server rendering calls

### Changed
- Default usage of PORT and LOG_LEVEL for the node-renderer bin file changed to use values RENDERER_PORT and RENDERER_LOG_LEVEL
- Default Rails config.server_render is "ExecJS". Previously was "VmRenderer"

Above changes in [PR 52](https://github.com/shakacode/react_on_rails_pro/pull/52) by [justin808](https://github.com/justin808).

## [1.0.0]
### Added
- support for node renderer & fallback renderer
- support for javascript evaluation caching
- advanced error handling

[Unreleased]: https://github.com/shakacode/react_on_rails_pro/compare/3.1.2...HEAD
[3.1.2]: https://github.com/shakacode/react_on_rails_pro/compare/3.1.1...3.1.2
[3.1.1]: https://github.com/shakacode/react_on_rails_pro/compare/3.1.0...3.1.1
[3.1.0]: https://github.com/shakacode/react_on_rails_pro/compare/3.0.1...3.1.0
[3.0.1]: https://github.com/shakacode/react_on_rails_pro/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/shakacode/react_on_rails_pro/compare/2.3.0...3.0.0
[3.0.0-rc.4]: https://github.com/shakacode/react_on_rails_pro/compare/3.0.0-rc.3...3.0.0-rc.4
[3.0.0-rc.3]: https://github.com/shakacode/react_on_rails_pro/compare/3.0.0-rc.1...3.0.0-rc.3
[3.0.0-rc.1]: https://github.com/shakacode/react_on_rails_pro/compare/3.0.0-rc.0...3.0.0-rc.1
[3.0.0-rc.0]: https://github.com/shakacode/react_on_rails_pro/compare/2.3.0...3.0.0-rc.0
[2.3.0]: https://github.com/shakacode/react_on_rails_pro/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/shakacode/react_on_rails_pro/compare/2.1.1...2.2.0
[2.1.1]: https://github.com/shakacode/react_on_rails_pro/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/shakacode/react_on_rails_pro/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.5.6...2.0.0
[2.0.0.beta.3]: https://github.com/shakacode/react_on_rails_pro/compare/2.0.0-beta.2...2.0.0-beta.3
[2.0.0.beta.2]: https://github.com/shakacode/react_on_rails_pro/compare/2.0.0-beta.1...2.0.0-beta.2
[2.0.0.beta.1]: https://github.com/shakacode/react_on_rails_pro/compare/2.0.0-beta.0...2.0.0-beta.1
[2.0.0.beta.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.5.6...2.0.0-beta.0
[1.5.6]: https://github.com/shakacode/react_on_rails_pro/compare/1.5.5...1.5.6
[1.5.5]: https://github.com/shakacode/react_on_rails_pro/compare/1.5.4...1.5.5
[1.5.4]: https://github.com/shakacode/react_on_rails_pro/compare/1.5.3...1.5.4
[1.5.3]: https://github.com/shakacode/react_on_rails_pro/compare/1.5.2...1.5.3
[1.5.2]: https://github.com/shakacode/react_on_rails_pro/compare/1.5.1...1.5.2
[1.5.1]: https://github.com/shakacode/react_on_rails_pro/compare/1.5.0...1.5.1
[1.5.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.4.4...1.5.0
[1.4.4]: https://github.com/shakacode/react_on_rails_pro/compare/1.4.3...1.4.4
[1.4.3]: https://github.com/shakacode/react_on_rails_pro/compare/1.4.2...1.4.3
[1.4.2]: https://github.com/shakacode/react_on_rails_pro/compare/1.4.1...1.4.2
[1.4.1]: https://github.com/shakacode/react_on_rails_pro/compare/1.4.0...1.4.1
[1.4.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.3.1...1.4.0
[1.3.1]: https://github.com/shakacode/react_on_rails_pro/compare/1.3.0...1.3.1
[1.3.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.2.1...1.3.0
[1.2.1]: https://github.com/shakacode/react_on_rails_pro/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/shakacode/react_on_rails_pro/releases/tag/1.0.0
