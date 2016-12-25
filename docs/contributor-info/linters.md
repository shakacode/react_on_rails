# Linters
These linters support the [ShakaCode Style Guidelines](./style.md)

## Autofix!

If you haven't tried the autofix options for `eslint` and `rubocop`, you're seriously missing out!

1. Be **SURE** you have a clean git status, as you'll want to review what the autofix does to your code!
2. **Rubocop:**  Be sure to be in the right directory where you have Ruby files, probably the top level of your Rails project.
  ```
  rubocop -a
  ```

3. **eslint:**: Be sure to be in the right directory where you have JS files.
  ```
  eslint --fix .
  ```
  
  or 
  
  ```
  npm run lint -- --fix
  ```

Autofixing is a **HUGE** time saver!

## ESLint

### Configuring Rules

Rules are configured with a 0, 1 or 2. Setting a rule to 0 is turning it off, setting it to 1 triggers a warning if that rule is violated, and setting it to 2 triggers an error.

Rules can also take a few additional options. In this case, the rule can be set to an array, the first item of which is the 0/1/2 flag and the rest are options.

See file [.eslintrc](../../client/.eslintrc) for examples of configuration

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

### Useful Reference Links

* [Configuring ESLint](http://eslint.org/docs/user-guide/configuring.html#configuring-rules)
* [ESLint quick start](http://untilfalse.com/eslint-quick-start/)
* [RuboCop](https://github.com/bbatsov/rubocop)
* [ESLint](http://eslint.org/)

