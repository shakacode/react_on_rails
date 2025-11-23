#!/bin/bash
set -e

# The node-renderer tests expect webpack bundles at spec/dummy/ssr-generated/
# but they're only built in react_on_rails_pro/spec/dummy/ssr-generated/
# This script copies them to the expected location for testing.
#
# This is necessary because:
# 1. The Pro dummy app (react_on_rails_pro/spec/dummy) has webpack configured
# 2. The node-renderer tests need to reference those built bundles
# 3. Tests run in packages/react-on-rails-pro-node-renderer/tests/
# 4. Test fixtures reference bundles at spec/dummy/ssr-generated (workspace root dummy app)

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

# Copy or create manifest files
echo "Copying manifest files..."
if [ -f "$PRO_DUMMY/public/webpack/test/react-client-manifest.json" ]; then
  cp "$PRO_DUMMY/public/webpack/test/react-client-manifest.json" "$ROOT_DUMMY/public/webpack/test/"
else
  echo "{}" > "$ROOT_DUMMY/public/webpack/test/react-client-manifest.json"
fi

if [ -f "$PRO_DUMMY/ssr-generated/react-server-client-manifest.json" ]; then
  cp "$PRO_DUMMY/ssr-generated/react-server-client-manifest.json" "$ROOT_DUMMY/ssr-generated/"
else
  echo "{}" > "$ROOT_DUMMY/ssr-generated/react-server-client-manifest.json"
fi

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
