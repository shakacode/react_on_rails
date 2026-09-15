---
name: rsc-adoption
description: >
  Use when adopting React Server Components in a React on Rails Pro app, including
  prerequisites, generator setup, component boundaries, data flow, and safety checks.
---

# Adopt React Server Components (Pro)

React Server Components are a React on Rails Pro workflow. Read the
[version-matched package guide](../../docs/agent/rsc-adoption.md) before changing setup.

1. Confirm the app uses the Pro gem and matching Pro npm packages, the Node renderer,
   and compatible React, React DOM, and RSC package releases.
2. Preserve the app's language on the supported setup path: use
   `bundle exec rails generate react_on_rails:rsc --typescript` for TypeScript apps and
   `bundle exec rails generate react_on_rails:rsc` for JavaScript apps. Review every generated change.
3. Treat the `'use client'` directive as the RSC boundary. Do not confuse it with
   `.client.` and `.server.` filename suffixes, which control bundle placement.
4. Keep Rails-owned data, authentication, authorization, and caching on the Rails side;
   pass data through props or async props rather than assuming server components can
   access Rails process state.
5. Run `bundle exec rake react_on_rails:install_rsc_agent_guardrails` and review payload
   route authorization, renderer isolation, secret handling, and serialized output.
6. Run the JSON doctor, build all required bundles, and exercise the RSC route in a browser.

Hosted RSC docs are a secondary reference:
https://reactonrails.com/docs/pro/react-server-components.
