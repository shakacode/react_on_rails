# Linters
The React on Rails generator automatically adds linters and their recommended accompanying configurations to your project (to disable this behavior, include the `--skip-linters` option when running the generator). Those linters that are written in Ruby have been added to your Gemfile, and those that run in Node have been add to your `package.json` under `devDependencies`.

To run the linters (runs both Ruby and Node linters):

```bash
rake lint
```
