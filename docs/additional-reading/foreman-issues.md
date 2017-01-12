# Foreman Issues

## It is not recomended to include foreman into Gemfile

See: https://github.com/ddollar/foreman

> Ruby users should take care not to install foreman in their project's Gemfile.

## Known issues

 * With `foreman 0.82.0` npm `react-s3-uploader` was failing to finish upload file to S3 when server was started by `foreman -f Procfile.dev`, 
   at the same time the same code works fine when ruby server started by `bundle exec rails s`.

 * The same Procfile with different versions of `foreman` in combination with different versions of `bundler` may produce different output of `ps aux`.
   This may brake bash tools which rely on `ps` output.
