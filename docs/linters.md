# Linters
The React on Rails generator can add linters and their recommended accompanying configurations to your project (to disable this behavior, include the `--linters` option when running the generator). Those linters that are written in Ruby have been added to your Gemfile, and those that run in Node have been add to your `package.json` under `devDependencies`.

To run the linters (runs both Ruby and Node linters):

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
