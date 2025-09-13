/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */

type PostSSRHook = () => void;

/**
 * Post-SSR Hook Tracker - manages post-SSR hooks for a single request.
 *
 * This class provides a local alternative to the global hook management,
 * allowing each request to have its own isolated hook tracker without sharing state.
 *
 * The tracker ensures that:
 * - Hooks are executed exactly once when SSR ends
 * - No hooks can be added after SSR has completed
 * - Proper cleanup occurs to prevent memory leaks
 */
class PostSSRHookTracker {
  private hooks: PostSSRHook[] = [];

  private hasSSREnded = false;

  /**
   * Adds a hook to be executed when SSR ends for this request.
   *
   * @param hook - Function to call when SSR ends
   * @throws Error if called after SSR has already ended
   */
  addPostSSRHook(hook: PostSSRHook): void {
    if (this.hasSSREnded) {
      console.error(
        'Cannot add post-SSR hook: SSR has already ended for this request. ' +
          'Hooks must be registered before or during the SSR process.',
      );
      return;
    }

    this.hooks.push(hook);
  }

  /**
   * Notifies all registered hooks that SSR has ended and clears the hook list.
   * This should be called exactly once when server-side rendering is complete.
   *
   * @throws Error if called multiple times
   */
  notifySSREnd(): void {
    if (this.hasSSREnded) {
      console.warn('notifySSREnd() called multiple times. This may indicate a bug in the SSR lifecycle.');
      return;
    }

    this.hasSSREnded = true;

    // Execute all hooks and handle any errors gracefully
    this.hooks.forEach((hook, index) => {
      try {
        hook();
      } catch (error) {
        console.error(`Error executing post-SSR hook ${index}:`, error);
      }
    });

    // Clear hooks to free memory
    this.hooks = [];
  }
}

export default PostSSRHookTracker;
