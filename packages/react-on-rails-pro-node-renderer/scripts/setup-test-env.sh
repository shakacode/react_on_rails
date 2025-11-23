#!/bin/bash
set -e

echo "Setting up test environment for react-on-rails-pro-node-renderer..."

# Determine the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$PACKAGE_DIR/../.." && pwd)"
PRO_DUMMY="$WORKSPACE_ROOT/react_on_rails_pro/spec/dummy"
ROOT_DUMMY="$WORKSPACE_ROOT/spec/dummy"

# Check if bundles exist in Pro dummy
if [ ! -f "$PRO_DUMMY/ssr-generated/server-bundle.js" ] || [ ! -f "$PRO_DUMMY/ssr-generated/rsc-bundle.js" ]; then
  echo "ERROR: Test bundles not found in $PRO_DUMMY/ssr-generated/"
  echo "Please run 'yarn build:test' in react_on_rails_pro/spec/dummy first."
  exit 1
fi

# Create directories for bundle copies
echo "Creating bundle directories..."
mkdir -p "$ROOT_DUMMY/ssr-generated"
mkdir -p "$ROOT_DUMMY/public/webpack/test"

# Copy bundles to expected locations
echo "Copying bundles to test locations..."
cp "$PRO_DUMMY/ssr-generated"/*.js "$ROOT_DUMMY/ssr-generated/"

# Create stub manifest files
echo "Creating stub manifest files..."
echo "{}" > "$ROOT_DUMMY/public/webpack/test/react-client-manifest.json"
echo "{}" > "$ROOT_DUMMY/ssr-generated/react-server-client-manifest.json"

echo "✓ Test environment setup complete!"
echo ""
echo "Bundles copied from:"
echo "  $PRO_DUMMY/ssr-generated/"
echo "To:"
echo "  $ROOT_DUMMY/ssr-generated/"
echo ""
echo "You can now run tests with:"
echo "  cd packages/react-on-rails-pro-node-renderer"
echo "  yarn test tests/htmlStreaming.test.js"
