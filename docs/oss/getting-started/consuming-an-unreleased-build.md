---
slug: consuming-an-unreleased-build
---

# Consuming an Unreleased Build

Use this page when you need to test an unreleased version of React on Rails in
your own application — before it is published to RubyGems or npm.

> [!NOTE]
> **Summary for AI agents:** This is the adopter-facing version of the
> "Testing your changes in an external application" section of
> [CONTRIBUTING.md](https://github.com/shakacode/react_on_rails/blob/main/CONTRIBUTING.md).
> It covers pointing a downstream app at a Git branch (gems) and at the
> per-package npm subdirectories. The two non-obvious gotchas are the
> OSS-vs-Pro `glob:` asymmetry for gems and the fact that bare
> `owner/repo#ref` npm refs do not work for the subdirectory packages.

## When you need this

React on Rails ships the gem and several npm packages from a single monorepo.
When a fix or feature has landed on `main` (or another branch) but has not yet
been released, you can still consume it directly from Git so you can validate it
in a real application before the next release.

This is useful when you want to:

- Verify a bug fix against your app before it is published.
- Try a feature on an upcoming branch.
- Reproduce or confirm behavior reported in an issue or PR.

## Ruby gems

Point your `Gemfile` at the Git repository and branch:

```ruby
gem 'react_on_rails',
  git: 'https://github.com/shakacode/react_on_rails',
  branch: 'main'
gem 'react_on_rails_pro',
  git: 'https://github.com/shakacode/react_on_rails',
  glob: 'react_on_rails_pro/react_on_rails_pro.gemspec',
  branch: 'main'
```

Note the asymmetry: the open-source `react_on_rails` gem needs **no** `glob:`
option — its gemspec lives at the repository root and Bundler finds it
automatically. Only `react_on_rails_pro` needs an explicit
`glob: 'react_on_rails_pro/react_on_rails_pro.gemspec'` because its gemspec
lives in a subdirectory. Run `bundle install` afterward, and use
`bundle update react_on_rails react_on_rails_pro` to pull newer commits from the
branch.

## npm packages

The npm packages live in subdirectories of the monorepo
(`packages/react-on-rails`, `packages/react-on-rails-pro`,
`packages/react-on-rails-pro-node-renderer`). Not every package manager can
depend on a single subdirectory of a Git repo, so the recommended path depends
on your manager.

### pnpm (recommended, v9+)

pnpm can install a subdirectory of a Git repo directly:

```shell
pnpm add "github:shakacode/react_on_rails#main&path:packages/react-on-rails"
```

For Pro, add the additional packages the same way, substituting
`packages/react-on-rails-pro` and
`packages/react-on-rails-pro-node-renderer` for the `path:` value.

### Yarn Berry

Yarn Berry supports the Git protocol with a workspace selector:

```shell
yarn add "git@github.com:shakacode/react_on_rails.git#workspace=react-on-rails&head=main"
```

### npm (and managers that can't resolve a Git subdirectory)

npm does not support depending on a subdirectory of a Git repo, so build a
tarball with `pnpm pack` and install that:

```shell
# In the React on Rails checkout
pnpm install && pnpm run build
cd packages/react-on-rails && pnpm pack   # creates react-on-rails-<version>.tgz

# In your app
npm install <path-to-tarball>
```

For rapid iteration, [yalc](https://github.com/whitecolor/yalc) is an
alternative: after `pnpm run build`, run `yalc publish` from each
`packages/*` directory you changed, then `yalc add <package>` in your app.

> [!TIP]
> **Why a bare `owner/repo#ref` fails for these packages:** a bare Git ref
> resolves the workspace **root**, not the publishable subdirectory you want.
> In addition, each package's `lib/` output is gitignored (`packages/*/lib/`)
> and produced by the package's `prepare`/build script — which some package
> managers skip for Git dependencies — so you would end up without the built
> output. The pnpm `path:` selector and the tarball both avoid this.

## React Server Components package

React Server Components also depend on the separate `react-on-rails-rsc` npm
package. Prefer a released package version when possible. For temporary testing
of an unreleased `react-on-rails-rsc` fix, choose the workflow based on how
widely the build must be shared:

| Workflow                                | Use when                                                                   | Tradeoff                                                                |
| --------------------------------------- | -------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| yalc                                    | You are iterating locally in one downstream app.                           | Fastest loop, but not useful for CI or sharing.                         |
| Canary npm publish                      | Teammates or CI need the same temporary build.                             | Requires maintainer npm publish rights and a unique prerelease version. |
| Packed tarball or throwaway dist branch | A package manager needs built files and npm publishing is not appropriate. | Must never be treated as the official release path.                     |

Avoid plain source-branch dependencies for `react-on-rails-rsc`, especially with
Yarn Classic:

```shell
yarn add react-on-rails-rsc@git+https://github.com/shakacode/react_on_rails_rsc.git#main
```

The package does not commit `dist/`; published npm tarballs include it.
Depending on install flags, cache state, and the package manager environment, a
Git dependency can install without the built files that package exports point
at, or spend the app install trying to build the package from source.

For a local yalc loop:

```shell
# In the react_on_rails_rsc checkout
yarn
yarn build
yalc publish

# In the downstream app
yalc add react-on-rails-rsc
yarn install
```

After each package change, rebuild and refresh the downstream app copy:

```shell
yarn build
yalc push
```

Do not commit yalc artifacts such as `.yalc/`, `yalc.lock`, or temporary
`package.json` dependency rewrites unless the downstream project deliberately
tracks them for its own testing workflow.

## Version pairing

When you consume an unreleased build, bump the related packages **together** so
versions stay compatible:

- `react_on_rails` (gem)
- `react-on-rails` (npm)
- `react_on_rails_pro` (gem)
- `react-on-rails-pro` (npm)
- `react-on-rails-pro-node-renderer` (npm)
- `react-on-rails-rsc` (npm), if you use React Server Components — see
  [shakacode/react_on_rails_rsc#109](https://github.com/shakacode/react_on_rails_rsc/issues/109)

Mixing a new gem with old npm packages (or vice versa) is the most common cause
of confusing failures when testing an unreleased build.

## See also

For the contributor-oriented version — including local `path:` dependencies and
testing changes against the in-repo dummy apps — see
[Testing your changes in an external application](https://github.com/shakacode/react_on_rails/blob/main/CONTRIBUTING.md#testing-your-changes-in-an-external-application)
in `CONTRIBUTING.md`.
