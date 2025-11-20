# 🤖 AI Agent Instructions: React on Rails Setup

_Super concise, copy-paste instructions for AI agents to set up React on Rails in common scenarios._

## 🔍 **Before Starting: Check Current Versions**

```bash
# Get latest available versions (recommended approach)
gem search react_on_rails --remote
```

Install and update gem and npm package using strict option.

---

## 🆕 Scenario 1: New Rails App with React on Rails

```bash
# Create new Rails app
rails new myapp --skip-javascript --database=postgresql
cd myapp

# Use latest version
bundle add react_on_rails --strict

bin/rails generate react_on_rails:install

# Accept change to bin/dev

# Start development servers
bin/dev
```

**✅ Success Check:** Visit `http://localhost:3000/hello_world` → Should see "Hello World" from React

---

## 🔄 Scenario 2: Add React on Rails to Existing Rails App

```bash
cd /path/to/existing/app
# Use latest version
bundle add react_on_rails --strict

bin/rails generate react_on_rails:install

# Accept change to bin/dev

# Start development servers
bin/dev
# Navigate to existing Rails app root

# Start development
bin/dev
```

---

## 🛠️ Common Troubleshooting Commands

- Always run `bin/dev` to test setup, and check browser console for any JavaScript errors
- `bin/dev kill` stops other conflicting processes
- `bin/rake react_on_rails:doctor` for helpful information
