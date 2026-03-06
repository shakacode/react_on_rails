# React on Rails Licensing FAQ

## Post-Monorepo Merger Licensing

### Q: What will happen to licensing after the monorepo merger?

**A:** Nothing changes for end users! We'll maintain the same dual licensing structure:

- **MIT Licensed (Free & Open Source):**
  - `react_on_rails` Ruby gem
  - `react-on-rails` NPM package
  - Core functionality remains completely free

- **Pro Licensed (Subscription Required for Production):**
  - `react_on_rails_pro` Ruby gem
  - `react-on-rails-pro` NPM package
  - `react-on-rails-pro-node-renderer` NPM package
  - Advanced features require valid subscription

### Q: Will package installation or usage change?

**A:** Yes. The Pro packages are now public instead of private:

- **Ruby:** Install `react_on_rails_pro` gem (it depends on `react_on_rails`)
- **JavaScript:** Install and import from `react-on-rails-pro` instead of `react-on-rails`

**Important:** Pro users should import from `react-on-rails-pro`, not `react-on-rails`. The Pro package re-exports all core features plus Pro-exclusive functionality:

```javascript
// Correct for Pro users
import ReactOnRails from 'react-on-rails-pro';
```

See the [Installation Guide](../react_on_rails_pro/docs/installation.md) for details.

### Q: How will the monorepo structure maintain license separation?

**A:** The monorepo will have clear directory-based license boundaries:

```
react_on_rails/ (monorepo root)
├── lib/
│   ├── react_on_rails/           # MIT Licensed
│   └── react_on_rails_pro/       # Pro Licensed
├── packages/
│   ├── react-on-rails/           # MIT Licensed
│   ├── react-on-rails-pro/       # Pro Licensed
│   └── react-on-rails-pro-node-renderer/  # Pro Licensed
└── LICENSE.md                    # Documents which directories use which license
```

### Q: What about contributing to the project?

**A:** Contributors should be aware of license boundaries:

- **MIT areas:** Anyone can contribute freely
- **Pro areas:** Contributions require agreement that improvements become part of the Pro offering
- **License compliance:** Never move Pro code into MIT-licensed directories

### Q: Will there be automated license compliance checking?

**A:** Yes! The monorepo will include automated checks to ensure:

- Pro files have proper license headers
- Pro code never accidentally enters MIT-licensed directories
- LICENSE.md accurately reflects all directory classifications
- CI fails if license compliance is violated

### Q: What if I'm currently using both packages?

**A:** Perfect! The monorepo makes this easier:

- Unified development and testing
- Coordinated releases when needed
- Shared tooling and documentation
- Same separate billing and licensing as today

### Q: Will documentation change?

**A:** Documentation will be enhanced:

- Combined docs show both free and pro features clearly
- Examples will be properly labeled by license
- Installation guides remain the same
- License boundaries clearly documented

### Q: When will this happen?

**A:** The merger is being executed in phased steps, each with CI checks and rollback options. See [Issue #2367: Merger Command Center](https://github.com/shakacode/react_on_rails/issues/2367) for the current checklist and status.

### Q: What if something goes wrong during the merger?

**A:** Each phase has:

- Complete rollback procedures
- Clear success criteria
- CI verification before proceeding
- Community feedback integration
- Immediate issue resolution process

---

## Current Licensing (Pre-Merger)

### Q: How does licensing work today?

**A:** We maintain two separate repositories:

- **react_on_rails** (MIT + Pro) - Core functionality is MIT-licensed and completely free. Pro features (in `pro/` directories) are Pro-licensed and require a subscription for production use
- **react_on_rails_pro** (Pro License) - Advanced features, subscription required for production

### Q: What requires a Pro subscription?

**A:** Pro features include:

- Server-side rendering optimizations
- Advanced caching strategies
- React Server Components support
- Node.js rendering process management
- Premium support and consultation

See [REACT-ON-RAILS-PRO-LICENSE.md](../REACT-ON-RAILS-PRO-LICENSE.md) for complete Pro license terms.

### Q: Can I modify the MIT-licensed interface files?

**A:** Yes! Under the MIT license, you can freely modify any MIT-licensed files (those outside `pro/` directories). However:

- **Permitted:** Modifying MIT-licensed code for your own purposes
- **Not Permitted:** Using those modifications to access Pro features without a valid license
- **Distinction:** The MIT license grants you modification rights, but the Pro License restricts unauthorized use of Pro features

### Q: Can I try Pro features for free?

**A:** Yes! Pro license allows free use for:

- Educational/classroom use
- Personal hobby projects
- Tutorials and demonstrations
- Non-production evaluation

Production use requires a valid subscription.

---

_For more information about the monorepo merger, see [Issue #2367: Merger Command Center](https://github.com/shakacode/react_on_rails/issues/2367)._
