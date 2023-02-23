/**
 * Holds virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const m = require('module');
const cluster = require('cluster');
const { promisify } = require('util');

const log = require('../shared/log');
const { getConfig } = require('../shared/configBuilder');
const { formatExceptionMessage, smartTrim } = require('../shared/utils');
const errorReporter = require('../shared/errorReporter');

const readFileAsync = promisify(fs.readFile);
const writeFileAsync = promisify(fs.writeFile);

// Both context and vmBundleFilePath are set when the VM is ready.
let context;

// vmBundleFilePath is cleared at the beginning of creating the context and set only when the
// context is properly created.
let vmBundleFilePath;

/**
 * Value is set after VM created from the bundleFilePath. This value is null if the context is
 * not ready.
 */
exports.getVmBundleFilePath = function getVmBundleFilePath() {
  return vmBundleFilePath;
};

function replayVmConsole() {
  if (log.level !== 'debug') return;
  const consoleHistoryFromVM = vm.runInContext('console.history', context);

  consoleHistoryFromVM.forEach((msg) => {
    const stringifiedList = msg.arguments.map((arg) => {
      let val;
      try {
        val = typeof arg === 'string' || arg instanceof String ? arg : JSON.stringify(arg);
      } catch (e) {
        val = `${e.message}: ${arg}`;
      }

      return val;
    });

    log.debug(stringifiedList.join(' '));
  });
}

/**
 *
 * @param filePath
 * @returns {Promise<boolean>}
 */
exports.buildVM = async function buildVM(filePath) {
  if (filePath === vmBundleFilePath && context) {
    return Promise.resolve(true);
  }

  try {
    const { supportModules, includeTimerPolyfills } = getConfig();
    vmBundleFilePath = undefined;
    if (supportModules) {
      context = vm.createContext({ Buffer, process, setTimeout, setInterval, clearTimeout, clearInterval });
    } else {
      context = vm.createContext();
    }
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
    if (supportModules) {
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

    // !isMaster check is required for JS unit testing:
    if (!cluster.isMaster) {
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
    errorReporter.notify(error);
    return Promise.reject(error);
  }
};

/**
 *
 * @param renderingRequest JS Code to execute for SSR
 * @param vmCluster
 * @returns {{exceptionMessage: string}}
 */
exports.runInVM = async function runInVM(renderingRequest, vmCluster) {
  const { bundlePath } = getConfig();

  try {
    if (log.level === 'debug') {
      const clusterWorkerId = vmCluster && vmCluster.worker ? `worker ${vmCluster.worker.id} ` : '';
      log.debug(`worker ${clusterWorkerId}received render request with code
${smartTrim(renderingRequest)}`);
      const debugOutputPathCode = path.join(bundlePath, 'code.js');
      log.debug(`Full code executed written to: ${debugOutputPathCode}`);
      await writeFileAsync(debugOutputPathCode, renderingRequest);
    }

    vm.runInContext('console.history = []', context);

    let result = vm.runInContext(renderingRequest, context);
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
};

/**
 *
 */
exports.resetVM = function resetVM() {
  context = undefined;
  vmBundleFilePath = undefined;
};
