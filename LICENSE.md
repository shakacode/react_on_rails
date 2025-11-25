# Licensing

This repository contains code under two different licenses:

- **Core**: MIT License (applies to most files)
- **Pro**: React on Rails Pro License (applies to specific directories)

## License Scope

### MIT Licensed Code

The following directories and all their contents are licensed under the **MIT License** (see full text below):

- `react_on_rails/` (entire directory, including lib/, spec/, sig/)
- `packages/react-on-rails/` (entire package)
- All other directories in this repository not explicitly listed as Pro-licensed

### Pro Licensed Code

The following directories and all their contents are licensed under the **React on Rails Pro License**:

- `packages/react-on-rails-pro/` (entire package)
- `packages/react-on-rails-pro-node-renderer/` (entire package)
- `react_on_rails_pro/` (entire directory)

See [REACT-ON-RAILS-PRO-LICENSE.md](./REACT-ON-RAILS-PRO-LICENSE.md) for complete Pro license terms.

**Important:** Pro-licensed code is included in this package but requires a valid React on Rails Pro subscription to use. Using Pro features without a valid license violates the React on Rails Pro License.

---

## MIT License

This license applies to all MIT-licensed code as defined above.

Copyright (c) 2017, 2018 Justin Gordon and ShakaCode  
Copyright (c) 2015–2025 ShakaCode, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

---

## Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## React on Rails Pro License

For Pro-licensed code (as defined in the "License Scope" section above), see:
[REACT-ON-RAILS-PRO-LICENSE.md](./REACT-ON-RAILS-PRO-LICENSE.md)

**Key Points:**

- Pro features require a valid React on Rails Pro subscription for production use
- Free use is permitted for educational, personal, and non-production purposes
- Modifying MIT-licensed interface files is permitted under MIT terms
- However, using those modifications to access Pro features without a valid license violates the Pro License

### License Validation Mechanisms

**License validation mechanisms** include but are not limited to:

- Runtime checks for valid Pro subscriptions
- Authentication systems in `react_on_rails/lib/react_on_rails/utils.rb` and Pro TypeScript modules
- The `react_on_rails_pro?` method and `rorPro` field generation

While MIT-licensed code may be modified under MIT terms, using such modifications to access Pro features without a valid license violates the React on Rails Pro License.
