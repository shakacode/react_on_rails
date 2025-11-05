/**
 * @fileoverview Prevent 'use client' directive in .server.tsx files
 * @author React on Rails Team
 */

/**
 * ESLint rule to prevent 'use client' directives in .server.tsx files.
 *
 * Files ending with .server.tsx are intended for server-side rendering in
 * React Server Components architecture. The 'use client' directive forces
 * webpack to bundle these as client components, which causes errors when
 * using React's react-server conditional exports with Shakapacker 9.3.0+.
 *
 * @type {import('eslint').Rule.RuleModule}
 */
module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: "Prevent 'use client' directive in .server.tsx files",
      category: 'Best Practices',
      recommended: true,
      url: 'https://github.com/shakacode/react_on_rails/pull/1919',
    },
    messages: {
      useClientInServerFile: `Files with '.server.tsx' extension should not have 'use client' directive. Server files are for React Server Components and should not use client-only APIs. If this component needs client-side features, rename it to .client.tsx or .tsx instead.`,
    },
    schema: [],
    fixable: 'code',
  },

  create(context) {
    const filename = context.filename || context.getFilename();

    // Only check .server.tsx files
    if (!filename.endsWith('.server.tsx') && !filename.endsWith('.server.ts')) {
      return {};
    }

    return {
      Program(node) {
        const sourceCode = context.sourceCode || context.getSourceCode();
        const text = sourceCode.getText();

        // Check for 'use client' directive at the start of the file
        // Uses backreference (\1) to ensure matching quotes (both single or both double)
        // Only matches at the very beginning of the file
        const useClientPattern = /^\s*(['"])use client\1;?\s*\n?/;
        const match = text.match(useClientPattern);

        if (match) {
          // Find the exact position of the directive
          const directiveIndex = text.indexOf(match[0]);

          context.report({
            node,
            messageId: 'useClientInServerFile',
            fix(fixer) {
              // Remove the 'use client' directive (regex already captures trailing newline)
              return fixer.removeRange([directiveIndex, directiveIndex + match[0].length]);
            },
          });
        }
      },
    };
  },
};
