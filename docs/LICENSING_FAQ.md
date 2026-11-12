# React on Rails Licensing FAQ

## Licensing

### How does licensing work?

React on Rails core, including the `react_on_rails` gem and `react-on-rails` npm package, remains under the MIT License. React on Rails Pro, including its gem, Node renderer, and `react-on-rails-rsc`, is governed by [The ShakaStack License, version 1.0, applied to React on Rails Pro](../REACT-ON-RAILS-PRO-LICENSE.md). Each released version keeps the terms it shipped with.

### What does ShakaStack Pro include?

One ShakaStack Pro subscription covers React on Rails Pro, ShakaPerf, and Inertia Rails SSR Cache for the whole organization, including every affiliate, application, environment, repository, and developer. There is no limit on headcount or revenue. It costs US $1,800 per year per organization at [pro.reactonrails.com](https://pro.reactonrails.com/), with Slack support. An active React on Rails Pro subscription already counts as ShakaStack Pro.

### What use of React on Rails Pro is free?

Development, test, CI, staging, preview, and review environments used solely to prepare an application before production are free for everyone. Production means serving real users or doing background work that supports a live application, whatever the environment is called. A genuine evaluation of covered use lasts up to 45 consecutive days. The rule about free development and CI applies to React on Rails Pro, not to every ShakaStack product. ShakaPerf has its own free use rules, and ongoing use in CI can require a subscription.

Production use is also free for an organization that answers yes to all three questions across its affiliates: do fewer than 10 people perform paid work for it, was its revenue in the last twelve months under US $1M, and has it raised under US $1M in outside capital ever? Charities, educational institutions, and hospitals are free at any size. Other production use requires ShakaStack Pro.

### Is a license key required?

No. A key is optional and only changes the attribution status on rendered pages and in logs. The software keeps running when a key is missing, invalid, or expired. A key does not replace the subscription requirement for covered use.

### What happens when a subscription ends?

Covered use under The ShakaStack License stays licensed for 30 days while you renew or wind down. The software keeps running. Earlier releases keep their own terms.

### Who pays for client work?

The organization whose business the work ultimately serves must qualify for free use or hold a subscription. Contractors work under that organization's coverage. An agency's subscription covers its own work, not its clients.

### How do I install the Pro packages?

Install `react_on_rails_pro` for Ruby. For JavaScript, install and import from `react-on-rails-pro`, which includes the core exports and Pro features. See the [installation guide](./pro/installation.md).

### How does the monorepo maintain license separation?

The `react_on_rails/` gem and `packages/react-on-rails/` package are MIT. The `react_on_rails_pro/`, `packages/react-on-rails-pro/`, and `packages/react-on-rails-pro-node-renderer/` trees contain Pro code. See [LICENSE.md](../LICENSE.md) and [DIRECTORY_LICENSING.md](./DIRECTORY_LICENSING.md) for the directory rules. Do not move Pro code into an MIT directory.

### How does this compare with Inertia Rails?

React on Rails core and Inertia Rails remain MIT. ShakaStack Pro includes the separate Inertia Rails SSR Cache product as well as React on Rails Pro and ShakaPerf. Each product has its own covered and free uses under its license edition.

Questions: [contact@shakacode.com](mailto:contact@shakacode.com).
