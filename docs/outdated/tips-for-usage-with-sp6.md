# Tips for usage with Shakapacker 6

As mentioned earlier in the documentation, we assume you install ReactOnRails in a project with Shakapacker 7+ installed and configured. If you still use Shakapacker 6, we encourage you to check the upgrade to the version 7 guide. Otherwise, you need to consider the following:

1. The install generator tries to take the necessary steps to adapt the installed files to match the file structure and configurations for Shakapacker 6. So you don't need to be worried about the ReactOnRails installation process.

2. Check the following table to map the references in the documentation to the relevant ones in Shakapacker 6:

| Usage in Shakapacker 7       | Equivalent in Shakapacker 6 |
| ---------------------------- | --------------------------- |
| `config/shakapacker.yml`     | `config/webpacker.yml`      |
| `bin/shakapacker`            | `bin/webpacker`             |
| `bin/shakapacker-dev-server` | `bin/webpacker-dev-server`  |

3. Any environment variables starting with `SHAKAPACKER_*` should be changed to `WEBPACKER_*`.
