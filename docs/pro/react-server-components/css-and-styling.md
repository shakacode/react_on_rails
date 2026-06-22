# CSS and Styling with React Server Components

This guide documents how CSS works across Server Components, Client Components, and traditional SSR in
React on Rails Pro. It covers the three-bundle CSS architecture, the FOUC prevention pipeline, and
per-approach setup guidance for every major CSS strategy.

## Quick reference

| Approach                                                      | Server Component                           | Client Component (RSC)      | Traditional SSR      | FOUC prevention          |
| ------------------------------------------------------------- | ------------------------------------------ | --------------------------- | -------------------- | ------------------------ |
| [Global CSS](#global-css)                                     | Use class names; CSS loads from layout     | Works                       | Works                | Rails layout `<link>`    |
| [CSS Modules](#css-modules)                                   | `exportOnlyLocals` renders class names     | Full extraction + chunk CSS | Full extraction      | RSC client-chunk links   |
| [SCSS Modules](#sassscss)                                     | Same as CSS Modules                        | Same as CSS Modules         | Same as CSS Modules  | RSC client-chunk links   |
| [Tailwind CSS](#tailwind-css)                                 | Use utility classes; CSS loads from layout | Use utility classes         | Use utility classes  | Rails layout `<link>`    |
| [Inline styles](#inline-styles)                               | Works (serialized in RSC payload)          | Works                       | Works                | N/A (no external CSS)    |
| [Vanilla Extract](#vanilla-extract)                           | Needs client-boundary wrapper              | Works with build plugin     | Works                | RSC client-chunk links   |
| [styled-components](#styled-components)                       | Not supported                              | Works behind `'use client'` | Works with SSR setup | None (runtime injection) |
| [Emotion](#emotion)                                           | Not supported                              | Works behind `'use client'` | Works with SSR setup | None (runtime injection) |
| [Other static extraction](#other-static-extraction-libraries) | Expected to work via layout CSS            | Expected to work            | Expected to work     | Depends on setup         |

Status: entries marked with specific verification notes below. See the [full compatibility matrix](#compatibility-matrix) for details.

## How CSS reaches the browser

CSS can reach the browser through two paths. Understanding both is essential for avoiding
Flash of Unstyled Content (FOUC).

### Path 1: Rails layout stylesheet tags

The standard React on Rails path. Global CSS, Tailwind utilities, and design tokens are imported from the
client pack and loaded via `stylesheet_pack_tag` in the Rails layout `<head>`:

```erb
<%= stylesheet_pack_tag "client-bundle", media: "all" %>
```

This works for all rendering modes because Rails always renders the layout HTML around the component.

### Path 2: RSC client-chunk stylesheet injection

For CSS imported by `'use client'` components inside an RSC tree, React on Rails Pro has a dedicated
FOUC prevention pipeline:

1. **Build time:** The RSC manifest identifies client references, while the client build records emitted
   `clientN` chunk assets in `loadable-stats.json`. React on Rails Pro uses those stats to map each
   RSC client chunk name to its extracted CSS files.

2. **Render time:** When the node renderer streams Flight data, `injectRSCPayload` scans the current
   payload for the client chunk names referenced by rendered client references. It injects only CSS
   hrefs for those chunk names, deduplicating hrefs across the stream.

3. **Stream injection:** `injectRSCPayload` emits
   `<link rel="stylesheet" href="..." data-precedence="rsc-css">` elements before the streamed reveal
   HTML that needs those client chunks.

4. **Browser behavior:** React 19 hoists `<link rel="stylesheet" data-precedence="...">` elements
   into `<head>`, deduplicates them across the RSC stream, and blocks tree commit until the
   stylesheets load. This prevents the styled Client Component from painting before its CSS is
   available.

> [!NOTE]
> RSC CSS collection is request/chunk driven, not a blanket scan of every client reference in the
> manifest. The injected CSS can still be broader than a single component when a rendered client chunk
> contains shared, vendor, or page-specific global CSS. Keep client boundaries thin so the chunks
> referenced by a page do not drag unrelated CSS into the render-blocking `rsc-css` group.

> [!CAUTION]
> These stylesheet links are render-blocking. Broad `'use client'` entry points that import
> page-specific global CSS can make unrelated RSC pages wait on that CSS even when they do not
> visually need it. Prefer thin client wrappers, CSS Modules, Tailwind utilities, or layout-level
> global CSS for styles that are truly shared across pages.
>
> Contaminated global CSS can also win source-order ties if React hoists the RSC stylesheet links
> after earlier Rails layout styles. Avoid bare element selectors in component stylesheets; if app
> globals must override framework CSS, make that specificity explicit in the app's global stylesheet.

### What this means for different CSS approaches

- **Build-time CSS** (CSS Modules, SCSS, Tailwind, Vanilla Extract) is extracted into files by
  the client bundle. If the import is behind `'use client'`, the extracted CSS file appears in
  `react-client-manifest.json` and gets FOUC prevention. If the import is in a global/layout pack,
  FOUC prevention comes from the Rails layout `<link>` tag.

- **Runtime CSS-in-JS** (styled-components, Emotion) injects CSS via `<style>` tags at runtime.
  Their CSS is **not** in extracted files and **not** in `react-client-manifest.json`. There is no
  FOUC prevention from the manifest pipeline for these approaches.

- **Inline styles** (`style` prop) are serialized directly in the HTML or RSC payload. No external
  CSS file is needed, so FOUC is not a concern.

## Three-bundle CSS architecture

React on Rails Pro builds three webpack/Rspack graphs for an RSC app. Each handles CSS differently:

| Bundle           | Runtime          | CSS handling                                                                                                                                                                                          |
| ---------------- | ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Client**       | Browser          | CSS is extracted by `MiniCssExtractPlugin` (webpack) or Rspack's built-in CSS extraction. The RSC manifest plugin records CSS files for each `'use client'` module.                                   |
| **Server** (SSR) | Node renderer VM | CSS extraction is disabled. CSS Modules use `exportOnlyLocals: true` in `css-loader`, which emits only the class-name-to-hash mapping without any CSS output. Plain CSS imports become empty modules. |
| **RSC**          | Node renderer VM | Same CSS handling as the server bundle, plus the RSC loader transforms `'use client'` modules into client references. No browser CSS is extracted.                                                    |

The key insight: **only the client bundle produces browser-loadable CSS**. The server and RSC bundles
need just enough CSS processing to render correct class names during SSR, but they never emit
stylesheets.

> [!NOTE]
> `sass-loader` and `postcss-loader` still run in the server and RSC bundles because `css-loader`
> needs valid CSS input to parse class names from CSS Modules. This means SCSS compilation and
> PostCSS processing (including Tailwind) run in all three builds, but only the client build
> produces CSS output.

## Where to import CSS

### Server Components

Server Components render in the RSC bundle, which does not extract CSS. Importing a CSS file only from
a Server Component does not produce a browser stylesheet.

**Recommended pattern:** Use class names from a globally loaded stylesheet (Tailwind utilities, global
CSS, or design tokens imported in the client pack):

```tsx
// app/javascript/components/ProductSummary.tsx (Server Component)
type Product = { name: string; description: string };

export default function ProductSummary({ product }: { product: Product }) {
  return (
    <article className="product-summary">
      <h2>{product.name}</h2>
      <p>{product.description}</p>
    </article>
  );
}
```

```css
/* app/javascript/styles/application.css — imported by client-bundle.ts */
.product-summary {
  display: grid;
  gap: 0.5rem;
}
```

The class name is server-rendered by the RSC component. The CSS loads from the Rails layout's
`stylesheet_pack_tag`.

**CSS Modules in Server Components** are a special case. The server and RSC bundles process CSS Modules
with `exportOnlyLocals`, which means the `import styles from './Foo.module.css'` statement works and
returns the class name mapping. The server renders the hashed class names. However, the actual CSS rules
are only extracted by the client bundle, so the component's CSS file must also be imported somewhere
in the client graph (typically by a `'use client'` component that uses the same module, or by
including it in the global stylesheet).

### Client Components inside an RSC tree

Put CSS imports behind the `'use client'` boundary. This keeps the CSS in the client graph, where it is
extracted into a file and recorded in the RSC manifest:

```tsx
// app/javascript/components/FavoriteButton.tsx
'use client';

import styles from './FavoriteButton.module.scss';

export default function FavoriteButton({ active }: { active: boolean }) {
  return (
    <button className={active ? styles.activeButton : styles.button} type="button">
      Favorite
    </button>
  );
}
```

```tsx
// app/javascript/components/ProductPage.tsx (Server Component)
import FavoriteButton from './FavoriteButton';

export default async function ProductPage({ product }: { product: Product }) {
  return (
    <section>
      <h1>{product.name}</h1>
      <FavoriteButton active={product.favorite} />
    </section>
  );
}
```

The RSC bundle turns `FavoriteButton` into a client reference. The client build extracts the SCSS
Module CSS, the RSC manifest records the CSS href, and the RSC stream injects `<link>` tags.

### Shared components

A module can be imported as a Server Component in one path and as part of the client graph in another.
React's `'use client'` directive marks a module dependency subtree, not a render-tree subtree.

Guidelines:

- Use global classes from a layout-loaded stylesheet when the component renders as a Server Component.
- Import CSS Modules from a `'use client'` wrapper when the component needs scoped styles and renders
  as a Client Component.
- Avoid CSS side effects in shared utility modules. They make it unclear whether CSS is emitted by the
  client bundle, ignored by the server/RSC bundle, or duplicated across packs.

## CSS approaches in detail

### Global CSS

Import global CSS from the client pack entry point. The stylesheet loads from the Rails layout
regardless of rendering mode.

```ts
// app/javascript/packs/client-bundle.ts
import '../styles/application.css';
```

```erb
<%= stylesheet_pack_tag "client-bundle", media: "all" %>
```

**Server Components:** Use class names freely. CSS loads from the layout.
**Client Components:** Works. CSS is part of the client bundle.
**Traditional SSR:** Works when `stylesheet_pack_tag` is in `<head>`.
**Limitations:** Not component-scoped. Ordering depends on import order and layout tag placement.
**Status:** Verified.

### CSS Modules

CSS Modules provide component-scoped class names with build-time hashing. They are the recommended
approach for scoped styling in React on Rails Pro RSC apps.

```tsx
// app/javascript/components/Card.tsx
'use client';

import styles from './Card.module.css';

export default function Card({ title }: { title: string }) {
  return <div className={styles.card}>{title}</div>;
}
```

```css
/* app/javascript/components/Card.module.css */
.card {
  padding: 1rem;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
}
```

**How it works across bundles:**

- **Client bundle:** `css-loader` processes the `.module.css` file with CSS Modules mode, generating
  hashed class names (e.g., `.card` becomes `.K8av1vsiP9K1YYs501EV`). `MiniCssExtractPlugin` extracts
  the CSS rules into the output stylesheet. The JavaScript module exports the mapping
  `{ card: 'K8av1vsiP9K1YYs501EV' }`.

- **Server bundle:** `css-loader` runs with `exportOnlyLocals: true`. It generates the same class name
  mapping but emits no CSS output. SSR renders the correct hashed class names in the HTML.

- **RSC bundle:** Same as the server bundle for Server Component imports. For `'use client'` modules,
  the RSC loader replaces the module with a client reference, so the CSS Module import is not
  evaluated in the RSC bundle.

**Server Components:** Can import CSS Modules and render hashed class names. The CSS rules must also be
available in the client bundle (via a `'use client'` component or global import).
**Client Components:** Full support. CSS is extracted and recorded in the RSC manifest.
**Traditional SSR:** Full support. Server renders class names; client stylesheet provides CSS.
**FOUC prevention:** Yes, via manifest `<link>` tags when behind `'use client'`.
**Status:** Verified by Pro dummy app specs.

### Sass/SCSS

SCSS Modules work identically to CSS Modules. `sass-loader` compiles SCSS to CSS before `css-loader`
processes it. The same `exportOnlyLocals` behavior applies in server/RSC bundles.

```tsx
// app/javascript/components/FavoriteButton.tsx
'use client';

import styles from './FavoriteButton.module.scss';

export default function FavoriteButton({ active }: { active: boolean }) {
  return (
    <button className={active ? styles.activeButton : styles.button} type="button">
      Favorite
    </button>
  );
}
```

**Required packages:** `sass`, `sass-loader`, configured via Shakapacker's default rules.
**Status:** Verified for SCSS Modules in RSC client boundary.

Plain (non-module) SCSS files follow the same rules as plain CSS: import from the client pack for
global styles, or from a `'use client'` component for scoped usage.

### Tailwind CSS

Tailwind CSS is a PostCSS plugin that generates utility CSS at build time. It scans source files for
class names and emits only the CSS needed. Since it produces static CSS, it works seamlessly with the
three-bundle architecture.

**How Tailwind works with RSC:**

1. Tailwind runs as a PostCSS plugin during the client bundle build only.
2. It scans all files listed in its `content` configuration for utility class names.
3. The generated CSS is extracted into the client stylesheet.
4. Server Components and Client Components both use Tailwind class names as plain strings.
5. The CSS loads from the Rails layout's `stylesheet_pack_tag`.

**Critical configuration:** The Tailwind `content` array must include all directories that contain
files using Tailwind classes, including React component files and ERB views:

#### Tailwind CSS v4 (new apps)

The React on Rails generator supports Tailwind v4 via `--tailwind`. Tailwind v4 uses a CSS-first
configuration model:

```css
/* app/javascript/styles/application.css */
@import 'tailwindcss';
```

```js
// postcss.config.mjs
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

Tailwind v4 auto-discovers source files without a `content` configuration. It scans the project
tree automatically.

#### Tailwind CSS v3 (existing apps)

Tailwind v3 requires explicit `content` paths. **Include both Rails views and JavaScript component
directories:**

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

> [!WARNING]
> If the `content` array does not include your React component directory, Tailwind will silently
> drop any utility classes used only in React components. The classes will appear in source code
> but have no effect — there will be no build error, just unstyled elements.

**Server Components:** Use Tailwind class names freely. CSS loads from the layout.
**Client Components:** Use Tailwind class names freely. CSS loads from the layout.
**Traditional SSR:** Works when the Tailwind stylesheet is in `<head>`.
**FOUC prevention:** Via Rails layout `<link>` tag (global CSS path).
**Limitations:** Dynamic class names (template literals, string concatenation) must be statically
discoverable by Tailwind's scanner or explicitly safelisted.
**Status:** Verified by build analysis; dummy app uses Tailwind v3 globally.

### Inline styles

React inline styles (`style` prop) work everywhere because they are serialized directly in the HTML
or RSC payload. No external CSS file is needed.

```tsx
// Works in Server Components, Client Components, and SSR
export default function Badge({ color }: { color: string }) {
  return (
    <span style={{ backgroundColor: color, padding: '0.25rem 0.5rem', borderRadius: '0.25rem' }}>New</span>
  );
}
```

**Server Components:** Works. Style objects are serialized in the RSC Flight payload.
**Client Components:** Works.
**Traditional SSR:** Works.
**FOUC prevention:** Not needed — styles are inline in the HTML.
**Limitations:** No pseudo-classes, media queries, or keyframe animations. Not ideal for complex
styling. Can increase HTML payload size.
**Status:** Verified by build analysis.

### Vanilla Extract

[Vanilla Extract](https://vanilla-extract.style/) compiles TypeScript style definitions to static CSS
at build time. Since it produces extracted CSS files, it integrates with the RSC manifest pipeline.

**Setup:** Add the Vanilla Extract webpack plugin to your client webpack config. Do not add it to the
server or RSC configs — those bundles should not extract CSS.

```js
// config/webpack/clientWebpackConfig.js (append to existing configureClient)
const { VanillaExtractPlugin } = require('@vanilla-extract/webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

const vanillaExtractCssRule = {
  test: /\.vanilla\.css$/i,
  use: [MiniCssExtractPlugin.loader, { loader: require.resolve('css-loader'), options: { url: false } }],
};

// Exclude .vanilla.css from the broad CSS rule to avoid double processing
const excludeVanillaExtractCss = (rule) => {
  if (!rule || typeof rule !== 'object') return;
  if (Array.isArray(rule.oneOf)) rule.oneOf.forEach(excludeVanillaExtractCss);
  if (rule.test instanceof RegExp && rule.test.test('app.css')) {
    rule.exclude = [rule.exclude, /\.vanilla\.css$/i].flat().filter(Boolean);
  }
};

const applyVanillaExtract = (clientConfig) => {
  clientConfig.plugins.push(new VanillaExtractPlugin());
  clientConfig.module.rules.forEach(excludeVanillaExtractCss);
  clientConfig.module.rules.push(vanillaExtractCssRule);
};
```

**Usage pattern:** Keep Vanilla Extract imports behind `'use client'` for RSC apps:

```ts
// app/javascript/components/productCard.css.ts
import { style } from '@vanilla-extract/css';

export const card = style({
  display: 'grid',
  gap: '0.75rem',
});
```

```tsx
// app/javascript/components/ProductCard.tsx
'use client';

import { card } from './productCard.css';

export default function ProductCard({ product }: { product: Product }) {
  return <article className={card}>{product.name}</article>;
}
```

The import specifier uses `productCard.css` (no `.ts`). Vanilla Extract's bundler plugin resolves the
authored `.css.ts` module and emits `.vanilla.css`. The broad CSS rule must exclude `.vanilla.css`
so the custom rule handles it.

**Server Components:** Importing `.css.ts` directly from a Server Component requires additional
server/RSC bundle configuration. Use the `'use client'` wrapper pattern instead.
**Client Components:** Works when the build plugin and CSS extraction rules are configured.
**FOUC prevention:** Yes, via manifest `<link>` tags when behind `'use client'`.
**Limitations:** Not verified end-to-end with React on Rails Pro RSC. The `.css.ts` import may need
an `swc-plugin-vanilla-extract` workaround in some setups. Inspect your `react-client-manifest.json`
to confirm CSS appears.
**Status:** Assumed from build-tool behavior. Not covered by a Pro regression test.

### styled-components

styled-components is a runtime CSS-in-JS library. It generates CSS at runtime by injecting `<style>`
tags into the DOM. This means its CSS is **not** extracted into files and **not** recorded in
`react-client-manifest.json`.

```tsx
// app/javascript/components/StyledButton.tsx
'use client';

import styled from 'styled-components';

const Button = styled.button`
  background-color: peachpuff;
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 0.25rem;
  cursor: pointer;
`;

export default function StyledButton() {
  return <Button>Click me</Button>;
}
```

> [!IMPORTANT]
> styled-components **must** be used behind a `'use client'` boundary. Using it in a Server Component
> will crash because it depends on React Context and `useRef`.

**Server Components:** Not supported. Will throw runtime errors.
**Client Components:** Works behind `'use client'`. styled-components v6 includes React 19
compatibility fixes.
**Traditional SSR:** Works with `ServerStyleSheet` for style extraction during SSR. Requires
app-specific integration with the node renderer.
**FOUC prevention:** None from the RSC manifest pipeline. Runtime-injected styles load after
JavaScript executes, which can cause a flash of unstyled content on RSC pages.
**Limitations:**

- Context-based theming (`ThemeProvider`) is not available in Server Components. Use CSS custom
  properties for cross-boundary theming.
- styled-components is in maintenance mode. The maintainer has stated: "For new projects, I would not
  recommend adopting styled-components."
- SSR style collection requires `ServerStyleSheet` wrapping, which is not built into React on Rails
  Pro's node renderer by default.
  **Status:** Unknown for React on Rails Pro RSC integration. Works in client-only usage.

### Emotion

Emotion is a runtime CSS-in-JS library similar to styled-components. The same architectural
constraints apply: runtime `<style>` injection, no extracted CSS chunk recording, no RSC FOUC prevention.

```tsx
// app/javascript/components/EmotionCard.tsx
'use client';

import styled from '@emotion/styled';

const Card = styled.div`
  background-color: powderblue;
  padding: 1rem;
  border-radius: 0.5rem;
`;

export default function EmotionCard() {
  return <Card>Emotion-styled card</Card>;
}
```

**Server Components:** Not supported. Emotion depends on React Context (`CacheProvider`).
**Client Components:** Works behind `'use client'`.
**Traditional SSR:** Works with Emotion's SSR cache/extraction setup (`@emotion/server`,
`extractCriticalToChunks`). Requires app-specific integration.
**FOUC prevention:** None from the RSC manifest pipeline.
**Status:** Unknown for RSC. Assumed to work for client-only usage.

### Other static extraction libraries

Libraries like [Linaria](https://linaria.dev/), [Panda CSS](https://panda-css.com/),
[StyleX](https://stylexjs.com/), and [Compiled](https://compiledcssinjs.com/) extract CSS at build
time, producing static CSS files that Shakapacker can serve.

**General principle:** If the library produces a CSS file that can be imported from a client pack or
a `'use client'` component, it will work with React on Rails Pro's RSC architecture. The CSS enters
the client bundle and is extracted normally.

**Setup pattern:**

1. Add the library's bundler plugin to your **client webpack/Rspack config only**.
2. Import the library's generated CSS from a `'use client'` component or the global stylesheet.
3. Verify the extracted CSS appears in `react-client-manifest.json` if using the `'use client'` path.
4. Do not add the library's plugin to the server or RSC bundle configs unless the library specifically
   requires it for class name resolution (check the library's RSC documentation).

**Status:** Assumed. None of these libraries are covered by React on Rails Pro regression tests.

### Class name utilities (clsx, classnames, CVA)

These libraries compose class name strings at runtime. They do not emit CSS themselves.

```tsx
import clsx from 'clsx';

export default function Alert({ type }: { type: 'info' | 'error' }) {
  return <div className={clsx('alert', `alert-${type}`)}>...</div>;
}
```

They work everywhere — Server Components, Client Components, SSR — because they are pure functions
that return strings. Pair them with a CSS approach that provides the actual class definitions
(Tailwind, CSS Modules, global CSS).

**Status:** Assumed; low risk.

## React on Rails asset rendering

### Manual pack loading

```erb
<%= stylesheet_pack_tag "client-bundle", media: "all" %>
<%= javascript_pack_tag "client-bundle", defer: true %>
```

### Auto-loaded component packs

With `auto_load_bundle: true`, use argless tag placeholders. React on Rails appends component pack
names during rendering:

```erb
<%= stylesheet_pack_tag media: "all" %>
<%= javascript_pack_tag defer: true %>
```

When using SSR with `auto_load_bundle`, render the body before the `<head>` so the component pack
names are available when the stylesheet tags are emitted:

```erb
<% content_for :body_content do %>
  <%= yield %>
<% end %>

<!DOCTYPE html>
<html>
  <head>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_pack_tag "client-bundle", media: "all" %>
    <%= stylesheet_pack_tag media: "all" %>
  </head>
  <body>
    <%= yield :body_content %>
    <%= javascript_pack_tag "client-bundle", defer: true %>
    <%= javascript_pack_tag defer: true %>
  </body>
</html>
```

### RSC pages

For pages rendered by `stream_react_component`, CSS for `'use client'` references is handled by the
Pro RSC renderer via the manifest pipeline. Keep the Rails stylesheet tags anyway for global CSS and
non-RSC components.

## Verifying CSS in production builds

Development HMR can hide or introduce FOUC that does not exist in production. Always verify with
production-like builds:

```bash
RAILS_ENV=production NODE_ENV=production CLIENT_BUNDLE_ONLY=true bin/shakapacker
RAILS_ENV=production NODE_ENV=production SERVER_BUNDLE_ONLY=true bin/shakapacker
RAILS_ENV=production NODE_ENV=production RSC_BUNDLE_ONLY=true bin/shakapacker
```

Then inspect:

1. **`public/<public_output_path>/manifest.json`** — Shakapacker asset manifest. Check that your CSS
   files are listed.
2. **`public/<public_output_path>/react-client-manifest.json`** — RSC client manifest. Check that
   `'use client'` modules have `css` arrays pointing to the correct stylesheet files.
3. **Server-rendered HTML** — Look for `<link rel="stylesheet">` tags before the first styled
   component. For RSC pages, look for `<link rel="stylesheet" data-precedence="rsc-css">` tags.

## Compatibility matrix

Status key:

- **Verified**: covered by current repo code, docs, or build analysis.
- **Assumed**: expected from current architecture and package behavior, but not covered by a
  React on Rails Pro regression fixture.
- **Unsupported**: does not fit the current generated RSC/server CSS pipeline.
- **Unknown**: needs a fixture or package-specific investigation before recommendation.

| Approach                            | Server Component                               | Client Component (RSC)               | Traditional SSR                        | FOUC prevention              | Required config                                            | Status              |
| ----------------------------------- | ---------------------------------------------- | ------------------------------------ | -------------------------------------- | ---------------------------- | ---------------------------------------------------------- | ------------------- |
| Global CSS (layout pack)            | Works (class names render; CSS loads globally) | Works                                | Works                                  | Rails `<link>`               | Import CSS in client pack; `stylesheet_pack_tag` in layout | Verified            |
| CSS Modules (`'use client'`)        | `exportOnlyLocals` renders class names         | Works; CSS extracted and in manifest | Works; server renders locals           | Manifest `<link>` tags       | Shakapacker CSS Modules config; RSC manifest plugin        | Verified            |
| CSS Modules (Server Component only) | Class names render but CSS is not emitted      | N/A                                  | Class names render but CSS not emitted | None                         | Move CSS to client graph                                   | Unsupported         |
| SCSS Modules (`'use client'`)       | Same as CSS Modules                            | Same as CSS Modules                  | Same as CSS Modules                    | Manifest `<link>` tags       | `sass`, `sass-loader`                                      | Verified            |
| Tailwind CSS                        | Works (utility class names)                    | Works (utility class names)          | Works                                  | Rails `<link>`               | PostCSS config; content paths must include component dirs  | Verified (build)    |
| Inline styles                       | Works (serialized in RSC payload)              | Works                                | Works                                  | N/A                          | None                                                       | Verified (build)    |
| `clsx`/`classnames`/CVA             | Works (pure string functions)                  | Works                                | Works                                  | N/A                          | None; pair with a CSS source                               | Assumed             |
| Vanilla Extract                     | Needs `'use client'` wrapper                   | Works with build plugin              | Works                                  | Manifest `<link>` tags       | `@vanilla-extract/webpack-plugin` in client config         | Assumed             |
| Linaria                             | Needs `'use client'` wrapper                   | Works after Babel/loader setup       | Works                                  | Depends on import path       | WyW Babel preset; `@wyw-in-js/webpack-loader`              | Assumed             |
| Panda CSS                           | Works (classes are static strings)             | Works                                | Works                                  | Rails `<link>`               | Panda CLI or PostCSS; import generated CSS in layout       | Assumed             |
| StyleX                              | Works (classes are static strings)             | Works                                | Works                                  | Rails `<link>`               | StyleX Babel plugin; import generated CSS                  | Assumed             |
| Compiled                            | Needs `'use client'` wrapper                   | Works with webpack loader            | Works                                  | Depends on import path       | `@compiled/webpack-loader`; CSS extraction                 | Assumed             |
| styled-components v6                | **Not supported** (crashes)                    | Works behind `'use client'`          | Works with `ServerStyleSheet`          | **None** (runtime injection) | Recent v6; optional Babel/SWC plugin                       | Unknown for Pro RSC |
| Emotion                             | **Not supported** (crashes)                    | Works behind `'use client'`          | Works with SSR cache                   | **None** (runtime injection) | `@emotion/react`, `@emotion/styled`; SSR setup             | Unknown for RSC     |
| Runtime component libraries         | Treat as Client Components                     | Works behind `'use client'`          | Depends on library SSR support         | **None** usually             | Library-specific                                           | Unknown             |

## Common pitfalls

### Importing CSS only from a Server Component

```tsx
// WRONG: CSS is not emitted to the browser
import './ProductSummary.css'; // only imported here, a Server Component

export default function ProductSummary() {
  return <div className="product-summary">...</div>;
}
```

The server renders `<div class="product-summary">`, but no stylesheet is loaded. The element appears
unstyled. Move the CSS import to the client pack or a `'use client'` component.

### Missing component directories in Tailwind content paths

If Tailwind classes work in ERB views but not in React components, check that the component directory
is in Tailwind's `content` array. Tailwind v3 does not scan files outside its configured paths.

### Using runtime CSS-in-JS without understanding FOUC implications

styled-components and Emotion work in Client Components, but their CSS loads after JavaScript
executes. On RSC pages, this means a visible flash where the component renders with no styles,
then styles appear once JavaScript hydrates. For new components, prefer CSS Modules or Tailwind.

### Adding CSS extraction plugins to server/RSC webpack configs

The server and RSC bundles should **not** have `MiniCssExtractPlugin`, `style-loader`, or any CSS
injection mechanism. CSS Modules should use `exportOnlyLocals: true`. The generated Pro configs
handle this correctly — do not override it.

### Forgetting to rebuild all three bundles after CSS changes

CSS changes that affect the RSC manifest (new `'use client'` components with CSS imports, new CSS
Module files) require rebuilding all three bundles. The manifest is generated from the client build
but consumed by the RSC renderer.

### Shakapacker v9 CSS Modules default change

Shakapacker v9 changed CSS Modules defaults to `namedExport: true` and
`exportLocalsConvention: 'camelCaseOnly'`. This breaks code using the default export pattern
(`import styles from './Foo.module.scss'`). The generated Pro configs override this to preserve
the original behavior (`namedExport: false`, `exportLocalsConvention: 'camelCase'`). If you
customize your webpack CSS rules, check that the overrides are still in place.

### Importing global CSS in the server bundle entry point

The server bundle entry (`server-bundle.js`) should **not** import `application.css` or other
global CSS files. CSS imports in the server bundle resolve to empty modules or class-name-only
mappings. Importing Tailwind's CSS in the server entry wastes build time without producing usable
output.

### RSC stylesheet cascade order (end-of-`<head>` precedence)

This pitfall applies to React 19+ installations, where React manages stylesheet precedence groups
via the `data-precedence` attribute. React 18 does not hoist these stylesheet groups.

The RSC client-chunk stylesheet pipeline emits each CSS href referenced by the current Flight payload
as a `<link rel="stylesheet" data-precedence="rsc-css">` tag. React places every
`data-precedence="rsc-css"` link at the **end** of `<head>`, after framework and vendor CSS, so when
specificity is equal, these stylesheets win source-order ties against precedence-less stylesheets —
including the Rails-layout `stylesheet_pack_tag` links that have no `data-precedence` attribute.

This matters when an RSC CSS Module contains an **unscoped global selector**. CSS Module _class names_
are scoped, but selectors such as `html`, `body`, `:root`, the universal selector `*`, bare
pseudo-elements like `::before` or `::placeholder`, and attribute selectors like `[data-theme]` still
apply globally. Because the `data-precedence="rsc-css"` group lands last, an unscoped selector inside a
CSS Module can override your global styles unexpectedly once that stylesheet is delivered:

```css
/* WRONG: a Bootstrap-style bare element selector inside an RSC CSS Module.
   It is NOT scoped, and the rsc-css group lands at the end of <head>, so this
   will win source-order ties against a global html rule and reset the root
   font-size site-wide. */
html {
  font-size: 14px;
}

.card {
  /* scoped class names are fine */
  padding: 1rem;
}
```

Defensive-specificity guidance: never put bare element selectors at the top of (or anywhere in) an
RSC CSS Module — scope every rule to a class. Keep global resets like `html { font-size }` in a
dedicated global stylesheet loaded through the Rails layout, not in a CSS Module that rides along
with a `'use client'` reference.

For teams that want the strictest no-type-selector convention, including rejecting scoped descendants
such as `.card a`, add a per-file override so CI catches element selectors in CSS Modules before they
reach production:

Example `.stylelintrc.json`:

```json
{
  "overrides": [
    {
      "files": ["**/*.module.css", "**/*.module.scss", "**/*.module.sass"],
      "rules": { "selector-max-type": 0 }
    }
  ]
}
```

If your CSS Module convention intentionally permits scoped descendants such as `.card a`, use
`selector-max-type: [0, { "ignore": ["descendant"] }]` instead — this still blocks bare top-level
selectors like `html` or `body` while allowing `.card a`:

```json
{
  "overrides": [
    {
      "files": ["**/*.module.css", "**/*.module.scss", "**/*.module.sass"],
      "rules": { "selector-max-type": [0, { "ignore": ["descendant"] }] }
    }
  ]
}
```

```css
/* ProductCard.module.css -- CORRECT: class-scoped rules only */
.card {
  font-size: 0.875rem;
  padding: 1rem;
}
```

```css
/* application.css -- CORRECT: global reset loaded through the Rails layout */
html {
  font-size: 14px;
}
```

See [RSC stylesheet injection troubleshooting](../../oss/migrating/rsc-troubleshooting.md#rsc-stylesheet-injection-render-blocking-links-and-cascade-order)
for the render-blocking, client-chunk-driven injection, and cascade behavior behind these links.

See [React Performance Tracks and Profiling](../../oss/building-features/performance-tracks-and-profiling.md#measuring-an-rsc-conversion-with-a-paired-ab)
to measure the end-to-end performance impact of RSC changes with a paired A/B comparison.

## Known limitations

- RSC stylesheet links are filtered by client chunk names found in the current Flight payload, not by
  blindly linking every client manifest entry. The links can still include any CSS bundled into those
  referenced chunks, so broad client boundaries or shared chunks can make more CSS render-blocking than
  a single component appears to need.
- Older `react-client-manifest.json` files without `css` arrays (pre `react-on-rails-rsc@19.0.5-rc.6`)
  cannot produce RSC stylesheet links. Rebuild all three bundles after upgrading.
- For client-side RSC navigation (`RSCRoute`), the RSC payload still needs stylesheet links. Verify
  this path separately for route-heavy apps.
- **Rspack FOUC gap:** The `RSCRspackPlugin` emits the same manifest schema as the webpack plugin
  for component references, but at the time of writing, Rspack builds can omit CSS assets for RSC
  client chunks from the stats consumed by `injectRSCPayload`. When that map is empty, the FOUC
  prevention pipeline is silently inactive. CSS for `'use client'` components still works via the
  Rails layout `stylesheet_pack_tag`, but without client-chunk stylesheet injection. See
  [Rspack compatibility](./rspack-compatibility.md) for details.
- **Rspack CSS Module class name divergence:** When using Rspack with CSS Modules, avoid
  `[contenthash]` in `localIdentName`. Rspack client and server builds may produce different
  content hashes for the same file, causing SSR class name mismatches. Use a stable `getLocalIdent`
  function based on file path and class name instead. See the
  [webpack-to-Rspack migration guide](../../oss/migrating/migrating-from-webpack-to-rspack.md).
- This page does not include regression fixtures for Tailwind, Vanilla Extract, Linaria, Panda CSS,
  Compiled, StyleX, styled-components, Emotion, or component-library styling systems.

## See also

- [RSC rendering flow](./rendering-flow.md) — client, server, and RSC bundle lifecycle
- [Styling with Tailwind CSS](../../oss/building-features/styling-with-tailwind.md) — generator setup
  for Tailwind v4
- [View helpers API](../../oss/api-reference/view-helpers-api.md) — `stream_react_component`,
  `stylesheet_pack_tag`, and related helpers
- [Third-party library compatibility](../../oss/migrating/rsc-third-party-libs.md) — RSC migration
  notes for CSS-in-JS and other libraries
- [Rspack compatibility](./rspack-compatibility.md) — bundler compatibility matrix
