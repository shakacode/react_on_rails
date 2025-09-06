# 🤖 AI Agent Instructions: React on Rails Setup

*Super concise, copy-paste instructions for AI agents to set up React on Rails in common scenarios.*

## 🔍 **Before Starting: Check Current Versions**

```bash
# Get latest available versions (recommended approach)
gem search react_on_rails --remote
gem search shakapacker --remote

# Or use specific versions from these commands in your Gemfile:
# Latest stable versions as of Jan 2025:
# react_on_rails ~> 14.2
# shakapacker ~> 8.1
```

**⚠️ Version Flexibility:** These instructions use `~> X.Y` which allows patch updates. Always check for latest versions before starting a new project.

---

## 🆕 Scenario 1: New Rails App with React on Rails

```bash
# Create new Rails app with essential gems
rails new myapp --skip-javascript --database=postgresql
cd myapp

# Add React on Rails to Gemfile (latest versions)
echo 'gem "react_on_rails", "~> 14.2"' >> Gemfile
echo 'gem "shakapacker", "~> 8.1"' >> Gemfile
bundle install

# Install React on Rails with Node dependencies
rails generate react_on_rails:install
yarn install

# Start development servers
bin/dev
```

**✅ Success Check:** Visit `http://localhost:3000/hello_world` → Should see "Hello World" from React

**📁 Generated Files:**
- `app/javascript/bundles/HelloWorld/components/HelloWorld.jsx`
- `app/controllers/hello_world_controller.rb`
- `app/views/hello_world/index.html.erb`

---

## 🔄 Scenario 2: Add React on Rails to Existing Rails App

```bash
# Navigate to existing Rails app root
cd /path/to/existing/app

# Add gems to Gemfile (before final 'end')
cat >> Gemfile << 'EOF'

# React on Rails
gem "react_on_rails", "~> 14.2"
gem "shakapacker", "~> 8.1"
EOF

# Install gems
bundle install

# Install React on Rails (will not overwrite existing files)
rails generate react_on_rails:install --ignore-existing-files

# Install Node dependencies  
yarn install

# Add React component to existing view
# Replace <view-name> with your actual view file
cat >> app/views/<view-name>/<action>.html.erb << 'EOF'

<%= react_component("HelloWorld", props: { name: "World" }) %>
EOF

# Start development
bin/dev
```

**⚠️ Pre-flight Checks:**
- Rails app has `bin/dev` or similar dev script
- `package.json` exists (if not, run `yarn init -y` first)
- No existing React setup conflicts

**✅ Success Check:** React component renders in your chosen view

---

## ⚡ Scenario 3: Convert Vite-Ruby to React on Rails

```bash
# Navigate to app root
cd /path/to/vite/ruby/app

# Remove Vite-Ruby gems from Gemfile
sed -i.bak '/gem.*vite_rails/d' Gemfile
sed -i.bak '/gem.*vite_ruby/d' Gemfile

# Add React on Rails gems to Gemfile
cat >> Gemfile << 'EOF'

# React on Rails (replacing Vite)
gem "react_on_rails", "~> 14.2" 
gem "shakapacker", "~> 8.1"
EOF

# Install new gems
bundle install

# Backup existing Vite config
mv vite.config.* vite.config.backup 2>/dev/null || true

# Remove Vite-specific files
rm -rf config/vite.json
rm -rf bin/vite*

# Install React on Rails
rails generate react_on_rails:install --force

# Migrate existing React components
# Move components from app/frontend/entrypoints/ to app/javascript/bundles/
mkdir -p app/javascript/bundles/Components
find app/frontend -name "*.jsx" -o -name "*.tsx" | while read file; do
    basename=$(basename "$file")
    cp "$file" "app/javascript/bundles/Components/$basename"
done

# Update component registrations in app/javascript/packs/hello-world-bundle.js
echo "// Register your existing components here"
echo "// import YourComponent from '../bundles/Components/YourComponent';"
echo "// ReactOnRails.register({ YourComponent });"

# Clean up old Vite files
rm -rf app/frontend
rm -rf public/vite*

# Update views to use React on Rails helpers
# Replace vite_javascript_tag with javascript_pack_tag
# Replace vite_stylesheet_tag with stylesheet_pack_tag

# Install dependencies
yarn install

# Start development
bin/dev
```

**🔧 Manual Steps Required:**
1. **Update views**: Replace `vite_javascript_tag` with `javascript_pack_tag "hello-world-bundle"`
2. **Register components**: Add your components to `app/javascript/packs/hello-world-bundle.js`
3. **Update imports**: Change relative paths if needed

**✅ Success Check:** 
- `bin/dev` starts without Vite errors
- React components render using `<%= react_component("YourComponent") %>`

---

## 🛠️ Common Troubleshooting Commands

```bash
# Check current versions and compatibility
bundle info react_on_rails shakapacker
rails --version
ruby --version
node --version

# Check React on Rails installation
rails runner "puts ReactOnRails::VERSION"

# Verify Shakapacker setup
bin/shakapacker --version

# Clear cache if components not updating
rm -rf tmp/cache public/packs
rails assets:clobber

# Check component registration
rails runner "puts ReactOnRails.configuration.components_subdirectory"

# Restart with clean build
pkill -f "bin/shakapacker-dev-server"
rm -rf public/packs-test
bin/dev
```

---

## 📋 Quick Reference

### Essential Files Structure
```
app/
├── controllers/hello_world_controller.rb
├── views/hello_world/index.html.erb
└── javascript/
    ├── bundles/HelloWorld/components/HelloWorld.jsx
    └── packs/hello-world-bundle.js
```

### Key Commands
- **Development**: `bin/dev` (starts Rails + Shakapacker)
- **Generate**: `rails generate react_on_rails:install`
- **Component**: `<%= react_component("ComponentName", props: {}) %>`

### Version Requirements
- Rails 7+ (Rails 8 supported), Ruby 3.0+ (Ruby 3.2+ for Rails 8), Node 20+ LTS, Yarn
- react_on_rails ~> 14.2+, shakapacker ~> 8.1+
- **Note**: Use `bundle info react_on_rails` to check latest available version

---

*💡 **Pro Tip for AI Agents**: Always run `bin/dev` to test setup, and check browser console for any JavaScript errors.*