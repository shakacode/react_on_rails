# Foreman Issues

## It is not recommended to include foreman into Gemfile

See: https://github.com/ddollar/foreman

> Ruby users should take care not to install foreman in their project's Gemfile.

## Known issues

- With `foreman 0.82.0`, the NPM package `react-s3-uploader` was failing to finish uploading a file to S3 when the server was started by `foreman -f Procfile.dev`.
  At the same time, the same code works fine when the Ruby server is started by `bundle exec rails s`.

- The same Procfile with different versions of `foreman` in combination with different versions of `bundler` may produce different output of `ps aux`.
  This may break Bash tools which rely on `ps` output.
