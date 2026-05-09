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
The preflight object exposes a small, serializable result. `StorySerializer`, `PublicStorySerializer`,
`ViewerSerializer`, and `StoryPolicy` are placeholder names in these examples; substitute your app's serializer,
presenter, or authorization helper as needed.

```ruby
class StoriesController < ApplicationController
  include ReactOnRailsPro::Stream # Requires React on Rails Pro

  def show
    preflight = StoryPagePreflight.call(params[:id], current_user: current_user)

    if preflight.redirect_reason
      # Map every possible redirect_reason StoryPagePreflight can return.
      # Unknown reasons fall back to root_path and log an error.
      redirect_path = {
        unauthenticated: sign_in_path,
      }.fetch(preflight.redirect_reason) do |reason|
        Rails.logger.error("Unknown redirect_reason: #{reason.inspect}")
        root_path
      end
      return redirect_to(redirect_path, status: preflight.redirect_status)
    end

    response.status = preflight.status if preflight.status
    response.headers["Cache-Control"] = preflight.cache_control if preflight.cache_control

    @story_props = preflight.props
    stream_view_containing_react_components(template: "stories/show")
  end
end
```

`stream_view_containing_react_components` commits the response status that was set before streaming begins. For example,
a pre-set `:not_found` status remains a real `404` in the HTTP response line.

One possible preflight implementation is:

```ruby
class StoryPagePreflight
  # redirect_reason is nil when no redirect is needed.
  Result = Struct.new(
    :props,
    :status,
    :redirect_reason,
    :redirect_status,
    :cache_control,
    keyword_init: true
  ) do
    # Override the Struct-generated accessor to supply a default when the field is nil.
    def redirect_status
      self[:redirect_status] || :see_other
    end
  end

  def self.call(story_id, current_user:)
    unless current_user
      return Result.new(props: {}, redirect_reason: :unauthenticated)
    end

    story = Story.find_by(id: story_id)

    unless story
      return Result.new(
        props: { notFound: true, story: nil },
        status: :not_found,
        cache_control: "no-store"
      )
    end

    unless StoryPolicy.new(current_user, story).read?
      return Result.new(
        props: { notFound: true, story: nil },
        status: :not_found,
        cache_control: "no-store"
      )
    end

    Result.new(
      props: { story: StorySerializer.render_as_hash(story) },
      cache_control: "private, no-cache"
    )
  end
end
```

```erb
<%= stream_react_component("StoryPage", props: @story_props) %>
```

Keep the props serializable and intentional. A good preflight result usually contains:

- The data the RSC tree needs to render
- The selected HTTP status
- Any redirect reason and status
- Cache policy metadata
- Small route-level flags such as `notFound: true`

Avoid making React responsible for route outcomes. React can render a "not found" UI, but Rails should decide whether the response is actually a `404`.

> **Important:** Set cookies and mutate session state before calling `stream_view_containing_react_components`, for the same reason you set status and cache headers first. Once streaming commits the headers, `Set-Cookie` changes and session writes can no longer be added reliably to the HTTP response.

## 404 and Not-Found Routes

The following controller snippets assume the controller includes `ReactOnRailsPro::Stream`, as shown in the preflight example.

For simple not-found cases, return a Rails response before streaming:

```ruby
def show
  story = Story.find_by(id: params[:id])
  return render(template: "errors/not_found", status: :not_found) unless story

  @story_props = { story: StorySerializer.render_as_hash(story) }
  stream_view_containing_react_components(template: "stories/show")
end
```

Create `app/views/errors/not_found.html.erb` or use another existing error template before copying this pattern. For quick local testing, `render(plain: "Not Found", status: :not_found)` is a minimal stand-in.

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

Then keep the React component purely presentational. The happy path omits `notFound`, so `notFound?: false` models the absent key as the non-error branch while still narrowing `story` after the guard:

```tsx
type StoryData = { id: number; title: string };
type StoryPageProps = { notFound: true; story: null } | { notFound?: false; story: StoryData };

export default function StoryPage({ notFound, story }: StoryPageProps) {
  if (notFound) {
    return <NotFoundMessage />;
  }

  return <Story story={story} />;
}
```

Use this pattern when the branded not-found UI benefits from the same RSC layout as the rest of the route. Use a plain Rails error template when you need the smallest, most reliable failure path.

Rails normalizes `response.status` values through Rack, so both integer codes such as `404` and Rails symbols such as
`:not_found` are valid.

Cache `404` responses publicly only when the route is truly missing, such as typo-driven URLs that repeat often. Prefer
`no-store` for user-specific or permission-sensitive misses, and use `410 Gone` for durable removals where caches should
reuse the response as a permanent absence.

Use `410 Gone` when the route identifies a permanently removed resource and you want caches to treat that response differently from a temporary `404`:

```ruby
def show
  story = Story.find_by(slug: params[:slug])

  return render(template: "errors/not_found", status: :not_found) unless story

  if story.removed?
    response.headers["Cache-Control"] = "public, max-age=3600" # Cache only for truly permanent removals.
    return render(template: "errors/gone", status: :gone)
  end

  @story_props = { story: StorySerializer.render_as_hash(story) }
  stream_view_containing_react_components(template: "stories/show")
end
```

Create `app/views/errors/gone.html.erb` if your app does not already have a generic template for `410`
responses. Cache a `410` only when the removal is durable enough for clients and CDNs to reuse that response.
With `max-age=3600`, a shared cache may keep serving the `410` for up to one hour after the origin restores the
resource unless you purge that cache explicitly. Choose the TTL based on how confident you are that the removal is
permanent and whether your CDN supports on-demand purging; longer TTLs are appropriate only for irreversible removals.

## Redirects

Use Rails redirects before streaming. Keep authentication redirects separate from authorization decisions so signed-in
users are not sent back to sign-in and private resources do not reveal that a record exists. Replace `can?` with your
app's authorization helper:

```ruby
def show
  return redirect_to(sign_in_path, status: :see_other) unless current_user

  story = Story.find_by(id: params[:id])
  return render(template: "errors/not_found", status: :not_found) unless story
  return render(template: "errors/not_found", status: :not_found) unless can?(:read, story)

  @story_props = { story: StorySerializer.render_as_hash(story) }
  stream_view_containing_react_components(template: "stories/show")
end
```

Use `:forbidden` for unauthorized users only when the route is allowed to reveal that the resource exists. For private
resources, returning the same `404` for missing and unauthorized records is usually safer.

Do not model route redirects as Server Component return values. React on Rails render-functions may expose redirect metadata for client routers, but React on Rails does not turn that metadata into an actual HTTP redirect for the page response. See [Redirect Information](../core-concepts/render-functions.md#8-redirect-information-legacy).

If a streamed response has already started and an error forces navigation, the fallback is client-side navigation or an error shell, not a true HTTP redirect. Treat that as an exception path, not the normal route design.

## Cache Headers

Set cache headers in Rails before streaming. The streamed HTML can include serialized props and embedded RSC payloads, so cache it with the same care you would use for any Rails response that contains user-specific data.

For personalized pages, prefer private HTTP caching with revalidation:

```ruby
response.headers["Cache-Control"] = "private, no-cache"
```

`private` prevents CDNs and shared proxies from storing the response; `no-cache` allows permitted HTTP caches to store it but requires revalidation with the origin before each reuse. For a private response, that permitted cache is usually the browser. Use `no-store` instead when sensitive responses must never be cached by anyone.

For public pages, let Rails decide freshness before rendering:

> **Rails 7.1+:** The `cache_control:` keyword on `stale?` requires Rails 7.1 or later. On earlier Rails versions, set the full `Cache-Control` header directly with `response.headers["Cache-Control"] = "public, max-age=300"` and keep the explicit freshness guard before streaming. `stale_while_revalidate` only helps caches that support that extension; unsupported browsers, proxies, and CDNs fall back to normal `max-age` behavior.

```ruby
def show
  story = Story.published.find_by(slug: params[:slug])
  return render(template: "errors/not_found", status: :not_found) unless story

  # If request validators still match, stale? sends 304 Not Modified and returns false.
  # The explicit return avoids opening a stream for that already-selected response.
  return unless stale?(
    story,
    public: true,
    cache_control: { max_age: 60, stale_while_revalidate: 300 }
  )

  @story_props = { story: PublicStorySerializer.render_as_hash(story) }
  stream_view_containing_react_components(template: "stories/show")
end
```

If `stale?` returns `false`, Rails has already prepared the `304 Not Modified` response; the early return keeps the controller from starting a streamed render after that response has been selected.

`stale?` compares Rails' response validators, such as the generated `ETag` and `Last-Modified`, with request headers
such as `If-None-Match` and `If-Modified-Since`. Before relying on this for public caching, make sure those validators
change whenever any rendered input changes. For example, models for comments or join records that affect the page can
declare `belongs_to :story, touch: true`, while author/profile data may need an explicit composite cache key or a manual
touch when it changes. Otherwise Rails can return `304 Not Modified` for content that should be regenerated.

When the response varies by locale, device class, authentication state, or feature flag, set the corresponding `Vary` policy before streaming or keep the response private:

```ruby
# Merge with any existing Vary tokens set upstream, then deduplicate.
existing_vary = response.headers["Vary"].presence

unless existing_vary == "*"
  vary_tokens = [existing_vary, "Accept-Language"].compact.join(", ")
  response.headers["Vary"] = vary_tokens.split(",").map(&:strip).uniq.join(", ")
end
```

Every `Vary` header expands the cache key; avoid high-cardinality headers for public caches unless that extra cache storage is intentional.

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

Keep viewer props minimal. They are embedded in the streamed response and visible to browser DevTools, logs, and any permitted cache, so include only fields the component actually reads rather than a full user representation.

```tsx
type StoryData = { id: number; title: string };
type ViewerData = { id: number; name: string };
type ResponsePolicy = { canonicalUrl: string };
type StoryPageProps = { story: StoryData; viewer: ViewerData; responsePolicy: ResponsePolicy };

export default function StoryPage({ story, viewer, responsePolicy }: StoryPageProps) {
  return (
    <>
      <link rel="canonical" href={responsePolicy.canonicalUrl} />
      <Story story={story} viewer={viewer} />
    </>
  );
}
```

Use the same serialized key names that the TypeScript component consumes. React on Rails passes prop keys through by default, so these example props are already in camelCase for TypeScript. If your app uses `config.rendering_props_extension` or another custom serializer to change key casing, use the Ruby-side key names that your serializer expects and keep both sides aligned.

Native `<link>` hoisting requires React 19. On React 18, use `react-helmet` or emit canonical URLs from the Rails layout instead. See [React 19 Native Metadata](../building-features/react-19-native-metadata.md).

React can render metadata, route chrome, empty states, and branded error UI from these props. Rails remains the source of truth for the actual HTTP semantics.

## Checklist

- Decide redirects before rendering.
- Decide `404`, `410`, and authorization statuses before rendering.
- Set cache headers before the first streamed chunk.
- Set cookies and mutate session state before the first streamed chunk.
- Pass route decisions into RSC as serializable props.
- Keep Rails controllers, policies, and services responsible for authentication, authorization, and response policy.
- Use Client Component navigation only for browser-side transitions after a valid HTTP response exists.

## Next Steps

- [Third-Party Library Compatibility](rsc-third-party-libs.md) -- dealing with incompatible libraries
- [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md) -- debugging and avoiding problems
