# Doctor-driven fix loop

Use the stable JSON form for agent and CI workflows:

```bash
bin/rails react_on_rails:doctor FORMAT=json
```

Standard output is one JSON document. The top-level `status`, `checks`, and `summary` describe the
run. Every check exposes a stable `id`, `status`, `severity`, `message`, `fix_command`, `docs_url`,
`remediation`, and `details` contract.

For every non-passing check, in array order:

1. Record `id` and `severity`.
2. Inspect `message`, `remediation.files`, and the current app state.
3. Use `remediation.prompt` and `remediation.expected_end_state` as bounded guidance.
4. Review the smallest corrective diff.
5. Rerun the JSON doctor and confirm the check passes without creating another failure.

Exit code `1` means at least one error remains. Warnings keep exit code `0`, so read `status` or
`summary.warn` when warning-free output matters. A `null` `fix_command` is expected; never infer an
unsafe global repair command from the check ID.

Secondary reference: https://reactonrails.com/docs/api-reference/doctor.
