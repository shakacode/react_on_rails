# Directory Licensing Documentation

This document outlines the directory-based licensing structure of the React on Rails monorepo. [LICENSE.md](../LICENSE.md) is the authoritative source for which directories use which license.

## Directory Structure

The repository is a monorepo containing two Ruby gems and three NPM packages under two licenses.

### MIT Licensed Directories

```text
react_on_rails/ (monorepo root)
├── react_on_rails/                  # Core Ruby gem (including lib/, spec/, sig/)
├── packages/react-on-rails/         # Core NPM package (including tests)
├── docs/                            # Documentation
├── .github/                         # GitHub workflows
└── [all other directories]          # MIT unless listed as Pro below
```

### Pro Licensed Directories

```text
react_on_rails/ (monorepo root)
├── react_on_rails_pro/                          # Pro Ruby gem (including specs)
├── packages/react-on-rails-pro/                 # Pro NPM package (including tests)
└── packages/react-on-rails-pro-node-renderer/   # Pro Node renderer (including tests)
```

**Important Distinction:**

- **MIT-licensed interface files** (outside the Pro-licensed directories) can be freely modified under MIT terms
- **Using those modifications to access Pro features** without a license violates the Pro License
- **Pro-licensed files** require a Pro license to use in any way

## License Compliance Rules

### File-Level Compliance

1. **Directory-Based Licensing**: Files inherit their license from the directory they are located in
2. **No Mixed Directories**: Each directory is either entirely MIT or entirely Pro — no mixed licensing within a directory
3. **Clear Boundaries**: [LICENSE.md](../LICENSE.md) explicitly lists which directories fall under which license

### Package-Level Compliance

1. **Gemspec Files**:
   - `react_on_rails/react_on_rails.gemspec`: `s.license = "MIT"`
   - `react_on_rails_pro/react_on_rails_pro.gemspec`: `s.license = "LicenseRef-LICENSE"`

2. **Package.json Files**:
   - `packages/react-on-rails/package.json`: `"license": "SEE LICENSE IN LICENSE.md"` (MIT)
   - `packages/react-on-rails-pro/package.json`: `"license": "SEE LICENSE IN LICENSE.md"`
   - `packages/react-on-rails-pro-node-renderer/package.json`: `"license": "SEE LICENSE IN LICENSE.md"`

### Critical Compliance Points

1. **Never Move Pro Code to MIT Directories**: No Pro-licensed code may end up in MIT-licensed directories.

2. **Update LICENSE.md Immediately**: Whenever directories are moved or created, `LICENSE.md` must be updated to reflect the new structure. It is the source of truth for directory licensing.

3. **Keep License Fields Accurate**: Each package's `package.json` and gemspec must declare the correct license for its directory.

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
2. Pro features: Contributions become part of the Pro offering
3. Shared tooling/docs (MIT): Benefits both packages
4. License compliance: Never compromise on proper licensing

---

_For licensing questions, see [LICENSING_FAQ.md](./LICENSING_FAQ.md) and [LICENSE.md](../LICENSE.md)._
