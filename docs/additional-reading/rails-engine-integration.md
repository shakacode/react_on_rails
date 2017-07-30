## In your engine

+ At the top of `config/initializers/react_on_rails.rb`
```ruby
ActiveSupport.on_load(:action_view) do
  include ReactOnRailsHelper
end
```
+ In your `<engine_name>.gemspec`:
```ruby
s.add_dependency 'react_on_rails', '~> 6'
```
+ In your `lib/<engine_name>.rb` (the entry point for your engine)
```ruby
require "react_on_rails"
```
+ In your `lib/tasks/<engine_name>_tasks.rake`:
```ruby
Rake.application.remove_task('react_on_rails:assets:compile_environment')

task 'react_on_rails:assets:compile_environment' do
  path = File.join(YourEngineName::Engine.root, 'client')
  sh "cd #{path} && #{ReactOnRails.configuration.build_production_command}"
end
``` 
## In the project including your engine

Place `gem 'react_on_rails', '~> 6'` before the gem pointing at your engine in your gemfile.

This is necessary because React on Rails attaches itself to the rake assets:precompile task. It then uses a direct path to cd into client, which will not exist in the main app that includes your engine. Since you'll always be precompiling assets in the parent app, this will always fail. The workaround then, is to remove the task and replace it with one that goes into your Engine's root. The reason you have to include the react on rails gem before your engine is so that the `react_on_rails:assets:compile_environment` task is defined by the time your engine gets loaded to remove it.

Requiring `react_on_rails` and including the helper will get rid of any issues where react on rails or react_component is undefined.

As far as solving the assets issue, `lib/tasks/assets.rake` in `react_on_rails` would somehow have to know that `react_on_rails` was included in an engine, and decide the path accordingly. This might be impossible, especially in the case of multiple engines using `react_on_rails` in a single application. Another solution would be to detach this rake task from the rails assets:precompile task, and let people use it separately.
