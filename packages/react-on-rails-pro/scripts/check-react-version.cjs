/**
 * Check if React version supports RSC features (React 19+).
 * Exits with code 0 if React < 19 (skip RSC tests).
 * Exits with code 1 if React >= 19 (run RSC tests).
 *
 * This is a CommonJS file (.cjs) because it needs to use require()
 * and the parent package has "type": "module".
 */
const v = require('react/package.json').version;

const majorVersion = parseInt(v, 10);

if (majorVersion < 19) {
  console.log(`RSC tests skipped (requires React 19+, found ${v})`);
  process.exit(0);
}

// Exit with code 1 so the || chain continues to run Jest
process.exit(1);
