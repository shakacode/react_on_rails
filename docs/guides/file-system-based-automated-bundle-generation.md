# File-System-Based Automated Bundle Generation

To use the automated bundle generation feature introduced in React on Rails v13.1.0, please upgrade to use [Shakapacker v6.5.0](https://github.com/shakacode/shakapacker/tree/v6.5.0) at least. If you are currently using webpacker, please follow the migration steps available [here](https://github.com/shakacode/shakapacker/blob/master/docs/v6_upgrade.md).

## Configuration

### Enable nested_entries for Shakapacker
To use the automated bundle generation feature, in the `webpacker.yml` file, set 

```yml
default:
  ...
  nested_entries: true
```

For more details, see [Configuration and Code](https://github.com/shakacode/shakapacker#configuration-and-code) section in [shakapacker](https://github.com/shakacode/shakapacker/).

### Configure Components Directory
`components_directory` is the directories containing components that can be automatically registered and used in Rails views.
Configure `config/initializers/react_on_rails`
to set the name for `components_directory`. 

```rb
config.components_directory = "ror_components"
```

Now all React components inside the directories called `ror_components` will automatically be registered for usage with [`react_component`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component) and [`react_component_hash`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component_hash) helper methods provided by React on Rails.

### Configure `auto_load_bundle` Option

For automated component registry, [`react_component`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component) and [`react_component_hash`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component_hash) view helper method tries to load generated bundle for component from the generated directory automatically per `auto_load_bundle` option. `auto_load_bundle` option in `config/initializers/react_on_rails` configures the default value that will be passed to component helpers. The default is `false`, and the parameter can be passed explicitly for each call.

*Note: Starting from React on Rails version 14.0.0, the default value for the `auto_load_bundle` option will be `true`.*

You can change the value in `config/initializers/react_on_rails` by updating it as follows:

```rb
config.auto_load_bundle = true
```

### Update `.gitignore` file
React on Rails automatically generates pack files for components to be registered in the `packs/generated` directory. To avoid committing generated files into the version control system, please update `.gitignore` to have 

```gitignore
### Generated React on Rails packs
packs/generated
```

*Note: the directory might be different depending on the `source_entry_path` in `config/webpacker.yml`.*

## Usage

### Basic usage

if the `webpacker.yml` file is configured as instructed [here](https://github.com/shakacode/shakapacker#configuration-and-code), with the following configurations

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
  │   └── application.js   # references ../src/my_component.js
  │   └── application.css
  └── src:                 # any directory name is fine. Referenced files need to be under source_path
  │   └── component.js
  └── stylesheets:
  │   └── my_styles.css
  └── images:
      └── logo.svg
```

Now, to automatically register `FooComponentOne`, `BarComponentOne` and `BarComponentTwo` for the usage with [`react_component`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component) and [`react_component_hash`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component_hash) helpers, create a directory structure as mentioned below:

```
app/javascript:
  └── packs:                   
  │   └── application.js     
  │   └── application.css
  └── src:                   
  │   └── Foo
  │   │ └── ...
  │   │ └── ror_components          # configured as `components_directory`
  │   │   └── FooComponentOne.jsx
  │   └── Bar
  │   │ └── ror_components          # configured as `components_directory`
  │   │   │ └── BarComponentOne.jsx
  │   │   │ └── BarComponentTwo.jsx       
```

To register a React component, creating a pack entry and manually registering it by calling `ReactOnRails.register` is no longer needed. With automatically generated packs, you can directly use `FooComponentOne`, `BarComponentOne` and `BarComponentTwo` in Rails view using:

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

the default value of the `auto_load_bundle` parameter can be specified by setting `config.auto_load_bundle` in `config/initializers/react_on_rails.rb`.

### Server Rendering and Client Rendering Components

If server rendering is enabled, the component will be registered for usage both in server and client rendering. In order to have separate definitions for client and server rendering, name the component files as `Component_Name.server.jsx` and `Component_Name.client.jsx`. The `Component_Name.server.jsx` file will be used for server rendering and the `Component_Name.client.jsx` file for client rendering. If you don't want the component rendered on the server, you should only have the `Component_Name.client.jsx` file.

*Note: If specifying separate definitions for client and server rendering, please make sure to delete the generalized `Component_Name.jsx` file.*

### Using Automated Bundle Generation Feature with already defined packs

To use the Automated Bundle Generation feature with already defined packs, `config/initializers/react_on_rails` should explicitly be configured with `config.auto_load_bundle = false` and you can explicitly pass `auto_load_bundle` option in [`react_component`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component) and  [`react_component_hash`](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/#react_component_hash) for the components using this feature.


