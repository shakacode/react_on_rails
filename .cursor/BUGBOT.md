# BugBot Rules for React on Rails

## License Scanning

If the PR modifies dependency files (package.json, pnpm-lock.yaml, yarn.lock, Gemfile, Gemfile.lock, gemspec), then:

- Run the built-in License Scan.
- If any new or upgraded dependency has a license in {GPL-2.0, GPL-3.0, AGPL-3.0}, then:
  - Add a blocking Bug titled "Disallowed license detected"
  - Include the offending package names, versions, and licenses in the Bug body
  - Apply labels "compliance" and "security"
- Note: Multi-licensed packages (e.g., "MIT OR GPL-2.0") are acceptable if at least one license is permissive.
