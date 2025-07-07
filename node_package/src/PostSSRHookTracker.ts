type PostSSRHook = () => void;

/**
 * Post-SSR Hook Tracker - manages post-SSR hooks for a single request.
 *
 * This class provides a local alternative to the global hook management,
 * allowing each request to have its own isolated hook tracker without sharing state.
 */
class PostSSRHookTracker {
  private hooks: PostSSRHook[] = [];

  /**
   * Adds a hook to be executed when SSR ends for this request.
   *
   * @param hook - Function to call when SSR ends
   */
  addPostSSRHook(hook: PostSSRHook): void {
    this.hooks.push(hook);
  }

  /**
   * Notifies all registered hooks that SSR has ended and clears the hook list.
   * This should be called when server-side rendering is complete.
   */
  notifySSREnd(): void {
    this.hooks.forEach((hook) => hook());
    this.hooks = [];
  }

  /**
   * Clears all hooks without executing them.
   * Should be called if the request is aborted or cleanup is needed.
   */
  clear(): void {
    this.hooks = [];
  }
}

export default PostSSRHookTracker;
