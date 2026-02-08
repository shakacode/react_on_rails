# RBS Type Checking

React on Rails uses RBS (Ruby Signature) for static type checking with Steep.

## Quick Start

- **Validate signatures**: `bundle exec rake rbs:validate` (run by CI)
- **Run type checker**: `bundle exec rake rbs:steep` (currently disabled in CI due to existing errors)
- **Run both**: `bundle exec rake rbs:all`
- **List RBS files**: `bundle exec rake rbs:list`
- **Runtime checking**: Enabled by default in tests when `rbs` gem is available

## Runtime Type Checking

Runtime type checking is **ENABLED BY DEFAULT** during test runs for:

- `rake run_rspec:gem` - Unit tests
- `rake run_rspec:dummy` - Integration tests
- `rake run_rspec:dummy_no_turbolinks` - Integration tests without Turbolinks

**Performance Impact**: Runtime type checking adds overhead (typically 5-15%) to test execution. This is acceptable during development and CI as it catches type errors in actual execution paths that static analysis might miss.

To disable runtime checking (e.g., for faster test iterations during development):

```bash
DISABLE_RBS_RUNTIME_CHECKING=true rake run_rspec:gem
```

**When to disable**: Consider disabling during rapid test-driven development cycles where you're running tests frequently. Re-enable before committing to catch type violations.

## Adding Type Signatures

When creating new Ruby files in `lib/react_on_rails/`:

1. **Create RBS signature**: Add `sig/react_on_rails/filename.rbs`
2. **Add to Steepfile**: Include `check "lib/react_on_rails/filename.rb"` in Steepfile
3. **Validate**: Run `bundle exec rake rbs:validate`
4. **Type check**: Run `bundle exec rake rbs:steep`
5. **Fix errors**: Address any type errors before committing

## Files Currently Type-Checked

See `react_on_rails/Steepfile` for the complete list. Core files include:

- `lib/react_on_rails.rb`
- `lib/react_on_rails/configuration.rb`
- `lib/react_on_rails/helper.rb`
- `lib/react_on_rails/packer_utils.rb`
- `lib/react_on_rails/server_rendering_pool.rb`
- And 10 more (see Steepfile for full list)

## Pro Package Type Checking

The Pro package has its own RBS signatures in `react_on_rails_pro/sig/`.

Validate Pro signatures:

```bash
cd react_on_rails_pro && bundle exec rake rbs:validate
```
