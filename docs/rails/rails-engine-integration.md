## In your engine

- At the top of `config/initializers/react_on_rails.rb`

```ruby
ActiveSupport.on_load(:action_view) do
  include ReactOnRailsHelper
end
```

- In your `<engine_name>.gemspec`:

```ruby
s.add_dependency 'react_on_rails', '~> 6'
```

- In your `lib/<engine_name>.rb` (the entry point for your engine)

```ruby
require "react_on_rails"
```

## In the project including your engine

Place `gem 'react_on_rails', '~> 6'` before the gem pointing at your engine in your gemfile.

Requiring `react_on_rails` and including the helper will get rid of any issues where `ReactOnRails` or `react_component` is undefined.

As far as solving the assets issue, `lib/tasks/assets.rake` in `react_on_rails` would somehow have to know that `react_on_rails` was included in an engine, and decide the path accordingly. This might be impossible, especially in the case of multiple engines using `react_on_rails` in a single application.

Another solution would be to detach this rake task from the `rails assets:precompile` task. This can be done by adding `REACT_ON_RAILS_PRECOMPILE=false` to your environment. If you do so, then React assets will have to be bundled separately from `rails assets:precompile`.

# Github Issues

- [Integration with an engine #342](https://github.com/shakacode/react_on_rails/issues/342)
- [Feature: target destination option for the install generator #459](https://github.com/shakacode/react_on_rails/issues/459)
- [Integration with Rails 5 Engines #562](https://github.com/shakacode/react_on_rails/issues/562)
- [Run inside a Rails engine? #257](https://github.com/shakacode/react_on_rails/issues/257)
