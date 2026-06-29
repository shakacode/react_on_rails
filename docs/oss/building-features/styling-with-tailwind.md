# Styling with Tailwind CSS v4

React on Rails can generate a Tailwind CSS v4 setup for the server-rendered
HelloWorld example. The generator uses Tailwind's CSS-first setup, the
`@tailwindcss/postcss` plugin, and the same shared bundler template for Webpack
and Rspack.

## New Apps

For a fresh Rails app, pass `--tailwind` to `create-react-on-rails-app`:

```bash
npx create-react-on-rails-app my-app --tailwind
cd my-app
bin/rails db:prepare
bin/dev
```

The CLI forwards `--tailwind` to `rails generate react_on_rails:install`, so the
generated `/hello_world` page is server-rendered and styled by Tailwind CSS v4.

## Existing Apps

For an existing Rails app, pass the generator flag directly:

```bash
bundle exec rails generate react_on_rails:install --tailwind
```

The generator installs these published packages:

```bash
pnpm add tailwindcss@^4.3.0 @tailwindcss/postcss@^4.3.0 postcss@^8.5.15 postcss-loader@^8.2.1
npm install tailwindcss@^4.3.0 @tailwindcss/postcss@^4.3.0 postcss@^8.5.15 postcss-loader@^8.2.1
yarn add tailwindcss@^4.3.0 @tailwindcss/postcss@^4.3.0 postcss@^8.5.15 postcss-loader@^8.2.1
```

It also creates `app/javascript/stylesheets/application.css`:

<!-- prettier-ignore -->
```css
@import "tailwindcss" source("../..");
```

The generator also creates `app/javascript/packs/react_on_rails_tailwind.js`
to import the Tailwind stylesheet and declares that pack from
`app/views/layouts/react_on_rails_default.html.erb`:

```erb
<% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
<%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
<%= javascript_pack_tag %>
```

The generated `HelloWorld.client.jsx` or `HelloWorld.client.tsx` uses Tailwind
utility classes but does not import the global stylesheet. The shared
`commonWebpackConfig.js` template inserts `postcss-loader` after `css-loader`
and configures `@tailwindcss/postcss`, regardless of whether the project uses
Webpack or Rspack.

## Server Rendering Without a Flash of Unstyled Content

The generated example keeps three pieces together:

1. `app/views/hello_world/index.html.erb` renders the component with
   `prerender: true`.
2. `app/javascript/packs/react_on_rails_tailwind.js` imports the Tailwind
   stylesheet as an app-level pack.
3. `app/views/layouts/react_on_rails_default.html.erb` keeps
   `<%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>` before
   `<%= javascript_pack_tag %>`.

Tailwind is layout-owned because it is global app styling. The generated
components only reference Tailwind class names. Do not move the Tailwind CSS
import back into a generated component; pages that use Tailwind classes but do
not load that component would then depend on the wrong pack for global styles.

In development, CSS can be injected by the dev server instead of extracted as a
static link. Use a production build when validating the no-FOUC path.

## Adding Tailwind Manually

If you are not rerunning the generator, add the packages yourself:

```bash
pnpm add tailwindcss@^4.3.0 @tailwindcss/postcss@^4.3.0 postcss@^8.5.15 postcss-loader@^8.2.1
npm install tailwindcss@^4.3.0 @tailwindcss/postcss@^4.3.0 postcss@^8.5.15 postcss-loader@^8.2.1
yarn add tailwindcss@^4.3.0 @tailwindcss/postcss@^4.3.0 postcss@^8.5.15 postcss-loader@^8.2.1
```

Then create a CSS entry, import it from an app-level client pack that your
layout declares, and add `postcss-loader` after `css-loader` in your shared
bundler config:

```javascript
{
  loader: 'postcss-loader',
  options: {
    postcssOptions: {
      plugins: [require('@tailwindcss/postcss')],
    },
  },
}
```

Keep the SSR view prerendered and keep the Tailwind stylesheet pack tag in the
layout head so the app-level Tailwind CSS can be emitted before the JavaScript
runs when Shakapacker is configured to emit stylesheet links.

Tailwind v3 projects should use Tailwind's v3 PostCSS setup instead of this v4
recipe.
