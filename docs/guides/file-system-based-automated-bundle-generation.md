# File-System-Based Automated Bundle Generation

To use the automated bundle generation feature introduced in React on Rails v13.1.0, please upgrade to use [Shakapacker v6.5.1](https://github.com/shakacode/shakapacker/tree/v6.5.1) at least. If you are currently using webpacker, please follow the migration steps available [here](https://github.com/shakacode/shakapacker/blob/master/docs/v6_upgrade.md).

## Configuration

### Enable nested_entries for Shakapacker
To use the automated bundle generation feature, set `nested_entries: true` in the `webpacker.yml` file like this.
The generated files will go in a nested directory.

```yml
default:
  ...
  nested_entries: true
```

For more details, see [Configuration and Code](https://github.com/shakacode/shakapacker#configuration-and-code) section in [shakapacker](https://github.com/shakacode/shakapacker/).

### Configure Components Subdirectory
`components_subdirectory`  is the name of the matched directories containing components that will be automatically registered for use by the view helpers.
For example, configure `config/initializers/react_on_rails` to set the name for `components_subdirectory`.·

```rb
config.components_subdirectory = "ror_components"
```

Now all React components inside the directories called `ror_components` will automatically be registered for usage with [`react_component`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component) and [`react_component_hash`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component_hash) helper methods provided by React on Rails.

### Configure `auto_load_bundle` Option

For automated component registry, [`react_component`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component) and [`react_component_hash`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component_hash) view helper method tries to load generated bundle for component from the generated directory automatically per `auto_load_bundle` option. `auto_load_bundle` option in `config/initializers/react_on_rails` configures the default value that will be passed to component helpers. The default is `false`, and the parameter can be passed explicitly for each call.

You can change the value in `config/initializers/react_on_rails` by updating it as follows:

```rb
config.auto_load_bundle = true
```

### Update `.gitignore` file
React on Rails automatically generates pack files for components to be registered in the `packs/generated` directory. To avoid committing generated files into the version control system, please update `.gitignore` to have

```gitignore
# Generated React on Rails packs
app/javascript/packs/generated
```

*Note: the directory might be different depending on the `source_entry_path` in `config/webpacker.yml`.*

## Usage

### Basic usage

#### Background
If the `webpacker.yml` file is configured as instructed [here](https://github.com/shakacode/shakapacker#configuration-and-code), with the following configurations

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


Suppose, you want to use bundle splitting to minimize unnecessary javascript loaded on each page, you would put each of your components in the `packs` directory.
```
app/javascript:
  └── packs:               # sets up webpack entries
  │   └── FooComponentOne.jsx # Internally uses ReactOnRails.register
  │   └── BarComponentOne.jsx # Internally uses ReactOnRails.register
  │   └── BarComponentTwo.jsx # Internally uses ReactOnRails.register
  └── src:                 # any directory name is fine. Referenced files need to be under source_path
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

File-system-based automated pack generation simplifies this process with a new option for the view helpers. The steps to use it in this example are:

1. Remove parameters passed directly to `javascript_pack_tag` and `stylesheet_pack_tag`.
2. Remove parameters passed directly to `append_javascript_pack_tag` and `append_stylesheet_pack_tag`.

Your layout would now contain:

```erb
  <%= javascript_pack_tag %>
  <%= stylesheet_pack_tag %>
```

3. Create a directory structure as mentioned below:

```
app/javascript:
  └── packs
  └── src:
  │   └── Foo
  │   │ └── ...
  │   │ └── ror_components          # configured as `components_subdirectory`
  │   │   └── FooComponentOne.jsx
  │   └── Bar
  │   │ └── ...
  │   │ └── ror_components          # configured as `components_subdirectory`
  │   │   │ └── BarComponentOne.jsx
  │   │   │ └── BarComponentTwo.jsx
```

4. You no longer need to register these React components nor directly add their bundles. For example you can have a Rails view using three components:

```erb
    <%= react_component("FooComponentOne", {}, auto_load_bundle: true) %>
    <%= react_component("BarComponentOne", {}, auto_load_bundle: true) %>
    <%= react_component("BarComponentTwo", {}, auto_load_bundle: true) %>
```

If `FooComponentOne` uses multiple HTML strings for server rendering, the [`react_component_hash`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component_hash) view helper can be used on the Rails view, as illustrated below.

```erb
<% foo_component_one_data = react_component_hash("FooComponentOne",
                                             prerender: true,
                                             auto_load_bundle: true
                                             props: {}
                                          ) %>
<% content_for :title do %>
   <%= foo_component_one_data['title'] %>
<% end %>
<%= foo_component_one_data["componentHtml"] %>
```

The default value of the `auto_load_bundle` parameter can be specified by setting `config.auto_load_bundle` in `config/initializers/react_on_rails.rb` and thus removed from each call to `react_component`.

### Server Rendering and Client Rendering Components

If server rendering is enabled, the component will be registered for usage both in server and client rendering. In order to have separate definitions for client and server rendering, name the component files as `ComponentName.server.jsx` and `ComponentName.client.jsx`. The `ComponentName.server.jsx` file will be used for server rendering and the `ComponentName.client.jsx` file for client rendering. If you don't want the component rendered on the server, you should only have the `ComponentName.client.jsx` file.

*Note: If specifying separate definitions for client and server rendering, please make sure to delete the generalized `ComponentName.jsx` file.*

### Using Automated Bundle Generation Feature with already defined packs

To use the Automated Bundle Generation feature with already defined packs, `config/initializers/react_on_rails` should explicitly be configured with `config.auto_load_bundle = false` and you can explicitly pass `auto_load_bundle` option in [`react_component`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component) and  [`react_component_hash`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component_hash) for the components using this feature.


