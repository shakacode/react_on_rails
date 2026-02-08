# React on Rails Licensing FAQ

> Internal contributor FAQ for repository licensing and merger execution context.

## Q: What is licensed under MIT?

The open-source package areas are MIT licensed:

- `react_on_rails/` (gem code and tests)
- `packages/react-on-rails/` (npm package)
- Other repository paths not explicitly marked as Pro in `LICENSE.md`

## Q: What is Pro-licensed?

The Pro package areas are licensed under the React on Rails Pro License:

- `react_on_rails_pro/`
- `packages/react-on-rails-pro/`
- `packages/react-on-rails-pro-node-renderer/`

See [`REACT-ON-RAILS-PRO-LICENSE.md`](../../REACT-ON-RAILS-PRO-LICENSE.md) for full terms.

## Q: Is React on Rails Pro publicly distributed?

Yes. Pro packages are publicly distributed on RubyGems and npm.

- Ruby gem: `react_on_rails_pro`
- npm packages: `react-on-rails-pro`, `react-on-rails-pro-node-renderer`

## Q: Do I need a license token to evaluate Pro?

No. React on Rails Pro supports evaluation, development, testing, and CI/CD without a token.

## Q: When is a paid Pro license required?

Production use requires a paid license under the Pro EULA.

## Q: How should Pro users import client APIs?

Import from `react-on-rails-pro`, not `react-on-rails`.

```javascript
import ReactOnRails from 'react-on-rails-pro';
```

## Q: How is license separation enforced in the monorepo?

By directory boundaries plus metadata consistency:

- `LICENSE.md` explicitly lists Pro paths.
- Pro npm packages use `"license": "UNLICENSED"`.
- Pro gemspec uses `s.license = "UNLICENSED"`.

## Q: What should contributors avoid?

- Moving Pro implementation code into MIT directories.
- Adding new Pro directories without updating `LICENSE.md`.
- Mixing core and Pro import paths in the same integration example without clear intent.

## Q: Where is active merger/licensing execution tracked?

Use these docs:

- `analysis/MERGER_COMMAND_CENTER.md`
- `analysis/PR_ISSUE_TRIAGE_2026-02-08.md`
- `analysis/merger-decisions.md`
