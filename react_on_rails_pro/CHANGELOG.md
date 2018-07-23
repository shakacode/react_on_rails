# Change Log
All notable changes to this project will be documented in this file. Items under `Unreleased` is upcoming features that will be out in next version.

## [Unreleased]
*Add changes in master not yet tagged.*

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

[Unreleased]: https://github.com/shakacode/react_on_rails_pro/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/shakacode/react_on_rails_pro/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/shakacode/react_on_rails_pro/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/shakacode/react_on_rails_pro/releases/tag/1.0.0

