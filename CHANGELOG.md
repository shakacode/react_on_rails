# Change Log
All notable changes to this project will be documented in this file. Items under `Unreleased` is upcoming features that will be out in next version.

## [Unreleased]
*Add changes in master not yet tagged.*

## [1.4.1] - 2019-03-19
### Fixed
- `cached_react_component_hash` incorrectly failed to include the bundle_hash unless `prerender: true` was used as an option. This fix addresses that issue. There is no need to use `prerender: true` as generating a hash only makes sense if prerendering is done.

## [1.4.0] - 2019-01-15
### Added
- Added config option `honeybadgerApiKey` or ENV value `HONEYBADGER_API_KEY` so that errors can flow to HoneyBadger.

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
* Major overhaul of the vm-renderer. Improved logging and error handling, ready for async
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
- Default usage of PORT and LOG_LEVEL for the vm-renderer bin file changed to use values RENDERER_PORT and RENDERER_LOG_LEVEL
- Default Rails config.server_render is "ExecJS". Previously was "VmRenderer"

Above changes in [PR 52](https://github.com/shakacode/react_on_rails_pro/pull/52) by [justin808](https://github.com/justin808).

## [1.0.0]
### Added
- support for node renderer & fallback renderer
- support for javascript evaluation caching
- advanced error handling

[Unreleased]: https://github.com/shakacode/react_on_rails_pro/compare/1.4.0...HEAD
[1.4.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.3.1...1.4.0
[1.3.1]: https://github.com/shakacode/react_on_rails_pro/compare/1.3.0...1.3.1
[1.3.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.2.1...1.3.0
[1.2.1]: https://github.com/shakacode/react_on_rails_pro/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/shakacode/react_on_rails_pro/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/shakacode/react_on_rails_pro/releases/tag/1.0.0

