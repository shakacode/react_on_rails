- [Generator](#generator)
  - [Understanding the Organization of the Generated Client Code](#understanding-the-organization-of-the-generated-client-code)
  - [Redux](#redux)
    - [Multiple React Components on a Page with One Store](#multiple-react-components-on-a-page-with-one-store)
  - [Using Images and Fonts](#using-images-and-fonts)
  - [Bootstrap Integration](#bootstrap-integration)
      + [Bootstrap via Rails Server](#bootstrap-via-rails-server)
      + [Bootstrap via Webpack HMR Dev Server](#bootstrap-via-webpack-hmr-dev-server)
      + [Keeping Custom Bootstrap Configurations Synced](#keeping-custom-bootstrap-configurations-synced)
      + [Skip Bootstrap Integration](#skip-bootstrap-integration)
  - [Linters](#linters)
      + [JavaScript Linters](#javascript-linters)
      + [Ruby Linters](#ruby-linters)
      + [Running the Linters](#running-the-linters)
        
The `react_on_rails:install` generator combined with the example pull requests of generator runs will get you up and running efficiently. There's a fair bit of setup with integrating Webpack with Rails. Defaults for options are such that the default is for the flag to be off. For example, the default for `-R` is that `redux` is off, and the default of `-b` is that `skip-bootstrap` is off.

Run `rails generate react_on_rails:install --help` for descriptions of all available options:

```
Usage:
  rails generate react_on_rails:install [options]

Options:
  -R, [--redux], [--no-redux]                          # Install Redux gems and Redux version of Hello World Example
  -S, [--server-rendering], [--no-server-rendering]    # Add necessary files and configurations for server-side rendering
  -j, [--skip-js-linters], [--no-skip-js-linters]      # Skip installing JavaScript linting files
  -L, [--ruby-linters], [--no-ruby-linters]            # Install ruby linting files, tasks, and configs
  -H, [--heroku-deployment], [--no-heroku-deployment]  # Install files necessary for deploying to Heroku
  -b, [--skip-bootstrap], [--no-skip-bootstrap]        # Skip installing files for bootstrap support

Runtime options:
  -f, [--force]                    # Overwrite files that already exist
  -p, [--pretend], [--no-pretend]  # Run but do not make any changes
  -q, [--quiet], [--no-quiet]      # Suppress status output
  -s, [--skip], [--no-skip]        # Skip files that already exist

Description:
    Create react on rails files for install generator.
```

For a clear example of what each generator option will do, see our generator results repo: [Generator Results](https://github.com/shakacode/react_on_rails-generator-results/blob/master/README.md). Each pull request shows a git "diff" that highlights the changes that the generator has made. Another good option is to create a simple test app per the [Tutorial](docs/tutorial.md).

### Understanding the Organization of the Generated Client Code
The generated client code follows our organization scheme. Each unique set of functionality, is given its own folder inside of `client/app/bundles`. This encourages for modularity of *domains*.

Inside of the generated "HelloWorld" domain you will find the following folders:

+  `startup`: two types of files, one that return a container component and implement any code that differs between client and server code (if using server-rendering), and a `clientRegistration` file that exposes the aforementioned files (as well as a `serverRegistration` file if using server rendering). These registration files are what webpack is using as an entry point.
+ `containers`: "smart components" (components that have functionality and logic that is passed to child "dumb components").
+ `components`: includes "dumb components", or components that simply render their properties and call functions given to them as properties by a parent component. Ultimately, at least one of these dumb components will have a parent container component.

You may also notice the `app/lib` folder. This is for any code that is common between bundles and therefore needs to be shared (for example, middleware).

### Redux
If you have used the `--redux` generator option, you will notice the familiar additional redux folders in addition to the aforementioned folders. The Hello World example has also been modified to use Redux.

Note the organizational paradigm of "bundles". These are like application domains and are used for grouping your code into webpack bundles, in case you decide to create different bundles for deployment. This is also useful for separating out logical parts of your application. The concept is that each bundle will have it's own Redux store. If you have code that you want to reuse across bundles, including components and reducers, place them under `/client/app/lib`.

### Using Images and Fonts
The generator has amended the folders created in `client/assets/` to Rails's asset path. We recommend that if you have any existing assets that you want to use with your client code, you should move them to these folders and use webpack as normal. This allows webpack's development server to have access to your assets, as it will not be able to see any assets in the default Rails directories which are above the `/client` directory.

Alternatively, if you have many existing assets and don't wish to move them, you could consider creating symlinks from client/assets that point to your Rails assets folders inside of `app/assets/`. The assets there will then be visible to both Rails and webpack.

### Bootstrap Integration
React on Rails ships with Twitter Bootstrap already integrated into the build. Note that the generator removes `require_tree` in both the application.js and application.css.scss files. This is to ensure the correct load order for the bootstrap integration, and is usually a good idea in general. You will therefore need to explicitly require your files.

How the Bootstrap library is loaded depends upon whether one is using the Rails server or the HMR development server.

#### Bootstrap via Rails Server
In the former case, the Rails server loads `bootstrap-sprockets`, provided by the `bootstrap-sass` ruby gem (added automatically to your Gemfile by the generator) via the `app/assets/stylesheets/_bootstrap-custom.scss` partial.

This allows for using Bootstrap in your regular Rails stylesheets. If you wish to customize any of the Bootstrap variables, you can do so via the `client/assets/stylesheets/_pre-bootstrap.scss` partial.

#### Bootstrap via Webpack HMR Dev Server
When using the webpack dev server, which does not go through Rails, bootstrap is loaded via the [bootstrap-sass-loader](https://github.com/shakacode/bootstrap-sass-loader) which uses the `client/bootstrap-sass-config.js` file.

#### Keeping Custom Bootstrap Configurations Synced
Because the webpack dev server and Rails each load Bootstrap via a different file (explained in the two sections immediately above), any changes to the way components are loaded in one file must also be made to the other file in order to keep styling consistent between the two. For example, if an import is excluded in `_bootstrap-custom.scss`, the same import should be excluded in `bootstrap-sass-config.js` so that styling in the Rails server and the webpack dev server will be the same.

#### Skip Bootstrap Integration
Bootstrap integration is enabled by default, but can be disabled by passing the `--skip-bootstrap` flag (alias `-b`). When you don't need Bootstrap in your existing project, just skip it as needed.

### Linters
The React on Rails generator can add linters and their recommended accompanying configurations to your project. There are two classes of linters: ruby linters and JavaScript linters.

##### JavaScript Linters
JavaScript linters are **enabled by default**, but can be disabled by passing the `--skip-js-linters` flag (alias `j`) , and those that run in Node have been added to `client/package.json` under `devDependencies`.

##### Ruby Linters
Ruby linters are **disabled by default**, but can be enabled by passing the `--ruby-linters` flag when generating. These linters have been added to your Gemfile in addition to the appropriate Rake tasks.

We really love using all the linters! Give them a try.

#### Running the Linters
To run the linters (runs all linters you have installed, even if you installed both Ruby and Node):

```bash
rake lint
```

Run this command to see all the linters available

```bash
rake -T lint
```

**Here's the list:**
```bash
rake lint               # Runs all linters
rake lint:eslint        # eslint
rake lint:js            # JS Linting
rake lint:jscs          # jscs
rake lint:rubocop[fix]  # Run Rubocop lint in shell
rake lint:ruby          # Run ruby-lint as shell
rake lint:scss          # See docs for task 'scss_lint'
```
