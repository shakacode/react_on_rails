# Description

Avoid repeating yourself, use pry-rails instead of copying the initializer to every rails project.
This is a small gem which causes `rails console` to open [pry](http://pry.github.com/). It therefore depends on *pry*.

# Prerequisites

- A Rails >= 3.0 Application

# Installation

Add this line to your gemfile:

	gem 'pry-rails', :group => :development

`bundle install` and enjoy pry.

# Usage

```
$ rails console
[1] pry(main)> show-routes
     pokemon POST   /pokemon(.:format)      pokemons#create
 new_pokemon GET    /pokemon/new(.:format)  pokemons#new
edit_pokemon GET    /pokemon/edit(.:format) pokemons#edit
             GET    /pokemon(.:format)      pokemons#show
             PUT    /pokemon(.:format)      pokemons#update
             DELETE /pokemon(.:format)      pokemons#destroy
        beer POST   /beer(.:format)         beers#create
    new_beer GET    /beer/new(.:format)     beers#new
   edit_beer GET    /beer/edit(.:format)    beers#edit
             GET    /beer(.:format)         beers#show
             PUT    /beer(.:format)         beers#update
             DELETE /beer(.:format)         beers#destroy
[2] pry(main)> show-routes --grep beer
        beer POST   /beer(.:format)         beers#create
    new_beer GET    /beer/new(.:format)     beers#new
   edit_beer GET    /beer/edit(.:format)    beers#edit
             GET    /beer(.:format)         beers#show
             PUT    /beer(.:format)         beers#update
             DELETE /beer(.:format)         beers#destroy
[3] pry(main)> show-routes --grep new
 new_pokemon GET    /pokemon/new(.:format)  pokemons#new
    new_beer GET    /beer/new(.:format)     beers#new
[4] pry(main)> show-models
Beer
  id: integer
  name: string
  type: string
  rating: integer
  ibu: integer
  abv: integer
  created_at: datetime
  updated_at: datetime
  belongs_to hacker
Hacker
  id: integer
  social_ability: integer
  created_at: datetime
  updated_at: datetime
  has_many pokemons
  has_many beers
Pokemon
  id: integer
  name: string
  caught: binary
  species: string
  abilities: string
  created_at: datetime
  updated_at: datetime
  belongs_to hacker
  has_many beers through hacker

$ DISABLE_PRY_RAILS=1 rails console
irb(main):001:0>
```

# Developing and Testing

To generate Gemfiles for Rails 3.0, 3.1, 3.2, 4.0, 4.1, and 4.2, run `rake
appraisal:gemfiles appraisal:install`.

You can then run the tests across all four versions with `rake appraisal`.  You
can also manually run the Rails console and server with `rake appraisal
console` and `rake appraisal server`.

For a specific version of Rails, use `rake appraisal:rails30`, `rake
appraisal:rails31`, `rake appraisal:rails32`, etc.

# Alternative

If you want to enable pry everywhere, make sure to check out
[pry everywhere](http://lucapette.com/pry/pry-everywhere/).
