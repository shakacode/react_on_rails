# Contributing

We love pull requests. Here's a quick guide:

1. Fork the repo.

1. Create your feature branch (`git checkout -b my-new-feature`)

1. Update [CHANGELOG.md](https://github.com/michaeldv/awesome_print/blob/master/CHANGELOG.md) with a brief description of your changes under the `unreleased` heading.

1. Commit your changes (`git commit -am 'Added some feature'`)

1. Push to the branch (`git push origin my-new-feature`)

1. Create new Pull Request

At this point you're waiting on us. We like to at least comment on, if not
accept, pull requests within three business days (and, typically, one business
day). We may suggest some changes or improvements or alternatives.

Some things that will increase the chance that your pull request is accepted is to follow the practices described on [Ruby style guide](https://github.com/bbatsov/ruby-style-guide), [Rails style guide](https://github.com/bbatsov/rails-style-guide) and [Better Specs](http://betterspecs.org/).

## Specs

To run all the specs in all gemfiles just run:

```
$ rake
```

To run specs of a single gemfile run:

```
$ appraisal rails-3.2 rake
```

If you want to run a specific spec in a gemfile run:

```
$ appraisal rails-3.2 rspec spec/colors_spec.rb
```
