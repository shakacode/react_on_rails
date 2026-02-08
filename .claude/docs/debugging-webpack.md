# Debugging Webpack Configuration Issues

When encountering issues with Webpack/Shakapacker configuration (e.g., components not rendering, CSS modules failing), use this debugging approach.

## 1. Create Debug Scripts

Create temporary debug scripts in the dummy app root to inspect the actual webpack configuration:

```javascript
// debug-webpack-rules.js - Inspect all webpack rules
const { generateWebpackConfig } = require('shakapacker');

const config = generateWebpackConfig();

console.log('=== Webpack Rules ===');
console.log(`Total rules: ${config.module.rules.length}\n`);

config.module.rules.forEach((rule, index) => {
  console.log(`\nRule ${index}:`);
  console.log('  test:', rule.test);
  console.log(
    '  use:',
    Array.isArray(rule.use) ? rule.use.map((u) => (typeof u === 'string' ? u : u.loader)) : rule.use,
  );

  if (rule.test) {
    console.log('  Matches .scss:', rule.test.test && rule.test.test('example.scss'));
    console.log('  Matches .module.scss:', rule.test.test && rule.test.test('example.module.scss'));
  }
});
```

```javascript
// debug-webpack-with-config.js - Inspect config AFTER modifications
const commonWebpackConfig = require('./config/webpack/commonWebpackConfig');

const config = commonWebpackConfig();

console.log('=== Webpack Rules AFTER commonWebpackConfig ===');
config.module.rules.forEach((rule, index) => {
  if (rule.test && rule.test.test('example.module.scss')) {
    console.log(`\nRule ${index} (CSS Modules):`);
    if (Array.isArray(rule.use)) {
      rule.use.forEach((loader, i) => {
        if (loader.loader && loader.loader.includes('css-loader')) {
          console.log(`  css-loader options:`, loader.options);
        }
      });
    }
  }
});
```

## 2. Run Debug Scripts

```bash
cd react_on_rails/spec/dummy  # or react_on_rails_pro/spec/dummy
NODE_ENV=test RAILS_ENV=test node debug-webpack-rules.js
NODE_ENV=test RAILS_ENV=test node debug-webpack-with-config.js
```

## 3. Analyze Output

- Verify the rules array structure matches expectations
- Check that loader options are correctly set
- Confirm rules only match intended file patterns
- Ensure modifications don't break existing loaders

## 4. Common Issues & Solutions

**CSS Modules breaking after Shakapacker upgrade:**

- Shakapacker 9.0+ defaults to `namedExport: true` for CSS Modules
- Existing code using `import styles from './file.module.css'` will fail
- Override in webpack config:
  ```javascript
  loader.options.modules.namedExport = false;
  loader.options.modules.exportLocalsConvention = 'camelCase';
  ```

**Rules not matching expected files:**

- Use `.test.test('example.file')` to check regex matching
- Shakapacker may combine multiple file extensions in single rules
- Test with actual filenames from your codebase

## 5. Clean Up

Always remove debug scripts before committing:

```bash
rm debug-*.js
```
