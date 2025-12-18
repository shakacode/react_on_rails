# Improved Error Messages for React on Rails

React on Rails provides enhanced error messages with actionable solutions to help you quickly identify and fix issues.

## Smart Error Messages

React on Rails now provides contextual error messages that:

- Identify the specific problem
- Suggest concrete solutions with code examples
- Offer similar component names when typos occur
- Prioritize auto-bundling as the recommended approach

## Auto-Bundling: The Recommended Approach

React on Rails supports automatic bundling, which eliminates the need for manual component registration.

### Benefits of Auto-Bundling

- **No manual registration**: Components are automatically available
- **Simplified development**: Just create the component file and use it
- **Automatic code splitting**: Each component gets its own bundle
- **Better performance**: Only load what you need

### How to Use Auto-Bundling

1. **Enable in your view:**

   ```erb
   <%= react_component("MyComponent", props: { data: @data }, auto_load_bundle: true) %>
   ```

2. **Place component in the correct directory:**

   ```
   app/javascript/components/
   └── MyComponent/
       └── MyComponent.jsx  # Must export default
   ```

3. **Generate bundles:**
   Bundles are automatically generated during asset precompilation via the Shakapacker precompile hook. For manual generation during development:
   ```bash
   bundle exec rake react_on_rails:generate_packs
   ```

That's it! No manual registration needed.

## Error Message Examples

### Component Not Registered

**Before:**

```
Component 'HelloWorld' not found
```

**After:**

````
❌ React on Rails Error

🔍 Problem:
Component 'HelloWorld' was not found in the component registry.

💡 Suggested Solution:

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

3. Include the bundle in your layout (e.g., `app/views/layouts/application.html.erb`):
   ```erb
   <%= javascript_pack_tag 'application' %>
   <%= stylesheet_pack_tag 'application' %>
   ```
````

### Enhanced SSR Errors

Server-side rendering errors now include:

- Colored, formatted output for better readability
- Specific error patterns detection (window/document undefined, hydration mismatches)
- Actionable troubleshooting steps
- Props and JavaScript code context
- Console message replay

**Example SSR Error:**

```

❌ React on Rails Server Rendering Error

Component: HelloWorldApp

📋 Error Details:
ReferenceError: window is not defined

💡 Troubleshooting Suggestions:

⚠️ Browser API (window/document) accessed during server render

The component tried to access 'window' which doesn't exist on the server.

Solutions:
• Wrap browser API calls in useEffect:
useEffect(() => { /_ DOM operations here _/ }, [])

• Check if running in browser:
if (typeof window !== 'undefined') { /_ browser code _/ }

• Use dynamic import for browser-only code
```

## Ruby Configuration

### Using SmartError Directly

You can create custom smart errors in your Rails code:

```ruby
raise ReactOnRails::SmartError.new(
  error_type: :component_not_registered,
  component_name: "MyComponent",
  additional_context: {
    available_components: ReactOnRails::PackerUtils.registered_components
  }
)
```

### Error Types

Available error types:

- `:component_not_registered` - Component not found in registry
- `:missing_auto_loaded_bundle` - Auto-bundle file not found
- `:hydration_mismatch` - Client/server HTML mismatch
- `:server_render_error` - General SSR error
- `:configuration_error` - Invalid configuration

## Best Practices

1. **Prefer auto-bundling** for new components to avoid registration issues
2. **Use server-side rendering** to catch React component errors, hydration mismatches, and SSR-specific issues (like accessing browser APIs) during development before they reach production
3. **Check error messages carefully** - they include specific solutions
4. **Keep components in standard locations** for better error detection

## Troubleshooting

If you encounter issues:

1. **Check component registration:**

   ```bash
   bundle exec rake react_on_rails:doctor
   ```

2. **Verify auto-bundle generation:**

   ```bash
   bundle exec rake react_on_rails:generate_packs
   ```

3. **Enable detailed errors** in development:
   ```bash
   FULL_TEXT_ERRORS=true rails server
   ```

## Related Documentation

- [Auto-Bundling Guide](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md)
- [Server Rendering](../core-concepts/react-server-rendering.md)
- [JavaScript API (Component Registration)](../api-reference/javascript-api.md)
