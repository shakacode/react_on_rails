# Generator Details

The `react_on_rails:install` generator combined with the example pull requests of generator runs will get you up and running efficiently. There's a fair bit of setup with integrating Webpack with Rails. Defaults for options are such that the default is for the flag to be off. For example, the default for `-R` is that `redux` is off.

Run `rails generate react_on_rails:install --help` for descriptions of all available options:

```
Usage:
  rails generate react_on_rails:install [options]

Options:
  -R, [--redux], [--no-redux]                      # Install Redux package and Redux version of Hello World Example. Default: false
      [--ignore-warnings], [--no-ignore-warnings]  # Skip warnings. Default: false

Runtime options:
  -f, [--force]                    # Overwrite files that already exist
  -p, [--pretend], [--no-pretend]  # Run but do not make any changes
  -q, [--quiet], [--no-quiet]      # Suppress status output
  -s, [--skip], [--no-skip]        # Skip files that already exist

Description:

The react_on_rails:install generator integrates webpack with rails with ease. You
can pass the redux option if you'd like to have redux setup for you automatically.

* Redux

    Passing the --redux generator option causes the generated Hello World example
    to integrate the Redux state container framework. The necessary node modules
    will be automatically included for you.

*******************************************************************************


Then you may run

    `rails s`
```

Another good option is to create a simple test app per the [Tutorial](../guides/tutorial.md).

# Understanding the Organization of the Generated Client Code

The generated client code follows our organization scheme. Each unique set of functionality is given its own folder inside of `app/javascript/app/bundles`. This encourages modularity of _domains_.

Inside the generated "HelloWorld" domain you will find the following folders:

- `startup`: contains the entry point files for webpack. It defaults to a single file that is used for both server and client compilation. But if these need to be different, then you can create two Webpack configurations with separate endpoints. Since RoR v14.2 this is strongly recommended because the client can import `react-on-rails/client` instead of `react-on-rails` for decreased bundle size.
- `containers`: contains "smart components" (components that have functionality and logic that is passed to child "dumb components").
- `components`: contains "dumb components", or components that simply render their properties and call functions given to them as properties by a parent component. Ultimately, at least one of these dumb components will have a parent container component.

You may also notice the `app/lib` folder. This is for any code that is common between bundles and therefore needs to be shared (for example, middleware).

## Redux

If you have used the `--redux` generator option, you will notice the familiar additional redux folders in addition to the aforementioned folders. The Hello World example has also been modified to use Redux.

Note the organizational paradigm of "bundles". These are like application domains and are used for grouping your code into webpack bundles, in case you decide to create different bundles for deployment. This is also useful for separating out logical parts of your application. The concept is that each bundle will have it's own Redux store. If you have code that you want to reuse across bundles, including components and reducers, place them under `/client/app/lib`.
