# CSS and Styling with React Server Components

This page documents how CSS moves through React on Rails Pro when an app uses React Server Components
(RSC), regular React on Rails client components, server-side rendering (SSR), and Shakapacker asset tags.

## Short recommendation

Use the normal Shakapacker CSS pipeline for styles that must apply to server-rendered markup. Put global,
Tailwind, design-system, and server-component-only styles in a stylesheet loaded from the Rails layout.
Use CSS Modules or component-scoped CSS imports behind a `'use client'` boundary when the styled markup is a
Client Component or a dependency of a Client Component.

Do not rely on CSS imported only by a Server Component to create a browser stylesheet. With the generated RSC
configs, the server and RSC bundles do not extract CSS. Server-only CSS imports may let the server render class
names, but they do not cause React on Rails to emit a stylesheet link for the browser.

## Investigation note

React on Rails Pro builds three graphs for an RSC app:

| Graph         | Runtime                           | CSS behavior                                                                                                                                                      |
| ------------- | --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Client bundle | Browser                           | CSS is extracted or injected by the normal Shakapacker client pipeline. The RSC manifest plugin records CSS files for `'use client'` references.                  |
| Server bundle | Node renderer VM for SSR          | CSS extraction plugins and style injection loaders are removed. CSS Modules are configured with `exportOnlyLocals`, so SSR can render class names without CSS IO. |
| RSC bundle    | Node renderer VM for RSC payloads | Uses the server bundle config plus the RSC loader. It transforms `'use client'` modules into client references and does not extract browser CSS.                  |

That split means CSS can reach the browser through two supported paths:

1. Rails renders Shakapacker stylesheet tags. This is the normal React on Rails path for global CSS,
   component bundles loaded by `auto_load_bundle`, and manually loaded packs.
2. The RSC renderer reads stylesheet hrefs from `react-client-manifest.json` for `'use client'` references
   and emits React 19 stylesheet links into the RSC stream. React hoists and dedupes those links so CSS for
   Client Components inside an RSC page can load before the component paints.

Verified in this repository:

- The current RSC rendering-flow docs state that the client bundle extracts CSS, the server bundle uses
  CSS Modules locals only, and the RSC bundle does not extract CSS.
- The Pro dummy app has a request spec that checks `react-client-manifest.json` records CSS for a
  `'use client'` component rendered by an RSC page.
- The Pro dummy app has a Playwright regression test for that same path: a CSS Module imported by a
  `'use client'` component in an RSC tree is preloaded or linked before the styled probe paints.
- The React on Rails helper still loads generated component packs by appending both
  `generated/<ComponentName>` JavaScript and stylesheet pack tags when `auto_load_bundle` is enabled.

Assumptions not proven by this docs-only pass:

- Plain non-module CSS imported behind a `'use client'` boundary should follow the same manifest stylesheet
  path as CSS Modules, but the checked regression fixture uses an SCSS module.
- Static CSS extraction libraries such as Vanilla Extract, Linaria, Panda CSS, and Compiled should work when
  their generated CSS is included in the client or global stylesheet pipeline, but this page does not add
  fixtures for those packages.
- styled-components has recent React 19 and RSC compatibility fixes. React on Rails Pro has not verified that
  integration end to end in this repository.

## Where to import CSS

### Server Components

Server Components render in the RSC bundle. Generated server bundles may import top-level Server Component
modules for registration, but neither the server nor RSC bundle extracts browser CSS. Importing a CSS file only
from a Server Component does not make React on Rails render a browser stylesheet for it.

Recommended pattern:

```tsx
// app/javascript/components/ProductSummary.tsx
// No 'use client'. This is a Server Component.
export default function ProductSummary({ product }) {
  return (
    <article className="product-summary">
      <h2>{product.name}</h2>
      <p>{product.description}</p>
    </article>
  );
}
```

```css
/* app/javascript/styles/application.css */
.product-summary {
  display: grid;
  gap: 0.5rem;
}
```

```ts
// app/javascript/packs/client-bundle.ts
import '../styles/application.css';
```

The class name is server-rendered by the RSC component, and the stylesheet is loaded by the Rails layout as a
normal Shakapacker asset.

### Client Components inside an RSC tree

If the markup is interactive or the style should be component-scoped, put the CSS import behind the client
boundary:

```tsx
// app/javascript/components/FavoriteButton.tsx
'use client';

import styles from './FavoriteButton.module.scss';

export default function FavoriteButton({ active }) {
  return (
    <button className={active ? styles.activeButton : styles.button} type="button">
      Favorite
    </button>
  );
}
```

```tsx
// app/javascript/components/ProductPage.tsx
import FavoriteButton from './FavoriteButton';

export default async function ProductPage({ product }) {
  return (
    <section>
      <h1>{product.name}</h1>
      <FavoriteButton active={product.favorite} />
    </section>
  );
}
```

The RSC bundle turns `FavoriteButton` into a client reference. The client build extracts the CSS, the RSC
client manifest records the CSS href, and the RSC stream emits stylesheet links for the browser.

### Shared components

A module can be evaluated as a Server Component in one import path and as part of the client graph in another
import path. React's `'use client'` directive marks a module dependency subtree, not a render-tree subtree.

For shared view components:

- Use global classes from a layout-loaded stylesheet if the component can render directly as a Server
  Component.
- Import CSS Modules from a wrapper that starts with `'use client'` if the component needs component-scoped
  CSS and will render as a Client Component.
- Avoid hidden CSS side effects in shared utility modules. They make it hard to know whether the CSS is
  emitted by the client bundle, ignored by the server/RSC bundle, or duplicated in several packs.

## React on Rails asset rendering

For manually loaded packs, render the stylesheet pack in the Rails layout or view:

```erb
<%= stylesheet_pack_tag "client-bundle", media: "all" %>
<%= javascript_pack_tag "client-bundle", defer: true %>
```

For generated packs with `auto_load_bundle: true`, keep empty Shakapacker tag placeholders in the layout.
React on Rails appends generated component pack names while rendering the view:

```erb
<%= stylesheet_pack_tag media: "all" %>
<%= javascript_pack_tag defer: true %>
```

When SSR and `auto_load_bundle` are both used, render the body into `content_for` before the `<head>` so the
append calls run before `stylesheet_pack_tag` emits the head links:

```erb
<% content_for :body_content do %>
  <%= yield %>
<% end %>

<!DOCTYPE html>
<html>
  <head>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%# Global app CSS pack, if you have one. %>
    <%= stylesheet_pack_tag "client-bundle", media: "all" %>

    <%# Auto-loaded generated component CSS. %>
    <%= stylesheet_pack_tag media: "all" %>
  </head>
  <body>
    <%= yield :body_content %>

    <%= javascript_pack_tag "client-bundle", defer: true %>
    <%= javascript_pack_tag defer: true %>
  </body>
</html>
```

For RSC pages rendered by `stream_react_component`, CSS for client references in the RSC payload is handled by
the Pro RSC renderer. It uses the manifest stylesheet hrefs and React 19 stylesheet hoisting. Keep the normal
Rails stylesheet tags anyway for global CSS, generated component packs, and non-RSC React on Rails components.

## Development versus production

Production and CI builds should be treated as the source of truth for CSS ordering. Production extracts CSS
into files and writes manifests. Development HMR may inject CSS from JavaScript or serve assets from the dev
server, so it can hide or create FOUC that is unrelated to the production path.

Use a production-like local check before declaring a CSS setup safe:

```bash
RAILS_ENV=production NODE_ENV=production CLIENT_BUNDLE_ONLY=true bin/shakapacker
RAILS_ENV=production NODE_ENV=production SERVER_BUNDLE_ONLY=true bin/shakapacker
RAILS_ENV=production NODE_ENV=production RSC_BUNDLE_ONLY=true bin/shakapacker
```

Then inspect:

- `public/<public_output_path>/manifest.json` for regular Shakapacker assets.
- `public/<public_output_path>/react-client-manifest.json` for client reference CSS arrays.
- The server-rendered HTML for `<link rel="stylesheet">` or React stylesheet preload/bootstrap hints before
  the styled RSC client boundary.

## Recommended setup

### 1. Keep a layout-loaded stylesheet for server-rendered HTML

Use this for design tokens, resets, Tailwind utilities, CSS variables, and classes used by Server Components:

```ts
// app/javascript/packs/client-bundle.ts
import '../styles/application.css';
```

```erb
<%= stylesheet_pack_tag "client-bundle", media: "all" %>
```

### 2. Put component-scoped imports behind `'use client'`

Use CSS Modules, SCSS modules, or plain CSS imports from the Client Component that owns the styled markup.
This keeps the CSS in the client graph so RSC can discover the stylesheet href from the client manifest.

### 3. Use Tailwind as global/static CSS

For new Tailwind CSS v4 apps, use the current PostCSS plugin and import Tailwind from the app stylesheet:

```js
// postcss.config.mjs
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

```css
/* app/javascript/styles/application.css */
@import 'tailwindcss';
```

For existing Tailwind CSS v3 apps, keep the older PostCSS shape and make sure Rails views plus RSC/client
component files are included in `content`:

```js
// config/tailwind.config.js
module.exports = {
  content: ['./app/views/**/*.{erb,haml,slim}', './app/javascript/**/*.{js,jsx,ts,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
};
```

```js
// postcss.config.js
const tailwindcss = require('tailwindcss');
const autoprefixer = require('autoprefixer');

module.exports = {
  plugins: [tailwindcss('./config/tailwind.config.js'), autoprefixer],
};
```

### 4. Prefer static CSS extraction for server-heavy surfaces

Static extraction libraries are the best fit when you want authored-in-JS styles but also want server-heavy
RSC pages. Configure the package so CSS is emitted into a stylesheet that Shakapacker can extract and Rails can
serve.

Example shape for Vanilla Extract:

```js
// config/webpack/commonWebpackConfig.js
const { VanillaExtractPlugin } = require('@vanilla-extract/webpack-plugin');
const { generateWebpackConfig, merge } = require('shakapacker');

const baseConfig = generateWebpackConfig();

module.exports = () =>
  merge({}, baseConfig, {
    plugins: [new VanillaExtractPlugin()],
  });
```

```tsx
// app/javascript/components/productCard.css.ts
import { style } from '@vanilla-extract/css';

export const card = style({
  display: 'grid',
  gap: '0.75rem',
});
```

```tsx
// app/javascript/components/ProductCard.tsx
import { card } from './productCard.css';

export default function ProductCard({ product }) {
  return <article className={card}>{product.name}</article>;
}
```

If `ProductCard` stays a Server Component, also import the extracted style module from a browser-loaded pack so
the CSS is emitted for Rails to serve:

```ts
// app/javascript/packs/client-bundle.ts
import '../components/productCard.css';
import '../styles/application.css';
```

Treat this as a starting point. Confirm the package's webpack/Rspack plugin supports the bundler you use and
then verify the emitted CSS in your client assets. If the styled component is a Client Component instead, keep
the style import behind that `'use client'` boundary and verify the CSS appears in `react-client-manifest.json`.

### 5. Treat runtime CSS-in-JS as package-specific

Runtime CSS-in-JS libraries are no longer one category:

- styled-components v6.3.x has React 19 and RSC compatibility fixes. Use CSS custom properties for theming in
  Server Components, and verify the exact version with React on Rails Pro before relying on it in production.
- Emotion still documents SSR style collection and hydration paths, but this repo has not verified Emotion in
  RSC Server Components. Keep Emotion-heavy UI behind `'use client'` boundaries unless you add an app-specific
  SSR/RSC integration test.
- Component libraries based on Emotion, styled-components, or another runtime styling layer should be treated
  like third-party client-feature packages unless their RSC support is documented and verified in your app.

## Compatibility matrix

Status key:

- **Verified**: covered by current repo code, docs, or tests.
- **Assumed**: expected from current repo behavior or package docs, but not exercised by a React on Rails Pro
  fixture in this docs-only pass.
- **Unsupported**: does not fit the current generated RSC/server CSS pipeline.
- **Unknown**: needs a fixture or package-specific investigation before recommendation.

| Approach/package                                         | RSC compatibility                                                                   | Client Component compatibility                                   | SSR compatibility                                                    | Required config                                                                  | Limitations                                                                                      | Status                                                               |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| Global CSS imported by a layout pack                     | Works for Server Components because classes render in HTML and CSS loads globally.  | Works.                                                           | Works when the stylesheet tag is in `<head>`.                        | Import CSS from a client/layout pack and render `stylesheet_pack_tag`.           | Not component-scoped. Ordering depends on layout/tag order.                                      | Verified from React on Rails paths.                                  |
| CSS Modules or SCSS Modules in `'use client'` components | Works. RSC records client-reference CSS in the manifest and emits stylesheet links. | Works.                                                           | Works: server bundle renders locals, client stylesheet supplies CSS. | Shakapacker CSS Modules/SCSS config; current RSC manifest plugin.                | Manifest-wide CSS links can over-include CSS for client refs not rendered on a specific request. | Verified by Pro dummy specs.                                         |
| CSS imported only by Server Components                   | Not supported as a browser stylesheet path.                                         | Not applicable unless also imported by client graph.             | Server may render class names, but CSS is not emitted.               | Move CSS to global/layout pack or a `'use client'` boundary.                     | Easy to ship unstyled HTML. CSS Modules locals alone are not enough.                             | Unsupported by current configs.                                      |
| Sass/SCSS through Shakapacker                            | Works when emitted through global packs or `'use client'` components.               | Works.                                                           | Works with the normal SSR CSS locals pattern.                        | `sass`, `sass-loader`, existing Shakapacker rules.                               | Direct server-only imports have the same limitation as CSS imports.                              | Verified for SCSS Modules in RSC client boundary; otherwise assumed. |
| PostCSS/Tailwind CSS                                     | Works best as global/static CSS loaded from the layout.                             | Works with class names in client components.                     | Works when compiled CSS is present before paint.                     | Tailwind/PostCSS config; include Rails views and JS/TS component files.          | Dynamic class names must be safelisted or statically discoverable.                               | Assumed; repo dummy uses Tailwind v3 globally.                       |
| `clsx`, `classnames`, CVA                                | Works because they only compose class strings.                                      | Works.                                                           | Works.                                                               | None beyond making sure the referenced classes exist in loaded CSS.              | They do not emit CSS; pair with Tailwind, global CSS, CSS Modules, or extracted CSS.             | Assumed; low risk.                                                   |
| Vanilla Extract                                          | Expected to work when its build plugin emits CSS through Shakapacker.               | Works when CSS assets are extracted.                             | Expected to work because class names are static.                     | `@vanilla-extract/webpack-plugin` or bundler equivalent.                         | Not verified with React on Rails Pro RSC; confirm Rspack support separately if using Rspack.     | Assumed.                                                             |
| Linaria                                                  | Expected to work when extracted CSS is included in the client/global CSS pipeline.  | Works after loader/Babel setup.                                  | Expected to work because styles are static CSS.                      | Linaria/WyW Babel preset plus `@wyw-in-js/webpack-loader` and CSS extraction.    | Runtime dynamic styles are limited to supported static-extraction patterns.                      | Assumed.                                                             |
| Panda CSS                                                | Expected to work as generated static CSS.                                           | Works when generated classes and CSS are included.               | Expected to work because output is static CSS.                       | Panda CLI or PostCSS setup; import generated CSS in a layout/client pack.        | Classes must be discoverable by Panda's scanner or generated via recipes/config.                 | Assumed.                                                             |
| Compiled CSS-in-JS                                       | Expected to work with extraction and normal CSS imports.                            | Works when the webpack loader or package CSS import is handled.  | Expected to work when CSS is extracted before paint.                 | `@compiled/webpack-loader` and CSS extraction rules, or package-specific setup.  | Ordering can be package-specific; verify any Atlassian/component-library migration path.         | Assumed.                                                             |
| styled-components v6.3.x                                 | Has React 19/RSC compatibility fixes; Server Component styling is unverified here.  | Works in Client Components.                                      | Package-specific; use documented Babel/SWC/plugin guidance.          | Recent styled-components version; optional tooling for class names.              | Not verified in this repo. Context theming is not available in Server Components; use CSS vars.  | Unknown for React on Rails Pro.                                      |
| Emotion                                                  | Keep behind `'use client'` unless you build and test an RSC integration.            | Works in Client Components.                                      | Requires Emotion SSR/cache/hydration setup for traditional SSR.      | Emotion SSR extraction/cache setup; React on Rails integration code.             | Runtime style insertion and context/cache providers need package-specific SSR/RSC handling.      | Unknown for RSC; assumed for client-only.                            |
| Runtime-styled component libraries                       | Treat as Client Components unless the library documents RSC support.                | Works behind `'use client'` if browser/client requirements hold. | Depends on the library's SSR support.                                | Library-specific providers, style collectors, Babel/SWC plugins, or CSS imports. | May force large client boundaries; can cause FOUC or hydration issues without tested SSR setup.  | Unknown.                                                             |

## Known limitations

- RSC stylesheet links are derived from the client manifest, not from the exact client references rendered by
  one request. This favors no-FOUC behavior over perfectly minimal per-request CSS.
- Older `react-client-manifest.json` files without CSS arrays cannot produce RSC stylesheet links. Rebuild all
  three bundles after upgrading `react-on-rails-rsc`.
- If a component's first styled usage is in the browser after an `RSCRoute` client-side navigation, the RSC
  payload still needs the stylesheet links. Verify that path separately for route-heavy apps.
- Rspack support exists, but check the Rspack compatibility page and verify CSS extraction for any package that
  relies on webpack-only plugins.
- This page intentionally does not include package fixtures or regression tests for Tailwind, Vanilla Extract,
  Linaria, Panda, Compiled, styled-components, Emotion, or component-library styling systems.

## Reference topics checked

- React Server Components and the `'use client'` directive
- Tailwind CSS PostCSS installation
- webpack css-loader behavior
- Vanilla Extract webpack integration
- Linaria bundler integration
- Panda CSS generated CSS setup
- Compiled CSS-in-JS installation
- styled-components React 19 and RSC notes
- Emotion SSR setup
