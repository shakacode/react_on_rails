#!/bin/zsh
set -e

# Initialize ASDF if available (for proper Ruby/Node versions)
if [[ -f ~/.asdf/asdf.sh ]]; then
    source ~/.asdf/asdf.sh
elif command -v asdf >/dev/null 2>&1; then
    # For homebrew-installed asdf
    if [[ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ]]; then
        source /opt/homebrew/opt/asdf/libexec/asdf.sh
    fi
fi

echo "🚀 Setting up React on Rails workspace..."

# Check required tools
echo "📋 Checking required tools..."
command -v bundle >/dev/null 2>&1 || { echo "❌ Error: bundler is not installed. Please install Ruby and bundler first."; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "❌ Error: pnpm is not installed. Please install pnpm first (npm install -g pnpm or corepack enable)."; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Error: Node.js is not installed. Please install Node.js first."; exit 1; }

echo "✅ Ruby version: $(ruby -v | awk '{print $2}')"
echo "✅ Node.js version: $(node -v)"

# Copy any environment files from root if they exist
if [ -n "$CONDUCTOR_ROOT_PATH" ]; then
    if [ -f "$CONDUCTOR_ROOT_PATH/.env" ]; then
        cp "$CONDUCTOR_ROOT_PATH/.env" .env
    fi
    if [ -f "$CONDUCTOR_ROOT_PATH/.env.local" ]; then
        cp "$CONDUCTOR_ROOT_PATH/.env.local" .env.local
    fi
fi

# Install Ruby dependencies
echo "💎 Installing Ruby dependencies (root)..."
bundle install

echo "💎 Installing Ruby dependencies for spec/dummy..."
(cd react_on_rails/spec/dummy && bundle install)

echo "💎 Installing Ruby dependencies for react_on_rails_pro..."
(cd react_on_rails_pro && bundle install)

echo "💎 Installing Ruby dependencies for react_on_rails_pro/spec/dummy..."
(cd react_on_rails_pro/spec/dummy && bundle install)

# Enable corepack for pnpm (this project uses pnpm, not yarn)
echo "📦 Enabling corepack for pnpm..."
corepack enable

# Install JavaScript dependencies
echo "📦 Installing JavaScript dependencies..."
pnpm install

# Build TypeScript (required for tests)
echo "🔨 Building TypeScript package..."
pnpm run build

# Generate the node package
echo "📦 Generating node package..."
rake node_package

# Install git hooks for linting
echo "🪝 Installing git hooks..."
bundle exec lefthook install || echo "⚠️ Could not install lefthook hooks"

# Run initial linting to ensure everything is set up correctly
echo "✅ Running initial linting checks..."
bundle exec rubocop --version
pnpm run type-check || echo "⚠️ Type checking had issues"

echo "✨ Workspace setup complete!"
echo ""
echo "📚 Key commands:"
echo "  • rake run_rspec:gem      - Run gem unit tests"
echo "  • rake run_rspec:dummy    - Run integration tests"
echo "  • pnpm run test           - Run JavaScript tests"
echo "  • bundle exec rubocop     - Run Ruby linting"
echo "  • rake autofix            - Auto-fix formatting"
