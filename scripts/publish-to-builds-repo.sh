#!/usr/bin/env bash
#
# Build all JS packages and push the built output to the react-on-rails-builds repo.
#
# Usage:
#   ./scripts/publish-to-builds-repo.sh [--dist-repo <git-url>] [--branch <branch>] [--tag <tag>] [--dry-run]
#
# Options:
#   --dist-repo   Git URL of the builds repo (default: git@github.com:shakacode/react-on-rails-builds.git)
#   --branch      Branch to push to in the builds repo (default: current git branch name)
#   --tag         Tag to create (default: v<version> from react-on-rails package.json)
#   --dry-run     Build and prepare but don't push
#
# The builds repo will have this structure:
#   react-on-rails/
#     package.json
#     lib/
#   react-on-rails-pro/
#     package.json
#     lib/
#   react-on-rails-pro-node-renderer/
#     package.json
#     lib/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOREPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DIST_REPO="git@github.com:shakacode/react-on-rails-builds.git"
DIST_BRANCH=""
DIST_TAG=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dist-repo) DIST_REPO="$2"; shift 2 ;;
    --branch)    DIST_BRANCH="$2"; shift 2 ;;
    --tag)       DIST_TAG="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    *)           echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

PACKAGES=(
  "react-on-rails"
  "react-on-rails-pro"
  "react-on-rails-pro-node-renderer"
)

# Read version from react-on-rails package.json
VERSION=$(node -e "console.log(require('./packages/react-on-rails/package.json').version)" 2>/dev/null)
if [[ -z "$VERSION" ]]; then
  echo "Error: Could not read version from packages/react-on-rails/package.json" >&2
  exit 1
fi

# Default branch to the current git branch name
if [[ -z "$DIST_BRANCH" ]]; then
  DIST_BRANCH=$(cd "$MONOREPO_ROOT" && git rev-parse --abbrev-ref HEAD)
fi

if [[ -z "$DIST_TAG" ]]; then
  DIST_TAG="v${VERSION}"
fi

echo "==> Monorepo root: $MONOREPO_ROOT"
echo "==> Version: $VERSION"
echo "==> Dist repo: $DIST_REPO"
echo "==> Dist branch: $DIST_BRANCH"
echo "==> Dist tag: $DIST_TAG"
echo "==> Dry run: $DRY_RUN"
echo ""

# -------------------------------------------------------------------
# 1. Build all packages
# -------------------------------------------------------------------
echo "==> Building all packages..."
cd "$MONOREPO_ROOT"
pnpm build
echo "==> Build complete."
echo ""

# -------------------------------------------------------------------
# 2. Clone or update the builds repo
# -------------------------------------------------------------------
DIST_DIR=$(mktemp -d)
trap 'rm -rf "$DIST_DIR"' EXIT

echo "==> Cloning builds repo into $DIST_DIR..."
if git ls-remote "$DIST_REPO" "refs/heads/$DIST_BRANCH" &>/dev/null; then
  git clone --branch "$DIST_BRANCH" --depth 1 "$DIST_REPO" "$DIST_DIR/repo" 2>/dev/null || \
    git clone "$DIST_REPO" "$DIST_DIR/repo" 2>/dev/null || {
      # Fresh repo with no commits yet
      git init "$DIST_DIR/repo"
      cd "$DIST_DIR/repo"
      git remote add origin "$DIST_REPO"
    }
else
  # Branch doesn't exist or repo is empty
  git clone "$DIST_REPO" "$DIST_DIR/repo" 2>/dev/null || {
    git init "$DIST_DIR/repo"
    cd "$DIST_DIR/repo"
    git remote add origin "$DIST_REPO"
  }
fi

cd "$DIST_DIR/repo"

# Ensure we're on the right branch
git checkout "$DIST_BRANCH" 2>/dev/null || git checkout -b "$DIST_BRANCH"

echo ""

# -------------------------------------------------------------------
# 3. Copy built packages
# -------------------------------------------------------------------
echo "==> Copying built packages..."

for pkg in "${PACKAGES[@]}"; do
  PKG_SRC="$MONOREPO_ROOT/packages/$pkg"
  PKG_DEST="$DIST_DIR/repo/$pkg"

  echo "    $pkg"

  # Clean the destination
  rm -rf "$PKG_DEST"
  mkdir -p "$PKG_DEST"

  # Copy package.json
  cp "$PKG_SRC/package.json" "$PKG_DEST/package.json"

  # Copy lib/ directory
  if [[ -d "$PKG_SRC/lib" ]]; then
    cp -r "$PKG_SRC/lib" "$PKG_DEST/lib"
  else
    echo "    WARNING: $PKG_SRC/lib does not exist! Was the build successful?" >&2
  fi

  # Copy README if it exists
  if [[ -f "$PKG_SRC/README.md" ]]; then
    cp "$PKG_SRC/README.md" "$PKG_DEST/README.md"
  fi
done

# -------------------------------------------------------------------
# 4. Fix workspace:* references in package.json files
# -------------------------------------------------------------------
echo "==> Replacing workspace:* references with version $VERSION..."

for pkg in "${PACKAGES[@]}"; do
  PKG_JSON="$DIST_DIR/repo/$pkg/package.json"
  if grep -q '"workspace:\*"' "$PKG_JSON" 2>/dev/null; then
    sed -i "s/\"workspace:\*\"/\"$VERSION\"/g" "$PKG_JSON"
    echo "    Fixed $pkg/package.json"
  fi
done

# -------------------------------------------------------------------
# 5. Remove prepare/prepublishOnly scripts (not needed in dist)
# -------------------------------------------------------------------
echo "==> Removing build-related scripts from package.json files..."

for pkg in "${PACKAGES[@]}"; do
  PKG_JSON="$DIST_DIR/repo/$pkg/package.json"
  node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('$PKG_JSON', 'utf8'));
    if (pkg.scripts) {
      delete pkg.scripts.build;
      delete pkg.scripts['build-watch'];
      delete pkg.scripts.clean;
      delete pkg.scripts.prepare;
      delete pkg.scripts.prepublishOnly;
      delete pkg.scripts['type-check'];
      if (Object.keys(pkg.scripts).length === 0) delete pkg.scripts;
    }
    delete pkg.devDependencies;
    fs.writeFileSync('$PKG_JSON', JSON.stringify(pkg, null, 2) + '\n');
  "
  echo "    Cleaned $pkg/package.json"
done

# -------------------------------------------------------------------
# 6. Write a top-level README
# -------------------------------------------------------------------
cat > "$DIST_DIR/repo/README.md" << 'READMEEOF'
# react-on-rails-builds

Pre-built JavaScript packages from the [react_on_rails](https://github.com/shakacode/react_on_rails) monorepo.

This repo contains compiled output ready for consumption as git dependencies.
Do not edit files here directly — they are generated by `scripts/publish-to-builds-repo.sh`
in the source monorepo.

## Usage (pnpm)

```json
{
  "dependencies": {
    "react-on-rails": "github:shakacode/react-on-rails-builds#TAG&path:react-on-rails",
    "react-on-rails-pro": "github:shakacode/react-on-rails-builds#TAG&path:react-on-rails-pro",
    "react-on-rails-pro-node-renderer": "github:shakacode/react-on-rails-builds#TAG&path:react-on-rails-pro-node-renderer"
  },
  "pnpm": {
    "overrides": {
      "react-on-rails": "github:shakacode/react-on-rails-builds#TAG&path:react-on-rails"
    }
  }
}
```

Replace `TAG` with the version tag (e.g., `v16.4.0-rc.5`).
READMEEOF

# -------------------------------------------------------------------
# 7. Commit and push
# -------------------------------------------------------------------
echo ""
cd "$DIST_DIR/repo"
git add -A

SOURCE_SHA=$(cd "$MONOREPO_ROOT" && git rev-parse --short HEAD)
SOURCE_BRANCH=$(cd "$MONOREPO_ROOT" && git rev-parse --abbrev-ref HEAD)

if git diff --cached --quiet; then
  echo "==> No file changes to commit."
else
  git commit -m "Build packages $VERSION from $SOURCE_BRANCH ($SOURCE_SHA)"
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "==> [DRY RUN] Would push to $DIST_REPO branch $DIST_BRANCH"
  echo "==> [DRY RUN] Would create tag $DIST_TAG"
  echo ""
  echo "==> Contents of dist repo:"
  find . -not -path './.git/*' -not -path './.git' | sort
else
  echo "==> Pushing to $DIST_REPO branch $DIST_BRANCH..."
  git push -u origin "$DIST_BRANCH"

  # Create and push tag
  if git rev-parse "$DIST_TAG" &>/dev/null; then
    echo "==> Tag $DIST_TAG already exists, skipping tag creation."
  else
    git tag "$DIST_TAG"
    git push origin "$DIST_TAG"
    echo "==> Tag $DIST_TAG pushed."
  fi
fi

echo ""
echo "==> Done! Packages published to $DIST_REPO"
echo "==> Tag: $DIST_TAG"
