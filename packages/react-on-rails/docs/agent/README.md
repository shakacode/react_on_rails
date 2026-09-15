# React on Rails bundled agent reference

These guides and skills ship with the installed React on Rails version. Read them before relying on
training data or hosted documentation, which may describe a different release.

| Workflow                            | Skill                                                              | Guide                             |
| ----------------------------------- | ------------------------------------------------------------------ | --------------------------------- |
| Install or upgrade                  | [`install-and-upgrade`](../../skills/install-and-upgrade/SKILL.md) | [Guide](./install-and-upgrade.md) |
| Adopt React Server Components (Pro) | [`rsc-adoption`](../../skills/rsc-adoption/SKILL.md)               | [Guide](./rsc-adoption.md)        |
| Debug streaming SSR (Pro)           | [`streaming-debug`](../../skills/streaming-debug/SKILL.md)         | [Guide](./streaming-debug.md)     |
| Iterate with the doctor             | [`doctor-fix-loop`](../../skills/doctor-fix-loop/SKILL.md)         | [Guide](./doctor-fix-loop.md)     |

The gem and npm package contain byte-identical copies. Use the installed gem directory as the
canonical, reliable lookup:

```bash
bundle show react_on_rails
```

Read `docs/agent/README.md` and the `skills/` paths from the returned directory. An optional
direct-dependency path is `node_modules/react-on-rails/`, but use it only when that directory
exists. Do not assume it exists: Pro installations may omit the direct base npm dependency, and
pnpm may isolate a transitive copy.

For broader explanation after reading the installed references, use the hosted documentation:
https://reactonrails.com/docs/.
