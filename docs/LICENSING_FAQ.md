# React on Rails Licensing FAQ

## Licensing

### Q: How does licensing work?

**A:** React on Rails uses a dual licensing structure:

- **MIT Licensed (Free & Open Source):**
  - `react_on_rails` Ruby gem
  - `react-on-rails` NPM package
  - Core functionality is completely free

- **ShakaCode Trust-Based Commercial Licensing (free for most uses; subscription for production use by larger organizations):**
  - `react_on_rails_pro` Ruby gem
  - `react-on-rails-pro` NPM package
  - `react-on-rails-pro-node-renderer` NPM package
  - Development, test, CI, staging, preview and review apps, education, personal projects, and open-source projects are free for everyone
  - Production is free for small organizations, charities, educational institutions, and hospitals

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

### Q: What requires a paid Pro license?

**A:** Production use by an organization above the small-organization line requires a subscription.

React on Rails (the `react_on_rails` gem and the `react-on-rails` package) is
open source under the MIT License, the same license as Inertia Rails.

React on Rails Pro adds React Server Components, streaming SSR, fragment
caching, and the dedicated Node renderer, under The React on Rails Pro License,
a trust-based commercial license:

- **Free for everyone, at any organization size:** development, test, CI,
  staging, preview and review apps (no license key needed), education, personal
  projects, open-source projects, and a 45-day production evaluation.
- **Free in production for small organizations:** under 10 people, under US $1M
  revenue in the last twelve months, and under US $1M raised, counted with
  affiliates. Charities, educational institutions, and hospitals are free at
  any size.
- **Everyone else subscribes for production use:** $1,800 per year per
  organization, covering every application, environment, and developer, with
  updates and maintainer support. Subscribe at
  [pro.reactonrails.com](https://pro.reactonrails.com/).
- **No license key is required to run anything,** nothing phones home, and
  nothing breaks: a missing key only changes one HTML comment from `Licensed`
  to `UNLICENSED`. If a subscription lapses, production stays licensed for 30
  days.
- **Terms are per version:** once a release ships under these terms, they never
  tighten on that release.

Full text:
[REACT-ON-RAILS-PRO-LICENSE.md](https://github.com/shakacode/react_on_rails/blob/main/REACT-ON-RAILS-PRO-LICENSE.md).
Questions: [contact@shakacode.com](mailto:contact@shakacode.com).

### Q: Can I try Pro features for free?

**A:** Yes. Reading and studying the source, development, test, CI, staging,
preview and review apps, education, training, tutorials, demonstrations,
academic research, personal projects, and qualifying open-source projects are
free for everyone. Every organization also gets one 45-day production
evaluation.

### Q: Is Pro free for my company?

**A:** Production use is free if you can answer yes to all three questions,
counted with affiliates: do fewer than 10 people work for your organization,
was revenue in the last twelve months under US $1M, and has it raised under US
$1M in outside capital? Charities, educational institutions, and hospitals are
free at any size. If any answer is no and none of those categories applies,
subscribe at [pro.reactonrails.com](https://pro.reactonrails.com/).

### Q: What happens if we do not configure a license key?

**A:** Nothing breaks. The app runs normally, logs report the license status,
and the HTML attribution comment reads `UNLICENSED` instead of `Licensed`.

### Q: What happens when a subscription lapses?

**A:** Production use stays licensed for 30 days while you renew or wind down.
The software keeps running either way.

### Q: We are an agency building for clients. Who needs the license?

**A:** The client organization is the licensee, and its size determines whether
production use is free or paid. You may rely on the client's written
self-certification of its status.

### Q: How does this compare with Inertia?

**A:** Comparing with Inertia Rails? React on Rails and Inertia Rails are both
MIT. The only paid part of this stack is React on Rails Pro, and only in
production at organizations above the small-organization line. That subscription
buys what Inertia Rails does not have today: React Server Components, streaming
SSR with selective hydration, fragment caching, and per-component adoption
inside existing Rails views. Already on Inertia? Both gems coexist in one app,
so you can migrate route by route: see the
[Inertia Rails migration guide](./oss/migrating/migrating-from-inertia-rails.md).

### Q: Can I modify the MIT-licensed interface files?

**A:** Yes! Under the MIT license, you can freely modify any MIT-licensed files (those outside the Pro-licensed directories). However:

- **Permitted:** Modifying MIT-licensed code for your own purposes
- **Pro boundary:** The MIT license governs the core files, while the Pro packages remain governed by The React on Rails Pro License

### Q: What about contributing to the project?

**A:** Contributors should be aware of license boundaries:

- **MIT areas:** Anyone can contribute freely
- **Pro areas:** Contributions require agreement that improvements become part of the Pro offering
- **License compliance:** Never move Pro code into MIT-licensed directories

For directory-level details and developer guidelines, see [DIRECTORY_LICENSING.md](./DIRECTORY_LICENSING.md).
