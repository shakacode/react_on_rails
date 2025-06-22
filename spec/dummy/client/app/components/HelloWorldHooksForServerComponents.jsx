'use client';

// This file serves as a thin wrapper around HelloWorldHooks to optimize bundle size.
// When HelloWorldHooks is imported directly by other client components (like PostsPage),
// the resulting bundle includes all dependent code. However, server components using
// HelloWorldHooks don't need this additional code. By importing from this wrapper file
// instead, server components will only receive the minimal bundle containing just
// HelloWorldHooks, improving performance and reducing unnecessary code transfer.

import HelloWorldHooks from './HelloWorldHooks';

export default HelloWorldHooks;
