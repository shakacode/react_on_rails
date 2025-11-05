/**
 * @fileoverview Tests for no-use-client-in-server-files rule
 */

const { RuleTester } = require('eslint');
const rule = require('./no-use-client-in-server-files.cjs');

const ruleTester = new RuleTester({
  languageOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
    parserOptions: {
      ecmaFeatures: {
        jsx: true,
      },
    },
  },
});

ruleTester.run('no-use-client-in-server-files', rule, {
  valid: [
    {
      code: `
import React from 'react';

export function ServerComponent() {
  return <div>Server Component</div>;
}
`,
      filename: 'Component.server.tsx',
    },
    {
      code: `
import { renderToString } from 'react-dom/server';

export function render() {
  return renderToString(<div>Hello</div>);
}
`,
      filename: 'ComponentRenderer.server.tsx',
    },
    {
      code: `
'use client';

import React from 'react';

export function ClientComponent() {
  return <div>Client Component</div>;
}
`,
      filename: 'Component.client.tsx',
    },
    {
      code: `
'use client';

import React from 'react';

export function ClientComponent() {
  return <div>Client Component</div>;
}
`,
      filename: 'Component.tsx',
    },
    {
      code: `
import React from 'react';

// This is fine - no 'use client' directive
export function ServerComponent() {
  return <div>Server</div>;
}
`,
      filename: 'App.server.ts',
    },
  ],

  invalid: [
    {
      code: `'use client';

import React from 'react';

export function Component() {
  return <div>Component</div>;
}
`,
      filename: 'Component.server.tsx',
      errors: [
        {
          messageId: 'useClientInServerFile',
        },
      ],
      output: `import React from 'react';

export function Component() {
  return <div>Component</div>;
}
`,
    },
    {
      code: `"use client";

import React from 'react';
`,
      filename: 'Component.server.tsx',
      errors: [
        {
          messageId: 'useClientInServerFile',
        },
      ],
      output: `import React from 'react';
`,
    },
    {
      code: `'use client'

import React from 'react';
`,
      filename: 'Component.server.tsx',
      errors: [
        {
          messageId: 'useClientInServerFile',
        },
      ],
      output: `import React from 'react';
`,
    },
    {
      code: `  'use client';

import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/server';
`,
      filename: 'AsyncOnServerSyncOnClient.server.tsx',
      errors: [
        {
          messageId: 'useClientInServerFile',
        },
      ],
      output: `import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/server';
`,
    },
    {
      code: `'use client';

import React from 'react';
`,
      filename: 'Component.server.ts',
      errors: [
        {
          messageId: 'useClientInServerFile',
        },
      ],
      output: `import React from 'react';
`,
    },
  ],
});
