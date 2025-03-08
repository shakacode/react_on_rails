# Linters

These linters support the [ShakaCode Style Guidelines](https://www.shakacode.com/react-on-rails/docs/misc/style/)

## Autofix!

If you haven't tried the autofix options for `eslint` and `rubocop`, you're seriously missing out!

1. Be **SURE** you have a clean git status, as you'll want to review what the autofix does to your code!
2. **Rubocop:** Be sure to be in the correct directory where you have Ruby files, usually the top level of your Rails project.

```bash
rubocop -a
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

## ESLint

See the [ESLint](http://eslint.org/) website for more information.

### Configuring Rules

See [the documentation](https://eslint.org/docs/latest/use/configure/rules) first.

Rule severity is configured with `'off'`, `'warn'` or `'error'`. In older configurations you can see `0`, `1`, and `2` instead.

Rules can also take a few additional options. In this case, the rule can be set to an array, the first item of which is the severity and the rest are options.

See file [.eslintrc](https://github.com/shakacode/react_on_rails/tree/master/.eslintrc) for examples of configuration

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
