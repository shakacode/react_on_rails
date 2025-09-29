# Improved Error Messages and Debugging

React on Rails now provides enhanced error messages with actionable solutions and debugging tools to help you quickly identify and fix issues.

## Features

### 1. Smart Error Messages

React on Rails now provides contextual error messages that:

- Identify the specific problem
- Suggest concrete solutions
- Provide code examples
- Offer similar component names when typos occur

### 2. Component Registration Debugging

Enable detailed logging to track component registration and identify issues.

### 3. Enhanced Prerender Errors

Server-side rendering errors now include specific troubleshooting steps based on the error type.

## Auto-Bundling: The Recommended Approach

React on Rails supports automatic bundling, which eliminates the need for manual component registration. This is the recommended approach for new projects and when adding new components.

### Benefits of Auto-Bundling

- **No manual registration**: Components are automatically available
- **Simplified development**: Just create the component file and use it
- **Better code organization**: Each component has its own directory
- **Automatic code splitting**: Each component gets its own bundle

### How to Use Auto-Bundling

1. **In your Rails view**, enable auto-bundling:

```erb
<%= react_component("YourComponent",
    props: { data: @data },
    auto_load_bundle: true) %>
```

2. **Place your component** in the correct directory structure:

```text
app/javascript/components/
└── YourComponent/
    └── YourComponent.jsx  # Must have export default
```

3. **Generate the bundles**:

```bash
bundle exec rake react_on_rails:generate_packs
```

### Configuration for Auto-Bundling

In `config/initializers/react_on_rails.rb`:

```ruby
ReactOnRails.configure do |config|
  # Set the components directory (default: "components")
  config.components_subdirectory = "components"

  # Enable auto-bundling globally (optional)
  config.auto_load_bundle = true
end
```

In `config/shakapacker.yml`:

```yaml
default: &default # Enable nested entries for auto-bundling
  nested_entries_dir: components
```

## Using Debug Mode

### JavaScript Configuration

Enable debug logging in your JavaScript entry file:

```javascript
// Enable debug mode for detailed logging
ReactOnRails.setOptions({
  debugMode: true,
  logComponentRegistration: true,
});

// Register your components
ReactOnRails.register({
  HelloWorld,
  ProductList,
  UserProfile,
});
```

With debug mode enabled, you'll see:

- Component registration timing
- Component sizes
- Registration confirmations
- Warnings about server/client mismatches

### Console Output Example

```text
[ReactOnRails] Debug mode enabled
[ReactOnRails] Component registration logging enabled
[ReactOnRails] Registering 3 component(s): HelloWorld, ProductList, UserProfile
[ReactOnRails] ✅ Registered: HelloWorld (~2.3kb)
[ReactOnRails] ✅ Registered: ProductList (~4.1kb)
[ReactOnRails] ✅ Registered: UserProfile (~3.8kb)
[ReactOnRails] Component registration completed in 12.45ms
```

## Common Error Scenarios

### Component Not Registered

**Old Error:**

```text
Component HelloWorld not found
```

**New Error:**

```text
❌ React on Rails Error: Component 'HelloWorld' Not Registered

Component 'HelloWorld' was not found in the component registry.

React on Rails offers two approaches:
• Auto-bundling (recommended): Components load automatically, no registration needed
• Manual registration: Traditional approach requiring explicit registration

💡 Suggested Solution:
Did you mean one of these? HelloWorldApp, HelloWorldComponent

🚀 Recommended: Use Auto-Bundling (No Registration Required!)

1. Enable auto-bundling in your view:
   <%= react_component("HelloWorld", props: {}, auto_load_bundle: true) %>

2. Place your component in the components directory:
   app/javascript/components/HelloWorld/HelloWorld.jsx

   Component structure:
   components/
   └── HelloWorld/
       └── HelloWorld.jsx (must export default)

3. Generate the bundle:
   bundle exec rake react_on_rails:generate_packs

✨ That's it! No manual registration needed.

─────────────────────────────────────────────

Alternative: Manual Registration

If you prefer manual registration:
1. Register in your entry file:
   ReactOnRails.register({ HelloWorld: HelloWorld });

2. Import the component:
   import HelloWorld from './components/HelloWorld';

📋 Context:
Component: HelloWorld
Registered components: HelloWorldApp, ProductList, UserProfile
Rails Environment: development (detailed errors enabled)
```

### Missing Auto-loaded Bundle

**Old Error:**

```text
ERROR ReactOnRails: Component "Dashboard" is configured as "auto_load_bundle: true" but the generated component entrypoint is missing.
```

**New Error:**

```text
❌ React on Rails Error: Auto-loaded Bundle Missing

Component 'Dashboard' is configured for auto-loading but its bundle is missing.
Expected location: /app/javascript/generated/Dashboard.js

💡 Suggested Solution:
1. Run the pack generation task:
   bundle exec rake react_on_rails:generate_packs

2. Ensure your component is in the correct directory:
   app/javascript/components/Dashboard/

3. Check that the component file follows naming conventions:
   - Component file: Dashboard.jsx or Dashboard.tsx
   - Must export default
```

### Server Rendering Error (Browser API)

**New Error with Contextual Help:**

```text
❌ React on Rails Server Rendering Error

Component: UserProfile

Error Details:
ReferenceError: window is not defined

💡 Troubleshooting Steps:
1. Browser API used on server - wrap with client-side check:
   if (typeof window !== 'undefined') { ... }

• Temporarily disable SSR to isolate the issue:
  prerender: false in your view helper
• Check server logs for detailed errors:
  tail -f log/development.log
```

### Hydration Mismatch

**New Error:**

```text
❌ React on Rails Error: Hydration Mismatch

The server-rendered HTML doesn't match what React rendered on the client.
Component: ProductList

💡 Suggested Solution:
Common causes and solutions:

1. **Random IDs or timestamps**: Use consistent values between server and client
   // Bad: Math.random() or Date.now()
   // Good: Use props or deterministic values

2. **Browser-only APIs**: Check for client-side before using:
   if (typeof window !== 'undefined') { ... }

3. **Different data**: Ensure props are identical on server and client
   - Check your redux store initialization
   - Verify railsContext is consistent

Debug tips:
- Set prerender: false temporarily to isolate the issue
- Check browser console for hydration warnings
- Compare server HTML with client render
```

## Ruby Configuration

### Enhanced Doctor Command

The doctor command now provides more detailed diagnostics:

```bash
$ rake react_on_rails:doctor

React on Rails Health Check v16.0
================================
✅ Node version: 18.17.0 (recommended)
✅ Rails version: 7.1.0 (compatible)
⚠️  Shakapacker: 7.0.0 (Rspack migration available)
✅ React version: 18.2.0
⚠️  TypeScript: Not detected (run: rails g react_on_rails:typescript)
❌ Component registration: 2 components not registered on client

Recommendations:
1. Consider migrating to Rspack for 3x faster builds
2. Enable TypeScript for better type safety
3. Check components: ProductList, UserProfile
```

## Configuration Options

### JavaScript Options

```javascript
ReactOnRails.setOptions({
  // Enable full debug mode
  debugMode: true,

  // Log component registration details only
  logComponentRegistration: true,

  // Existing options
  traceTurbolinks: false,
  turbo: false,
});
```

### Rails Configuration

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  # Enable detailed error traces in development
  config.trace = Rails.env.development?

  # Raise errors during prerendering for debugging
  config.raise_on_prerender_error = Rails.env.development?

  # Show full error messages
  ENV["FULL_TEXT_ERRORS"] = "true" if Rails.env.development?
end
```

## Best Practices

1. **Development Environment**: Always enable debug mode and detailed errors in development
2. **Production Environment**: Disable debug logging but keep error reporting
3. **Testing**: Use the enhanced error messages to quickly identify test failures
4. **CI/CD**: Enable FULL_TEXT_ERRORS in CI for complete error traces

## Troubleshooting Tips

### Quick Debugging Checklist

1. **Component not rendering?**

   - Enable debug mode: `ReactOnRails.setOptions({ debugMode: true })`
   - Check browser console for registration logs
   - Verify component is registered on both server and client

2. **Server rendering failing?**

   - Set `prerender: false` to test client-only rendering
   - Check for browser-only APIs (window, document, localStorage)
   - Review server logs: `tail -f log/development.log`

3. **Hydration warnings?**

   - Look for non-deterministic values (Math.random, Date.now)
   - Check for browser-specific conditionals
   - Ensure props match between server and client

4. **Bundle not found?**
   - Run `bundle exec rake react_on_rails:generate_packs`
   - Verify component location and naming
   - Check webpack/shakapacker configuration

## Migration from Previous Versions

If upgrading from an earlier version of React on Rails:

1. The new error messages are automatically enabled
2. No configuration changes required
3. Existing error handling code continues to work
4. Consider enabling debug mode for better development experience

## Support

If you encounter issues not covered by the enhanced error messages:

- 🚀 Professional Support: react_on_rails@shakacode.com
- 💬 React + Rails Slack: [https://invite.reactrails.com](https://invite.reactrails.com)
- 🆓 GitHub Issues: [https://github.com/shakacode/react_on_rails/issues](https://github.com/shakacode/react_on_rails/issues)
- 📖 Discussions: [https://github.com/shakacode/react_on_rails/discussions](https://github.com/shakacode/react_on_rails/discussions)
