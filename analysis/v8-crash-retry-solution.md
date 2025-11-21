# V8 Crash Retry Solution for CI

## Problem

CI jobs occasionally fail with a transient V8 bytecode deserialization crash during the Node.js setup phase. The error manifests as:

```
Fatal error in , line 0
Check failed: ReadSingleBytecodeData( source_.Get(), SlotAccessorForHandle<IsolateT>(&ret, isolate())) == 1.
```

This error occurs during the `yarn cache dir` command execution within the `actions/setup-node@v4` action.

## Root Cause

This is a known bug in Node.js/V8 that occurs sporadically:

- **Node.js Issue**: https://github.com/nodejs/node/issues/56010
- **Setup-node Issue**: https://github.com/actions/setup-node/issues/1028

The crash happens when V8 attempts to deserialize cached bytecode and encounters corrupted or incompatible data. It's a transient issue that typically resolves on retry.

## Previous Workarounds

Before this fix, the codebase used two workarounds:

1. **Completely disable yarn caching** in `examples.yml`:

   ```yaml
   # TODO: Re-enable yarn caching once Node.js V8 cache crash is fixed
   # Tracking: https://github.com/actions/setup-node/issues/1028
   # cache: yarn
   # cache-dependency-path: '**/yarn.lock'
   ```

2. **Conditionally disable caching for Node 22** in `integration-tests.yml`:
   ```yaml
   cache: ${{ matrix.node-version != '22' && 'yarn' || '' }}
   ```

Both workarounds significantly slowed down CI by preventing yarn dependency caching.

## Solution

Created a custom composite GitHub action at `.github/actions/setup-node-with-retry/` that:

### Key Features

1. **Pre-validation**: Tests `yarn cache dir` works before running `setup-node`
2. **Automatic retry**: Retries up to 3 times when V8 crashes are detected
3. **Smart error detection**: Only retries on V8 crashes, fails fast on other errors
4. **Clear diagnostics**: Provides warning annotations in CI logs
5. **Configurable**: Allows customizing max retries (defaults to 3)
6. **Backward compatible**: Drop-in replacement for `actions/setup-node@v4`

### How It Works

```yaml
- name: Setup Node.js with retry
  shell: bash
  run: |
    # Pre-validate yarn cache dir works
    if timeout 30 yarn cache dir > "$TEMP_OUTPUT" 2>&1; then
      echo "Yarn cache dir command succeeded"
    else
      # Check for V8 crash signature
      if grep -q "Fatal error in.*Check failed: ReadSingleBytecodeData" "$TEMP_OUTPUT"; then
        echo "::warning::V8 bytecode deserialization error detected"
        # Retry logic...
      fi
    fi

- name: Actually setup Node.js
  uses: actions/setup-node@v4
  # ... standard setup-node configuration
```

### Usage

```yaml
- name: Setup Node
  uses: ./.github/actions/setup-node-with-retry
  with:
    node-version: 22
    cache: yarn
    cache-dependency-path: '**/yarn.lock'
    max-retries: 3 # Optional, defaults to 3
```

## Changes Made

Updated all 8 CI workflow files to use the new action:

1. ✅ `examples.yml` - **Re-enabled yarn caching**
2. ✅ `integration-tests.yml` - **Re-enabled yarn caching for Node 22**
3. ✅ `lint-js-and-ruby.yml`
4. ✅ `package-js-tests.yml`
5. ✅ `playwright.yml`
6. ✅ `pro-integration-tests.yml`
7. ✅ `pro-lint.yml`
8. ✅ `pro-test-package-and-gem.yml`

## Benefits

1. **Improved reliability**: CI no longer fails due to transient V8 crashes
2. **Better performance**: Yarn caching re-enabled across all workflows
3. **Clear diagnostics**: Warning annotations show when retries occur
4. **Maintainable**: Centralized retry logic in a reusable action
5. **Future-proof**: Can be updated independently if V8 crash patterns change

## Monitoring

To verify the retry logic is working when V8 crashes occur:

1. Watch CI logs for these warning messages:

   ```
   ::warning::V8 bytecode deserialization error detected (attempt 1/3)
   Retrying in 5 seconds...
   ```

2. Check that jobs succeed after retry instead of failing

3. If a job exhausts all retries, it will show:
   ```
   ::error::All 3 retry attempts failed
   ```

## Implementation Details

- **Timeout**: Each retry attempt has a 30-second timeout for `yarn cache dir`
- **Retry delay**: 5 seconds between attempts to allow transient issues to clear
- **Max retries**: Defaults to 3, configurable via input
- **Error detection**: Regex pattern matches V8 crash signature in stderr/stdout

## Future Improvements

If the V8 crash persists even with retries, consider:

1. Updating Node.js to a version with the fix (when available)
2. Increasing max-retries for particularly flaky environments
3. Adding exponential backoff between retries
4. Implementing cache clearing before retry

## Pull Request

- **PR**: https://github.com/shakacode/react_on_rails/pull/2082
- **Branch**: `jg-/ci-retry-v8-crash`
