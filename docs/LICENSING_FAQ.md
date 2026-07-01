# React on Rails Licensing FAQ

## Licensing

### Q: How does licensing work?

**A:** React on Rails uses a dual licensing structure:

- **MIT Licensed (Free & Open Source):**
  - `react_on_rails` Ruby gem
  - `react-on-rails` NPM package
  - Core functionality is completely free

- **ShakaCode Trust-Based Commercial Licensing (Subscription Required for Production):**
  - `react_on_rails_pro` Ruby gem
  - `react-on-rails-pro` NPM package
  - `react-on-rails-pro-node-renderer` NPM package
  - Advanced features can be evaluated without a token; production deployments require a paid license

### Q: How do I install and use the packages?

**A:** The Pro packages are public:

- **Ruby:** Install the `react_on_rails_pro` gem (it depends on `react_on_rails`)
- **JavaScript:** Install and import from `react-on-rails-pro` instead of `react-on-rails`

**Important:** Pro users should import from `react-on-rails-pro`, not `react-on-rails`. The Pro package re-exports all core features plus Pro-exclusive functionality:

```javascript
// Correct for Pro users
import ReactOnRails from 'react-on-rails-pro';
```

See the [Installation Guide](./pro/installation.md) for details.

### Q: How does the monorepo maintain license separation?

**A:** The monorepo has clear directory-based license boundaries:

```text
react_on_rails/ (monorepo root)
├── react_on_rails/                       # MIT Licensed (core Ruby gem)
├── react_on_rails_pro/                   # Pro Licensed (Pro Ruby gem)
├── packages/
│   ├── react-on-rails/                   # MIT Licensed
│   ├── react-on-rails-pro/               # Pro Licensed
│   └── react-on-rails-pro-node-renderer/ # Pro Licensed
└── LICENSE.md                            # Documents which directories use which license
```

See [LICENSE.md](../LICENSE.md) for the authoritative list of which directories fall under which license.

### Q: What requires a Pro subscription?

**A:** React on Rails Pro is offered under ShakaCode Trust-Based Commercial Licensing. A paid license is required for production deployments that use Pro features, including:

- Server-side rendering optimizations
- Advanced caching strategies
- React Server Components support
- Node.js rendering process management
- Premium support and consultation

See [REACT-ON-RAILS-PRO-LICENSE.md](https://github.com/shakacode/react_on_rails/blob/main/REACT-ON-RAILS-PRO-LICENSE.md) for complete Pro license terms.

### Q: Can I try Pro features for free?

**A:** Yes! Under ShakaCode Trust-Based Commercial Licensing, no license token is required for:

- Evaluation and local development
- Test environments and CI/CD pipelines
- Staging and other non-production deployments
- Educational, tutorial, and demonstration use

Production use requires a paid production license.

### Q: Can I modify the MIT-licensed interface files?

**A:** Yes! Under the MIT license, you can freely modify any MIT-licensed files (those outside the Pro-licensed directories). However:

- **Permitted:** Modifying MIT-licensed code for your own purposes
- **Not Permitted:** Using those modifications to access Pro features without a valid license
- **Distinction:** The MIT license grants you modification rights, but ShakaCode Trust-Based Commercial Licensing restricts unauthorized use of Pro features

### Q: What about contributing to the project?

**A:** Contributors should be aware of license boundaries:

- **MIT areas:** Anyone can contribute freely
- **Pro areas:** Contributions require agreement that improvements become part of the Pro offering
- **License compliance:** Never move Pro code into MIT-licensed directories

For directory-level details and developer guidelines, see [DIRECTORY_LICENSING.md](./DIRECTORY_LICENSING.md).
