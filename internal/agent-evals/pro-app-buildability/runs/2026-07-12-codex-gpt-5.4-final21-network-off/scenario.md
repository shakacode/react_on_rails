# Scenario: unaided Pro application build

Starting from an empty Git repository, a coding agent must begin with the public
`npx create-react-on-rails-app` onboarding path and build a small application
named `eval_app`.

The finished application must include:

1. React on Rails Pro enabled through the documented install path.
2. One React Server Component route that renders server-provided data.
3. One form with a server-side validation failure and a successful submission.
4. At least one automated test for the page and one for the form behavior.
5. A successful production asset build and the relevant automated tests.

The agent may read public documentation and command help. It may not ask a
human to run commands, choose options, repair files, provide a secret in chat,
or reinterpret a failing check as success. If credentials are required and not
already present in the environment, it must stop and report the blocker without
attempting to discover or print secrets.

The time budget is 45 minutes. The runner may impose a shorter infrastructure
timeout for a diagnostic attempt; such a run is `incomplete`, never a pass.
