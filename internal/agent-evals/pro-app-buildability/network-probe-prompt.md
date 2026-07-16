Run exactly these two read-only capability probes from the current empty workspace:

1. `npm view create-react-on-rails-app version --json`
2. `gem search --remote --exact '^rails$'`

Do not create files, install packages, inspect other directories, or try alternate commands. Report each exact command and observed exit code. Set status to `completed` only when both exit 0; otherwise set status to `blocked` and name the failing capability. Human interventions are zero.
