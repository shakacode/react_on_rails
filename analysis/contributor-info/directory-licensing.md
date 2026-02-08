# Directory Licensing Documentation

> Internal contributor document for repository licensing boundaries.

This document describes the **current** licensing boundaries in this monorepo.

## Source of Truth

- License scope and legal terms: [`LICENSE.md`](../../LICENSE.md)
- Pro license agreement: [`REACT-ON-RAILS-PRO-LICENSE.md`](../../REACT-ON-RAILS-PRO-LICENSE.md)

If this file and `LICENSE.md` ever differ, `LICENSE.md` is authoritative.

## Current Repository Structure

### MIT-Licensed Areas

- `react_on_rails/` (entire directory, including `lib/`, `spec/`, and `sig/`)
- `packages/react-on-rails/` (entire package)
- All other directories not explicitly listed as Pro-licensed

### Pro-Licensed Areas

- `react_on_rails_pro/` (entire directory)
- `packages/react-on-rails-pro/` (entire package)
- `packages/react-on-rails-pro-node-renderer/` (entire package)

## Practical Rules for Contributors

1. Do not move Pro implementation code into MIT-licensed directories.
2. Update `LICENSE.md` when adding or moving Pro directories.
3. Keep package license metadata consistent:
   - `packages/react-on-rails/package.json` -> `MIT`
   - `packages/react-on-rails-pro/package.json` -> `UNLICENSED`
   - `packages/react-on-rails-pro-node-renderer/package.json` -> `UNLICENSED`
4. Keep gem license metadata consistent:
   - `react_on_rails/react_on_rails.gemspec` -> `MIT`
   - `react_on_rails_pro/react_on_rails_pro.gemspec` -> `UNLICENSED`

## License Model Summary

React on Rails Pro is distributed publicly but licensed differently:

- Evaluation, development, testing, and CI/CD usage are allowed without a license token.
- Production deployments require a paid Pro license under the Pro EULA.

For current decisions and merger tracking context, see:

- [`analysis/MERGER_COMMAND_CENTER.md`](../MERGER_COMMAND_CENTER.md)
- [`analysis/merger-decisions.md`](../merger-decisions.md)
