# Previous generated RSC config fixture

`manifest_era_b58d1fe8b.js` is a verbatim `clientWebpackConfig.js` as the last pre-#5079
`rails g react_on_rails:rsc` version produced it: the golden `webpack_rsc` fixture as
committed at `b58d1fe8b`, i.e. the generated output immediately before the
react-on-rails-pro client-component registrations (issue #5079) were appended to the
emitted resolver.

The file is byte-verbatim historical output — no added headers or comments — so the
outdated-resolver detection in `rsc_generator_spec.rb` sees exactly what a real app
contains. The generator never rewrites this shape; the specs pin that it warns with
manual registration instructions and leaves the file unchanged.
