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
```

It also creates `app/javascript/stylesheets/application.css`:

```css
@import 'tailwindcss';
```

The generated `HelloWorld.client.jsx` or `HelloWorld.client.tsx` imports that CSS
file and uses Tailwind utility classes. The shared `commonWebpackConfig.js`
template inserts `postcss-loader` after `css-loader` and configures
`@tailwindcss/postcss`, regardless of whether the project uses Webpack or Rspack.

## Server Rendering Without a Flash of Unstyled Content

The generated example keeps two pieces together:

1. `app/views/hello_world/index.html.erb` renders the component with
   `prerender: true`.
2. `app/views/layouts/react_on_rails_default.html.erb` keeps
   `<%= stylesheet_pack_tag %>` in the document head before
   `<%= javascript_pack_tag %>`.

When React on Rails auto-loads the generated component pack, it appends the
generated component stylesheet pack. In a production build, Shakapacker emits
that stylesheet as an extracted CSS `<link>` in the SSR HTML. Do not remove the
empty `stylesheet_pack_tag`; it is the placeholder React on Rails uses to insert
component CSS and avoid a Tailwind flash of unstyled content.

In development, CSS can be injected by the dev server instead of extracted as a
static link. Use a production build when validating the no-FOUC path.

## Adding Tailwind Manually

If you are not rerunning the generator, add the packages yourself:

```bash
pnpm add tailwindcss@^4.3.0 @tailwindcss/postcss@^4.3.0 postcss@^8.5.15 postcss-loader@^8.2.1
```

Then create a CSS entry, import it from your client component or client pack,
and add `postcss-loader` after `css-loader` in your shared bundler config:

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

Keep the SSR view prerendered and keep `stylesheet_pack_tag` in the layout head
so the generated component CSS can be emitted before the JavaScript runs.

Tailwind v3 projects should use Tailwind's v3 PostCSS setup instead of this v4
recipe.
