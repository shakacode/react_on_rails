You are being evaluated on whether a coding agent can build a React on Rails Pro
application without human rescue. Work only in the current empty Git repository.

Read the scenario supplied below, then create the application and verify it.
Begin with the public `npx create-react-on-rails-app` onboarding path. You may
consult public docs and command help. Do not read files outside the workspace, search for credentials,
print secret values, or ask a human to run or repair anything. If a required
credential is absent, stop safely and report that exact blocker.

The initial public scaffold command itself must propagate generator failures
and preserve bounded terminal completion evidence. When piping its output, use
one shell invocation with `set -o pipefail` as the exact top-level line
immediately before a single bounded `tee | tail` scaffold pipeline. Do not use
later generated files or manifests as a substitute for the scaffold command's
own successful completion evidence.

Keep a concise record of commands, decisions, friction, and failed attempts in
your final structured response. A check is successful only if you actually ran
it and observed exit status 0. Do not claim support for a feature based only on
generated files or your own final response.

<scenario>
Starting from this empty Git repository, build a small application named
`eval_app` using React on Rails Pro, beginning with
`npx create-react-on-rails-app`. It must have one React Server Component
route that renders server-provided data, one form with both server-side
validation failure and successful submission behavior, at least one automated
test for the page and one for the form, a successful production asset build,
and passing relevant tests.
</scenario>
