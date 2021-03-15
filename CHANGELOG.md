# Change Log
All notable changes to this project will be documented in this file. Items under `Unreleased` is upcoming features that will be out in next version.

## [Unreleased]
*Add changes in master not yet tagged.*

### 2.0 Upgrade Steps
In your `config/initializers/react_on_rails_pro.rb`:
1. Rename any references from `config.serializer_globs` to `config.dependency_globs`
1. Rename any references from `vm-renderer` to `node-renderer`
1. Rename `vmRenderer` to `NodeRenderer`
1. Be sure to namespace the package like `require('@shakacode-tools/react-on-rails-pro-node-renderer');`

For example, the old code might be:
```js
const { reactOnRailsProVmRenderer } = require('react-on-rails-pro-vm-renderer');
```
New
```js
const { reactOnRailsProNodeRenderer } = require('@shakacode-tools/react-on-rails-pro-node-renderer');
```

## [2.0.0.beta.1] - 2021-01
* Added Sentry Tracing support. [PR 150](https://github.com/shakacode/react_on_rails_pro/pull/150) by [ashgaliyev](https://github.com/ashgaliyev). To use this feature, you need to add `config.sentryTracing = true` (or ENV `SENTRY_TRACING=true`) and optionally the `config.sentryTracesSampleRate = 0.5` (or ENV `SENTRY_TRACES_SAMPLE_RATE=0.5`). The value of the sample rate is the percentage of requests to trace. For documentation of Sentry Tracing, see the [Sentry Performance Monitoring Docs](https://docs.sentry.io/platforms/ruby/performance/), the [Sentry Distributed Tracing Docs](https://docs.sentry.io/product/performance/distributed-tracing/), and the [Sentry Sampling Transactions Docs](https://docs.sentry.io/platforms/ruby/performance/sampling/). The default **config.sentryTracesSampleRate** is **0.1**.


- Renamed `config.serializer_globs`to `config.dependency_globs`. [PR 165](https://github.com/shakacode/react_on_rails_pro/pull/165) by [judahmeek](https://github.com/judahmeek)


## [2.0.0.beta.0] - 2020-12-03
* Renamed VM Renderer to Node Renderer


## [1.5.5-fixes] - 2021-03-02
### Added
- Improve cache information from react_component_hash. Hash result now includes 2 new keys
  * RORP_CACHE_HIT
  * RORP_CACHE_KEY
  Additionally, ReactOnRailsPro::Utils.printable_cache_key(cache_key) added.

 [PR 140](https://github.com/shakacode/react_on_rails_pro/pull/140) by [justin808](https://github.com/justin808).

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

[Unreleased]: https://github.com/shakacode/react_on_rails_pro/compare/2.0.0.beta.0...HEAD
[2.0.0.beta.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.5.6...2.0.0.beta.0
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
