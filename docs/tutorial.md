# Tutorial for React on Rails (THIS ONLY WORKS UP TO VERSION 5.1.1)

*Version 5.2 and greater have removed the non-essential options. See the [changelog](../CHANGELOG.md) for details on what was removed.*

This tutorial setups up a new Rails app with **React on Rails**, demonstrating Rails + React + Redux + Server Rendering.

You can find:

* [Source code for this sample app](https://github.com/justin808/test-react-on-rails-3) (for an older version)
* [Live on Heroku](https://shakacode-react-on-rails.herokuapp.com/hello_world)

By the time you read this, the latest may have changed. Be sure to check the versions here:

* https://rubygems.org/gems/react_on_rails
* https://www.npmjs.com/package/react-on-rails

Trying out v4 is super easy, so long as you have the basic prerequisites. This includes the basics for Rails 4.x and node version 5+. I recommend `rvm` and `nvm` to install Ruby and Node.

```
cd <directory where you want to create your new Rails app>
# any name you like
rails new test-react-on-rails-3
cd test-react-on-rails-3
# git-extras command to make a new git repo and commit everything
git setup
vim Gemfile
```

Add this line to your Gemfile:

```
gem 'react_on_rails'
```


```
bundle
bundle exec rails generate react_on_rails:install -R -S -H -L
bundle && npm i
npm run rails-server
```

* R => Redux
* S => Server Rendering
* H => Heroku setup
* L => Linters


Visit http://localhost:3000/hello_world and see your React On Rails app running!

```
npm run express-server
```

<img src="http://forum.shakacode.com/uploads/default/original/1X/5bd396a7f9c0764929b693fb79eb6685ec6f62cf.png" width="470" height="499">

Visit http://localhost:4000 and see your React On Rails app running using the Webpack Dev server.

With this setup, you can make changes to your JS or CSS and the browser will hot reload the changes (no page refresh required).

I'm going to add this line to client/app/bundles/HelloWorld/HelloWorldWidget.jsx:

```html
<h1>Welcome to React On Rails!</h1>
```

<img src="http://forum.shakacode.com/uploads/default/original/1X/d20719a52541e95ddd968a95192d3247369c3bf6.png" width="498" height="500">

If you save, you'll soon see this screen:

<img src="http://forum.shakacode.com/uploads/default/original/1X/228706a99a411548a4539f72446d3f115ed36f95.png" width="555" height="500">


If you're motivated to try the linting setup, you'll want to run the following commands:

     bin/rake lint

You'll see a few rubocop errors.

    rubocop -a

That will fix almost all the errors. However, the linter setup expects you to have rspec (small bug currently). These two commands address that issue:

```
rm -rf test
mkdir spec
```

    bin/rake lint

The edit `application.scss`. Delete the comment at the top.

    bin/rake lint

You should see 

```
bin/rake lint                                                                                                                                                                                                   

Running via Spring preloader in process 26674
Running Rubocop Linters via `rubocop -S -D .`
rubocop -S -D .
Warning: Deprecated pattern style '/Users/justin/scratch/test-react-on-rails-3/client/node_modules/**/*' in /Users/justin/scratch/test-react-on-rails-3/.rubocop.yml
Inspecting 22 files
......................

22 files inspected, no offenses detected
Running ruby-lint Linters via `ruby-lint app config spec lib`
ruby-lint app config spec lib
scss-lint found no lints
Running eslint via `cd client && npm run eslint . -- --ext .jsx,.js`
cd client && npm run eslint . -- --ext .jsx,.js

> react-webpack-rails-tutorial@1.1.0 eslint /Users/justin/scratch/test-react-on-rails-3/client
> eslint --ext .js,.jsx . "." "--ext" ".jsx,.js"

Running jscs via `cd client && npm run jscs .`
cd client && npm run jscs .

> react-webpack-rails-tutorial@1.1.0 jscs /Users/justin/scratch/test-react-on-rails-3/client
> jscs --verbose . "."

Completed running all JavaScript Linters
Completed all linting
```

## RubyMine

It's super important to exclude certain directories from RubyMine or else it will slow to a crawl as it tries to parse all the npm files.

* `app/assets/webpack`
* `client/node_modules`

<img src="http://forum.shakacode.com/uploads/default/original/1X/a1b3e1146d86915f7d5d1c89548e81ec208458cc.png" width="338" height="500">


## Deploying to Heroku

### Create Your Heroku App
*Assuming you can login to heroku.com and have logged into to your shell for heroku.*

1. Visit https://dashboard.heroku.com/new and create an app, say named `my-name-react-on-rails`:

<img src="http://forum.shakacode.com/uploads/default/original/1X/2d1b6abc40eef8e411e84d2679de91353f617567.png" width="690" height="319">

Run this command that looks like this from your new heroku app

    heroku git:remote -a my-name-react-on-rails

Set heroku to use multiple buildpacks:

    heroku buildpacks:set heroku/ruby
    heroku buildpacks:add --index 1 heroku/nodejs


### Swap out sqlite for postgres by doing the following:

1. Delete the line with `sqlite` and replace it with:

```ruby
   gem 'pg'
```

2. Replace your `database.yml` file with this (assuming your app name is "ror").

```yml
default: &default
  adapter: postgresql
  username:
  password:
  host: localhost

development:
  <<: *default
  database: ror_development

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: ror_test

production:
  <<: *default
  database: ror_production
```

Then you need to setup postgres so you can run locally:

```
bundle
bin/rake db:migrate
bin/rake db:setup
```

I'd recommend adding this line to the top of your `routes.rb`. That way, your root page will go to the Hello World page for React On Rails.

```ruby
root "hello_world#index"
```

You can see the changes [here on github](https://github.com/justin808/test-react-on-rails-3/commit/09909433c186566a53f611e8b1cfeca3238f5266).

Then push your app to Heroku!

    git push heroku master

Here's mine:

* [Source code for this sample app](https://github.com/justin808/test-react-on-rails-3)
* [Live on Heroku](https://shakacode-react-on-rails.herokuapp.com/hello_world)

Feedback is greatly appreciated! As are stars on github!
