/**
 * Manages the virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

import fs from 'fs';
import path from 'path';
import vm from 'vm';
import m from 'module';
import cluster from 'cluster';
import { promisify } from 'util';
import log from '../shared/log';
import { getConfig } from '../shared/configBuilder';
import { formatExceptionMessage, smartTrim } from '../shared/utils';
import errorReporter from '../shared/errorReporter';

const readFileAsync = promisify(fs.readFile);
const writeFileAsync = promisify(fs.writeFile);

// Both context and vmBundleFilePath are set when the VM is ready.
let context: vm.Context | undefined;

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

function replayVmConsole() {
  if (log.level !== 'debug' || !context) return;
  const consoleHistoryFromVM = vm.runInContext('console.history', context) as { arguments: unknown[] }[];

  consoleHistoryFromVM.forEach((msg) => {
    const stringifiedList = msg.arguments.map((arg) => {
      let val;
      try {
        val = typeof arg === 'string' || arg instanceof String ? arg : JSON.stringify(arg);
      } catch (e) {
        val = `${(e as Error).message}: ${arg}`;
      }

      return val;
    });

    log.debug(stringifiedList.join(' '));
  });
}

// This works before node 16
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace -- needed to augment
  namespace NodeJS {
    interface Global {
      ReactOnRails?: unknown;
    }
  }
}
// This works on node 16+
declare global {
  // eslint-disable-next-line vars-on-top, no-var
  var ReactOnRails: unknown;
}

export async function buildVM(filePath: string) {
  if (filePath === vmBundleFilePath && context) {
    return Promise.resolve(true);
  }

  try {
    const { supportModules, includeTimerPolyfills, additionalContext } = getConfig();
    const additionalContextIsObject = additionalContext !== null && additionalContext.constructor === Object;
    vmBundleFilePath = undefined;
    const contextObject = {};
    if (supportModules) {
      log.debug(
        'Adding Buffer, process, setTimeout, setInterval, clearTimeout, clearInterval to context object.',
      );
      Object.assign(contextObject, { Buffer, process, setTimeout, setInterval, clearTimeout, clearInterval });
    }
    if (additionalContextIsObject) {
      const keysString = Object.keys(additionalContext).join(', ');
      log.debug(`Adding ${keysString} to context object.`);
      Object.assign(contextObject, additionalContext);
    }
    context = vm.createContext(contextObject);

    // Create explicit reference to global context, just in case (some libs can use it):
    vm.runInContext('global = this', context);

    // Reimplement console methods for replaying on the client:
    vm.runInContext(
      `
    console = { history: [] };
    ['error', 'log', 'info', 'warn'].forEach(function (level) {
      console[level] = function () {
        var argArray = Array.prototype.slice.call(arguments);
        if (argArray.length > 0) {
          argArray[0] = '[SERVER] ' + argArray[0];
        }
        console.history.push({level: level, arguments: argArray});
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

    if (includeTimerPolyfills) {
      // Define timer polyfills:
      vm.runInContext(`function setInterval() {}`, context);
      vm.runInContext(`function setTimeout() {}`, context);
      vm.runInContext(`function clearTimeout() {}`, context);
      vm.runInContext(`function clearInterval() {}`, context);
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
    errorReporter.notify(error as Error);
    return Promise.reject(error as Error);
  }
}

/**
 *
 * @param renderingRequest JS Code to execute for SSR
 * @param vmCluster
 */
export async function runInVM(
  renderingRequest: string,
  vmCluster?: typeof cluster,
): Promise<string | { exceptionMessage: string }> {
  const { bundlePath } = getConfig();

  try {
    if (context == null) {
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

    vm.runInContext('console.history = []', context);

    let result = vm.runInContext(renderingRequest, context) as string | Promise<string>;
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

    replayVmConsole();
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
