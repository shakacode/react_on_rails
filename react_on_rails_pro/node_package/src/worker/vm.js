/**
 * Holds virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

const fs = require('fs');
const vm = require('vm');
const cluster = require('cluster');
const { clearConsoleHistory } = require('./consoleHistory');

let context;
let bundleUpdateTimeUtc;

/**
 *
 */
exports.buildVM = function buildVMNew(filePath) {
  const sandbox = { console };
  context = vm.createContext(sandbox);

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
  sandbox = undefined;
  bundleUpdateTimeUtc = undefined;
};
