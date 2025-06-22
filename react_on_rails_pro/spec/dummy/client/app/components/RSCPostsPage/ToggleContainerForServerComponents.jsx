'use client';

// This file serves as a thin wrapper around ToggleContainer to optimize bundle size.
// When ToggleContainer is imported directly by other client components,
// the resulting bundle includes all dependent code. However, server components using
// ToggleContainer don't need this additional code. By importing from this wrapper file
// instead, server components will only receive the minimal bundle containing just
// ToggleContainer, improving performance and reducing unnecessary code transfer.

import ToggleContainer from './ToggleContainer';

export default ToggleContainer;
