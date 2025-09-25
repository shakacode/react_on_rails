# Licensing

- **Core**: MIT (this file)
- **Pro**: see [REACT-ON-RAILS-PRO-LICENSE.md](./REACT-ON-RAILS-PRO-LICENSE.md)

## LicenseRef-Proprietary

```
SPDX-License-Identifier: LicenseRef-Proprietary
```

The proprietary portions of this software are licensed under the React on Rails Pro License. See [REACT-ON-RAILS-PRO-LICENSE.md](./REACT-ON-RAILS-PRO-LICENSE.md) for complete terms.

**Proprietary directories:**

- `lib/react_on_rails/pro/`
- `node_package/src/pro/`

**Usage restrictions:**

- Pro features require a valid React on Rails Pro subscription
- Any attempt to circumvent license validation is prohibited
- See REACT-ON-RAILS-PRO-LICENSE.md for full terms and conditions

---

## MIT License for Core React on Rails

This license applies to all files within this repository, with the exception of the code located in the following directories, which are licensed separately under the React on Rails Pro License:

- `lib/react_on_rails/pro/`
- `node_package/src/pro/`

**Important:** The Pro-licensed directories contain code that is included in this package but requires a valid React on Rails Pro subscription to function. Any attempt to circumvent, bypass, modify, or disable the license validation mechanisms is strictly prohibited and constitutes a violation of this license and the React on Rails Pro License.

**Critical:** The MIT-licensed code that imports or interfaces with Pro-licensed modules (including but not limited to clientStartup.ts, serverRenderReactComponent.ts, ReactOnRails.client.ts, and ReactOnRails.node.ts) is protected by this license. Any modification, patching, or circumvention of these interface modules to enable unauthorized access to Pro features is strictly prohibited and constitutes a violation of this license and the React on Rails Pro License.

**Ruby License Validation Protection:** The MIT-licensed Ruby code that performs license validation and generates the `rails_context` (including but not limited to lib/react_on_rails/helper.rb, lib/react_on_rails/utils.rb, and any code that calls `ReactOnRails::Utils.react_on_rails_pro?` or generates the `rorPro` field) is protected by this license. Any modification, patching, or circumvention of these license validation mechanisms to enable unauthorized access to Pro features is strictly prohibited and constitutes a violation of this license and the React on Rails Pro License.

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

The code in the directories listed above is part of the React on Rails Pro framework and is licensed under the React on Rails Pro License.

You can find the full text of the license agreement here:
[REACT-ON-RAILS-PRO-LICENSE.md](./REACT-ON-RAILS-PRO-LICENSE.md)
