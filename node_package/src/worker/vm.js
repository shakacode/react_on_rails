/**
 * Holds virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

const fs = require('fs');
const vm = require('vm');
const path = require('path');
const cluster = require('cluster');
const log = require('winston');
const Console = require('console').Console;

let context;
let bundleFilePath;

/**
 *
 */
exports.buildVM = function buildVMNew(filePath) {
  // Create sandbox with new console instance:
  const sandbox = { console: new Console(process.stdout, process.stderr) };
  context = vm.createContext(sandbox);

  // Create explicit reference to global context, just in case (some libs can use it):
  vm.runInContext('global = this', context);

  // Run console.history script in created context to patch its console instance:
  const consoleHistoryModuleDir = path.dirname(require.resolve('console.history'));
  const pathToConsoleHistory = path.join(consoleHistoryModuleDir, 'console-history.js');
  const consoleHistoryContents = fs.readFileSync(pathToConsoleHistory, 'utf8');
  vm.runInContext(consoleHistoryContents, context);

  // Override console._collect method to comply with ReactOnRails console replay script:
  vm.runInContext(`console._collect = (type, args) => {
    // Build console history entry in react_on_rails format:
    const argArray = Array.prototype.slice.call(args);
    if (argArray.length > 0) {
      argArray[0] = \`[SERVER] \${argArray[0]}\`;
    }

    console.history.push({ level: 'log', arguments: argArray });
  };`, context);

  // Run bundle code in created context:
  const bundleContents = fs.readFileSync(filePath, 'utf8');
  vm.runInContext(bundleContents, context);

  // Save bundle file path for further checkings for bundle updates:
  bundleFilePath = filePath;

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
  return result;
};

/**
 *
 */
exports.resetVM = function resetVM() {
  context = undefined;
  bundleFilePath = undefined;
};
