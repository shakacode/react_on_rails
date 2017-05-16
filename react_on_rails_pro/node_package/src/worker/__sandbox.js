/**
 * Hold sandboxed-module instance for rendering code in isolated context.
 * @module worker/sandbox
 */

const fs = require('fs');
const SandboxedModule = require('sandboxed-module');
const cluster = require('cluster');
const { clearConsoleHistory } = require('./consoleHistory');

let vm;
let bundleUpdateTimeUtc;

/**
 *
 */
exports.buildVM = function buildVMNew(filePath) {
  fs.appendFileSync(filePath, '; exports.run = function(code) { return eval(code) };');
  vm = SandboxedModule.load(filePath, { globals: { Math } });

  bundleUpdateTimeUtc = +(fs.statSync(filePath).mtime);

  if (!cluster.isMaster) console.log(`Built VM for worker #${cluster.worker.id}`);
  console.log('Required objects now in VM sandbox context:', vm.exports.run('ReactOnRails') !== undefined);
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
  clearConsoleHistory();
  const result = vm.exports.run(code);
  return result;
};

/**
 *
 */
exports.resetVM = function resetVM() {
  vm = undefined;
  bundleUpdateTimeUtc = undefined;
};
