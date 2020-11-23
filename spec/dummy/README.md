


# Caching

To toggle caching in development, as explained in [this article](http://guides.rubyonrails.org/caching_with_rails.html#caching-in-development)
`rails dev:cache`


## Run yarn if not done yet

```sh
cd react_on_rails
yarn run dummy:install
```

# Starting the Sample App

## Static Loading of Rails Assets
```sh
foreman start -f Procfile.static
```

## Creating Assets for Tests
```sh
foreman start -f Procfile.spec
```
