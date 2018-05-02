/**
 * Holds virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

'use strict';

const fs = require('fs');
const vm = require('vm');
const cluster = require('cluster');
const log = require('winston');

let context;
let bundleFilePath;

/**
 *
 */
function undefinedForExecLogging(functionName) {
  return `
    console.error('[ReactOnRails Renderer]: ${functionName} is not defined for VM. No-op for server rendering.');
    console.error(getStackTrace().join('\\n'));`;
}

/**
 *
 */
function replayVmConsole() {
  if (log.level !== 'debug') return;
  const consoleHistoryFromVM = vm.runInContext('console.history', context);

  consoleHistoryFromVM.forEach((msg) => {
    const stringifiedList = msg.arguments.map(arg => {
      let val;
      try {
        val = (typeof arg === 'string' || arg instanceof String) ? arg : JSON.stringify(arg);
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
 */
exports.buildVM = function buildVMNew(filePath) {
  context = vm.createContext();

  // Create explicit reference to global context, just in case (some libs can use it):
  vm.runInContext('global = this', context);

  // Reimplement console methods for replaying on the client:
  vm.runInContext(`
    console = { history: [] };
    ['error', 'log', 'info', 'warn'].forEach(function (level) {
      console[level] = function () {
        var argArray = Array.prototype.slice.call(arguments);
        if (argArray.length > 0) {
          argArray[0] = '[SERVER] ' + argArray[0];
        }
        console.history.push({level: level, arguments: argArray});
      };
    });`, context);

  // Define global getStackTrace() function:
  vm.runInContext(`
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
    }`, context);

  // Define timer polyfills:
  vm.runInContext(`function setInterval() { ${undefinedForExecLogging('setInterval')} }`, context);
  vm.runInContext(`function setTimeout() { ${undefinedForExecLogging('setTimeout')} }`, context);
  vm.runInContext(`function clearTimeout() { ${undefinedForExecLogging('clearTimeout')} }`, context);

  // Run bundle code in created context:
  const bundleContents = fs.readFileSync(filePath, 'utf8');
  vm.runInContext(bundleContents, context);

  // Save bundle file path for further checkings for bundle updates:
  bundleFilePath = filePath;

  // !isMaster check is required for JS unit testing:
  if (!cluster.isMaster) log.debug(`Built VM for worker #${cluster.worker.id}`);
  log.debug('Required objects now in VM sandbox context:', vm.runInContext('global.ReactOnRails', context) !== undefined);
  log.debug('Required objects should not leak to the global context:', global.ReactOnRails);
  return vm;
};

/**
 *
 */
exports.getBundleFilePath = function getBundleFilePath() {
  return bundleFilePath;
};

/**
 *
 */
exports.runInVM = function runInVM(code) {
  vm.runInContext('console.history = []', context);
  const result = vm.runInContext(code, context);
  replayVmConsole();
  return result;
};

/**
 *
 */
exports.resetVM = function resetVM() {
  context = undefined;
  bundleFilePath = undefined;
};
