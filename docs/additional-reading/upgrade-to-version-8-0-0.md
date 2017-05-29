# Upgrading to *react_on_rails* Version 8.0.0

The newest version of *react_on_rails*, 8.0.0, has some key differences compared to version 7.0.4. Most notably, version 8.0.0 will be using the latest version of [webpacker_lite](https://github.com/shakacode/webpacker_lite). This means your webpack-bundles will be placed in your *public* directory. You'll have to make some slight modifications accordingly.  


## General Instructions

1. Update the gem in your Gemfile:

```ruby
	gem 'react_on_rails', '~> 8.0.0.beta.3'
```

2. In client/package.json, update react_on_rails node module to “8.0.0-beta.3”

```json
// client/package.json
  // ...
  "dependencies": {
    // ...
    "react-on-rails": "8.0.0-beta.3",
    // ...
   }
```

3. Install gems and node_modules
    - Simply run ```bundle && yarn```  
    - react_on_rails gem/node_module should be up-to-date now
4. Commit your changes before running react_on_rails generator
	- Run ```git add .``` and ```git commit -m “committing changes before installing react_on_rails”```
	- The generator wont let you install unless you've committed your changes.
5. Run ```rails g react_on_rails:install```
	- this will create ```config/webpacker_lite.yml```
	- the new ```webpacker_lite.yml``` file will replace the previous ```paths.yml```
7. Remove ```//= require webpack-bundle``` from your ```app/assets/javascripts/application.js``` 
	- this gets deleted because the new *webpacker_lite* gem puts its webpack-bundles inside the *public* directory instead of the *assets* directory

