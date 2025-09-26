/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

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
