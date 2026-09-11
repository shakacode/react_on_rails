# System Specs for Streamed RSC Payloads

Use this guide when a Rails system spec needs to verify that the browser consumes a streamed React Server
Components payload from `rsc_payload_route`, `rsc_payload_react_component`, `stream_react_component`, or
`stream_react_component_with_async_props`.

Before writing these specs, wire the Rails test process, test bundles, and node renderer using the
[RSC and Node Renderer System Tests](../../oss/building-features/testing-configuration.md#rsc-and-node-renderer-system-tests)
recipe.

## Transport Requirement

The RSC payload request must reach the browser as the live response from the Rails app or node-renderer path.
Do not stub, cache, replay, or buffer that request in a browser proxy. If the payload is buffered until
completion, the browser-side RSC client may never observe the chunks that unblock hydration. The system spec can
then hang even though the server generated a valid response.

Common symptoms:

- the page HTML renders, but the browser never reaches the hydrated state;
- the RSC payload request stays `inflight` or completes only after the spec times out;
- browser console logs show a pending Flight decode or missing client reference after the payload route returned
  successfully on the server.

## Choose the Test Topology

Choose the owner of the application runtime before you choose the browser assertions:

| Situation                                                                                                                                                     | Recommended owner                                               |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| Rails' normal system-test server can reach the renderer, no custom application processes run inside examples, and the test needs a simple hydration assertion | Capybara with a non-buffering driver is acceptable              |
| The test needs a separately launched Rails server or node renderer                                                                                            | E2E on Rails + Playwright                                       |
| Test data must be visible across process or database connections                                                                                              | E2E on Rails app commands or scenarios                          |
| Streaming HTTP, Action Cable, exact network counts, failed-resource checks, or traces are central assertions                                                  | Playwright                                                      |
| The app already uses Playwright for ShakaPerf, visual regression, or other browser verification                                                               | Reuse Playwright instead of adding a custom Capybara runtime    |
| Puffing Billy or another external proxy is needed for unrelated APIs                                                                                          | Keep those tests separate; do not proxy or cache the RSC stream |

Capybara is not generally incompatible with RSC. It is a good fit when Rails manages the system-test server and
that server can reach the renderer. If you would need to start a separate Rails origin or renderer around each
example, stop extending the Capybara harness and use the multi-process path below.

## Capybara Shape for a Rails-managed Runtime

Use a non-Billy browser driver for specs that assert streamed RSC behavior. If your suite's default JavaScript
driver is already a plain Selenium driver, you can use it directly. Otherwise, register a dedicated driver for
RSC streaming assertions and keep Puffing Billy for specs that need browser-side external request stubbing.

```ruby
# spec/support/capybara_rsc_streaming.rb
Capybara.register_driver :selenium_chrome_rsc_streaming do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new") if ENV["HEADLESS"] != "false"
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--no-sandbox") if ENV["CI"]

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
```

```ruby
RSpec.describe "public RSC pages", :rsc, :js, type: :system do
  driven_by :selenium_chrome_rsc_streaming

  it "hydrates the streamed RSC payload" do
    visit "/"

    expect(page).to have_css("[data-rsc-ready='true']")
  end
end
```

Use an app-specific ready marker or interaction. The important assertion is that the browser finished consuming
the Flight payload, not merely that the initial static HTML was present.

Good assertions include:

- a client island becomes interactive and responds to a click;
- an app-owned hydration marker appears after the client boundary finishes;
- a Suspense fallback is replaced by streamed content and the related client control works.

## E2E on Rails + Playwright for a Multi-process Runtime

Use [E2E on Rails](https://e2eonrails.com/) with Playwright when a test needs an external Rails server, a node
renderer, cross-process Rails data setup, or detailed streaming and network evidence. Follow the canonical
[Streamed and Multi-process Applications](https://e2eonrails.com/docs/STREAMING_AND_MULTI_PROCESS_APPS/) guide for
the full setup. Keep this React on Rails guide focused on the RSC transport boundary.

```text
focused RSC E2E run
  -> start and wait for the node renderer
  -> start and wait for one Rails test server
  -> run the configured Playwright desktop and mobile projects
       -> E2E on Rails command resets and creates Rails data
       -> fresh browser context exercises the real RSC stream
       -> assert hydration, interaction, console, failed resources, and network
  -> stop Rails
  -> stop the renderer
```

Keep these responsibilities separate:

- React on Rails owns the RSC route, renderer configuration, and streaming contract.
- The consuming app owns process commands, dependency ordering, readiness checks, logs, and cleanup.
- E2E on Rails owns Rails-side app commands and state setup.
- Playwright owns browser contexts, traces, console and page errors, failed resources, and network assertions.

> **Lifecycle rule:** Do not start and stop the Rails server or RSC renderer around individual examples or
> retries. Keep one application topology alive for the focused E2E run. Reset browser contexts and application
> data between tests, and stop application processes only after the run.

Streamed chunks and browser resource requests can outlive the assertion that appears to finish a test. Killing the
origin during reset can create late chunk errors, attribute a failure to the next test, and make retries look more
stable than the underlying system.

### Make Test Data Visible to Rails

A separate Rails server uses another process and database connection. It normally cannot see records inside an
RSpec example's uncommitted transaction. Do not use committed `before(:all)` fixtures as the default workaround.

Create and reset data inside the serving Rails process through E2E on Rails
[app commands](https://e2eonrails.com/docs/app-commands/) or
[scenarios](https://e2eonrails.com/docs/scenarios/). Transaction-sharing modes require every participating
process, thread, and connection to support the same assumptions; they are not a general multi-process solution.

## Puffing Billy Compatibility

Puffing Billy is an HTTP proxy for browser requests. Its
[README](https://github.com/oesmith/puffing-billy) describes Capybara drivers with `_billy`
suffixes, proxied unstubbed requests, cache configuration for requests routed through the proxy, and
request log handlers such as `proxy`, `stubs`, `cache`, `error`, and `inflight`.

That model is useful for external browser API calls, but it is a poor default for streamed RSC payload routes. For
specs that must verify streaming:

- do not run the spec with a `_billy` Capybara driver;
- do not stub the RSC payload URL;
- keep RSC payload paths out of `path_blacklist`, `cache_whitelist`, `merge_cached_responses_whitelist`, and any
  persistent cache fixtures;
- do not treat Billy `whitelist` entries as streaming proof. Whitelisting keeps local app URLs from being cached
  by default, but the browser request can still be routed through the proxy layer;
- if a spec needs both external browser stubs and streamed RSC payloads, prefer server-side stubs in the Rails
  process, a local fake service, or a separate non-Billy spec for the RSC assertion.

For remote Chrome, proxy bypass rules are host-oriented rather than route-aware. Bypassing the Capybara app host
can keep `/rsc_payload` out of the Billy proxy, but it also means Billy will not observe other browser requests to
that same app host. Prefer registering a dedicated non-Billy RSC driver unless the suite has a well-tested reason
to share the Billy driver.

When diagnosing an existing Billy-backed spec, temporarily enable request recording and inspect the Billy log. A
streamed RSC payload handled by `cache`, `stubs`, `error`, or left `inflight` is not a passing transport setup. A
`proxy` handler is better, but still needs an end-to-end hydration assertion because proxying alone does not prove
chunk delivery to the browser.

## Verification Checklist

For app-specific system specs:

1. Visit the RSC route with a non-Billy streaming driver.
2. Wait for an app-owned hydrated marker, visible client-island behavior, or streamed content replacement.
3. Confirm the RSC payload route was served by the app under test, not by a Billy stub or cache.
4. Keep external API stubbing separate from the RSC payload transport check.

For a multi-process Playwright test, also:

1. Fail on unexpected `console.error` messages, page errors or unhandled rejections, failed RSC chunks, and failed
   resources.
2. Capture a Playwright trace, screenshot or video, Rails logs, and renderer logs when a test fails.
3. Verify that one stable Rails origin and one stable renderer origin serve the focused run.
4. Run the same source tests in each required desktop and mobile project.
5. Treat retries as diagnostic evidence, not proof of stability.
6. After migration parity, delete superseded browser specs and custom runtime helpers instead of maintaining two
   sources of truth.

Request specs for `/rsc_payload/:component_name` are still useful for status codes, content type, and payload
shape, but they do not prove browser streaming. Pair request specs with at least one browser assertion when the
behavior depends on hydration or progressive Flight chunk delivery.

If the app can only reproduce a failure with Puffing Billy in front of the RSC payload route, keep that spec
skipped or pending and link the skip to the app-specific proxy limitation. Do not treat a buffered proxy path as a
supported RSC transport.
