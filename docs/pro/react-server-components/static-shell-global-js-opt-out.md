# Page-Level Global JavaScript Opt-Out for Static Shells

React Server Component pages often make the biggest performance gains when the
HTML shell is mostly static. Those pages may still need the normal Rails layout,
global stylesheet, design tokens, fonts, and header/footer markup, but they may
not need the full application-wide browser pack.

Use an explicit page-level opt-out in the Rails layout. The layout keeps loading
global CSS and generated component CSS, but skips the selected global JavaScript
pack only on pages that opt in.

> [!NOTE]
> This is an application layout convention, not a React Server Components API.
> Keep the decision explicit in Rails so static public pages do not accidentally
> inherit route, auth, analytics, or modal behavior from the default app pack.

## When to Use This Pattern

Use this for RSC or partially prerendered pages where all of these are true:

- The Rails layout and global CSS should remain unchanged.
- The page's initial UI is useful without the normal global browser pack.
- Any required browser behavior can live in a small page-specific sidecar pack.
- The page explicitly opts out, rather than relying on a path or controller name
  check hidden in the layout.

Do not use this for pages whose primary behavior depends on app-wide JavaScript,
such as authenticated dashboards, global modals, navigation state managers, or
client routers initialized by the skipped pack.

## Layout Pattern

Keep stylesheet tags unconditional. If your global pack imports your global CSS,
continue rendering its stylesheet even when the JavaScript for that pack is
skipped.

```erb
<!-- app/views/layouts/application.html.erb -->
<% content_for :body_content do %>
  <%= yield %>
<% end %>

<!DOCTYPE html>
<html>
  <head>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_pack_tag "global", media: "all" %>
    <%= stylesheet_pack_tag media: "all" %>
  </head>
  <body>
    <%= yield :body_content %>

    <% append_javascript_pack_tag "global" unless content_for?(:skip_global_javascript) %>
    <%= javascript_pack_tag defer: true %>
  </body>
</html>
```

The important split is:

- `stylesheet_pack_tag "global"` stays in the layout for every page.
- `content_for :body_content` captures the page before the `<head>` renders, so
  any stylesheet appends from the page are available to the head flush.
- `append_javascript_pack_tag "global"` is conditional.
- The empty `javascript_pack_tag` still flushes page-specific packs appended by
  the view or by React on Rails auto-bundling.

If the global pack must run before page-specific sidecars on normal pages, use
`prepend_javascript_pack_tag "global"` with the same guard.

If your layout already uses the
[`content_for :body_content` pattern](../../oss/core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#2-css-not-loading-fouc---flash-of-unstyled-content),
keep that structure and only apply the conditional guard around the global
JavaScript append.

## Page Opt-Out

In a static shell view, provide the opt-out flag and append only the small
sidecar pack that the page still needs.

If the page uses `stream_react_component`, render the containing view through
the streaming wrapper so the helper has the async barrier it expects:

```ruby
# app/controllers/public_controller.rb
class PublicController < ApplicationController
  include ActionController::Live
  include ReactOnRails::Controller
  include ReactOnRailsPro::Stream

  def home
    @public_home_props = PublicHomeProps.call
    stream_view_containing_react_components(template: "public/home")
  end
end
```

```erb
<%# app/views/public/home.html.erb %>
<% provide :skip_global_javascript, "true" %>
<% append_javascript_pack_tag "public_home_intent_hydration" %>

<%= stream_react_component(
  "PublicHomePage",
  props: @public_home_props
) %>
```

The sidecar should stay narrow. Examples include a newsletter form enhancer, an
intent-hydration trigger, a consent-aware analytics event, or a small progressive
enhancement that is truly required on that static shell.
For the broader controller/view contract, see the
[Streaming Server Rendering guide](../../oss/building-features/streaming-server-rendering.md).

If the sidecar imports CSS, append its stylesheet too. This relies on the
`content_for :body_content` layout timing shown above; without that capture, a
stylesheet append from a normal view body runs after the layout `<head>` has
already flushed the main `stylesheet_pack_tag`, which can cause FOUC.

```erb
<% append_stylesheet_pack_tag "public_home_intent_hydration" %>
<% append_javascript_pack_tag "public_home_intent_hydration" %>
```

Most static shells should not need this because shared visual styling belongs in
the layout-loaded global stylesheet or in RSC client-chunk styles. See
[CSS and Styling with React Server Components](./css-and-styling.md) for how
RSC-specific CSS reaches the browser.

## Keep the Contract Visible

Name the flag after what the page is skipping, not after the route:

```erb
<% provide :skip_global_javascript, "true" %>
```

Avoid layout conditions like this:

```erb
<% unless controller_name == "public_pages" %>
  <% append_javascript_pack_tag "global" %>
<% end %>
```

Route-based conditions make future pages inherit the opt-out accidentally. A
view-level flag keeps the trade-off close to the page that owns it.

## Caveats to Audit Before Opting Out

Audit the skipped global pack for app-wide browser behavior. Common surprises:

- Auth and account modals, login prompts, and session-expiration handlers.
- Query-parameter effects such as flash banners, campaign attribution, or
  scroll-to-anchor fixes.
- Analytics, consent management, A/B testing, error reporting, and web-vitals
  collection.
- Turbo, Stimulus, or client-router setup that assumes the global pack is always
  present.
- Header, footer, or navigation interactions owned by the layout rather than the
  page.

Move behavior that still matters on the static shell into a smaller sidecar pack
or a layout-owned script that is intentionally loaded on those pages. Do not rely
on the skipped global pack for behavior you still expect to run.

## Verification Checklist

For each opted-out page:

1. View source or inspect the network panel and confirm the global JavaScript
   asset is absent.
2. Confirm the global stylesheet and layout CSS still load.
3. Confirm the page-specific sidecar JavaScript loads when one is required.
4. Compare at least one normal app page and confirm it still receives the global
   JavaScript pack.
5. Manually exercise the audited behaviors above, especially analytics, auth
   entry points, and header/footer interactions.

This pattern works well with auto-bundled RSC entry points because it does not
disable the generated per-page pack flush. It only removes the app-wide global
JavaScript pack from pages that explicitly opt out.
