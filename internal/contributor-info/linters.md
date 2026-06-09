# Linters

These linters support the [ShakaCode Style Guidelines](../../docs/oss/misc/style.md)

## Autofix!

If you haven't tried the autofix options for `eslint` and `rubocop`, you're seriously missing out!

1. Be **SURE** you have a clean git status, as you'll want to review what the autofix does to your code!
2. **RuboCop:** In this monorepo, use the package-scoped bundle that owns the Ruby files. For routine
   formatting, prefer `rake autofix`; for targeted Ruby autofix on a specific package:

```bash
# OSS Ruby (react_on_rails package only; skip if you already ran rake autofix):
# -A includes unsafe cops, matching the set rake autofix applies.
(cd react_on_rails && bundle exec rubocop -A)

# Pro Ruby or RuboCop config changes:
# --ignore-parent-exclusion prevents root AllCops Exclude patterns, written as root-relative paths,
# from being applied while running inside react_on_rails_pro/.
(cd react_on_rails_pro && bundle exec rubocop -A --ignore-parent-exclusion)
```

3. **ESLint:** Be sure to be in the correct directory where you have JS files.

```bash
eslint --fix .
```

or

```bash
npm run lint -- --fix
```

Autofixing is a **HUGE** time saver!

## Prettier

[Prettier](https://prettier.io/) handles code formatting for JavaScript, TypeScript, CSS, and Markdown files.

**⚠️ CRITICAL**: Prettier is the SOLE authority for formatting. Never manually format code.

### Basic Usage

```bash
# Check formatting
pnpm start format.listDifferent

# Fix formatting (includes all linters)
rake autofix

# Or format only
pnpm start format
```

### Merge Conflict Resolution

When resolving merge conflicts, **NEVER manually format**. Follow this sequence:

1. Resolve logical conflicts only
2. `git add .` (or specific files)
3. `rake autofix` (fixes all formatting + linting)
4. `git add .` (if autofix made changes)
5. Continue with `git rebase --continue` or `git commit`

**Why this matters**: Manual formatting during conflict resolution creates "formatting wars" between tools and leads to back-and-forth formatting changes in PRs.

## ESLint

See the [ESLint](https://eslint.org/) website for more information.

### Configuring Rules

See [the documentation](https://eslint.org/docs/latest/use/configure/rules) first.

Rule severity is configured with `'off'`, `'warn'` or `'error'`. In older configurations you can see `0`, `1`, and `2` instead.

Rules can also take a few additional options. In this case, the rule can be set to an array, the first item of which is the severity and the rest are options.

See file [.eslintrc](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails/lib/generators/react_on_rails/templates/.eslintrc) for examples of configuration

### Specify/Override rules in code

Rules can also be specified in the code file to be linted, as JavaScript comments. This can be useful when the rule is a one-off or is a override to a project-wide rule.

For example, if your file assumes a few globals and you have the no-undef rule set in the .eslintrc file, you might want to relax the rule in the current file.

```
/* global $, window, angular */
// rest of code
```

It's also useful to disable ESLint for particular lines or blocks of lines.

```
console.log('console.log not allowed'); // eslint-disable-line

alert('alert not allowed'); // eslint-disable-line no-alert

/* eslint-disable no-console, no-alert */
console.log('more console.log');
alert('more alert');
/* eslint-enable no-console, no-alert */
```

You can disable all rules for a line or block, or only specific rules, as shown above.

## RuboCop

See the [RuboCop website](https://rubocop.org/).
