# JSON Race Condition Demo

Reproduces the race condition in React on Rails Pro's `immediate_hydration` feature.

**Issue:** https://github.com/shakacode/react_on_rails/issues/2283

## The Bug

When `immediate_hydration` is enabled, React on Rails Pro reads JSON props from `<script type="application/json">` tags **immediately** when the JS bundle executes, without waiting for the DOM to be fully loaded.

On slow networks with large props, the HTML streams in chunks. If JavaScript executes before all chunks arrive, `el.textContent` returns truncated JSON:

```
SyntaxError: Unterminated string in JSON at position XXXXX
```

## Two Demo Versions

### `server-v2.rb` (Recommended - Accurate reproduction)

This version accurately reproduces the React on Rails architecture:
- External async script in `<head>` (like client-bundle.js)
- JSON script tag in `<body>`
- Server uses chunked transfer encoding with deliberate delays
- No browser throttling needed - server simulates slow streaming

```bash
ruby server-v2.rb
# Open http://localhost:4568
```

### `server.rb` (Simpler - requires browser throttling)

Simpler demo that requires browser network throttling:

```bash
ruby server.rb
# Open http://localhost:4567
# Set Chrome DevTools → Network → Throttle to "Slow 3G"
```

## Why server-v2.rb is More Accurate

| Aspect | server.rb | server-v2.rb |
|--------|-----------|--------------|
| JS location | Inline `<script>` | External `<script async>` |
| JSON location | After inline JS | Before external JS executes |
| Streaming | Requires browser throttling | Server chunks with delays |
| Matches RoR? | No | Yes |

The real bug happens when:
1. JSON script tag **exists** in DOM (browser parsed opening tag)
2. But its **content is incomplete** (closing `</script>` not received)
3. External async JS reads `textContent` → truncated JSON

## Timeline of the Bug

```
Server streams HTML via chunked transfer encoding:

[Chunk 1] <head><script src="bundle.js" async></head><body>...
          <script type="application/json">{"items":[
              │
              │ ← Browser starts downloading bundle.js
              │
[Chunk 2]     {"id":0,"name":"Item 0"...
              │
              │ ← bundle.js finishes downloading, EXECUTES NOW
              │   document.querySelector('.js-react-on-rails-component')
              │   → Found! (opening tag was in chunk 1)
              │   el.textContent → '{"items":[{"id":0,"name":"Item 0"...'
              │   → TRUNCATED! (chunks 3-4 not received)
              │   JSON.parse() → ERROR
              │
[Chunk 3]     ...more items...
[Chunk 4]     ...]}}</script></body>
```

## Playwright Test

For automated testing:

```bash
cd react_on_rails_pro/spec/dummy
pnpm e2e-test e2e-tests/large_props_stress_test.spec.ts -g "EXTREME"
```

## The Fix

The fix should ensure JSON script tags are fully loaded before parsing:

1. **Wait for DOMContentLoaded** - Guarantees all HTML is parsed
2. **Check for closing tag** - Verify `</script>` has been parsed
3. **Validate JSON structure** - Check for balanced braces before parsing
4. **Use MutationObserver** - Wait for script tag content to stabilize
