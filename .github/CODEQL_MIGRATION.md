# CodeQL: Disable Default Setup Before Merging PR #2884

PR #2884 adds a CodeQL advanced setup workflow that replaces the current default setup. GitHub does not allow both to run simultaneously — the advanced workflow will fail until the default is disabled.

## Steps (requires admin access)

1. Go to https://github.com/shakacode/react_on_rails/settings/security_analysis
2. Find the **"CodeQL analysis"** row
3. Click the **three-dot menu** (⋮) to the right
4. Click **"Disable CodeQL"**
5. Confirm in the popup
6. Merge PR #2884

## Or via CLI

```bash
gh api --method PATCH repos/shakacode/react_on_rails/code-scanning/default-setup -f state=not-configured
```

## Notes

- Existing alerts are NOT deleted — they remain visible until the advanced workflow produces new results.
- After merge, the advanced workflow runs on push/PR to `main` and weekly (Monday 6am UTC).
- The advanced workflow excludes `tests/fixtures/` and `spec/dummy/` from scanning to eliminate false positives from build artifacts and test apps.
- This file can be deleted after the migration is complete.
