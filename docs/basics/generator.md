- [Generator](#generator)
  - [Understanding the Organization of the Generated Client Code](#understanding-the-organization-of-the-generated-client-code)
  - [Redux](#redux)
  - [Using Images and Fonts](#using-images-and-fonts)

The `react_on_rails:install` generator combined with the example pull requests of generator runs will get you up and running efficiently. There's a fair bit of setup with integrating Webpack with Rails. Defaults for options are such that the default is for the flag to be off. For example, the default for `-R` is that `redux` is off, and the default of `-b` is that `skip-bootstrap` is off.

Run `rails generate react_on_rails:install --help` for descriptions of all available options:

```
Usage:
  rails generate react_on_rails:install [options]

Options:
  -R, [--redux], [--no-redux]                      # Install Redux gems and Redux version of Hello World Example. Default: false
  -N, [--node], [--no-node]                        # Sets up node as a server rendering option. Default: false
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

* Node

    Passing the --node generator option sets up the necessary files for node to render the react_components.

*******************************************************************************

After running the generator, you will want to:

    bundle && npm i

Then you may run

    foreman start -f Procfile.dev

More Details:

    `https://github.com/shakacode/react_on_rails/blob/master/docs/basics/generator.md`
```

Another good option is to create a simple test app per the [Tutorial](../tutorial.md).

### Understanding the Organization of the Generated Client Code
The generated client code follows our organization scheme. Each unique set of functionality, is given its own folder inside of `client/app/bundles`. This encourages for modularity of *domains*.

Inside of the generated "HelloWorld" domain you will find the following folders:

+  `startup`: This contains the entry point files for webpack. It defaults to a single file that is used for server and client compilation, but if these need to be different, then you can create two webpack configurations with separate endpoints.
+ `containers`: "smart components" (components that have functionality and logic that is passed to child "dumb components").
+ `components`: includes "dumb components", or components that simply render their properties and call functions given to them as properties by a parent component. Ultimately, at least one of these dumb components will have a parent container component.

You may also notice the `app/lib` folder. This is for any code that is common between bundles and therefore needs to be shared (for example, middleware).

### Redux
If you have used the `--redux` generator option, you will notice the familiar additional redux folders in addition to the aforementioned folders. The Hello World example has also been modified to use Redux.

Note the organizational paradigm of "bundles". These are like application domains and are used for grouping your code into webpack bundles, in case you decide to create different bundles for deployment. This is also useful for separating out logical parts of your application. The concept is that each bundle will have it's own Redux store. If you have code that you want to reuse across bundles, including components and reducers, place them under `/client/app/lib`.

### Using Images and Fonts
The generator has amended the folders created in `client/assets/` to Rails's asset path. We recommend that if you have any existing assets that you want to use with your client code, you should move them to these folders and use webpack as normal. This allows webpack's development server to have access to your assets, as it will not be able to see any assets in the default Rails directories which are above the `/client` directory.

Alternatively, if you have many existing assets and don't wish to move them, you could consider creating symlinks from client/assets that point to your Rails assets folders inside of `app/assets/`. The assets there will then be visible to both Rails and webpack.
