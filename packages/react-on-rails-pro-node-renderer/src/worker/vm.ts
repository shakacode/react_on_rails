/**
 * Manages the virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

import fs from 'fs';
import path from 'path';
import vm from 'vm';
import m from 'module';
import cluster from 'cluster';
import type { Readable } from 'stream';
import { ReadableStream } from 'stream/web';
import { promisify, TextEncoder } from 'util';
import type { ReactOnRails as ROR } from 'react-on-rails' with { 'resolution-mode': 'import' };
import type { Context } from 'vm';

import SharedConsoleHistory from '../shared/sharedConsoleHistory.js';
import log from '../shared/log.js';
import { getConfig } from '../shared/configBuilder.js';
import {
  formatExceptionMessage,
  smartTrim,
  isReadableStream,
  getRequestBundleFilePath,
  handleStreamError,
} from '../shared/utils.js';
import * as errorReporter from '../shared/errorReporter.js';

const readFileAsync = promisify(fs.readFile);
const writeFileAsync = promisify(fs.writeFile);

export interface VMContext {
  context: Context;
  sharedConsoleHistory: SharedConsoleHistory;
  lastUsed: number; // Track when this VM was last used
}

// Store contexts by their bundle file paths
const vmContexts = new Map<string, VMContext>();

// Track VM creation promises to handle concurrent buildVM requests
const vmCreationPromises = new Map<string, Promise<VMContext>>();

/**
 * Returns all bundle paths that have a VM context
 */
export function hasVMContextForBundle(bundlePath: string) {
  return vmContexts.has(bundlePath);
}

/**
 * Get a specific VM context by bundle path
 */
export function getVMContext(bundlePath: string): VMContext | undefined {
  return vmContexts.get(bundlePath);
}

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
export type RenderResult = string | Readable | { exceptionMessage: string };

declare global {
  // This works on node 16+
  // https://stackoverflow.com/questions/35074713/extending-typescript-global-object-in-node-js/68328575#68328575
  // eslint-disable-next-line vars-on-top, no-var
  var ReactOnRails: ROR | undefined;
}

const extendContext = (contextObject: vm.Context, additionalContext: Record<string, unknown>) => {
  if (log.level === 'debug') {
    log.debug(`Adding ${Object.keys(additionalContext).join(', ')} to context object.`);
  }
  Object.assign(contextObject, additionalContext);
};

// Helper function to manage VM pool size
function manageVMPoolSize() {
  const { maxVMPoolSize } = getConfig();

  if (vmContexts.size <= maxVMPoolSize) {
    return;
  }

  const sortedEntries = Array.from(vmContexts.entries()).sort(([, a], [, b]) => a.lastUsed - b.lastUsed);

  while (sortedEntries.length > maxVMPoolSize) {
    const oldestPath = sortedEntries.shift()?.[0];
    if (oldestPath) {
      vmContexts.delete(oldestPath);
      log.debug(`Removed VM for bundle ${oldestPath} due to pool size limit (max: ${maxVMPoolSize})`);
    }
  }
}

export class VMContextNotFoundError extends Error {
  constructor(bundleFilePath: string) {
    super(`VMContext not found for bundle: ${bundleFilePath}`);
    this.name = 'VMContextNotFoundError';
  }
}

async function buildVM(filePath: string): Promise<VMContext> {
  // Return existing promise if VM is already being created
  if (vmCreationPromises.has(filePath)) {
    return vmCreationPromises.get(filePath) as Promise<VMContext>;
  }

  // Check if VM for this bundle already exists
  const vmContext = vmContexts.get(filePath);
  if (vmContext) {
    // Update last used time when accessing existing VM
    vmContext.lastUsed = Date.now();
    return Promise.resolve(vmContext);
  }

  // Create a new promise for this VM creation
  const vmCreationPromise = (async () => {
    try {
      const { supportModules, stubTimers, additionalContext } = getConfig();
      const additionalContextIsObject =
        additionalContext !== null && additionalContext.constructor === Object;
      const sharedConsoleHistory = new SharedConsoleHistory();

      const contextObject = { sharedConsoleHistory };

      if (supportModules) {
        // IMPORTANT: When adding anything to this object, update:
        // 1. docs/node-renderer/js-configuration.md
        // 2. packages/node-renderer/src/shared/configBuilder.ts
        extendContext(contextObject, {
          Buffer,
          TextDecoder,
          TextEncoder,
          URLSearchParams,
          ReadableStream,
          process,
          setTimeout,
          setInterval,
          setImmediate,
          clearTimeout,
          clearInterval,
          clearImmediate,
          queueMicrotask,
        });
      }

      if (additionalContextIsObject) {
        extendContext(contextObject, additionalContext);
      }
      const context = vm.createContext(contextObject);

      // Create explicit reference to global context, just in case (some libs can use it):
      vm.runInContext('global = this', context);

      // Reimplement console methods for replaying on the client:
      vm.runInContext(
        `
      console = {
        get history() {
          return sharedConsoleHistory.getConsoleHistory();
        },
        set history(value) {
          // Do nothing. It's just for the backward compatibility.
        },
      };
      ['error', 'log', 'info', 'warn'].forEach(function (level) {
        console[level] = function () {
          var argArray = Array.prototype.slice.call(arguments);
          if (argArray.length > 0) {
            argArray[0] = '[SERVER] ' + argArray[0];
          }
          sharedConsoleHistory.addToConsoleHistory({level: level, arguments: argArray});
        };
      });`,
        context,
      );

      // Define global getStackTrace() function:
      vm.runInContext(
        `
      function getStackTrace() {
        var stack;
        try {
          throw new Error('');
        }
        catch (error) {
          stack = error.stack || '';
        }
        stack = stack.split('\\n').map(function (line) { return line.trim(); });
        return stack.splice(stack[0] == 'Error' ? 2 : 1);
      }`,
        context,
      );

      if (stubTimers) {
        // Define timer polyfills:
        vm.runInContext(`function setInterval() {}`, context);
        vm.runInContext(`function setTimeout() {}`, context);
        vm.runInContext(`function setImmediate() {}`, context);
        vm.runInContext(`function clearTimeout() {}`, context);
        vm.runInContext(`function clearInterval() {}`, context);
        vm.runInContext(`function clearImmediate() {}`, context);
        vm.runInContext(`function queueMicrotask() {}`, context);
      }

      // Run bundle code in created context:
      const bundleContents = await readFileAsync(filePath, 'utf8');

      // If node-specific code is provided then it must be wrapped into a module wrapper. The bundle
      // may need the `require` function, which is not available when running in vm unless passed in.
      if (additionalContextIsObject || supportModules) {
        vm.runInContext(m.wrap(bundleContents), context)(
          exports,
          require,
          module,
          filePath,
          path.dirname(filePath),
        );
      } else {
        vm.runInContext(bundleContents, context);
      }

      // Only now, after VM is fully initialized, store the context
      const newVmContext: VMContext = {
        context,
        sharedConsoleHistory,
        lastUsed: Date.now(),
      };
      vmContexts.set(filePath, newVmContext);

      // Manage pool size after adding new VM
      manageVMPoolSize();

      // isWorker check is required for JS unit testing:
      if (cluster.isWorker && cluster.worker !== undefined) {
        log.debug(`Built VM for worker #${cluster.worker.id} with bundle ${filePath}`);
      }

      if (log.level === 'debug') {
        log.debug(
          'Required objects now in VM sandbox context: %s',
          vm.runInContext('global.ReactOnRails', context) !== undefined,
        );
        log.debug(
          'Required objects should not leak to the global context (true means OK): %s',
          !!global.ReactOnRails,
        );
      }

      return newVmContext;
    } catch (error) {
      log.error({ error }, 'Caught Error when creating context in buildVM');
      errorReporter.error(error as Error);
      throw error;
    } finally {
      // Always remove the promise from the map when done
      vmCreationPromises.delete(filePath);
    }
  })();

  // Store the promise
  vmCreationPromises.set(filePath, vmCreationPromise);

  return vmCreationPromise;
}

async function getOrBuildVMContext(bundleFilePath: string, buildVmsIfNeeded: boolean): Promise<VMContext> {
  const vmContext = getVMContext(bundleFilePath);
  if (vmContext) {
    return vmContext;
  }

  const vmCreationPromise = vmCreationPromises.get(bundleFilePath);
  if (vmCreationPromise) {
    return vmCreationPromise;
  }

  if (buildVmsIfNeeded) {
    return buildVM(bundleFilePath);
  }

  throw new VMContextNotFoundError(bundleFilePath);
}

export type ExecutionContext = {
  runInVM: (
    renderingRequest: string,
    bundleFilePath: string,
    vmCluster?: typeof cluster,
  ) => Promise<RenderResult>;
  getVMContext: (bundleFilePath: string) => VMContext | undefined;
};

export async function buildExecutionContext(
  bundlePaths: string[],
  buildVmsIfNeeded: boolean,
): Promise<ExecutionContext> {
  const mapBundleFilePathToVMContext = new Map<string, VMContext>();
  await Promise.all(
    bundlePaths.map(async (bundleFilePath) => {
      const vmContext = await getOrBuildVMContext(bundleFilePath, buildVmsIfNeeded);
      vmContext.lastUsed = Date.now();
      mapBundleFilePathToVMContext.set(bundleFilePath, vmContext);
    }),
  );
  const sharedExecutionContext = new Map();

  const runInVM = async (renderingRequest: string, bundleFilePath: string, vmCluster?: typeof cluster) => {
    try {
      const { serverBundleCachePath } = getConfig();
      const vmContext = mapBundleFilePathToVMContext.get(bundleFilePath);
      if (!vmContext) {
        throw new VMContextNotFoundError(bundleFilePath);
      }

      // Update last used timestamp
      vmContext.lastUsed = Date.now();

      const { context, sharedConsoleHistory } = vmContext;

      if (log.level === 'debug') {
        // worker is nullable in the primary process
        const workerId = vmCluster?.worker?.id;
        log.debug(`worker ${workerId ? `${workerId} ` : ''}received render request for bundle ${bundleFilePath} with code
  ${smartTrim(renderingRequest)}`);
        const debugOutputPathCode = path.join(serverBundleCachePath, 'code.js');
        log.debug(`Full code executed written to: ${debugOutputPathCode}`);
        await writeFileAsync(debugOutputPathCode, renderingRequest);
      }

      let result = sharedConsoleHistory.trackConsoleHistoryInRenderRequest(() => {
        context.renderingRequest = renderingRequest;
        context.sharedExecutionContext = sharedExecutionContext;
        context.runOnOtherBundle = (bundleTimestamp: string | number, newRenderingRequest: string) => {
          const otherBundleFilePath = getRequestBundleFilePath(bundleTimestamp);
          return runInVM(otherBundleFilePath, newRenderingRequest, vmCluster);
        };

        try {
          return vm.runInContext(renderingRequest, context) as RenderCodeResult;
        } finally {
          context.renderingRequest = undefined;
          context.sharedExecutionContext = undefined;
          context.runOnOtherBundle = undefined;
        }
      });

      if (isReadableStream(result)) {
        const newStreamAfterHandlingError = handleStreamError(result, (error) => {
          const msg = formatExceptionMessage(renderingRequest, error, 'Error in a rendering stream');
          errorReporter.message(msg);
        });
        return newStreamAfterHandlingError;
      }
      if (typeof result !== 'string') {
        const objectResult = await result;
        result = JSON.stringify(objectResult);
      }
      if (log.level === 'debug') {
        log.debug(`result from JS:
  ${smartTrim(result)}`);
        const debugOutputPathResult = path.join(serverBundleCachePath, 'result.json');
        log.debug(`Wrote result to file: ${debugOutputPathResult}`);
        await writeFileAsync(debugOutputPathResult, result);
      }

      return result;
    } catch (exception) {
      const exceptionMessage = formatExceptionMessage(renderingRequest, exception);
      log.debug('Caught exception in rendering request', exceptionMessage);
      return Promise.resolve({ exceptionMessage });
    }
  };

  return {
    getVMContext: (bundleFilePath: string) => mapBundleFilePathToVMContext.get(bundleFilePath),
    runInVM,
  };
}

/** @internal Used in tests */
export function resetVM() {
  // Clear all VM contexts
  vmContexts.clear();
}

// Optional: Add a method to remove a specific VM if needed
/**
 * @public TODO: Remove the line below when this function is actually used
 */
export function removeVM(bundlePath: string) {
  vmContexts.delete(bundlePath);
}
