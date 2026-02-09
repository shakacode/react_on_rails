# Proposal: create-react-on-rails-app CLI Tool

**Issue:** https://github.com/shakacode/react_on_rails/issues/1637

## Overview

Create an NPX-executable CLI tool (`create-react-on-rails-app`) that provides a single-command setup experience for React on Rails projects, similar to `create-react-app` or `create-next-app`.

## Command Usage

```bash
npx create-react-on-rails-app my-app [options]
```

### Options

- `--template <type>` - typescript, javascript, redux, redux-typescript (default: javascript)
- `--package-manager <pm>` - npm, pnpm (default: auto-detect)
- `--bundler <type>` - shakapacker, rspack (default: shakapacker)
- `--tailwind` - Add Tailwind CSS
- `--pro` - Install React on Rails Pro with RSC demo (future enhancement)
- `--skip-install` - Skip dependency installation
- `--interactive` - Interactive mode with prompts (default: true)

### Example Usage

```bash
# Basic JavaScript setup
npx create-react-on-rails-app my-app

# TypeScript with Tailwind
npx create-react-on-rails-app my-app --template=typescript --tailwind

# Redux with TypeScript, using pnpm
npx create-react-on-rails-app my-app --template=redux-typescript --package-manager=pnpm

# Using Rspack bundler
npx create-react-on-rails-app my-app --template=typescript --bundler=rspack

# Interactive mode (prompts for all options)
npx create-react-on-rails-app my-app --interactive

# Future: React on Rails Pro with RSC
npx create-react-on-rails-app my-app --pro
```

## Technical Implementation

### 1. Language: TypeScript

**Rationale:**

- Better maintainability with type safety
- Easier refactoring and IDE support
- Follows modern CLI tool patterns (create-next-app, create-remix, etc.)
- Monorepo already has TypeScript build infrastructure
- More professional codebase for contributors
- Build step is minimal with existing tooling

**Build Setup:**

- Compile TypeScript to JavaScript before publishing
- Use existing monorepo build configuration
- Published package contains compiled JS in `dist/` folder

### 2. Location: Monorepo Package

**Path:** `packages/create-react-on-rails-app/` within the react_on_rails monorepo

**Benefits:**

- Share templates with Rails generators (DRY principle)
- Versioned in sync with the gem
- Use same CI/CD pipeline
- Published separately to NPM

### 3. Code Reuse from react_on_rails-demos

**Approach:** Port Ruby script logic to TypeScript shell orchestration

**Reuse patterns from:**

- `bin/new-demo` - Rails app creation workflow
- `bin/scaffold-demo` - Template and option handling
- `lib/demo_scripts/` - Version management, validation logic

**Implementation Strategy:**

```typescript
// Port Ruby scripts to TypeScript that shells out to same commands
import { execSync } from 'child_process';

execSync('rails new my-app --database=postgresql --skip-javascript');
execSync('bundle add react_on_rails --strict');
execSync('bundle install');
execSync('rails generate react_on_rails:install --typescript');
```

### 4. Package Structure

```
packages/create-react-on-rails-app/
  src/
    index.ts                        # Main entry point
    cli.ts                          # CLI orchestrator with Commander.js
    validators.ts                   # Prerequisite checks (Node, Ruby, Rails)
    rails-setup.ts                  # Rails app creation logic
    template-handler.ts             # Template application logic
    package-manager.ts              # Package manager detection/execution
    types.ts                        # TypeScript type definitions
  dist/                             # Compiled JavaScript (gitignored, published to NPM)
    index.js
    cli.js
    # ... (other compiled files)
  bin/
    create-react-on-rails-app.js    # Entry point (#!/usr/bin/env node) - calls dist/index.js
  package.json                      # Separate NPM package config
  tsconfig.json                     # TypeScript configuration
  README.md                         # Package documentation
```

### 5. Dependencies

```json
{
  "dependencies": {
    "commander": "^11.0.0",
    "chalk": "^5.0.0",
    "ora": "^6.0.0",
    "prompts": "^2.4.0"
  }
}
```

## Core Workflow

### Step 1: Validate Prerequisites

Check for required tools and versions:

- Node.js 18+ installed
- Ruby 3.0+ installed
- Rails gem available (`rails --version`)
- Package manager available (npm or pnpm)

**Validation Strategy:**

The CLI validates that dependencies exist but **does not attempt to install them**. This respects the many different ways users manage their development environments.

**Ruby Validation:**

```typescript
interface ValidationResult {
  success: boolean;
  message?: string;
}

function validateRuby(): ValidationResult {
  try {
    const rubyVersion = execSync('ruby --version', { encoding: 'utf8' });
    const version = parseRubyVersion(rubyVersion);

    if (version.major < 3) {
      return {
        success: false,
        message: `Ruby ${version.full} detected. React on Rails requires Ruby 3.0+`,
      };
    }

    return { success: true };
  } catch (error) {
    return {
      success: false,
      message: 'Ruby is not installed or not found in PATH',
    };
  }
}
```

**Error Messages - Ruby Not Found:**

```
Ruby is not installed or not found in PATH

React on Rails requires Ruby 3.0+

Popular installation options:
  - mise:   https://mise.jdx.dev/ (recommended)
  - rbenv:  https://github.com/rbenv/rbenv
  - asdf:   https://asdf-vm.com/
  - rvm:    https://rvm.io/

After installing Ruby, restart your terminal and try again.
```

**Rails Validation:**

```typescript
function validateRails(): ValidationResult {
  try {
    const railsVersion = execSync('rails --version', { encoding: 'utf8' });
    return { success: true };
  } catch (error) {
    return {
      success: false,
      message: 'Rails gem is not installed',
    };
  }
}
```

**Error Messages - Rails Not Found:**

```
Rails is not installed

Install Rails:
  gem install rails

Then try again.
```

**Node.js Validation:**

```typescript
function validateNode(): ValidationResult {
  const version = process.versions.node;
  const major = parseInt(version.split('.')[0], 10);

  if (major < 18) {
    return {
      success: false,
      message: `Node.js ${version} detected. React on Rails requires Node.js 18+`,
    };
  }

  return { success: true };
}
```

**Package Manager Validation:**

```typescript
function validatePackageManager(): ValidationResult {
  const managers = ['npm', 'pnpm', 'bun'];
  const available = managers.filter((pm) => {
    try {
      execSync(`${pm} --version`, { stdio: 'ignore' });
      return true;
    } catch {
      return false;
    }
  });

  if (available.length === 0) {
    return {
      success: false,
      message: 'No JavaScript package manager found (npm, pnpm, or bun)',
    };
  }

  return { success: true, message: `Found: ${available.join(', ')}` };
}
```

**Philosophy:**

- Validate and provide helpful guidance
- Respect user's environment management choices (mise, rbenv, asdf, etc.)
- Clear error messages with actionable next steps
- Don't try to install system-level dependencies
- Don't manage Ruby/Node versions
- Don't override user's preferred tools

### Step 2: Create Rails Application

```bash
rails new <app-name> --database=postgresql --skip-javascript
cd <app-name>
```

**Configuration:**

- PostgreSQL as default database
- Skip default JavaScript setup (we'll add our own)
- Standard Rails file structure

### Step 3: Install React on Rails Gem

```bash
bundle add react_on_rails --strict
bundle install
```

**Versioning:**

- Use `--strict` to lock to exact version
- Match gem version to NPM package version
- Ensure compatibility between Ruby and JS packages

### Step 4: Run React on Rails Generator

```bash
rails generate react_on_rails:install [--typescript] [--redux] [--rspack]
```

**Options passed through:**

- `--typescript` if template includes TypeScript
- `--redux` if template is redux or redux-typescript
- `--rspack` if bundler is rspack
- `--ignore-warnings` for non-interactive mode

### Step 5: Apply Additional Templates

**Tailwind CSS** (if `--tailwind` flag):

1. Install Tailwind dependencies
2. Configure PostCSS
3. Create Tailwind config
4. Add Tailwind directives to CSS
5. Update webpack/rspack config for Tailwind

**Future - React on Rails Pro** (if `--pro` flag):

1. Prompt for license key
2. Add `react-on-rails-pro` gem
3. Configure Pro initializer
4. Generate RSC demo component
5. Set up Pro-specific webpack config

### Step 6: Install JavaScript Dependencies

```bash
<detected-package-manager> install  # unless --skip-install
```

**Package Manager Detection:**

1. Check for lockfiles (package-lock.json, pnpm-lock.yaml)
2. Use specified `--package-manager` if provided
3. Fall back to npm if no preference

### Step 7: Success Message

```
Created my-app with React on Rails!

Next steps:
  cd my-app
  bin/dev

Visit http://localhost:3000/hello_world

Documentation: https://www.shakacode.com/react-on-rails/docs/
```

## React on Rails Pro Support (Future Enhancement)

### Command

```bash
npx create-react-on-rails-app my-app --pro
```

### Workflow

1. **License Validation**
   - Prompt for Pro license key
   - Or read from `REACT_ON_RAILS_PRO_LICENSE` environment variable
   - Validate key format

2. **Pro Installation**
   - Add `react-on-rails-pro` gem instead of open source version
   - Add `react-on-rails-rsc` NPM package
   - Install Pro-specific dependencies

3. **Configuration**
   - Configure Pro settings in initializer
   - Set up RSC-specific webpack config
   - Configure server rendering pool for Pro

4. **Demo Content**
   - Generate RSC demo component
   - Add RSC route examples
   - Include Pro feature showcase

5. **Documentation**
   - Link to Pro-specific docs
   - Show Pro feature overview
   - Provide upgrade path from open source

## Integration with react_on_rails-demos

### Current State

The [react_on_rails-demos](https://github.com/shakacode/react_on_rails-demos) repository has Ruby scripts:

- `bin/new-demo` - Creates basic demos
- `bin/scaffold-demo` - Creates advanced demos with options
- `lib/demo_scripts/` - Shared logic modules

### Proposed Integration

**Update demos repository to use the CLI tool:**

```ruby
# In bin/new-demo or bin/scaffold-demo
flags = []
flags << "--template=#{options[:template]}" if options[:template]
flags << "--tailwind" if options[:tailwind]
flags << "--typescript" if options[:typescript]

system("npx create-react-on-rails-app #{name} #{flags.join(' ')}")
```

### Benefits

- Eliminates code duplication between repos
- Single source of truth for app creation
- Demos automatically stay current with latest setup patterns
- Easier to maintain and test
- Consistent behavior between CLI and demos

## Success Criteria

### User Experience

- Reduces setup from 10+ manual steps to 1 command
- Solves issue #1637 (TypeScript + Tailwind setup confusion)
- Familiar NPX pattern for JavaScript developers
- Clear error messages and helpful guidance

### Technical Quality

- Standardized project structure across all new apps
- Works with npm and pnpm
- Proper error handling and validation
- Cross-platform support (macOS, Linux, Windows)

### Maintainability

- Code shared with existing generators (DRY)
- Versioned with gem for compatibility
- Integration tests covering all templates
- Clear documentation for contributors

### Future Growth

- Foundation for React on Rails Pro adoption
- Easy to add new templates and options
- Extensible architecture

## Implementation Plan

### Phase 1: Setup (Week 1)

1. Create `packages/create-react-on-rails-app/` directory structure
2. Set up package.json with proper bin configuration
3. Add Commander.js for CLI argument parsing
4. Implement basic scaffolding and help text

### Phase 2: Core Logic (Week 2)

1. Implement prerequisite validators
2. Add Rails app creation orchestration
3. Integrate with existing `react_on_rails:install` generator
4. Add package manager detection and execution

### Phase 3: Templates (Week 3)

1. Support JavaScript template (default)
2. Support TypeScript template
3. Support Redux templates (JS and TS variants)
4. Add Tailwind CSS integration

### Phase 4: Testing (Week 4)

1. Write integration tests that create real apps
2. Test all template combinations
3. Test across different package managers
4. Cross-platform testing (macOS, Linux, Windows)

### Phase 5: Documentation (Week 5)

1. Write comprehensive README for the package
2. Update main react_on_rails README with quick start
3. Add examples for common use cases
4. Create troubleshooting guide

### Phase 6: Publishing (Week 6)

1. Add to NPM publish workflow in monorepo
2. Set up versioning to match gem
3. Initial release to NPM
4. Announcement blog post / social media

### Phase 7: Integration (Week 7)

1. Update react_on_rails-demos to use CLI tool
2. Deprecate duplicate Ruby scripts
3. Update demos documentation

### Phase 8: Pro Support (Future)

1. Design Pro license validation
2. Implement RSC demo generation
3. Add Pro-specific configuration
4. Test with Pro customers

## Open Questions

1. **Versioning Strategy**
   - Should CLI version match gem version exactly?
   - Or use independent versioning?
   - **Recommendation:** Match major.minor, independent patch

2. **Default Template**
   - Should default be JavaScript or TypeScript?
   - **Recommendation:** JavaScript for lower barrier to entry

3. **Interactive Mode**
   - How detailed should prompts be?
   - Include advanced options or keep simple?
   - **Recommendation:** Simple by default, --advanced flag for more options

4. **Git Initialization**
   - Rails already creates git repos - any special handling needed?
   - **Recommendation:** No special handling, Rails default is fine

5. **Testing Strategy**
   - Full integration tests create real apps - slow but thorough
   - Unit tests faster but less coverage
   - **Recommendation:** Both - unit tests for logic, integration for E2E

## Resources

- **Original Issue:** https://github.com/shakacode/react_on_rails/issues/1637
- **react_on_rails-demos:** https://github.com/shakacode/react_on_rails-demos
- **Similar Tools for Reference:**
  - create-react-app: https://github.com/facebook/create-react-app
  - create-next-app: https://github.com/vercel/next.js/tree/canary/packages/create-next-app
  - create-remix: https://github.com/remix-run/remix/tree/main/packages/create-remix

## Next Steps

When ready to begin implementation:

1. Create feature branch (already done: `justin808/create-ror-app-cli`)
2. Set up package structure
3. Start with Phase 1 tasks
4. Regular check-ins and feedback cycles
5. Iterate based on testing and user feedback
