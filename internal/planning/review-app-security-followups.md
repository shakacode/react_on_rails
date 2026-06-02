# Review App Security Followups Implementation Plan

**Goal:** Document and propagate safe review-app defaults for public React on Rails, React on Rails Pro, Control Plane
Flow, and the main demo/starter apps.

**Architecture:** Start with policy documentation in React on Rails, then update Control Plane Flow as the canonical
platform guidance, then regenerate or patch downstream demo/starter app docs and wrappers. Keep code workflow changes
minimal until the reusable Control Plane Flow guidance is updated.

**Tech Stack:** Markdown docs, GitHub Actions, Control Plane Flow (`cpflow`), Control Plane (`cpln`), Rails review apps.

## Task 1: React on Rails Review-App Security Docs

Files:

- Create `docs/oss/deployment/review-app-security.md`.
- Modify `docs/oss/deployment/README.md`.
- Create `docs/pro/deployment/review-app-security.md`.
- Modify `docs/pro/react-on-rails-pro.md` and `docs/README.md`.

Steps:

- Add OSS review-app security guidance covering untrusted PR code, same-repository auto-deploys, fork PR maintainer
  approval, disposable resources, production-like runtime mode, and test/development endpoint exposure.
- Link the OSS doc from deployment docs.
- Add Pro-specific review-app security guidance covering `REACT_ON_RAILS_PRO_LICENSE`, unlicensed review apps, node
  renderer credentials, isolated review orgs/GVCs, and disposable secrets.
- Link the Pro doc from the Pro route map and top-level docs guide.
- Verify docs formatting and links.

## Task 2: Control Plane Flow Canonical Guidance

Files:

- Modify `docs/ci-automation.md`.
- Modify `docs/secrets-and-env-values.md`.
- Optionally modify generated GitHub Actions docs/help templates if the active checkout contains them.

Steps:

- Add a "Review App Security for Public Repositories" section.
- Clarify that fork PRs must not auto-deploy and maintainer-triggered fork deploys still execute attacker-controlled
  code.
- Recommend a dedicated review-app Control Plane org or tightly scoped service account.
- Warn against reusing staging/production tokens or broad `superusers` tokens for public review apps.
- Clarify that `cpln://secret/...` protects storage/config, but any secret mounted into a review-app workload can be
  read by deployed PR code.
- Document the safe generated wrapper shape for same-repository auto-deploys and maintainer comment deploys.

## Task 3: Main Demo And Starter App PRs

Repositories:

- `shakacode/react-webpack-rails-tutorial`
- `shakacode/react-on-rails-hn-rsc-demo`
- `shakacode/react-server-components-marketplace-demo`
- `shakacode/react-on-rails-template`

Steps:

- Patch `react-webpack-rails-tutorial` `.controlplane/readme.md` and `.github/cpflow-help.md`; review whether
  `DOCKER_BUILD_SSH_KEY` is required for review-app builds.
- Patch `react-on-rails-hn-rsc-demo` `.controlplane/readme.md` and `.github/cpflow-help.md`; split or document
  `REACT_ON_RAILS_PRO_LICENSE` so review apps do not receive production-like license secrets by default.
- Patch `react-server-components-marketplace-demo` Control Plane docs before review apps are enabled; call out
  `REACT_ON_RAILS_PRO_LICENSE`, `RENDERER_PASSWORD`, `DATABASE_URL`, and `SECRET_KEY_BASE`.
- Patch `react-on-rails-template` starter documentation or generated template snippets so new apps inherit the safe
  review-app language from Control Plane Flow.

## Task 4: PR Sequencing

- Open the React on Rails docs PR first.
- Open the Control Plane Flow docs PR next.
- Patch downstream demo/starter repositories after Control Plane Flow wording is settled.
- For each docs-only PR, run the repo's markdown formatting/check command when available. For workflow wrapper changes,
  run the repo's generated GitHub Actions test command if present, such as `bin/test-cpflow-github-flow`.
