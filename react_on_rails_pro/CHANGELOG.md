# Change Log
All notable changes to this project will be documented in this file. Items under `Unreleased` is upcoming features that will be out in next version.

## [Unreleased]
- nothing

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

[Unreleased]: https://github.com/shakacode/react_on_rails_pro/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/shakacode/react_on_rails_pro/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/shakacode/react_on_rails_pro/releases/tag/1.0.0

