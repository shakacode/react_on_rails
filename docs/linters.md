# Linters
The React on Rails generator can add linters and their recommended accompanying configurations to your project. There are two classes of linters: ruby linters and JavaScript linters.

## JavaScript Linters

JavaScript linters are **enabled by default**, but can be disabled by passing the `--skip-js-linters` flag (alias `j`) , and those that run in Node have been add to `client/package.json` under `devDependencies`.

## Ruby Linters
Ruby linters are **disabled by default**, but can be enabled by passing the `--ruby-linters` flag when generating. These linters have been added to your Gemfile in addition to the the appropriate Rake tasks.

## Running the Linters
To run the linters (runs all linters you have installed, even if you installed both Ruby and Node):

```bash
rake lint
```

Run this command to see all the linters available

```bash
rake -T lint
```

**Here's the list:**
```bash
rake lint               # Runs all linters
rake lint:eslint        # eslint
rake lint:js            # JS Linting
rake lint:jscs          # jscs
rake lint:rubocop[fix]  # Run Rubocop lint in shell
rake lint:ruby          # Run ruby-lint as shell
rake lint:scss          # See docs for task 'scss_lint'
```
