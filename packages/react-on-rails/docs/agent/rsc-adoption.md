# React Server Components adoption (Pro)

React Server Components require React on Rails Pro. Use the generator and installed package contracts;
do not reconstruct the RSC build or renderer protocol from memory.

## Adoption sequence

1. Confirm the Pro gem/npm packages, Node renderer, React, React DOM, and RSC package are compatible.
2. Run `bundle exec rails generate react_on_rails:rsc` and review the generated client, server, and
   RSC bundle configuration.
3. Move one leaf at a time. The `'use client'` directive marks the server-to-client boundary, not
   every module that will execute on the client. Modules imported below that boundary remain client code
   even when they lack the directive; place it only where a subtree needs browser APIs, state, effects,
   or event handlers.
4. Keep `.client.` and `.server.` suffixes conceptually separate: they select bundle placement and do
   not classify React Server Components.
5. Keep Rails-owned data and security decisions in Rails. Supply data through props or async props;
   server components do not gain in-process access to Rails models, sessions, or cookies.
6. Install the app safety guardrails and review the generated skill and advisory hook:

```bash
bundle exec rake react_on_rails:install_rsc_agent_guardrails
bin/rails react_on_rails:doctor FORMAT=json
```

Before completion, protect any RSC payload route, keep the Node renderer private, avoid sensitive
logged props or URLs, build all three bundles, and exercise navigation and hydration in a browser.

Secondary reference: https://reactonrails.com/docs/pro/react-server-components.
