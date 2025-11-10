# React on Rails TODO

## Generator Improvements

### HelloWorld Component Structure

- [x] Fix bad import in HelloWorld.server.jsx (server importing from client)
- [x] Simplify to single HelloWorld.jsx file with documentation
- [ ] **Consider alternative approach**: Create second example component showing client/server split
  - Add `client_server_different.jsx` in sibling directory like `/examples/` or `/advanced/`
  - Show real-world use case (React Router, styled-components, etc.)
  - Keep HelloWorld simple for beginners

### File Organization

- [x] **Improved ror_components directory structure**
  - Documentation now suggests moving shared components to `../components/` directory
  - Keeps ror_components clean for React on Rails specific entry points
  - Recommended structure:
    ```
    src/HelloWorld/
    ├── components/
    │   └── HelloWorld.jsx          # Shared component implementation
    └── ror_components/
        ├── HelloWorld.client.jsx   # Client entry point (when needed)
        └── HelloWorld.server.jsx   # Server entry point (when needed)
    ```
- [ ] **Consider adding generator flag to create this structure automatically**

### Generator Options

- [ ] **Add generator flags for different patterns**
  - `--simple` (default): Single component file
  - `--split`: Generate client/server split example
  - `--example-name`: Customize component name beyond HelloWorld

## Documentation Improvements

### Component Architecture Guide

- [ ] **Add comprehensive docs on client/server patterns**
  - When to use single vs split files
  - Common libraries requiring server setup (React Router, styled-components, Apollo)
  - Migration path from simple to split architecture
  - Auto-registration behavior explanation

### Code Comments

- [x] Add inline documentation to HelloWorld.jsx explaining split pattern
- [ ] Add JSDoc comments for better IDE support
- [ ] Include links to relevant documentation sections

## Testing Infrastructure

- [ ] **Test generator output for both simple and split patterns**
- [ ] **Validate that auto-registration works correctly**
- [ ] **Add integration tests for client/server rendering differences**

## Developer Experience

- [ ] **bin/dev help command enhancements**

  - [x] Add emojis and colors for better readability
  - [ ] Add section about component development patterns
  - [ ] Include troubleshooting for client/server split issues

- [ ] **Babel Configuration Conflict Detection**

  - [ ] Add validation in generator/initializer to detect conflicting Babel configs
  - [ ] Improve error messaging for duplicate preset issues
  - [ ] Common conflict: babel.config.js + package.json "babel" section
  - [ ] Specific guidance for yalc development workflow
  - [ ] Add troubleshooting section for this common issue:

    ```
    ❌ BABEL CONFIGURATION CONFLICT DETECTED
    Found duplicate Babel configurations:
    • babel.config.js ✓ (recommended)
    • package.json "babel" section ❌ (conflicting)

    🔧 FIX: Remove the "babel" section from package.json
    ```

### IDE Support

- [ ] **Improve TypeScript support**
  - Add .d.ts files for better type inference
  - Document TypeScript patterns for client/server split
  - Consider TypeScript generator templates

## Performance & Bundle Analysis

- [ ] **Bundle splitting documentation**
  - How React on Rails handles client/server bundles
  - Best practices for code splitting
  - webpack bundle analysis guidance

## Real-World Examples

- [ ] **Create example apps showing advanced patterns**
  - React Router with SSR
  - styled-components with server-side rendering
  - Apollo Client hydration
  - Next.js-style patterns

## Migration Guide

- [ ] **Document upgrade paths**
  - Converting from Webpacker to Shakapacker
  - Migrating from single to split components
  - Updating existing projects to new patterns

## Community & Ecosystem

- [ ] **Plugin ecosystem considerations**
  - Standard patterns for community components
  - Guidelines for React on Rails compatible libraries
  - Template repository for component patterns

---

## Current Known Issues

- Generator installer still has remaining issues (mentioned in context)
- Version mismatch warnings with yalc during development
- Need clearer documentation on when to use different patterns
- **Babel configuration conflicts** - Common during yalc development when package.json and babel.config.js both define presets

## Priority Order

1. Fix remaining generator installer issues
2. Improve HelloWorld component documentation
3. Add alternative example showing client/server split
4. Create comprehensive architecture documentation
5. Add generator flags for different patterns
