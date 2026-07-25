# Golden generator output

Checked-in snapshots of what the React on Rails generator actually writes. Owned by
`spec/react_on_rails/generators/generator_golden_output_spec.rb`, which regenerates them
from the real templates and diffs the result.

**Do not hand-edit these files.** They are a record of generator output, not source. To
update them after an intentional template change:

```bash
cd react_on_rails && REGENERATE_GENERATOR_GOLDEN=1 \
  bundle exec rspec spec/react_on_rails/generators/generator_golden_output_spec.rb
```

Then read `git diff` on this directory before committing. An unreviewed regeneration turns
the gate into a rubber stamp, which is the failure mode it exists to prevent (issue #4787).

> **Adding a variant? Check the trailing newline.** The `trailing-newlines` hook in
> `.lefthook.yml` runs with `stage_fixed: true`, so a golden file that does not end in a
> newline is silently rewritten at commit time. The committed bytes then differ from
> generator output and the spec goes red for a reason that looks nothing like the cause.
> All files here end with a newline as committed; keep it that way.

## Layout

One directory per variant, mirroring the path the generator writes to, so the bundler
directory mapping (`config/webpack` vs `config/rspack`) is pinned too:

| Variant                     | Flags            | Pins                                     |
| --------------------------- | ---------------- | ---------------------------------------- |
| `webpack_base`              | `--no-rspack`    | Base OSS install                         |
| `webpack_pro`               | `--pro`          | Pro branches of the template             |
| `webpack_rsc`               | `--rsc`          | RSC branches + `RSCWebpackPlugin`        |
| `rspack_base`               | `--rspack`       | `config/rspack/` destination             |
| `rspack_pro`                | `--rspack --pro` | `config/rspack/` destination, Pro        |
| `rspack_rsc`                | `--rspack --rsc` | `RSCRspackPlugin` and its import path    |
| `webpack_base_shakapacker8` | `--no-rspack`    | Shakapacker < 9 hardcoded-output-path arm |

Shakapacker version detection is stubbed per variant so these files do not depend on
whichever Shakapacker version happens to be installed locally.

## Formatting

Prettier and ESLint both skip this directory via the `**/*generated*` ignore rule. That is
load-bearing: these files must stay byte-identical to generator output, so no formatter may
rewrite them.
