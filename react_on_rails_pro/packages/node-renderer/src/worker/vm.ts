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
import { promisify } from 'util';
import type { ReactOnRails as ROR } from 'react-on-rails';

import SharedConsoleHistory from '../shared/sharedConsoleHistory';
import log from '../shared/log';
import { getConfig } from '../shared/configBuilder';
import { formatExceptionMessage, smartTrim, isReadableStream } from '../shared/utils';
import * as errorReporter from '../shared/errorReporter';

const readFileAsync = promisify(fs.readFile);
const writeFileAsync = promisify(fs.writeFile);

// Both context and vmBundleFilePath are set when the VM is ready.
let context: vm.Context | undefined;
let sharedConsoleHistory: SharedConsoleHistory | undefined;

// vmBundleFilePath is cleared at the beginning of creating the context and set only when the
// context is properly created.
let vmBundleFilePath: string | undefined;

/**
 * Value is set after VM created from the bundleFilePath. This value is undefined if the context is
 * not ready.
 */
export function getVmBundleFilePath() {
  return vmBundleFilePath;
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

export async function buildVM(filePath: string) {
  if (filePath === vmBundleFilePath && context) {
    return Promise.resolve(true);
  }

  try {
    const { supportModules, stubTimers, additionalContext } = getConfig();
    const additionalContextIsObject = additionalContext !== null && additionalContext.constructor === Object;
    vmBundleFilePath = undefined;
    sharedConsoleHistory = new SharedConsoleHistory();
    const contextObject = { sharedConsoleHistory };
    if (supportModules) {
      extendContext(contextObject, {
        Buffer,
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
    context = vm.createContext(contextObject);

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
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
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

    // isWorker check is required for JS unit testing:
    if (cluster.isWorker && cluster.worker !== undefined) {
      log.debug(`Built VM for worker #${cluster.worker.id}`);
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

    vmBundleFilePath = filePath;

    return Promise.resolve(true);
  } catch (error) {
    log.error('Caught Error when creating context in buildVM, %O', error);
    errorReporter.error(error as Error);
    return Promise.reject(error as Error);
  }
}

/**
 *
 * @param renderingRequest JS Code to execute for SSR
 * @param vmCluster
 */
export async function runInVM(renderingRequest: string, vmCluster?: typeof cluster): Promise<RenderResult> {
  const { bundlePath } = getConfig();

  try {
    if (context == null || sharedConsoleHistory == null) {
      throw new Error('runInVM called before buildVM');
    }

    if (log.level === 'debug') {
      // worker is nullable in the primary process
      const workerId = vmCluster?.worker?.id;
      log.debug(`worker ${workerId ? `${workerId} ` : ''}received render request with code
${smartTrim(renderingRequest)}`);
      const debugOutputPathCode = path.join(bundlePath, 'code.js');
      log.debug(`Full code executed written to: ${debugOutputPathCode}`);
      await writeFileAsync(debugOutputPathCode, renderingRequest);
    }

    // Capture context to ensure TypeScript sees it as defined within the callback
    const localContext = context;
    let result = sharedConsoleHistory.trackConsoleHistoryInRenderRequest(
      () => vm.runInContext(renderingRequest, localContext) as RenderCodeResult,
    );

    if (isReadableStream(result)) {
      return result;
    }
    if (typeof result !== 'string') {
      const objectResult = await result;
      result = JSON.stringify(objectResult);
    }
    if (log.level === 'debug') {
      log.debug(`result from JS:
${smartTrim(result)}`);
      const debugOutputPathResult = path.join(bundlePath, 'result.json');
      log.debug(`Wrote result to file: ${debugOutputPathResult}`);
      await writeFileAsync(debugOutputPathResult, result);
    }

    return Promise.resolve(result);
  } catch (exception) {
    const exceptionMessage = formatExceptionMessage(renderingRequest, exception);
    log.debug('Caught exception in rendering request', exceptionMessage);
    return Promise.resolve({ exceptionMessage });
  }
}

export function resetVM() {
  context = undefined;
  vmBundleFilePath = undefined;
}
