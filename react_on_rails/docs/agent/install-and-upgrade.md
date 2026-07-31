# Install and upgrade

Use this guide for an existing Rails app. Keep app-specific choices and custom configuration intact.

## Preflight

- Record the Rails, Ruby, Node, Shakapacker, React on Rails gem, npm package, and package-manager state.
- Identify both Ruby and JavaScript lockfiles and start from a reviewable working tree.
- Keep the gem and npm package on the same React on Rails release. A Pro app must also update its Pro
  gem and JavaScript packages together.

## Install

Add Shakapacker and React on Rails through Bundler.
Choose exactly one stack flag before running the install generator.
Use `--standard-only` for OSS, `--pro` for Pro, or `--rsc` for Pro with RSC.
Do not rely on an interactive TTY prompt; replace `<STACK_FLAG>` explicitly in every command.
Choose the language explicitly too: replace `<LANGUAGE_CHOICE>` with `--typescript` for TypeScript,
or remove that placeholder for JavaScript. TypeScript is optional; omitting its flag preserves JavaScript.

```bash
bundle add shakapacker --strict
bundle add react_on_rails --strict
```

Skip this Pro-gem preparation for `--standard-only`.
For `--pro` or `--rsc` only, derive the exact installed base-gem version before adding the Pro gem:

```bash
ROR_GEM_VERSION="$(bundle exec ruby -rreact_on_rails/version -e 'print ReactOnRails::VERSION')"
bundle add react_on_rails_pro --version="${ROR_GEM_VERSION}" --strict
```

If that exact version is an unpublished prerelease, require a matching local/path `react_on_rails_pro` gem
and use the same exact version instead of the registry command:

```bash
bundle add react_on_rails_pro --path="<path-to-matching-react_on_rails_pro>" --version="${ROR_GEM_VERSION}" --strict
```

Never fall back silently to a stable Pro gem.
For `--pro` or `--rsc` only, after either Pro source command succeeds, remove the direct base-gem declaration:

```bash
bundle remove react_on_rails
```

This cleanup removes only the direct `react_on_rails` declaration; `react_on_rails_pro` retains the matching base gem
transitively. Do not run this cleanup for `--standard-only`.

After the conditional Pro preparation, run the generator with the explicit stack flag:

```bash
bundle exec rails generate react_on_rails:install <LANGUAGE_CHOICE> <STACK_FLAG>
```

Use the app's declared JavaScript package manager if the generator prints a manual install command.
Review the generated initializer, Shakapacker configuration, scripts, routes, and sample files.

## Upgrade

1. Record the installed Ruby gem version as `CURRENT_VERSION`:

   ```bash
   CURRENT_VERSION="$(bundle exec ruby -rreact_on_rails/version -e 'puts ReactOnRails::VERSION')"
   printf '%s\n' "$CURRENT_VERSION"
   ```

2. Choose and verify explicit Ruby and npm target versions before editing dependency pins. Record
   the Ruby/tag form as `GEM_TARGET_VERSION` and the npm semver form as `NPM_TARGET_VERSION`.
   Ruby prereleases use dot notation (for example, `17.0.0.rc.6`); npm prereleases use hyphen notation
   (for example, `17.0.0-rc.6`). Choose both explicitly rather than deriving either from
   `CURRENT_VERSION` or from the other target.

   ```bash
   GEM_TARGET_VERSION="<Ruby/tag version you selected>"
   NPM_TARGET_VERSION="<npm semver version you selected>"
   git ls-remote --exit-code --tags https://github.com/shakacode/react_on_rails.git \
     "refs/tags/v${GEM_TARGET_VERSION}"
   ```

3. Read the changelog and upgrade guidance from the immutable repository tag `v<GEM_TARGET_VERSION>`:
   `https://github.com/shakacode/react_on_rails/tree/v<GEM_TARGET_VERSION>`. Compare the complete
   `CURRENT_VERSION..GEM_TARGET_VERSION` release range before changing dependencies:
   `https://github.com/shakacode/react_on_rails/compare/v<CURRENT_VERSION>...v<GEM_TARGET_VERSION>`.

## JavaScript target matrix

Use exactly the row matching the detected stack. Verify every relevant package version before
pinning it; checking only the base package is insufficient. Use the app's declared package manager's
registry-inspection command for every exact package spec below. Do not assume pnpm, npm, Yarn, or Bun
is available merely because another package manager is installed.

- **OSS (`--standard-only`)**: pin and verify `react-on-rails@${NPM_TARGET_VERSION}`.

- **Pro (all renderers)**: pin and verify `react-on-rails-pro@${NPM_TARGET_VERSION}`. Also pin and verify
  `react-on-rails-pro-node-renderer@${NPM_TARGET_VERSION}` only when the app uses the standalone NodeRenderer.
  Do not add a direct `react-on-rails` dependency to Pro or RSC apps.

- **RSC (`--rsc`)**: follow the Pro rule, including its conditional standalone NodeRenderer package
  and prohibition on a direct base dependency. Select `RSC_TARGET_VERSION` independently from the
  target release guidance or the target tag's
  `ReactOnRails::Generators::JsDependencyManager::RSC_PACKAGE_VERSION_PIN`:
  `https://github.com/shakacode/react_on_rails/blob/v<GEM_TARGET_VERSION>/react_on_rails/lib/generators/react_on_rails/js_dependency_manager.rb`.
  Never derive `RSC_TARGET_VERSION` from `NPM_TARGET_VERSION`. Pin and verify the exact
  `react-on-rails-rsc@${RSC_TARGET_VERSION}` release.

  ```bash
  RSC_TARGET_VERSION="<exact RSC pin from target guidance>"
  ```

4. Pin Ruby gems with `GEM_TARGET_VERSION` and regenerate the Bundler lockfile.
   Apply exactly the matching JavaScript matrix row with the app's declared package manager, pin each
   package to the verified exact version, and regenerate the JavaScript lockfile.
5. Detect the app's existing stack and current generator choices from its dependencies and
   configuration. Use the one preserving mapping that matches the existing stack:
   - Use `--standard-only` for an existing OSS stack.
   - Use `--pro` only for an existing Pro + NodeRenderer stack.
   - Use `--rsc` for an existing RSC stack.

   Pro + ExecJS has no preserving install-generator flag.
   For that stack, skip both generator preview and apply steps; upgrade dependencies and configuration manually.
   Preserve the ExecJS renderer setup. For the three preserving mappings, preserve the current stack.
   Preserve every other current generator choice, such as TypeScript, Redux, or generated
   test-framework choices.

6. For a stack with a preserving mapping, first rerun the generator as a preview, substituting the
   selected stack flag and the app's other current choices:

   ```bash
   bundle exec rails generate react_on_rails:install --pretend <STACK_FLAG> <OTHER_CURRENT_CHOICES>
   ```

   `--pretend` omits dependency installation and script effects; it is not a complete mutation audit.
   Review the complete preview without overwriting app-owned configuration. Never prescribe or run a
   bare, non-TTY generator rerun.

7. Only for a stack with a preserving mapping, and only after reviewing and accepting the preview,
   apply the same choices without `--pretend`:

   ```bash
   bundle exec rails generate react_on_rails:install <STACK_FLAG> <OTHER_CURRENT_CHOICES>
   ```

8. Run the doctor loop, compile assets, and run focused application tests.

```bash
bin/rails react_on_rails:doctor FORMAT=json
bundle exec rails shakapacker:compile
```

Secondary references:
https://reactonrails.com/docs/getting-started/existing-rails-app and
https://reactonrails.com/docs/upgrading/upgrading-react-on-rails.
