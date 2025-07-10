# File-System-Based Automated Bundle Generation

To use the automated bundle generation feature introduced in React on Rails v13.1.0, please upgrade to use [Shakapacker v6.5.1](https://github.com/shakacode/shakapacker/tree/v6.5.1) at least. If you are currently using Webpacker, please follow the migration steps available [v6 upgrade](https://github.com/shakacode/shakapacker/blob/master/docs/v6_upgrade.md). Then upgrade to Shakapacker 7 using [v7 upgrade](https://github.com/shakacode/shakapacker/blob/master/docs/v7_upgrade.md) guide.

## Configuration

### Enable nested_entries for Shakapacker

To use the automated bundle generation feature, set `nested_entries: true` in the `shakapacker.yml` file like this.
The generated files will go in a nested directory.

```yml
default:
  ...
  nested_entries: true
```

For more details, see [Configuration and Code](https://github.com/shakacode/shakapacker#configuration-and-code) section in [shakapacker](https://github.com/shakacode/shakapacker/).

### Configure Components Subdirectory

`components_subdirectory` is the name of the matched directories containing components that will be automatically registered for use by the view helpers.
For example, configure `config/initializers/react_on_rails` to set the name for `components_subdirectory`:

```rb
config.components_subdirectory = "ror_components"
```

Now all React components inside the directories called `ror_components` will automatically be registered for usage with [`react_component`](../api/view-helpers-api.md#react_component) and [`react_component_hash`](../api/view-helpers-api.md#react_component_hash) helper methods provided by React on Rails.

### Configure `auto_load_bundle` Option

For automated component registry, [`react_component`](../api/view-helpers-api.md#react_component) and [`react_component_hash`](../api/view-helpers-api.md#react_component_hash) view helper method tries to load generated bundle for component from the generated directory automatically per `auto_load_bundle` option. `auto_load_bundle` option in `config/initializers/react_on_rails` configures the default value that will be passed to component helpers. The default is `false`, and the parameter can be passed explicitly for each call.

You can change the value in `config/initializers/react_on_rails` by updating it as follows:

```rb
config.auto_load_bundle = true
```

### Location of generated files

Generated files will go to the following two directories:

- Pack files for entrypoint components will be generated in the `{Shakapacker.config.source_entry_path}/generated` directory.
- The interim server bundle file, which is only generated if you already have a server bundle entrypoint and have not set `make_generated_server_bundle_the_entrypoint` to `true`, will be generated in the `{Pathname(Shakapacker.config.source_entry_path).parent}/generated` directory.

### Update `.gitignore` file

To avoid committing generated files to your version control system, please update `.gitignore` to include:

```gitignore
# Generated React on Rails packs
**/generated/**
```

### Commit changes to server bundle entrypoint

If you already have an existing server bundle entrypoint and have not set `make_generated_server_bundle_the_entrypoint` to `true`, then pack generation will add an import statement to your existing server bundle entrypoint similar to:

```javascript
// import statement added by react_on_rails:generate_packs rake task
import './../generated/server-bundle-generated.js';
```

We recommend committing this import statement to your version control system.

## Usage

### Basic usage

#### Background

If the `shakapacker.yml` file is configured as instructed [here](https://github.com/shakacode/shakapacker#configuration-and-code), with the following configurations

```yml
default: &default
  source_path: app/javascript
  source_entry_path: packs
  public_root_path: public
  public_output_path: packs
  nested_entries: true
# And more
```

the directory structure will look like this

```
app/javascript:
  └── packs:               # sets up webpack entries
  │   └── application.js   # references FooComponentOne.jsx, BarComponentOne.jsx and BarComponentTwo.jsx in `../src`
  └── src:                 # any directory name is fine. Referenced files need to be under source_path
  │   └── Foo
  │   │   └── ...
  │   │   └── FooComponentOne.jsx
  │   └── Bar
  │   │   └── ...
  │   │   └── BarComponentOne.jsx
  │   │   └── BarComponentTwo.jsx
  └── stylesheets:
  │   └── my_styles.css
  └── images:
      └── logo.svg
```

Previously, many applications would use one pack (webpack entrypoint) for many components. In this example, the`application.js` file manually registers server components, `FooComponentOne`, `BarComponentOne` and `BarComponentTwo`.

```jsx
import ReactOnRails from 'react-on-rails';
import FooComponentOne from '../src/Foo/FooComponentOne';
import BarComponentOne from '../src/Foo/BarComponentOne';
import BarComponentTwo from '../src/Foo/BarComponentTwo';

ReactOnRails.register({ FooComponentOne, BarComponentOne, BarComponentTwo });
```

Your layout would contain:

```erb
  <%= javascript_pack_tag 'application' %>
  <%= stylesheet_pack_tag 'application' %>
```

Now suppose you want to use bundle splitting to minimize unnecessary javascript loaded on each page, you would put each of your components in the `packs` directory.

```text
app/javascript:
  └── packs:                   # sets up webpack entries
  │   └── FooComponentOne.jsx  # Internally uses ReactOnRails.register
  │   └── BarComponentOne.jsx  # Internally uses ReactOnRails.register
  │   └── BarComponentTwo.jsx  # Internally uses ReactOnRails.register
  └── src:                     # any directory name is fine. Referenced files need to be under source_path
  │   └── Foo
  │   │   └── ...
  │   └── Bar
  │   │   └── ...
  └── stylesheets:
  │   └── my_styles.css
  └── images:
      └── logo.svg
```

The tricky part is to figure out which bundles to load on any Rails view. [Shakapacker's `append_stylesheet_pack_tag` and `append_javascript_pack_tag` view helpers](https://github.com/shakacode/shakapacker#view-helper-append_javascript_pack_tag-and-append_stylesheet_pack_tag) enables Rails views to specify needed bundles for use by layout's call to `javascript_pack_tag` and `stylesheet_pack_tag`.

#### Solution

File-system-based automated pack generation simplifies this process with a new option for the view helpers.

For example, if you wanted to utilize our file-system based entrypoint generation for `FooComponentOne` and `BarComponentOne`, but not `BarComponentTwo` (for whatever reason), then...

1. Remove generated entrypoints from parameters passed directly to `javascript_pack_tag` and `stylesheet_pack_tag`.
2. Remove generated entrypoints from parameters passed directly to `append_javascript_pack_tag` and `append_stylesheet_pack_tag`.

   Your layout would now contain:

   ```erb
   <%= javascript_pack_tag('BarComponentTwo') %>
   <%= stylesheet_pack_tag('BarComponentTwo') %>
   ```

3. Create a directory structure where the components that you want to be auto-generated are within `ReactOnRails.configuration.components_subdirectory`, which should be a subdirectory of `Shakapacker.config.source_path`:

   ```text
   app/javascript:
     └── packs:
     │   └── BarComponentTwo.jsx  # Internally uses ReactOnRails.register
     └── src:
     │   └── Foo
     │   │ └── ...
     │   │ └── ror_components          # configured as `components_subdirectory`
     │   │   └── FooComponentOne.jsx
     │   └── Bar
     │   │ └── ...
     │   │ └── ror_components          # configured as `components_subdirectory`
     │   │   │ └── BarComponentOne.jsx
     │   │ └── something_else
     │   │   │ └── BarComponentTwo.jsx
   ```

   4. You no longer need to register the React components within the `ReactOnRails.configuration.components_subdirectory` nor directly add their bundles. For example, you can have a Rails view using three components:

      ```erb
      <% append_javascript_pack('BarComponentTwo') %>
      <%= react_component("FooComponentOne", {}, auto_load_bundle: true) %>
      <%= react_component("BarComponentOne", {}, auto_load_bundle: true) %>
      <%= react_component("BarComponentTwo", {}) %>
      ```

      If a component uses multiple HTML strings for server rendering, the [`react_component_hash`](../api/view-helpers-api.md#react_component_hash) view helper can be used on the Rails view, as illustrated below.

      ```erb
      <% foo_component_one_data = react_component_hash(
           "FooComponentOne",
           prerender: true,
           auto_load_bundle: true,
           props: {}
         )
      %>
      <% content_for :title do %>
        <%= foo_component_one_data["title"] %>
      <% end %>
      <%= foo_component_one_data["componentHtml"] %>
      ```

      The default value of the `auto_load_bundle` parameter can be specified by setting `config.auto_load_bundle` in `config/initializers/react_on_rails.rb` and thus removed from each call to `react_component`.

### Server Rendering and Client Rendering Components

If server rendering is enabled, the component will be registered for usage both in server and client rendering. To have separate definitions for client and server rendering, name the component files `ComponentName.server.jsx` and `ComponentName.client.jsx`. The `ComponentName.server.jsx` file will be used for server rendering and the `ComponentName.client.jsx` file for client rendering. If you don't want the component rendered on the server, you should only have the `ComponentName.client.jsx` file.

Once generated, all server entrypoints will be imported into a file named `[ReactOnRails.configuration.server_bundle_js_file]-generated.js`, which in turn will be imported into a source file named the same as `ReactOnRails.configuration.server_bundle_js_file`. If your server bundling logic is such that your server bundle source entrypoint is not named the same as your `ReactOnRails.configuration.server_bundle_js_file` and changing it would be difficult, please let us know.

> [!IMPORTANT]
> When specifying separate definitions for client and server rendering, you need to delete the generalized `ComponentName.jsx` file.

### Using Automated Bundle Generation Feature with already defined packs

As of version 13.3.4, bundles inside directories that match `config.components_subdirectory` will be automatically added as entrypoints, while bundles outside those directories need to be manually added to the `Shakapacker.config.source_entry_path` or Webpack's `entry` rules.
