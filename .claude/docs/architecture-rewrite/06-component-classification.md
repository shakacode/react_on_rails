# New Architecture: Unified Component Classification

## Design Principle

Replace the two orthogonal classification systems (file suffixes + `'use client'` directive) with a **single, declarative classification** that makes intent explicit and eliminates file I/O during pack generation.

## Current Problem Recap

### System 1: Bundle Placement (file suffixes)

| Suffix        | Client Bundle | Server Bundle | RSC Bundle |
| ------------- | :-----------: | :-----------: | :--------: |
| `.client.jsx` |      Yes      |      No       |     No     |
| `.server.jsx` |      No       |      Yes      |    Yes     |
| No suffix     |      Yes      |      Yes      |    Yes     |

### System 2: RSC Classification (`'use client'` directive)

| Directive          | Registration method            |
| ------------------ | ------------------------------ |
| Has `'use client'` | `ReactOnRails.register(...)`   |
| No directive       | `registerServerComponent(...)` |

These are independent, producing a confusing 2x3 matrix where some combinations are nonsensical.

### Additional overhead

- `client_entrypoint?` reads each file from disk to detect `'use client'`
- `warn_if_likely_client_component` runs regex against file contents
- Pack generation does multiple glob passes with different filters

## Proposed: Single Classification with Convention

### New convention

A component's classification is determined by **one attribute**: its file suffix.

| Suffix            | Bundle Placement |        RSC Role        |     Generated Registration     |
| ----------------- | :--------------: | :--------------------: | :----------------------------: |
| `.client.jsx/tsx` |   Client only    | React Client Component |  `ReactOnRails.register(...)`  |
| `.server.jsx/tsx` |   Server + RSC   | React Server Component | `registerServerComponent(...)` |
| No suffix         |   All bundles    | React Client Component |  `ReactOnRails.register(...)`  |

The key insight: **the `'use client'` directive is redundant with the file suffix**. If a file is `.server.jsx`, it's a server component. If it's `.client.jsx` or unsuffixed, it's a client component. We don't need to read the file to determine this.

### What about `'use client'` in unsuffixed files?

For backward compatibility:

- Unsuffixed files that have `'use client'` continue to work — they're already client components by default
- Unsuffixed files that lack `'use client'` are also treated as client components (no change for non-RSC users)
- Only `.server.jsx` files are treated as server components

This means `'use client'` becomes documentation, not a classification signal. The file suffix is the single source of truth.

### When RSC is disabled

When `enable_rsc_support = false` (the default), the classification simplifies further:

| Suffix            | Bundle Placement |    Generated Registration    |
| ----------------- | :--------------: | :--------------------------: |
| `.client.jsx/tsx` |   Client only    | `ReactOnRails.register(...)` |
| `.server.jsx/tsx` |   Server only    | `ReactOnRails.register(...)` |
| No suffix         |   All bundles    | `ReactOnRails.register(...)` |

All components use `ReactOnRails.register(...)`. The suffix only controls which webpack bundle includes them.

## Implementation: Unified ComponentClassifier

```ruby
module ReactOnRails
  class ComponentClassifier
    SUFFIXES = {
      client: /\.client\.(jsx?|tsx?)$/,
      server: /\.server\.(jsx?|tsx?)$/
    }.freeze

    def initialize(rsc_enabled:)
      @rsc_enabled = rsc_enabled
    end

    # Classify a component file into its type.
    #
    # @param file_path [String] Path to the component file
    # @return [ComponentType] Classification result
    def classify(file_path)
      suffix = detect_suffix(file_path)
      ComponentType.new(
        suffix: suffix,
        bundles: bundles_for(suffix),
        registration: registration_for(suffix)
      )
    end

    private

    def detect_suffix(file_path)
      case file_path
      when SUFFIXES[:client] then :client
      when SUFFIXES[:server] then :server
      else :universal
      end
    end

    def bundles_for(suffix)
      case suffix
      when :client then [:client]
      when :server then @rsc_enabled ? [:server, :rsc] : [:server]
      when :universal then @rsc_enabled ? [:client, :server, :rsc] : [:client, :server]
      end
    end

    def registration_for(suffix)
      if @rsc_enabled && suffix == :server
        :server_component  # registerServerComponent(...)
      else
        :standard          # ReactOnRails.register(...)
      end
    end
  end

  class ComponentType
    attr_reader :suffix, :bundles, :registration

    def initialize(suffix:, bundles:, registration:)
      @suffix = suffix
      @bundles = bundles
      @registration = registration
    end

    def client_bundle?
      bundles.include?(:client)
    end

    def server_bundle?
      bundles.include?(:server)
    end

    def rsc_bundle?
      bundles.include?(:rsc)
    end

    def server_component?
      registration == :server_component
    end
  end
end
```

## Pack Generation Simplification

### Current: Multiple glob passes with file I/O

```ruby
# packs_generator.rb (simplified)
def generate_packs
  common_files = glob_components.grep_v(CLIENT_OR_SERVER_REGEX)   # Pass 1
  client_files = glob_components.grep(CLIENT_REGEX)                # Pass 2
  server_files = glob_components.grep(SERVER_REGEX)                # Pass 3

  common_files.each do |file|
    if rsc_enabled && !client_entrypoint?(file)  # File I/O!
      generate_server_component_pack(file)
    else
      generate_standard_pack(file)
    end
  end
  # ... similar for client_files and server_files
end
```

### Proposed: Single pass with classifier

```ruby
def generate_packs
  classifier = ComponentClassifier.new(rsc_enabled: rsc_enabled?)
  component_files = glob_component_directory

  component_files.each do |file_path|
    component_type = classifier.classify(file_path)
    generate_pack(file_path, component_type)
  end
end

def generate_pack(file_path, component_type)
  component_name = extract_name(file_path)

  component_type.bundles.each do |bundle|
    pack_path = pack_path_for(component_name, bundle)
    content = if component_type.server_component?
                server_component_pack_content(file_path, component_name)
              else
                standard_pack_content(file_path, component_name)
              end
    write_pack(pack_path, content)
  end
end
```

Benefits:

- **Single glob operation** instead of 3+
- **No file I/O for classification** — suffix determines everything
- **Linear processing** — one pass over all files
- **Explicit classification** — `ComponentType` object carries all decisions

## Removing the Heuristic Warning

The current `warn_if_likely_client_component` method uses regex to detect client-only APIs:

```ruby
LIKELY_CLIENT_COMPONENT_REGEX = /\b(useState|useEffect|useLayoutEffect|...)\b/
```

This is a fragile heuristic. In the new system, we remove it entirely. If a user puts `useState` in a `.server.jsx` file, the React runtime will give them a clear error at render time. We don't need to duplicate that warning at the pack generation level.

## Backward Compatibility

### For non-RSC users (majority)

Zero change. The suffix convention already works as described. `'use client'` is already irrelevant for them.

### For RSC users

The only behavioral change: unsuffixed files without `'use client'` that were previously treated as server components (because they lacked the directive) will now be treated as client components (because they're unsuffixed).

Migration: RSC users should ensure their server components use the `.server.jsx` suffix. This is already a best practice documented in the guides.

### Deprecation path

1. Log a warning if an unsuffixed file is detected without `'use client'` in an RSC-enabled project:
   ```
   [ReactOnRails] Component 'Foo.jsx' has no file suffix and no 'use client' directive.
   In a future version, it will be treated as a client component.
   Add '.server' suffix to make it a server component, or add 'use client' to silence this warning.
   ```
2. After one major version, remove the warning and the `'use client'` check entirely.

## Summary

| Aspect                         | Current                    | Proposed                          |
| ------------------------------ | -------------------------- | --------------------------------- |
| Classification systems         | 2 (suffix + directive)     | 1 (suffix only)                   |
| File I/O during classification | Yes (`File.read` per file) | No                                |
| Glob passes                    | 3+                         | 1                                 |
| Heuristic warnings             | Yes (regex-based)          | No                                |
| RSC classification             | `'use client'` directive   | `.server` suffix                  |
| Data model                     | Implicit (method returns)  | Explicit (`ComponentType` object) |
