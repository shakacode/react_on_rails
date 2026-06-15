# Hydration Scheduling

`hydrate_on` lets a Rails view keep server-rendered HTML visible immediately while deferring when React attaches event handlers and effects for that island.

Deferred modes are implemented by the open-source client renderer. If React on Rails Pro is installed, non-immediate modes raise an error instead of silently hydrating immediately.

Use it on standard `react_component` roots:

```erb
<%= react_component("ProductRecommendations",
                    props: @recommendation_props,
                    prerender: true,
                    hydrate_on: :visible) %>
```

The open-source package supports these modes:

| Mode         | Behavior                                                                                                        |
| ------------ | --------------------------------------------------------------------------------------------------------------- |
| `:immediate` | Default. Hydrates or client-renders as soon as React on Rails processes the component.                          |
| `:visible`   | Uses `IntersectionObserver` and hydrates when the component container enters the viewport, with a 200px margin. |
| `:idle`      | Uses `requestIdleCallback` with a timeout, falling back to a short timer when the browser lacks idle callbacks. |

## When to Use It

Use `hydrate_on: :visible` for below-the-fold islands such as recommendations, comments, footers, or sidebar widgets. Use `hydrate_on: :idle` for low-priority islands that are visible but not needed for the first interaction.

Keep `:immediate` for navigation, forms, buttons, and anything the user may interact with right away.

## Server-Rendered Islands

With `prerender: true`, the user sees the server-rendered HTML immediately. React hydration waits for the selected mode:

```erb
<%= react_component("Reviews",
                    props: { product_id: @product.id },
                    prerender: true,
                    hydrate_on: :visible) %>
```

Because the HTML is already present, this works well for content that should be readable before it becomes interactive. Avoid making deferred islands look interactive before hydration. For example, render controls disabled until the component has hydrated, or keep immediate hydration for controls above the fold.

## Client-Only Roots

`hydrate_on` also schedules client-only roots:

```erb
<%= react_component("ClientOnlyChart",
                    props: @chart_props,
                    prerender: false,
                    hydrate_on: :idle) %>
```

For `prerender: false`, the container stays empty until React renders. Prefer server rendering when users should see meaningful content before hydration.

For `hydrate_on: :visible`, an empty zero-size client-only container cannot be reliably observed by `IntersectionObserver`. React on Rails renders that root on the next tick instead of leaving it permanently unmounted. If you need true viewport-based deferral for a client-only root, reserve layout space for the container or use `hydrate_on: :idle`.

## Turbo and Turbolinks Cleanup

React on Rails cancels pending `:visible` observers and `:idle` callbacks during the same page-unload lifecycle it uses to unmount React roots on Turbo and Turbolinks navigation. If a user navigates away before a deferred island hydrates, the pending observer or callback is disconnected so the old page cannot hydrate after Turbo swaps the body.

## What This Does Not Do

`hydrate_on` does not defer JavaScript bundle fetching. If you use `auto_load_bundle: true`, the generated bundle is still loaded when the page loads; only the React root creation is scheduled. Deferred bundle fetch is a separate optimization.

`:interaction` is not supported in the open-source package. Passing `hydrate_on: :interaction` raises an error. Use `:immediate`, `:visible`, or `:idle`.

Renderer functions, the 3-argument functions that call `hydrateRoot` or `createRoot` themselves, own their own mounting behavior. `hydrate_on` applies to normal React component registrations that React on Rails mounts for you.
