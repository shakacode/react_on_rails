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
declare class PostSSRHookTracker {
  private hooks;

  private hasSSREnded;

  /**
   * Adds a hook to be executed when SSR ends for this request.
   *
   * @param hook - Function to call when SSR ends
   * @throws Error if called after SSR has already ended
   */
  addPostSSRHook(hook: PostSSRHook): void;

  /**
   * Notifies all registered hooks that SSR has ended and clears the hook list.
   * This should be called exactly once when server-side rendering is complete.
   *
   * @throws Error if called multiple times
   */
  notifySSREnd(): void;
}
export default PostSSRHookTracker;
