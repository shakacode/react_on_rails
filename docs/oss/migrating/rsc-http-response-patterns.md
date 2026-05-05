# RSC Migration: HTTP Response Ownership

This guide covers status codes, redirects, and cache headers when Rails owns the HTTP request and React Server Components own the rendered UI.

> **Part 5 of the [RSC Migration Series](migrating-to-rsc.md)** | Previous: [Data Fetching Migration](rsc-data-fetching.md) | Next: [Third-Party Library Compatibility](rsc-third-party-libs.md)

> **Note:** The streaming helpers shown in this guide (`ReactOnRailsPro::Stream`, `stream_view_containing_react_components`, and `stream_react_component`) require React on Rails Pro. The same HTTP ownership rules apply to non-streaming Rails responses; use the rendering helper that matches your app.

## Core Rule: Rails Decides Before Rendering

React Server Components decide what UI to render. Rails still decides the HTTP response:

- Status codes (`200`, `404`, `410`, etc.)
- Redirects
- Cache headers
- Cookies and session policy
- Authentication and authorization failures

With streaming, this boundary matters even more. Once Rails writes the first response chunk, headers are committed. After that point the app can no longer turn the response into a real HTTP redirect, change `200` to `404`, or revise cache policy. Make these route-level decisions in the controller or a Ruby preflight object before calling `stream_view_containing_react_components`.

## Preflight Pattern

Use a controller or service object to gather data and choose the response policy before rendering the RSC tree.

```ruby
class StoriesController < ApplicationController
  include ReactOnRailsPro::Stream

  def show
    preflight = StoryPagePreflight.call(params[:id], current_user: current_user)

    return redirect_to(preflight.redirect_path, status: :see_other) if preflight.redirect_path

    response.status = preflight.status if preflight.status
    response.set_header("Cache-Control", preflight.cache_control) if preflight.cache_control

    @story_props = preflight.props
    stream_view_containing_react_components(template: "stories/show")
  end
end
```

```erb
<%= stream_react_component("StoryPage", props: @story_props) %>
```

Keep the props serializable and intentional. A good preflight result usually contains:

- The data the RSC tree needs to render
- The selected HTTP status
- Any redirect target
- Cache policy metadata
- Small route-level flags such as `notFound: true`

Avoid making React responsible for route outcomes. React can render a "not found" UI, but Rails should decide whether the response is actually a `404`.

## 404 And Not-Found Routes

For simple not-found cases, return a Rails response before streaming:

```ruby
def show
  story = Story.find_by(id: params[:id])
  return render(template: "errors/not_found", status: :not_found) unless story

  @story_props = { story: StorySerializer.render_as_hash(story) }
  stream_view_containing_react_components(template: "stories/show")
end
```

If you want the not-found page itself to be rendered by RSC, set the status before streaming:

```ruby
def show
  story = Story.find_by(id: params[:id])

  if story.nil?
    response.status = :not_found
    @story_props = { notFound: true, story: nil }
  else
    @story_props = { story: StorySerializer.render_as_hash(story) }
  end

  stream_view_containing_react_components(template: "stories/show")
end
```

Then keep the React component purely presentational:

```tsx
type StoryPageProps = { notFound: true; story: null } | { notFound?: false; story: Story };

export default function StoryPage({ notFound, story }: StoryPageProps) {
  if (notFound) {
    return <NotFoundMessage />;
  }

  return <Story story={story} />;
}
```

Use this pattern when the branded not-found UI benefits from the same RSC layout as the rest of the route. Use a plain Rails error template when you need the smallest, most reliable failure path.

## Redirects

Use Rails redirects before streaming:

```ruby
def show
  story = Story.find_by(id: params[:id])
  return redirect_to(stories_path, alert: "Story not found", status: :see_other) unless story

  return redirect_to(sign_in_path, status: :see_other) unless can?(:read, story)

  @story_props = { story: StorySerializer.render_as_hash(story) }
  stream_view_containing_react_components(template: "stories/show")
end
```

Do not model route redirects as Server Component return values. React on Rails render-functions may expose redirect metadata for client routers, but React on Rails does not turn that metadata into an actual HTTP redirect for the page response. See [Redirect Information](../core-concepts/render-functions.md#8-redirect-information-legacy).

If a streamed response has already started and an error forces navigation, the fallback is client-side navigation or an error shell, not a true HTTP redirect. Treat that as an exception path, not the normal route design.

## Cache Headers

Set cache headers in Rails before streaming. The streamed HTML can include serialized props and embedded RSC payloads, so cache it with the same care you would use for any Rails response that contains user-specific data.

For personalized pages, prefer private HTTP caching with revalidation:

```ruby
response.set_header("Cache-Control", "private, no-cache")
```

`no-cache` allows HTTP caches to store the response but requires revalidation with the origin before each reuse. Use `no-store` instead when sensitive responses must never be cached by anyone.

For public pages, let Rails decide freshness before rendering:

```ruby
def show
  story = Story.published.find_by(slug: params[:slug])
  return render(template: "errors/not_found", status: :not_found) unless story

  return unless stale?(
    story,
    public: true,
    cache_control: { max_age: 60, stale_while_revalidate: 300 }
  )

  @story_props = { story: PublicStorySerializer.render_as_hash(story) }
  stream_view_containing_react_components(template: "stories/show")
end
```

Rails 7.1+ supports `cache_control:` on `stale?`. On older Rails versions, set the full `Cache-Control` header directly and keep the explicit freshness guard before streaming.

When the response varies by locale, device class, authentication state, or feature flag, set the corresponding `Vary` policy or keep the response private:

```ruby
response.set_header("Vary", "Accept-Language")
```

Do not bury cache decisions inside Server Components. By the time React is rendering, the controller should already know whether the response is public, private, stale, or not cacheable.

## What To Pass Into RSC

Pass decisions as data, not as hidden HTTP side effects:

```ruby
@story_props = {
  story: StorySerializer.render_as_hash(story),
  viewer: ViewerSerializer.render_as_hash(current_user),
  responsePolicy: {
    canonicalUrl: story_url(story)
  }
}
```

```tsx
type ResponsePolicy = { canonicalUrl: string };
type StoryPageProps = { story: Story; viewer: Viewer; responsePolicy: ResponsePolicy };

export default function StoryPage({ story, viewer, responsePolicy }: StoryPageProps) {
  return (
    <>
      <link rel="canonical" href={responsePolicy.canonicalUrl} />
      <Story story={story} viewer={viewer} />
    </>
  );
}
```

Native `<link>` hoisting requires React 19. On React 18, use `react-helmet` or emit canonical URLs from the Rails layout instead. See [React 19 Native Metadata](../building-features/react-19-native-metadata.md).

React can render metadata, route chrome, empty states, and branded error UI from these props. Rails remains the source of truth for the actual HTTP semantics.

## Checklist

- Decide redirects before rendering.
- Decide `404`, `410`, and authorization statuses before rendering.
- Set cache headers before the first streamed chunk.
- Pass route decisions into RSC as serializable props.
- Keep Rails controllers, policies, and services responsible for authentication, authorization, and response policy.
- Use Client Component navigation only for browser-side transitions after a valid HTTP response exists.
