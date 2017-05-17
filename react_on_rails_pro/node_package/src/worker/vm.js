/**
 * Holds virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

const fs = require('fs');
const vm = require('vm');
const path = require('path');
const cluster = require('cluster');
const Console = require('console').Console;

let context;
let bundleUpdateTimeUtc;

/**
 *
 */
exports.buildVM = function buildVMNew(filePath) {
  // Create sandbox with new console instance:
  const sandbox = { console: new Console(process.stdout, process.stderr) };
  context = vm.createContext(sandbox);

  // Run console.history script in created context to patch its console instance:
  const consoleHistoryModuleDir = path.dirname(require.resolve('console.history'));
  const pathToConsoleHistory = path.join(consoleHistoryModuleDir, 'console-history.js');
  const consoleHistoryContents = fs.readFileSync(pathToConsoleHistory, 'utf8');
  vm.runInContext(consoleHistoryContents, context);

  // Override console._collect method to comply with ReactOnRails console replay script:
  vm.runInContext(`console._collect = (type, args) => {
    // Act normal, and just pass all original arguments to the origial console function:
    // eslint-disable-next-line prefer-spread
    console[\`_\${type}\`].apply(console, args);

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

  bundleUpdateTimeUtc = +(fs.statSync(filePath).mtime);

  if (!cluster.isMaster) console.log(`Built VM for worker #${cluster.worker.id}`);
  console.log('Required objects now in VM sandbox context:', vm.runInContext('ReactOnRails', context) !== undefined);
  console.log('Required objects should not leak to the global context:', global.ReactOnRails);
  return vm;
};

/**
 *
 */
exports.getBundleUpdateTimeUtc = function getBundleUpdateTimeUtc() {
  return bundleUpdateTimeUtc;
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
  bundleUpdateTimeUtc = undefined;
};
