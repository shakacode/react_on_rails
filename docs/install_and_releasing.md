### Install and Release
To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Updating New Versions of the Gem
See https://github.com/svenfuchs/gem-release

```bash
gem bump
cd spec/dummy
bundle
git commit -am "Updated Gemfile.lock"
cd ../..
gem tag
gem release
```

## Testing the Gem before Release from a Rails App
If you want to test the gem with an application before you release a new version of the gem, you can specify the path to your local version via your test app's Gemfile:

```ruby
gem "react_on_rails", path: "../path-to-react-on-rails"
```

Note that you will need to bundle install after making this change, but also that **you will need to restart your Rails application if you make any changes to the gem**.
