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
command -v yarn >/dev/null 2>&1 || { echo "❌ Error: yarn is not installed. Please install yarn first."; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Error: Node.js is not installed. Please install Node.js first."; exit 1; }

# Check Ruby version
RUBY_VERSION=$(ruby -v | awk '{print $2}')
MIN_RUBY_VERSION="3.0.0"
if [[ $(echo -e "$MIN_RUBY_VERSION\n$RUBY_VERSION" | sort -V | head -n1) != "$MIN_RUBY_VERSION" ]]; then
    echo "❌ Error: Ruby version $RUBY_VERSION is too old. React on Rails requires Ruby >= 3.0.0"
    echo "   Please upgrade Ruby using rbenv, rvm, or your system package manager."
    exit 1
fi
echo "✅ Ruby version: $RUBY_VERSION"

# Check Node version
NODE_VERSION=$(node -v | cut -d'v' -f2)
MIN_NODE_VERSION="20.0.0"
if [[ $(echo -e "$MIN_NODE_VERSION\n$NODE_VERSION" | sort -V | head -n1) != "$MIN_NODE_VERSION" ]]; then
    echo "❌ Error: Node.js version v$NODE_VERSION is too old. React on Rails requires Node.js >= 20.0.0"
    echo "   Please upgrade Node.js using nvm, asdf, or your system package manager."
    exit 1
fi
echo "✅ Node.js version: v$NODE_VERSION"

# Copy any environment files from root if they exist
if [ -f "$CONDUCTOR_ROOT_PATH/.env" ]; then
    echo "📝 Copying .env file..."
    cp "$CONDUCTOR_ROOT_PATH/.env" .env
fi

if [ -f "$CONDUCTOR_ROOT_PATH/.env.local" ]; then
    echo "📝 Copying .env.local file..."
    cp "$CONDUCTOR_ROOT_PATH/.env.local" .env.local
fi

# Install Ruby dependencies
echo "💎 Installing Ruby dependencies..."
bundle install

# Install JavaScript dependencies
echo "📦 Installing JavaScript dependencies..."
yarn install

# Build the TypeScript package
echo "🔨 Building TypeScript package..."
yarn run build

# Generate the node package
echo "📦 Generating node package..."
rake node_package

# Install git hooks for linting
echo "🪝 Installing git hooks..."
bundle exec lefthook install || echo "⚠️ Could not install lefthook hooks"

# Run initial linting to ensure everything is set up correctly
echo "✅ Running initial linting checks..."
bundle exec rubocop --version
yarn run type-check || echo "⚠️ Type checking had issues"

echo "✨ Workspace setup complete!"
echo ""
echo "📚 Key commands:"
echo "  • rake - Run all tests and linting"
echo "  • rake run_rspec - Run Ruby tests"
echo "  • yarn run test - Run JavaScript tests"
echo "  • bundle exec rubocop - Run Ruby linting (required before commits)"
echo "  • rake autofix - Auto-fix formatting issues"
echo ""
echo "⚠️ Remember: Always run 'bundle exec rubocop' before committing!"
