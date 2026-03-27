#!/usr/bin/env node

// Check Node.js version before loading anything else
const currentNodeVersion = process.versions.node;
const major = parseInt(currentNodeVersion.split('.')[0], 10);

if (major < 18) {
  console.error(
    `You are running Node.js ${currentNodeVersion}.\n` +
      'create-react-on-rails-app requires Node.js 18 or higher.\n' +
      'Please update your version of Node.js.',
  );
  process.exit(1);
}

require('../lib/index.js');
