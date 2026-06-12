---
title: Error Reference
---

<!-- GENERATED FILE - DO NOT EDIT DIRECTLY. -->
<!-- Regenerate with: BUNDLE_GEMFILE=react_on_rails/Gemfile bundle exec ruby script/generate_error_reference.rb -->
<!-- Source: react_on_rails/lib/react_on_rails/smart_error.rb -->

# Error Reference

React on Rails SmartError messages include stable `ROR###` codes and canonical URLs. Use this page to look up a code from a terminal error, server log, or support request.

Error codes are append-only once published: do not reuse a removed code for a different failure.

## Code Index

| Code              | Error                            | SmartError type                     |
| ----------------- | -------------------------------- | ----------------------------------- |
| [ROR001](#ror001) | Component Not Registered         | `:component_not_registered`         |
| [ROR002](#ror002) | Auto-loaded Bundle Missing       | `:missing_auto_loaded_bundle`       |
| [ROR003](#ror003) | Auto-loaded Store Bundle Missing | `:missing_auto_loaded_store_bundle` |
| [ROR004](#ror004) | Hydration Mismatch               | `:hydration_mismatch`               |
| [ROR005](#ror005) | Server Rendering Failed          | `:server_rendering_error`           |
| [ROR006](#ror006) | Redux Store Not Found            | `:redux_store_not_found`            |
| [ROR007](#ror007) | Configuration Error              | `:configuration_error`              |

<a id="ror001"></a>

## ROR001: Component Not Registered

**SmartError type:** `:component_not_registered`

**Canonical URL:** https://reactonrails.com/docs/reference/error-reference#ror001

React on Rails could not find the component in the client-side component registry.

### Example SmartError Output

```text
❌ React on Rails Error [ROR001]: Component 'ProductCard' Not Registered

Component 'ProductCard' was not found in the component registry.

React on Rails offers two approaches:
• Auto-bundling (recommended): Components load automatically, no registration needed
• Manual registration: Traditional approach requiring explicit registration


Code: ROR001
Docs: https://reactonrails.com/docs/reference/error-reference#ror001

💡 Suggested Solution:
🚀 Recommended: Use Auto-Bundling (No Registration Required!)

1. Enable auto-bundling in your view:
   <%= react_component("ProductCard", props: {}, auto_load_bundle: true) %>

2. Place your component in the components directory:
   app/javascript/components/ProductCard/ProductCard.jsx

   Component structure:
   components/
   └── ProductCard/
       └── ProductCard.jsx (must export default)

3. Generate the bundle:
   bundle exec rake react_on_rails:generate_packs

✨ That's it! No manual registration needed.

─────────────────────────────────────────────

Alternative: Manual Registration

If you prefer manual registration:
1. Register in your entry file:
   ReactOnRails.register({ ProductCard: ProductCard });

2. Import the component:
   import ProductCard from './components/ProductCard';



📋 Context:
Component: ProductCard
Registered components: ProductList, ProductDetails, UserProfile
Rails Environment: development (detailed errors enabled)

🔧 Need More Help?
📞 Get Help & Support:
   • 🚀 Professional Support: react_on_rails@shakacode.com (fastest resolution)
   • 💬 React + Rails Slack: https://invite.reactrails.com
   • 🆓 GitHub Issues: https://github.com/shakacode/react_on_rails/issues
   • 📖 Discussions: https://github.com/shakacode/react_on_rails/discussions
```

<a id="ror002"></a>

## ROR002: Auto-loaded Bundle Missing

**SmartError type:** `:missing_auto_loaded_bundle`

**Canonical URL:** https://reactonrails.com/docs/reference/error-reference#ror002

A component is configured for auto-loading, but its generated bundle is missing.

### Example SmartError Output

```text
❌ React on Rails Error [ROR002]: Auto-loaded Bundle Missing

Component 'Dashboard' is configured for auto-loading but its bundle is missing.
Expected location: app/javascript/packs/generated/Dashboard.js


Code: ROR002
Docs: https://reactonrails.com/docs/reference/error-reference#ror002

💡 Suggested Solution:
1. Run the pack generation task:
   bundle exec rake react_on_rails:generate_packs

2. Ensure your component is in the correct directory:
   app/javascript/components/Dashboard/

3. Check that the component file follows naming conventions:
   - Component file: Dashboard.jsx or Dashboard.tsx
   - Must export default

4. Verify webpack/shakapacker is configured for nested entries:
   config.nested_entries_dir = 'components'



📋 Context:
Component: Dashboard
Rails Environment: development (detailed errors enabled)

🔧 Need More Help?
📞 Get Help & Support:
   • 🚀 Professional Support: react_on_rails@shakacode.com (fastest resolution)
   • 💬 React + Rails Slack: https://invite.reactrails.com
   • 🆓 GitHub Issues: https://github.com/shakacode/react_on_rails/issues
   • 📖 Discussions: https://github.com/shakacode/react_on_rails/discussions
```

<a id="ror003"></a>

## ROR003: Auto-loaded Store Bundle Missing

**SmartError type:** `:missing_auto_loaded_store_bundle`

**Canonical URL:** https://reactonrails.com/docs/reference/error-reference#ror003

A Redux store is configured for auto-loading, but its generated store bundle is missing.

### Example SmartError Output

```text
❌ React on Rails Error [ROR003]: Auto-loaded Store Bundle Missing

Redux store 'AppStore' is configured for auto-loading but its bundle is missing.
Expected location: app/javascript/packs/generated/AppStore.js


Code: ROR003
Docs: https://reactonrails.com/docs/reference/error-reference#ror003

💡 Suggested Solution:
1. Run the pack generation task:
   bundle exec rake react_on_rails:generate_packs

2. Ensure your store is in a directory matching stores_subdirectory under packer_source_path:
   app/javascript/**/ror_stores/AppStore.js

3. Check that the store file follows naming conventions:
   - Store file: AppStore.js or AppStore.ts
   - Must export default a store generator function

4. Verify stores_subdirectory is configured:
   config.stores_subdirectory = 'ror_stores'



📋 Context:
Component: AppStore
Rails Environment: development (detailed errors enabled)

🔧 Need More Help?
📞 Get Help & Support:
   • 🚀 Professional Support: react_on_rails@shakacode.com (fastest resolution)
   • 💬 React + Rails Slack: https://invite.reactrails.com
   • 🆓 GitHub Issues: https://github.com/shakacode/react_on_rails/issues
   • 📖 Discussions: https://github.com/shakacode/react_on_rails/discussions
```

<a id="ror004"></a>

## ROR004: Hydration Mismatch

**SmartError type:** `:hydration_mismatch`

**Canonical URL:** https://reactonrails.com/docs/reference/error-reference#ror004

The server-rendered HTML does not match the React tree rendered in the browser.

### Example SmartError Output

```text
❌ React on Rails Error [ROR004]: Hydration Mismatch

The server-rendered HTML doesn't match what React rendered on the client.
Component: UserProfile


Code: ROR004
Docs: https://reactonrails.com/docs/reference/error-reference#ror004

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

4. **Conditional rendering**: Avoid using user agent or viewport checks

Debug tips:
- Set prerender: false temporarily to isolate the issue
- Check browser console for hydration warnings
- Compare server HTML with client render



📋 Context:
Component: UserProfile
Rails Environment: development (detailed errors enabled)

🔧 Need More Help?
📞 Get Help & Support:
   • 🚀 Professional Support: react_on_rails@shakacode.com (fastest resolution)
   • 💬 React + Rails Slack: https://invite.reactrails.com
   • 🆓 GitHub Issues: https://github.com/shakacode/react_on_rails/issues
   • 📖 Discussions: https://github.com/shakacode/react_on_rails/discussions
```

<a id="ror005"></a>

## ROR005: Server Rendering Failed

**SmartError type:** `:server_rendering_error`

**Canonical URL:** https://reactonrails.com/docs/reference/error-reference#ror005

Server-side rendering failed while rendering a React component.

### Example SmartError Output

```text
❌ React on Rails Error [ROR005]: Server Rendering Failed

An error occurred while server-side rendering component 'ComplexComponent'.
window is not defined


Code: ROR005
Docs: https://reactonrails.com/docs/reference/error-reference#ror005

💡 Suggested Solution:
1. Check your JavaScript console output:
   tail -f log/development.log | grep 'React on Rails'

2. Common issues:
   - Missing Node.js dependencies: cd client && npm install
   - Syntax errors in component code
   - Using browser-only APIs without checks

3. Debug server rendering:
   - Set config.trace = true in your configuration
   - Set config.development_mode = true for better errors
   - Check config.server_bundle_js_file points to correct file

4. Verify your server bundle:
   bin/shakapacker or bin/webpack



📋 Context:
Component: ComplexComponent
Rails Environment: development (detailed errors enabled)

🔧 Need More Help?
📞 Get Help & Support:
   • 🚀 Professional Support: react_on_rails@shakacode.com (fastest resolution)
   • 💬 React + Rails Slack: https://invite.reactrails.com
   • 🆓 GitHub Issues: https://github.com/shakacode/react_on_rails/issues
   • 📖 Discussions: https://github.com/shakacode/react_on_rails/discussions
```

<a id="ror006"></a>

## ROR006: Redux Store Not Found

**SmartError type:** `:redux_store_not_found`

**Canonical URL:** https://reactonrails.com/docs/reference/error-reference#ror006

A component requested a Redux store that was not registered.

### Example SmartError Output

```text
❌ React on Rails Error [ROR006]: Redux Store Not Found

Redux store 'AppStore' was not found.
Available stores: UserStore, ProductStore


Code: ROR006
Docs: https://reactonrails.com/docs/reference/error-reference#ror006

💡 Suggested Solution:
1. Register your Redux store:
   ReactOnRails.registerStore({ AppStore: AppStore });

2. Ensure the store is imported:
   import AppStore from './store/AppStore';

3. Initialize the store before rendering components that depend on it:
   <%= redux_store('AppStore', props: {}) %>

4. Check store dependencies in your component:
   store_dependencies: ['AppStore']



📋 Context:
Rails Environment: development (detailed errors enabled)

🔧 Need More Help?
📞 Get Help & Support:
   • 🚀 Professional Support: react_on_rails@shakacode.com (fastest resolution)
   • 💬 React + Rails Slack: https://invite.reactrails.com
   • 🆓 GitHub Issues: https://github.com/shakacode/react_on_rails/issues
   • 📖 Discussions: https://github.com/shakacode/react_on_rails/discussions
```

<a id="ror007"></a>

## ROR007: Configuration Error

**SmartError type:** `:configuration_error`

**Canonical URL:** https://reactonrails.com/docs/reference/error-reference#ror007

React on Rails detected invalid or incomplete configuration.

### Example SmartError Output

```text
❌ React on Rails Error [ROR007]: Configuration Error

Invalid configuration detected.
config.server_bundle_js_file points to a missing file


Code: ROR007
Docs: https://reactonrails.com/docs/reference/error-reference#ror007

💡 Suggested Solution:
Review your React on Rails configuration:

1. Check config/initializers/react_on_rails.rb

2. Common configuration issues:
   - Invalid bundle paths
   - Missing Node modules location
   - Incorrect component subdirectory

3. Run configuration doctor:
   rake react_on_rails:doctor



📋 Context:
Rails Environment: development (detailed errors enabled)

🔧 Need More Help?
📞 Get Help & Support:
   • 🚀 Professional Support: react_on_rails@shakacode.com (fastest resolution)
   • 💬 React + Rails Slack: https://invite.reactrails.com
   • 🆓 GitHub Issues: https://github.com/shakacode/react_on_rails/issues
   • 📖 Discussions: https://github.com/shakacode/react_on_rails/discussions
```
