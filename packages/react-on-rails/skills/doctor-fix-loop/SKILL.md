---
name: doctor-fix-loop
description: >
  Use when diagnosing a React on Rails app with the stable doctor JSON contract and
  iterating through actionable remediation until no error-level checks remain.
---

# Run the doctor fix loop

Read the [version-matched package guide](../../docs/agent/doctor-fix-loop.md), then run:

```bash
bin/rails react_on_rails:doctor FORMAT=json
```

1. Parse standard output as one JSON document; treat incidental standard-error output as diagnostics.
2. Process non-passing checks in array order using their stable `id`, `severity`, `message`,
   `remediation.prompt`, `remediation.files`, and `remediation.expected_end_state` fields.
3. Inspect the named files and verify the diagnosis before editing. Do not invent a broad automatic
   fix from a check ID, and do not treat a nullable `fix_command` as required.
4. Make the smallest correction, review its diff, and rerun the doctor.
5. Continue until the report has no error-level checks. Warnings are advisory but should be reported.
6. Run the focused build or test that exercises each repaired subsystem.

The hosted JSON contract is a secondary reference:
https://reactonrails.com/docs/api-reference/doctor.
