# Directory Licensing Documentation

This document outlines the current and post-merger directory licensing structure for React on Rails projects.

## Current Structure (Pre-Merger)

### react_on_rails Repository - MIT Licensed

All directories in the `react_on_rails` repository are MIT licensed:

```
react_on_rails/
├── lib/react_on_rails/           # Core Ruby code (MIT)
├── node_package/src/             # Core JS/TS code (MIT)
│   └── pro/                      # Pro features with license validation (Pro licensed)
├── spec/                         # Core tests (MIT)
├── docs/                         # Documentation (MIT)
├── .github/                      # GitHub workflows (MIT)
└── [all other directories]       # MIT
```

**Exception:** The `node_package/src/pro/` directory contains Pro implementation code licensed under the React on Rails Pro License. This code is included in the package but requires a valid Pro license to use.

**Important Distinction:**

- **MIT-licensed interface files** (outside `pro/` directories) can be freely modified under MIT terms
- **Using those modifications to access Pro features** without a license violates the Pro License
- **Pro-licensed files** (inside `pro/` directories) require a Pro license to use in any way

### react_on_rails_pro Repository - Pro Licensed

All directories in the `react_on_rails_pro` repository are Pro licensed:

```
react_on_rails_pro/
├── lib/react_on_rails_pro/       # Pro Ruby code
├── packages/node-renderer/       # Pro Node.js renderer
├── spec/                         # Pro tests
├── .circleci/                    # CircleCI config
└── [all other directories]       # Pro licensed
```

## Post-Merger Structure (Target)

After the monorepo merger, the unified repository will have clear directory-based licensing:

### MIT Licensed Directories

```
react_on_rails/ (monorepo root)
├── lib/react_on_rails/           # Core Ruby code
├── packages/react-on-rails/      # Core NPM package
├── spec/ruby/react_on_rails/     # Core Ruby tests
├── spec/packages/react-on-rails/ # Core JS tests
├── docs/                         # Shared documentation
├── tools/                        # Shared development tools
├── .github/                      # Unified GitHub workflows
└── [shared config files]         # Build configs, etc.
```

### Pro Licensed Directories

```
react_on_rails/ (monorepo root)
├── lib/react_on_rails_pro/       # Pro Ruby code
├── packages/react-on-rails-pro/  # Pro NPM package
├── packages/react-on-rails-pro-node-renderer/  # Pro Node renderer
├── spec/ruby/react_on_rails_pro/ # Pro Ruby tests
├── spec/packages/react-on-rails-pro/  # Pro JS tests
└── spec/packages/react-on-rails-pro-node-renderer/  # Pro Node renderer tests
```

## License Compliance Rules

### File-Level Compliance

1. **Repository-Level Licensing**: Files inherit their license from the directory they're located in
2. **No Mixed Directories**: Each directory is either entirely MIT or entirely Pro - no mixed licensing within a directory
3. **Clear Boundaries**: The `LICENSE.md` file explicitly lists which directories fall under which license

### Package-Level Compliance

1. **Gemspec Files**:

   - `react_on_rails.gemspec`: `s.license = "MIT"`
   - `react_on_rails_pro.gemspec`: `s.license = "UNLICENSED"`

2. **Package.json Files**:
   - `packages/react-on-rails/package.json`: `"license": "MIT"`
   - `packages/react-on-rails-pro/package.json`: `"license": "UNLICENSED"`
   - `packages/react-on-rails-pro-node-renderer/package.json`: `"license": "UNLICENSED"`

### Critical Compliance Points

1. **Never Move Pro Code to MIT Directories**: During the merger, strict verification ensures no Pro-licensed code accidentally ends up in MIT-licensed directories

2. **Update LICENSE.md Immediately**: Whenever directories are moved or created, `LICENSE.md` must be updated to reflect the new structure

3. **Automated Verification**: CI checks will verify:
   - All Pro directories are listed in LICENSE.md
   - Package.json and gemspec files have correct license fields
   - No orphaned or unlisted directories exist

## Migration Phases and License Updates

The monorepo merger plan includes specific license compliance checkpoints at each phase:

- **Phase 1**: Update license references and documentation
- **Phase 2**: Establish dual CI with clear directory boundaries
- **Phase 3-4**: Reorganize directories while maintaining license compliance
- **Phase 5-6**: Finalize structure and add automated license checking
- **Phase 7**: Complete documentation and verification

Each phase includes mandatory license compliance verification before proceeding to the next phase.

## Developer Guidelines

### When Adding New Files

1. Determine if the functionality is Core (MIT) or Pro (subscription required)
2. Place the file in the appropriate licensed directory
3. Ensure the package.json or gemspec correctly reflects the license
4. Update LICENSE.md if creating new directories

### When Moving Files

1. Verify the destination directory has the correct license for the file content
2. Never move Pro features to MIT directories
3. Update import statements and references
4. Verify no licensing boundaries are crossed inappropriately

### When Contributing

1. Core features (MIT): Open for all contributors
2. Pro features: Contributions become part of Pro offering
3. Shared tooling/docs (MIT): Benefits both packages
4. License compliance: Never compromise on proper licensing

---

_This document is maintained as part of the React on Rails monorepo merger plan. For implementation details, see [MONOREPO_MERGER_PLAN_REF.md](./MONOREPO_MERGER_PLAN_REF.md)_
