# Examples Catalog and Repo Naming Plan

## Goals

1. Make React on Rails and React on Rails Pro example repos easy to discover on
   GitHub.
2. Make `reactonrails.com/examples` a clean marketing catalog rather than a
   random list of historical repos.
3. Keep canonical taxonomy and example guidance in `react_on_rails/docs/`.
4. Reduce future docs churn by routing doc references through one maintained
   examples page instead of repeating repo slugs everywhere.

## Naming Decision

Use these public repo prefixes for anything we want to market actively:

| Type     | Pattern                     | Why                                                         |
| -------- | --------------------------- | ----------------------------------------------------------- |
| Demo     | `react-on-rails-demo-*`     | Best for evaluation apps, benchmarks, and feature showcases |
| Example  | `react-on-rails-example-*`  | Best for focused migration and implementation references    |
| Tutorial | `react-on-rails-tutorial-*` | Best for repos that map directly to docs or video lessons   |

Keep package and product repos as-is:

- `react_on_rails`
- `react_on_rails_pro`
- `react_on_rails_rsc`

Those names are package identities, not marketing slugs.

## Repos to Feature Publicly

These are the repos we should feature on `reactonrails.com/examples` and point
to from the docs:

| Public repo                           | Recommended action | Canonical status          | Notes                                     |
| ------------------------------------- | ------------------ | ------------------------- | ----------------------------------------- |
| `react-on-rails-demo-ssr-hmr`         | Feature            | Rename completed          | Maintained SSR + HMR tutorial repo        |
| `react-on-rails-rsc-demo`             | Feature            | Keep current slug for now | Minimal public RSC starter                |
| `react-on-rails-demo-hacker-news-rsc` | Feature            | Rename completed          | Compact Pro + RSC showcase                |
| `react-on-rails-demo-marketplace-rsc` | Feature            | Rename completed          | Performance-focused RSC demo              |
| `react-on-rails-demo-gumroad-rsc`     | Feature            | Rename completed          | Inertia vs React on Rails Pro benchmark   |
| `react-on-rails-example-migration`    | Feature            | Rename completed          | Focused `react-rails` migration reference |
| `react-on-rails-example-open-flights` | Feature            | Rename completed          | Larger migration reference                |
| `react-on-rails-demos`                | Feature            | Rename completed          | Shared infrastructure repo for demo apps  |

## Repos to De-emphasize or Archive

These should not appear on the primary public examples page. Some can stay
public for historical reference, but they should be archived or treated as
legacy once the current catalog is in place.

| Repo                                                             | Recommended action           | Reason                                                          |
| ---------------------------------------------------------------- | ---------------------------- | --------------------------------------------------------------- |
| `react_on_rails-hacker-news-app`                                 | Archive or de-emphasize      | Duplicate Hacker News concept; keep one canonical HN repo       |
| `spike-react-on-rails-tutorial-v15-with-rspack`                  | De-emphasize                 | Useful engineering spike, weak marketing name                   |
| `react_on_rails-v16-generator-playground`                        | De-emphasize                 | Playground/test utility, not a user-facing example              |
| `react_on_rails-demo-v16-ssr-auto-registration-bundle-splitting` | De-emphasize or rename later | Valuable topic, but current slug is too long and version-heavy  |
| `react_on_rails-demo-16-4-0-rc5`                                 | Archive                      | Release snapshot, not a maintained example                      |
| `test-react-on-rails-v12`                                        | Archive                      | Version-specific test repo                                      |
| `test-react-on-rails-v12-no-sprockets`                           | Archive                      | Version-specific test repo                                      |
| `test-react-on-rails-plus-webpacker-v4`                          | Archive                      | Version-specific tutorial repo                                  |
| `react_on_rails-tutorial-v11`                                    | Archive                      | Older tutorial generation                                       |
| `v8-demo`                                                        | Archive                      | Historical version demo                                         |
| `old-react-on-rails-examples`                                    | Archive                      | Already marked outdated by name                                 |
| `react_on_rails-with-webpacker`                                  | Archive                      | Historical integration prototype                                |
| `react_on_rails-update-webpack-v2`                               | Archive                      | Historical upgrade experiment                                   |
| `react_on_rails-test-new-redux-generation`                       | Archive                      | PR-specific experiment repo                                     |
| `react_on_rails-generator-results`                               | Archive                      | Generator output snapshot                                       |
| `react_on_rails-generator-results-pre-0`                         | Archive                      | Generator output snapshot                                       |
| `react_on_rails-generator-results-testing`                       | Archive                      | Generator output snapshot                                       |
| `react_actioncable_counter`                                      | De-emphasize                 | Narrow feature demo, not a primary entry point                  |
| `rails-tutorial-with-react-on-rails`                             | De-emphasize                 | Historical tutorial adaptation                                  |
| `egghead-tutorial-react-on-rails-v6.3.1-create-component`        | Archive or de-emphasize      | Video-course artifact                                           |
| `egghead-add-redux-component-to-react-on-rails`                  | Archive or de-emphasize      | Video-course artifact                                           |
| `react-webpack-rails-tutorial`                                   | De-emphasize                 | Legacy full app; still useful, but not a primary modern starter |

## Internal Repos

Operational or private repos can matter for maintenance work, but they should
not appear in public catalogs or public-facing docs. Keep those references in
private planning material only.

## Docs and Site Follow-up

1. Keep a canonical examples/reference page in `react_on_rails/docs/`.
2. Use `reactonrails.com/examples` as the marketing-forward catalog.
3. Replace hard-coded repo links in docs with the maintained examples page when
   the repo itself is not the main point.
4. Update GitHub descriptions and topics for all featured repos:
   - `react-on-rails`
   - `react-on-rails-pro`
   - `react-server-components`
   - `ruby-on-rails`
   - `shakapacker`
   - `rspack` where applicable
   - `migration`, `benchmark`, or `demo` as appropriate

## Execution Order

1. Update docs and `reactonrails.com/examples` first.
2. Verify GitHub redirects for completed renames before removing any legacy
   slugs from docs or issue references.
3. Update repo descriptions and topics.
4. Archive or de-emphasize legacy repos after the new catalog is live.
