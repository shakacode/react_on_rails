/**
 * Holds virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

import fs from 'fs';
import path from 'path';
import vm from 'vm';
import cluster from 'cluster';
import log from 'winston';

import { getConfig } from '../shared/configBuilder';
import smartTrim from '../shared/smartTrim';

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
export function buildVM(filePath) {
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
}

/**
 *
 */
export function getBundleFilePath() {
  return bundleFilePath;
}

/**
 *
 */
export function runInVM(code, vmCluster) {
  const { bundlePath } = getConfig();

  try {
    if (log.level === 'debug') {
      const clusterWorkerId = vmCluster && vmCluster.worker ? `worker ${vmCluster.worker.id} ` : '';
      log.debug(`worker ${clusterWorkerId}received render request with code
${smartTrim(code)}`);
      const debugOutputPathCode = path.join(bundlePath, 'code.js');
      log.debug(`Full code executed written to: ${debugOutputPathCode}`);
      fs.writeFileSync(debugOutputPathCode, code);
    }

    vm.runInContext('console.history = []', context);
    const result = vm.runInContext(code, context);

    if (log.level === 'debug') {
      log.debug(`result from JS:
${smartTrim(result)}`);
      const debugOutputPathResult = path.join(bundlePath, 'result.json');
      log.debug(`Wrote result to file: ${debugOutputPathResult}`);
      fs.writeFileSync(debugOutputPathResult, result);
    }

    replayVmConsole();
    return result;
  } catch (e) {
    const exceptionMessage = `
JS code was:
${smartTrim(code)}
    
EXCEPTION MESSAGE:
${e.message}

STACK:
${e.stack}`;
    log.error(`Caught execution error:\n${exceptionMessage}`);
    return { exceptionMessage };
  }
}

/**
 *
 */
export function resetVM() {
  context = undefined;
  bundleFilePath = undefined;
}
