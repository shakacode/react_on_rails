/**
 * Manages async props for incremental server-side rendering.
 *
 * DESIGN PRINCIPLES:
 *
 * 1. PROMISE CACHING: Same promise is returned for multiple getProp() calls.
 *    This is CRITICAL for React's rendering model - if we returned new promises,
 *    React would create infinite render loops or flicker as each render would
 *    get a different promise object.
 *
 * 2. ORDER INDEPENDENCE: Props can be set before or after they're requested.
 *    - If getProp() is called first: Creates promise, suspends, later setProp() resolves it
 *    - If setProp() is called first: Creates resolved promise, getProp() returns immediately
 *
 * 3. STREAM LIFECYCLE: endStream() rejects all unresolved props.
 *    This handles the case where the HTTP request closes before all props arrive,
 *    allowing React to show error boundaries instead of hanging forever.
 *
 * USAGE FLOW:
 * 1. ServerRenderingJsCode calls addAsyncPropsCapabilityToComponentProps()
 * 2. Component calls getReactOnRailsAsyncProp("propName") → getProp() returns promise
 * 3. React suspends on the promise
 * 4. Rails sends update chunk → setProp("propName", value) → promise resolves
 * 5. React resumes rendering with the value
 *
 * @example
 * // Inside a React Server Component
 * async function MyComponent({ getReactOnRailsAsyncProp }) {
 *   const users = await getReactOnRailsAsyncProp('users');
 *   return <UserList users={users} />;
 * }
 */
declare class AsyncPropsManager {
    private isClosed;
    private propNameToPromiseController;
    /**
     * Gets the promise for an async prop. Returns the SAME promise on repeated calls.
     *
     * IMPORTANT: This is not an async function intentionally.
     * Returning the same Promise object on every call is required for React's
     * concurrent rendering - new promises would cause re-renders.
     */
    getProp(propName: string): Promise<unknown>;
    setProp(propName: string, propValue: unknown): void;
    endStream(): void;
    private getOrCreatePromiseController;
    private static getNoPropFoundError;
}
/**
 * Gets or creates an AsyncPropsManager from the shared execution context.
 *
 * This function implements lazy initialization to handle race conditions between
 * the initial render request and update chunks. Whichever executes first will
 * create the manager, and subsequent calls will reuse the same instance.
 *
 * @param sharedExecutionContext - Map scoped to the current HTTP request
 * @returns The AsyncPropsManager instance (existing or newly created)
 */
export declare function getOrCreateAsyncPropsManager(sharedExecutionContext: Map<string, unknown>): AsyncPropsManager;
export default AsyncPropsManager;
//# sourceMappingURL=AsyncPropsManager.d.ts.map