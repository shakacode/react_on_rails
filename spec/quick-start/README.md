# React on Rails Quick Start Example

This Rails application demonstrates the React on Rails setup process described in our [15-Minute Quick Start Guide](../../docs/quick-start/README.md).

## ✅ What This Demonstrates

This example app shows:

- **Complete React on Rails setup** following the quick-start guide exactly
- **Basic React component** (`HelloWorld`) integrated with Rails
- **Props passing** from Rails controller to React component
- **Hot Module Replacement** ready for development
- **Server-side rendering** capability (disabled by default)
- **Modern toolchain** with Shakapacker 8.3.0 and React 19

## 🚀 Quick Test

To verify this example works:

1. **Install dependencies:**
   ```bash
   bundle install
   npm install
   ```

2. **Start the development server:**
   ```bash
   ./bin/dev
   ```

3. **Visit the app:**
   Open http://localhost:3000/hello_world

You should see a React component with an interactive input field that updates in real-time.

## 📁 Generated Structure

The React on Rails generator created:

### Rails Files
- `app/controllers/hello_world_controller.rb` - Controller with props
- `app/views/hello_world/index.html.erb` - Rails view with React component
- `app/views/layouts/hello_world.html.erb` - Layout with webpack assets
- `config/initializers/react_on_rails.rb` - Configuration

### React Files  
- `app/javascript/bundles/HelloWorld/components/HelloWorld.jsx` - React component
- `app/javascript/bundles/HelloWorld/components/HelloWorld.module.css` - CSS modules
- `app/javascript/packs/hello-world-bundle.js` - Component registration
- `app/javascript/packs/server-bundle.js` - Server-side rendering setup

### Development Files
- `bin/dev` - Start both Rails and Webpack dev server with HMR
- `bin/dev-static` - Start with static bundles (no HMR)
- `Procfile.dev` / `Procfile.dev-static` - Process definitions

### Webpack Configuration
- `config/webpack/` - Complete Webpack setup for development and production
- `config/shakapacker.yml` - Shakapacker configuration
- `babel.config.js` - Babel configuration with React presets

## 🔧 Try These Next Steps

### Enable Server-Side Rendering
Edit `app/views/hello_world/index.html.erb` and change:
```erb
<%= react_component("HelloWorld", props: @hello_world_props, prerender: false) %>
```
to:
```erb
<%= react_component("HelloWorld", props: @hello_world_props, prerender: true) %>
```

### Customize the Component
Edit `app/javascript/bundles/HelloWorld/components/HelloWorld.jsx` and see your changes update instantly with hot reloading.

### Update Props from Rails
Modify `@hello_world_props` in `app/controllers/hello_world_controller.rb` to pass different data to your React component.

## 📋 Setup Steps Followed

This app was created by following these exact steps from the quick-start guide:

1. ✅ `rails new quick-start --skip-javascript`
2. ✅ `bundle add shakapacker --strict`  
3. ✅ `rails shakapacker:install`
4. ✅ `bundle add react_on_rails --strict` (using local path)
5. ✅ `git init && git add . && git commit -m "Initial setup"`
6. ✅ `rails generate react_on_rails:install`

The entire setup took approximately 15 minutes and resulted in a fully functional React + Rails application with hot reloading.

## 🎯 Purpose

This example serves multiple purposes:

1. **Validation** - Proves the quick-start guide works exactly as documented
2. **Reference** - Shows the expected file structure after setup
3. **Testing** - Provides a working example for development and testing
4. **Documentation** - Demonstrates best practices for React on Rails integration

---

**Next Steps:** Check out the [complete React on Rails documentation](../../docs/README.md) for advanced features like Redux integration, React Router, and deployment guides.
