# YALC Alternatives for Monorepo Development

**Purpose:** Evaluate alternatives to YALC for local package development in the React on Rails monorepo

**Current Pain Points with YALC:**

1. Manual `yalc publish` required after changes
2. Not integrated into monorepo workflow
3. Additional tool dependency (not standard)
4. Requires `.yalc` directory and lock file management
5. Can cause confusion when packages get out of sync

---

## Option 1: pnpm Workspaces (⭐ Recommended)

### Overview

pnpm is a fast, disk-space-efficient package manager with excellent monorepo support built-in.

### Pros ✅

- **Automatic linking:** No manual publish step needed
- **Faster installs:** Content-addressable storage, hard links
- **Better disk usage:** Shares packages across projects
- **Workspace protocol:** `"react-on-rails": "workspace:*"` for local deps
- **Selective builds:** `pnpm --filter <package>` for targeted operations
- **Industry adoption:** Used by Vue, Vite, and many large monorepos
- **Zero config linking:** Packages in workspace automatically linked

### Cons ❌

- Requires migration from Yarn
- Learning curve for team
- Different lockfile format (pnpm-lock.yaml vs yarn.lock)
- Some tools may not support pnpm yet (rare)

### Migration Path

```bash
# 1. Install pnpm
npm install -g pnpm

# 2. Import yarn.lock (converts to pnpm-lock.yaml)
pnpm import

# 3. Update package.json workspaces (syntax is the same)
# No changes needed to workspace configuration

# 4. Update dependencies in package.json
# Change from:
#   "react-on-rails": "16.2.0-beta.10"
# To:
#   "react-on-rails": "workspace:*"

# 5. Install
pnpm install

# 6. Update scripts
# Replace "yarn" with "pnpm" in scripts and CI
```

### Usage Examples

```bash
# Install dependencies
pnpm install

# Build specific package
pnpm --filter react-on-rails build

# Build all packages
pnpm -r build  # recursive

# Run tests in specific package
pnpm --filter react-on-rails-pro test

# Add dependency to specific package
pnpm --filter react-on-rails-pro add lodash

# No yalc needed - changes are automatically linked!
```

### Effort Estimate

- **Time:** 2-4 hours
- **Risk:** Low (pnpm is stable and well-tested)
- **Rollback:** Easy (keep yarn.lock as backup)

---

## Option 2: Yarn Workspaces + yarn link (⚡ Quick Win)

### Overview

Use built-in `yarn link` instead of yalc, leveraging existing Yarn workspaces.

### Pros ✅

- **Zero migration:** Already using Yarn workspaces
- **Native Yarn feature:** No additional tools
- **Simpler than yalc:** One less dependency
- **Familiar workflow:** Team already knows Yarn

### Cons ❌

- Still manual (need to run `yarn link`)
- Workspace packages should auto-link already
- Less powerful than pnpm for complex monorepos
- Slower than pnpm for large projects

### Implementation

**Current Problem:** Why is yalc needed if workspaces exist?

**Answer:** Workspace packages are auto-linked by Yarn! You might not need yalc OR yarn link.

### Verify Auto-Linking

```bash
# In a workspace, packages should auto-link
cd packages/react-on-rails-pro
yarn install

# Check if react-on-rails is linked
ls -la node_modules/react-on-rails
# Should be a symlink to ../../react-on-rails
```

**If auto-linking works:** Remove yalc entirely!

**If you need to link to external projects:**

```bash
# In package directory
cd packages/react-on-rails
yarn link

# In external project
cd ~/my-rails-app
yarn link react-on-rails
```

### Effort Estimate

- **Time:** 1-2 hours (mainly testing)
- **Risk:** Very low
- **Rollback:** Instant (just use yalc again)

---

## Option 3: npm Workspaces (Only if switching to npm)

### Overview

npm 7+ has built-in workspace support similar to Yarn.

### Pros ✅

- Native to npm (no additional tools)
- Standard across Node ecosystem
- Automatic linking like Yarn workspaces

### Cons ❌

- Requires migration from Yarn
- Slower than pnpm
- Less features than pnpm for monorepos
- No compelling reason to switch from Yarn to npm

### When to Consider

- Only if standardizing on npm for other reasons
- If already using npm in parts of the project

### Effort Estimate

- **Time:** 4-6 hours
- **Risk:** Medium (lockfile changes)
- **Recommendation:** Don't migrate unless required

---

## Option 4: Turborepo (Advanced Monorepo Tooling)

### Overview

Build orchestration tool that wraps pnpm/yarn/npm with caching and task scheduling.

### Pros ✅

- **Intelligent caching:** Skips unchanged package builds
- **Parallel execution:** Builds packages in parallel respecting deps
- **Remote caching:** Share cache across team
- **Task pipelines:** Define complex build workflows

### Cons ❌

- Overkill for current monorepo size (3 packages)
- Additional complexity
- Another tool to learn and maintain

### When to Consider

- If monorepo grows to 10+ packages
- If build times become significant problem
- If team needs remote caching

### Effort Estimate

- **Time:** 8-16 hours
- **Risk:** Medium (complexity)
- **Recommendation:** Overkill for current needs

---

## Option 5: Lerna (Classic Monorepo Tool)

### Overview

Original JavaScript monorepo tool, now maintained by Nx team.

### Pros ✅

- Mature and battle-tested
- Familiar to many developers
- Handles versioning and publishing

### Cons ❌

- Considered legacy (Nx/Turborepo are successors)
- Slower than modern alternatives
- More complex setup

### Recommendation

- **Don't use:** Superseded by better tools
- **Exception:** If already using Lerna

---

## Option 6: Keep YALC but Automate

### Overview

Keep yalc but integrate into workspace scripts for automatic publishing.

### Implementation

```json
// In each package.json
{
  "scripts": {
    "dev": "concurrently \"yarn build-watch\" \"yarn yalc:publish:watch\"",
    "yalc:publish:watch": "nodemon --watch lib --exec 'yalc publish'"
  }
}
```

Or use `onchange` package:

```json
{
  "scripts": {
    "yalc:auto": "onchange 'lib/**' -- yalc publish"
  }
}
```

### Pros ✅

- Keep current workflow
- Minimal changes
- Automates the pain point

### Cons ❌

- Still need yalc
- More complex than native solutions
- Doesn't solve the root problem

---

## Comparison Matrix

| Feature          | YALC (Current) | pnpm         | Yarn + link  | npm         | Turborepo   |
| ---------------- | -------------- | ------------ | ------------ | ----------- | ----------- |
| Auto-linking     | ❌ Manual      | ✅ Yes       | ✅ Yes\*     | ✅ Yes\*    | ✅ Yes      |
| Speed            | ⚠️ Medium      | 🚀 Fast      | ⚠️ Medium    | 🐌 Slow     | 🚀 Fast     |
| Disk Usage       | ➖ Normal      | ✅ Efficient | ➖ Normal    | ❌ Wasteful | ➖ Normal   |
| Caching          | ❌ No          | ✅ Yes       | ❌ No        | ⚠️ Basic    | 🚀 Advanced |
| Learning Curve   | ⚠️ Medium      | ⚠️ Medium    | ✅ Low       | ✅ Low      | ❌ High     |
| Migration Effort | -              | ⚠️ 2-4h      | ✅ 1-2h      | ⚠️ 4-6h     | ❌ 8-16h    |
| Recommendation   | ❌ Replace     | ⭐ Best      | ✅ Quick win | ❌ Skip     | ⚠️ Overkill |

\*Workspaces auto-link within monorepo; yarn/npm link needed for external projects only

---

## Recommendations

### Immediate (This PR)

**✅ Do:** Remove yalc reliance within monorepo

- Workspace packages should auto-link already
- Test if `yarn install` automatically links packages
- If yes: Remove all yalc scripts from workspace packages
- If no: Debug why auto-linking isn't working

### Short-Term (Next Month)

**⭐ Recommended:** Migrate to pnpm

- Better monorepo support
- Faster installs
- Industry standard for modern monorepos
- Low migration risk

### Alternative (If avoiding migration)

**✅ Acceptable:** Keep Yarn workspaces, remove yalc

- Workspace auto-linking should be sufficient
- Use `yarn link` only for external testing
- Simpler than current yalc setup

### Don't Do

- ❌ npm workspaces (no benefit over Yarn)
- ❌ Lerna (outdated)
- ❌ Turborepo (overkill for 3 packages)
- ❌ Keep yalc (unnecessary complexity)

---

## Action Plan

### Phase 1: Investigate Auto-Linking (1 hour)

- [ ] Test if workspace packages auto-link already
- [ ] Document findings
- [ ] If working: Remove yalc from internal dependencies

### Phase 2: Decision Point

**If auto-linking works:**

- [ ] Remove yalc entirely (except for external project testing)
- [ ] Update documentation

**If auto-linking doesn't work:**

- [ ] Debug why (likely config issue)
- [ ] Fix workspace configuration
- [ ] Then remove yalc

### Phase 3: Consider pnpm Migration (Optional, Post-Monorepo)

- [ ] Create spike branch to test pnpm
- [ ] Measure install/build times
- [ ] Test CI compatibility
- [ ] Make go/no-go decision
- [ ] If yes: Migrate in separate PR

---

## Testing Checklist

Before removing yalc, verify:

- [ ] Workspace packages auto-link:

  ```bash
  cd packages/react-on-rails-pro
  yarn install
  ls -la node_modules/react-on-rails  # Should be symlink
  ```

- [ ] Changes propagate without republish:

  ```bash
  # Make change in react-on-rails
  # Build react-on-rails
  yarn workspace react-on-rails build
  # Verify change visible in react-on-rails-pro without yalc publish
  ```

- [ ] Builds work in correct order:
  ```bash
  yarn build  # Should build core first, then pro packages
  ```

---

## Conclusion

**For React on Rails Monorepo:**

1. **Immediate:** Verify workspace auto-linking works (should replace yalc for internal deps)
2. **Short-term:** Consider pnpm migration for better DX
3. **External testing:** Keep yalc or yarn link for testing in external Rails apps

**Bottom line:** You probably don't need yalc for a 3-package monorepo with Yarn workspaces. Fix auto-linking if it's not working, don't add more tools.
