/**
 * Manages the virtual machine for rendering code in isolated context.
 * @module worker/vm
 */
import cluster from 'cluster';
import type { Readable } from 'stream';
import type { ReactOnRails as ROR } from 'react-on-rails' with { 'resolution-mode': 'import' };
import type { Context } from 'vm';
import SharedConsoleHistory from '../shared/sharedConsoleHistory.js';
export interface VMContext {
    context: Context;
    sharedConsoleHistory: SharedConsoleHistory;
    lastUsed: number;
}
/**
 * Returns all bundle paths that have a VM context
 * @internal Used in tests
 */
export declare function hasVMContextForBundle(bundlePath: string): boolean;
/**
 * Get a specific VM context by bundle path
 */
export declare function getVMContext(bundlePath: string): VMContext | undefined;
/**
 * The type of the result returned by executing the code payload sent in the rendering request.
 */
export type RenderCodeResult = string | Promise<string> | Readable;
/**
 * The type of the result returned by the `runInVM` function.
 *
 * Similar to {@link RenderCodeResult} returned by executing the code payload sent in the rendering request,
 * but after awaiting the promise if present and handling exceptions if any.
 */
export type RenderResult = string | Readable | {
    exceptionMessage: string;
};
declare global {
    var ReactOnRails: ROR | undefined;
}
export declare class VMContextNotFoundError extends Error {
    constructor(bundleFilePath: string);
}
export type ExecutionContext = {
    runInVM: (renderingRequest: string, bundleFilePath: string, vmCluster?: typeof cluster) => Promise<RenderResult>;
    getVMContext: (bundleFilePath: string) => VMContext | undefined;
};
/**
 * Builds an ExecutionContext that manages VM execution for a set of bundles.
 *
 * The ExecutionContext includes a `sharedExecutionContext` Map that enables safe data sharing
 * between the initial render request and subsequent update chunks (for incremental rendering).
 *
 * CRITICAL SECURITY DESIGN:
 * - sharedExecutionContext is created ONCE per ExecutionContext (per HTTP request)
 * - It is NOT a global variable - each request gets its own isolated Map
 * - This prevents data leakage between concurrent rendering requests from different users
 * - The Map is passed to the VM context only during code execution, then immediately removed
 *
 * @see handleIncrementalRenderRequest.ts for how update chunks access the same context
 */
export declare function buildExecutionContext(bundlePaths: string[], buildVmsIfNeeded: boolean): Promise<ExecutionContext>;
/** @internal Used in tests */
export declare function resetVM(): void;
/**
 * @public TODO: Remove the line below when this function is actually used
 */
export declare function removeVM(bundlePath: string): void;
//# sourceMappingURL=vm.d.ts.map